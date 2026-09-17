part of '../chord.dart';

class ChordQuality {
  const ChordQuality(
    this.label,
    this.suffix,
    this.romanSuffix,
    this.intervals,
    this.scaleSteps,
  );

  final String label;
  final String suffix;
  final String romanSuffix;

  /// Semitone offsets above the root, low to high.
  final List<int> intervals;

  /// Diatonic steps of each tone above the root, low to high.
  final List<int> scaleSteps;

  bool get isSeventh => intervals.length == 4;

  /// Whether the third is minor, so the roman numeral is lower case.
  bool get hasMinorThird => intervals[1] == 3;

  int get toneCount => intervals.length;

  static const major = ChordQuality('major', '', '', [0, 4, 7], [0, 2, 4]);
  static const minor = ChordQuality('minor', 'm', '', [0, 3, 7], [0, 2, 4]);
  static const diminished = ChordQuality(
    'diminished',
    'dim',
    '\u00B0',
    [0, 3, 6],
    [0, 2, 4],
  );
  static const augmented = ChordQuality(
    'augmented',
    'aug',
    '+',
    [0, 4, 8],
    [0, 2, 4],
  );
  static const majorSixth = ChordQuality(
    'major sixth',
    '6',
    '6',
    [0, 4, 7, 9],
    [0, 2, 4, 5],
  );
  static const minorSixth = ChordQuality(
    'minor sixth',
    'm6',
    '6',
    [0, 3, 7, 9],
    [0, 2, 4, 5],
  );
  static const majorSeventh = ChordQuality(
    'major seventh',
    'maj7',
    'maj7',
    [0, 4, 7, 11],
    [0, 2, 4, 6],
  );
  static const dominantSeventh = ChordQuality(
    'dominant seventh',
    '7',
    '7',
    [0, 4, 7, 10],
    [0, 2, 4, 6],
  );
  static const minorSeventh = ChordQuality(
    'minor seventh',
    'm7',
    '7',
    [0, 3, 7, 10],
    [0, 2, 4, 6],
  );
  static const halfDiminishedSeventh = ChordQuality(
    'half-diminished seventh',
    'm7\u266D5',
    '\u00F87',
    [0, 3, 6, 10],
    [0, 2, 4, 6],
  );
  static const diminishedSeventh = ChordQuality(
    'diminished seventh',
    'dim7',
    '\u00B07',
    [0, 3, 6, 9],
    [0, 2, 4, 6],
  );

  /// Names the chord built from a diatonic stack of [scaleSteps] with the
  /// matching semitone [intervals]. The highest natural extension names the
  /// chord; degrees that do not match their major-scale spelling are shown as
  /// alterations (for example a flat ninth or sharp eleventh).
  factory ChordQuality.fromStack(List<int> scaleSteps, List<int> intervals) =>
      chordQualityFromStack(scaleSteps, intervals);

  @override
  bool operator ==(Object other) {
    if (other is! ChordQuality ||
        other.suffix != suffix ||
        other.intervals.length != intervals.length) {
      return false;
    }
    for (var i = 0; i < intervals.length; i++) {
      if (other.intervals[i] != intervals[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(suffix, Object.hashAll(intervals));
}
