import 'package:flutter_test/flutter_test.dart';
import 'package:whatisthisnote/core/metronome.dart';

void main() {
  group('beatInterval', () {
    test('maps bpm to the time between beats', () {
      expect(beatInterval(60), const Duration(seconds: 1));
      expect(beatInterval(120), const Duration(milliseconds: 500));
    });

    test('clamps to the supported tempo range', () {
      expect(beatInterval(1), beatInterval(kMinBpm));
      expect(beatInterval(1000), beatInterval(kMaxBpm));
    });
  });

  group('register pitches', () {
    test('computes MIDI numbers and frequencies', () {
      expect(midiForPitchClass(0, 4), 60);
      expect(midiForPitchClass(9, 4), 69);
      expect(frequencyForPitchClass(9, 4), closeTo(440, 0.0001));
      expect(frequencyForPitchClass(0, 4), closeTo(261.6256, 0.001));
    });

    test('names every pitch class with sharps', () {
      expect(pitchClassName(0), 'C');
      expect(pitchClassName(1), 'C\u266F');
      expect(pitchClassName(10), 'A\u266F');
      expect(pitchClassName(12), 'C');
    });
  });
}
