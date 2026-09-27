import 'package:flutter/material.dart';

class NotebookTheme {
  static const Color paper = Color(0xFFF4EFE6);
  static const Color ink = Color(0xFF1A1815);
  static const Color oxblood = Color(0xFF7A2E2E);
  static const Color graphite = Color(0xFF5A564E);

  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: paper,
      colorScheme: const ColorScheme.light(
        primary: oxblood,
        secondary: graphite,
        surface: paper,
        onSurface: ink,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 22,
          fontWeight: FontWeight.normal,
          color: ink,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Georgia',
          fontSize: 17,
          color: ink,
          height: 1.5,
        ),
        labelSmall: TextStyle(
          fontFamily: 'monospace',
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: graphite,
          letterSpacing: 1.2,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: oxblood,
          textStyle: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 17,
            decoration: TextDecoration.underline,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: oxblood,
          foregroundColor: paper,
          textStyle: const TextStyle(
            fontFamily: 'Georgia',
            fontSize: 17,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: ink, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
        ),
      ),
    );
  }
}
