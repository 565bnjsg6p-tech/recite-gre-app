import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'src/data/app_database.dart';
import 'src/data/app_scope.dart';
import 'src/data/app_store.dart';
import 'src/data/auth_repository.dart';
import 'src/data/sync_service.dart';
import 'src/theme/app_theme.dart';
import 'src/ui/app_shell.dart';
import 'src/ui/pages/access_pages.dart';

class ReciteApp extends StatefulWidget {
  const ReciteApp({super.key, this.store, this.authRepository});

  final AppStore? store;
  final AuthRepository? authRepository;

  @override
  State<ReciteApp> createState() => _ReciteAppState();
}

class _ReciteAppState extends State<ReciteApp> {
  late final AppStore _store;
  late final AuthRepository _authRepository;
  late final Future<void> _ready;
  String? _selectedLanguage;
  AppUser? _user;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? AppStore(AppDatabase.defaults());
    _authRepository = widget.authRepository ?? SupabaseAuthRepository();
    _ready = _initialize();
  }

  @override
  void dispose() {
    _store.disposeStore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recite GRE',
      debugShowCheckedModeBanner: false,
      theme: ReciteTheme.light(),
      scrollBehavior: const ReciteScrollBehavior(),
      home: FutureBuilder<void>(
        future: _ready,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _StartupScreen();
          }
          if (snapshot.hasError) {
            return _StartupError(error: snapshot.error.toString());
          }
          if (_selectedLanguage == null) {
            return LanguageSelectionPage(
              onEnglish: () => _selectLanguage('english'),
              onGerman: () => _selectLanguage('german'),
            );
          }
          if (_selectedLanguage == 'german') {
            return GermanComingSoonPage(onBack: _clearLanguage);
          }
          if (_user == null) {
            return AuthPage(
              authRepository: _authRepository,
              onAuthenticated: _setAuthenticatedUser,
              onBack: _clearLanguage,
            );
          }
          return AppScope(
            store: _store,
            child: AppShell(
              user: _user!,
              onSignOut: _signOut,
              onChangeLanguage: _clearLanguage,
            ),
          );
        },
      ),
    );
  }

  Future<void> _initialize() async {
    await _store.initialize();
    _selectedLanguage = await _authRepository.getSelectedLanguage();
    _user = await _authRepository.getSession();
    final user = _user;
    if (user != null) {
      await _store.activateUser(user.id);
      _autoSyncAfterLogin();
    }
  }

  Future<void> _selectLanguage(String language) async {
    await _authRepository.saveSelectedLanguage(language);
    setState(() => _selectedLanguage = language);
  }

  Future<void> _clearLanguage() async {
    await _authRepository.signOut();
    await _authRepository.clearSelectedLanguage();
    _store.clearActiveUser();
    setState(() {
      _selectedLanguage = null;
      _user = null;
    });
  }

  Future<void> _signOut() async {
    await _authRepository.signOut();
    _store.clearActiveUser();
    setState(() => _user = null);
  }

  Future<void> _setAuthenticatedUser(AppUser user) async {
    await _store.activateUser(user.id);
    setState(() => _user = user);
    _autoSyncAfterLogin();
  }

  void _autoSyncAfterLogin() {
    if (_authRepository is! SupabaseAuthRepository) {
      return;
    }
    unawaited(
      _store.syncNow().catchError((_) {
        return const SyncResult(
          success: false,
          message: '',
          pushed: 0,
          pulled: 0,
          pendingChanges: 0,
        );
      }),
    );
  }
}

class ReciteScrollBehavior extends MaterialScrollBehavior {
  const ReciteScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class _StartupScreen extends StatelessWidget {
  const _StartupScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('数据库启动失败：$error'),
        ),
      ),
    );
  }
}
