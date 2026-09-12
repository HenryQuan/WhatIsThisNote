import 'package:flutter/material.dart';

/// Central place for the app's light and dark themes.
class AppTheme {
  const AppTheme._();

  static const Color _seed = Color(0xFF4A6CF7);

  /// Theme using Material You dynamic colors when [dynamicScheme] is available
  /// (Android 12+/macOS), otherwise falling back to the brand seed color.
  static ThemeData light([ColorScheme? dynamicScheme]) =>
      _build(Brightness.light, dynamicScheme);

  static ThemeData dark([ColorScheme? dynamicScheme]) =>
      _build(Brightness.dark, dynamicScheme);

  static ThemeData _build(Brightness brightness, ColorScheme? dynamicScheme) {
    final scheme = dynamicScheme ??
        ColorScheme.fromSeed(
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
