part of '../piano_keyboard.dart';

class _PianoKeyboardPainter extends CustomPainter {
  _PianoKeyboardPainter({
    required this.midi,
    required this.label,
    required this.showHighlight,
    required this.midiUpperOctave,
    required this.highlightPitchClasses,
    required this.chordPitchClasses,
    required this.chordMidis,
    required this.suggestedPitchClasses,
    required this.chordLabels,
    required this.playingPitchClass,
    required this.playingUpperOctave,
    required this.whiteColor,
    required this.blackColor,
    required this.borderColor,
    required this.highlightColor,
    required this.scaleColor,
    required this.chordColor,
    required this.suggestedColor,
    required this.onChordColor,
    required this.playingColor,
    required this.onHighlightColor,
    required this.highlightBlackColor,
    required this.scaleBlackColor,
    required this.chordBlackColor,
    required this.playingBlackColor,
  });

  final int midi;
  final String? label;
  final bool showHighlight;
  final bool midiUpperOctave;
  final Set<int>? highlightPitchClasses;
  final Set<int>? chordPitchClasses;
  final Set<int>? chordMidis;
  final Set<int>? suggestedPitchClasses;
  final Map<int, String>? chordLabels;
  final int? playingPitchClass;
  final bool playingUpperOctave;
  final Color whiteColor;
  final Color blackColor;
  final Color borderColor;
  final Color highlightColor;
  final Color scaleColor;
  final Color chordColor;
  final Color suggestedColor;
  final Color onChordColor;
  final Color playingColor;
  final Color onHighlightColor;

  /// Slightly different shades used for the note highlight and the scale tint
  /// on the shorter black keys (the sharps/flats between two white keys) so
  /// they stay distinct from the larger white keys.
  final Color highlightBlackColor;
  final Color scaleBlackColor;
  final Color chordBlackColor;
  final Color playingBlackColor;

  /// Pitch classes of the black keys.
  static const Set<int> _blackPitchClasses = {1, 3, 6, 8, 10};

  /// White key a black key sits after, keyed by the black key's pitch class.
  static const Map<int, int> _blackAfterWhite = {1: 0, 3: 1, 6: 3, 8: 4, 10: 5};

  /// White key for a white pitch class.
  static const Map<int, int> _whiteIndex = {
    0: 0,
    2: 1,
    4: 2,
    5: 3,
    7: 4,
    9: 5,
    11: 6,
  };

  /// Pitch class of each of the eight white keys (C to the next C).
  static const List<int> _whitePitchClasses = [0, 2, 4, 5, 7, 9, 11, 0];

  /// Semitone offset of each white key from the keyboard's lower C.
  static const List<int> _whiteOffsets = [0, 2, 4, 5, 7, 9, 11, 12];

  /// MIDI number of the keyboard's lower C (C4); it spans C4-C5 (60-72).
  static const int _baseMidi = 60;

  /// Pitch class of the key under [point] in a keyboard of [size], using the
  /// same layout as [paint]. Black keys take precedence where they overlap a
  /// white key.
  static int pitchClassAt(Offset point, Size size) {
    const whiteCount = 8;
    final whiteWidth = size.width / whiteCount;
    final blackWidth = whiteWidth * 0.62;
    final blackHeight = size.height * 0.62;
    if (point.dy <= blackHeight) {
      for (final entry in _blackAfterWhite.entries) {
        final center = (entry.value + 1) * whiteWidth;
        if (point.dx >= center - blackWidth / 2 &&
            point.dx <= center + blackWidth / 2) {
          return entry.key;
        }
      }
    }
    final index = (point.dx / whiteWidth).floor().clamp(0, whiteCount - 1);
    return _whitePitchClasses[index];
  }

