import 'dart:math' as math;

/// Tempo limits of the metronome, in beats per minute.
const int kMinBpm = 40;
const int kMaxBpm = 208;

/// The lowest register the finder sweeps from, and the highest it reaches.
const int kMinZone = 1;
const int kMaxZone = 8;

/// How long one beat lasts at [bpm], clamped to the supported range.
Duration beatInterval(int bpm) =>
    Duration(microseconds: 60000000 ~/ bpm.clamp(kMinBpm, kMaxBpm));

/// The twelve pitch classes, always labelled with sharps. The finder spells a
/// note with the key signature where it can, but a chromatic fallback keeps a
/// plain name available for every pitch.
const List<String> kSharpPitchClassNames = [
  'C',
  'C\u266F',
  'D',
  'D\u266F',
  'E',
  'F',
  'F\u266F',
  'G',
  'G\u266F',
  'A',
  'A\u266F',
  'B',
];

/// Scientific name of a pitch class, e.g. `C`, `F\u266F`.
String pitchClassName(int pitchClass) =>
    kSharpPitchClassNames[pitchClass % 12];

/// MIDI note number for [pitchClass] (0 == C) in [octave] (middle C is C4).
int midiForPitchClass(int pitchClass, int octave) =>
    (octave + 1) * 12 + (pitchClass % 12);

/// Frequency in hertz of a MIDI note number, with A4 (69) == 440 Hz.
double frequencyForMidi(int midi) =>
    440.0 * math.pow(2, (midi - 69) / 12).toDouble();

/// Frequency in hertz of [pitchClass] in [octave], with A4 == 440 Hz.
double frequencyForPitchClass(int pitchClass, int octave) =>
    frequencyForMidi(midiForPitchClass(pitchClass, octave));
