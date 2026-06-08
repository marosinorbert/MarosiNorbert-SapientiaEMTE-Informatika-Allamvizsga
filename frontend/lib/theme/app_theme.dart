import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF22C55E);
  static const Color primaryLight = Color(0xFFDCFCE7);
  static const Color primarySurface = Color(0xFFF0FDF4);
  static const Color background = Color(0xFFF8FFFE);
  static const Color cardBg = Colors.white;
  static const Color textPrimary = Color(0xFF1A2E1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: background,
        fontFamily: 'Roboto',
        cardTheme: CardThemeData(
          color: cardBg,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: border),
          ),
        ),
      );
}