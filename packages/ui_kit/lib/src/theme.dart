import 'package:flutter/material.dart';

/// Emergency-response inspired palette — sober, high readability, trust.
class AyniColors {
  static const background = Color(0xFF0F1419);
  static const surface = Color(0xFF1A2332);
  static const surfaceElevated = Color(0xFF243044);
  static const primary = Color(0xFFC0392B);
  static const secondary = Color(0xFF2E86AB);
  static const textPrimary = Color(0xFFF4F6F8);
  static const textSecondary = Color(0xFFA8B3C0);
  static const success = Color(0xFF27AE60);
  static const warning = Color(0xFFE67E22);
  static const critical = Color(0xFFC0392B);
}

ThemeData buildAyniTheme() {
  const scheme = ColorScheme.dark(
    primary: AyniColors.primary,
    secondary: AyniColors.secondary,
    surface: AyniColors.surface,
    error: AyniColors.critical,
    onPrimary: AyniColors.textPrimary,
    onSecondary: AyniColors.textPrimary,
    onSurface: AyniColors.textPrimary,
    onError: AyniColors.textPrimary,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AyniColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AyniColors.surface,
      foregroundColor: AyniColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: CardThemeData(
      color: AyniColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AyniColors.primary,
        foregroundColor: AyniColors.textPrimary,
        minimumSize: const Size.fromHeight(56),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AyniColors.textPrimary,
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: AyniColors.secondary, width: 2),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AyniColors.surfaceElevated,
      labelStyle: const TextStyle(color: AyniColors.textSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AyniColors.surfaceElevated),
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        color: AyniColors.textPrimary,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      titleLarge: TextStyle(
        color: AyniColors.textPrimary,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: TextStyle(color: AyniColors.textPrimary, fontSize: 16),
      bodyMedium: TextStyle(color: AyniColors.textSecondary, fontSize: 14),
    ),
  );
}
