import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_database.dart';
import 'app_preferences.dart';

enum SyncPhase { idle, syncing, notConfigured, failed }

typedef SyncProgressCallback = Future<void> Function(SyncProgress progress);

class SyncProgress {
  const SyncProgress({required this.message, this.completed, this.total});

  final String message;
  final int? completed;
  final int? total;

  double? get value {
    final totalValue = total;
    final completedValue = completed;
    if (totalValue == null || completedValue == null || totalValue <= 0) {
      return null;
    }
    return (completedValue / totalValue).clamp(0, 1);
  }
}

class SyncState {
  const SyncState({
    required this.phase,
    required this.pendingChanges,
    required this.message,
    this.lastSyncedAt,
    this.progressValue,
    this.progressLabel,
  });

  final SyncPhase phase;
  final int pendingChanges;
  final String message;
  final DateTime? lastSyncedAt;
  final double? progressValue;
  final String? progressLabel;

  bool get canSync => phase != SyncPhase.syncing;
}

class SyncResult {
  const SyncResult({
    required this.success,
    required this.message,
    required this.pushed,
    required this.pulled,
    required this.pendingChanges,
  });

  final bool success;
  final String message;
  final int pushed;
  final int pulled;
  final int pendingChanges;
}

abstract class SyncService {
  Stream<SyncState> watchSyncStatus({required String userId});

  Future<SyncResult> pushLocalChanges({
    required String userId,
    SyncProgressCallback? onProgress,
  });

  Future<SyncResult> pullRemoteChanges({
    required String userId,
    bool full = false,
    SyncProgressCallback? onProgress,
  });

  Future<SyncResult> syncNow({
    required String userId,
    SyncProgressCallback? onProgress,
  });
}

class PlaceholderSyncService implements SyncService {
  const PlaceholderSyncService({
    required this.database,
    required this.preferences,
  });

  final AppDatabase database;
  final AppPreferences preferences;

  @override
  Stream<SyncState> watchSyncStatus({required String userId}) async* {
    yield await _buildState(userId);
  }

  @override
  Future<SyncResult> pushLocalChanges({
    required String userId,
    SyncProgressCallback? onProgress,
  }) async {
    return _notConfiguredResult(userId);
  }

  @override
  Future<SyncResult> pullRemoteChanges({
    required String userId,
    bool full = false,
    SyncProgressCallback? onProgress,
  }) async {
    return _notConfiguredResult(userId);
  }

  @override
  Future<SyncResult> syncNow({
    required String userId,
    SyncProgressCallback? onProgress,
  }) async {
    return _notConfiguredResult(userId);
  }

  Future<SyncState> _buildState(String userId) async {
    final pending = await database.countPendingSync(userId);
    final configured = await _isConfigured();
    if (!configured) {
      return SyncState(
        phase: SyncPhase.notConfigured,
        pendingChanges: pending,
        message: 'Supabase 尚未配置，本地变更会先保留。',
      );
    }
    return SyncState(
      phase: SyncPhase.idle,
      pendingChanges: pending,
      message: pending == 0 ? '本地无待同步变更。' : '有 $pending 条本地变更等待同步。',
    );
  }

  Future<SyncResult> _notConfiguredResult(String userId) async {
    final pending = await database.countPendingSync(userId);
    return SyncResult(
      success: false,
      message: 'Supabase 尚未配置。先完成项目 URL 和 anon key 后即可接入真实同步。',
      pushed: 0,
      pulled: 0,
      pendingChanges: pending,
    );
  }

  Future<bool> _isConfigured() async {
    final url = await preferences.getSupabaseUrl();
    final anonKey = await preferences.getSupabaseAnonKey();
    return url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
  }
}

class SupabaseSyncService implements SyncService {
  static const _wordBatchSize = 200;
  static const _syncOverlap = Duration(minutes: 2);

  SupabaseSyncService({
    required this.database,
    this.preferences,
    SupabaseClient? client,
  }) : _client = client ?? Supabase.instance.client;

  final AppDatabase database;
  final AppPreferences? preferences;
  final SupabaseClient _client;

  @override
  Stream<SyncState> watchSyncStatus({required String userId}) async* {
    final pending = await _countPending(userId);
    final configured = _client.auth.currentSession != null;
    yield SyncState(
      phase: configured ? SyncPhase.idle : SyncPhase.notConfigured,
      pendingChanges: pending,
      message: configured
          ? (pending == 0 ? '本地无待同步变更。' : '有 $pending 条本地变更等待同步。')
          : '尚未登录 Supabase。',
    );
  }

