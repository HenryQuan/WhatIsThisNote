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

const MusicalKey _cMajor = MusicalKey('C', KeyMode.major, 0);
const MusicalKey _gMajor = MusicalKey('G', KeyMode.major, 1);
const MusicalKey _fMajor = MusicalKey('F', KeyMode.major, -1);

/// The guided theory path, in order.
const List<Lesson> kLessons = [
  Lesson('The five lines', [
    LessonStep(
      title: 'Meet the staff',
      instruction:
          'Music is written on a staff of five lines. Higher on the staff '
          'means a higher pitch. In the treble clef this middle line is B.',
      clef: Clef.treble,
      key: _cMajor,
      step: 4,
    ),
    LessonStep(
      title: 'Lines spell E G B D F',
      instruction:
          'Notes on the lines are a third apart. One line down from B is G.',
      clef: Clef.treble,
      key: _cMajor,
      step: 2,
    ),
    LessonStep(
      title: 'The bottom line',
      instruction:
          'The bottom line is E. Read the lines from the bottom up: '
          'E, G, B, D, F.',
      clef: Clef.treble,
      key: _cMajor,
      step: 0,
    ),
    LessonStep(
      title: 'Your turn',
      instruction: 'Drag the note down to the middle line (B).',
      clef: Clef.treble,
      key: _cMajor,
      step: 6,
      kind: LessonStepKind.practice,
      targetStep: 4,
    ),
  ]),
  Lesson('The spaces', [
    LessonStep(
      title: 'Spaces spell F A C E',
      instruction:
          'Notes in the spaces sit between the lines. The first space from '
          'the bottom is F.',
      clef: Clef.treble,
      key: _cMajor,
      step: 1,
    ),
    LessonStep(
      title: 'Up the spaces',
      instruction: 'The spaces from the bottom up are F, A, C, E.',
      clef: Clef.treble,
      key: _cMajor,
      step: 3,
    ),
    LessonStep(
      title: 'Your turn',
      instruction: 'Drag the note to the top space (E).',
      clef: Clef.treble,
      key: _cMajor,
      step: 1,
      kind: LessonStepKind.practice,
      targetStep: 7,
    ),
  ]),
  Lesson('The bass clef', [
    LessonStep(
      title: 'A lower clef',
      instruction:
          'The bass clef is used for low instruments. Its middle line is D.',
      clef: Clef.bass,
      key: _cMajor,
      step: 4,
    ),
    LessonStep(
      title: 'The bottom line',
      instruction:
          'The bottom line of the bass staff is G, and the lines spell '
          'G, B, D, F, A.',
      clef: Clef.bass,
      key: _cMajor,
      step: 0,
    ),
    LessonStep(
      title: 'Your turn',
      instruction: 'Drag the note up to the middle line (D).',
      clef: Clef.bass,
      key: _cMajor,
      step: 0,
      kind: LessonStepKind.practice,
      targetStep: 4,
    ),
  ]),
  Lesson('Sharps and flats', [
    LessonStep(
      title: 'Sharps',
      instruction:
          'A sharp raises a note by a half step. In G major every F becomes '
          'F sharp, written in the key signature.',
      clef: Clef.treble,
      key: _gMajor,
      step: 8,
    ),
    LessonStep(
      title: 'Flats',
      instruction:
          'A flat lowers a note by a half step. In F major every B becomes '
          'B flat.',
      clef: Clef.treble,
      key: _fMajor,
      step: 4,
    ),
    LessonStep(
      title: 'Your turn',
      instruction:
          'In G major the F is sharp. Drag the note to the top line (F).',
      clef: Clef.treble,
      key: _gMajor,
      step: 1,
      kind: LessonStepKind.practice,
      targetStep: 8,
    ),
  ]),
  Lesson('Accidentals', [
    LessonStep(
      title: 'Sharp',
      instruction:
          'A sharp (\u266F) raises a note by a half step. This F cannot be '
          'written in C major without a sign, so a sharp is printed in front '
          'of it, making it F\u266F.',
      clef: Clef.treble,
      key: _cMajor,
      step: 8,
      accidental: Accidental.sharp,
    ),
    LessonStep(
      title: 'Flat',
      instruction:
          'A flat (\u266D) lowers a note by a half step. This B becomes '
          'B\u266D, with a flat sign in front of it.',
      clef: Clef.treble,
      key: _cMajor,
      step: 4,
      accidental: Accidental.flat,
    ),
    LessonStep(
      title: 'Natural',
      instruction:
          'A natural (\u266E) cancels an earlier sharp or flat. In G major '
          'the key signature makes every F sharp, so an F natural needs a '
          'natural sign.',
      clef: Clef.treble,
      key: _gMajor,
      step: 8,
      accidental: Accidental.natural,
    ),
    LessonStep(
      title: 'Your turn',
      instruction: 'Drag the note up to F and make it F\u266F.',
      clef: Clef.treble,
      key: _cMajor,
      step: 4,
      kind: LessonStepKind.practice,
      targetStep: 8,
      targetAccidental: Accidental.sharp,
    ),
  ]),
];
