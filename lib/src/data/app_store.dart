import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_database.dart';
import 'app_preferences.dart';
import 'mock_repository.dart';
import 'openai_word_enricher.dart';
import 'sync_service.dart';
import 'word_entry.dart';

enum ReviewRating { forgot, shaky, known }

enum ImportMode { dictionary, aiQueue, queueOnly }

class DashboardStats {
  const DashboardStats({
    required this.totalWords,
    required this.dueToday,
    required this.queuedForAi,
    required this.reviewedWords,
    required this.reviewedToday,
    required this.pendingSync,
  });

  final int totalWords;
  final int dueToday;
  final int queuedForAi;
  final int reviewedWords;
  final int reviewedToday;
  final int pendingSync;
}

class ImportResult {
  const ImportResult({
    required this.added,
    required this.skipped,
    required this.dictionaryMatched,
    required this.queued,
  });

  final int added;
  final int skipped;
  final int dictionaryMatched;
  final int queued;
}

class AiBatchResult {
  const AiBatchResult({
    required this.success,
    required this.failed,
    required this.message,
  });

  final int success;
  final int failed;
  final String message;
}

class StudyActivityPoint {
  const StudyActivityPoint({
    required this.date,
    required this.addedWords,
    required this.reviewedWords,
  });

  final DateTime date;
  final int addedWords;
  final int reviewedWords;
}

class DictionaryBatchResult {
  const DictionaryBatchResult({
    required this.filled,
    required this.missing,
    required this.skipped,
  });

  final int filled;
  final int missing;
  final int skipped;

  String get message => '词典补全完成：命中 $filled 个，未命中 $missing 个，跳过 $skipped 个。';
}

class BasicDictionaryEntry {
  const BasicDictionaryEntry({
    required this.word,
    required this.phonetic,
    required this.chineseMeaning,
    required this.englishMeaning,
    required this.partOfSpeech,
    required this.tags,
  });

  final String word;
  final String phonetic;
  final String chineseMeaning;
  final String englishMeaning;
  final String partOfSpeech;
  final List<String> tags;

