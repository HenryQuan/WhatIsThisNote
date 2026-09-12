import 'dart:math' as math;

import 'accidental.dart';

/// The seven diatonic note letters used in western music notation.
enum NoteLetter {
  c('C', 'Do'),
  d('D', 'Re'),
  e('E', 'Mi'),
  f('F', 'Fa'),
  g('G', 'Sol'),
  a('A', 'La'),
  b('B', 'Si');

  const NoteLetter(this.name, this.solfege);

  /// Letter name in scientific pitch notation, e.g. `C`.
  final String name;

  /// Fixed-do solfege name, e.g. `Do`.
  final String solfege;

  /// Number used in numbered notation (jianpu): `1 == Do`, `2 == Re`, ...,
  /// `7 == Ti`.
  int get degree => index + 1;

  /// Semitone offset from C within the same octave.
  int get semitone => const [0, 2, 4, 5, 7, 9, 11][index];
}

/// A written note on the staff, independent of any clef.
///
/// Internally a note is a single integer, [diatonicIndex], where
/// `C0 == 0`, `D0 == 1`, ... `B0 == 6`, `C1 == 7` and so on. Moving one
/// diatonic step up the staff always increases the index by one, which makes
/// staff math (ledger lines, transposing by a third, ...) trivial.
///
/// [accidental] alters the sounding pitch without changing the staff position,
/// exactly like a sharp or flat in written music.
class Note implements Comparable<Note> {
  const Note(this.diatonicIndex, [this.accidental = Accidental.natural]);

  /// Creates a natural note from a letter and an octave, e.g.
  /// `Note.fromLetter(NoteLetter.e, 4)`.
  factory Note.fromLetter(NoteLetter letter, int octave) =>
      Note(octave * 7 + letter.index);

  final int diatonicIndex;
  final Accidental accidental;

  /// The letter of this note.
  NoteLetter get letter => NoteLetter.values[diatonicIndex % 7];

  /// The scientific octave number (C4 is middle C).
  int get octave => (diatonicIndex - (diatonicIndex % 7)) ~/ 7;

  /// Scientific pitch name without the octave, e.g. `F♯`.
  String get pitchName {
    final suffix = accidental == Accidental.natural ? '' : accidental.text;
    return '${letter.name}$suffix';
  }

  /// Scientific pitch name, e.g. `E4` or `F♯5`.
  String get name => '$pitchName$octave';

  /// Fixed-do solfege name, e.g. `Mi` or `Fa♯`.
  String get solfege {
    final suffix = accidental == Accidental.natural ? '' : accidental.text;
    return '${letter.solfege}$suffix';
  }

  /// Number used in numbered notation, `1` for Do through `7` for Ti. The
  /// octave above is `8` (again Do).
  int get degree => letter.degree;

  /// MIDI note number using standard tuning (C4 == 60).
  int get midi => (octave + 1) * 12 + letter.semitone + accidental.offset;

  /// Frequency in hertz using A4 == 440 Hz.
  double get frequency => 440.0 * math.pow(2, (midi - 69) / 12).toDouble();

  /// True when no accidental alters the letter.
  bool get isNatural => accidental == Accidental.natural;

  /// The other common spelling of this note, e.g. `G♭4` for `F♯4`, or `null`
  /// for natural notes (and for the rare note with no single-accidental twin).
  Note? get enharmonic {
    if (accidental == Accidental.natural) return null;
    final twinIndex =
        diatonicIndex + (accidental == Accidental.sharp ? 1 : -1);
    final naturalTwin = Note(twinIndex);
    final difference = midi - naturalTwin.midi;
    if (difference == 0) return naturalTwin;
    if (difference.abs() != 1) return null;
    return Note(twinIndex, difference > 0 ? Accidental.sharp : Accidental.flat);
  }

  /// Full enharmonic spelling, e.g. `G♭4`, or `null` for natural notes.
  String? get enharmonicName => enharmonic?.name;

  /// Returns a copy of this note with the given [accidental].
  Note withAccidental(Accidental accidental) =>
      Note(diatonicIndex, accidental);

  /// Returns a copy transposed by [steps] diatonic steps, keeping the
  /// accidental.
  Note transpose(int steps) => Note(diatonicIndex + steps, accidental);

  @override
  int compareTo(Note other) {
    final byPosition = diatonicIndex.compareTo(other.diatonicIndex);
    if (byPosition != 0) return byPosition;
    return accidental.offset.compareTo(other.accidental.offset);
  }

  @override
  bool operator ==(Object other) =>
      other is Note &&
      other.diatonicIndex == diatonicIndex &&
      other.accidental == accidental;

  @override
  int get hashCode => Object.hash(diatonicIndex, accidental);

  @override
  String toString() => name;
}
