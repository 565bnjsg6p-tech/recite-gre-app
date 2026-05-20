import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'recite_app.dart';
import 'src/data/app_database.dart';
import 'src/data/app_preferences.dart';
import 'src/data/app_store.dart';
import 'src/data/auth_repository.dart';
import 'src/data/sync_service.dart';
import 'src/config/supabase_config.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };
      ErrorWidget.builder = (details) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                '页面渲染遇到问题，请刷新后重试。\n${details.exceptionAsString()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF172026),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
          ),
        );
      };

      final startup = await _buildStartupApp();
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.white,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
      runApp(startup);
    },
    (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, stack: stackTrace),
      );
    },
  );
}

Future<Widget> _buildStartupApp() async {
  try {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    return const ReciteApp();
  } on Object {
    final database = AppDatabase.defaults();
    final preferences = AppPreferences();
    return ReciteApp(
      store: AppStore(
        database,
        preferences: preferences,
        syncService: PlaceholderSyncService(
          database: database,
          preferences: preferences,
        ),
      ),
      authRepository: LocalAuthRepository(),
      startupNotice: '云端服务暂时不可用，已切换为本地模式。页面可以继续打开，稍后刷新可恢复云同步。',
    );
  }
}

class HexColor extends Color {
  HexColor(final String hexColor) : super(_getColorFromHex(hexColor));

  static int _getColorFromHex(String hexColor) {
    var value = hexColor.toUpperCase().replaceAll('#', '');
    if (value.length == 6) {
      value = 'FF$value';
    }
    return int.parse(value, radix: 16);
  }
}
