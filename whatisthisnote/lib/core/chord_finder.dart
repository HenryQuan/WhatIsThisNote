import 'chord.dart';

/// A chord shape that matches a set of pitch classes.
///
/// [missing] and [extra] list the pitch classes the textbook voicing would add
/// or omit, so the same type names both exact matches (both empty) and the
/// closest shape when the notes spell no common chord.
class ChordMatch {
  const ChordMatch({
    required this.rootPitchClass,
    required this.quality,
    this.missing = const [],
    this.extra = const [],
  });

  /// Pitch class of the chord root, 0 == C.
  final int rootPitchClass;

  final ChordQuality quality;

  /// Pitch classes this chord uses that the input does not.
  final List<int> missing;

  /// Pitch classes the input has that this chord does not use.
  final List<int> extra;

  bool get isExact => missing.isEmpty && extra.isEmpty;

  /// How far the input is from an exact voicing; 0 is exact.
  int get distance => missing.length + extra.length;

  /// The chord's pitch classes, low to high from the root.
  Set<int> get pitchClasses => {
    for (final interval in quality.intervals) (rootPitchClass + interval) % 12,
  };

  @override
  String toString() =>
      'ChordMatch(root: $rootPitchClass, ${quality.suffix}, '
      'missing: $missing, extra: $extra)';
}

/// Names every chord (across all twelve roots and the known qualities) that the
/// [pitchClasses] could spell.
///
/// Exact matches are returned first; when none is exact the closest shapes are
/// returned instead, annotated with the notes they add or omit. Results whose
/// root is [preferredRoot] (the learner's selected note) sort first, then by
/// distance, then by the simplest shape.
List<ChordMatch> findChordMatches(
  Iterable<int> pitchClasses, {
  int? preferredRoot,
  int maxResults = 12,
}) {
  final input = {for (final pitchClass in pitchClasses) pitchClass % 12};
  if (input.length < 2) return const [];

  final matches = <ChordMatch>[];
  for (var root = 0; root < 12; root++) {
    for (final quality in kChordQualities) {
      final chordSet = {
        for (final interval in quality.intervals) (root + interval) % 12,
      };
      final missing = chordSet.difference(input).toList()..sort();
      final extra = input.difference(chordSet).toList()..sort();
      // A shape more than two notes away is noise, not a suggestion.
      if (missing.length + extra.length > 2) continue;
      matches.add(
        ChordMatch(
          rootPitchClass: root,
          quality: quality,
          missing: missing,
          extra: extra,
        ),
      );
    }
  }

  matches.sort((a, b) {
    final preferredA = a.rootPitchClass == preferredRoot ? 0 : 1;
    final preferredB = b.rootPitchClass == preferredRoot ? 0 : 1;
    if (preferredA != preferredB) return preferredA - preferredB;
    if (a.distance != b.distance) return a.distance - b.distance;
    if (a.quality.toneCount != b.quality.toneCount) {
      return a.quality.toneCount - b.quality.toneCount;
    }
    return a.rootPitchClass - b.rootPitchClass;
  });

  final exact = matches.where((match) => match.isExact).toList();
  final result = exact.isNotEmpty ? exact : matches;
  return result.take(maxResults).toList();
}