  @override
  Future<SyncResult> pushLocalChanges({
    required String userId,
    SyncProgressCallback? onProgress,
  }) async {
    if (_client.auth.currentSession == null) {
      return _notSignedIn(userId);
    }

    final pending = await database.getPendingWordChanges(userId);
    final dirtyPersonalWords = <WordCard>[];
    final dirtyBookWords = <WordCard>[];
    var pushed = 0;
    for (final row in pending) {
      if (row.syncStatus == 'deleted') {
        if (_isBookWord(row)) {
          await _softDeleteWordProgress(row);
          await database.markLocalOnlyDeletedWordSynced(
            userId: userId,
            wordId: row.id,
          );
        } else if (row.remoteId == null || row.remoteId!.isEmpty) {
          await database.markLocalOnlyDeletedWordSynced(
            userId: userId,
            wordId: row.id,
          );
        } else {
          final deletedAt = row.deletedAt ?? DateTime.now();
          await _client
              .from('word_cards')
              .update({
                'deleted_at': deletedAt.toUtc().toIso8601String(),
                'client_updated_at': row.updatedAt.toUtc().toIso8601String(),
              })
              .eq('id', row.remoteId!);
          await database.markWordSynced(
            userId: userId,
            wordId: row.id,
            remoteId: row.remoteId!,
            updatedAt: row.updatedAt,
          );
        }
        pushed += 1;
        continue;
      }

      if (_isBookWord(row)) {
        if (_bookWordNeedsRemoteProgress(row)) {
          dirtyBookWords.add(row);
        } else {
          await database.markWordSynced(
            userId: userId,
            wordId: row.id,
            remoteId: row.remoteId ?? '',
            updatedAt: row.updatedAt,
          );
          pushed += 1;
        }
      } else {
        dirtyPersonalWords.add(row);
      }
    }

    if (pushed > 0) {
      await onProgress?.call(
        SyncProgress(message: '已处理 $pushed 条删除记录，准备上传词卡。'),
      );
    }

    pushed += await _pushWordCards(
      userId: userId,
      rows: dirtyPersonalWords,
      onProgress: onProgress,
    );
    pushed += await _pushWordProgress(
      userId: userId,
      rows: dirtyBookWords,
      onProgress: onProgress,
    );
    pushed += await _pushReviewLogs(userId, onProgress: onProgress);

    final remaining = await _countPending(userId);
    return SyncResult(
      success: true,
      message: '上传完成：$pushed 条，本地待同步 $remaining 条。',
      pushed: pushed,
      pulled: 0,
      pendingChanges: remaining,
    );
  }

  Future<int> _pushWordCards({
    required String userId,
    required List<WordCard> rows,
    SyncProgressCallback? onProgress,
  }) async {
    var pushed = 0;
    final totalBatches = (rows.length / _wordBatchSize).ceil();
    for (var start = 0; start < rows.length; start += _wordBatchSize) {
      final batch = rows.skip(start).take(_wordBatchSize).toList();
      if (batch.isEmpty) {
        continue;
      }
      final batchNumber = start ~/ _wordBatchSize + 1;
      await onProgress?.call(
        SyncProgress(
          message: '正在上传词卡批次 $batchNumber/$totalBatches（本批 ${batch.length} 个）。',
          completed: batchNumber - 1,
          total: totalBatches,
        ),
      );
      final payload = [
        for (final row in batch) _wordToRemote(row)..remove('id'),
      ];
      final remoteRows = await _client
          .from('word_cards')
          .upsert(
            payload,
            onConflict: 'user_id,language,source_type,book_key,word',
          )
          .select('id,source_type,book_key,word,updated_at');
      final remoteByKey = <String, Map<String, dynamic>>{};
      for (final item in remoteRows as List<dynamic>) {
        final map = Map<String, dynamic>.from(item as Map);
        remoteByKey[_remoteWordKey(
              sourceType: map['source_type']?.toString() ?? '',
              bookKey: map['book_key']?.toString() ?? '',
              word: map['word']?.toString() ?? '',
            )] =
            map;
      }
      for (final row in batch) {
        final remote = remoteByKey[_wordKey(row)];
        final remoteId = remote?['id']?.toString();
        if (remoteId == null || remoteId.isEmpty) {
          throw StateError('Supabase did not return word_cards.id.');
        }
        await database.markWordSynced(
          userId: userId,
          wordId: row.id,
          remoteId: remoteId,
          updatedAt: row.updatedAt,
        );
        pushed += 1;
      }
      await onProgress?.call(
        SyncProgress(
          message: '词卡批次 $batchNumber/$totalBatches 已上传，累计 $pushed 个词。',
          completed: batchNumber,
          total: totalBatches,
        ),
      );
    }
    return pushed;
  }

  Future<int> _pushWordProgress({
    required String userId,
    required List<WordCard> rows,
    SyncProgressCallback? onProgress,
  }) async {
    var pushed = 0;
    final totalBatches = (rows.length / _wordBatchSize).ceil();
    for (var start = 0; start < rows.length; start += _wordBatchSize) {
      final batch = rows.skip(start).take(_wordBatchSize).toList();
      if (batch.isEmpty) {
        continue;
      }
      final batchNumber = start ~/ _wordBatchSize + 1;
      await onProgress?.call(
        SyncProgress(
          message:
              '正在上传词书学习进度 $batchNumber/$totalBatches（本批 ${batch.length} 个）。',
          completed: batchNumber - 1,
          total: totalBatches,
        ),
      );
      final payload = [for (final row in batch) _wordProgressToRemote(row)];
      final remoteRows = await _client
          .from('word_progress')
          .upsert(payload, onConflict: 'user_id,language,book_key,word')
          .select('id,book_key,word,updated_at');
      final remoteByKey = <String, Map<String, dynamic>>{};
      for (final item in remoteRows as List<dynamic>) {
        final map = Map<String, dynamic>.from(item as Map);
        remoteByKey[_remoteWordKey(
              sourceType: 'book',
              bookKey: map['book_key']?.toString() ?? '',
              word: map['word']?.toString() ?? '',
            )] =
            map;
      }
      for (final row in batch) {
        final remote = remoteByKey[_wordKey(row)];
        final remoteId = remote?['id']?.toString();
        if (remoteId == null || remoteId.isEmpty) {
          throw StateError('Supabase did not return word_progress.id.');
        }
        await database.markWordSynced(
          userId: userId,
          wordId: row.id,
          remoteId: remoteId,
          updatedAt: row.updatedAt,
        );
        pushed += 1;
      }
      await onProgress?.call(
        SyncProgress(
          message: '词书学习进度 $batchNumber/$totalBatches 已上传，累计 $pushed 个词。',
          completed: batchNumber,
          total: totalBatches,
        ),
      );
    }
    return pushed;
  }

