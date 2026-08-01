import 'package:flutter/material.dart';

/// Brand palette derived from the AyniSOS logo (teal shield, navy type, orange spark).
class AyniColors {
  static const background = Color(0xFFF3F7F8);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceElevated = Color(0xFFE6F0F2);
  static const primary = Color(0xFF2F95A4);
  static const secondary = Color(0xFF1C2E4A);
  static const accent = Color(0xFFF48B29);
  static const textPrimary = Color(0xFF1C2E4A);
  static const textSecondary = Color(0xFF5A6B7D);
  static const success = Color(0xFF2E9B63);
  static const warning = Color(0xFFF48B29);
  static const critical = Color(0xFFC0392B);
}

ThemeData buildAyniTheme() {
  const scheme = ColorScheme.light(
    primary: AyniColors.primary,
    secondary: AyniColors.secondary,
    tertiary: AyniColors.accent,
    surface: AyniColors.surface,
    error: AyniColors.critical,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onTertiary: Colors.white,
    onSurface: AyniColors.textPrimary,
    onError: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AyniColors.background,
    dividerColor: AyniColors.surfaceElevated,
    appBarTheme: const AppBarTheme(
      backgroundColor: AyniColors.surface,
      foregroundColor: AyniColors.textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: AyniColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: AyniColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE0E8EC)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AyniColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AyniColors.secondary,
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: AyniColors.primary, width: 2),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AyniColors.primary),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AyniColors.surface,
      labelStyle: const TextStyle(color: AyniColors.textSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5E0E4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AyniColors.primary, width: 2),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AyniColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.4,
      ),
      titleLarge: TextStyle(
        color: AyniColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: AyniColors.textPrimary, fontSize: 16, height: 1.4),
      bodyMedium: TextStyle(color: AyniColors.textSecondary, fontSize: 14, height: 1.4),
    ),
  );
}
