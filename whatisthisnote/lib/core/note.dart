import 'dart:math' as math;

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

  /// Semitone offset from C within the same octave.
  int get semitone => const [0, 2, 4, 5, 7, 9, 11][index];
}

/// A written note on the staff, independent of any clef.
///
/// Internally a note is a single integer, [diatonicIndex], where
/// `C0 == 0`, `D0 == 1`, ... `B0 == 6`, `C1 == 7` and so on. Moving one
/// diatonic step up the staff always increases the index by one, which makes
/// staff math (ledger lines, transposing by a third, ...) trivial.
class Note implements Comparable<Note> {
  const Note(this.diatonicIndex);

  /// Creates a note from a letter and an octave, e.g. `Note.fromLetter(NoteLetter.e, 4)`.
  factory Note.fromLetter(NoteLetter letter, int octave) =>
      Note(octave * 7 + letter.index);

  final int diatonicIndex;

  /// The letter of this note.
  NoteLetter get letter => NoteLetter.values[diatonicIndex % 7];

  /// The scientific octave number (C4 is middle C).
  int get octave => (diatonicIndex - (diatonicIndex % 7)) ~/ 7;

  /// Scientific pitch name, e.g. `E4`.
  String get name => '${letter.name}$octave';

  /// Fixed-do solfege name, e.g. `Mi`.
  String get solfege => letter.solfege;

  /// MIDI note number using standard tuning (C4 == 60).
  int get midi => (octave + 1) * 12 + letter.semitone;

  /// Frequency in hertz using A4 == 440 Hz.
  double get frequency => 440.0 * math.pow(2, (midi - 69) / 12).toDouble();

  /// Returns a copy transposed by [steps] diatonic steps.
  Note transpose(int steps) => Note(diatonicIndex + steps);

  @override
  int compareTo(Note other) => diatonicIndex.compareTo(other.diatonicIndex);

  @override
  bool operator ==(Object other) =>
      other is Note && other.diatonicIndex == diatonicIndex;

  @override
  int get hashCode => diatonicIndex.hashCode;

  @override
  String toString() => name;
}
