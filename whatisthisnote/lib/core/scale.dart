/// One step of a scale: a semitone offset above the tonic plus the degree
/// label used in music theory, e.g. `3` or `♭7`.
class ScaleDegree {
  const ScaleDegree(this.semitone, this.label);

  final int semitone;
  final String label;
}

/// A scale or note set that can be highlighted on the keyboard and staff.
///
/// Every set is expressed as semitone offsets from its tonic so that the same
/// shape can be transposed to any key.
enum ScaleType {
  major('Major', [
    ScaleDegree(0, '1'),
    ScaleDegree(2, '2'),
    ScaleDegree(4, '3'),
    ScaleDegree(5, '4'),
    ScaleDegree(7, '5'),
    ScaleDegree(9, '6'),
    ScaleDegree(11, '7'),
  ]),
  naturalMinor('Natural minor', [
    ScaleDegree(0, '1'),
    ScaleDegree(2, '2'),
    ScaleDegree(3, '\u266D3'),
    ScaleDegree(5, '4'),
    ScaleDegree(7, '5'),
    ScaleDegree(8, '\u266D6'),
    ScaleDegree(10, '\u266D7'),
  ]),
  harmonicMinor('Harmonic minor', [
    ScaleDegree(0, '1'),
    ScaleDegree(2, '2'),
    ScaleDegree(3, '\u266D3'),
    ScaleDegree(5, '4'),
    ScaleDegree(7, '5'),
    ScaleDegree(8, '\u266D6'),
    ScaleDegree(11, '7'),
  ]),
  melodicMinor('Melodic minor', [
    ScaleDegree(0, '1'),
    ScaleDegree(2, '2'),
    ScaleDegree(3, '\u266D3'),
    ScaleDegree(5, '4'),
    ScaleDegree(7, '5'),
    ScaleDegree(9, '6'),
    ScaleDegree(11, '7'),
  ]),
  majorPentatonic('Major pentatonic', [
    ScaleDegree(0, '1'),
    ScaleDegree(2, '2'),
    ScaleDegree(4, '3'),
    ScaleDegree(7, '5'),
    ScaleDegree(9, '6'),
  ]),
  minorPentatonic('Minor pentatonic', [
    ScaleDegree(0, '1'),
    ScaleDegree(3, '\u266D3'),
    ScaleDegree(5, '4'),
    ScaleDegree(7, '5'),
    ScaleDegree(10, '\u266D7'),
  ]),
  blues('Blues', [
    ScaleDegree(0, '1'),
    ScaleDegree(3, '\u266D3'),
    ScaleDegree(5, '4'),
    ScaleDegree(6, '\u266D5'),
    ScaleDegree(7, '5'),
    ScaleDegree(10, '\u266D7'),
  ]);

  const ScaleType(this.label, this.degrees);

  final String label;
  final List<ScaleDegree> degrees;

  /// True when the scale contains a note that is a blue note (♭3, ♭5 or ♭7)
  /// rather than a plain major-scale degree.
  bool get hasBlueNotes =>
      degrees.any((d) => d.label.startsWith('\u266D') &&
          const {'\u266D3', '\u266D5', '\u266D7'}.contains(d.label));
}

/// A [ScaleType] rooted at a particular pitch class.
class Scale {
  const Scale(this.tonicLabel, this.tonicPitchClass, this.type);

  /// Display name of the tonic, e.g. `G` or `F♯`.
  final String tonicLabel;

  /// Pitch class of the tonic, 0 == C.
  final int tonicPitchClass;

  final ScaleType type;

  /// Human readable name, e.g. `G Blues`.
  String get label => '$tonicLabel ${type.label}';

  /// The twelve-tone pitch classes that belong to this scale.
  Set<int> get pitchClasses => {
        for (final degree in type.degrees)
          (tonicPitchClass + degree.semitone) % 12,
      };

  /// Whether the sounding [midi] note is in the scale.
  bool contains(int midi) => pitchClasses.contains(midi % 12);

  /// Degree label of the sounding [midi] note, or `null` when it is outside
  /// the scale.
  String? degreeLabelFor(int midi) {
    final pitchClass = midi % 12;
    for (final degree in type.degrees) {
      if ((tonicPitchClass + degree.semitone) % 12 == pitchClass) {
        return degree.label;
      }
    }
    return null;
  }
}
