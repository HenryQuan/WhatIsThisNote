import 'accidental.dart';
import 'note.dart';
import 'scale.dart';

/// How many scale tones are stacked above the root of a diatonic chord.
///
/// Steps are counted in scale degrees: a seventh stacks the root, third, fifth
/// and seventh, and a thirteenth keeps stacking thirds up to the thirteenth.
/// The sixth is the exception, replacing the seventh with the sixth degree.
enum ChordExtension {
  triad('Triads', [0, 2, 4]),
  sixth('Sixths', [0, 2, 4, 5]),
  seventh('Sevenths', [0, 2, 4, 6]),
  ninth('Ninths', [0, 2, 4, 6, 8]),
  eleventh('Elevenths', [0, 2, 4, 6, 8, 10]),
  thirteenth('Thirteenths', [0, 2, 4, 6, 8, 10, 12]);

  const ChordExtension(this.label, this.scaleSteps);

  final String label;

  /// Diatonic steps above the root, low to high.
  final List<int> scaleSteps;

  int get toneCount => scaleSteps.length;
}

/// The states of the chord lab add-on, from off to full thirteenth chords.
enum ChordMode {
  off('Off', null),
  triads('Triads', ChordExtension.triad),
  sixths('Sixths', ChordExtension.sixth),
  sevenths('Sevenths', ChordExtension.seventh),
  ninths('Ninths', ChordExtension.ninth),
  elevenths('Elevenths', ChordExtension.eleventh),
  thirteenths('Thirteenths', ChordExtension.thirteenth);

  const ChordMode(this.label, this.extension);

  final String label;

  /// The stack this mode builds, or `null` when the lab is off.
  final ChordExtension? extension;

  bool get isOn => extension != null;
}

/// The quality of a chord: its human readable [label], the symbol [suffix]
/// (e.g. `m` for a minor triad) and the [romanSuffix] after the roman numeral.
///
/// Extended chords keep intervals above an octave: a ninth is 14 semitones, an
/// eleventh 17 and a thirteenth 21.
class ChordQuality {
  const ChordQuality(this.label, this.suffix, this.romanSuffix, this.intervals);

  final String label;
  final String suffix;
  final String romanSuffix;

  /// Semitone offsets above the root, low to high.
  final List<int> intervals;

  bool get isSeventh => intervals.length == 4;

  /// Whether the third is minor, so the roman numeral is lower case.
  bool get hasMinorThird => intervals[1] == 3;

  static const major = ChordQuality('major', '', '', [0, 4, 7]);
  static const minor = ChordQuality('minor', 'm', '', [0, 3, 7]);
  static const diminished = ChordQuality('diminished', 'dim', '\u00B0', [
    0,
    3,
    6,
  ]);
  static const augmented = ChordQuality('augmented', 'aug', '+', [0, 4, 8]);
  static const majorSixth = ChordQuality('major sixth', '6', '6', [0, 4, 7, 9]);
  static const minorSixth = ChordQuality('minor sixth', 'm6', '6', [
    0,
    3,
    7,
    9,
  ]);
  static const majorSeventh = ChordQuality('major seventh', 'maj7', 'maj7', [
    0,
    4,
    7,
    11,
  ]);
  static const dominantSeventh = ChordQuality('dominant seventh', '7', '7', [
    0,
    4,
    7,
    10,
  ]);
  static const minorSeventh = ChordQuality('minor seventh', 'm7', '7', [
    0,
    3,
    7,
    10,
  ]);
  static const halfDiminishedSeventh = ChordQuality(
    'half-diminished seventh',
    'm7\u266D5',
    '\u00F87',
    [0, 3, 6, 10],
  );
  static const diminishedSeventh = ChordQuality(
    'diminished seventh',
    'dim7',
    '\u00B07',
    [0, 3, 6, 9],
  );

