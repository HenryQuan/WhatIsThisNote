import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

part 'piano_keyboard/painter.dart';
part 'piano_keyboard/painter_helpers.dart';

/// A small one-octave piano keyboard (C to the next C) used to show where the
/// current note sits on a real keyboard. The key matching [midi] is
/// highlighted, any key whose pitch class is in [highlightPitchClasses] is
/// tinted (used for scale highlighting) and any key in [chordPitchClasses] is
/// tinted (used for chord tones). While a scale is played automatically,
/// [playingPitchClass] marks the note that is currently sounding.
class PianoKeyboard extends StatelessWidget {
  const PianoKeyboard({
    super.key,
    required this.midi,
    this.label,
    this.highlightPitchClasses,
    this.chordPitchClasses,
    this.chordMidis,
    this.suggestedPitchClasses,
    this.chordLabels,
    this.midiUpperOctave = false,
    this.playingPitchClass,
    this.playingUpperOctave = false,
    this.height = 54,
    this.showHighlight = true,
    this.onPitchClassTap,
  });

  /// MIDI number of the note to highlight (C4 == 60).
  final int midi;

  /// Short text drawn on the highlighted key, e.g. `G` or `F♯`.
  final String? label;

  /// Pitch classes (0 == C) to tint, e.g. the notes of the selected scale.
  final Set<int>? highlightPitchClasses;

  /// Pitch classes (0 == C) of the current chord, tinted a third colour.
  final Set<int>? chordPitchClasses;

  /// Exact MIDI notes of the current chord, tinted a third colour. Takes
  /// precedence over [chordPitchClasses] so an upper-octave C lights the upper
  /// C key instead of the lower one. The keyboard spans C4-C5 (MIDI 60-72).
  final Set<int>? chordMidis;

  /// Pitch classes (0 == C) of a chord's ideal tones, outlined rather than
  /// filled. Used by the chord builder to show the notes of the closest chord
  /// so the learner can see which keys to add; keys that are already part of
  /// the chord stay solid.
  final Set<int>? suggestedPitchClasses;

  /// Note names (0 == C) to write on the chord keys, e.g. `{0: 'C', 4: 'E',
  /// 7: 'G', 11: 'B'}` for Cmaj7. Only drawn on keys that are part of the
  /// chord or one of the [suggestedPitchClasses].
  final Map<int, String>? chordLabels;

  /// Whether [midi]'s key is the upper of the keyboard's two C keys, used when
  /// the highlighted note is a C in the upper octave.
  final bool midiUpperOctave;

  /// Pitch class (0 == C) of the note that is currently sounding while a
  /// sequence plays, or `null` when nothing is playing.
  final int? playingPitchClass;

  /// Whether the sounding note is the upper of the keyboard's two C keys.
  /// The keyboard spans one octave (C to C), so the closing tonic of a scale
  /// must light the second C rather than the first.
  final bool playingUpperOctave;

  final double height;

  /// Whether [midi]'s key is highlighted. Turned off for read-and-play, where
  /// highlighting the answer would give it away.
  final bool showHighlight;

  /// Called with the pitch class of the key the learner taps, making the
  /// keyboard an input device. `null` leaves it a read-only display.
  final ValueChanged<int>? onPitchClassTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final keyboard = CustomPaint(
      size: Size.infinite,
      painter: _PianoKeyboardPainter(
        midi: midi,
        label: label,
        showHighlight: showHighlight,
        midiUpperOctave: midiUpperOctave,
        highlightPitchClasses: highlightPitchClasses,
        chordPitchClasses: chordPitchClasses,
        chordMidis: chordMidis,
        suggestedPitchClasses: suggestedPitchClasses,
        chordLabels: chordLabels,
        playingPitchClass: playingPitchClass,
        playingUpperOctave: playingUpperOctave,
        whiteColor: scheme.surfaceContainerLowest,
        blackColor: scheme.onSurface,
        borderColor: scheme.outlineVariant,
        highlightColor: scheme.primary,
        scaleColor: scheme.primaryContainer,
        chordColor: scheme.tertiary,
        suggestedColor: scheme.tertiary,
        onChordColor: scheme.onTertiary,
        playingColor: scheme.secondary,
        onHighlightColor: scheme.onPrimary,
        highlightBlackColor: Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.78),
          scheme.onSurface,
        ),
        scaleBlackColor: Color.alphaBlend(
          scheme.primaryContainer.withValues(alpha: 0.78),
          scheme.onSurface,
        ),
        chordBlackColor: Color.alphaBlend(
          scheme.tertiary.withValues(alpha: 0.78),
          scheme.onSurface,
        ),
        playingBlackColor: Color.alphaBlend(
          scheme.secondary.withValues(alpha: 0.78),
          scheme.onSurface,
        ),
      ),
    );
    if (onPitchClassTap == null) {
      return SizedBox(height: height, child: keyboard);
    }
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            onPitchClassTap!(
              _PianoKeyboardPainter.pitchClassAt(
                details.localPosition,
                Size(constraints.maxWidth, constraints.maxHeight),
              ),
            );
          },
          child: keyboard,
        ),
      ),
    );
  }
}
