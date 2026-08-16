import 'package:flutter/material.dart';

/// Zentrale Theme-Definitionen der App.
class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
      brightness: Brightness.light,
      snackBarTheme: _snackBarTheme(),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      brightness: Brightness.dark,
      snackBarTheme: _snackBarTheme(),
    );
  }

  static SnackBarThemeData _snackBarTheme() {
    return const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    );
  }
}