  Future<void> _softDeleteWordProgress(WordCard row) async {
    final deletedAt = row.deletedAt ?? DateTime.now();
    await _client.from('word_progress').upsert({
      'user_id': row.userId,
      'language': 'english',
      'book_key': row.bookKey,
      'word': row.word,
      'mastery': row.mastery,
      'due_at': row.dueAt.toUtc().toIso8601String(),
      'review_count': row.reviewCount,
      'lapse_count': row.lapseCount,
      'ease_factor': row.easeFactor,
      'interval_days': row.intervalDays,
      'client_updated_at': row.updatedAt.toUtc().toIso8601String(),
      'deleted_at': deletedAt.toUtc().toIso8601String(),
    }, onConflict: 'user_id,language,book_key,word');
  }

  bool _isBookWord(WordCard row) {
    return row.sourceType == 'book' && row.bookKey.trim().isNotEmpty;
  }

  bool _bookWordNeedsRemoteProgress(WordCard row) {
    if (row.reviewCount > 0 ||
        row.mastery > 0 ||
        row.lapseCount > 0 ||
        row.intervalDays > 0 ||
        row.note.trim().isNotEmpty ||
        row.enrichmentStatus != 'dictionary') {
      return true;
    }
    return _decodeJsonList(row.rootsJson).isNotEmpty ||
        _decodeJsonList(row.synonymsJson).isNotEmpty ||
        _decodeJsonList(row.antonymsJson).isNotEmpty ||
        row.example.trim().isNotEmpty;
  }

  String _wordKey(WordCard row) {
    return _remoteWordKey(
      sourceType: row.sourceType,
      bookKey: row.bookKey,
      word: row.word,
    );
  }

  String _remoteWordKey({
    required String sourceType,
    required String bookKey,
    required String word,
  }) {
    return jsonEncode([sourceType, bookKey, word]);
  }

  @override
  Future<SyncResult> pullRemoteChanges({
    required String userId,
    bool full = false,
    SyncProgressCallback? onProgress,
  }) async {
    if (_client.auth.currentSession == null) {
      return _notSignedIn(userId);
    }

    await onProgress?.call(const SyncProgress(message: '正在读取云端词库。'));
    final since = full ? null : await _incrementalSince();
    dynamic query = _client
        .from('word_cards')
        .select()
        .eq('user_id', userId)
        .eq('language', 'english')
        .neq('source_type', 'book');
    if (since != null) {
      query = query.gte('updated_at', since.toUtc().toIso8601String());
    }
    final remoteRows = await query as List<dynamic>;
    var pulled = 0;
    final totalRows = remoteRows.length;
    for (final item in remoteRows) {
      final map = Map<String, dynamic>.from(item as Map);
      final remoteId = map['id']?.toString() ?? '';
      final word = map['word']?.toString() ?? '';
      if (remoteId.isEmpty || word.isEmpty) {
        continue;
      }

      final local =
          await database.getWordByRemoteId(userId, remoteId) ??
          await database.getWordByIdentity(
            userId: userId,
            sourceType: map['source_type']?.toString() ?? 'personal',
            bookKey: map['book_key']?.toString() ?? '',
            word: word,
          ) ??
          await database.getWordByText(userId, word);
      if (local != null && local.syncStatus == 'dirty') {
        final remoteUpdatedAt = _parseRemoteDate(map['updated_at']);
        if (remoteUpdatedAt != null &&
            !remoteUpdatedAt.isAfter(local.updatedAt)) {
          continue;
        }
      }

      await database.upsertWord(
        _remoteToCompanion(
          userId: userId,
          localId: local?.id ?? '$userId:$word',
          map: map,
        ),
      );
      pulled += 1;
      if (pulled % 500 == 0 || pulled == totalRows) {
        await onProgress?.call(
          SyncProgress(
            message: '正在合并云端词库 $pulled/$totalRows。',
            completed: pulled,
            total: totalRows,
          ),
        );
      }
    }

    pulled += await _pullWordProgress(
      userId,
      since: since,
      onProgress: onProgress,
    );
    pulled += await _pullReviewLogs(
      userId,
      since: since,
      onProgress: onProgress,
    );

    final remaining = await _countPending(userId);
    return SyncResult(
      success: true,
      message: '拉取完成：$pulled 条，本地待同步 $remaining 条。',
      pushed: 0,
      pulled: pulled,
      pendingChanges: remaining,
    );
  }

