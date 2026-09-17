part of '../chord.dart';

class ChordToneAtStaff {
  const ChordToneAtStaff({
    required this.staffStep,
    required this.note,
    required this.isRoot,
  });

  final int staffStep;
  final Note note;
  final bool isRoot;

  @override
  bool operator ==(Object other) =>
      other is ChordToneAtStaff &&
      other.staffStep == staffStep &&
      other.note == note &&
      other.isRoot == isRoot;

  @override
  int get hashCode => Object.hash(staffStep, note, isRoot);
}

/// The stable category used to localize a progression name.
enum ProgressionGenre {
  pop,
  dooWop,
  axis,
  folk,
  rock,
  anthem,
  singer,
  ballad,
  emo,
  cadence,
  jazz,
  turnaround,
  circle,
  minorPop,
  minorRock,
  minor,
  andalusian,
  canon,
}

/// A named sequence of scale degrees, e.g. the pop progression I V vi IV.
class ChordProgression {
  const ChordProgression(this.name, this.degrees, this.genre);

  final String name;

  /// Scale degrees (1..7) played in order.
  final List<int> degrees;

  /// Stable identifier used by localization instead of parsing [name].
  final ProgressionGenre genre;

  /// The roman-numeral part of the stable English label.
  String get romanNumerals {
    final separator = name.indexOf(' \u2013 ');
    return separator < 0 ? name : name.substring(separator + 3);
  }
}

/// Progressions that sound good in the common major and minor moods.
///
/// Each entry lists scale degrees (1..7) of whatever seven-note scale is
/// selected, so the same list reads as I V vi IV in a major key and i v VI iv
/// in a minor one. Names with an explicit minor numeral mark progressions
/// that only make musical sense in a minor mood.
const List<ChordProgression> kProgressions = [
  // Major moods.
  ChordProgression('Pop \u2013 I V vi IV', [1, 5, 6, 4], ProgressionGenre.pop),
  ChordProgression('Doo-wop \u2013 I vi IV V', [
    1,
    6,
    4,
    5,
  ], ProgressionGenre.dooWop),
  ChordProgression('Axis \u2013 vi IV I V', [
    6,
    4,
    1,
    5,
  ], ProgressionGenre.axis),
  ChordProgression('Folk \u2013 I IV V', [1, 4, 5], ProgressionGenre.folk),
  ChordProgression('Rock \u2013 I IV V IV', [
    1,
    4,
    5,
    4,
  ], ProgressionGenre.rock),
  ChordProgression('Anthem \u2013 I V IV I', [
    1,
    5,
    4,
    1,
  ], ProgressionGenre.anthem),
  ChordProgression('Singer \u2013 I iii IV V', [
    1,
    3,
    4,
    5,
  ], ProgressionGenre.singer),
  ChordProgression('Pop \u2013 I IV vi V', [1, 4, 6, 5], ProgressionGenre.pop),
  ChordProgression('Ballad \u2013 I vi IV I', [
    1,
    6,
    4,
    1,
  ], ProgressionGenre.ballad),
  ChordProgression('Emo \u2013 I V vi iii', [1, 5, 6, 3], ProgressionGenre.emo),
  ChordProgression('Cadence \u2013 IV V I', [
    4,
    5,
    1,
  ], ProgressionGenre.cadence),
  // Jazz and turnarounds.
  ChordProgression('Jazz \u2013 ii V I', [2, 5, 1], ProgressionGenre.jazz),
  ChordProgression('Turnaround \u2013 I vi ii V', [
    1,
    6,
    2,
    5,
  ], ProgressionGenre.turnaround),
  ChordProgression('Circle \u2013 vi ii V I', [
    6,
    2,
    5,
    1,
  ], ProgressionGenre.circle),
  ChordProgression('Jazz \u2013 iii vi ii V', [
    3,
    6,
    2,
    5,
  ], ProgressionGenre.jazz),
  ChordProgression('Jazz \u2013 ii V I vi', [
    2,
    5,
    1,
    6,
  ], ProgressionGenre.jazz),
  // Minor moods (the flat numerals are how they read in a minor scale).
  ChordProgression('Minor pop \u2013 i \u266DVI \u266DIII \u266DVII', [
    1,
    6,
    3,
    7,
  ], ProgressionGenre.minorPop),
  ChordProgression(
    'Minor rock \u2013 i \u266DVII \u266DVI \u266DVII',
    [1, 7, 6, 7],
    ProgressionGenre.minorRock,
  ),
  ChordProgression('Minor \u2013 i iv v i', [
    1,
    4,
    5,
    1,
  ], ProgressionGenre.minor),
  ChordProgression('Minor \u2013 i \u266DVI iv v', [
    1,
    6,
    4,
    5,
  ], ProgressionGenre.minor),
  ChordProgression('Minor \u2013 i iv \u266DVII \u266DIII', [
    1,
    4,
    7,
    3,
  ], ProgressionGenre.minor),
  ChordProgression('Andalusian \u2013 i \u266DVII \u266DVI V', [
    1,
    7,
    6,
    5,
  ], ProgressionGenre.andalusian),
  ChordProgression('Canon \u2013 I V vi iii IV I IV V', [
    1,
    5,
    6,
    3,
    4,
    1,
    4,
    5,
  ], ProgressionGenre.canon),
];
