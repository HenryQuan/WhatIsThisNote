import 'package:flutter_test/flutter_test.dart';
import 'package:whatisthisnote/core/chord.dart';
import 'package:whatisthisnote/core/chord_finder.dart';

void main() {
  group('findChordMatches', () {
    test('names the major triad on the selected root', () {
      final matches = findChordMatches([0, 4, 7], preferredRoot: 0);
      expect(matches, isNotEmpty);
      expect(matches.first.isExact, isTrue);
      expect(matches.first.rootPitchClass, 0);
      expect(matches.first.quality, ChordQuality.major);
    });

    test('names a seventh chord', () {
      final matches = findChordMatches([0, 4, 7, 11], preferredRoot: 0);
      expect(matches.first.isExact, isTrue);
      expect(matches.first.rootPitchClass, 0);
      expect(matches.first.quality.suffix, 'maj7');
    });

    test('returns only exact matches when the notes spell a chord', () {
      final matches = findChordMatches([2, 4, 7, 11], preferredRoot: 4);
      expect(matches, isNotEmpty);
      expect(matches.every((match) => match.isExact), isTrue);
      // Em7 and G6 are the same four notes; the selected root comes first.
      expect(matches.first.rootPitchClass, 4);
    });

    test('suggests the closest shapes when no chord is exact', () {
      final matches = findChordMatches([0, 4], preferredRoot: 0);
      expect(matches, isNotEmpty);
      expect(matches.first.isExact, isFalse);
      expect(matches.first.rootPitchClass, 0);
      expect(matches.first.quality, ChordQuality.major);
      expect(matches.first.missing, [7]);
      expect(matches.first.extra, isEmpty);
    });

    test('prefers the selected root among close matches', () {
      final defaultOrder = findChordMatches([0, 4]);
      final preferred = findChordMatches([0, 4], preferredRoot: 9);
      expect(defaultOrder.first.rootPitchClass, 0);
      expect(preferred.first.rootPitchClass, 9);
      expect(preferred.first.quality, ChordQuality.minor);
    });

    test('ignores a single note and clamps the result count', () {
      expect(findChordMatches([0]), isEmpty);
      expect(findChordMatches([0, 1, 2, 3, 4, 5]), hasLength(lessThanOrEqualTo(12)));
    });
  });
}
