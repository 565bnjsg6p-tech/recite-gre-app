import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.language,
  });

  final String id;
  final String email;
  final String displayName;
  final String language;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      language: json['language']?.toString() ?? 'english',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'language': language,
    };
  }
}

class AuthResult {
  const AuthResult.success(this.user) : error = '';

  const AuthResult.failure(this.error) : user = null;

  final AppUser? user;
  final String error;

  bool get isSuccess => user != null;
}

abstract class AuthRepository {
  Future<String?> getSelectedLanguage();

  Future<void> saveSelectedLanguage(String language);

  Future<void> clearSelectedLanguage();

  Future<AppUser?> getSession();

  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String language = 'english',
  });

  Future<AuthResult> login({
    required String email,
    required String password,
    String language = 'english',
  });

  Future<void> signOut();
}

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  static const _languageKey = 'selected_language';

  final SupabaseClient _client;

  @override
  Future<String?> getSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }

  @override
  Future<void> saveSelectedLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  @override
  Future<void> clearSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageKey);
  }

  @override
  Future<AppUser?> getSession() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return null;
    }
    return _toAppUser(user, await getSelectedLanguage() ?? 'english');
  }

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String language = 'english',
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cleanName = displayName.trim();
    final validationError = _validateCredentials(normalizedEmail, password);
    if (validationError != null) {
      return AuthResult.failure(validationError);
    }

    try {
      final response = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          'display_name': cleanName.isEmpty
              ? normalizedEmail.split('@').first
              : cleanName,
          'preferred_language': language,
        },
      );
      final user = response.user;
      if (user == null) {
        return const AuthResult.failure('注册没有返回账号，请稍后重试。');
      }
      final appUser = _toAppUser(user, language);
      await _upsertProfileIfPossible(appUser);
      return AuthResult.success(appUser);
    } on AuthException catch (error) {
      return AuthResult.failure(error.message);
    } on PostgrestException catch (error) {
      return AuthResult.failure(error.message);
    } on Object catch (error) {
      return AuthResult.failure('注册失败：$error');
    }
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    String language = 'english',
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final validationError = _validateCredentials(normalizedEmail, password);
    if (validationError != null) {
      return AuthResult.failure(validationError);
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: normalizedEmail,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        return const AuthResult.failure('没有找到登录账号。');
      }
      final appUser = _toAppUser(user, language);
      await _upsertProfileIfPossible(appUser);
      return AuthResult.success(appUser);
    } on AuthException catch (error) {
      return AuthResult.failure(error.message);
    } on PostgrestException catch (error) {
      return AuthResult.failure(error.message);
    } on Object catch (error) {
      return AuthResult.failure('登录失败：$error');
    }
  }

  @override
  Future<void> signOut() {
    return _client.auth.signOut();
  }

  Future<void> _upsertProfileIfPossible(AppUser user) async {
    if (_client.auth.currentSession == null) {
      return;
    }
    try {
      await _client.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'display_name': user.displayName,
        'preferred_language': user.language,
      });
    } on PostgrestException {
      // The auth session is still usable even if the schema has not been run yet.
    }
  }

  AppUser _toAppUser(User user, String language) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
    final displayName = metadata['display_name']?.toString();
    final preferredLanguage =
        metadata['preferred_language']?.toString() ?? language;
    return AppUser(
      id: user.id,
      email: user.email ?? '',
      displayName: displayName == null || displayName.isEmpty
          ? (user.email ?? 'Recite user').split('@').first
          : displayName,
      language: preferredLanguage,
    );
  }

  String? _validateCredentials(String email, String password) {
    if (!email.contains('@') || !email.contains('.')) {
      return '请输入有效邮箱。';
    }
    if (password.length < 6) {
      return '密码至少 6 位。';
    }
    return null;
  }
}

class LocalAuthRepository implements AuthRepository {
  static const _accountsKey = 'local_auth_accounts';
  static const _sessionKey = 'local_auth_session';
  static const _languageKey = 'selected_language';

  @override
  Future<String?> getSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }

  @override
  Future<void> saveSelectedLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  @override
  Future<void> clearSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageKey);
  }

  @override
  Future<AppUser?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final user = AppUser.fromJson(decoded);
      return user.id.isEmpty ? null : user;
    } on FormatException {
      await prefs.remove(_sessionKey);
      return null;
    }
  }

  @override
  Future<AuthResult> register({
    required String email,
    required String password,
    required String displayName,
    String language = 'english',
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final cleanName = displayName.trim();
    final validationError = _validateCredentials(normalizedEmail, password);
    if (validationError != null) {
      return AuthResult.failure(validationError);
    }

    final accounts = await _loadAccounts();
    if (accounts.any((account) => account.email == normalizedEmail)) {
      return const AuthResult.failure('这个邮箱已经注册，可以直接登录。');
    }

    final now = DateTime.now().toUtc();
    final account = _LocalAccount(
      id: 'user_${now.microsecondsSinceEpoch}',
      email: normalizedEmail,
      displayName: cleanName.isEmpty
          ? normalizedEmail.split('@').first
          : cleanName,
      passwordHash: _hashPassword(normalizedEmail, password),
      createdAt: now,
      updatedAt: now,
    );
    accounts.add(account);
    await _saveAccounts(accounts);

    final user = AppUser(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      language: language,
    );
    await _saveSession(user);
    return AuthResult.success(user);
  }

  @override
  Future<AuthResult> login({
    required String email,
    required String password,
    String language = 'english',
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final validationError = _validateCredentials(normalizedEmail, password);
    if (validationError != null) {
      return AuthResult.failure(validationError);
    }

    final accounts = await _loadAccounts();
    final matches = accounts.where(
      (account) => account.email == normalizedEmail,
    );
    if (matches.isEmpty) {
      return const AuthResult.failure('没有找到这个账号，请先注册。');
    }

    final account = matches.first;
    if (account.passwordHash != _hashPassword(normalizedEmail, password)) {
      return const AuthResult.failure('密码不正确。');
    }

    final user = AppUser(
      id: account.id,
      email: account.email,
      displayName: account.displayName,
      language: language,
    );
    await _saveSession(user);
    return AuthResult.success(user);
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> _saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
  }

  Future<List<_LocalAccount>> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_LocalAccount.fromJson)
          .where((account) => account.id.isNotEmpty && account.email.isNotEmpty)
          .toList();
    } on FormatException {
      return [];
    }
  }

  Future<void> _saveAccounts(List<_LocalAccount> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _accountsKey,
      jsonEncode([for (final account in accounts) account.toJson()]),
    );
  }

  String? _validateCredentials(String email, String password) {
    if (!email.contains('@') || !email.contains('.')) {
      return '请输入有效邮箱。';
    }
    if (password.length < 6) {
      return '密码至少 6 位。';
    }
    return null;
  }

  String _hashPassword(String email, String password) {
    final bytes = utf8.encode('recite-auth-v1|$email|$password');
    return sha256.convert(bytes).toString();
  }
}

class _LocalAccount {
  const _LocalAccount({
    required this.id,
    required this.email,
    required this.displayName,
    required this.passwordHash,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String passwordHash;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory _LocalAccount.fromJson(Map<String, dynamic> json) {
    return _LocalAccount(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      displayName: json['displayName']?.toString() ?? '',
      passwordHash: json['passwordHash']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt:
          DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'passwordHash': passwordHash,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
