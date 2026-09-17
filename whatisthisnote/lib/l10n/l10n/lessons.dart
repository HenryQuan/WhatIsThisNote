part of '../l10n.dart';

const MusicalKey _cMajor = MusicalKey('C', KeyMode.major, 0);
const MusicalKey _gMajor = MusicalKey('G', KeyMode.major, 1);
const MusicalKey _fMajor = MusicalKey('F', KeyMode.major, -1);

/// Builds the guided lesson content at the localization boundary. The core
/// lesson model stays independent of Flutter and generated localization code.
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


