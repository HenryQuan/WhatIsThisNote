part of '../notation_painter.dart';

extension _NotationLabelDrawing on NotationPainter {
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
}
