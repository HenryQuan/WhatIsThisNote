import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../audio/note_player.dart';
import '../../core/chord.dart';
import '../../core/clef.dart';
import '../../core/display_preferences.dart';
import '../../core/key.dart';
import '../../core/lesson.dart';
import '../../core/note.dart';
import '../../core/quiz.dart';
import '../../core/scale.dart';
import '../../core/staff_geometry.dart';
import '../widgets/display_settings_sheet.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/staff_view.dart';

/// The two kinds of note sequence that can be played automatically.
enum _Playback { highlight, progression }

/// How long each note of a sequence rings, and how long to wait before the
/// next one starts. The gap is a little longer than the sound so the notes
/// stay distinct.
const Duration _sequenceNoteDuration = Duration(milliseconds: 340);
const Duration _sequenceStepGap = Duration(milliseconds: 420);

/// The main screen: an interactive staff plus controls for the clef, the key,
/// an optional scale highlight, the note position and the theme.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.display,
    required this.onDisplayChanged,
    this.notePlayer,
    this.showCoachMark = false,
    this.onCoachMarkDismissed,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final DisplayPreferences display;
  final ValueChanged<DisplayPreferences> onDisplayChanged;

  /// Overrides the audio player, used by tests to avoid the native plugin.
  final NotePlayer? notePlayer;

  /// Whether to show the one-time first-run coach mark over the staff.
  final bool showCoachMark;

  /// Called when the learner dismisses the coach mark.
  final VoidCallback? onCoachMarkDismissed;

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

  /// A specific chord picked from the readout, overriding the diatonic chord.
  ChordQuality? _chordQuality;

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

  /// Width of the wide-layout controls rail, dragged by the user.
  double _sidebarWidth = 380;

  /// The sequence currently playing automatically, if any, and which note of
  /// it is sounding. [_playbackToken] invalidates in-flight timer callbacks
  /// when a sequence is stopped or replaced.
  _Playback? _playback;
  int? _playbackIndex;
  int _playbackToken = 0;
  Timer? _playbackTimer;

  void _setStep(int step) {
    setState(() => _step = step.clamp(kMinStaffStep, kMaxStaffStep));
  }

  /// Created on first use so tests that inject a player never touch the plugin.
  NotePlayer? _ownedPlayer;
  NotePlayer get _notePlayer =>
      widget.notePlayer ?? (_ownedPlayer ??= AudioNotePlayer());

  /// Catches app-wide keyboard shortcuts (arrow keys, space) that bubble up
  /// from the focused control.
  final FocusNode _keyboardFocus = FocusNode(debugLabel: 'home-shortcuts');

  @override
  void dispose() {
    _keyboardFocus.dispose();
    _playbackTimer?.cancel();
    _playbackToken++;
    _ownedPlayer?.dispose();
    super.dispose();
  }

  /// Plays whatever is currently shown, including the chord-lab voicing.
  void _playCurrent({Duration? duration}) {
    final scale = _selectedScale;
    final note = _key.applyTo(_clef.noteAt(_step));
    _playSound(note, _chordFor(_chordScale(scale), note), duration: duration);
  }

  /// Plays the current note/chord and cancels any running sequence, used by
  /// the play button and the space shortcut.
  void _playNow() {
    _stopSequence();
    _playCurrent();
  }

  /// Whether the keyboard focus is on a button, so space/arrows should keep
  /// their normal button behaviour instead of being treated as shortcuts.
  bool _focusIsInteractive() {
    final context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    return context.findAncestorWidgetOfExactType<ButtonStyleButton>() != null ||
        context.findAncestorWidgetOfExactType<InkWell>() != null;
  }

  KeyEventResult _onShortcut(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (_focusIsInteractive()) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _stopSequence();
      _setStep(_step + 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _stopSequence();
      _setStep(_step - 1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.space) {
      _playNow();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// The frequencies for the written [note], or [chord]'s tones when the
  /// chord lab is on, voiced from the current staff position.
  List<double> _frequenciesFor(Note note, Chord? chord) {
    if (chord == null) return <double>[note.frequency];
    return <double>[
      for (final step in chord.staffSteps(_step))
        _key.applyTo(_clef.noteAt(step)).frequency,
    ];
  }

  /// Plays the written [note], or [chord]'s tones when the chord lab is on.
  void _playSound(Note note, Chord? chord, {Duration? duration}) {
    _notePlayer.play(_frequenciesFor(note, chord), duration: duration);
  }

  /// Stops any automatic playback and clears its highlight.
  void _stopSequence() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _playbackToken++;
    if (_playback != null || _playbackIndex != null) {
      setState(() {
        _playback = null;
        _playbackIndex = null;
      });
    }
  }

  /// Starts [kind] from the top, or stops it when it is already playing.
  void _toggleSequence(_Playback kind) {
    if (_playback == kind) {
      _stopSequence();
      return;
    }
    final total = _sequenceLength(kind);
    if (total == 0) return;
    _stopSequence();
    final token = _playbackToken;
    setState(() {
      _playback = kind;
      _playbackIndex = 0;
    });
    _playSequenceStep(token, kind, 0);
  }

  /// How many steps [kind] plays. A scale gets one extra note so it ends on
  /// the tonic an octave up. Returns 0 when the required selection is missing.
  int _sequenceLength(_Playback kind) {
    switch (kind) {
      case _Playback.highlight:
        final type = _scaleType;
        return type == null ? 0 : type.degrees.length + 1;
      case _Playback.progression:
        return _progression?.degrees.length ?? 0;
    }
  }

  /// Plays one step of the running sequence and schedules the next.
  void _playSequenceStep(int token, _Playback kind, int index) {
    if (!mounted || token != _playbackToken) return;
    if (index >= _sequenceLength(kind)) {
      _stopSequence();
      return;
    }
    setState(() => _playbackIndex = index);

    if (kind == _Playback.highlight) {
      final scale = _selectedScale!;
      final octave = _key.applyTo(_clef.noteAt(_step)).octave;
      _notePlayer.play(<double>[
        scale.frequencies(octave: octave, includeOctave: true)[index],
      ], duration: _sequenceNoteDuration);
    } else {
      _jumpToDegree(_progression!.degrees[index]);
      _playCurrent(duration: _sequenceNoteDuration);
    }

    _playbackTimer = Timer(
      _sequenceStepGap,
      () => _playSequenceStep(token, kind, index + 1),
    );
  }

  void _openDisplaySettings() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => DisplaySettingsSheet(
        preferences: widget.display,
        onChanged: widget.onDisplayChanged,
      ),
    );
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

  /// The chord built on [note] in [scale]: the diatonic chord when the note is
  /// in the scale, and a chromatic transformation of it when the note lies
  /// outside, so a transformed augmented or diminished shape still appears.
  /// Returns `null` only when the chord lab is off.
  Chord? _chordFor(Scale scale, Note note) {
    if (_chordMode == ChordMode.off) return null;
    final override = _chordQuality;
    if (override != null) {
      return Chord.onNote(note, override, inversion: _inversion);
    }
    if (scale.pitchClasses.contains(note.midi % 12)) {
      return Chord.diatonic(
        scale,
        _degreeOf(note, scale),
        extension: _chordMode.extension!,
        inversion: _inversion,
      );
    }
    return Chord.chromatic(
      scale,
      note,
      extension: _chordMode.extension!,
      inversion: _inversion,
    );
  }

  /// Selects a specific chord for the current root, or clears the override when
  /// the diatonic chord is wanted again.
  void _selectChordQuality(ChordQuality quality) {
    _stopSequence();
    setState(() {
      _chordQuality = quality;
      _inversion = 0;
    });
  }

  void _setChordMode(ChordMode mode) {
    if (_playback != null) _stopSequence();
    setState(() {
      _chordMode = mode;
      _chordQuality = null;
      final tones = mode.extension?.toneCount ?? 0;
      final max = tones == 0 ? 0 : (tones - 1).clamp(0, 3);
      if (_inversion > max) _inversion = 0;
      // Progression chips belong to the chord lab; clear the selection when
      // the lab is turned off so nothing stale renders in the rail.
      if (mode == ChordMode.off) _progression = null;
    });
  }

  /// Moves the note to the nearest position with [degree], stopping any
  /// running sequence (used by the progression chips).
  void _moveToDegree(int degree) {
    _stopSequence();
    _jumpToDegree(degree);
  }

  /// Moves the note to the nearest position with [degree] without touching
  /// playback, so the progression sequence can walk the chips.
  void _jumpToDegree(int degree) {
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
    if (_playback != null) _stopSequence();
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
    if (_playback != null) _stopSequence();
    setState(() {
      _guided = true;
      _practice = false;
      _lessonIndex = 0;
      _stepIndex = 0;
    });
    _applyLessonStep();
  }

  void _exitGuided() {
    if (_playback != null) _stopSequence();
    setState(() => _guided = false);
  }

  /// Enters practice mode: a separate mode that hides the answer and quizzes
  /// the learner on the note drawn on the staff.
  void _startPractice() {
    if (_playback != null) _stopSequence();
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

  void _exitPractice() {
    if (_playback != null) _stopSequence();
    setState(() => _practice = false);
  }

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
    int? playingPitchClass;
    var playingUpperOctave = false;
    if (_playback == _Playback.highlight &&
        _playbackIndex != null &&
        scale != null) {
      final degrees = scale.type.degrees;
      final semitone = _playbackIndex! < degrees.length
          ? degrees[_playbackIndex!].semitone
          : 12;
      final absolute = scale.tonicPitchClass + semitone;
      playingPitchClass = absolute % 12;
      // The keyboard shows a single C-to-C octave, so the closing tonic must
      // light the upper C rather than the lower one.
      playingUpperOctave = absolute >= 12;
    }

    return Focus(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: _onShortcut,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'What is this note?',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
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
            IconButton(
              key: const Key('display-settings'),
              tooltip: 'Display',
              icon: const Icon(Icons.tune),
              onPressed: _openDisplaySettings,
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              // On a wide window the controls move into a right-hand rail so
              // the staff can use the full height instead of being squeezed
              // above a full-width control panel. Guided and practice are
              // focused modes and stay at the bottom even when wide.
              final sidebar = constraints.maxWidth >= 900;
              final modePanel = _guided || (_practice && _question != null);

              final staff = Stack(
                fit: StackFit.expand,
                children: [
                  StaffView(
                    clef: _clef,
                    keySignature: _key,
                    step: _step,
                    chordSteps: chord?.staffSteps(_step) ?? const [],
                    targetStep: _guidedTarget,
                    showLabel:
                        widget.display.showStaffLabel &&
                        (!_practice || _answered != null),
                    interactive: !_practice,
                    naming: widget.display.naming,
                    showEnharmonic: widget.display.showEnharmonic,
                    semanticValue: (!_practice || _answered != null)
                        ? note.name
                        : null,
                    onStepChanged: (step) {
                      if (step == _step) return;
                      _stopSequence();
                      setState(() => _step = step);
                    },
                  ),
                  if (widget.showCoachMark && !_practice && !_guided)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: _CoachMark(
                        onDismiss: widget.onCoachMarkDismissed ?? () {},
                      ),
                    ),
                ],
              );

              final panel = _guided
                  ? _GuidedPanel(
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
                  : (_practice && _question != null)
                  ? _PracticePanel(
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
                  : _Controls(
                      key: const Key('controls'),
                      sidebar: sidebar,
                      clef: _clef,
                      keySignature: _key,
                      display: widget.display,
                      scale: scale,
                      chord: chord,
                      chordScale: chordScale,
                      chordMode: _chordMode,
                      inversion: chord?.inversion ?? 0,
                      selectedQuality: _chordQuality,
                      progression: _progression,
                      step: _step,
                      playingPitchClass: playingPitchClass,
                      playingUpperOctave: playingUpperOctave,
                      highlightPlaying: _playback == _Playback.highlight,
                      progressionPlaying: _playback == _Playback.progression,
                      activeProgressionIndex: _playback == _Playback.progression
                          ? _playbackIndex
                          : null,
                      onPlay: _playNow,
                      onPlayHighlight: () =>
                          _toggleSequence(_Playback.highlight),
                      onPlayProgression: () =>
                          _toggleSequence(_Playback.progression),
                      onClefChanged: (clef) {
                        _stopSequence();
                        setState(() => _clef = clef);
                      },
                      onKeyChanged: (key) {
                        _stopSequence();
                        setState(() => _key = key);
                      },
                      onScaleTypeChanged: (type) {
                        _stopSequence();
                        setState(() => _scaleType = type);
                      },
                      onChordModeChanged: _setChordMode,
                      onQualitySelected: _selectChordQuality,
                      onInversionChanged: (value) {
                        _stopSequence();
                        setState(() => _inversion = value);
                      },
                      onProgressionChanged: (value) {
                        _stopSequence();
                        setState(() => _progression = value);
                      },
                      onDegreeSelected: _moveToDegree,
                      onStepChanged: (step) {
                        _stopSequence();
                        _setStep(step);
                      },
                    );

              if (!sidebar || modePanel) {
                return Column(
                  children: [
                    Expanded(child: staff),
                    panel,
                  ],
                );
              }

              final maxSidebarWidth = (constraints.maxWidth - 420).clamp(
                320.0,
                820.0,
              );
              final sidebarWidth = _sidebarWidth.clamp(280.0, maxSidebarWidth);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: staff),
                  _SidebarResizer(
                    onDrag: (dx) => setState(() {
                      _sidebarWidth = (_sidebarWidth - dx).clamp(
                        280.0,
                        maxSidebarWidth,
                      );
                    }),
                  ),
                  SizedBox(width: sidebarWidth, child: panel),
                ],
              );
            },
          ),
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

