import 'chord.dart';
import 'key.dart';
import 'note.dart';
import 'scale.dart';

/// Pure chord calculations used by the home page.
///
/// Keeping these decisions outside the widget makes the UI responsible for
/// state and layout, while the music rules remain easy to test in isolation.
class ChordService {
  const ChordService._();

  /// Uses [selected] when it is a seven-note scale; otherwise uses the mode's
  /// ordinary major or natural-minor scale for chord construction.
  static Scale scaleForChords(MusicalKey key, Scale? selected) {
    if (selected != null && selected.isHeptatonic) return selected;
    return Scale(
      key.tonic,
      key.tonicPitchClass,
      key.mode == KeyMode.major ? ScaleType.major : ScaleType.naturalMinor,
    );
  }

  /// Returns the numbered scale degree of [note] by its written letter.
  static int degreeOf(Note note, Scale scale) {
    var relative = (note.letter.index - scale.tonicLetter.index) % 7;
    if (relative < 0) relative += 7;
    return relative + 1;
  }

  /// Builds the chord shown for [note] in the current chord-lab settings.
  static Chord? chordFor({
    required ChordMode mode,
    required ChordQuality? quality,
    required Scale scale,
    required Note note,
    required int inversion,
  }) {
    if (mode == ChordMode.off) return null;
    if (quality != null) {
      return Chord.onNote(note, quality, inversion: inversion);
    }
    if (scale.pitchClasses.contains(note.midi % 12)) {
      return Chord.diatonic(
        scale,
        degreeOf(note, scale),
        extension: mode.extension!,
        inversion: inversion,
      );
    }
    return Chord.chromatic(
      scale,
      note,
      extension: mode.extension!,
      inversion: inversion,
    );
  }
}
