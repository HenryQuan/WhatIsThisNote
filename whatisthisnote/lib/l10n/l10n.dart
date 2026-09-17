import 'package:flutter/widgets.dart';

import '../core/accidental.dart';
import '../core/chord.dart';
import '../core/clef.dart';
import '../core/display_preferences.dart';
import '../core/key.dart';
import '../core/lesson.dart';
import '../core/metronome.dart';
import '../core/note.dart';
import '../core/scale.dart';
import 'app_localizations.dart';

/// `context.l10n` shorthand for [AppLocalizations.of].
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Localized names for the theory objects in `core`, kept out of the pure
/// data classes so they stay free of UI concerns (and their English values
/// stay stable for tests).
extension AppLocalizationsCore on AppLocalizations {
  String namingSystemName(NamingSystem system) => switch (system) {
    NamingSystem.scientific => namingScientific,
    NamingSystem.solfege => namingSolfege,
    NamingSystem.jianpu => namingJianpu,
  };

  String clefLabel(Clef clef) => switch (clef) {
    Clef.treble => clefTreble,
    Clef.bass => clefBass,
    Clef.alto => clefAlto,
  };

  String scaleTypeName(ScaleType type) => switch (type) {
    ScaleType.major => scaleMajor,
    ScaleType.naturalMinor => scaleNaturalMinor,
    ScaleType.harmonicMinor => scaleHarmonicMinor,
    ScaleType.melodicMinor => scaleMelodicMinor,
    ScaleType.majorPentatonic => scaleMajorPentatonic,
    ScaleType.minorPentatonic => scaleMinorPentatonic,
    ScaleType.blues => scaleBlues,
  };

  String scaleLabel(Scale scale) =>
      scaleDisplayName(scale.tonicLabel, scaleTypeName(scale.type));

  String chordExtensionName(ChordExtension extension) => switch (extension) {
    ChordExtension.triad => stackTriads,
    ChordExtension.sixth => stackSixths,
    ChordExtension.seventh => stackSevenths,
    ChordExtension.ninth => stackNinths,
    ChordExtension.eleventh => stackElevenths,
    ChordExtension.thirteenth => stackThirteenths,
  };

  String chordModeName(ChordMode mode) {
    final extension = mode.extension;
    return extension == null ? off : chordExtensionName(extension);
  }

  String tempoLabel(int bpm) => switch (tempoFor(bpm)) {
    Tempo.largo => tempoLargo,
    Tempo.larghetto => tempoLarghetto,
    Tempo.adagio => tempoAdagio,
    Tempo.andante => tempoAndante,
    Tempo.moderato => tempoModerato,
    Tempo.allegro => tempoAllegro,
    Tempo.presto => tempoPresto,
    Tempo.prestissimo => tempoPrestissimo,
  };

  String keyName(MusicalKey key) =>
      keyDisplayName(key.tonic, key.mode == KeyMode.major ? major : minor);

  String keySignatureLabel(MusicalKey key) {
    if (key.accidentals == 0) return signatureNone;
    return key.accidentals > 0
        ? signatureSharps(key.signatureCount)
        : signatureFlats(key.signatureCount);
  }

  String inversionLabel(int inversion) => switch (inversion) {
    0 => inversionRoot,
    1 => inversion1st,
    2 => inversion2nd,
    3 => inversion3rd,
    4 => inversion4th,
    5 => inversion5th,
    6 => inversion6th,
    _ => inversionNth(inversion),
  };

  /// The compact inversion name used on the chord lab's selector buttons, e.g.
  /// `Root`, `1st`, `2nd`, `3rd`.
  String inversionShortLabel(int inversion) => switch (inversion) {
    0 => inversionShortRoot,
    1 => inversionShort1st,
    2 => inversionShort2nd,
    _ => inversionShort3rd,
  };

  /// The localized fixed-do solfege name of [letter], e.g. `Do` or `レ`.
  String solfegeName(NoteLetter letter) => switch (letter) {
    NoteLetter.c => solfegeC,
    NoteLetter.d => solfegeD,
    NoteLetter.e => solfegeE,
    NoteLetter.f => solfegeF,
    NoteLetter.g => solfegeG,
    NoteLetter.a => solfegeA,
    NoteLetter.b => solfegeB,
  };

