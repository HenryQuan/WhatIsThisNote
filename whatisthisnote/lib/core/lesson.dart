import '../l10n/app_localizations.dart';
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

/// The guided theory path, in order, with all text localized.
List<Lesson> buildLessons(AppLocalizations l10n) => [
  Lesson(l10n.lessonFiveLinesTitle, [
    LessonStep(
      title: l10n.lessonMeetStaffTitle,
      instruction: l10n.lessonMeetStaffBody,
      clef: Clef.treble,
      key: _cMajor,
      step: 4,
    ),
    LessonStep(
      title: l10n.lessonLinesTitle,
      instruction: l10n.lessonLinesBody,
      clef: Clef.treble,
      key: _cMajor,
      step: 2,
    ),
    LessonStep(
      title: l10n.lessonBottomLineTitle,
      instruction: l10n.lessonBottomLineBody,
      clef: Clef.treble,
      key: _cMajor,
      step: 0,
    ),
    LessonStep(
      title: l10n.lessonYourTurnTitle,
      instruction: l10n.lessonLinesPracticeBody,
      clef: Clef.treble,
      key: _cMajor,
      step: 6,
      kind: LessonStepKind.practice,
      targetStep: 4,
    ),
  ]),
  Lesson(l10n.lessonSpacesTitle, [
    LessonStep(
      title: l10n.lessonSpacesSpellTitle,
      instruction: l10n.lessonSpacesSpellBody,
      clef: Clef.treble,
      key: _cMajor,
      step: 1,
    ),
    LessonStep(
      title: l10n.lessonUpSpacesTitle,
      instruction: l10n.lessonUpSpacesBody,
      clef: Clef.treble,
      key: _cMajor,
      step: 3,
    ),
    LessonStep(
      title: l10n.lessonYourTurnTitle,
      instruction: l10n.lessonSpacesPracticeBody,
      clef: Clef.treble,
      key: _cMajor,
      step: 1,
      kind: LessonStepKind.practice,
      targetStep: 7,
    ),
  ]),
  Lesson(l10n.lessonBassClefTitle, [
    LessonStep(
      title: l10n.lessonLowerClefTitle,
      instruction: l10n.lessonLowerClefBody,
      clef: Clef.bass,
      key: _cMajor,
      step: 4,
    ),
    LessonStep(
      title: l10n.lessonBottomLineTitle,
      instruction: l10n.lessonBassBottomLineBody,
      clef: Clef.bass,
      key: _cMajor,
      step: 0,
    ),
    LessonStep(
      title: l10n.lessonYourTurnTitle,
      instruction: l10n.lessonBassPracticeBody,
      clef: Clef.bass,
      key: _cMajor,
      step: 0,
      kind: LessonStepKind.practice,
      targetStep: 4,
    ),
  ]),
  Lesson(l10n.lessonSharpsFlatsTitle, [
    LessonStep(
      title: l10n.lessonSharpsTitle,
      instruction: l10n.lessonSharpsBody,
      clef: Clef.treble,
      key: _gMajor,
      step: 8,
    ),
    LessonStep(
      title: l10n.lessonFlatsTitle,
      instruction: l10n.lessonFlatsBody,
      clef: Clef.treble,
      key: _fMajor,
      step: 4,
    ),
    LessonStep(
      title: l10n.lessonYourTurnTitle,
      instruction: l10n.lessonSharpsPracticeBody,
      clef: Clef.treble,
      key: _gMajor,
      step: 1,
      kind: LessonStepKind.practice,
      targetStep: 8,
    ),
  ]),
  Lesson(l10n.lessonAccidentalsTitle, [
    LessonStep(
      title: l10n.lessonSharpTitle,
      instruction: l10n.lessonSharpBody,
      clef: Clef.treble,
      key: _cMajor,
      step: 8,
      accidental: Accidental.sharp,
    ),
    LessonStep(
      title: l10n.lessonFlatTitle,
      instruction: l10n.lessonFlatBody,
      clef: Clef.treble,
      key: _cMajor,
      step: 4,
      accidental: Accidental.flat,
    ),
    LessonStep(
      title: l10n.lessonNaturalTitle,
      instruction: l10n.lessonNaturalBody,
      clef: Clef.treble,
      key: _gMajor,
      step: 8,
      accidental: Accidental.natural,
    ),
    LessonStep(
      title: l10n.lessonYourTurnTitle,
      instruction: l10n.lessonAccidentalsPracticeBody,
      clef: Clef.treble,
      key: _cMajor,
      step: 4,
      kind: LessonStepKind.practice,
      targetStep: 8,
      targetAccidental: Accidental.sharp,
    ),
  ]),
];
