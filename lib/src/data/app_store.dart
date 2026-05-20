import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import 'app_database.dart';
import 'app_preferences.dart';
import 'mock_repository.dart';
import 'openai_word_enricher.dart';
import 'word_book_catalog.dart';
import 'word_quality.dart';
import 'sync_service.dart';
import 'word_entry.dart';

enum ReviewRating { forgot, shaky, known }

enum ImportMode { dictionary, aiQueue, queueOnly }

class DashboardStats {
  const DashboardStats({
    required this.totalWords,
    required this.dueToday,
    required this.queuedForAi,
    required this.difficultWords,
    required this.reviewedWords,
    required this.reviewedToday,
    required this.pendingSync,
  });

  final int totalWords;
  final int dueToday;
  final int queuedForAi;
  final int difficultWords;
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

class WordBookImportResult {
  const WordBookImportResult({
    required this.book,
    required this.added,
    required this.skipped,
    required this.scheduledLater,
  });

  final WordBookDefinition book;
  final int added;
  final int skipped;
  final int scheduledLater;

  String get message {
    return '${book.shortLabel} 导入完成：新增 $added 个，跳过 $skipped 个，分批安排 $scheduledLater 个。';
  }
}

class WordBookStats {
  const WordBookStats({
    required this.book,
    required this.totalDictionaryWords,
    required this.importedWords,
    required this.newWords,
    required this.learningWords,
    required this.familiarWords,
    required this.masteredWords,
    required this.enabled,
  });

  final WordBookDefinition book;
  final int totalDictionaryWords;
  final int importedWords;
  final int newWords;
  final int learningWords;
  final int familiarWords;
  final int masteredWords;
  final bool enabled;

  int get remainingWords {
    final remaining = totalDictionaryWords - importedWords;
    return remaining < 0 ? 0 : remaining;
  }

  double get progress {
    if (importedWords == 0) {
      return 0;
    }
    return masteredWords / importedWords;
  }
}

class WordBookEntryProgress {
  const WordBookEntryProgress({
    required this.word,
    required this.chineseMeaning,
    required this.imported,
    required this.mastery,
    required this.reviewCount,
    required this.dueLabel,
    required this.enrichmentStatus,
  });

  final String word;
  final String chineseMeaning;
  final bool imported;
  final MasteryLevel? mastery;
  final int reviewCount;
  final String dueLabel;
  final String enrichmentStatus;
}

class AiBatchResult {
  const AiBatchResult({
    required this.success,
    required this.needsReview,
    required this.failed,
    required this.message,
  });

  final int success;
  final int needsReview;
  final int failed;
  final String message;
}

class SyncLogEntry {
  const SyncLogEntry({
    required this.createdAt,
    required this.success,
    required this.message,
    required this.pushed,
    required this.pulled,
    required this.pendingChanges,
  });

  final DateTime createdAt;
  final bool success;
  final String message;
  final int pushed;
  final int pulled;
  final int pendingChanges;

  Map<String, dynamic> toJson() {
    return {
      'createdAt': createdAt.toIso8601String(),
      'success': success,
      'message': message,
      'pushed': pushed,
      'pulled': pulled,
      'pendingChanges': pendingChanges,
    };
  }

  factory SyncLogEntry.fromJson(Map<String, dynamic> json) {
    return SyncLogEntry(
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      pushed: (json['pushed'] as num?)?.toInt() ?? 0,
      pulled: (json['pulled'] as num?)?.toInt() ?? 0,
      pendingChanges: (json['pendingChanges'] as num?)?.toInt() ?? 0,
    );
  }
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

class StudyDashboard {
  const StudyDashboard({
    required this.streakDays,
    required this.activeRate7,
    required this.activeRate30,
    required this.tomorrowReviewWords,
    required this.difficultWords,
    required this.reviewableWords,
  });

  final int streakDays;
  final double activeRate7;
  final double activeRate30;
  final int tomorrowReviewWords;
  final int difficultWords;
  final int reviewableWords;
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

class BatchEditResult {
  const BatchEditResult({
    required this.changed,
    required this.skipped,
    required this.message,
  });

  final int changed;
  final int skipped;
  final String message;
}

class BackupPreview {
  const BackupPreview({
    required this.version,
    required this.exportedAt,
    required this.userId,
    required this.wordCount,
    required this.reviewLogCount,
    required this.personalWordCount,
    required this.bookWordCount,
    required this.aiWordCount,
    required this.dictionaryWordCount,
  });

  final int version;
  final DateTime? exportedAt;
  final String userId;
  final int wordCount;
  final int reviewLogCount;
  final int personalWordCount;
  final int bookWordCount;
  final int aiWordCount;
  final int dictionaryWordCount;
}

class BackupImportResult {
  const BackupImportResult({
    required this.importedWords,
    required this.importedReviewLogs,
    required this.replaced,
  });

  final int importedWords;
  final int importedReviewLogs;
  final bool replaced;

  String get message {
    final mode = replaced ? '覆盖导入' : '合并导入';
    return '$mode 完成：导入 $importedWords 个单词、$importedReviewLogs 条复习记录。';
  }
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
  Future<SyncResult>? _syncInFlight;
  DateTime? _pendingSyncCountCachedAt;
  int? _pendingSyncCountCache;
  bool _disposed = false;

