import 'dart:ui' show Locale;

/// The languages the app ships. [system] follows the device locale; every
/// other value pins the app to that language.
///
/// The names are written in their own language (endonyms), which is the
/// convention for a language picker and means they never need translating.
enum AppLanguage {
  system(null, 'System default'),
  english(Locale('en'), 'English'),
  simplifiedChinese(
    Locale.fromSubtags(languageCode: 'zh'),
    '\u7B80\u4F53\u4E2D\u6587',
  ),
  traditionalChinese(
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    '\u7E41\u9AD4\u4E2D\u6587',
  ),
  japanese(Locale('ja'), '\u65E5\u672C\u8A9E'),
  korean(Locale('ko'), '\uD55C\uAD6D\uC5B4'),
  spanish(Locale('es'), 'Espa\u00F1ol'),
  french(Locale('fr'), 'Fran\u00E7ais'),
  german(Locale('de'), 'Deutsch'),
  portuguese(Locale('pt'), 'Portugu\u00EAs');

  const AppLanguage(this.locale, this.nativeName);

  /// The locale to select, or `null` to follow the system language.
  final Locale? locale;

  /// The language's name in that language.
  final String nativeName;
}
