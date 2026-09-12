import 'note.dart';

/// A musical clef.
///
/// Each clef maps a staff "step" (a half space, with `0` being the bottom
/// staff line and `8` the top line) to a [Note]. The [bottomLine] value is the
/// note that sits on the bottom line of the staff for this clef.
enum Clef {
  /// G clef. Bottom line is E4, the G4 line is the second line from the bottom.
  treble(
    label: 'Treble',
    glyph: '\uE050',
    bottomLine: Note(30), // E4
    glyphStep: 2,
  ),

  /// F clef. Bottom line is G2, the F3 line is the fourth line from the bottom.
  bass(
    label: 'Bass',
    glyph: '\uE062',
    bottomLine: Note(18), // G2
    glyphStep: 6,
  ),

  /// C clef. The C4 line is the middle line.
  alto(
    label: 'Alto',
    glyph: '\uE05C',
    bottomLine: Note(24), // F3
    glyphStep: 4,
  );

  const Clef({
    required this.label,
    required this.glyph,
    required this.bottomLine,
    required this.glyphStep,
  });

  /// Human readable name.
  final String label;

  /// SMuFL code point used to render the clef with a music font.
  final String glyph;

  /// The note written on the bottom line of the staff.
  final Note bottomLine;

  /// The staff step at which the glyph's origin (the line it references) sits.
  final int glyphStep;

  /// The note written at [step] (may be negative or greater than 8).
  Note noteAt(int step) => bottomLine.transpose(step);

  /// The inverse of [noteAt]: the diatonic step above the bottom line.
  int stepOf(Note note) => note.diatonicIndex - bottomLine.diatonicIndex;
}
