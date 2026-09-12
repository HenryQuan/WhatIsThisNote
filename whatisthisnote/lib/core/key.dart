import 'accidental.dart';
import 'clef.dart';
import 'note.dart';

/// Whether a key is major or minor.
enum KeyMode { major, minor }

/// One accidental of a key signature and the staff step it is written on
/// (which depends on the clef).
class SignatureAccidental {
  const SignatureAccidental(this.accidental, this.step);

  final Accidental accidental;
  final int step;
}

/// A musical key: a tonic, a mode and the number of sharps (positive) or
/// flats (negative) in its key signature.
class MusicalKey {
  const MusicalKey(this.tonic, this.mode, this.accidentals);

  /// Tonic name, e.g. `C`, `F♯` or `B♭`.
  final String tonic;

  final KeyMode mode;

  /// Positive for sharps, negative for flats, `0` for C major / A minor.
  final int accidentals;

  static const NoteLetter _c = NoteLetter.c;
  static const NoteLetter _d = NoteLetter.d;
  static const NoteLetter _e = NoteLetter.e;
  static const NoteLetter _f = NoteLetter.f;
  static const NoteLetter _g = NoteLetter.g;
  static const NoteLetter _a = NoteLetter.a;
  static const NoteLetter _b = NoteLetter.b;

  /// The order sharps are added: F C G D A E B.
  static const List<NoteLetter> sharpOrder = [_f, _c, _g, _d, _a, _e, _b];

  /// The order flats are added: B E A D G C F.
  static const List<NoteLetter> flatOrder = [_b, _e, _a, _d, _g, _c, _f];

  /// Display name, e.g. `G major`.
  String get label => '$tonic ${mode == KeyMode.major ? 'major' : 'minor'}';

  /// Number of accidentals, always non-negative.
  int get signatureCount => accidentals.abs();

  /// The tonic letter, parsed from [tonic].
  NoteLetter get tonicLetter =>
      NoteLetter.values.firstWhere((letter) => letter.name == tonic[0]);

  /// The accidental of the tonic, parsed from [tonic].
  Accidental get tonicAccidental {
    if (tonic.contains('\u266F')) return Accidental.sharp;
    if (tonic.contains('\u266D')) return Accidental.flat;
    return Accidental.natural;
  }

  /// Pitch class of the tonic, 0 == C.
  int get tonicPitchClass {
    final pitchClass = tonicLetter.semitone + tonicAccidental.offset;
    return (pitchClass % 12 + 12) % 12;
  }

  /// Description of the signature, e.g. `2 sharps`.
  String get signatureLabel {
    if (accidentals == 0) return 'no sharps or flats';
    final count = signatureCount;
    final name = accidentals > 0 ? 'sharp' : 'flat';
    return '$count $name${count == 1 ? '' : 's'}';
  }

  /// The note names altered by this signature, in writing order, e.g.
  /// `F♯, C♯` for D major. Empty for C major / A minor.
  String get signatureNotes {
    if (accidentals == 0) return '';
    final order = accidentals > 0 ? sharpOrder : flatOrder;
    final accidental = accidentals > 0 ? Accidental.sharp : Accidental.flat;
    return order
        .take(signatureCount)
        .map((letter) => '${letter.name}${accidental.text}')
        .join(', ');
  }

  /// The accidental a written [letter] takes inside this key.
  Accidental accidentalFor(NoteLetter letter) {
    if (accidentals > 0) {
      return sharpOrder.take(accidentals).contains(letter)
          ? Accidental.sharp
          : Accidental.natural;
    }
    if (accidentals < 0) {
      return flatOrder.take(-accidentals).contains(letter)
          ? Accidental.flat
          : Accidental.natural;
    }
    return Accidental.natural;
  }

  /// Applies this key signature to a written [note].
  Note applyTo(Note note) => note.withAccidental(accidentalFor(note.letter));

  /// The accidentals to draw on [clef]'s staff, in order.
  List<SignatureAccidental> signatureFor(Clef clef) {
    if (accidentals > 0) {
      final steps = clef.sharpSignatureSteps;
      return [
        for (var i = 0; i < accidentals; i++)
          SignatureAccidental(Accidental.sharp, steps[i]),
      ];
    }
    if (accidentals < 0) {
      final steps = clef.flatSignatureSteps;
      return [
        for (var i = 0; i < -accidentals; i++)
          SignatureAccidental(Accidental.flat, steps[i]),
      ];
    }
    return const [];
  }

  @override
  bool operator ==(Object other) =>
      other is MusicalKey &&
      other.tonic == tonic &&
      other.mode == mode &&
      other.accidentals == accidentals;

  @override
  int get hashCode => Object.hash(tonic, mode, accidentals);

  @override
  String toString() => label;
}

/// The fifteen major keys, ordered by number of accidentals.
const List<MusicalKey> kMajorKeys = [
  MusicalKey('C', KeyMode.major, 0),
  MusicalKey('G', KeyMode.major, 1),
  MusicalKey('D', KeyMode.major, 2),
  MusicalKey('A', KeyMode.major, 3),
  MusicalKey('E', KeyMode.major, 4),
  MusicalKey('B', KeyMode.major, 5),
  MusicalKey('F♯', KeyMode.major, 6),
  MusicalKey('C♯', KeyMode.major, 7),
  MusicalKey('F', KeyMode.major, -1),
  MusicalKey('B♭', KeyMode.major, -2),
  MusicalKey('E♭', KeyMode.major, -3),
  MusicalKey('A♭', KeyMode.major, -4),
  MusicalKey('D♭', KeyMode.major, -5),
  MusicalKey('G♭', KeyMode.major, -6),
  MusicalKey('C♭', KeyMode.major, -7),
];

/// The fifteen minor keys, ordered by number of accidentals.
const List<MusicalKey> kMinorKeys = [
  MusicalKey('A', KeyMode.minor, 0),
  MusicalKey('E', KeyMode.minor, 1),
  MusicalKey('B', KeyMode.minor, 2),
  MusicalKey('F♯', KeyMode.minor, 3),
  MusicalKey('C♯', KeyMode.minor, 4),
  MusicalKey('G♯', KeyMode.minor, 5),
  MusicalKey('D♯', KeyMode.minor, 6),
  MusicalKey('A♯', KeyMode.minor, 7),
  MusicalKey('D', KeyMode.minor, -1),
  MusicalKey('G', KeyMode.minor, -2),
  MusicalKey('C', KeyMode.minor, -3),
  MusicalKey('F', KeyMode.minor, -4),
  MusicalKey('B♭', KeyMode.minor, -5),
  MusicalKey('E♭', KeyMode.minor, -6),
  MusicalKey('A♭', KeyMode.minor, -7),
];

/// All thirty keys, majors then minors.
const List<MusicalKey> kAllKeys = [...kMajorKeys, ...kMinorKeys];
