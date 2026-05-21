import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const maxDailyNewWords = 10000;

  static const _apiBaseUrl = 'ai_api_base_url';
  static const _apiKey = 'ai_api_key';
  static const _legacyApiKey = 'openai_api_key';
  static const _model = 'ai_model';
  static const _legacyModel = 'openai_model';
  static const _supabaseUrl = 'supabase_url';
  static const _supabaseAnonKey = 'supabase_anon_key';
  static const _lastSyncedAt = 'last_synced_at';
  static const _lastFullRepairSyncedAt = 'last_full_repair_synced_at';
  static const _lastBackupAt = 'last_backup_at';
  static const _syncEventLog = 'sync_event_log';
  static const _dailyNewWords = 'study_daily_new_words';
  static const _dailyReviewLimit = 'study_daily_review_limit';
  static const _examDate = 'study_exam_date';
  static const _studySettingsUpdatedAt = 'study_settings_updated_at';
  static const _studySettingsPending = 'study_settings_pending';
  static const _importedWordBooks = 'imported_word_books';
  static const _disabledWordBooks = 'disabled_word_books';
  static const _seedRepairDonePrefix = 'seed_repair_done_';

  Future<String> getApiBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiBaseUrl) ?? '';
  }

  Future<void> saveApiBaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_apiBaseUrl);
    } else {
      await prefs.setString(_apiBaseUrl, trimmed);
    }
  }

  Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKey) ?? prefs.getString(_legacyApiKey) ?? '';
  }

  Future<void> saveApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_apiKey);
      await prefs.remove(_legacyApiKey);
    } else {
      await prefs.setString(_apiKey, trimmed);
      await prefs.remove(_legacyApiKey);
    }
  }

  Future<String> getModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_model) ?? prefs.getString(_legacyModel) ?? '';
  }

  Future<void> saveModel(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_model);
      await prefs.remove(_legacyModel);
    } else {
      await prefs.setString(_model, trimmed);
      await prefs.remove(_legacyModel);
    }
  }

  Future<String> getSupabaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_supabaseUrl) ?? '';
  }

  Future<void> saveSupabaseUrl(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_supabaseUrl);
    } else {
      await prefs.setString(_supabaseUrl, trimmed);
    }
  }

  Future<String> getSupabaseAnonKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_supabaseAnonKey) ?? '';
  }

  Future<void> saveSupabaseAnonKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_supabaseAnonKey);
    } else {
      await prefs.setString(_supabaseAnonKey, trimmed);
    }
  }

  Future<DateTime?> getLastSyncedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncedAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> saveLastSyncedAt(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncedAt, value.toIso8601String());
  }

  Future<DateTime?> getLastFullRepairSyncedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastFullRepairSyncedAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> saveLastFullRepairSyncedAt(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastFullRepairSyncedAt, value.toIso8601String());
  }

  Future<DateTime?> getLastBackupAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastBackupAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> saveLastBackupAt(DateTime value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupAt, value.toIso8601String());
  }

  Future<List<String>> getSyncEventLog() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_syncEventLog) ?? const <String>[];
  }

  Future<void> saveSyncEventLog(List<String> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_syncEventLog, entries.take(20).toList());
  }

  Future<int> getDailyNewWords() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyNewWords) ?? 30;
  }

  Future<void> saveDailyNewWords(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _dailyNewWords,
      value.clamp(1, maxDailyNewWords).toInt(),
    );
  }

  Future<int> getDailyReviewLimit() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyReviewLimit) ?? 80;
  }

  Future<void> saveDailyReviewLimit(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyReviewLimit, value.clamp(1, 600).toInt());
  }

  Future<DateTime?> getExamDate() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_examDate);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<void> saveExamDate(DateTime? value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value == null) {
      await prefs.remove(_examDate);
      return;
    }
    await prefs.setString(_examDate, value.toIso8601String());
  }

  Future<DateTime?> getStudySettingsUpdatedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_studySettingsUpdatedAt);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  Future<bool> hasPendingStudySettings() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_studySettingsPending) ?? false;
  }

  Future<void> markStudySettingsSynced() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_studySettingsPending, false);
  }

  Future<void> markStudySettingsDirty({DateTime? updatedAt}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _studySettingsUpdatedAt,
      (updatedAt ?? DateTime.now()).toIso8601String(),
    );
    await prefs.setBool(_studySettingsPending, true);
  }

  Future<void> saveStudySettings({
    required int dailyNewWords,
    required int dailyReviewLimit,
    required DateTime? examDate,
    required DateTime updatedAt,
    required bool pendingSync,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _dailyNewWords,
      dailyNewWords.clamp(1, maxDailyNewWords).toInt(),
    );
    await prefs.setInt(
      _dailyReviewLimit,
      dailyReviewLimit.clamp(1, 600).toInt(),
    );
    if (examDate == null) {
      await prefs.remove(_examDate);
    } else {
      await prefs.setString(_examDate, examDate.toIso8601String());
    }
    await prefs.setString(_studySettingsUpdatedAt, updatedAt.toIso8601String());
    await prefs.setBool(_studySettingsPending, pendingSync);
  }

  Future<Set<String>> getDisabledWordBooks() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_disabledWordBooks) ?? const <String>[])
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  Future<Set<String>> getImportedWordBooks() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_importedWordBooks) ?? const <String>[])
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet();
  }

  Future<bool> saveImportedWordBooks(Set<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeStringSet(keys);
    final previous =
        prefs.getStringList(_importedWordBooks) ?? const <String>[];
    if (_sameStringList(previous, normalized)) {
      return false;
    }
    await prefs.setStringList(_importedWordBooks, normalized);
    return true;
  }

  Future<bool> mergeImportedWordBooks(Set<String> keys) async {
    final current = await getImportedWordBooks();
    final next = {...current, ...keys};
    return saveImportedWordBooks(next);
  }

  Future<void> saveDisabledWordBooks(Set<String> keys) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalizeStringSet(keys);
    await prefs.setStringList(_disabledWordBooks, normalized);
  }

  List<String> _normalizeStringSet(Set<String> keys) {
    return keys
        .map((item) => item.trim().toLowerCase())
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
  }

  bool _sameStringList(List<String> left, List<String> right) {
    if (left.length != right.length) {
      return false;
    }
    for (var i = 0; i < left.length; i += 1) {
      if (left[i] != right[i]) {
        return false;
      }
    }
    return true;
  }

  Future<bool> isSeedRepairDone(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_seedRepairDonePrefix$userId') ?? false;
  }

  Future<void> markSeedRepairDone(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_seedRepairDonePrefix$userId', true);
  }
}
