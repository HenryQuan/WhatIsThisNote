import 'accidental.dart';
import 'clef.dart';
import 'key.dart';

/// Whether a [LessonStep] explains something or asks the learner to act.
enum LessonStepKind { explain, practice }

/// A single step in a guided lesson. It fully describes the staff state to
/// show so the path is deterministic.
class LessonStep {
  const LessonStep({
    required this.title,
    required this.instruction,
    required this.clef,
    required this.key,
    required this.step,
    this.kind = LessonStepKind.explain,
    this.targetStep,
    this.accidental,
    this.targetAccidental,
  });

  final String title;
  final String instruction;
  final Clef clef;
  final MusicalKey key;

  /// Staff step the note starts on.
  final int step;

  final LessonStepKind kind;

  /// Staff step the learner must drag the note to (practice steps only).
  final int? targetStep;

  /// Accidental written on the note, overriding the key signature. `null` uses
  /// the key's accidental for the note's letter, so lessons can introduce
  /// sharps, flats and naturals outside the key.
  final Accidental? accidental;

  /// Accidental written on the hollow practice target, overriding the key
  /// signature.
  final Accidental? targetAccidental;

  bool get isPractice => kind == LessonStepKind.practice;
}

/// An ordered group of [LessonStep]s.
class Lesson {
  const Lesson(this.title, this.steps);

  final String title;
  final List<LessonStep> steps;
}
