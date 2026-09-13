import 'package:flutter/material.dart';

/// Material 3 dark theme (UIUX §1). Study sessions are often in low light, so
/// dark mode is the default. No color is ever the only signal — every status
/// carries a label + value (accessibility locked in the plan).
class AppTheme {
  static const Color bg = Color(0xFF0E1116); // near-black, low glare
  static const Color surface = Color(0xFF171C24); // card surface
  static const Color surfaceHigh = Color(0xFF202733); // raised surface
  static const Color primary = Color(0xFF7C6CFF); // neural-violet
  static const Color accent = Color(0xFF4ADE80); // recall-green
  static const Color warm = Color(0xFFFFB84D); // pressure/warning amber
  static const Color danger = Color(0xFFFF6B6B); // gap red
  static const Color textPrimary = Color(0xFFE6E9EF);
  static const Color textDim = Color(0xFF8A93A6);

  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        surface: bg,
      ),
      scaffoldBackgroundColor: bg,
      fontFamily: null,
    );

    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
            color: textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: surfaceHigh)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: primary.withValues(alpha: 0.25),
        iconTheme: WidgetStateProperty.resolveWith(
          (_) => const IconThemeData(color: textDim, size: 24),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (_) => const TextStyle(color: textDim, fontSize: 11),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceHigh,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        hintStyle: const TextStyle(color: textDim),
      ),
    );
  }
}