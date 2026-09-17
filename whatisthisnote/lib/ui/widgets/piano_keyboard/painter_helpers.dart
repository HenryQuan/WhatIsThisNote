part of '../piano_keyboard.dart';

extension _PianoKeyboardPainterLabels on _PianoKeyboardPainter {
  void _paintSuggestionOutline(
    Canvas canvas,
    Rect rect,
    Radius radius,
    double inset,
  ) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect.deflate(inset), radius),
      Paint()
        ..color = suggestedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  /// Writes a chord tone's name near the bottom of its key. The font shrinks
  /// with the key so a full name still fits on a narrow key.
  void _paintKeyLabel(
    Canvas canvas,
    Rect rect,
    String text,
    Color color,
    double keyWidth,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: (keyWidth * 0.32).clamp(8.0, 13.0),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.bottom - painter.height - 3,
      ),
    );
  }

  void _paintLabel(Canvas canvas, Rect rect, Color color, double maxFontSize) {
    final painter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontSize: maxFontSize.clamp(9.0, 16.0),
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        rect.center.dx - painter.width / 2,
        rect.center.dy - painter.height / 2,
      ),
    );
  }
}