  @override
  Future<SyncResult> syncNow({
    required String userId,
    SyncProgressCallback? onProgress,
  }) async {
    try {
      await onProgress?.call(const SyncProgress(message: '正在检查本地变更。'));
      final push = await pushLocalChanges(
        userId: userId,
        onProgress: onProgress,
      );
      if (!push.success) {
        return push;
      }
      await onProgress?.call(const SyncProgress(message: '本地上传完成，开始拉取云端数据。'));
      final pull = await pullRemoteChanges(
        userId: userId,
        onProgress: onProgress,
      );
      await onProgress?.call(const SyncProgress(message: '正在同步学习计划设置。'));
      final settings = await _syncStudySettings(userId);
      final remaining = await _countPending(userId);
      await onProgress?.call(const SyncProgress(message: '正在收尾并刷新同步状态。'));
      return SyncResult(
        success: pull.success,
        message:
            '同步完成：上传 ${push.pushed} 条，拉取 ${pull.pulled} 条，待同步 $remaining 条。',
        pushed: push.pushed + settings.pushed,
        pulled: pull.pulled + settings.pulled,
        pendingChanges: remaining,
      );
    } on AuthException catch (error) {
      return _failure(userId, _syncFailureMessage(error));
    } on PostgrestException catch (error) {
      return _failure(userId, _syncFailureMessage(error));
    } on Object catch (error) {
      return _failure(userId, '同步失败：$error');
    }
  }

  Future<int> _countPending(String userId) async {
    final localPending = await database.countPendingSync(userId);
    final settingsPending = preferences == null
        ? false
        : await preferences!.hasPendingStudySettings();
    return localPending + (settingsPending ? 1 : 0);
  }

  Future<_SettingsSyncCount> _syncStudySettings(String userId) async {
    final prefs = preferences;
    if (prefs == null) {
      return const _SettingsSyncCount();
    }

    final remoteRows = await _client
        .from('study_settings')
        .select()
        .eq('user_id', userId)
        .eq('language', 'english');
    final remote = remoteRows.isEmpty
        ? null
        : Map<String, dynamic>.from(remoteRows.first as Map);
    final localUpdatedAt = await prefs.getStudySettingsUpdatedAt();
    final remoteUpdatedAt = remote == null
        ? null
        : _parseRemoteDate(remote['client_updated_at']) ??
              _parseRemoteDate(remote['updated_at']);
    final localIsPending = await prefs.hasPendingStudySettings();

    if (remote == null || localIsPending) {
      final pushedAt = localUpdatedAt ?? DateTime.now();
      await _client
          .from('study_settings')
          .upsert(
            await _studySettingsToRemote(userId, pushedAt),
            onConflict: 'user_id,language',
          );
      await prefs.markStudySettingsSynced();
      return const _SettingsSyncCount(pushed: 1);
    }

    if (remoteUpdatedAt != null &&
        (localUpdatedAt == null || remoteUpdatedAt.isAfter(localUpdatedAt))) {
      await _saveRemoteStudySettings(remote, pendingSync: false);
      return const _SettingsSyncCount(pulled: 1);
    }
    if (await _remoteSettingsHaveMissingLocalBooks(remote)) {
      await _saveRemoteStudySettings(remote, pendingSync: false);
      return const _SettingsSyncCount(pulled: 1);
    }
    return const _SettingsSyncCount();
  }

  Future<Map<String, dynamic>> _studySettingsToRemote(
    String userId,
    DateTime updatedAt,
  ) async {
    final prefs = preferences!;
    final examDate = await prefs.getExamDate();
    final importedBooks = {
      ...await prefs.getImportedWordBooks(),
      ...await _localImportedWordBookKeys(userId),
    }.toList()..sort();
    final disabledBooks = (await prefs.getDisabledWordBooks()).toList()..sort();
    return {
      'user_id': userId,
      'language': 'english',
      'daily_new_words': await prefs.getDailyNewWords(),
      'daily_review_limit': await prefs.getDailyReviewLimit(),
      'exam_date': examDate == null ? null : _formatDateOnly(examDate),
      'settings_json': <String, dynamic>{
        'importedWordBooks': importedBooks,
        'disabledWordBooks': disabledBooks,
      },
      'client_updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': null,
    };
  }

  Future<void> _saveRemoteStudySettings(
    Map<String, dynamic> remote, {
    required bool pendingSync,
  }) async {
    final settingsJson = _settingsJson(remote['settings_json']);
    await preferences!.saveStudySettings(
      dailyNewWords: (remote['daily_new_words'] as num?)?.toInt() ?? 30,
      dailyReviewLimit: (remote['daily_review_limit'] as num?)?.toInt() ?? 80,
      examDate: _parseDateOnly(remote['exam_date']),
      updatedAt:
          _parseRemoteDate(remote['client_updated_at']) ??
          _parseRemoteDate(remote['updated_at']) ??
          DateTime.now(),
      pendingSync: pendingSync,
    );
    await preferences!.saveImportedWordBooks(
      _stringSet(settingsJson['importedWordBooks']),
    );
    await preferences!.saveDisabledWordBooks(
      _stringSet(settingsJson['disabledWordBooks']),
    );
  }

