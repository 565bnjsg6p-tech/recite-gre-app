import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_database.dart';
import 'app_preferences.dart';

enum SyncPhase { idle, syncing, notConfigured, failed }

class SyncState {
  const SyncState({
    required this.phase,
    required this.pendingChanges,
    required this.message,
    this.lastSyncedAt,
  });

  final SyncPhase phase;
  final int pendingChanges;
  final String message;
  final DateTime? lastSyncedAt;

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

  Future<SyncResult> pushLocalChanges({required String userId});

  Future<SyncResult> pullRemoteChanges({required String userId});

  Future<SyncResult> syncNow({required String userId});
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
  Future<SyncResult> pushLocalChanges({required String userId}) async {
    return _notConfiguredResult(userId);
  }

  @override
  Future<SyncResult> pullRemoteChanges({required String userId}) async {
    return _notConfiguredResult(userId);
  }

  @override
  Future<SyncResult> syncNow({required String userId}) async {
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
  Future<SyncResult> pushLocalChanges({required String userId}) async {
    if (_client.auth.currentSession == null) {
      return _notSignedIn(userId);
    }

    final pending = await database.getPendingWordChanges(userId);
    var pushed = 0;
    for (final row in pending) {
      if (row.syncStatus == 'deleted') {
        if (row.remoteId == null || row.remoteId!.isEmpty) {
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

      final remote = await _client
          .from('word_cards')
          .upsert(_wordToRemote(row), onConflict: 'user_id,language,word')
          .select('id,updated_at')
          .single();
      final remoteId = remote['id']?.toString();
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

    pushed += await _pushReviewLogs(userId);

    final remaining = await _countPending(userId);
    return SyncResult(
      success: true,
      message: '上传完成：$pushed 条，本地待同步 $remaining 条。',
      pushed: pushed,
      pulled: 0,
      pendingChanges: remaining,
    );
  }

  @override
  Future<SyncResult> pullRemoteChanges({required String userId}) async {
    if (_client.auth.currentSession == null) {
      return _notSignedIn(userId);
    }

    final remoteRows = await _client
        .from('word_cards')
        .select()
        .eq('user_id', userId)
        .eq('language', 'english');
    var pulled = 0;
    for (final item in remoteRows) {
      final map = Map<String, dynamic>.from(item as Map);
      final remoteId = map['id']?.toString() ?? '';
      final word = map['word']?.toString() ?? '';
      if (remoteId.isEmpty || word.isEmpty) {
        continue;
      }

      final local =
          await database.getWordByRemoteId(userId, remoteId) ??
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
    }

    pulled += await _pullReviewLogs(userId);

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
  Future<SyncResult> syncNow({required String userId}) async {
    try {
      final push = await pushLocalChanges(userId: userId);
      if (!push.success) {
        return push;
      }
      final pull = await pullRemoteChanges(userId: userId);
      final settings = await _syncStudySettings(userId);
      final remaining = await _countPending(userId);
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
      return _failure(userId, 'åŒæ­¥å¤±è´¥ï¼š$error');
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
    return const _SettingsSyncCount();
  }

  Future<Map<String, dynamic>> _studySettingsToRemote(
    String userId,
    DateTime updatedAt,
  ) async {
    final prefs = preferences!;
    final examDate = await prefs.getExamDate();
    return {
      'user_id': userId,
      'language': 'english',
      'daily_new_words': await prefs.getDailyNewWords(),
      'daily_review_limit': await prefs.getDailyReviewLimit(),
      'exam_date': examDate == null ? null : _formatDateOnly(examDate),
      'settings_json': <String, dynamic>{},
      'client_updated_at': updatedAt.toUtc().toIso8601String(),
      'deleted_at': null,
    };
  }

  Future<void> _saveRemoteStudySettings(
    Map<String, dynamic> remote, {
    required bool pendingSync,
  }) async {
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
  }

  Future<int> _pushReviewLogs(String userId) async {
    final pending = await database.getPendingReviewLogChanges(userId);
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
    }
    return pushed;
  }

  Future<int> _pullReviewLogs(String userId) async {
    final remoteRows = await _client
        .from('review_logs')
        .select()
        .eq('user_id', userId);
    var pulled = 0;
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
    if (remoteWordId != null && remoteWordId.isNotEmpty) {
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
    return null;
  }

  Map<String, dynamic> _wordToRemote(WordCard row) {
    final payload = {
      'user_id': row.userId,
      'language': 'english',
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
      if (message.contains('review_logs') ||
          message.contains('word_cards') ||
          message.contains('study_settings')) {
        return '同步失败：云端数据表结构还没更新，请在 Supabase SQL Editor 重新运行 docs/supabase_schema.sql。';
      }
      if (message.contains('row-level security') || message.contains('rls')) {
        return '同步失败：Supabase RLS 权限未通过，请确认当前账号已登录且 SQL policy 已创建。';
      }
      return '同步失败：${error.message}';
    }
    return '同步失败：$error';
  }
}

class _SettingsSyncCount {
  const _SettingsSyncCount({this.pushed = 0, this.pulled = 0});

  final int pushed;
  final int pulled;
}
