import 'package:flutter/material.dart';

/// Lays out one SMuFL glyph using the bundled Bravura font.
TextPainter layoutMusicGlyph(String glyph, double fontSize, Color color) {
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

/// Paints a laid-out glyph so that its origin sits on [baselineY]. When
/// [centerX] is given the glyph is centred on it, otherwise it starts at [x].
void paintMusicGlyph(
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
