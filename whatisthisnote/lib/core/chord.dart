import 'accidental.dart';
import 'note.dart';
import 'scale.dart';

/// The three states of the chord lab add-on.
enum ChordMode {
  off('Off'),
  triads('Triads'),
  sevenths('Sevenths');

  const ChordMode(this.label);

  final String label;
}

/// The quality (interval structure) of a chord and the suffix used in its
/// symbol, e.g. `m` for a minor triad.
enum ChordQuality {
  major('major', '', [0, 4, 7]),
  minor('minor', 'm', [0, 3, 7]),
  diminished('diminished', 'dim', [0, 3, 6]),
  augmented('augmented', 'aug', [0, 4, 8]),
  majorSeventh('major seventh', 'maj7', [0, 4, 7, 11]),
  dominantSeventh('dominant seventh', '7', [0, 4, 7, 10]),
  minorSeventh('minor seventh', 'm7', [0, 3, 7, 10]),
  halfDiminishedSeventh('half-diminished seventh', 'm7\u266D5', [0, 3, 6, 10]),
  diminishedSeventh('diminished seventh', 'dim7', [0, 3, 6, 9]);

  const ChordQuality(this.label, this.suffix, this.intervals);

  final String label;
  final String suffix;

  /// Semitone offsets above the root, low to high.
  final List<int> intervals;

  bool get isSeventh => intervals.length == 4;
}

/// A chord: a root plus a [ChordQuality]. [inversion] rotates the chord tones
/// so that another chord tone becomes the bass.
class Chord {
  const Chord({
    required this.rootName,
    required this.rootPitchClass,
    required this.rootLetter,
    required this.quality,
    required this.degree,
    this.flatDegree = false,
    this.inversion = 0,
  });

  /// Builds the diatonic chord on [degree] (1..7) of a seven-note [scale].
  ///
  /// When [seventh] is true a seventh is stacked on top of the triad.
  factory Chord.diatonic(
    Scale scale,
    int degree, {
    bool seventh = false,
    int inversion = 0,
  }) {
    assert(scale.isHeptatonic, 'Chords need a seven-note scale');
    final degrees = scale.type.degrees;
    final d = degree - 1;

    int semitones(int offset) {
      final index = d + offset;
      return degrees[index % 7].semitone + (index >= 7 ? 12 : 0);
    }

    final rootSemitones = semitones(0);
    final intervals = <int>[
      0,
      semitones(2) - rootSemitones,
      semitones(4) - rootSemitones,
      if (seventh) semitones(6) - rootSemitones,
    ];
    final quality = _qualityFor(intervals);
    final rootPitchClass = (scale.tonicPitchClass + rootSemitones) % 12;
    final rootLetter = NoteLetter.values[(scale.tonicLetter.index + d) % 7];

    return Chord(
      rootName: _spell(rootLetter, rootPitchClass),
      rootPitchClass: rootPitchClass,
      rootLetter: rootLetter,
      quality: quality,
      degree: degree,
      flatDegree: degrees[d].label.startsWith('\u266D'),
      inversion: inversion.clamp(0, quality.intervals.length - 1),
    );
  }

  final String rootName;
  final int rootPitchClass;
  final NoteLetter rootLetter;
  final ChordQuality quality;

  /// Scale degree of the root, 1..7.
  final int degree;

  /// Whether the scale degree's label carries a flat (used by [romanNumeral]).
  final bool flatDegree;

  final int inversion;

  List<int> get intervals => quality.intervals;

  /// Chord symbol, e.g. `C`, `Dm`, `G7` or `Bdim`.
  String get symbol => '$rootName${quality.suffix}';

  /// The chord tones as pitch classes, ordered from the bass upward for the
  /// current [inversion].
  List<int> get pitchClasses {
    final base = [
      for (final interval in intervals) (rootPitchClass + interval) % 12,
    ];
    final count = base.length;
    final rotation = inversion % count;
    return [for (var i = 0; i < count; i++) base[(i + rotation) % count]];
  }

  Set<int> get pitchClassSet => pitchClasses.toSet();

