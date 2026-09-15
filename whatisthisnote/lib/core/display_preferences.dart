import 'app_language.dart';

/// The naming system used for note names in the readout and on the staff.
enum NamingSystem { scientific, solfege, jianpu }

/// User-configurable display preferences.
///
/// This is a small immutable value object on purpose: persistence (for example
/// with `shared_preferences`) can be added later by serializing these fields,
/// without touching the widgets that consume them.
class DisplayPreferences {
  const DisplayPreferences({
    this.naming = NamingSystem.scientific,
    this.showStaffLabel = true,
    this.showEnharmonic = false,
    this.language = AppLanguage.system,
  });

  /// Which name is shown first in the readout and next to the note.
  final NamingSystem naming;

  /// Whether to draw the note name next to the note on the staff.
  final bool showStaffLabel;

  /// Whether to also show the enharmonic spelling (F♯ ~ G♭).
  final bool showEnharmonic;

  /// The app language, or [AppLanguage.system] to follow the device.
  final AppLanguage language;

  DisplayPreferences copyWith({
    NamingSystem? naming,
    bool? showStaffLabel,
    bool? showEnharmonic,
    AppLanguage? language,
  }) => DisplayPreferences(
    naming: naming ?? this.naming,
    showStaffLabel: showStaffLabel ?? this.showStaffLabel,
    showEnharmonic: showEnharmonic ?? this.showEnharmonic,
    language: language ?? this.language,
  );

  @override
  bool operator ==(Object other) =>
      other is DisplayPreferences &&
      other.naming == naming &&
      other.showStaffLabel == showStaffLabel &&
      other.showEnharmonic == showEnharmonic &&
      other.language == language;

  @override
  int get hashCode =>
      Object.hash(naming, showStaffLabel, showEnharmonic, language);
}