  @override
  void paint(Canvas canvas, Size size) {
    const whiteCount = 8; // C D E F G A B C
    final whiteWidth = size.width / whiteCount;
    final blackWidth = whiteWidth * 0.62;
    final blackHeight = size.height * 0.62;

    final pitchClass = midi % 12;
    final isBlack = _blackPitchClasses.contains(pitchClass);
    final whiteIndexOfHighlight = isBlack
        ? _blackAfterWhite[pitchClass]
        : (pitchClass == 0 && midiUpperOctave
              ? whiteCount - 1
              : _whiteIndex[pitchClass]);

    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (var i = 0; i < whiteCount; i++) {
      final rect = Rect.fromLTWH(
        i * whiteWidth,
        0,
        whiteWidth,
        size.height,
      ).deflate(0.5);
      final whitePitchClass = _whitePitchClasses[i];
      // The last white key is the octave C: it shares pitch class 0 with the
      // first key, so a pitch-class tint must not light both of them.
      final isUpperC = i == whiteCount - 1;
      final highlighted =
          showHighlight && !isBlack && i == whiteIndexOfHighlight;
      final tinted =
          !isUpperC &&
          (highlightPitchClasses?.contains(whitePitchClass) ?? false);
      final inChord = chordMidis != null
          ? chordMidis!.contains(_baseMidi + _whiteOffsets[i])
          : !isUpperC &&
                (chordPitchClasses?.contains(whitePitchClass) ?? false);
      final suggested =
          !isUpperC &&
          (suggestedPitchClasses?.contains(whitePitchClass) ?? false);
      final chordLabel = (inChord || suggested)
          ? (chordLabels?[whitePitchClass])
          : null;
      final playing =
          playingPitchClass == whitePitchClass &&
          (whitePitchClass != 0 || (i == 7) == playingUpperOctave);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = playing
              ? playingColor
              : highlighted
              ? highlightColor
              : inChord
              ? chordColor
              : tinted
              ? scaleColor
              : whiteColor,
      );
      canvas.drawRRect(rrect, border);
      if (suggested && !inChord && !playing && !highlighted) {
        _paintSuggestionOutline(canvas, rect, const Radius.circular(4), 3.5);
      }
      if (chordLabel != null && !playing && !(highlighted && label != null)) {
        _paintKeyLabel(
          canvas,
          rect,
          chordLabel,
          inChord ? onChordColor : suggestedColor,
          whiteWidth,
        );
      }
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
      final highlighted = showHighlight && isBlack && entry.key == pitchClass;
      final tinted = highlightPitchClasses?.contains(entry.key) ?? false;
      final inChord = chordMidis != null
          ? chordMidis!.contains(_baseMidi + entry.key)
          : (chordPitchClasses?.contains(entry.key) ?? false);
      final suggested = suggestedPitchClasses?.contains(entry.key) ?? false;
      final chordLabel = (inChord || suggested)
          ? (chordLabels?[entry.key])
          : null;
      final playing = playingPitchClass == entry.key;
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = playing
              ? playingBlackColor
              : highlighted
              ? highlightBlackColor
              : inChord
              ? chordBlackColor
              : tinted
              ? scaleBlackColor
              : blackColor,
      );
      if (suggested && !inChord && !playing && !highlighted) {
        _paintSuggestionOutline(canvas, rect, const Radius.circular(2), 2.5);
      }
      if (chordLabel != null && !playing && !(highlighted && label != null)) {
        _paintKeyLabel(
          canvas,
          rect,
          chordLabel,
          inChord ? onChordColor : suggestedColor,
          whiteWidth,
        );
      }
      if (highlighted && label != null) {
        _paintLabel(canvas, rect, onHighlightColor, blackWidth * 0.7);
      }
    }
  }

  /// Draws the inner outline that marks a suggested chord tone: a key the
  /// closest chord needs but the learner has not stacked yet.
  @override
  bool shouldRepaint(covariant _PianoKeyboardPainter old) {
    return old.midi != midi ||
        old.label != label ||
        old.showHighlight != showHighlight ||
        old.midiUpperOctave != midiUpperOctave ||
        !setEquals(old.highlightPitchClasses, highlightPitchClasses) ||
        !setEquals(old.chordPitchClasses, chordPitchClasses) ||
        !setEquals(old.chordMidis, chordMidis) ||
        !setEquals(old.suggestedPitchClasses, suggestedPitchClasses) ||
        !mapEquals(old.chordLabels, chordLabels) ||
        old.playingPitchClass != playingPitchClass ||
        old.playingUpperOctave != playingUpperOctave ||
        old.whiteColor != whiteColor ||
        old.blackColor != blackColor ||
        old.borderColor != borderColor ||
        old.highlightColor != highlightColor ||
        old.scaleColor != scaleColor ||
        old.chordColor != chordColor ||
        old.suggestedColor != suggestedColor ||
        old.onChordColor != onChordColor ||
        old.playingColor != playingColor ||
        old.highlightBlackColor != highlightBlackColor ||
        old.scaleBlackColor != scaleBlackColor ||
        old.chordBlackColor != chordBlackColor ||
        old.playingBlackColor != playingBlackColor ||
        old.onHighlightColor != onHighlightColor;
  }
}