  /// The localized fixed-do solfege name of [note], including any accidental,
  /// e.g. `Fa♯`.
  String solfegeFor(Note note) {
    final suffix = note.accidental == Accidental.natural
        ? ''
        : note.accidental.text;
    return '${solfegeName(note.letter)}$suffix';
  }

  /// The descriptive name of a chord quality, e.g. `dominant seventh`.
  String chordQualityName(ChordQuality quality) =>
      _chordQualityName(quality.suffix) ?? quality.label;

  /// The display name of a progression, e.g. `Pop – I V vi IV`. Only the
  /// genre word is translated; the roman numerals stay as written. The
  /// progression category is a typed core value, not a localized string key.
  String progressionName(ChordProgression progression) =>
      '${_progressionGenre(progression.genre)} \u2013 '
      '${progression.romanNumerals}';

  String _progressionGenre(ProgressionGenre genre) => switch (genre) {
    ProgressionGenre.pop => progPop,
    ProgressionGenre.dooWop => progDooWop,
    ProgressionGenre.axis => progAxis,
    ProgressionGenre.folk => progFolk,
    ProgressionGenre.rock => progRock,
    ProgressionGenre.anthem => progAnthem,
    ProgressionGenre.singer => progSinger,
    ProgressionGenre.ballad => progBallad,
    ProgressionGenre.emo => progEmo,
    ProgressionGenre.cadence => progCadence,
    ProgressionGenre.jazz => progJazz,
    ProgressionGenre.turnaround => progTurnaround,
    ProgressionGenre.circle => progCircle,
    ProgressionGenre.minorPop => progMinorPop,
    ProgressionGenre.minorRock => progMinorRock,
    ProgressionGenre.minor => progMinor,
    ProgressionGenre.andalusian => progAndalusian,
    ProgressionGenre.canon => progCanon,
  };

  String? _chordQualityName(String suffix) => switch (suffix) {
    '' => chqMajor,
    'm' => chqMinor,
    'dim' => chqDiminished,
    'aug' => chqAugmented,
    '6' => chqMajorSixth,
    'm6' => chqMinorSixth,
    'maj7' => chqMajorSeventh,
    '7' => chqDominantSeventh,
    'm7' => chqMinorSeventh,
    'm7\u266D5' => chqHalfDiminishedSeventh,
    'dim7' => chqDiminishedSeventh,
    'mMaj7' => chqMinorMajorSeventh,
    'augMaj7' => chqAugmentedMajorSeventh,
    'maj9' => chqMajorNinth,
    '9' => chqDominantNinth,
    'm9' => chqMinorNinth,
    '7\u266D9' => chqDominantSeventhFlatNinth,
    '7\u266F9' => chqDominantSeventhSharpNinth,
    'maj11' => chqMajorEleventh,
    '11' => chqDominantEleventh,
    'm11' => chqMinorEleventh,
    '9\u266F11' => chqDominantNinthSharpEleventh,
    'maj13' => chqMajorThirteenth,
    '13' => chqDominantThirteenth,
    'm13' => chqMinorThirteenth,
    'maj13\u266F11' => chqMajorThirteenthSharpEleventh,
    '13\u266F11' => chqDominantThirteenthSharpEleventh,
    '11\u266D13' => chqDominantEleventhFlatThirteenth,
    '5' => chqPowerChord,
    'sus2' => chqSuspendedSecond,
    'sus4' => chqSuspendedFourth,
    '7sus4' => chqDominantSeventhSuspendedFourth,
    'add9' => chqAddedNinth,
    '6/9' => chqSixthNinth,
    '7\u266D5' => chqDominantSeventhFlatFive,
    '7\u266F5' => chqAugmentedSeventh,
    'add4' => chqAddedFourth,
    'add\u266F11' => chqAddedSharpEleventh,
    'madd9' => chqMinorAddedNinth,
    'madd11' => chqMinorAddedEleventh,
    '9sus4' => chqNinthSuspendedFourth,
    '13sus4' => chqThirteenthSuspendedFourth,
    'mMaj9' => chqMinorMajorNinth,
    'mMaj11' => chqMinorMajorEleventh,
    'mMaj13' => chqMinorMajorThirteenth,
    '7\u266D9\u266F11' => chqDominantSeventhFlatNinthSharpEleventh,
    '7\u266D9\u266D13' => chqDominantSeventhFlatNinthFlatThirteenth,
    'aug6' => chqAugmentedSixth,
    '6/9\u266D5' => chqSixthNinthFlatFive,
    _ => null,
  };
}

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
