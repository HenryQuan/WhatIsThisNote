import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// A small one-octave piano keyboard (C to the next C) used to show where the
/// current note sits on a real keyboard. The key matching [midi] is
/// highlighted, and optionally any key whose pitch class is in
/// [highlightPitchClasses] is tinted (used for scale highlighting).
class PianoKeyboard extends StatelessWidget {
  const PianoKeyboard({
    super.key,
    required this.midi,
    this.label,
    this.highlightPitchClasses,
    this.height = 54,
  });

  /// MIDI number of the note to highlight (C4 == 60).
  final int midi;

  /// Short text drawn on the highlighted key, e.g. `G` or `F♯`.
  final String? label;

  /// Pitch classes (0 == C) to tint, e.g. the notes of the selected scale.
  final Set<int>? highlightPitchClasses;

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
          highlightPitchClasses: highlightPitchClasses,
          whiteColor: scheme.surfaceContainerLowest,
          blackColor: scheme.onSurface,
          borderColor: scheme.outlineVariant,
          highlightColor: scheme.primary,
          scaleColor: scheme.primaryContainer,
          onHighlightColor: scheme.onPrimary,
          highlightBlackColor: Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.78),
            scheme.onSurface,
          ),
          scaleBlackColor: Color.alphaBlend(
            scheme.primaryContainer.withValues(alpha: 0.78),
            scheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _PianoKeyboardPainter extends CustomPainter {
  _PianoKeyboardPainter({
    required this.midi,
    required this.label,
    required this.highlightPitchClasses,
    required this.whiteColor,
    required this.blackColor,
    required this.borderColor,
    required this.highlightColor,
    required this.scaleColor,
    required this.onHighlightColor,
    required this.highlightBlackColor,
    required this.scaleBlackColor,
  });

  final int midi;
  final String? label;
  final Set<int>? highlightPitchClasses;
  final Color whiteColor;
  final Color blackColor;
  final Color borderColor;
  final Color highlightColor;
  final Color scaleColor;
  final Color onHighlightColor;

  /// Slightly different shades used for the note highlight and the scale tint
  /// on the shorter black keys (the sharps/flats between two white keys) so
  /// they stay distinct from the larger white keys.
  final Color highlightBlackColor;
  final Color scaleBlackColor;

  /// Pitch classes of the black keys.
  static const Set<int> _blackPitchClasses = {1, 3, 6, 8, 10};

  /// White key a black key sits after, keyed by the black key's pitch class.
  static const Map<int, int> _blackAfterWhite = {1: 0, 3: 1, 6: 3, 8: 4, 10: 5};

  /// White key for a white pitch class.
  static const Map<int, int> _whiteIndex = {0: 0, 2: 1, 4: 2, 5: 3, 7: 4, 9: 5, 11: 6};

  /// Pitch class of each of the eight white keys (C to the next C).
  static const List<int> _whitePitchClasses = [0, 2, 4, 5, 7, 9, 11, 0];

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
      final tinted =
          highlightPitchClasses?.contains(_whitePitchClasses[i]) ?? false;
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = highlighted
              ? highlightColor
              : tinted
                  ? scaleColor
                  : whiteColor,
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
      final highlighted = isBlack && entry.key == pitchClass;
      final tinted = highlightPitchClasses?.contains(entry.key) ?? false;
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = highlighted
              ? highlightBlackColor
              : tinted
                  ? scaleBlackColor
                  : blackColor,
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
        !setEquals(old.highlightPitchClasses, highlightPitchClasses) ||
        old.whiteColor != whiteColor ||
        old.blackColor != blackColor ||
        old.borderColor != borderColor ||
        old.highlightColor != highlightColor ||
        old.scaleColor != scaleColor ||
        old.highlightBlackColor != highlightBlackColor ||
        old.scaleBlackColor != scaleBlackColor ||
        old.onHighlightColor != onHighlightColor;
  }
}
