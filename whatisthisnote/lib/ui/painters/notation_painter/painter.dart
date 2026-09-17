part of '../notation_painter.dart';

class NotationPainter extends CustomPainter {
  NotationPainter({
    required this.geometry,
    required this.clef,
    required this.key,
    required this.step,
    required this.noteX,
    required this.lineColor,
    required this.noteColor,
    required this.labelColor,
    required this.labelBackgroundColor,
    required this.showLabel,
    this.naming = NamingSystem.scientific,
    this.showEnharmonic = false,
    this.solfegeName = _defaultSolfegeName,
    this.chordTones = const [],
    this.chordColor = const Color(0xFF000000),
    this.targetStep,
    this.targetColor,
    this.accidental,
    this.targetAccidental,
    this.melodySteps = const [],
    this.melodyIndex = 0,
    this.melodyActiveColor = const Color(0xFF000000),
  });

  final StaffGeometry geometry;
  final Clef clef;
  final MusicalKey key;

  /// Continuous (possibly fractional) staff step of the note. Fractional
  /// values are used while dragging.
  final double step;

  /// Horizontal centre of the note.
  final double noteX;

  final Color lineColor;
  final Color noteColor;
  final Color labelColor;
  final Color labelBackgroundColor;
  final bool showLabel;

  /// Which naming system the label uses, plus whether the enharmonic spelling
  /// is appended.
  final NamingSystem naming;
  final bool showEnharmonic;

  /// Localized spelling of a note's fixed-do solfege name, used when [naming]
  /// is [NamingSystem.solfege].
  final String Function(Note note) solfegeName;

  /// Exact tones of the current chord, low to high. Empty for a single note.
  final List<ChordToneAtStaff> chordTones;

  /// Colour used for the chord tones other than the root.
  final Color chordColor;

  /// Optional target staff step to hint at, drawn as a hollow notehead.
  final int? targetStep;

  /// Colour of the hollow target notehead. Defaults to [noteColor].
  final Color? targetColor;

  /// Accidental written on the note, overriding the key signature. `null` uses
  /// the key's accidental for the note's letter.
  final Accidental? accidental;

  /// Accidental written on the hollow [targetStep] notehead.
  final Accidental? targetAccidental;

  /// Staff steps of a phrase drawn left to right. Empty for a single note.
  final List<int> melodySteps;

  /// Index of the phrase note the learner is currently reading; drawn in
  /// [melodyActiveColor] and the rest in [noteColor].
  final int melodyIndex;

  /// Colour of the active phrase note.
  final Color melodyActiveColor;

  /// Staff step the label describes: the lowest chord tone (the bass) when a
  /// chord is shown, otherwise the written note.
  int get labelStep =>
      chordTones.isEmpty ? step.round() : chordTones.first.staffStep;

  /// The note written at [step], taking the explicit [override] into account.
  Note _writtenNote(int step, Accidental? override) {
    final note = key.applyTo(clef.noteAt(step));
    return override == null ? note : note.withAccidental(override);
  }

  /// Whether [note] needs a printed accidental because it differs from what the
  /// key signature already implies for its letter.
  bool _needsAccidental(Note note) =>
      note.accidental != key.accidentalFor(note.letter);

  /// The note the label describes, including any explicit accidental.
  Note get _labelNote {
    if (chordTones.isNotEmpty) return chordTones.first.note;
    if (accidental != null) {
      return key.applyTo(clef.noteAt(labelStep)).withAccidental(accidental!);
    }
    return key.applyTo(clef.noteAt(labelStep));
  }

  /// Name shown by the label next to the note (or the chord bass), using the
  /// selected naming system.
  String get labelNoteName {
    final note = _labelNote;
    switch (naming) {
      case NamingSystem.scientific:
        return note.pitchName;
      case NamingSystem.solfege:
        return solfegeName(note);
      case NamingSystem.jianpu:
        return key.jianpuFor(note);
    }
  }

  /// Full text drawn in the label: the name, plus the enharmonic spelling when
  /// that preference is on.
  String get labelText {
    final note = _labelNote;
    final twin = showEnharmonic ? note.enharmonic?.pitchName : null;
    return twin == null ? labelNoteName : '$labelNoteName/$twin';
  }

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = (geometry.space * 0.11).clamp(1.0, 4.0)
      ..strokeCap = StrokeCap.round;

    _paintStaff(canvas, linePaint);
    _paintClef(canvas);
    _paintKeySignature(canvas);
    if (melodySteps.isNotEmpty) {
      _paintMelody(canvas, linePaint);
      return;
    }
    _paintLedgerLines(canvas, linePaint);
    _paintTarget(canvas);
    if (chordTones.isEmpty) {
      _paintNote(canvas);
    } else {
      _paintChord(canvas);
    }
    if (showLabel) {
      _paintLabel(canvas);
    }
  }

  @override
  bool shouldRepaint(covariant NotationPainter old) {
    return old.geometry.size != geometry.size ||
        old.geometry.space != geometry.space ||
        old.clef != clef ||
        old.key != key ||
        old.step != step ||
        old.noteX != noteX ||
        old.lineColor != lineColor ||
        old.noteColor != noteColor ||
        old.labelColor != labelColor ||
        old.labelBackgroundColor != labelBackgroundColor ||
        old.showLabel != showLabel ||
        old.naming != naming ||
        old.showEnharmonic != showEnharmonic ||
        !listEquals(old.chordTones, chordTones) ||
        old.chordColor != chordColor ||
        old.targetStep != targetStep ||
        old.targetColor != targetColor ||
        old.accidental != accidental ||
        old.targetAccidental != targetAccidental ||
        !listEquals(old.melodySteps, melodySteps) ||
        old.melodyIndex != melodyIndex ||
        old.melodyActiveColor != melodyActiveColor;
  }
}
