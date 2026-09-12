import 'package:flutter/material.dart';

import '../../core/chord.dart';
import '../../core/clef.dart';
import '../../core/key.dart';
import '../../core/lesson.dart';
import '../../core/note.dart';
import '../../core/quiz.dart';
import '../../core/scale.dart';
import '../../core/staff_geometry.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/staff_view.dart';

/// The main screen: an interactive staff plus controls for the clef, the key,
/// an optional scale highlight, the note position and the theme.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Clef _clef = Clef.treble;
  MusicalKey _key = kMajorKeys.first;

  /// Optional scale highlight (an add-on), off by default.
  ScaleType? _scaleType;

  /// Optional chord lab (an add-on), off by default.
  ChordMode _chordMode = ChordMode.off;
  int _inversion = 0;
  ChordProgression? _progression;

  /// Optional guided theory path (an add-on), off by default.
  bool _guided = false;
  int _lessonIndex = 0;
  int _stepIndex = 0;

  /// Optional practice mode (name-the-note quiz), off by default.
  bool _practice = false;
  QuizBuilder? _quizBuilder;
  QuizQuestion? _question;
  String? _answered;
  int _attempts = 0;
  int _correctAnswers = 0;
  int _streak = 0;
  int _bestStreak = 0;

  /// Middle line of the treble staff (B4).
  int _step = 4;

  void _setStep(int step) {
    setState(() => _step = step.clamp(kMinStaffStep, kMaxStaffStep));
  }

  Scale? get _selectedScale => _scaleType == null
      ? null
      : Scale(_key.tonic, _key.tonicPitchClass, _scaleType!);

  /// The seven-note scale used to build chords. Falls back to the key's major
  /// or natural minor scale when the highlight set is not heptatonic.
  Scale _chordScale(Scale? selected) {
    if (selected != null && selected.isHeptatonic) return selected;
    return Scale(
      _key.tonic,
      _key.tonicPitchClass,
      _key.mode == KeyMode.major ? ScaleType.major : ScaleType.naturalMinor,
    );
  }

  /// Numbered scale degree (1..7) of a written note, by letter.
  static int _degreeOf(Note note, Scale scale) {
    var relative = (note.letter.index - scale.tonicLetter.index) % 7;
    if (relative < 0) relative += 7;
    return relative + 1;
  }

  /// The diatonic chord built on [note]'s scale degree, or `null` when the
  /// chord lab is off or [note] is not in [scale].
  Chord? _chordFor(Scale scale, Note note) {
    if (_chordMode == ChordMode.off) return null;
    if (!scale.pitchClasses.contains(note.midi % 12)) return null;
    return Chord.diatonic(
      scale,
      _degreeOf(note, scale),
      seventh: _chordMode == ChordMode.sevenths,
      inversion: _inversion,
    );
  }

  void _setChordMode(ChordMode mode) {
    setState(() {
      _chordMode = mode;
      final max = mode == ChordMode.sevenths ? 3 : 2;
      if (_inversion > max) _inversion = 0;
    });
  }

  /// Moves the note to the nearest position with [degree] (used by the
  /// progression chips).
  void _moveToDegree(int degree) {
    final scale = _chordScale(_selectedScale);
    final note = _key.applyTo(_clef.noteAt(_step));
    var delta = (degree - _degreeOf(note, scale)) % 7;
    if (delta > 3) delta -= 7;
    _setStep(_step + delta);
  }

  Lesson get _lesson => kLessons[_lessonIndex];
  LessonStep get _lessonStep => _lesson.steps[_stepIndex];
  int get _totalSteps =>
      kLessons.fold(0, (sum, lesson) => sum + lesson.steps.length);
  int get _completedSteps {
    var count = 0;
    for (var i = 0; i < _lessonIndex; i++) {
      count += kLessons[i].steps.length;
    }
    return count + _stepIndex;
  }

  bool get _isLastStep =>
      _lessonIndex == kLessons.length - 1 &&
      _stepIndex == _lesson.steps.length - 1;

  /// True once the learner has matched a practice step's target.
  bool get _practiceMatched =>
      !_lessonStep.isPractice || _step == _lessonStep.targetStep;

  /// The staff step the guided path is hinting at, or `null` when off or
  /// already matched.
  int? get _guidedTarget {
    if (!_guided || !_lessonStep.isPractice) return null;
    return _step == _lessonStep.targetStep ? null : _lessonStep.targetStep;
  }

  /// Applies a lesson step to the staff, turning the add-ons off so the path
  /// stays focused.
  void _applyLessonStep() {
    final step = _lessonStep;
    setState(() {
      _clef = step.clef;
      _key = step.key;
      _scaleType = null;
      _chordMode = ChordMode.off;
      _inversion = 0;
      _progression = null;
      _step = step.step;
    });
  }

  void _startGuided() {
    setState(() {
      _guided = true;
      _practice = false;
      _lessonIndex = 0;
      _stepIndex = 0;
    });
    _applyLessonStep();
  }

  void _exitGuided() => setState(() => _guided = false);

  /// Enters practice mode: a separate mode that hides the answer and quizzes
  /// the learner on the note drawn on the staff.
  void _startPractice() {
    setState(() {
      _practice = true;
      _guided = false;
      _scaleType = null;
      _chordMode = ChordMode.off;
      _progression = null;
      _quizBuilder = QuizBuilder(clef: _clef, key: _key);
      _attempts = 0;
      _correctAnswers = 0;
      _streak = 0;
      _bestStreak = 0;
    });
    _nextPracticeQuestion();
  }

  void _exitPractice() => setState(() => _practice = false);

  void _nextPracticeQuestion() {
    final question = _quizBuilder!.next();
    setState(() {
      _question = question;
      _answered = null;
      _step = question.step;
    });
  }

  void _answerPractice(String choice) {
    final question = _question;
    if (_answered != null || question == null) return;
    final correct = question.isCorrect(choice);
    setState(() {
      _answered = choice;
      _attempts++;
      if (correct) {
        _correctAnswers++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
      } else {
        _streak = 0;
      }
    });
  }

  void _resetPracticeScore() {
    setState(() {
      _attempts = 0;
      _correctAnswers = 0;
      _streak = 0;
      _bestStreak = 0;
    });
  }

  void _nextLessonStep() {
    if (!_practiceMatched) return;
    if (!_isLastStep) {
      setState(() {
        if (_stepIndex + 1 < _lesson.steps.length) {
          _stepIndex++;
        } else {
          _lessonIndex++;
          _stepIndex = 0;
        }
      });
      _applyLessonStep();
    } else {
      _exitGuided();
    }
  }

  void _previousLessonStep() {
    if (_lessonIndex == 0 && _stepIndex == 0) return;
    setState(() {
      if (_stepIndex > 0) {
        _stepIndex--;
      } else {
        _lessonIndex--;
        _stepIndex = kLessons[_lessonIndex].steps.length - 1;
      }
    });
    _applyLessonStep();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _selectedScale;
    final chordScale = _chordScale(scale);
    final note = _key.applyTo(_clef.noteAt(_step));
    final chord = _chordFor(chordScale, note);

    return Scaffold(
      appBar: AppBar(
        title: const Text('What is this note?'),
        actions: [
          IconButton(
            tooltip: 'Practice',
            isSelected: _practice,
            icon: const Icon(Icons.quiz),
            onPressed: _practice ? _exitPractice : _startPractice,
          ),
          IconButton(
            tooltip: 'Guided path',
            isSelected: _guided,
            icon: const Icon(Icons.school),
            onPressed: _guided ? _exitGuided : _startGuided,
          ),
          PopupMenuButton<ThemeMode>(
            tooltip: 'Theme',
            icon: Icon(_themeIcon(widget.themeMode)),
            initialValue: widget.themeMode,
            onSelected: widget.onThemeModeChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ThemeMode.system,
                child: _ThemeOption(
                  icon: Icons.brightness_auto,
                  label: 'System',
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.light,
                child: _ThemeOption(icon: Icons.light_mode, label: 'Light'),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: _ThemeOption(icon: Icons.dark_mode, label: 'Dark'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StaffView(
                clef: _clef,
                keySignature: _key,
                step: _step,
                chordSteps: chord?.staffSteps(_step) ?? const [],
                targetStep: _guidedTarget,
                showLabel: !_practice || _answered != null,
                interactive: !_practice,
                onStepChanged: (step) {
                  if (step != _step) setState(() => _step = step);
                },
              ),
            ),
            if (_guided)
              _GuidedPanel(
                key: const Key('guided-panel'),
                lesson: _lesson,
                step: _lessonStep,
                lessonIndex: _lessonIndex,
                stepIndex: _stepIndex,
                totalSteps: _totalSteps,
                completedSteps: _completedSteps,
                isLastStep: _isLastStep,
                matched: _practiceMatched,
                onBack: _previousLessonStep,
                onNext: _nextLessonStep,
                onExit: _exitGuided,
              )
            else if (_practice && _question != null)
              _PracticePanel(
                key: const Key('practice-panel'),
                question: _question!,
                answered: _answered,
                attempts: _attempts,
                correctAnswers: _correctAnswers,
                streak: _streak,
                bestStreak: _bestStreak,
                onAnswer: _answerPractice,
                onNext: _nextPracticeQuestion,
                onReset: _resetPracticeScore,
                onExit: _exitPractice,
              )
            else
              _Controls(
                key: const Key('controls'),
                clef: _clef,
                keySignature: _key,
                scale: scale,
                chord: chord,
                chordScale: chordScale,
                chordMode: _chordMode,
                inversion: chord?.inversion ?? 0,
                progression: _progression,
                step: _step,
                onClefChanged: (clef) => setState(() => _clef = clef),
                onKeyChanged: (key) => setState(() => _key = key),
                onScaleTypeChanged: (type) => setState(() => _scaleType = type),
                onChordModeChanged: _setChordMode,
                onInversionChanged: (value) =>
                    setState(() => _inversion = value),
                onProgressionChanged: (value) =>
                    setState(() => _progression = value),
                onDegreeSelected: _moveToDegree,
                onStepChanged: _setStep,
              ),
          ],
        ),
      ),
    );
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}

/// The panel shown while the guided theory path is active. It replaces the
/// manual controls with the current step and Back / Next navigation.
class _GuidedPanel extends StatelessWidget {
  const _GuidedPanel({
    super.key,
    required this.lesson,
    required this.step,
    required this.lessonIndex,
    required this.stepIndex,
    required this.totalSteps,
    required this.completedSteps,
    required this.isLastStep,
    required this.matched,
    required this.onBack,
    required this.onNext,
    required this.onExit,
  });

  final Lesson lesson;
  final LessonStep step;
  final int lessonIndex;
  final int stepIndex;
  final int totalSteps;
  final int completedSteps;
  final bool isLastStep;
  final bool matched;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final canGoBack = lessonIndex > 0 || stepIndex > 0;
    final canAdvance = !step.isPractice || matched;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Lesson ${lessonIndex + 1} of ${kLessons.length}: '
                      '${lesson.title}',
                      key: const Key('guided-lesson'),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    key: const Key('guided-exit'),
                    tooltip: 'Exit guided path',
                    icon: const Icon(Icons.close),
                    onPressed: onExit,
                  ),
                ],
              ),
              LinearProgressIndicator(
                key: const Key('guided-progress'),
                value: (completedSteps + 1) / totalSteps,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Text(
                step.title,
                key: const Key('guided-step-title'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                step.instruction,
                key: const Key('guided-instruction'),
                style: theme.textTheme.bodyMedium,
              ),
              if (step.isPractice) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      matched ? Icons.check_circle : Icons.touch_app,
                      size: 18,
                      color: matched ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        matched
                            ? 'That is the note. Well done!'
                            : 'Drag the note to the hollow notehead.',
                        key: const Key('guided-status'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: matched
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('guided-back'),
                      onPressed: canGoBack ? onBack : null,
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      key: const Key('guided-next'),
                      onPressed: canAdvance ? onNext : null,
                      child: Text(isLastStep ? 'Finish' : 'Next'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The panel shown in practice mode. It replaces the manual controls with a
/// name-the-note quiz: the staff hides the answer and the learner picks the
/// name from four choices.
class _PracticePanel extends StatelessWidget {
  const _PracticePanel({
    super.key,
    required this.question,
    required this.answered,
    required this.attempts,
    required this.correctAnswers,
    required this.streak,
    required this.bestStreak,
    required this.onAnswer,
    required this.onNext,
    required this.onReset,
    required this.onExit,
  });

  final QuizQuestion question;
  final String? answered;
  final int attempts;
  final int correctAnswers;
  final int streak;
  final int bestStreak;
  final ValueChanged<String> onAnswer;
  final VoidCallback onNext;
  final VoidCallback onReset;
  final VoidCallback onExit;

  bool get _revealed => answered != null;
  bool get _wasCorrect => _revealed && question.isCorrect(answered!);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.quiz, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Practice',
                      key: const Key('practice-title'),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (streak > 0) ...[
                    Icon(
                      Icons.local_fire_department,
                      size: 18,
                      color: scheme.tertiary,
                    ),
                    Text(
                      '$streak',
                      key: const Key('practice-streak'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    '$correctAnswers / $attempts',
                    key: const Key('practice-score'),
                    style: theme.textTheme.titleSmall,
                  ),
                  IconButton(
                    key: const Key('practice-exit'),
                    tooltip: 'Exit practice',
                    icon: const Icon(Icons.close),
                    onPressed: onExit,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'What note is this?',
                key: const Key('practice-prompt'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Pick the name of the note on the staff. '
                'Best streak: $bestStreak.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final choice in question.choices)
                    _answerButton(context, choice),
                ],
              ),
              if (_revealed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _wasCorrect ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: _wasCorrect ? scheme.primary : scheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _wasCorrect
                            ? 'Correct! It is ${question.answer}.'
                            : 'Not quite. It is ${question.answer}.',
                        key: const Key('practice-feedback'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _wasCorrect ? scheme.primary : scheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('practice-reset'),
                      onPressed: onReset,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      key: const Key('practice-next'),
                      onPressed: _revealed ? onNext : null,
                      child: const Text('Next note'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _answerButton(BuildContext context, String choice) {
    final scheme = Theme.of(context).colorScheme;
    final isAnswer = choice == question.answer;
    final isPicked = choice == answered;
    Color background;
    Color foreground;
    if (!_revealed) {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurface;
    } else if (isAnswer) {
      background = scheme.primary;
      foreground = scheme.onPrimary;
    } else if (isPicked) {
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
    } else {
      background = scheme.surfaceContainerHighest.withValues(alpha: 0.4);
      foreground = scheme.onSurfaceVariant;
    }
    return FilledButton(
      key: Key('practice-choice-$choice'),
      onPressed: _revealed ? null : () => onAnswer(choice),
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background,
        disabledForegroundColor: foreground,
        minimumSize: const Size(56, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18),
      ),
      child: Text(
        choice,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    super.key,
    required this.clef,
    required this.keySignature,
    required this.scale,
    required this.chord,
    required this.chordScale,
    required this.chordMode,
    required this.inversion,
    required this.progression,
    required this.step,
    required this.onClefChanged,
    required this.onKeyChanged,
    required this.onScaleTypeChanged,
    required this.onChordModeChanged,
    required this.onInversionChanged,
    required this.onProgressionChanged,
    required this.onDegreeSelected,
    required this.onStepChanged,
  });

  final Clef clef;
  final MusicalKey keySignature;
  final Scale? scale;
  final Chord? chord;
  final Scale chordScale;
  final ChordMode chordMode;
  final int inversion;
  final ChordProgression? progression;
  final int step;
  final ValueChanged<Clef> onClefChanged;
  final ValueChanged<MusicalKey> onKeyChanged;
  final ValueChanged<ScaleType?> onScaleTypeChanged;
  final ValueChanged<ChordMode> onChordModeChanged;
  final ValueChanged<int> onInversionChanged;
  final ValueChanged<ChordProgression?> onProgressionChanged;
  final ValueChanged<int> onDegreeSelected;
  final ValueChanged<int> onStepChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = keySignature.applyTo(clef.noteAt(step));

    final scaleDegree = scale?.degreeLabelFor(note.midi);
    final inScale = scaleDegree != null;
    final badgeColor = scale == null || inScale
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final badgeTextColor = scale == null || inScale
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final badgeLabel = scale == null ? '${note.degree}' : (scaleDegree ?? '–');

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              note.name,
                              key: const Key('note-name'),
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              note.solfege,
                              key: const Key('note-solfege'),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${clef.label} clef  ·  drag the note or tap the staff',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badgeLabel,
                                key: const Key('note-degree'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: badgeTextColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                scale == null
                                    ? 'numbered notation (1 = Do … 8 = Do)'
                                    : '${scale!.label} · '
                                          '${inScale ? 'degree $scaleDegree' : 'outside scale'}',
                                key: const Key('note-scale-caption'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton.filledTonal(
                        onPressed: step < kMaxStaffStep
                            ? () => onStepChanged(step + 1)
                            : null,
                        icon: const Icon(Icons.keyboard_arrow_up),
                        tooltip: 'Higher',
                      ),
                      IconButton.filledTonal(
                        onPressed: step > kMinStaffStep
                            ? () => onStepChanged(step - 1)
                            : null,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        tooltip: 'Lower',
                      ),
                    ],
                  ),
                ],
              ),
              if (chordMode != ChordMode.off) ...[
                const SizedBox(height: 12),
                _ChordReadout(chord: chord, chordScale: chordScale),
              ],
              const SizedBox(height: 12),
              PianoKeyboard(
                midi: note.midi,
                label: note.pitchName,
                highlightPitchClasses: scale?.pitchClasses,
                chordPitchClasses: chord?.pitchClassSet,
              ),
              const SizedBox(height: 12),
              SegmentedButton<Clef>(
                showSelectedIcon: false,
                segments: [
                  for (final value in Clef.values)
                    ButtonSegment<Clef>(value: value, label: Text(value.label)),
                ],
                selected: {clef},
                onSelectionChanged: (selection) =>
                    onClefChanged(selection.first),
              ),
              const SizedBox(height: 8),
              _KeySelector(value: keySignature, onChanged: onKeyChanged),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _ScaleSelector(
                      value: scale?.type,
                      onChanged: onScaleTypeChanged,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ChordSelector(
                      value: chordMode,
                      onChanged: onChordModeChanged,
                    ),
                  ),
                ],
              ),
              if (chordMode != ChordMode.off) ...[
                const SizedBox(height: 8),
                _InversionSelector(
                  value: inversion,
                  count: chordMode == ChordMode.sevenths ? 4 : 3,
                  onChanged: onInversionChanged,
                ),
                const SizedBox(height: 8),
                _ProgressionSelector(
                  value: progression,
                  onChanged: onProgressionChanged,
                ),
                if (progression != null) ...[
                  const SizedBox(height: 8),
                  _ProgressionChips(
                    progression: progression!,
                    scale: chordScale,
                    seventh: chordMode == ChordMode.sevenths,
                    onSelected: onDegreeSelected,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KeySelector extends StatelessWidget {
  const _KeySelector({required this.value, required this.onChanged});

  final MusicalKey value;
  final ValueChanged<MusicalKey> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<MusicalKey>(
      tooltip: 'Key signature',
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem<MusicalKey>(
          enabled: false,
          height: 34,
          child: _MenuHeader('Major'),
        ),
        for (final key in kMajorKeys)
          PopupMenuItem<MusicalKey>(
            value: key,
            height: 64,
            child: _KeyMenuEntry(musicalKey: key),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<MusicalKey>(
          enabled: false,
          height: 34,
          child: _MenuHeader('Minor'),
        ),
        for (final key in kMinorKeys)
          PopupMenuItem<MusicalKey>(
            value: key,
            height: 64,
            child: _KeyMenuEntry(musicalKey: key),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.piano, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Key: ${value.label}',
                key: const Key('key-label'),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                value.signatureLabel,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _ScaleSelector extends StatelessWidget {
  const _ScaleSelector({required this.value, required this.onChanged});

  final ScaleType? value;
  final ValueChanged<ScaleType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<_ScaleOption>(
      tooltip: 'Scale highlight',
      onSelected: (option) => onChanged(option.type),
      itemBuilder: (context) => [
        const PopupMenuItem<_ScaleOption>(
          value: _ScaleOption(null),
          child: Text('Off'),
        ),
        const PopupMenuDivider(),
        for (final type in ScaleType.values)
          PopupMenuItem<_ScaleOption>(
            value: _ScaleOption(type),
            child: Text(type.label),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.highlight, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Highlight: ${value?.label ?? 'Off'}',
                key: const Key('scale-label'),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _ScaleOption {
  const _ScaleOption(this.type);

  final ScaleType? type;
}

class _ChordSelector extends StatelessWidget {
  const _ChordSelector({required this.value, required this.onChanged});

  final ChordMode value;
  final ValueChanged<ChordMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<ChordMode>(
      tooltip: 'Chords',
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final mode in ChordMode.values)
          PopupMenuItem<ChordMode>(value: mode, child: Text(mode.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.multitrack_audio, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Chords: ${value.label}',
                key: const Key('chord-label'),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _InversionSelector extends StatelessWidget {
  const _InversionSelector({
    required this.value,
    required this.count,
    required this.onChanged,
  });

  final int value;
  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const labels = ['Root', '1st', '2nd', '3rd'];
    return SegmentedButton<int>(
      showSelectedIcon: false,
      segments: [
        for (var i = 0; i < count; i++)
          ButtonSegment<int>(value: i, label: Text(labels[i])),
      ],
      selected: {value.clamp(0, count - 1)},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}

class _ProgressionSelector extends StatelessWidget {
  const _ProgressionSelector({required this.value, required this.onChanged});

  final ChordProgression? value;
  final ValueChanged<ChordProgression?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<_ProgressionOption>(
      tooltip: 'Progression',
      onSelected: (option) => onChanged(option.value),
      itemBuilder: (context) => [
        const PopupMenuItem<_ProgressionOption>(
          value: _ProgressionOption(null),
          child: Text('Off'),
        ),
        const PopupMenuDivider(),
        for (final progression in kProgressions)
          PopupMenuItem<_ProgressionOption>(
            value: _ProgressionOption(progression),
            child: Text(progression.name),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.queue_music, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Progression: ${value?.name ?? 'Off'}',
                key: const Key('progression-label'),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _ProgressionOption {
  const _ProgressionOption(this.value);

  final ChordProgression? value;
}

class _ProgressionChips extends StatelessWidget {
  const _ProgressionChips({
    required this.progression,
    required this.scale,
    required this.seventh,
    required this.onSelected,
  });

  final ChordProgression progression;
  final Scale scale;
  final bool seventh;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('progression-chips'),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < progression.degrees.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            ActionChip(
              key: Key('prog-$i'),
              visualDensity: VisualDensity.compact,
              label: Text(
                Chord.diatonic(
                  scale,
                  progression.degrees[i],
                  seventh: seventh,
                ).romanNumeral,
              ),
              onPressed: () => onSelected(progression.degrees[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _ChordReadout extends StatelessWidget {
  const _ChordReadout({required this.chord, required this.chordScale});

  final Chord? chord;
  final Scale chordScale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chord = this.chord;
    final caption = chord == null
        ? 'chromatic note \u2013 no diatonic chord'
        : '${chord.romanNumeral}  ·  ${chord.quality.label}  ·  '
              '${chord.inversionLabel} in ${chordScale.label}';
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: scheme.tertiaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            chord?.displaySymbol ?? '\u2013',
            key: const Key('chord-symbol'),
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onTertiaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            caption,
            key: const Key('chord-caption'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _KeyMenuEntry extends StatelessWidget {
  const _KeyMenuEntry({required this.musicalKey});

  final MusicalKey musicalKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = musicalKey.signatureNotes;
    final detail = notes.isEmpty
        ? musicalKey.signatureLabel
        : '${musicalKey.signatureLabel} \u00B7 $notes';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(musicalKey.label),
        Text(
          detail,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon), const SizedBox(width: 12), Text(label)]);
  }
}
