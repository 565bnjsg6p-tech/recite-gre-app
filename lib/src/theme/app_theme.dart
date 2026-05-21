import 'package:flutter/material.dart';

class ReciteColors {
  static const ink = Color(0xFF17262A);
  static const muted = Color(0xFF60737A);
  static const surface = Color(0xFFF7F9FA);
  static const line = Color(0xFFE5EAED);
  static const blue = Color(0xFF4A7DFF);
  static const teal = Color(0xFF13B6A3);
  static const orange = Color(0xFFFFA928);
  static const red = Color(0xFFE85D75);
}

class ReciteTheme {
  static ThemeData light() {
    const fontFallback = <String>[
      'PingFang SC',
      'Hiragino Sans GB',
      'Microsoft YaHei',
      'Noto Sans CJK SC',
      'Noto Sans SC',
      'Source Han Sans SC',
      'Roboto',
      'Arial',
      'sans-serif',
    ];
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: ReciteColors.blue,
        primary: ReciteColors.blue,
        secondary: ReciteColors.teal,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: ReciteColors.surface,
      fontFamilyFallback: fontFallback,
    );

    return base.copyWith(
      textTheme: base.textTheme.apply(
        bodyColor: ReciteColors.ink,
        displayColor: ReciteColors.ink,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: ReciteColors.ink,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: ReciteColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ReciteColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ReciteColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ReciteColors.blue, width: 1.4),
        ),
      ),
    );
  }
}
