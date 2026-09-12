import 'package:flutter/material.dart';

/// A small one-octave piano keyboard (C to the next C) used to show where the
/// current note sits on a real keyboard. The key matching [midi] is
/// highlighted and optionally labelled with [label].
class PianoKeyboard extends StatelessWidget {
  const PianoKeyboard({
    super.key,
    required this.midi,
    this.label,
    this.height = 54,
  });

  /// MIDI number of the note to highlight (C4 == 60).
  final int midi;

  /// Short text drawn on the highlighted key, e.g. `G` or `F♯`.
  final String? label;

  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _PianoKeyboardPainter(
          midi: midi,
          label: label,
          whiteColor: scheme.surfaceContainerLowest,
          blackColor: scheme.onSurface,
          borderColor: scheme.outlineVariant,
          highlightColor: scheme.primary,
          onHighlightColor: scheme.onPrimary,
        ),
      ),
    );
  }
}

class _PianoKeyboardPainter extends CustomPainter {
  _PianoKeyboardPainter({
    required this.midi,
    required this.label,
    required this.whiteColor,
    required this.blackColor,
    required this.borderColor,
    required this.highlightColor,
    required this.onHighlightColor,
  });

  final int midi;
  final String? label;
  final Color whiteColor;
  final Color blackColor;
  final Color borderColor;
  final Color highlightColor;
  final Color onHighlightColor;

  /// Pitch classes of the black keys.
  static const Set<int> _blackPitchClasses = {1, 3, 6, 8, 10};

  /// White key a black key sits after, keyed by the black key's pitch class.
  static const Map<int, int> _blackAfterWhite = {1: 0, 3: 1, 6: 3, 8: 4, 10: 5};

  /// White key for a white pitch class.
  static const Map<int, int> _whiteIndex = {0: 0, 2: 1, 4: 2, 5: 3, 7: 4, 9: 5, 11: 6};

  @override
  void paint(Canvas canvas, Size size) {
    const whiteCount = 8; // C D E F G A B C
    final whiteWidth = size.width / whiteCount;
    final blackWidth = whiteWidth * 0.62;
    final blackHeight = size.height * 0.62;

    final pitchClass = midi % 12;
    final isBlack = _blackPitchClasses.contains(pitchClass);
    final whiteIndexOfHighlight =
        isBlack ? _blackAfterWhite[pitchClass] : _whiteIndex[pitchClass];

    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < whiteCount; i++) {
      final rect = Rect.fromLTWH(i * whiteWidth, 0, whiteWidth, size.height)
          .deflate(0.5);
      final highlighted = !isBlack && i == whiteIndexOfHighlight;
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(
        rrect,
        Paint()..color = highlighted ? highlightColor : whiteColor,
      );
      canvas.drawRRect(rrect, border);
      if (highlighted && label != null) {
        _paintLabel(canvas, rect, onHighlightColor, whiteWidth * 0.5);
      }
    }

    for (final entry in _blackAfterWhite.entries) {
      final cx = (entry.value + 1) * whiteWidth;
      final rect = Rect.fromCenter(
        center: Offset(cx, blackHeight / 2),
        width: blackWidth,
        height: blackHeight,
      );
      final highlighted = isBlack && entry.value == whiteIndexOfHighlight;
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      canvas.drawRRect(
        rrect,
        Paint()..color = highlighted ? highlightColor : blackColor,
      );
      if (highlighted && label != null) {
        _paintLabel(canvas, rect, onHighlightColor, blackWidth * 0.7);
      }
    }
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

  @override
  bool shouldRepaint(covariant _PianoKeyboardPainter old) {
    return old.midi != midi ||
        old.label != label ||
        old.whiteColor != whiteColor ||
        old.blackColor != blackColor ||
        old.borderColor != borderColor ||
        old.highlightColor != highlightColor ||
        old.onHighlightColor != onHighlightColor;
  }
}
