import 'dart:math';

import 'staff_geometry.dart';

/// A short, single-voice phrase the learner reads off the staff and then plays
/// back, left to right, on the on-screen keyboard.
class Melody {
  const Melody(this.steps);

  /// Staff steps of the notes. Lower steps are lower pitches; the first entry
  /// is the first note to play.
  final List<int> steps;

  int get length => steps.length;
}

/// Builds random phrases for the read-and-play exercise.
///
/// Notes may sit up to three ledger lines above or below the staff, and a
/// phrase mixes small steps with the occasional leap or free jump, so a new
/// phrase is always a little different. A fresh phrase is generated each time
/// [next] is called.
class MelodyBuilder {
  MelodyBuilder({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Steps a phrase may use, from three ledger lines below the staff to three
  /// above.
  static final List<int> range = [
    for (var step = kMinStaffStep; step <= kMaxStaffStep; step++) step,
  ];

  /// Shortest and longest phrase, in notes.
  static const int minNotes = 4;
  static const int maxNotes = 7;

  /// Smallest and largest interval, in staff steps, between two notes.
  static const int minLeap = 1;
  static const int maxLeap = 4;

  /// One in this many notes jumps anywhere on the staff for variety.
  static const int freeJumpChance = 6;

  /// Generates the next random phrase.
  Melody next() {
    final count = minNotes + _random.nextInt(maxNotes - minNotes + 1);
    final steps = <int>[_pick()];
    while (steps.length < count) {
      if (_random.nextInt(freeJumpChance) == 0) {
        steps.add(_pick());
        continue;
      }
      final magnitude = minLeap + _random.nextInt(maxLeap - minLeap + 1);
      final leap = _random.nextBool() ? magnitude : -magnitude;
      final target = _bounce(steps.last + leap);
      steps.add(target == steps.last ? _bounce(steps.last + 1) : target);
    }
    return Melody(steps);
  }

  int _pick() => range[_random.nextInt(range.length)];

  /// Reflects [step] back inside [range] so a leap off the edge stays a leap
  /// rather than flattening onto the boundary.
  int _bounce(int step) {
    if (step < range.first) return range.first + (range.first - step);
    if (step > range.last) return range.last - (step - range.last);
    return step;
  }
}
