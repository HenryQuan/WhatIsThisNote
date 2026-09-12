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
    _paintNote(canvas);
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
    final painter = _layoutGlyph(
      clef.glyph,
      geometry.space * 4,
      lineColor,
    );
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
      _paintGlyph(
        canvas,
        glyph,
        x: x,
        baselineY: geometry.yForStep(item.step),
      );
      x += spacing;
    }
  }

  void _paintLedgerLines(Canvas canvas, Paint paint) {
    final steps = geometry.ledgerStepsFor(step.round());
    final halfWidth = geometry.space * 0.95;
    for (final ledgerStep in steps) {
      final y = geometry.yForStep(ledgerStep);
      canvas.drawLine(
        Offset(noteX - halfWidth, y),
        Offset(noteX + halfWidth, y),
        paint,
      );
    }
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

  void _paintLabel(Canvas canvas) {
    final note = key.applyTo(clef.noteAt(step.round()));
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
    final y = geometry.yForStep(step) - painter.height / 2;

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
    final baselineOffset =
        painter.computeDistanceToActualBaseline(TextBaseline.alphabetic);
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
        old.showLabel != showLabel;
  }
}