  factory BasicDictionaryEntry.fromJson(Map<String, dynamic> json) {
    return BasicDictionaryEntry(
      word: json['word']?.toString() ?? '',
      phonetic: json['phonetic']?.toString() ?? '',
      chineseMeaning: json['chineseMeaning']?.toString() ?? '',
      englishMeaning: json['englishMeaning']?.toString() ?? '',
      partOfSpeech: json['partOfSpeech']?.toString() ?? '',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class AppStore extends ChangeNotifier {
  AppStore(
    this.database, {
    AppPreferences? preferences,
    OpenAiWordEnricher? enricher,
    SyncService? syncService,
  }) : preferences = preferences ?? AppPreferences(),
       _enricher = enricher ?? OpenAiWordEnricher(),
       _syncService = syncService;

  final AppDatabase database;
  final AppPreferences preferences;
  final OpenAiWordEnricher _enricher;
  final SyncService? _syncService;
  final _syncStateController = StreamController<SyncState>.broadcast();
  Map<String, BasicDictionaryEntry>? _dictionary;
  String? _userId;
  SyncState? _lastSyncState;

  Future<void> initialize() async {
    await database.ensureCompatibleSchema();
  }

  Future<void> activateUser(String userId) async {
    _userId = userId;
    await database.ensureCompatibleSchema();
    final now = DateTime.now();
    final activeCount = await database.countWords(userId);
    if (activeCount > 0) {
      await _repairSeedWordsIfNeeded(now);
      notifyListeners();
      return;
    }
    if (await database.countLegacyWords() > 0) {
      notifyListeners();
      return;
    }

    for (final word in MockRepository.words) {
      await database.upsertWord(_entryToCompanion(word, now));
    }
    notifyListeners();
  }

  void clearActiveUser() {
    _userId = null;
    _lastSyncState = null;
    notifyListeners();
  }

  Stream<List<WordEntry>> watchWords() {
    return database
        .watchAllWords(_requireUserId())
        .map((rows) => rows.map(_rowToEntry).toList());
  }

  Stream<List<WordEntry>> watchDueWords() {
    return database
        .watchDueWords(_requireUserId(), DateTime.now())
        .map((rows) => rows.map(_rowToEntry).toList());
  }

  Stream<DashboardStats> watchDashboardStats() {
    final userId = _requireUserId();
    return database.watchAllWords(userId).asyncMap((rows) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueToday = rows.where((row) => !row.dueAt.isAfter(now)).length;
      final queued = rows
          .where((row) => row.enrichmentStatus == 'queued_ai')
          .length;
      final reviewed = rows.where((row) => row.reviewCount > 0).length;
      final reviewedToday = await database.countReviewLogsSince(userId, today);
      final pendingSync = await database.countPendingSync(userId);
      return DashboardStats(
        totalWords: rows.length,
        dueToday: dueToday,
        queuedForAi: queued,
        reviewedWords: reviewed,
        reviewedToday: reviewedToday,
        pendingSync: pendingSync,
      );
    });
  }

  Stream<SyncState> watchSyncStatus() {
    final service =
        _syncService ??
        SupabaseSyncService(database: database, preferences: preferences);
    final userId = _requireUserId();
    return (() async* {
      final cached = _lastSyncState;
      if (cached != null) {
        yield cached;
      } else {
        final state = await service.watchSyncStatus(userId: userId).first;
        yield await _withLastSyncedAt(state);
      }
      yield* _syncStateController.stream;
    })();
  }

  Future<SyncResult> syncNow() async {
    final service =
        _syncService ??
        SupabaseSyncService(database: database, preferences: preferences);
    await _emitSyncState(SyncPhase.syncing, message: '正在同步云端词库和复习记录。');
    try {
      final result = await service.syncNow(userId: _requireUserId());
      if (result.success) {
        await preferences.saveLastSyncedAt(DateTime.now());
      }
      await _emitSyncState(
        result.success ? SyncPhase.idle : SyncPhase.failed,
        message: result.message,
      );
      notifyListeners();
      return result;
    } on Object catch (error) {
      final message = '同步失败：$error';
      await _emitSyncState(SyncPhase.failed, message: message);
      notifyListeners();
      return SyncResult(
        success: false,
        message: message,
        pushed: 0,
        pulled: 0,
        pendingChanges: await database.countPendingSync(_requireUserId()),
      );
    }
  }

  Future<int> countLegacyWords() {
    return database.countLegacyWords();
  }

  Future<void> claimLegacyDataForActiveUser() async {
    await database.claimLegacyData(_requireUserId(), DateTime.now());
    await _emitSyncState(SyncPhase.idle, message: '本地词库已绑定到当前账号，等待同步到云端。');
    notifyListeners();
  }

  Future<StudyPlan> getStudyPlan() async {
    final examDate = await preferences.getExamDate();
    return StudyPlan(
      dailyNewWords: await preferences.getDailyNewWords(),
      dailyReviewLimit: await preferences.getDailyReviewLimit(),
      examDateLabel: _formatExamDate(examDate),
      todayNewDone: 0,
      todayReviewDone: 0,
      streakDays: 0,
    );
  }

  Future<void> saveStudyPlan({
    required int dailyNewWords,
    required int dailyReviewLimit,
    required DateTime? examDate,
  }) async {
    await preferences.saveStudySettings(
      dailyNewWords: dailyNewWords,
      dailyReviewLimit: dailyReviewLimit,
      examDate: examDate,
      updatedAt: DateTime.now(),
      pendingSync: true,
    );
    notifyListeners();
  }

  Stream<List<StudyActivityPoint>> watchStudyActivity({int days = 30}) {
    final userId = _requireUserId();
    final start = _dayStart(DateTime.now()).subtract(Duration(days: days - 1));
    return database.watchAllWords(userId).asyncMap((words) async {
      final logs = await database.getReviewLogsSince(userId, start);
      final addedByDay = <DateTime, int>{};
      final reviewedByDay = <DateTime, int>{};
      for (final row in words) {
        final day = _dayStart(row.createdAt);
        if (!day.isBefore(start)) {
          addedByDay[day] = (addedByDay[day] ?? 0) + 1;
        }
      }
      for (final row in logs) {
        final day = _dayStart(row.reviewedAt);
        reviewedByDay[day] = (reviewedByDay[day] ?? 0) + 1;
      }
      return [
        for (var i = 0; i < days; i++)
          () {
            final date = start.add(Duration(days: i));
            return StudyActivityPoint(
              date: date,
              addedWords: addedByDay[date] ?? 0,
              reviewedWords: reviewedByDay[date] ?? 0,
            );
          }(),
      ];
    });
  }

  String _requireUserId() {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      throw StateError('AppStore has no active user.');
    }
    return userId;
  }

  String _localWordId(String word) {
    final normalized = word.trim().toLowerCase();
    return '${_requireUserId()}:$normalized';
  }

  Future<ImportResult> importWords(String rawText, ImportMode mode) async {
    final candidates = parseWords(rawText);
    if (candidates.isEmpty) {
      return const ImportResult(
        added: 0,
        skipped: 0,
        dictionaryMatched: 0,
        queued: 0,
      );
    }

    final dictionary = mode == ImportMode.dictionary
        ? await _loadDictionary()
        : const <String, BasicDictionaryEntry>{};
    final existingWords = (await database.getAllWords(
      _requireUserId(),
    )).map((row) => row.word.toLowerCase()).toSet();
    final now = DateTime.now();
    var added = 0;
    var skipped = 0;
    var dictionaryMatched = 0;
    var queued = 0;

    for (final word in candidates) {
      if (existingWords.contains(word)) {
        skipped += 1;
        continue;
      }

      final entry = dictionary[word];
      if (entry != null) {
        await database.upsertWord(_dictionaryCompanion(entry, now));
        dictionaryMatched += 1;
      } else {
        await database.upsertWord(
          _placeholderCompanion(
            word,
            now,
            status: mode == ImportMode.aiQueue ? 'queued_ai' : 'queued',
          ),
        );
        queued += 1;
      }

      existingWords.add(word);
      added += 1;
    }

    notifyListeners();
    return ImportResult(
      added: added,
      skipped: skipped,
      dictionaryMatched: dictionaryMatched,
      queued: queued,
    );
  }

  Future<void> updateNote(String wordId, String note) async {
    await database.updateNote(_requireUserId(), wordId, note, DateTime.now());
    notifyListeners();
  }

  Future<void> updateWordContent({
    required WordEntry original,
    required String chineseMeaning,
    required String englishMeaning,
    required String greFocus,
    required String rootsText,
    required String synonymsText,
    required String antonymsText,
    required String example,
    required String memoryTip,
    required String note,
    required String tagsText,
  }) async {
    await database.updateWordContent(
      userId: _requireUserId(),
      wordId: original.id,
      chineseMeaning: chineseMeaning.trim(),
      englishMeaning: englishMeaning.trim(),
      greFocus: greFocus.trim(),
      rootsJson: jsonEncode(_parseRoots(rootsText)),
      synonymsJson: jsonEncode(_splitTextList(synonymsText)),
      antonymsJson: jsonEncode(_splitTextList(antonymsText)),
      example: example.trim(),
      memoryTip: memoryTip.trim(),
      note: note.trim(),
      tagsJson: jsonEncode(_splitTextList(tagsText)),
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> queueForAi(String wordId) async {
    await database.updateEnrichmentStatus(
      userId: _requireUserId(),
      wordId: wordId,
      status: 'queued_ai',
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  Future<void> queueManyForAi(List<String> wordIds) async {
    for (final wordId in wordIds) {
      await database.updateEnrichmentStatus(
        userId: _requireUserId(),
        wordId: wordId,
        status: 'queued_ai',
        updatedAt: DateTime.now(),
      );
    }
    notifyListeners();
  }

  Future<bool> fillWordFromDictionary(String wordId) async {
    final result = await fillManyFromDictionary([wordId]);
    return result.filled == 1;
  }

  Future<DictionaryBatchResult> fillManyFromDictionary(
    List<String> wordIds,
  ) async {
    if (wordIds.isEmpty) {
      return const DictionaryBatchResult(filled: 0, missing: 0, skipped: 0);
    }

    final selectedIds = wordIds.toSet();
    final dictionary = await _loadDictionary();
    final rows = (await database.getAllWords(
      _requireUserId(),
    )).where((row) => selectedIds.contains(row.id)).toList();
    final now = DateTime.now();
    var filled = 0;
    var missing = 0;
    var skipped = selectedIds.length - rows.length;

    for (final row in rows) {
      if (!_canUseDictionaryFill(row.enrichmentStatus)) {
        skipped += 1;
        continue;
      }
      final entry = dictionary[row.word.toLowerCase()];
      if (entry == null) {
        missing += 1;
        continue;
      }
      await _updateRowFromDictionary(row.id, entry, now);
      filled += 1;
    }

    notifyListeners();
    return DictionaryBatchResult(
      filled: filled,
      missing: missing,
      skipped: skipped,
    );
  }

  Future<void> deleteWords(List<String> wordIds) async {
    await database.deleteWordsByIds(_requireUserId(), wordIds);
    notifyListeners();
  }

  Future<String> getApiKey() => preferences.getApiKey();

  Future<void> saveApiKey(String value) => preferences.saveApiKey(value);

  Future<String> getModel() => preferences.getModel();

  Future<void> saveModel(String value) => preferences.saveModel(value);

  Future<AiBatchResult> enrichQueuedAiWords({int limit = 10}) async {
    final apiKey = await getApiKey();
    if (apiKey.trim().isEmpty) {
      return const AiBatchResult(
        success: 0,
        failed: 0,
        message: '请先在设置页保存 OpenAI API Key。',
      );
    }

    final model = await getModel();
    final words = (await database.getAllWords(
      _requireUserId(),
    )).where((row) => row.enrichmentStatus == 'queued_ai').take(limit).toList();
    if (words.isEmpty) {
      return const AiBatchResult(
        success: 0,
        failed: 0,
        message: '没有待 AI 补全的单词。',
      );
    }

    var success = 0;
    var failed = 0;
    String? firstError;
    for (final word in words) {
      try {
        final data = await _enricher.enrich(
          apiKey: apiKey,
          model: model,
          word: word.word,
        );
        await database.updateAiEnrichment(
          userId: _requireUserId(),
          wordId: word.id,
          chineseMeaning: data.chineseMeaning,
          englishMeaning: data.englishMeaning,
          greFocus: data.greFocus,
          rootsJson: jsonEncode([
            for (final root in data.roots)
              {'part': root.part, 'meaning': root.meaning},
          ]),
          synonymsJson: jsonEncode(data.synonyms),
          antonymsJson: jsonEncode(data.antonyms),
          example: data.example,
          memoryTip: data.memoryTip,
          tagsJson: jsonEncode(['AI 补全', ...data.tags]),
          updatedAt: DateTime.now(),
        );
        success += 1;
      } on Exception catch (error) {
        firstError ??= error.toString();
        await database.updateEnrichmentStatus(
          userId: _requireUserId(),
          wordId: word.id,
          status: 'failed',
          updatedAt: DateTime.now(),
        );
        failed += 1;
      }
    }

    notifyListeners();
    return AiBatchResult(
      success: success,
      failed: failed,
      message:
          'AI 补全完成：成功 $success 个，失败 $failed 个。'
          '${firstError == null ? '' : ' 首个错误：$firstError'}',
    );
  }

  Future<void> recordReview(WordEntry word, ReviewRating rating) async {
    final now = DateTime.now();
    final reviewCount = word.reviewCount + 1;
    final lapseCount = rating == ReviewRating.forgot
        ? word.lapseCount + 1
        : word.lapseCount;
    final schedule = _nextSm2Schedule(
      now: now,
      rating: rating,
      reviewCount: reviewCount,
      previousEaseFactor: word.easeFactor,
      previousIntervalDays: word.intervalDays,
    );
    final mastery = _nextMastery(
      current: word.mastery,
      rating: rating,
      intervalDays: schedule.intervalDays,
    );
    await database.addReviewLog(
      userId: _requireUserId(),
      wordId: word.id,
      rating: rating.name,
      reviewedAt: now,
    );
    await database.updateReviewState(
      userId: _requireUserId(),
      wordId: word.id,
      mastery: mastery.index,
      dueAt: schedule.dueAt,
      reviewCount: reviewCount,
      lapseCount: lapseCount,
      easeFactor: schedule.easeFactor,
      intervalDays: schedule.intervalDays,
      updatedAt: now,
    );
    notifyListeners();
  }

  Future<void> disposeStore() async {
    await _syncStateController.close();
    await database.close();
  }

  Future<SyncState> _withLastSyncedAt(SyncState state) async {
    return SyncState(
      phase: state.phase,
      pendingChanges: state.pendingChanges,
      message: state.message,
      lastSyncedAt: await preferences.getLastSyncedAt(),
    );
  }

  Future<void> _emitSyncState(
    SyncPhase phase, {
    required String message,
  }) async {
    final state = SyncState(
      phase: phase,
      pendingChanges: await database.countPendingSync(_requireUserId()),
      message: message,
      lastSyncedAt: await preferences.getLastSyncedAt(),
    );
    _lastSyncState = state;
    if (!_syncStateController.isClosed) {
      _syncStateController.add(state);
    }
  }

  Future<String> exportBackupJson() async {
    final words = await database.getAllWords(_requireUserId());
    final logs = await database.getAllReviewLogs(_requireUserId());
    final payload = {
      'version': 1,
      'userId': _requireUserId(),
      'exportedAt': DateTime.now().toIso8601String(),
      'words': [
        for (final row in words)
          {
            'id': row.id,
            'userId': row.userId,
            'remoteId': row.remoteId,
            'syncStatus': row.syncStatus,
            'deletedAt': row.deletedAt?.toIso8601String(),
            'word': row.word,
            'chineseMeaning': row.chineseMeaning,
            'englishMeaning': row.englishMeaning,
            'greFocus': row.greFocus,
            'rootsJson': row.rootsJson,
            'synonymsJson': row.synonymsJson,
            'antonymsJson': row.antonymsJson,
            'example': row.example,
            'memoryTip': row.memoryTip,
            'note': row.note,
            'tagsJson': row.tagsJson,
            'mastery': row.mastery,
            'dueAt': row.dueAt.toIso8601String(),
            'reviewCount': row.reviewCount,
            'lapseCount': row.lapseCount,
            'easeFactor': row.easeFactor,
            'intervalDays': row.intervalDays,
            'enrichmentStatus': row.enrichmentStatus,
            'createdAt': row.createdAt.toIso8601String(),
            'updatedAt': row.updatedAt.toIso8601String(),
          },
      ],
      'reviewLogs': [
        for (final row in logs)
          {
            'wordId': row.wordId,
            'userId': row.userId,
            'remoteId': row.remoteId,
            'syncStatus': row.syncStatus,
            'deletedAt': row.deletedAt?.toIso8601String(),
            'rating': row.rating,
            'reviewedAt': row.reviewedAt.toIso8601String(),
            'updatedAt': row.updatedAt?.toIso8601String(),
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> importBackupJson(String rawJson, {bool replace = false}) async {
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final words = decoded['words'] as List<dynamic>? ?? const [];
    final logs = decoded['reviewLogs'] as List<dynamic>? ?? const [];
    if (replace) {
      await database.clearAllData(_requireUserId());
    }
    for (final item in words.whereType<Map<String, dynamic>>()) {
      final word = item['word']?.toString() ?? '';
      if (word.isEmpty) {
        continue;
      }
      final importedId = item['id']?.toString() ?? '';
      final wordId = importedId.startsWith('${_requireUserId()}:')
          ? importedId
          : _localWordId(word);
      await database.upsertWord(
        WordCardsCompanion.insert(
          id: wordId,
          userId: Value(_requireUserId()),
          remoteId: Value(item['remoteId']?.toString()),
          syncStatus: Value(item['syncStatus']?.toString() ?? 'dirty'),
          deletedAt: Value(_parseDate(item['deletedAt'])),
          word: word,
          chineseMeaning: item['chineseMeaning']?.toString() ?? '',
          englishMeaning: item['englishMeaning']?.toString() ?? '',
          greFocus: item['greFocus']?.toString() ?? '',
          rootsJson: Value(item['rootsJson']?.toString() ?? '[]'),
          synonymsJson: Value(item['synonymsJson']?.toString() ?? '[]'),
          antonymsJson: Value(item['antonymsJson']?.toString() ?? '[]'),
          example: Value(item['example']?.toString() ?? ''),
          memoryTip: Value(item['memoryTip']?.toString() ?? ''),
          note: Value(item['note']?.toString() ?? ''),
          tagsJson: Value(item['tagsJson']?.toString() ?? '[]'),
          mastery: Value((item['mastery'] as num?)?.toInt() ?? 0),
          dueAt: _parseDate(item['dueAt']) ?? DateTime.now(),
          reviewCount: Value((item['reviewCount'] as num?)?.toInt() ?? 0),
          lapseCount: Value((item['lapseCount'] as num?)?.toInt() ?? 0),
          easeFactor: Value((item['easeFactor'] as num?)?.toInt() ?? 250),
          intervalDays: Value((item['intervalDays'] as num?)?.toInt() ?? 0),
          enrichmentStatus: Value(
            item['enrichmentStatus']?.toString() ?? 'queued',
          ),
          createdAt: _parseDate(item['createdAt']) ?? DateTime.now(),
          updatedAt: _parseDate(item['updatedAt']) ?? DateTime.now(),
        ),
      );
    }
    for (final item in logs.whereType<Map<String, dynamic>>()) {
      final importedWordId = item['wordId']?.toString() ?? '';
      final wordId = importedWordId.startsWith('${_requireUserId()}:')
          ? importedWordId
          : _localWordId(importedWordId);
      final reviewedAt = _parseDate(item['reviewedAt']);
      if (importedWordId.isEmpty || reviewedAt == null) {
        continue;
      }
      await database.addReviewLog(
        userId: _requireUserId(),
        wordId: wordId,
        rating: item['rating']?.toString() ?? 'known',
        reviewedAt: reviewedAt,
      );
    }
    notifyListeners();
  }

  Future<void> clearAllData() async {
    await database.clearAllData(_requireUserId());
    notifyListeners();
  }

  static List<String> parseWords(String rawText) {
    return rawText
        .split(RegExp(r'[^A-Za-z-]+'))
        .map((word) => word.trim().toLowerCase())
        .where((word) => word.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  static List<String> _splitTextList(String text) {
    return _normalizeText(text)
        .split(RegExp(r'[\n,;，；]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  static String _normalizeText(String text) {
    return text
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\n')
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n');
  }

  static List<Map<String, String>> _parseRoots(String text) {
    return text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .map((line) {
          final separator = line.contains(':') ? ':' : '：';
          final parts = line.split(separator);
          if (parts.length < 2) {
            return {'part': line, 'meaning': ''};
          }
          return {
            'part': parts.first.trim(),
            'meaning': parts.skip(1).join(separator).trim(),
          };
        })
        .toList();
  }

  DateTime? _parseDate(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }

  Future<void> _repairSeedWordsIfNeeded(DateTime now) async {
    final rowsById = {
      for (final row in await database.getAllWords(_requireUserId()))
        row.word.toLowerCase(): row,
    };
    for (final seed in MockRepository.words) {
      final row = rowsById[seed.word.toLowerCase()];
      if (row == null) {
        continue;
      }
      if (_hasMojibake(row)) {
        await database.upsertWord(
          _entryToCompanion(seed, now, idOverride: row.id),
        );
      }
    }
  }

  bool _hasMojibake(WordCard row) {
    return [
      row.chineseMeaning,
      row.greFocus,
      row.memoryTip,
      row.note,
      row.tagsJson,
    ].any((value) => value.contains('�'));
  }

  Future<Map<String, BasicDictionaryEntry>> _loadDictionary() async {
    final cached = _dictionary;
    if (cached != null) {
      return cached;
    }

    final rawJson = await rootBundle.loadString(
      'assets/dictionaries/exam_basic.json',
    );
    final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
    final entries = decoded.map(
      (word, value) => MapEntry(
        word,
        BasicDictionaryEntry.fromJson(value as Map<String, dynamic>),
      ),
    );
    _dictionary = entries;
    return entries;
  }

  WordCardsCompanion _entryToCompanion(
    WordEntry entry,
    DateTime now, {
    String? idOverride,
  }) {
    return WordCardsCompanion.insert(
      id: idOverride ?? _localWordId(entry.word),
      userId: Value(_requireUserId()),
      word: entry.word,
      chineseMeaning: _normalizeText(entry.chineseMeaning),
      englishMeaning: _normalizeText(entry.englishMeaning),
      greFocus: _normalizeText(entry.greFocus),
      rootsJson: Value(
        jsonEncode([
          for (final root in entry.roots)
            {'part': root.part, 'meaning': root.meaning},
        ]),
      ),
      synonymsJson: Value(jsonEncode(entry.synonyms)),
      antonymsJson: Value(jsonEncode(entry.antonyms)),
      example: Value(_normalizeText(entry.example)),
      memoryTip: Value(_normalizeText(entry.memoryTip)),
      note: Value(_normalizeText(entry.note)),
      tagsJson: Value(jsonEncode(entry.tags)),
      mastery: Value(entry.mastery.index),
      dueAt: _seedDueDate(entry.dueLabel, now),
      reviewCount: Value(entry.reviewCount),
      lapseCount: Value(entry.lapseCount),
      easeFactor: Value(entry.easeFactor),
      intervalDays: Value(entry.intervalDays),
      enrichmentStatus: Value(entry.enrichmentStatus),
      syncStatus: const Value('dirty'),
      createdAt: now,
      updatedAt: now,
    );
  }

  WordCardsCompanion _dictionaryCompanion(
    BasicDictionaryEntry entry,
    DateTime now,
  ) {
    final content = _dictionaryContent(entry);

    return WordCardsCompanion.insert(
      id: _localWordId(entry.word),
      userId: Value(_requireUserId()),
      word: entry.word,
      chineseMeaning: content.chineseMeaning,
      englishMeaning: content.englishMeaning,
      greFocus: content.greFocus,
      rootsJson: const Value('[]'),
      synonymsJson: const Value('[]'),
      antonymsJson: const Value('[]'),
      example: const Value(''),
      memoryTip: Value(content.memoryTip),
      note: const Value(''),
      tagsJson: Value(jsonEncode(content.tags)),
      mastery: Value(MasteryLevel.newWord.index),
      dueAt: now,
      reviewCount: const Value(0),
      lapseCount: const Value(0),
      easeFactor: const Value(250),
      intervalDays: const Value(0),
      enrichmentStatus: const Value('dictionary'),
      syncStatus: const Value('dirty'),
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _updateRowFromDictionary(
    String wordId,
    BasicDictionaryEntry entry,
    DateTime now,
  ) {
    final content = _dictionaryContent(entry);
    return database.updateDictionaryEnrichment(
      userId: _requireUserId(),
      wordId: wordId,
      chineseMeaning: content.chineseMeaning,
      englishMeaning: content.englishMeaning,
      greFocus: content.greFocus,
      memoryTip: content.memoryTip,
      tagsJson: jsonEncode(content.tags),
      updatedAt: now,
    );
  }

  _DictionaryContent _dictionaryContent(BasicDictionaryEntry entry) {
    final tags = [
      ...entry.tags.map((tag) => tag.toUpperCase()),
      if (entry.partOfSpeech.isNotEmpty) entry.partOfSpeech,
    ];
    final chineseMeaning = _normalizeText(entry.chineseMeaning);
    return _DictionaryContent(
      chineseMeaning: chineseMeaning.isEmpty ? '词典暂无中文释义' : chineseMeaning,
      englishMeaning: _normalizeText(entry.englishMeaning),
      greFocus: '基础词典补全，可正常复习；需要更完整的 GRE 考点、词根词缀和记忆提示时，可升级为 AI 补全。',
      memoryTip: entry.phonetic.isEmpty ? '' : '音标：/${entry.phonetic}/',
      tags: tags.toSet().toList(),
    );
  }

  WordCardsCompanion _placeholderCompanion(
    String word,
    DateTime now, {
    required String status,
  }) {
    return WordCardsCompanion.insert(
      id: _localWordId(word),
      userId: Value(_requireUserId()),
      word: word,
      chineseMeaning: status == 'queued_ai' ? '待 AI 补全' : '待补全',
      englishMeaning: 'Waiting for enrichment.',
      greFocus: status == 'queued_ai'
          ? '已加入 AI 补全队列，稍后会生成 GRE 考点、词根词缀和例句。'
          : '已加入本地词库，可稍后选择基础词典补全或 AI 深度补全。',
      rootsJson: const Value('[]'),
      synonymsJson: const Value('[]'),
      antonymsJson: const Value('[]'),
      example: const Value(''),
      memoryTip: const Value(''),
      note: const Value(''),
      tagsJson: Value(jsonEncode([status == 'queued_ai' ? '待 AI 补全' : '待补全'])),
      mastery: Value(MasteryLevel.newWord.index),
      dueAt: now,
      reviewCount: const Value(0),
      lapseCount: const Value(0),
      easeFactor: const Value(250),
      intervalDays: const Value(0),
      enrichmentStatus: Value(status),
      syncStatus: const Value('dirty'),
      createdAt: now,
      updatedAt: now,
    );
  }

  DateTime _seedDueDate(String label, DateTime now) {
    if (label == '明天') {
      return DateTime(now.year, now.month, now.day + 1);
    }
    return now;
  }

  WordEntry _rowToEntry(WordCard row) {
    final roots = _decodeList(row.rootsJson)
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => RootPart(
            part: item['part']?.toString() ?? '',
            meaning: item['meaning']?.toString() ?? '',
          ),
        )
        .where((item) => item.part.isNotEmpty)
        .toList();

    return WordEntry(
      id: row.id,
      word: row.word,
      createdAtMs: row.createdAt.millisecondsSinceEpoch,
      chineseMeaning: _normalizeText(row.chineseMeaning),
      englishMeaning: _normalizeText(row.englishMeaning),
      greFocus: _normalizeText(row.greFocus),
      roots: roots,
      synonyms: _decodeStringList(row.synonymsJson),
      antonyms: _decodeStringList(row.antonymsJson),
      example: _normalizeText(row.example),
      memoryTip: _normalizeText(row.memoryTip),
      note: _normalizeText(row.note),
      tags: _decodeStringList(row.tagsJson),
      mastery: MasteryLevel
          .values[row.mastery.clamp(0, MasteryLevel.values.length - 1).toInt()],
      dueLabel: _dueLabel(row.dueAt),
      reviewCount: row.reviewCount,
      lapseCount: row.lapseCount,
      easeFactor: row.easeFactor,
      intervalDays: row.intervalDays,
      enrichmentStatus: row.enrichmentStatus,
    );
  }

  List<dynamic> _decodeList(String rawJson) {
    try {
      final decoded = jsonDecode(rawJson);
      return decoded is List ? decoded : const [];
    } on FormatException {
      return const [];
    }
  }

  List<String> _decodeStringList(String rawJson) {
    return _decodeList(rawJson).map((item) => item.toString()).toList();
  }

  String _dueLabel(DateTime dueAt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueAt.year, dueAt.month, dueAt.day);
    final days = dueDay.difference(today).inDays;
    if (days <= 0) {
      return '今天';
    }
    if (days == 1) {
      return '明天';
    }
    return '$days 天后';
  }

  DateTime _dayStart(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  String _formatExamDate(DateTime? value) {
    if (value == null) {
      return '未设置';
    }
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}.$month.$day';
  }

  MasteryLevel _nextMastery({
    required MasteryLevel current,
    required ReviewRating rating,
    required int intervalDays,
  }) {
    switch (rating) {
      case ReviewRating.forgot:
        return MasteryLevel.learning;
      case ReviewRating.shaky:
        return current == MasteryLevel.newWord
            ? MasteryLevel.learning
            : current;
      case ReviewRating.known:
        if (intervalDays >= 21) {
          return MasteryLevel.mastered;
        }
        if (intervalDays >= 6) {
          return MasteryLevel.familiar;
        }
        return MasteryLevel.learning;
    }
  }

  bool _canUseDictionaryFill(String status) {
    return status == 'queued' || status == 'queued_ai' || status == 'failed';
  }

  _Sm2Schedule _nextSm2Schedule({
    required DateTime now,
    required ReviewRating rating,
    required int reviewCount,
    required int previousEaseFactor,
    required int previousIntervalDays,
  }) {
    final quality = switch (rating) {
      ReviewRating.forgot => 2,
      ReviewRating.shaky => 4,
      ReviewRating.known => 5,
    };
    final easeFactor = _nextEaseFactor(previousEaseFactor, quality);
    late final int intervalDays;
    switch (rating) {
      case ReviewRating.forgot:
        intervalDays = 0;
      case ReviewRating.shaky:
        intervalDays = previousIntervalDays <= 0
            ? 1
            : (previousIntervalDays * 1.2).round().clamp(1, 3650).toInt();
      case ReviewRating.known:
        if (reviewCount <= 1) {
          intervalDays = 1;
        } else if (reviewCount == 2) {
          intervalDays = 6;
        } else {
          final base = previousIntervalDays <= 0 ? 6 : previousIntervalDays;
          intervalDays = (base * easeFactor / 100)
              .round()
              .clamp(1, 3650)
              .toInt();
        }
    }
    return _Sm2Schedule(
      dueAt: intervalDays == 0
          ? now
          : DateTime(now.year, now.month, now.day + intervalDays),
      easeFactor: easeFactor,
      intervalDays: intervalDays,
    );
  }

  int _nextEaseFactor(int previousEaseFactor, int quality) {
    if (quality < 3) {
      return (previousEaseFactor - 20).clamp(130, 300).toInt();
    }
    final delta = (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)) * 100;
    return (previousEaseFactor + delta.round()).clamp(130, 300).toInt();
  }
}

class _Sm2Schedule {
  const _Sm2Schedule({
    required this.dueAt,
    required this.easeFactor,
    required this.intervalDays,
  });

  final DateTime dueAt;
  final int easeFactor;
  final int intervalDays;
}

class _DictionaryContent {
  const _DictionaryContent({
    required this.chineseMeaning,
    required this.englishMeaning,
    required this.greFocus,
    required this.memoryTip,
    required this.tags,
  });

  final String chineseMeaning;
  final String englishMeaning;
  final String greFocus;
  final String memoryTip;
  final List<String> tags;
}