  Future<void> initialize() async {
    await database.ensureCompatibleSchema();
  }

  Future<void> activateUser(String userId) async {
    _userId = userId;
    await database.ensureCompatibleSchema();
    final now = DateTime.now();
    final activeCount = await database.countWords(userId);
    if (activeCount > 0) {
      if (!await preferences.isSeedRepairDone(userId)) {
        await _repairSeedWordsIfNeeded(now);
        await preferences.markSeedRepairDone(userId);
      }
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
    await preferences.markSeedRepairDone(userId);
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
        .map(
          (rows) => rows
              .where((row) => _isReviewableStatus(row.enrichmentStatus))
              .where((row) => row.mastery != MasteryLevel.newWord.index)
              .where((row) => row.mastery != MasteryLevel.mastered.index)
              .map(_rowToEntry)
              .toList(),
        );
  }

  Stream<List<WordEntry>> watchNewWords({String? bookKey}) {
    final userId = _requireUserId();
    final normalizedBookKey = bookKey?.trim().toLowerCase() ?? '';
    return database.watchAllWords(userId).asyncMap((rows) async {
      final dailyNewWords = await preferences.getDailyNewWords();
      final disabledBooks = await preferences.getDisabledWordBooks();
      final todaySeed = _dailySeed(DateTime.now(), userId);
      final candidates =
          rows
              .where((row) => row.sourceType == 'book')
              .where(
                (row) =>
                    normalizedBookKey.isEmpty ||
                    row.bookKey.toLowerCase() == normalizedBookKey,
              )
              .where(
                (row) => !disabledBooks.contains(row.bookKey.toLowerCase()),
              )
              .where((row) => row.mastery == MasteryLevel.newWord.index)
              .where((row) => _isReviewableStatus(row.enrichmentStatus))
              .toList()
            ..sort(
              (a, b) => _stableDailyRank(
                todaySeed,
                a.id,
              ).compareTo(_stableDailyRank(todaySeed, b.id)),
            );
      return candidates.take(dailyNewWords).map(_rowToEntry).toList();
    });
  }

  Stream<List<WordEntry>> watchDifficultWords() {
    return database.watchAllWords(_requireUserId()).map((rows) {
      final candidates =
          rows
              .where((row) => _isReviewableStatus(row.enrichmentStatus))
              .where((row) => row.mastery != MasteryLevel.newWord.index)
              .where((row) => row.mastery != MasteryLevel.mastered.index)
              .where(_isDifficultRow)
              .toList()
            ..sort(_compareDifficultRows);
      return candidates.map(_rowToEntry).toList();
    });
  }

  Stream<DashboardStats> watchDashboardStats() {
    final userId = _requireUserId();
    return database.watchAllWords(userId).asyncMap((rows) async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final dueToday = rows
          .where((row) => _isReviewableStatus(row.enrichmentStatus))
          .where((row) => row.mastery != MasteryLevel.newWord.index)
          .where((row) => row.mastery != MasteryLevel.mastered.index)
          .where((row) => !row.dueAt.isAfter(now))
          .length;
      final queued = rows
          .where((row) => _isAiQueueStatus(row.enrichmentStatus))
          .length;
      final difficult = rows
          .where((row) => _isReviewableStatus(row.enrichmentStatus))
          .where((row) => row.mastery != MasteryLevel.newWord.index)
          .where((row) => row.mastery != MasteryLevel.mastered.index)
          .where(_isDifficultRow)
          .length;
      final reviewed = rows.where((row) => row.reviewCount > 0).length;
      final reviewedToday = await database.countReviewLogsSince(userId, today);
      final pendingSync = await database.countPendingSync(userId);
      return DashboardStats(
        totalWords: rows.length,
        dueToday: dueToday,
        queuedForAi: queued,
        difficultWords: difficult,
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
    final existing = _syncInFlight;
    if (existing != null) {
      return existing;
    }
    final task = _runSyncNow();
    _syncInFlight = task;
    return task.whenComplete(() {
      if (identical(_syncInFlight, task)) {
        _syncInFlight = null;
      }
    });
  }

  Future<SyncResult> _runSyncNow() async {
    final service =
        _syncService ??
        SupabaseSyncService(database: database, preferences: preferences);
    await _emitSyncState(SyncPhase.syncing, message: '正在同步云端词库和复习记录。');
    try {
      final result = await service.syncNow(
        userId: _requireUserId(),
        onProgress: (progress) => _emitSyncState(
          SyncPhase.syncing,
          message: progress.message,
          progressValue: progress.value,
          progressLabel: _syncProgressLabel(progress),
        ),
      );
      if (result.success) {
        await preferences.saveLastSyncedAt(DateTime.now());
      }
      await _recordSyncLog(result);
      await _emitSyncState(
        result.success ? SyncPhase.idle : SyncPhase.failed,
        message: result.message,
        forcePendingCount: true,
      );
      if (!_disposed) {
        notifyListeners();
      }
      return result;
    } on Object catch (error) {
      final message = '同步失败：$error';
      final pending = await database.countPendingSync(_requireUserId());
      await _recordSyncLog(
        SyncResult(
          success: false,
          message: message,
          pushed: 0,
          pulled: 0,
          pendingChanges: pending,
        ),
      );
      await _emitSyncState(SyncPhase.failed, message: message);
      if (!_disposed) {
        notifyListeners();
      }
      return SyncResult(
        success: false,
        message: message,
        pushed: 0,
        pulled: 0,
        pendingChanges: pending,
      );
    }
  }

  Future<void> _recordSyncLog(SyncResult result) async {
    final logs = await getSyncLogs();
    final next = [
      SyncLogEntry(
        createdAt: DateTime.now(),
        success: result.success,
        message: result.message,
        pushed: result.pushed,
        pulled: result.pulled,
        pendingChanges: result.pendingChanges,
      ),
      ...logs,
    ];
    await preferences.saveSyncEventLog([
      for (final log in next.take(20)) jsonEncode(log.toJson()),
    ]);
  }

  Future<int> countLegacyWords() {
    return database.countLegacyWords();
  }

  List<WordBookDefinition> getWordBooks() => wordBookCatalog;

  Future<List<WordBookStats>> getWordBookStats() async {
    final dictionary = await _loadDictionary();
    final words = await database.getAllWords(_requireUserId());
    final disabledBooks = await preferences.getDisabledWordBooks();

    return [
      for (final book in wordBookCatalog)
        () {
          final imported = words
              .where((row) => row.sourceType == 'book')
              .where((row) => row.bookKey.toLowerCase() == book.key)
              .toList();
          return WordBookStats(
            book: book,
            totalDictionaryWords: dictionary.values
                .where((entry) => book.matchesTags(entry.tags))
                .length,
            importedWords: imported.length,
            newWords: imported
                .where((row) => row.mastery == MasteryLevel.newWord.index)
                .length,
            learningWords: imported
                .where((row) => row.mastery == MasteryLevel.learning.index)
                .length,
            familiarWords: imported
                .where((row) => row.mastery == MasteryLevel.familiar.index)
                .length,
            masteredWords: imported
                .where((row) => row.mastery == MasteryLevel.mastered.index)
                .length,
            enabled: !disabledBooks.contains(book.key),
          );
        }(),
    ];
  }

  Future<List<WordBookEntryProgress>> getWordBookEntryProgress(
    String bookKey,
  ) async {
    final book = findWordBook(bookKey);
    if (book == null) {
      return const [];
    }

    final dictionary = await _loadDictionary();
    final importedRows = {
      for (final row in await database.getAllWords(_requireUserId()))
        if (row.sourceType == 'book' && row.bookKey == book.key)
          row.word.toLowerCase(): row,
    };
    final entries =
        dictionary.values
            .where((entry) => book.matchesTags(entry.tags))
            .toList()
          ..sort((a, b) => a.word.compareTo(b.word));

    return [
      for (final entry in entries)
        () {
          final row = importedRows[entry.word.toLowerCase()];
          final mastery = row == null
              ? null
              : MasteryLevel.values[row.mastery
                    .clamp(0, MasteryLevel.values.length - 1)
                    .toInt()];
          return WordBookEntryProgress(
            word: entry.word,
            chineseMeaning: row == null
                ? _normalizeText(entry.chineseMeaning)
                : _normalizeText(row.chineseMeaning),
            imported: row != null,
            mastery: mastery,
            reviewCount: row?.reviewCount ?? 0,
            dueLabel: row == null ? '未导入' : _dueLabel(row.dueAt),
            enrichmentStatus: row?.enrichmentStatus ?? 'not_imported',
          );
        }(),
    ];
  }

  Future<Set<String>> getDisabledWordBooks() {
    return preferences.getDisabledWordBooks();
  }

  Future<void> setWordBookEnabled(String bookKey, bool enabled) async {
    final disabled = await preferences.getDisabledWordBooks();
    final normalized = bookKey.trim().toLowerCase();
    if (enabled) {
      disabled.remove(normalized);
    } else {
      disabled.add(normalized);
    }
    await preferences.saveDisabledWordBooks(disabled);
    notifyListeners();
  }

  Future<int> countTomorrowDueWords() async {
    final userId = _requireUserId();
    final now = DateTime.now();
    final tomorrowEnd = DateTime(now.year, now.month, now.day + 2);
    final rows = await database.getAllWords(userId);
    return rows
        .where((row) => _isReviewableStatus(row.enrichmentStatus))
        .where((row) => row.mastery != MasteryLevel.newWord.index)
        .where((row) => row.mastery != MasteryLevel.mastered.index)
        .where((row) => row.dueAt.isBefore(tomorrowEnd))
        .length;
  }

  Future<void> claimLegacyDataForActiveUser() async {
    await database.claimLegacyData(_requireUserId(), DateTime.now());
    await _emitSyncState(SyncPhase.idle, message: '本地词库已绑定到当前账号，等待同步到云端。');
    notifyListeners();
  }

  Future<StudyPlan> getStudyPlan() async {
    final examDate = await preferences.getExamDate();
    final systemReviewCount = await _countSystemReviewWords();
    return StudyPlan(
      dailyNewWords: await preferences.getDailyNewWords(),
      dailyReviewLimit: systemReviewCount,
      examDateLabel: _formatExamDate(examDate),
      todayNewDone: 0,
      todayReviewDone: 0,
      streakDays: 0,
    );
  }

  Future<void> saveStudyPlan({
    required int dailyNewWords,
    int? dailyReviewLimit,
    required DateTime? examDate,
  }) async {
    final reviewLimit =
        dailyReviewLimit ?? await preferences.getDailyReviewLimit();
    await preferences.saveStudySettings(
      dailyNewWords: dailyNewWords,
      dailyReviewLimit: reviewLimit,
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

  Stream<StudyDashboard> watchStudyDashboard() {
    final userId = _requireUserId();
    return database.watchAllWords(userId).asyncMap((rows) async {
      final now = DateTime.now();
      final today = _dayStart(now);
      final start30 = today.subtract(const Duration(days: 29));
      final logs = await database.getReviewLogsSince(userId, start30);
      final activeDays = <DateTime>{};
      for (final row in rows) {
        final day = _dayStart(row.createdAt);
        if (!day.isBefore(start30)) {
          activeDays.add(day);
        }
      }
      for (final log in logs) {
        activeDays.add(_dayStart(log.reviewedAt));
      }

      var streak = 0;
      for (var cursor = today; activeDays.contains(cursor);) {
        streak += 1;
        cursor = cursor.subtract(const Duration(days: 1));
      }

      final tomorrowStart = today.add(const Duration(days: 1));
      final tomorrowEnd = today.add(const Duration(days: 2));
      final reviewableRows = rows
          .where((row) => _isReviewableStatus(row.enrichmentStatus))
          .toList();
      final tomorrowReview = reviewableRows
          .where((row) => row.mastery != MasteryLevel.newWord.index)
          .where((row) => row.mastery != MasteryLevel.mastered.index)
          .where((row) => !row.dueAt.isBefore(tomorrowStart))
          .where((row) => row.dueAt.isBefore(tomorrowEnd))
          .length;
      final difficult = reviewableRows
          .where((row) => row.mastery != MasteryLevel.newWord.index)
          .where((row) => row.mastery != MasteryLevel.mastered.index)
          .where(_isDifficultRow)
          .length;

      return StudyDashboard(
        streakDays: streak,
        activeRate7: _activeRate(activeDays, today, 7),
        activeRate30: _activeRate(activeDays, today, 30),
        tomorrowReviewWords: tomorrowReview,
        difficultWords: difficult,
        reviewableWords: reviewableRows.length,
      );
    });
  }

  double _activeRate(Set<DateTime> activeDays, DateTime today, int days) {
    if (days <= 0) {
      return 0;
    }
    var active = 0;
    for (var i = 0; i < days; i++) {
      if (activeDays.contains(today.subtract(Duration(days: i)))) {
        active += 1;
      }
    }
    return active / days;
  }

  String _requireUserId() {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      throw StateError('AppStore has no active user.');
    }
    return userId;
  }

  String _localWordId(
    String word, {
    String sourceType = 'personal',
    String bookKey = '',
  }) {
    final normalized = word.trim().toLowerCase();
    final normalizedBookKey = bookKey.trim().toLowerCase();
    return '${_requireUserId()}:$sourceType:$normalizedBookKey:$normalized';
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
    final existingWords = (await database.getAllWords(_requireUserId()))
        .where((row) => row.sourceType == 'personal')
        .map((row) => row.word.toLowerCase())
        .toSet();
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
        await database.upsertWord(
          _dictionaryCompanion(entry, now, sourceType: 'personal'),
        );
        dictionaryMatched += 1;
      } else {
        await database.upsertWord(
          _placeholderCompanion(
            word,
            now,
            sourceType: 'personal',
            bookKey: '',
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

  Future<WordBookImportResult> importWordBook(String bookKey) async {
    final book = findWordBook(bookKey);
    if (book == null) {
      throw ArgumentError.value(bookKey, 'bookKey', 'Unknown word book.');
    }

    final dictionary = await _loadDictionary();
    final entries =
        dictionary.values
            .where((entry) => book.matchesTags(entry.tags))
            .toList()
          ..sort((a, b) => a.word.compareTo(b.word));
    final existingKeys = <String>{
      for (final row in await database.getAllWords(_requireUserId()))
        if (row.sourceType == 'book' && row.bookKey == book.key)
          row.word.toLowerCase(),
    };
    final dailyNewWords = await preferences.getDailyNewWords();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var added = 0;
    var skipped = 0;
    var scheduledLater = 0;

    for (final entry in entries) {
      final normalized = entry.word.toLowerCase();
      if (existingKeys.contains(normalized)) {
        skipped += 1;
        continue;
      }
      final dueAt = _bookSeedDueDate(today, added, dailyNewWords);
      if (dueAt.isAfter(today)) {
        scheduledLater += 1;
      }
      await database.upsertWord(
        _bookCompanion(entry, dueAt, bookKey: book.key),
      );
      existingKeys.add(normalized);
      added += 1;
    }

    notifyListeners();
    return WordBookImportResult(
      book: book,
      added: added,
      skipped: skipped,
      scheduledLater: scheduledLater,
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

  Future<BatchEditResult> queueManyForAi(List<String> wordIds) async {
    final rows = await database.getWordsByIds(_requireUserId(), wordIds);
    var changed = 0;
    var skipped = wordIds.toSet().length - rows.length;
    for (final row in rows) {
      if (row.enrichmentStatus == 'queued_ai') {
        skipped += 1;
        continue;
      }
      await database.updateEnrichmentStatus(
        userId: _requireUserId(),
        wordId: row.id,
        status: 'queued_ai',
        updatedAt: DateTime.now(),
      );
      changed += 1;
    }
    notifyListeners();
    return BatchEditResult(
      changed: changed,
      skipped: skipped,
      message: '已加入 AI 补全队列：$changed 个，跳过 $skipped 个。',
    );
  }

  Future<BatchEditResult> addTagsToWords(
    List<String> wordIds,
    String rawTags,
  ) async {
    final tagsToAdd = _splitTextList(rawTags);
    if (tagsToAdd.isEmpty) {
      return const BatchEditResult(
        changed: 0,
        skipped: 0,
        message: '没有输入可添加的标签。',
      );
    }
    final rows = await database.getWordsByIds(_requireUserId(), wordIds);
    var changed = 0;
    var skipped = wordIds.toSet().length - rows.length;
    final now = DateTime.now();
    for (final row in rows) {
      final nextTags = <String>{
        ..._decodeStringList(row.tagsJson),
        ...tagsToAdd,
      }.map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
      final previousCount = _decodeStringList(row.tagsJson).toSet().length;
      if (nextTags.length == previousCount) {
        skipped += 1;
        continue;
      }
      await database.updateWordTags(
        userId: _requireUserId(),
        wordId: row.id,
        tagsJson: jsonEncode(nextTags),
        updatedAt: now,
      );
      changed += 1;
    }
    notifyListeners();
    return BatchEditResult(
      changed: changed,
      skipped: skipped,
      message: '标签已添加到 $changed 个单词，跳过 $skipped 个。',
    );
  }

  Future<BatchEditResult> markWordsDifficult(List<String> wordIds) async {
    final ids = wordIds.toSet().toList();
    final changed = await database.markWordsDifficultByIds(
      userId: _requireUserId(),
      ids: ids,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
    return BatchEditResult(
      changed: changed,
      skipped: ids.length - changed,
      message: '已标记困难词：$changed 个。',
    );
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

  Future<String> getApiBaseUrl() => preferences.getApiBaseUrl();

  Future<void> saveApiBaseUrl(String value) =>
      preferences.saveApiBaseUrl(value);

  Future<String> getModel() => preferences.getModel();

  Future<void> saveModel(String value) => preferences.saveModel(value);

  Future<DateTime?> getLastBackupAt() => preferences.getLastBackupAt();

  Future<void> saveLastBackupAt(DateTime value) =>
      preferences.saveLastBackupAt(value);

  Future<List<SyncLogEntry>> getSyncLogs() async {
    final raw = await preferences.getSyncEventLog();
    return raw
        .map((item) {
          try {
            final decoded = jsonDecode(item);
            if (decoded is Map<String, dynamic>) {
              return SyncLogEntry.fromJson(decoded);
            }
          } on Object {
            // Ignore corrupted local preference entries.
          }
          return null;
        })
        .whereType<SyncLogEntry>()
        .toList();
  }

  Future<String> buildDiagnosticReport() async {
    final userId = _requireUserId();
    final words = await database.getAllWords(userId);
    final stats = await watchDashboardStats().first;
    final syncLogs = await getSyncLogs();
    final plan = await getStudyPlan();
    final supabaseSignedIn = _isSupabaseSignedIn();
    final statusCounts = <String, int>{};
    for (final row in words) {
      statusCounts[row.enrichmentStatus] =
          (statusCounts[row.enrichmentStatus] ?? 0) + 1;
    }
    final payload = {
      'generatedAt': DateTime.now().toIso8601String(),
      'activeUserHash': userId.hashCode.toString(),
      'database': {
        'words': stats.totalWords,
        'dueToday': stats.dueToday,
        'reviewedToday': stats.reviewedToday,
        'queuedForAi': stats.queuedForAi,
        'difficultWords': stats.difficultWords,
        'pendingSync': stats.pendingSync,
        'enrichmentStatusCounts': statusCounts,
      },
      'studyPlan': {
        'dailyNewWords': plan.dailyNewWords,
        'systemReviewWords': plan.dailyReviewLimit,
        'examDate': plan.examDateLabel,
      },
      'settings': {
        'hasApiBaseUrl': (await getApiBaseUrl()).trim().isNotEmpty,
        'hasApiKey': (await getApiKey()).trim().isNotEmpty,
        'model': await getModel(),
        'supabaseRuntimeConfigured':
            SupabaseConfig.url.isNotEmpty && SupabaseConfig.anonKey.isNotEmpty,
        'supabaseSignedIn': supabaseSignedIn,
      },
      'recentSyncLogs': [for (final log in syncLogs.take(5)) log.toJson()],
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  bool _isSupabaseSignedIn() {
    try {
      return Supabase.instance.client.auth.currentSession != null;
    } on Object {
      return false;
    }
  }

  Future<AiBatchResult> enrichQueuedAiWords({int limit = 10}) async {
    final apiBaseUrl = await getApiBaseUrl();
    final apiKey = await getApiKey();
    if (apiBaseUrl.trim().isEmpty) {
      return const AiBatchResult(
        success: 0,
        needsReview: 0,
        failed: 0,
        message: '请先在设置页填写接口地址。',
      );
    }
    if (apiKey.trim().isEmpty) {
      return const AiBatchResult(
        success: 0,
        needsReview: 0,
        failed: 0,
        message: '请先在设置页保存 API Key。',
      );
    }

    final model = await getModel();
    if (model.trim().isEmpty) {
      return const AiBatchResult(
        success: 0,
        needsReview: 0,
        failed: 0,
        message: '请先在设置页选择模型。',
      );
    }

    final words = (await database.getAllWords(_requireUserId()))
        .where((row) => _isAiQueueStatus(row.enrichmentStatus))
        .take(limit)
        .toList();
    if (words.isEmpty) {
      return const AiBatchResult(
        success: 0,
        needsReview: 0,
        failed: 0,
        message: '没有待 AI 补全的单词。',
      );
    }

    var success = 0;
    var needsReview = 0;
    var failed = 0;
    String? firstError;
    for (final word in words) {
      try {
        final data = await _enricher.enrich(
          apiBaseUrl: apiBaseUrl,
          apiKey: apiKey,
          model: model,
          word: word.word,
        );
        final quality = data.quality;
        final isAccepted = quality.isAcceptable;
        if (!isAccepted) {
          firstError ??= quality.summary;
        }
        await database.updateAiEnrichment(
          userId: _requireUserId(),
          wordId: word.id,
          chineseMeaning: _preferAiText(
            data.chineseMeaning,
            word.chineseMeaning,
          ),
          englishMeaning: _preferAiText(
            data.englishMeaning,
            word.englishMeaning,
          ),
          greFocus: _preferAiText(data.greFocus, word.greFocus),
          rootsJson: jsonEncode([
            for (final root
                in data.roots.isEmpty
                    ? _decodeList(
                        word.rootsJson,
                      ).whereType<Map<String, dynamic>>().map(
                        (item) => RootPart(
                          part: item['part']?.toString() ?? '',
                          meaning: item['meaning']?.toString() ?? '',
                        ),
                      )
                    : data.roots)
              {'part': root.part, 'meaning': root.meaning},
          ]),
          synonymsJson: jsonEncode(
            data.synonyms.isEmpty
                ? _decodeStringList(word.synonymsJson)
                : data.synonyms,
          ),
          antonymsJson: jsonEncode(
            data.antonyms.isEmpty
                ? _decodeStringList(word.antonymsJson)
                : data.antonyms,
          ),
          example: _preferAiText(data.example, word.example),
          memoryTip: _preferAiText(data.memoryTip, word.memoryTip),
          tagsJson: jsonEncode(
            _aiQualityTags(
              existingTagsJson: word.tagsJson,
              aiTags: data.tags,
              quality: quality,
              needsReview: !isAccepted,
            ),
          ),
          enrichmentStatus: isAccepted ? 'ai' : 'ai_review',
          updatedAt: DateTime.now(),
        );
        if (isAccepted) {
          success += 1;
        } else {
          needsReview += 1;
        }
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
      needsReview: needsReview,
      failed: failed,
      message:
          'AI 补全完成：成功 $success 个，需复核 $needsReview 个，失败 $failed 个。'
          '${firstError == null ? '' : ' 首个错误：$firstError'}',
    );
  }

  String _preferAiText(String aiValue, String currentValue) {
    final trimmed = aiValue.trim();
    return trimmed.isEmpty ? currentValue : trimmed;
  }

  List<String> _aiQualityTags({
    required String existingTagsJson,
    required List<String> aiTags,
    required AiContentQuality quality,
    required bool needsReview,
  }) {
    final existing = _decodeStringList(existingTagsJson)
        .where((tag) => !tag.startsWith('质量 '))
        .where((tag) => !tag.startsWith('缺 '))
        .where((tag) => tag != 'AI 待复核')
        .where((tag) => tag != 'AI 补全')
        .toList();
    final tags = <String>[
      needsReview ? 'AI 待复核' : 'AI 补全',
      '质量 ${quality.score}',
      if (quality.missingRequired.isNotEmpty)
        '缺 ${quality.missingRequired.take(2).join('/')}',
      ...aiTags,
      ...existing,
    ];
    return tags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .take(8)
        .toList();
  }

  bool _isAiQueueStatus(String status) {
    return status == 'queued_ai' || status == 'ai_review';
  }

  bool _isReviewableStatus(String status) {
    return status == 'dictionary' || status == 'ai' || status == 'ready';
  }

  Future<void> recordReview(
    WordEntry word,
    ReviewRating rating, {
    bool isNewWord = false,
  }) async {
    final now = DateTime.now();
    final reviewCount = word.reviewCount + 1;
    final lapseCount = rating == ReviewRating.forgot
        ? word.lapseCount + 1
        : word.lapseCount;
    final schedule = isNewWord && rating == ReviewRating.known
        ? _Sm2Schedule(
            dueAt: now.add(const Duration(days: 36500)),
            easeFactor: word.easeFactor,
            intervalDays: 36500,
          )
        : _nextSm2Schedule(
            now: now,
            rating: rating,
            reviewCount: reviewCount,
            previousEaseFactor: word.easeFactor,
            previousIntervalDays: word.intervalDays,
          );
    final mastery = isNewWord && rating == ReviewRating.known
        ? MasteryLevel.mastered
        : _nextMastery(
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

  Future<void> completeNewWord(
    WordEntry word, {
    required bool firstSightKnown,
  }) async {
    final now = DateTime.now();
    final reviewCount = word.reviewCount + 1;
    final dueAt = now.add(const Duration(days: 36500));
    await database.addReviewLog(
      userId: _requireUserId(),
      wordId: word.id,
      rating: firstSightKnown ? 'first_sight_known' : 'new_word_mastered',
      reviewedAt: now,
    );
    await database.updateReviewState(
      userId: _requireUserId(),
      wordId: word.id,
      mastery: MasteryLevel.mastered.index,
      dueAt: dueAt,
      reviewCount: reviewCount,
      lapseCount: word.lapseCount,
      easeFactor: word.easeFactor,
      intervalDays: 36500,
      updatedAt: now,
    );
    notifyListeners();
  }

  Future<void> disposeStore() async {
    _disposed = true;
    await _syncStateController.close();
    await database.close();
  }

  Future<SyncState> _withLastSyncedAt(SyncState state) async {
    return SyncState(
      phase: state.phase,
      pendingChanges: state.pendingChanges,
      message: state.message,
      lastSyncedAt: await preferences.getLastSyncedAt(),
      progressValue: state.progressValue,
      progressLabel: state.progressLabel,
    );
  }

  Future<void> _emitSyncState(
    SyncPhase phase, {
    required String message,
    double? progressValue,
    String? progressLabel,
    bool forcePendingCount = false,
  }) async {
    if (_disposed) {
      return;
    }
    final state = SyncState(
      phase: phase,
      pendingChanges: await _pendingSyncCount(force: forcePendingCount),
      message: message,
      lastSyncedAt: await preferences.getLastSyncedAt(),
      progressValue: progressValue,
      progressLabel: progressLabel,
    );
    _lastSyncState = state;
    if (!_syncStateController.isClosed) {
      _syncStateController.add(state);
    }
  }

  Future<int> _pendingSyncCount({bool force = false}) async {
    final now = DateTime.now();
    final cachedAt = _pendingSyncCountCachedAt;
    final cached = _pendingSyncCountCache;
    if (!force &&
        cachedAt != null &&
        cached != null &&
        now.difference(cachedAt) < const Duration(milliseconds: 700)) {
      return cached;
    }
    final count = await database.countPendingSync(_requireUserId());
    _pendingSyncCountCachedAt = now;
    _pendingSyncCountCache = count;
    return count;
  }

  String? _syncProgressLabel(SyncProgress progress) {
    final completed = progress.completed;
    final total = progress.total;
    if (completed == null || total == null || total <= 0) {
      return null;
    }
    return '$completed / $total';
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
            'sourceType': row.sourceType,
            'bookKey': row.bookKey,
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

  BackupPreview previewBackupJson(String rawJson) {
    final decoded = _decodeBackupPayload(rawJson);
    final words = decoded['words'] as List<dynamic>? ?? const [];
    final logs = decoded['reviewLogs'] as List<dynamic>? ?? const [];
    var personalWords = 0;
    var bookWords = 0;
    var aiWords = 0;
    var dictionaryWords = 0;
    for (final item in words.whereType<Map<String, dynamic>>()) {
      final sourceType = item['sourceType']?.toString() ?? 'personal';
      if (sourceType == 'book') {
        bookWords += 1;
      } else {
        personalWords += 1;
      }
      final enrichmentStatus = item['enrichmentStatus']?.toString();
      if (enrichmentStatus == 'ai') {
        aiWords += 1;
      } else if (enrichmentStatus == 'dictionary') {
        dictionaryWords += 1;
      }
    }
    return BackupPreview(
      version: (decoded['version'] as num?)?.toInt() ?? 0,
      exportedAt: _parseDate(decoded['exportedAt']),
      userId: decoded['userId']?.toString() ?? '',
      wordCount: words.whereType<Map<String, dynamic>>().length,
      reviewLogCount: logs.whereType<Map<String, dynamic>>().length,
      personalWordCount: personalWords,
      bookWordCount: bookWords,
      aiWordCount: aiWords,
      dictionaryWordCount: dictionaryWords,
    );
  }

  Future<BackupImportResult> importBackupJson(
    String rawJson, {
    bool replace = false,
  }) async {
    final decoded = _decodeBackupPayload(rawJson);
    final words = decoded['words'] as List<dynamic>? ?? const [];
    final logs = decoded['reviewLogs'] as List<dynamic>? ?? const [];
    var importedWords = 0;
    var importedLogs = 0;
    if (replace) {
      await database.clearAllData(_requireUserId());
    }
    for (final item in words.whereType<Map<String, dynamic>>()) {
      final word = item['word']?.toString() ?? '';
      if (word.isEmpty) {
        continue;
      }
      final importedId = item['id']?.toString() ?? '';
      final sourceType = item['sourceType']?.toString() ?? 'personal';
      final bookKey = item['bookKey']?.toString() ?? '';
      final wordId = importedId.startsWith('${_requireUserId()}:')
          ? importedId
          : _localWordId(word, sourceType: sourceType, bookKey: bookKey);
      await database.upsertWord(
        WordCardsCompanion.insert(
          id: wordId,
          userId: Value(_requireUserId()),
          remoteId: Value(item['remoteId']?.toString()),
          syncStatus: Value(item['syncStatus']?.toString() ?? 'dirty'),
          deletedAt: Value(_parseDate(item['deletedAt'])),
          word: word,
          sourceType: Value(sourceType),
          bookKey: Value(bookKey),
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
      importedWords += 1;
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
      importedLogs += 1;
    }
    notifyListeners();
    return BackupImportResult(
      importedWords: importedWords,
      importedReviewLogs: importedLogs,
      replaced: replace,
    );
  }

  static Map<String, dynamic> _decodeBackupPayload(String rawJson) {
    final decoded = jsonDecode(rawJson);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('备份 JSON 必须是对象格式。');
    }
    final words = decoded['words'];
    final logs = decoded['reviewLogs'];
    if (words != null && words is! List<dynamic>) {
      throw const FormatException('备份 JSON 的 words 字段格式不正确。');
    }
    if (logs != null && logs is! List<dynamic>) {
      throw const FormatException('备份 JSON 的 reviewLogs 字段格式不正确。');
    }
    return decoded;
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
    for (final seed in MockRepository.words) {
      final row = await database.getWordByText(_requireUserId(), seed.word);
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
      id:
          idOverride ??
          _localWordId(
            entry.word,
            sourceType: entry.sourceType,
            bookKey: entry.bookKey,
          ),
      userId: Value(_requireUserId()),
      word: entry.word,
      sourceType: Value(entry.sourceType),
      bookKey: Value(entry.bookKey),
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
    DateTime now, {
    required String sourceType,
    String bookKey = '',
  }) {
    final content = _dictionaryContent(entry);

    return WordCardsCompanion.insert(
      id: _localWordId(entry.word, sourceType: sourceType, bookKey: bookKey),
      userId: Value(_requireUserId()),
      word: entry.word,
      sourceType: Value(sourceType),
      bookKey: Value(bookKey),
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

  WordCardsCompanion _bookCompanion(
    BasicDictionaryEntry entry,
    DateTime dueAt, {
    required String bookKey,
  }) {
    final now = DateTime.now();
    return _dictionaryCompanion(
      entry,
      dueAt,
      sourceType: 'book',
      bookKey: bookKey,
    ).copyWith(
      dueAt: Value(dueAt),
      syncStatus: const Value('synced'),
      createdAt: Value(now),
      updatedAt: Value(now),
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
    required String sourceType,
    required String bookKey,
    required String status,
  }) {
    return WordCardsCompanion.insert(
      id: _localWordId(word, sourceType: sourceType, bookKey: bookKey),
      userId: Value(_requireUserId()),
      word: word,
      sourceType: Value(sourceType),
      bookKey: Value(bookKey),
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

  DateTime _bookSeedDueDate(DateTime dayStart, int index, int dailyNewWords) {
    final perDay = dailyNewWords <= 0 ? 30 : dailyNewWords;
    final offsetDays = index ~/ perDay;
    return DateTime(dayStart.year, dayStart.month, dayStart.day + offsetDays);
  }

  String _dailySeed(DateTime value, String userId) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$userId:${value.year}-$month-$day';
  }

  int _stableDailyRank(String seed, String value) {
    var hash = 0x811c9dc5;
    final text = '$seed:$value';
    for (final unit in text.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }

  Future<int> _countSystemReviewWords() async {
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return 0;
    }
    final now = DateTime.now();
    final rows = await database.getAllWords(userId);
    return rows
        .where((row) => _isReviewableStatus(row.enrichmentStatus))
        .where((row) => row.mastery != MasteryLevel.newWord.index)
        .where((row) => row.mastery != MasteryLevel.mastered.index)
        .where((row) => !row.dueAt.isAfter(now))
        .length;
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
      sourceType: row.sourceType,
      bookKey: row.bookKey,
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
    return status == 'queued' ||
        status == 'queued_ai' ||
        status == 'ai_review' ||
        status == 'failed';
  }

  bool _isDifficultRow(WordCard row) {
    return row.lapseCount > 0 ||
        row.easeFactor <= 220 ||
        (row.reviewCount >= 2 && row.mastery == MasteryLevel.learning.index);
  }

  int _compareDifficultRows(WordCard a, WordCard b) {
    final lapseCompare = b.lapseCount.compareTo(a.lapseCount);
    if (lapseCompare != 0) {
      return lapseCompare;
    }
    final easeCompare = a.easeFactor.compareTo(b.easeFactor);
    if (easeCompare != 0) {
      return easeCompare;
    }
    final dueCompare = a.dueAt.compareTo(b.dueAt);
    if (dueCompare != 0) {
      return dueCompare;
    }
    return a.word.compareTo(b.word);
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