  /// Pitch class of the lowest sounding note.
  int get bassPitchClass => pitchClasses.first;

  /// Name of the bass note, e.g. `B` for the first inversion of `G7`.
  String get bassName {
    final letter = NoteLetter.values[(rootLetter.index + 2 * inversion) % 7];
    return _spell(letter, bassPitchClass);
  }

  /// Symbol including the slash bass when inverted, e.g. `G7/B`.
  String get displaySymbol => inversion == 0 ? symbol : '$symbol/$bassName';

  /// Roman numeral for the chord in its key, e.g. `V7`, `ii7` or `vii\u00B07`.
  String get romanNumeral {
    const numerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];
    final upper = (flatDegree ? '\u266D' : '') + numerals[(degree - 1) % 7];
    final lower = upper.toLowerCase();
    switch (quality) {
      case ChordQuality.major:
        return upper;
      case ChordQuality.augmented:
        return '$upper+';
      case ChordQuality.minor:
        return lower;
      case ChordQuality.diminished:
        return '$lower\u00B0';
      case ChordQuality.majorSeventh:
        return '${upper}maj7';
      case ChordQuality.dominantSeventh:
        return '${upper}7';
      case ChordQuality.minorSeventh:
        return '${lower}7';
      case ChordQuality.halfDiminishedSeventh:
        return '$lower\u00F87';
      case ChordQuality.diminishedSeventh:
        return '$lower\u00B07';
    }
  }

  /// Human readable inversion, e.g. `1st inversion`.
  String get inversionLabel {
    switch (inversion % intervals.length) {
      case 0:
        return 'root position';
      case 1:
        return '1st inversion';
      case 2:
        return '2nd inversion';
      default:
        return '3rd inversion';
    }
  }

  /// Staff steps of the chord voiced from [rootStep], low to high, for the
  /// current inversion. Each chord tone is a diatonic third above the last.
  List<int> staffSteps(int rootStep) {
    final count = intervals.length;
    final base = [for (var i = 0; i < count; i++) rootStep + 2 * i];
    final rotation = inversion % count;
    return [
      for (var i = 0; i < count; i++)
        i < count - rotation
            ? base[i + rotation]
            : base[i + rotation - count] + 7,
    ];
  }

  static ChordQuality _qualityFor(List<int> intervals) {
    for (final quality in ChordQuality.values) {
      if (quality.intervals.length != intervals.length) continue;
      var matches = true;
      for (var i = 0; i < intervals.length; i++) {
        if (quality.intervals[i] != intervals[i]) {
          matches = false;
          break;
        }
      }
      if (matches) return quality;
    }
    throw ArgumentError('Unsupported chord intervals: $intervals');
  }

  static String _spell(NoteLetter letter, int pitchClass) {
    var offset = pitchClass - letter.semitone;
    if (offset > 6) offset -= 12;
    if (offset < -6) offset += 12;
    final accidental = offset < 0
        ? Accidental.flat
        : offset > 0
        ? Accidental.sharp
        : Accidental.natural;
    final suffix = accidental == Accidental.natural ? '' : accidental.text;
    return '${letter.name}$suffix';
  }

  @override
  String toString() => displaySymbol;
}

/// A named sequence of scale degrees, e.g. the pop progression I V vi IV.
class ChordProgression {
  const ChordProgression(this.name, this.degrees);

  final String name;

  /// Scale degrees (1..7) played in order.
  final List<int> degrees;
}

/// A few progressions that sound good in the common major and minor moods.
const List<ChordProgression> kProgressions = [
  ChordProgression('Pop \u2013 I V vi IV', [1, 5, 6, 4]),
  ChordProgression('Doo-wop \u2013 I vi IV V', [1, 6, 4, 5]),
  ChordProgression('Jazz \u2013 ii V I', [2, 5, 1]),
  ChordProgression('Canon \u2013 I V vi iii IV I IV V', [
    1,
    5,
    6,
    3,
    4,
    1,
    4,
    5,
  ]),
  ChordProgression('Andalusian \u2013 i \u266DVII \u266DVI V', [1, 7, 6, 5]),
];