/// The draggable divider between the staff and the controls rail. Dragging it
/// left widens the rail and dragging it right shrinks it.
class _SidebarResizer extends StatelessWidget {
  const _SidebarResizer({required this.onDrag});

  /// Called with the horizontal drag delta (positive when dragging right).
  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: Semantics(
          label: 'Resize controls panel',
          child: SizedBox(
            width: 12,
            child: Center(
              child: Container(width: 1, color: scheme.outlineVariant),
            ),
          ),
        ),
      ),
    );
  }
}

/// The one-time first-run coach mark shown over the staff. It explains the two
/// core gestures and can be dismissed with a single tap.
class _CoachMark extends StatelessWidget {
  const _CoachMark({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      label:
          'Onboarding. Drag the note up or down to change its pitch, or tap '
          'a line to jump to it.',
      child: Stack(
        children: [
          // The card body lets gestures fall through to the staff underneath;
          // only the "Got it" button is interactive, so the coach mark never
          // blocks the very gesture it is teaching.
          IgnorePointer(
            child: Material(
              key: const Key('onboarding-coach'),
              color: scheme.inverseSurface,
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, color: scheme.onInverseSurface),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Drag the note up or down to change pitch. Tap a line '
                        'to jump there.',
                        style: TextStyle(color: scheme.onInverseSurface),
                      ),
                    ),
                    const SizedBox(width: 84),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: TextButton(
                key: const Key('onboarding-dismiss'),
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onInverseSurface,
                ),
                child: const Text('Got it'),
              ),
            ),
          ),
        ],
      ),
    );
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
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
/// name from five choices.
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
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
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
        minimumSize: const Size(76, 54),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: Text(choice),
    );
  }
}

