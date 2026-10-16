import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color backgroundDark = Color(0xFF0B0E14);
  static const Color surfaceCard = Color(0xFF141923);
  static const Color surfaceElevated = Color(0xFF1E2636);

  static const Color accentCyan = Colors.cyanAccent;
  static const Color accentAmber = Colors.amberAccent;
  static const Color accentGreen = Colors.greenAccent;
  static const Color accentRed = Colors.redAccent;
  static const Color accentBlue = Colors.blueAccent;

  static ThemeData get darkTheme {
    return ThemeData.dark(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        surface: surfaceCard,
        primary: accentBlue,
        secondary: accentCyan,
        error: accentRed,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Colors.white12),
        ),
      ),
    );
  }
}
