part of '../notation_painter.dart';

extension _NotationStaffDrawing on NotationPainter {
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
}
