import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  static const _apiKey = 'openai_api_key';
  static const _model = 'openai_model';
  static const _supabaseUrl = 'supabase_url';
  static const _supabaseAnonKey = 'supabase_anon_key';
  static const _lastSyncedAt = 'last_synced_at';
  static const _dailyNewWords = 'study_daily_new_words';
  static const _dailyReviewLimit = 'study_daily_review_limit';
  static const _examDate = 'study_exam_date';
  static const _studySettingsUpdatedAt = 'study_settings_updated_at';
  static const _studySettingsPending = 'study_settings_pending';

  Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKey) ?? '';
  }

  Future<void> saveApiKey(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_apiKey);
    } else {
      await prefs.setString(_apiKey, trimmed);
    }
  }

  Future<String> getModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_model) ?? 'gpt-4.1-mini';
  }

  Future<void> saveModel(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await prefs.remove(_model);
    } else {
      await prefs.setString(_model, trimmed);
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

  Future<int> getDailyNewWords() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_dailyNewWords) ?? 30;
  }

  Future<void> saveDailyNewWords(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyNewWords, value.clamp(1, 300).toInt());
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

  Future<void> saveStudySettings({
    required int dailyNewWords,
    required int dailyReviewLimit,
    required DateTime? examDate,
    required DateTime updatedAt,
    required bool pendingSync,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dailyNewWords, dailyNewWords.clamp(1, 300).toInt());
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
}