/// Reserves the width of one accidental glyph in the note readout so that a
/// sharp or flat appearing mid-drag never reflows the panel. The glyph itself
/// is fully transparent and hidden from assistive tech.
class _AccidentalReserve extends StatelessWidget {
  const _AccidentalReserve({super.key, required this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        '\u266F',
        maxLines: 1,
        style: (style ?? const TextStyle()).copyWith(
          color: const Color(0x00000000),
        ),
      ),
    );
  }
}

/// A small play/stop button shown beside the highlight and progression
/// selectors; it runs that sequence, or stops it while it is playing.
class _SequenceButton extends StatelessWidget {
  const _SequenceButton({
    super.key,
    required this.playing,
    required this.onPressed,
    required this.tooltip,
  });

  final bool playing;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      isSelected: playing,
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      icon: Icon(playing ? Icons.stop : Icons.play_arrow),
      tooltip: playing ? 'Stop' : tooltip,
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    super.key,
    this.sidebar = false,
    required this.clef,
    required this.keySignature,
    required this.display,
    required this.scale,
    required this.chord,
    required this.chordScale,
    required this.chordMode,
    required this.inversion,
    required this.selectedQuality,
    required this.progression,
    required this.step,
    required this.playingPitchClass,
    required this.playingUpperOctave,
    required this.highlightPlaying,
    required this.progressionPlaying,
    required this.activeProgressionIndex,
    required this.onPlay,
    required this.onPlayHighlight,
    required this.onPlayProgression,
    required this.onClefChanged,
    required this.onKeyChanged,
    required this.onScaleTypeChanged,
    required this.onChordModeChanged,
    required this.onQualitySelected,
    required this.onInversionChanged,
    required this.onProgressionChanged,
    required this.onDegreeSelected,
    required this.onStepChanged,
  });

  /// Whether the panel is shown as a full-height rail beside the staff
  /// instead of a bar below it.
  final bool sidebar;

  final Clef clef;
  final MusicalKey keySignature;
  final DisplayPreferences display;
  final Scale? scale;
  final Chord? chord;
  final Scale chordScale;
  final ChordMode chordMode;
  final int inversion;
  final ChordQuality? selectedQuality;
  final ChordProgression? progression;
  final int step;
  final int? playingPitchClass;
  final bool playingUpperOctave;
  final bool highlightPlaying;
  final bool progressionPlaying;
  final int? activeProgressionIndex;
  final VoidCallback onPlay;
  final VoidCallback onPlayHighlight;
  final VoidCallback onPlayProgression;
  final ValueChanged<Clef> onClefChanged;
  final ValueChanged<MusicalKey> onKeyChanged;
  final ValueChanged<ScaleType?> onScaleTypeChanged;
  final ValueChanged<ChordMode> onChordModeChanged;
  final ValueChanged<ChordQuality> onQualitySelected;
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

    final primaryName = switch (display.naming) {
      NamingSystem.scientific => note.name,
      NamingSystem.solfege => note.solfege,
      NamingSystem.jianpu => keySignature.jianpuFor(note),
    };
    final secondaryNames = <(Key, String)>[
      if (display.naming != NamingSystem.scientific)
        (const Key('note-pitch'), note.name),
      if (display.naming != NamingSystem.solfege)
        (const Key('note-solfege'), note.solfege),
      if (display.naming != NamingSystem.jianpu)
        (const Key('note-jianpu'), keySignature.jianpuFor(note)),
    ];
    final enharmonic = display.showEnharmonic ? note.enharmonicName : null;

    // Tablets and desktop windows get a compact layout: the keyboard shares
    // the readout row and the selectors wrap into one or two lines, leaving
    // more of the screen for the staff. In the sidebar the rail is narrow, so
    // the stacked layout is used regardless of the window width.
    final wide = !sidebar && MediaQuery.sizeOf(context).width >= 720;

    final clefSelector = SegmentedButton<Clef>(
      showSelectedIcon: false,
      segments: [
        for (final value in Clef.values)
          ButtonSegment<Clef>(value: value, label: Text(value.label)),
      ],
      selected: {clef},
      onSelectionChanged: (selection) => onClefChanged(selection.first),
    );
    final keySelector = _KeySelector(
      value: keySignature,
      onChanged: onKeyChanged,
    );
    final scaleSelector = _ScaleSelector(
      value: scale?.type,
      onChanged: onScaleTypeChanged,
    );
    final chordSelector = _ChordSelector(
      value: chordMode,
      onChanged: onChordModeChanged,
    );
    final chordTones =
        selectedQuality?.toneCount ?? chordMode.extension?.toneCount ?? 3;
    final inversionSelector = _InversionSelector(
      value: inversion,
      count: chordTones.clamp(3, 4),
      onChanged: onInversionChanged,
    );
    final progressionSelector = _ProgressionSelector(
      value: progression,
      onChanged: onProgressionChanged,
    );

    // Each selector gets a play button beside it: the highlight plays its
    // scale note by note, the progression plays its chords in turn.
    final scaleRow = Row(
      children: [
        Expanded(child: scaleSelector),
        const SizedBox(width: 4),
        _SequenceButton(
          key: const Key('play-highlight'),
          playing: highlightPlaying,
          onPressed: scale == null ? null : onPlayHighlight,
          tooltip: 'Play the highlighted scale',
        ),
      ],
    );
    final progressionRow = Row(
      children: [
        Expanded(child: progressionSelector),
        const SizedBox(width: 4),
        _SequenceButton(
          key: const Key('play-progression'),
          playing: progressionPlaying,
          onPressed: progression == null ? null : onPlayProgression,
          tooltip: 'Play the progression',
        ),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: sidebar
            ? double.infinity
            : MediaQuery.sizeOf(context).height * 0.72,
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
                            Flexible(
                              child: Semantics(
                                liveRegion: true,
                                child: Text(
                                  primaryName,
                                  key: const Key('note-name'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                            ),
                            // Reserve room for an accidental even on natural
                            // notes so a sharp/flat appearing mid-drag does not
                            // widen the readout and shift the layout.
                            if (note.isNatural)
                              _AccidentalReserve(
                                key: const Key('note-name-reserve'),
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            if (enharmonic != null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '\u2248 $enharmonic',
                                  key: const Key('note-enharmonic'),
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.headlineSmall
                                      ?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (secondaryNames.isNotEmpty)
                          Row(
                            children: [
                              for (
                                var i = 0;
                                i < secondaryNames.length;
                                i++
                              ) ...[
                                if (i > 0) const SizedBox(width: 12),
                                Flexible(
                                  child: Text(
                                    secondaryNames[i].$2,
                                    key: secondaryNames[i].$1,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                  ),
                                ),
                                if (note.isNatural)
                                  _AccidentalReserve(
                                    style: theme.textTheme.headlineSmall,
                                  ),
                              ],
                            ],
                          ),
                        Text(
                          '${clef.label} clef',
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
                                    ? '1 = Do ... 8 = Do'
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
                        key: const Key('play-note'),
                        onPressed: onPlay,
                        icon: const Icon(Icons.volume_up),
                        tooltip: chord == null ? 'Play note' : 'Play chord',
                      ),
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
                  if (wide) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: PianoKeyboard(
                        midi: note.midi,
                        label: note.pitchName,
                        highlightPitchClasses: scale?.pitchClasses,
                        chordPitchClasses: chord?.pitchClassSet,
                        playingPitchClass: playingPitchClass,
                        playingUpperOctave: playingUpperOctave,
                      ),
                    ),
                  ],
                ],
              ),
              if (chordMode != ChordMode.off) ...[
                const SizedBox(height: 12),
                _ChordReadout(
                  chord: chord,
                  chordScale: chordScale,
                  rootName: chord?.rootName ?? note.pitchName,
                  selectedQuality: selectedQuality,
                  onQualitySelected: onQualitySelected,
                ),
              ],
              if (!wide) ...[
                const SizedBox(height: 12),
                PianoKeyboard(
                  midi: note.midi,
                  label: note.pitchName,
                  highlightPitchClasses: scale?.pitchClasses,
                  chordPitchClasses: chord?.pitchClassSet,
                  playingPitchClass: playingPitchClass,
                  playingUpperOctave: playingUpperOctave,
                ),
              ],
              const SizedBox(height: 12),
              if (wide)
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    clefSelector,
                    SizedBox(width: 280, child: keySelector),
                    SizedBox(width: 260, child: scaleRow),
                    SizedBox(width: 220, child: chordSelector),
                    if (chordMode != ChordMode.off)
                      SizedBox(width: 300, child: progressionRow),
                    if (chordMode != ChordMode.off) inversionSelector,
                  ],
                )
              else ...[
                clefSelector,
                const SizedBox(height: 8),
                keySelector,
                const SizedBox(height: 8),
                // In the rail the selectors are full-width so their labels
                // never have to truncate; the phone layout keeps them paired.
                if (sidebar) ...[
                  scaleRow,
                  const SizedBox(height: 8),
                  chordSelector,
                ] else
                  Row(
                    children: [
                      Expanded(child: scaleRow),
                      const SizedBox(width: 8),
                      Expanded(child: chordSelector),
                    ],
                  ),
                if (chordMode != ChordMode.off) ...[
                  const SizedBox(height: 8),
                  inversionSelector,
                  const SizedBox(height: 8),
                  progressionRow,
                ],
              ],
              if (chordMode != ChordMode.off && progression != null) ...[
                const SizedBox(height: 8),
                _ProgressionChips(
                  progression: progression!,
                  scale: chordScale,
                  extension: chordMode.extension ?? ChordExtension.triad,
                  alignment: wide
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.start,
                  wrap: sidebar,
                  activeIndex: activeProgressionIndex,
                  onSelected: onDegreeSelected,
                ),
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
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
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
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
    required this.extension,
    required this.onSelected,
    this.alignment = MainAxisAlignment.start,
    this.wrap = false,
    this.activeIndex,
  });

  final ChordProgression progression;
  final Scale scale;
  final ChordExtension extension;
  final ValueChanged<int> onSelected;

  /// How the chips are aligned when they do not fill the row.
  final MainAxisAlignment alignment;

  /// Whether the chips flow onto multiple lines instead of scrolling
  /// horizontally. Used in the narrow controls rail so no chip is ever cut
  /// off at the edge.
  final bool wrap;

  /// The index of the chip whose chord is currently sounding, so it can be
  /// emphasised while the progression plays.
  final int? activeIndex;

  List<Widget> _buildChips(
    ChordProgression progression, {
    required bool keyed,
    required ColorScheme scheme,
  }) => [
    for (var i = 0; i < progression.degrees.length; i++)
      ActionChip(
        key: keyed ? Key('prog-$i') : null,
        visualDensity: VisualDensity.compact,
        backgroundColor: keyed && i == activeIndex
            ? scheme.secondaryContainer
            : null,
        label: Text(
          Chord.diatonic(
            scale,
            progression.degrees[i],
            extension: extension,
          ).romanNumeral,
          // Only the colour changes, never the weight, so the active chip
          // keeps its width and the row never reflows while playing.
          style: keyed && i == activeIndex
              ? TextStyle(color: scheme.onSecondaryContainer)
              : null,
        ),
        onPressed: () => onSelected(progression.degrees[i]),
      ),
  ];

  Wrap _wrapChips(List<Widget> chips) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: alignment == MainAxisAlignment.end
        ? WrapAlignment.end
        : WrapAlignment.start,
    children: chips,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chips = _buildChips(progression, keyed: true, scheme: scheme);
    if (wrap) {
      // Reserve the height needed by the longest built-in progression so the
      // rail does not resize (and the panel does not jump) when switching
      // between progressions with different numbers of chips.
      final longest = kProgressions.reduce(
        (a, b) => a.degrees.length >= b.degrees.length ? a : b,
      );
      return Stack(
        children: [
          if (longest != progression)
            ExcludeFocus(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: 0,
                    child: _wrapChips(
                      _buildChips(longest, keyed: false, scheme: scheme),
                    ),
                  ),
                ),
              ),
            ),
          KeyedSubtree(
            key: const Key('progression-chips'),
            child: _wrapChips(chips),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: const Key('progression-chips'),
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: alignment,
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                chips[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ChordReadout extends StatelessWidget {
  const _ChordReadout({
    required this.chord,
    required this.chordScale,
    required this.rootName,
    required this.selectedQuality,
    required this.onQualitySelected,
  });

  final Chord? chord;
  final Scale chordScale;

  /// The root the quality menu is built on.
  final String rootName;

  /// The specific chord currently picked, or `null` for the diatonic chord.
  final ChordQuality? selectedQuality;

  final ValueChanged<ChordQuality> onQualitySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chord = this.chord;
    final caption = chord == null
        ? 'chromatic note \u2013 no diatonic chord'
        : chord.diatonic
        ? '${chord.romanNumeral}  ·  ${chord.quality.label}  ·  '
              '${chord.inversionLabel} in ${chordScale.label}'
        : chord.chromatic
        ? '${chord.romanNumeral}  ·  ${chord.quality.label}  ·  '
              '${chord.inversionLabel}  ·  chromatic'
        : '${chord.quality.label}  ·  ${chord.inversionLabel}  ·  '
              'chosen chord';
    return Row(
      children: [
        PopupMenuButton<ChordQuality>(
          key: const Key('chord-menu'),
          tooltip: 'Choose a chord',
          onSelected: onQualitySelected,
          itemBuilder: (context) => [
            for (final quality in kChordQualities)
              CheckedPopupMenuItem<ChordQuality>(
                value: quality,
                checked: quality == selectedQuality,
                child: Text('$rootName${quality.suffix}'),
              ),
          ],
          child: Container(
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
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            caption,
            key: const Key('chord-caption'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
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