  Future<bool> _remoteSettingsHaveMissingLocalBooks(
    Map<String, dynamic> remote,
  ) async {
    final prefs = preferences;
    if (prefs == null) {
      return false;
    }
    final settingsJson = _settingsJson(remote['settings_json']);
    final remoteImported = _stringSet(settingsJson['importedWordBooks']);
    if (remoteImported.isEmpty) {
      return false;
    }
    final localImported = await prefs.getImportedWordBooks();
    return remoteImported.difference(localImported).isNotEmpty;
  }

  Future<Set<String>> _localImportedWordBookKeys(String userId) async {
    final rows = await database.getAllWords(userId);
    return {
      for (final row in rows)
        if (row.sourceType == 'book' && row.bookKey.trim().isNotEmpty)
          row.bookKey.trim().toLowerCase(),
    };
  }

  Map<String, dynamic> _settingsJson(Object? value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    if (value is String && value.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } on FormatException {
        return const <String, dynamic>{};
      }
    }
    return const <String, dynamic>{};
  }

  Set<String> _stringSet(Object? value) {
    if (value is Iterable) {
      return value
          .map((item) => item.toString().trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split(',')
          .map((item) => item.trim().toLowerCase())
          .where((item) => item.isNotEmpty)
          .toSet();
    }
    return const <String>{};
  }

  Future<int> _pushReviewLogs(
    String userId, {
    SyncProgressCallback? onProgress,
  }) async {
    final pending = await database.getPendingReviewLogChanges(userId);
    if (pending.isNotEmpty) {
      await onProgress?.call(
        SyncProgress(
          message: '正在上传复习记录 0/${pending.length}。',
          completed: 0,
          total: pending.length,
        ),
      );
    }
    var pushed = 0;
    for (final row in pending) {
      if (row.syncStatus == 'deleted') {
        if (row.remoteId == null || row.remoteId!.isEmpty) {
          await database.markLocalOnlyDeletedReviewLogSynced(
            userId: userId,
            logId: row.id,
          );
        } else {
          final deletedAt = row.deletedAt ?? DateTime.now();
          await _client
              .from('review_logs')
              .update({
                'deleted_at': deletedAt.toUtc().toIso8601String(),
                'client_updated_at': (row.updatedAt ?? deletedAt)
                    .toUtc()
                    .toIso8601String(),
              })
              .eq('id', row.remoteId!);
          await database.markReviewLogSynced(
            userId: userId,
            logId: row.id,
            remoteId: row.remoteId!,
            updatedAt: row.updatedAt ?? deletedAt,
          );
        }
        pushed += 1;
        continue;
      }

      final remote = await _client
          .from('review_logs')
          .upsert(await _reviewLogToRemote(userId, row))
          .select('id,updated_at')
          .single();
      final remoteId = remote['id']?.toString();
      if (remoteId == null || remoteId.isEmpty) {
        throw StateError('Supabase did not return review_logs.id.');
      }
      await database.markReviewLogSynced(
        userId: userId,
        logId: row.id,
        remoteId: remoteId,
        updatedAt: row.updatedAt ?? row.reviewedAt,
      );
      pushed += 1;
      if (pushed % 100 == 0 || pushed == pending.length) {
        await onProgress?.call(
          SyncProgress(
            message: '正在上传复习记录 $pushed/${pending.length}。',
            completed: pushed,
            total: pending.length,
          ),
        );
      }
    }
    return pushed;
  }

  Future<DateTime?> _incrementalSince() async {
    final lastSyncedAt = await preferences?.getLastSyncedAt();
    if (lastSyncedAt == null) {
      return null;
    }
    return lastSyncedAt.subtract(_syncOverlap);
  }

  Future<int> _pullWordProgress(
    String userId, {
    required DateTime? since,
    SyncProgressCallback? onProgress,
  }) async {
    await onProgress?.call(
      SyncProgress(
        message: since == null ? '正在读取云端词书学习进度。' : '正在读取云端增量词书学习进度。',
      ),
    );
    dynamic query = _client
        .from('word_progress')
        .select()
        .eq('user_id', userId)
        .eq('language', 'english');
    if (since != null) {
      query = query.gte('updated_at', since.toUtc().toIso8601String());
    }
    final remoteRows = await query as List<dynamic>;
    var pulled = 0;
    final totalRows = remoteRows.length;
    for (final item in remoteRows) {
      final map = Map<String, dynamic>.from(item as Map);
      final remoteId = map['id']?.toString() ?? '';
      final word = map['word']?.toString() ?? '';
      final bookKey = map['book_key']?.toString() ?? '';
      if (remoteId.isEmpty || word.isEmpty || bookKey.isEmpty) {
        continue;
      }

      final local =
          await database.getWordByRemoteId(userId, remoteId) ??
          await database.getWordByIdentity(
            userId: userId,
            sourceType: 'book',
            bookKey: bookKey,
            word: word,
          );
      if (local != null && local.syncStatus == 'dirty') {
        final remoteUpdatedAt = _parseRemoteDate(map['updated_at']);
        if (remoteUpdatedAt != null &&
            !remoteUpdatedAt.isAfter(local.updatedAt)) {
          continue;
        }
      }
      if (local == null && _parseRemoteDate(map['deleted_at']) != null) {
        continue;
      }

      await database.upsertWord(
        _progressToCompanion(userId: userId, local: local, map: map),
      );
      pulled += 1;
      if (pulled % 500 == 0 || pulled == totalRows) {
        await onProgress?.call(
          SyncProgress(
            message: '正在合并词书学习进度 $pulled/$totalRows。',
            completed: pulled,
            total: totalRows,
          ),
        );
      }
    }
    return pulled;
  }

  Future<int> _pullReviewLogs(
    String userId, {
    required DateTime? since,
    SyncProgressCallback? onProgress,
  }) async {
    await onProgress?.call(const SyncProgress(message: '正在读取云端复习记录。'));
    dynamic query = _client.from('review_logs').select().eq('user_id', userId);
    if (since != null) {
      query = query.gte('updated_at', since.toUtc().toIso8601String());
    }
    final remoteRows = await query as List<dynamic>;
    var pulled = 0;
    final totalRows = remoteRows.length;
    for (final item in remoteRows) {
      final map = Map<String, dynamic>.from(item as Map);
      final remoteId = map['id']?.toString() ?? '';
      if (remoteId.isEmpty) {
        continue;
      }

      final local = await database.getReviewLogByRemoteId(userId, remoteId);
      if (local != null && local.syncStatus == 'dirty') {
        final remoteUpdatedAt = _parseRemoteDate(map['updated_at']);
        final localUpdatedAt = local.updatedAt ?? local.reviewedAt;
        if (remoteUpdatedAt != null &&
            !remoteUpdatedAt.isAfter(localUpdatedAt)) {
          continue;
        }
      }

      final wordId = await _resolveLocalWordId(userId, map);
      if (wordId == null) {
        continue;
      }

      await database.upsertRemoteReviewLog(
        userId: userId,
        localId: local?.id,
        remoteId: remoteId,
        wordId: wordId,
        rating: map['rating']?.toString() ?? 'again',
        reviewedAt: _parseRemoteDate(map['reviewed_at']) ?? DateTime.now(),
        updatedAt: _parseRemoteDate(map['updated_at']) ?? DateTime.now(),
        deletedAt: _parseRemoteDate(map['deleted_at']),
      );
      pulled += 1;
      if (pulled % 200 == 0 || pulled == totalRows) {
        await onProgress?.call(
          SyncProgress(
            message: '正在合并复习记录 $pulled/$totalRows。',
            completed: pulled,
            total: totalRows,
          ),
        );
      }
    }
    return pulled;
  }

  Future<Map<String, dynamic>> _reviewLogToRemote(
    String userId,
    ReviewLog row,
  ) async {
    final word = await database.getWordById(userId, row.wordId);
    final payload = {
      'user_id': row.userId,
      'local_word_id': row.wordId,
      'source_type': word?.sourceType ?? '',
      'book_key': word?.bookKey ?? '',
      'word': word?.word ?? '',
      'rating': row.rating,
      'reviewed_at': row.reviewedAt.toUtc().toIso8601String(),
      'client_updated_at': (row.updatedAt ?? row.reviewedAt)
          .toUtc()
          .toIso8601String(),
      'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
    };
    final remoteId = row.remoteId;
    if (remoteId != null && remoteId.isNotEmpty) {
      payload['id'] = remoteId;
    }
    final remoteWordId = word?.remoteId;
    final isBookWord =
        word != null && word.sourceType == 'book' && word.bookKey.isNotEmpty;
    if (!isBookWord && remoteWordId != null && remoteWordId.isNotEmpty) {
      payload['word_card_id'] = remoteWordId;
    }
    return payload;
  }

  Future<String?> _resolveLocalWordId(
    String userId,
    Map<String, dynamic> map,
  ) async {
    final remoteWordId = map['word_card_id']?.toString();
    if (remoteWordId != null && remoteWordId.isNotEmpty) {
      final localWord = await database.getWordByRemoteId(userId, remoteWordId);
      if (localWord != null) {
        return localWord.id;
      }
    }

    final localWordId = map['local_word_id']?.toString();
    if (localWordId != null && localWordId.isNotEmpty) {
      final localWord = await database.getWordById(userId, localWordId);
      if (localWord != null) {
        return localWord.id;
      }
    }
    final word = map['word']?.toString();
    if (word != null && word.isNotEmpty) {
      final sourceType = map['source_type']?.toString() ?? '';
      final bookKey = map['book_key']?.toString() ?? '';
      if (sourceType.isNotEmpty) {
        final localWord = await database.getWordByIdentity(
          userId: userId,
          sourceType: sourceType,
          bookKey: bookKey,
          word: word,
        );
        if (localWord != null) {
          return localWord.id;
        }
      }
      final localWord = await database.getWordByText(userId, word);
      if (localWord != null) {
        return localWord.id;
      }
    }
    return null;
  }

  Map<String, dynamic> _wordProgressToRemote(WordCard row) {
    return {
      'user_id': row.userId,
      'language': 'english',
      'book_key': row.bookKey,
      'word': row.word,
      'chinese_meaning': row.chineseMeaning,
      'english_meaning': row.englishMeaning,
      'gre_focus': row.greFocus,
      'roots_json': _decodeJsonList(row.rootsJson),
      'synonyms_json': _decodeJsonList(row.synonymsJson),
      'antonyms_json': _decodeJsonList(row.antonymsJson),
      'example': row.example,
      'memory_tip': row.memoryTip,
      'note': row.note,
      'tags_json': _decodeJsonList(row.tagsJson),
      'mastery': row.mastery,
      'due_at': row.dueAt.toUtc().toIso8601String(),
      'review_count': row.reviewCount,
      'lapse_count': row.lapseCount,
      'ease_factor': row.easeFactor,
      'interval_days': row.intervalDays,
      'enrichment_status': row.enrichmentStatus,
      'client_updated_at': row.updatedAt.toUtc().toIso8601String(),
      'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _wordToRemote(WordCard row) {
    final payload = {
      'user_id': row.userId,
      'language': 'english',
      'source_type': row.sourceType,
      'book_key': row.bookKey,
      'word': row.word,
      'chinese_meaning': row.chineseMeaning,
      'english_meaning': row.englishMeaning,
      'gre_focus': row.greFocus,
      'roots_json': _decodeJsonList(row.rootsJson),
      'synonyms_json': _decodeJsonList(row.synonymsJson),
      'antonyms_json': _decodeJsonList(row.antonymsJson),
      'example': row.example,
      'memory_tip': row.memoryTip,
      'note': row.note,
      'tags_json': _decodeJsonList(row.tagsJson),
      'mastery': row.mastery,
      'due_at': row.dueAt.toUtc().toIso8601String(),
      'review_count': row.reviewCount,
      'lapse_count': row.lapseCount,
      'ease_factor': row.easeFactor,
      'interval_days': row.intervalDays,
      'enrichment_status': row.enrichmentStatus,
      'client_updated_at': row.updatedAt.toUtc().toIso8601String(),
      'deleted_at': row.deletedAt?.toUtc().toIso8601String(),
    };
    final remoteId = row.remoteId;
    if (remoteId != null && remoteId.isNotEmpty) {
      payload['id'] = remoteId;
    }
    return payload;
  }

  WordCardsCompanion _remoteToCompanion({
    required String userId,
    required String localId,
    required Map<String, dynamic> map,
  }) {
    final word = map['word']?.toString() ?? '';
    final createdAt = _parseRemoteDate(map['created_at']) ?? DateTime.now();
    final updatedAt = _parseRemoteDate(map['updated_at']) ?? DateTime.now();
    return WordCardsCompanion.insert(
      id: localId,
      userId: Value(userId),
      remoteId: Value(map['id']?.toString()),
      syncStatus: const Value('synced'),
      deletedAt: Value(_parseRemoteDate(map['deleted_at'])),
      word: word,
      sourceType: Value(map['source_type']?.toString() ?? 'personal'),
      bookKey: Value(map['book_key']?.toString() ?? ''),
      chineseMeaning: map['chinese_meaning']?.toString() ?? '',
      englishMeaning: map['english_meaning']?.toString() ?? '',
      greFocus: map['gre_focus']?.toString() ?? '',
      rootsJson: Value(jsonEncode(map['roots_json'] ?? const [])),
      synonymsJson: Value(jsonEncode(map['synonyms_json'] ?? const [])),
      antonymsJson: Value(jsonEncode(map['antonyms_json'] ?? const [])),
      example: Value(map['example']?.toString() ?? ''),
      memoryTip: Value(map['memory_tip']?.toString() ?? ''),
      note: Value(map['note']?.toString() ?? ''),
      tagsJson: Value(jsonEncode(map['tags_json'] ?? const [])),
      mastery: Value((map['mastery'] as num?)?.toInt() ?? 0),
      dueAt: _parseRemoteDate(map['due_at']) ?? DateTime.now(),
      reviewCount: Value((map['review_count'] as num?)?.toInt() ?? 0),
      lapseCount: Value((map['lapse_count'] as num?)?.toInt() ?? 0),
      easeFactor: Value((map['ease_factor'] as num?)?.toInt() ?? 250),
      intervalDays: Value((map['interval_days'] as num?)?.toInt() ?? 0),
      enrichmentStatus: Value(map['enrichment_status']?.toString() ?? 'queued'),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  WordCardsCompanion _progressToCompanion({
    required String userId,
    required WordCard? local,
    required Map<String, dynamic> map,
  }) {
    final word = map['word']?.toString() ?? '';
    final bookKey = map['book_key']?.toString() ?? '';
    final createdAt =
        local?.createdAt ??
        _parseRemoteDate(map['created_at']) ??
        DateTime.now();
    final updatedAt = _parseRemoteDate(map['updated_at']) ?? DateTime.now();
    return WordCardsCompanion.insert(
      id: local?.id ?? _localBookWordId(userId, bookKey, word),
      userId: Value(userId),
      remoteId: Value(map['id']?.toString()),
      syncStatus: const Value('synced'),
      deletedAt: Value(_parseRemoteDate(map['deleted_at'])),
      word: word,
      sourceType: const Value('book'),
      bookKey: Value(bookKey),
      chineseMeaning: _remoteText(
        map,
        'chinese_meaning',
        fallback: local?.chineseMeaning ?? '',
      ),
      englishMeaning: _remoteText(
        map,
        'english_meaning',
        fallback: local?.englishMeaning ?? '',
      ),
      greFocus: _remoteText(map, 'gre_focus', fallback: local?.greFocus ?? ''),
      rootsJson: Value(
        jsonEncode(map['roots_json'] ?? _localJsonList(local?.rootsJson)),
      ),
      synonymsJson: Value(
        jsonEncode(map['synonyms_json'] ?? _localJsonList(local?.synonymsJson)),
      ),
      antonymsJson: Value(
        jsonEncode(map['antonyms_json'] ?? _localJsonList(local?.antonymsJson)),
      ),
      example: Value(
        _remoteText(map, 'example', fallback: local?.example ?? ''),
      ),
      memoryTip: Value(
        _remoteText(map, 'memory_tip', fallback: local?.memoryTip ?? ''),
      ),
      note: Value(_remoteText(map, 'note', fallback: local?.note ?? '')),
      tagsJson: Value(
        jsonEncode(map['tags_json'] ?? _localJsonList(local?.tagsJson)),
      ),
      mastery: Value((map['mastery'] as num?)?.toInt() ?? local?.mastery ?? 0),
      dueAt: _parseRemoteDate(map['due_at']) ?? local?.dueAt ?? DateTime.now(),
      reviewCount: Value(
        (map['review_count'] as num?)?.toInt() ?? local?.reviewCount ?? 0,
      ),
      lapseCount: Value(
        (map['lapse_count'] as num?)?.toInt() ?? local?.lapseCount ?? 0,
      ),
      easeFactor: Value(
        (map['ease_factor'] as num?)?.toInt() ?? local?.easeFactor ?? 250,
      ),
      intervalDays: Value(
        (map['interval_days'] as num?)?.toInt() ?? local?.intervalDays ?? 0,
      ),
      enrichmentStatus: Value(
        map['enrichment_status']?.toString() ??
            local?.enrichmentStatus ??
            'dictionary',
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String _localBookWordId(String userId, String bookKey, String word) {
    return '$userId:book:${bookKey.trim().toLowerCase()}:${word.trim().toLowerCase()}';
  }

  String _remoteText(
    Map<String, dynamic> map,
    String key, {
    required String fallback,
  }) {
    final value = map[key]?.toString() ?? '';
    return value.isEmpty ? fallback : value;
  }

  List<dynamic> _localJsonList(String? raw) {
    return raw == null ? const [] : _decodeJsonList(raw);
  }

  List<dynamic> _decodeJsonList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded : const [];
    } on FormatException {
      return const [];
    }
  }

  DateTime? _parseRemoteDate(Object? value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  DateTime? _parseDateOnly(Object? value) {
    if (value == null) {
      return null;
    }
    final parts = value.toString().split('-');
    if (parts.length != 3) {
      return DateTime.tryParse(value.toString())?.toLocal();
    }
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }
    return DateTime(year, month, day);
  }

  String _formatDateOnly(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  Future<SyncResult> _notSignedIn(String userId) async {
    final pending = await _countPending(userId);
    return SyncResult(
      success: false,
      message: '尚未登录 Supabase，无法同步。',
      pushed: 0,
      pulled: 0,
      pendingChanges: pending,
    );
  }

  Future<SyncResult> _failure(String userId, String message) async {
    final pending = await _countPending(userId);
    return SyncResult(
      success: false,
      message: message,
      pushed: 0,
      pulled: 0,
      pendingChanges: pending,
    );
  }

  String _syncFailureMessage(Object error) {
    if (error is AuthException) {
      final detail = error.message.isEmpty ? '' : '（${error.message}）';
      return '同步失败：登录状态已过期，请退出后重新登录。$detail';
    }
    if (error is PostgrestException) {
      final message = error.message.toLowerCase();
      final detail = _postgrestDetail(error);
      if (message.contains('review_logs') ||
          message.contains('word_cards') ||
          message.contains('word_progress') ||
          message.contains('study_settings')) {
        return '同步失败：云端数据表结构或缓存还没更新，请在 Supabase SQL Editor 重新运行 docs/supabase_schema.sql，或单独运行 notify pgrst, \'reload schema\';。$detail';
      }
      if (message.contains('row-level security') || message.contains('rls')) {
        return '同步失败：Supabase RLS 权限未通过，请确认当前账号已登录且 SQL policy 已创建。$detail';
      }
      return '同步失败：${error.message}$detail';
    }
    return '同步失败：$error';
  }

  String _postgrestDetail(PostgrestException error) {
    final parts = <String>[
      if (error.code != null && error.code!.isNotEmpty) 'code=${error.code}',
      if (error.details != null) 'details=${error.details}',
      if (error.hint != null && error.hint!.isNotEmpty) 'hint=${error.hint}',
      if (error.message.isNotEmpty) 'message=${error.message}',
    ];
    if (parts.isEmpty) {
      return '';
    }
    return '（${parts.join('；')}）';
  }
}

class _SettingsSyncCount {
  const _SettingsSyncCount({this.pushed = 0, this.pulled = 0});

  final int pushed;
  final int pulled;
}
