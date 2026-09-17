part of '../chord.dart';

/// How many scale tones are stacked above the root of a diatonic chord.
///
/// Steps are counted in scale degrees: a seventh stacks the root, third, fifth
/// and seventh, and a thirteenth keeps stacking thirds up to the thirteenth.
/// The sixth is the exception, replacing the seventh with the sixth degree.
enum ChordExtension {
  triad('Triads', [0, 2, 4]),
  sixth('Sixths', [0, 2, 4, 5]),
  seventh('Sevenths', [0, 2, 4, 6]),
  ninth('Ninths', [0, 2, 4, 6, 8]),
  eleventh('Elevenths', [0, 2, 4, 6, 8, 10]),
  thirteenth('Thirteenths', [0, 2, 4, 6, 8, 10, 12]);

  const ChordExtension(this.label, this.scaleSteps);

  final String label;

  /// Diatonic steps above the root, low to high.
  final List<int> scaleSteps;

  int get toneCount => scaleSteps.length;
}

/// The states of the chord lab add-on, from off to full thirteenth chords.
enum ChordMode {
  off('Off', null),
  triads('Triads', ChordExtension.triad),
  sixths('Sixths', ChordExtension.sixth),
  sevenths('Sevenths', ChordExtension.seventh),
  ninths('Ninths', ChordExtension.ninth),
  elevenths('Elevenths', ChordExtension.eleventh),
  thirteenths('Thirteenths', ChordExtension.thirteenth);

  const ChordMode(this.label, this.extension);

  final String label;

  /// The stack this mode builds, or `null` when the lab is off.
  final ChordExtension? extension;

  bool get isOn => extension != null;
}

/// The quality of a chord: its human readable [label], the symbol [suffix]
/// (e.g. `m` for a minor triad) and the [romanSuffix] after the roman numeral.
///
/// Extended chords keep intervals above an octave: a ninth is 14 semitones, an
/// eleventh 17 and a thirteenth 21.
