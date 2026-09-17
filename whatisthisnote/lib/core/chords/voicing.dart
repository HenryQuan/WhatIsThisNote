part of '../chord.dart';

extension ChordVoicing on Chord {
  /// Staff steps of the chord voiced from [rootStep], low to high, for the
  /// current inversion. The lowest note is lifted an octave above the top of
  /// the stack so extended chords stay in ascending order.
  List<int> staffSteps(int rootStep) {
    final count = scaleSteps.length;
    final lift = ((scaleSteps.last ~/ 7) + 1) * 7;
    final base = [for (var i = 0; i < count; i++) rootStep + scaleSteps[i]];
    final rotation = inversion % count;
    return [
      for (var i = 0; i < count; i++)
        i < count - rotation
            ? base[i + rotation]
            : base[i + rotation - count] + lift,
    ];
  }

  /// The chord tones voiced from [rootStep], with their exact written notes.
  ///
  /// The staff position and the sounding pitch are kept together here. This
  /// prevents callers from accidentally rebuilding an altered chord from the
  /// key signature and losing its explicit sharps or flats.
  List<ChordToneAtStaff> voicing(Note root, int rootStep) {
    final count = scaleSteps.length;
    final rotation = inversion % count;
    final voicedSteps = staffSteps(rootStep);
    final tones = <ChordToneAtStaff>[];

    for (var voicedIndex = 0; voicedIndex < count; voicedIndex++) {
      final sourceIndex = (voicedIndex + rotation) % count;
      final octave = voicedIndex < count - rotation ? 0 : 1;
      final scaleStep = scaleSteps[sourceIndex] + octave * 7;
      final staffStep = voicedSteps[voicedIndex];
      final natural = Note(root.diatonicIndex + scaleStep);
      final midi = root.midi + intervals[sourceIndex] + octave * 12;
      final accidentalOffset = midi - natural.midi;
      final accidental = switch (accidentalOffset) {
        -2 => Accidental.doubleFlat,
        -1 => Accidental.flat,
        0 => Accidental.natural,
        1 => Accidental.sharp,
        2 => Accidental.doubleSharp,
        _ => throw StateError(
          'Chord tone needs an unsupported accidental: '
          '${root.pitchName} ${quality.suffix}',
        ),
      };
      tones.add(
        ChordToneAtStaff(
          staffStep: staffStep,
          note: natural.withAccidental(accidental),
          isRoot: sourceIndex == 0,
        ),
      );
    }
    return tones;
  }
}
