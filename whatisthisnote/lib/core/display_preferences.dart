/// The naming system used for note names in the readout and on the staff.
enum NamingSystem {
  scientific('Scientific'),
  solfege('Solfege'),
  jianpu('Numbered');

  const NamingSystem(this.label);

  final String label;
}

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
  });

  /// Which name is shown first in the readout and next to the note.
  final NamingSystem naming;

  /// Whether to draw the note name next to the note on the staff.
  final bool showStaffLabel;

  /// Whether to also show the enharmonic spelling (F♯ ~ G♭).
  final bool showEnharmonic;

  DisplayPreferences copyWith({
    NamingSystem? naming,
    bool? showStaffLabel,
    bool? showEnharmonic,
  }) => DisplayPreferences(
    naming: naming ?? this.naming,
    showStaffLabel: showStaffLabel ?? this.showStaffLabel,
    showEnharmonic: showEnharmonic ?? this.showEnharmonic,
  );

  @override
  bool operator ==(Object other) =>
      other is DisplayPreferences &&
      other.naming == naming &&
      other.showStaffLabel == showStaffLabel &&
      other.showEnharmonic == showEnharmonic;

  @override
  int get hashCode => Object.hash(naming, showStaffLabel, showEnharmonic);
}
