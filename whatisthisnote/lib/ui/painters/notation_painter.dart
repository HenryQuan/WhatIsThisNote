import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/clef.dart';
import '../../core/key.dart';
import '../../core/staff_geometry.dart';
import '../notation_glyphs.dart';

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
    this.chordSteps = const [],
    this.chordColor = const Color(0xFF000000),
    this.targetStep,
    this.targetColor,
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

  /// Staff steps of the current chord, low to high. Empty for a single note.
  final List<int> chordSteps;

  /// Colour used for the chord tones other than the root.
  final Color chordColor;

  /// Optional target staff step to hint at, drawn as a hollow notehead.
  final int? targetStep;

  /// Colour of the hollow target notehead. Defaults to [noteColor].
  final Color? targetColor;

  /// Staff step the label describes: the lowest chord tone (the bass) when a
  /// chord is shown, otherwise the written note.
  int get labelStep => chordSteps.isEmpty ? step.round() : chordSteps.first;

  /// Name shown by the label next to the note (or the chord bass).
  String get labelNoteName => key.applyTo(clef.noteAt(labelStep)).pitchName;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = (geometry.space * 0.11).clamp(1.0, 4.0)
      ..strokeCap = StrokeCap.round;

    _paintStaff(canvas, linePaint);
    _paintClef(canvas);
    _paintKeySignature(canvas);
    _paintLedgerLines(canvas, linePaint);
    _paintTarget(canvas);
    if (chordSteps.isEmpty) {
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

  void _paintLedgerLines(Canvas canvas, Paint paint) {
    final notes = <int>[
      if (chordSteps.isEmpty) step.round() else ...chordSteps,
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
    final notehead = _layoutGlyph(
      NotationGlyphs.noteheadWhole,
      geometry.space * 4,
      targetColor ?? noteColor,
    );
    _paintGlyph(
      canvas,
      notehead,
      centerX: noteX,
      baselineY: geometry.yForStep(target.toDouble()),
    );
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

    _paintGlyph(canvas, notehead, centerX: noteX, baselineY: noteY);
  }

  void _paintChord(Canvas canvas) {
    final rootStep = chordSteps.firstWhere(
      (chordStep) => chordStep % 7 == step.round() % 7,
      orElse: () => chordSteps.first,
    );
    final headHalfWidth =
        _layoutGlyph(
          NotationGlyphs.noteheadBlack,
          geometry.space * 4,
          noteColor,
        ).width /
        2;
    final stemUp = chordSteps.first < 4;
    final stemLength = geometry.space * 3.5;
    final stemPaint = Paint()
      ..color = chordColor
      ..strokeWidth = (geometry.space * 0.12).clamp(1.2, 4.0)
      ..strokeCap = StrokeCap.round;

    final lowest = geometry.yForStep(chordSteps.first);
    final highest = geometry.yForStep(chordSteps.last);
    final stemX = noteX + (stemUp ? headHalfWidth : -headHalfWidth);
    canvas.drawLine(
      Offset(stemX, stemUp ? lowest : highest),
      Offset(stemX, stemUp ? highest - stemLength : lowest + stemLength),
      stemPaint,
    );

    for (final chordStep in chordSteps) {
      final notehead = _layoutGlyph(
        NotationGlyphs.noteheadBlack,
        geometry.space * 4,
        chordStep == rootStep ? noteColor : chordColor,
      );
      _paintGlyph(
        canvas,
        notehead,
        centerX: noteX,
        baselineY: geometry.yForStep(chordStep),
      );
    }
  }

  void _paintLabel(Canvas canvas) {
    final note = key.applyTo(clef.noteAt(labelStep));
    final painter = TextPainter(
      text: TextSpan(
        text: note.pitchName,
        style: TextStyle(
          color: labelColor,
          fontSize: geometry.space * 1.05,
          fontWeight: FontWeight.w700,
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

    final pad = geometry.space * 0.25;
    final background = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        x - pad,
        y - pad,
        painter.width + pad * 2,
        painter.height + pad * 2,
      ),
      Radius.circular(geometry.space * 0.3),
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
        !listEquals(old.chordSteps, chordSteps) ||
        old.chordColor != chordColor ||
        old.targetStep != targetStep ||
        old.targetColor != targetColor;
  }
}
