import 'package:flutter/material.dart';

/// Central place for the app's light and dark themes.
class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF4A6CF7);

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      scaffoldBackgroundColor: scheme.surface,
    );
  }
}