  /// Names the chord built from a diatonic stack of [scaleSteps] with the
  /// matching semitone [intervals]. The highest natural extension names the
  /// chord; degrees that do not match their major-scale spelling are shown as
  /// alterations (for example a flat ninth or sharp eleventh).
  factory ChordQuality.fromStack(List<int> scaleSteps, List<int> intervals) {
    final byStep = <int, int>{
      for (var i = 0; i < scaleSteps.length; i++) scaleSteps[i]: intervals[i],
    };
    final third = byStep[2]!;
    final fifth = byStep[4]!;
    final sixth = byStep[5];
    final seventh = byStep[6];
    final ninth = byStep[8];
    final eleventh = byStep[10];
    final thirteenth = byStep[12];

    // Triads and sixths are complete on their own.
    if (seventh == null) {
      if (sixth != null) {
        final six = sixth == 9 ? '6' : '\u266D6';
        final sixWord = sixth == 9 ? 'sixth' : 'flat sixth';
        if (third == 4 && fifth == 7) {
          return ChordQuality('major $sixWord', six, six, intervals);
        }
        if (third == 3 && fifth == 7) {
          return ChordQuality('minor $sixWord', 'm$six', six, intervals);
        }
        if (third == 4 && fifth == 8) {
          return ChordQuality(
            'augmented $sixWord',
            'aug$six',
            '+$six',
            intervals,
          );
        }
        return ChordQuality(
          'diminished $sixWord',
          'dim$six',
          '\u00B0$six',
          intervals,
        );
      }
      if (third == 4 && fifth == 7) return ChordQuality.major;
      if (third == 3 && fifth == 7) return ChordQuality.minor;
      if (third == 4 && fifth == 8) return ChordQuality.augmented;
      return ChordQuality.diminished;
    }

    // Seventh quality, kept as the parts an extension number replaces.
    String base;
    String baseRoman;
    String baseLabel;
    String extSuffix;
    String extRoman;
    String extLabel;
    var flatFive = false;

    if (third == 3 && fifth == 6) {
      if (seventh == 9) {
        base = 'dim7';
        baseRoman = '\u00B07';
        baseLabel = 'diminished seventh';
        extSuffix = 'dim';
        extRoman = '\u00B0';
        extLabel = 'diminished ';
      } else if (seventh == 11) {
        base = 'mMaj7\u266D5';
        baseRoman = 'mMaj7\u266D5';
        baseLabel = 'minor-major seventh flat five';
        extSuffix = 'mMaj';
        extRoman = 'mMaj';
        extLabel = 'minor-major ';
        flatFive = true;
      } else {
        base = 'm7\u266D5';
        baseRoman = '\u00F87';
        baseLabel = 'half-diminished seventh';
        extSuffix = 'm';
        extRoman = '\u00F8';
        extLabel = 'half-diminished ';
        flatFive = true;
      }
    } else if (third == 3 && fifth == 7) {
      if (seventh == 11) {
        base = 'mMaj7';
        baseRoman = 'mMaj7';
        baseLabel = 'minor-major seventh';
        extSuffix = 'mMaj';
        extRoman = 'mMaj';
        extLabel = 'minor-major ';
      } else {
        base = 'm7';
        baseRoman = '7';
        baseLabel = 'minor seventh';
        extSuffix = 'm';
        extRoman = '';
        extLabel = 'minor ';
      }
    } else if (third == 4 && fifth == 7) {
      if (seventh == 11) {
        base = 'maj7';
        baseRoman = 'maj7';
        baseLabel = 'major seventh';
        extSuffix = 'maj';
        extRoman = 'maj';
        extLabel = 'major ';
      } else {
        base = '7';
        baseRoman = '7';
        baseLabel = 'dominant seventh';
        extSuffix = '';
        extRoman = '';
        extLabel = 'dominant ';
      }
    } else {
      if (seventh == 11) {
        base = 'augMaj7';
        baseRoman = '+maj7';
        baseLabel = 'augmented major seventh';
        extSuffix = 'augMaj';
        extRoman = '+maj';
        extLabel = 'augmented major ';
      } else {
        base = 'aug7';
        baseRoman = '+7';
        baseLabel = 'augmented seventh';
        extSuffix = 'aug';
        extRoman = '+';
        extLabel = 'augmented ';
      }
    }

    final hasNatural9 = ninth == 14;
    final hasNatural11 = eleventh == 17;
    final hasNatural13 = thirteenth == 21;

    String? primary;
    String? primaryWord;
    if (hasNatural13) {
      primary = '13';
      primaryWord = 'thirteenth';
    } else if (hasNatural11) {
      primary = '11';
      primaryWord = 'eleventh';
    } else if (hasNatural9) {
      primary = '9';
      primaryWord = 'ninth';
    }

    final alterations = <String>[];
    final alterationWords = <String>[];
    if (ninth != null && !hasNatural9) {
      alterations.add(ninth == 13 ? '\u266D9' : '\u266F9');
      alterationWords.add(ninth == 13 ? 'flat ninth' : 'sharp ninth');
    }
    if (eleventh != null && !hasNatural11) {
      alterations.add('\u266F11');
      alterationWords.add('sharp eleventh');
    }
    if (thirteenth != null && !hasNatural13) {
      alterations.add('\u266D13');
      alterationWords.add('flat thirteenth');
    }

    String suffix;
    String roman;
    String label;
    if (primary != null) {
      suffix = '$extSuffix$primary${flatFive ? '\u266D5' : ''}';
      roman =
          '$extRoman$primary'
          '${flatFive && extRoman != '\u00F8' ? '\u266D5' : ''}';
      label =
          '$extLabel$primaryWord'
          '${flatFive && extRoman != '\u00F8' ? ' flat five' : ''}';
    } else {
      suffix = base;
      roman = baseRoman;
      label = baseLabel;
    }
    if (alterations.isNotEmpty) {
      suffix += alterations.join();
      roman += alterations.join();
      label += ' ${alterationWords.join(' ')}';
    }
    return ChordQuality(label, suffix, roman, intervals);
  }

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

/// A chord: a root plus a [ChordQuality]. [inversion] rotates the chord tones
/// so that another chord tone becomes the bass.
class Chord {
  const Chord({
    required this.rootName,
    required this.rootPitchClass,
    required this.rootLetter,
    required this.quality,
    required this.degree,
    required this.scaleSteps,
    this.flatDegree = false,
    this.inversion = 0,
  });

