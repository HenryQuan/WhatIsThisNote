part of '../chord.dart';

class Chord {
  const Chord({
    required this.rootName,
    required this.rootPitchClass,
    required this.rootLetter,
    required this.quality,
    required this.degree,
    this.degreeAccidental = '',
    this.diatonic = true,
    this.chromatic = false,
    this.inversion = 0,
  });

  /// Builds [root]'s chord with an explicit [quality], used when a specific
  /// chord (for example Fmaj13\u266F11) is picked from the readout instead of the
  /// scale's diatonic chord.
  factory Chord.onNote(Note root, ChordQuality quality, {int inversion = 0}) {
    return Chord(
      rootName: root.pitchName,
      rootPitchClass: root.midi % 12,
      rootLetter: root.letter,
      quality: quality,
      degree: 1,
      diatonic: false,
      inversion: inversion.clamp(0, quality.intervals.length - 1),
    );
  }

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
      degreeAccidental: degrees[d].label.startsWith('\u266D') ? '\u266D' : '',
      inversion: inversion.clamp(0, quality.intervals.length - 1),
    );
  }

  /// Builds the chord on a chromatic [root] that is not in [scale], keeping the
  /// scale's letter-degrees in the upper voices.
  ///
  /// Displacing the root from its scale tone alters every stacked interval, so
  /// a diatonic shape can come out transformed: lowering the root of a major
  /// triad yields a diminished one, raising the root of a minor triad yields an
  /// augmented one, and so on. This is the chord shown when the highlighted
  /// note lies outside the selected scale.
  factory Chord.chromatic(
    Scale scale,
    Note root, {
    ChordExtension extension = ChordExtension.triad,
    int inversion = 0,
  }) {
    assert(scale.isHeptatonic, 'Chords need a seven-note scale');
    final degrees = scale.type.degrees;
    var d = (root.letter.index - scale.tonicLetter.index) % 7;
    if (d < 0) d += 7;

    int scaleSemitone(int index) =>
        degrees[index % 7].semitone + (index ~/ 7) * 12;

    final scaleRoot = scaleSemitone(d);
    final scaleRootPitchClass = (scale.tonicPitchClass + scaleRoot) % 12;
    final rootPitchClass = root.midi % 12;
    var offset = (rootPitchClass - scaleRootPitchClass) % 12;
    if (offset > 6) offset -= 12;

    // The accidental on the roman numeral, measured against the tonic's major
    // scale so it reads the same in major and minor keys.
    final majorDegree =
        (scale.tonicPitchClass + ScaleType.major.degrees[d].semitone) % 12;
    var difference = (rootPitchClass - majorDegree) % 12;
    if (difference > 6) difference -= 12;
    final accidental = difference < 0
        ? '\u266D'
        : difference > 0
        ? '\u266F'
        : '';

    final scaleSteps = extension.scaleSteps;
    final intervals = <int>[
      for (var i = 0; i < scaleSteps.length; i++)
        i == 0 ? 0 : scaleSemitone(d + scaleSteps[i]) - scaleRoot - offset,
    ];
    final quality = ChordQuality.fromStack(scaleSteps, intervals);

    return Chord(
      rootName: root.pitchName,
      rootPitchClass: rootPitchClass,
      rootLetter: root.letter,
      quality: quality,
      degree: d + 1,
      degreeAccidental: accidental,
      diatonic: false,
      chromatic: true,
      inversion: inversion.clamp(0, quality.intervals.length - 1),
    );
  }

  final String rootName;
  final int rootPitchClass;
  final NoteLetter rootLetter;
  final ChordQuality quality;

  /// Scale degree of the root, 1..7.
  final int degree;

  /// Whether the chord is the scale's diatonic chord, rather than a specific
  /// chord picked from the readout or a chromatic transformation.
  final bool diatonic;

  /// Whether the chord is a chromatic transformation of a scale chord: the
  /// root lies outside the scale but the upper voices keep the scale's
  /// letter-degrees (see [Chord.chromatic]).
  final bool chromatic;

  /// Accidental prefixed to the roman numeral's degree, e.g. `♭` or `♯`.
  final String degreeAccidental;

  final int inversion;

  List<int> get intervals => quality.intervals;

  /// Diatonic steps of each chord tone above the root, low to high.
  List<int> get scaleSteps => quality.scaleSteps;

  /// The chord tones spelled from the root, low to high, e.g. `C`, `E`, `G\u266F`.
  ///
  /// Each tone keeps its diatonic letter, so the enharmonic spelling of the
  /// same pitch classes differs by root (`C\u2013E\u2013G\u266F` for Caug but
  /// `E\u2013G\u266F\u2013B\u266F` for Eaug).
  List<String> get noteNames => [
    for (var i = 0; i < scaleSteps.length; i++)
      _spell(
        NoteLetter.values[(rootLetter.index + scaleSteps[i]) % 7],
        (rootPitchClass + intervals[i]) % 12,
      ),
  ];

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

  /// Each chord tone's pitch class mapped to its spelled name, e.g.
  /// `{0: 'C', 4: 'E', 7: 'G', 11: 'B'}` for Cmaj7.
  Map<int, String> get pitchClassNames {
    final result = <int, String>{};
    for (var i = 0; i < intervals.length; i++) {
      result[(rootPitchClass + intervals[i]) % 12] = noteNames[i];
    }
    return result;
  }

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
    final upper = '$degreeAccidental${numerals[(degree - 1) % 7]}';
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

  static String _spell(NoteLetter letter, int pitchClass) {
    var offset = pitchClass - letter.semitone;
    if (offset > 6) offset -= 12;
    if (offset < -6) offset += 12;
    final accidental = offset < 0
        ? offset == -2
              ? Accidental.doubleFlat
              : Accidental.flat
        : offset > 0
        ? offset == 2
              ? Accidental.doubleSharp
              : Accidental.sharp
        : Accidental.natural;
    final suffix = accidental == Accidental.natural ? '' : accidental.text;
    return '${letter.name}$suffix';
  }

  @override
  String toString() => displaySymbol;
}

/// One exact chord tone in a staff voicing.
