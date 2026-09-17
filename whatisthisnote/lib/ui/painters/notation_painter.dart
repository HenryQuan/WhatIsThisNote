import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/accidental.dart';
import '../../core/chord.dart';
import '../../core/clef.dart';
import '../../core/display_preferences.dart';
import '../../core/key.dart';
import '../../core/note.dart';
import '../../core/staff_geometry.dart';
import '../notation_glyphs.dart';

/// Default solfege spelling for the on-staff label. UI code swaps this out for
/// a localized resolver; the plain English/Italian names keep the painter
/// usable on its own (for example in tests).
String _defaultSolfegeName(Note note) => note.solfege;

/// Paints a five line staff, a clef, the key signature, the ledger lines
/// required by the current note and the note itself (with stem). Also paints a
/// small label next to the note showing its scientific and solfege names.
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

  void _paintStaff(Canvas canvas, Paint paint) {
    for (var line = 0; line < 5; line++) {
      final y = geometry.yForStep(line * 2);
      canvas.drawLine(
        Offset(geometry.staffLeft, y),
        Offset(geometry.staffRight, y),
        paint,
      );
    }
  }

  void _paintClef(Canvas canvas) {
    final painter = _layoutGlyph(clef.glyph, geometry.space * 4, lineColor);
    _paintGlyph(
      canvas,
      painter,
      x: geometry.staffLeft + geometry.space * 0.15,
      baselineY: geometry.yForStep(clef.glyphStep),
    );
  }

  void _paintKeySignature(Canvas canvas) {
    final items = key.signatureFor(clef);
    if (items.isEmpty) return;
    final spacing = geometry.space * 0.9;
    var x = geometry.staffLeft + (clef.advance + 0.35) * geometry.space;
    for (final item in items) {
      final glyph = _layoutGlyph(
        item.accidental.glyph,
        geometry.space * 4,
        lineColor,
      );
      _paintGlyph(canvas, glyph, x: x, baselineY: geometry.yForStep(item.step));
      x += spacing;
    }
  }

  /// Draws a phrase left to right, each note with its own stem and ledger
  /// lines, highlighting the note the learner is reading.
  void _paintMelody(Canvas canvas, Paint linePaint) {
    final count = melodySteps.length;
    final keyWidth = key.signatureFor(clef).length * geometry.space * 0.9;
    final startX =
        geometry.staffLeft +
        (clef.advance + 0.35) * geometry.space +
        keyWidth +
        geometry.space * 1.2;
    final endX = geometry.staffRight - geometry.space * 1.2;
    final spacing = count > 1 ? (endX - startX) / (count - 1) : 0.0;
    final stemLength = geometry.space * 3.5;

    for (var i = 0; i < count; i++) {
      final noteStep = melodySteps[i];
      final x = startX + spacing * i;
      final color = i == melodyIndex ? melodyActiveColor : noteColor;
      final stroke = Paint()
        ..color = color
        ..strokeWidth = (geometry.space * 0.12).clamp(1.2, 4.0)
        ..strokeCap = StrokeCap.round;

      for (final ledgerStep in geometry.ledgerStepsFor(noteStep)) {
        final y = geometry.yForStep(ledgerStep);
        canvas.drawLine(
          Offset(x - geometry.space * 0.95, y),
          Offset(x + geometry.space * 0.95, y),
          linePaint,
        );
      }

      final notehead = _layoutGlyph(
        NotationGlyphs.noteheadBlack,
        geometry.space * 4,
        color,
      );
      final noteY = geometry.yForStep(noteStep);
      final stemUp = noteStep < 4;
      final stemX = x + (stemUp ? 1 : -1) * notehead.width / 2;
      canvas.drawLine(
        Offset(stemX, noteY),
        Offset(stemX, noteY + (stemUp ? -stemLength : stemLength)),
        stroke,
      );
      _paintGlyph(canvas, notehead, centerX: x, baselineY: noteY);
    }
  }

  void _paintLedgerLines(Canvas canvas, Paint paint) {
    final notes = <int>[
      if (chordTones.isEmpty)
        step.round()
      else
        ...chordTones.map((tone) => tone.staffStep),
      ?targetStep,
    ];
    final halfWidth = geometry.space * 0.95;
    final drawn = <int>{};
    for (final note in notes) {
      for (final ledgerStep in geometry.ledgerStepsFor(note)) {
        if (!drawn.add(ledgerStep)) continue;
        final y = geometry.yForStep(ledgerStep);
        canvas.drawLine(
          Offset(noteX - halfWidth, y),
          Offset(noteX + halfWidth, y),
          paint,
        );
      }
    }
  }

  void _paintTarget(Canvas canvas) {
    final target = targetStep;
    if (target == null || target == step.round()) return;
    final color = targetColor ?? noteColor;
    final notehead = _layoutGlyph(
      NotationGlyphs.noteheadWhole,
      geometry.space * 4,
      color,
    );
    final targetY = geometry.yForStep(target.toDouble());
    final note = _writtenNote(target, targetAccidental);
    if (_needsAccidental(note)) {
      _paintAccidental(
        canvas,
        note.accidental,
        targetY,
        noteX - notehead.width / 2,
        color,
      );
    }
    _paintGlyph(canvas, notehead, centerX: noteX, baselineY: targetY);
  }

  /// Draws an accidental glyph just left of a notehead centred at [noteX] and
  /// [noteY], so a note can show a sharp, flat or natural outside the key.
  void _paintAccidental(
    Canvas canvas,
    Accidental accidental,
    double noteY,
    double noteLeft,
    Color color,
  ) {
    final glyph = _layoutGlyph(accidental.glyph, geometry.space * 4, color);
    final x = noteLeft - geometry.space * 0.08 - glyph.width;
    _paintGlyph(canvas, glyph, x: x, baselineY: noteY);
  }

  void _paintNote(Canvas canvas) {
    final notehead = _layoutGlyph(
      NotationGlyphs.noteheadBlack,
      geometry.space * 4,
      noteColor,
    );
    final noteY = geometry.yForStep(step);

    final stemUp = step < 4;
    final headHalfWidth = notehead.width / 2;
    final stemX = noteX + (stemUp ? headHalfWidth : -headHalfWidth);
    final stemLength = geometry.space * 3.5;
    final stemPaint = Paint()
      ..color = noteColor
      ..strokeWidth = (geometry.space * 0.12).clamp(1.2, 4.0)
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(stemX, noteY),
      Offset(stemX, noteY + (stemUp ? -stemLength : stemLength)),
      stemPaint,
    );

    final note = _writtenNote(step.round(), accidental);
    if (_needsAccidental(note)) {
      _paintAccidental(
        canvas,
        note.accidental,
        noteY,
        noteX - headHalfWidth,
        noteColor,
      );
    }

    _paintGlyph(canvas, notehead, centerX: noteX, baselineY: noteY);
  }

  void _paintChord(Canvas canvas) {
    final firstStep = chordTones.first.staffStep;
    final lastStep = chordTones.last.staffStep;
    final headHalfWidth =
        _layoutGlyph(
          NotationGlyphs.noteheadBlack,
          geometry.space * 4,
          noteColor,
        ).width /
        2;
    final stemUp = firstStep < 4;
    final stemLength = geometry.space * 3.5;
    final stemPaint = Paint()
      ..color = chordColor
      ..strokeWidth = (geometry.space * 0.12).clamp(1.2, 4.0)
      ..strokeCap = StrokeCap.round;

    final lowest = geometry.yForStep(firstStep);
    final highest = geometry.yForStep(lastStep);
    final stemX = noteX + (stemUp ? headHalfWidth : -headHalfWidth);
    canvas.drawLine(
      Offset(stemX, stemUp ? lowest : highest),
      Offset(stemX, stemUp ? highest - stemLength : lowest + stemLength),
      stemPaint,
    );

    for (final tone in chordTones) {
      final chordStep = tone.staffStep;
      final notehead = _layoutGlyph(
        NotationGlyphs.noteheadBlack,
        geometry.space * 4,
        tone.isRoot ? noteColor : chordColor,
      );
      final noteY = geometry.yForStep(chordStep);
      if (_needsAccidental(tone.note)) {
        _paintAccidental(
          canvas,
          tone.note.accidental,
          noteY,
          noteX - notehead.width / 2,
          tone.isRoot ? noteColor : chordColor,
        );
      }
      _paintGlyph(canvas, notehead, centerX: noteX, baselineY: noteY);
    }
  }

  void _paintLabel(Canvas canvas) {
    final painter = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: labelColor,
          fontSize: geometry.space * 0.95,
          fontWeight: FontWeight.w700,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final gap = geometry.space * 1.1;
    var x = noteX + gap;
    if (x + painter.width > geometry.staffRight) {
      x = noteX - gap - painter.width;
    }
    final y = geometry.yForStep(labelStep.toDouble()) - painter.height / 2;

    final pad = geometry.space * 0.16;
    final height = painter.height + pad * 2;
    final width = math.max(painter.width + pad * 2, height);
    final background = RRect.fromRectAndRadius(
      Rect.fromLTWH(x - (width - painter.width) / 2, y - pad, width, height),
      Radius.circular(height / 2),
    );
    canvas.drawRRect(background, Paint()..color = labelBackgroundColor);
    painter.paint(canvas, Offset(x, y));
  }

  TextPainter _layoutGlyph(String glyph, double fontSize, Color color) {
    return TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontFamily: 'Bravura',
          fontSize: fontSize,
          color: color,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  void _paintGlyph(
    Canvas canvas,
    TextPainter painter, {
    double? x,
    double? centerX,
    required double baselineY,
  }) {
    final baselineOffset = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    final dx = centerX != null ? centerX - painter.width / 2 : (x ?? 0);
    painter.paint(canvas, Offset(dx, baselineY - baselineOffset));
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