  /// Builds the diatonic chord on [degree] (1..7) of a seven-note [scale],
  /// stacking [extension] above the root.
  factory Chord.diatonic(
    Scale scale,
    int degree, {
    ChordExtension extension = ChordExtension.triad,
    int inversion = 0,
  }) {
    assert(scale.isHeptatonic, 'Chords need a seven-note scale');
    final degrees = scale.type.degrees;
    final d = degree - 1;

    int scaleSemitone(int index) =>
        degrees[index % 7].semitone + (index ~/ 7) * 12;

    final rootSemitones = scaleSemitone(d);
    final scaleSteps = extension.scaleSteps;
    final intervals = <int>[
      for (final step in scaleSteps) scaleSemitone(d + step) - rootSemitones,
    ];
    final quality = ChordQuality.fromStack(scaleSteps, intervals);
    final rootPitchClass = (scale.tonicPitchClass + rootSemitones) % 12;
    final rootLetter = NoteLetter.values[(scale.tonicLetter.index + d) % 7];

    return Chord(
      rootName: _spell(rootLetter, rootPitchClass),
      rootPitchClass: rootPitchClass,
      rootLetter: rootLetter,
      quality: quality,
      degree: degree,
      scaleSteps: scaleSteps,
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

  /// Diatonic steps of each chord tone above the root, low to high.
  final List<int> scaleSteps;

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
    final offset = scaleSteps[inversion % scaleSteps.length];
    final letter = NoteLetter.values[(rootLetter.index + offset) % 7];
    return _spell(letter, bassPitchClass);
  }

  /// Symbol including the slash bass when inverted, e.g. `G7/B`.
  String get displaySymbol => inversion == 0 ? symbol : '$symbol/$bassName';

  /// Roman numeral for the chord in its key, e.g. `V7`, `ii7` or `vii\u00B07`.
  String get romanNumeral {
    const numerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];
    final upper = (flatDegree ? '\u266D' : '') + numerals[(degree - 1) % 7];
    final numeral = quality.hasMinorThird ? upper.toLowerCase() : upper;
    return '$numeral${quality.romanSuffix}';
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
      case 3:
        return '3rd inversion';
      case 4:
        return '4th inversion';
      case 5:
        return '5th inversion';
      default:
        return '6th inversion';
    }
  }

  /// Staff steps of the chord voiced from [rootStep], low to high, for the
  /// current inversion. The lowest note is lifted an octave above the top of
  /// the stack so extended chords stay in ascending order.
  List<int> staffSteps(int rootStep) {
    final count = scaleSteps.length;
    final lift = ((scaleSteps.last ~/ 7) + 1) * 7;
    final base = [for (var i = 0; i < count; i++) rootStep + scaleSteps[i]];
    final rotation = inversion % count;
    return [
      for (var i = 0; i < count; i++)
        i < count - rotation
            ? base[i + rotation]
            : base[i + rotation - count] + lift,
    ];
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

/// Progressions that sound good in the common major and minor moods.
///
/// Each entry lists scale degrees (1..7) of whatever seven-note scale is
/// selected, so the same list reads as I V vi IV in a major key and i v VI iv
/// in a minor one. Names with an explicit minor numeral mark progressions
/// that only make musical sense in a minor mood.
const List<ChordProgression> kProgressions = [
  // Major moods.
  ChordProgression('Pop \u2013 I V vi IV', [1, 5, 6, 4]),
  ChordProgression('Doo-wop \u2013 I vi IV V', [1, 6, 4, 5]),
  ChordProgression('Axis \u2013 vi IV I V', [6, 4, 1, 5]),
  ChordProgression('Folk \u2013 I IV V', [1, 4, 5]),
  ChordProgression('Rock \u2013 I IV V IV', [1, 4, 5, 4]),
  ChordProgression('Anthem \u2013 I V IV I', [1, 5, 4, 1]),
  ChordProgression('Singer \u2013 I iii IV V', [1, 3, 4, 5]),
  ChordProgression('Pop \u2013 I IV vi V', [1, 4, 6, 5]),
  ChordProgression('Ballad \u2013 I vi IV I', [1, 6, 4, 1]),
  ChordProgression('Emo \u2013 I V vi iii', [1, 5, 6, 3]),
  ChordProgression('Cadence \u2013 IV V I', [4, 5, 1]),
  // Jazz and turnarounds.
  ChordProgression('Jazz \u2013 ii V I', [2, 5, 1]),
  ChordProgression('Turnaround \u2013 I vi ii V', [1, 6, 2, 5]),
  ChordProgression('Circle \u2013 vi ii V I', [6, 2, 5, 1]),
  ChordProgression('Jazz \u2013 iii vi ii V', [3, 6, 2, 5]),
  ChordProgression('Jazz \u2013 ii V I vi', [2, 5, 1, 6]),
  // Minor moods (the flat numerals are how they read in a minor scale).
  ChordProgression('Minor pop \u2013 i \u266DVI \u266DIII \u266DVII', [
    1,
    6,
    3,
    7,
  ]),
  ChordProgression('Minor rock \u2013 i \u266DVII \u266DVI \u266DVII', [
    1,
    7,
    6,
    7,
  ]),
  ChordProgression('Minor \u2013 i iv v i', [1, 4, 5, 1]),
  ChordProgression('Minor \u2013 i \u266DVI iv v', [1, 6, 4, 5]),
  ChordProgression('Minor \u2013 i iv \u266DVII \u266DIII', [1, 4, 7, 3]),
  ChordProgression('Andalusian \u2013 i \u266DVII \u266DVI V', [1, 7, 6, 5]),
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
];
