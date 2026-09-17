part of '../home_page.dart';

extension _HomeActivities on _HomePageState {
  List<Lesson> get _lessons => buildLessons(context.l10n);
  Lesson get _lesson => _lessons[_lessonIndex];
  LessonStep get _lessonStep => _lesson.steps[_stepIndex];
  int get _totalSteps =>
      _lessons.fold(0, (sum, lesson) => sum + lesson.steps.length);
  int get _completedSteps {
    final lessons = _lessons;
    var count = 0;
    for (var i = 0; i < _lessonIndex; i++) {
      count += lessons[i].steps.length;
    }
    return count + _stepIndex;
  }

  bool get _isLastStep =>
      _lessonIndex == _lessons.length - 1 &&
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

  /// The accidental written on the guided note at [step], or `null` to use the
  /// key signature. The practice target's accidental applies once the learner
  /// reaches it.
  Accidental? _guidedAccidentalAt(int step) {
    if (!_guided) return null;
    final lesson = _lessonStep;
    if (lesson.targetStep == step) return lesson.targetAccidental;
    if (lesson.step == step) return lesson.accidental;
    return null;
  }

  /// The note currently written on the staff, including any guided accidental.
  Note get _writtenNote {
    final note = _key.applyTo(_clef.noteAt(_step));
    final accidental = _guidedAccidentalAt(_step);
    return accidental == null ? note : note.withAccidental(accidental);
  }

  /// Applies a lesson step to the staff, turning the add-ons off so the path
  /// stays focused.
  void _applyLessonStep() {
    if (_playback != null) _stopSequence();
    final step = _lessonStep;
    _update(() {
      _clef = step.clef;
      _key = step.key;
      _scaleType = null;
      _chordMode = ChordMode.off;
      _inversion = 0;
      _progression = null;
      _step = step.step;
    });
  }

  /// Switches the top-level destination. Leaving Practice clears its mode so
  /// the quiz cannot outlive a staff the learner changed on another tab.
  void _selectTab(_HomeTab tab) {
    if (tab == _tab) return;
    if (_playback != null) _stopSequence();
    _stopMelody();
    _stopMetronome();
    _stopRegister();
    final startPractice =
        tab == _HomeTab.practice && !_practice && !_guided && !_read;
    _update(() {
      _tab = tab;
      if (tab != _HomeTab.practice) {
        _practice = false;
        _guided = false;
        _read = false;
      }
    });
    if (startPractice) _startPractice();
  }

  void _startGuided() {
    if (_playback != null) _stopSequence();
    _update(() {
      _guided = true;
      _practice = false;
      _read = false;
      _lessonIndex = 0;
      _stepIndex = 0;
    });
    _applyLessonStep();
  }

  void _exitGuided() {
    if (_playback != null) _stopSequence();
    _update(() {
      _guided = false;
      _tab = _HomeTab.note;
    });
  }

  /// Enters practice mode: a separate mode that hides the answer and quizzes
  /// the learner on the note drawn on the staff.
  void _startPractice() {
    if (_playback != null) _stopSequence();
    _update(() {
      _practice = true;
      _guided = false;
      _read = false;
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
    _update(() {
      _practice = false;
      _tab = _HomeTab.note;
    });
  }

  void _nextPracticeQuestion() {
    final question = _quizBuilder!.next();
    _update(() {
      _question = question;
      _answered = null;
      _step = question.step;
    });
  }

  void _answerPractice(String choice) {
    final question = _question;
    if (_answered != null || question == null) return;
    final correct = question.isCorrect(choice);
    _update(() {
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
    _update(() {
      _attempts = 0;
      _correctAnswers = 0;
      _streak = 0;
      _bestStreak = 0;
    });
  }

  /// Enters read-and-play mode: a random phrase appears on the staff and the
  /// learner plays it back, left to right, on the keyboard.
  void _startRead() {
    if (_playback != null) _stopSequence();
    _stopMelody();
    _update(() {
      _read = true;
      _practice = false;
      _guided = false;
      _scaleType = null;
      _chordMode = ChordMode.off;
      _progression = null;
      _chordQuality = null;
      _melodyBuilder = MelodyBuilder();
    });
    _nextMelody();
  }

  void _exitRead() {
    if (_playback != null) _stopSequence();
    _stopMelody();
    _update(() {
      _read = false;
      _tab = _HomeTab.note;
    });
  }

  /// Starts a fresh random phrase.
  void _nextMelody() {
    _stopMelody();
    final melody = _melodyBuilder!.next();
    _update(() {
      _melody = melody;
      _melodyIndex = 0;
      _melodyMistake = false;
      _melodyDone = false;
      _step = melody.steps.first;
    });
  }

  /// Handles a key the learner tapped while reading the phrase.
  void _tapMelodyKey(int pitchClass) {
    final melody = _melody;
    if (melody == null || _melodyDone) return;
    final note = _key.applyTo(_clef.noteAt(melody.steps[_melodyIndex]));
    if (pitchClass != note.midi % 12) {
      _update(() => _melodyMistake = true);
      return;
    }
    _stopMelody();
    unawaited(
      _notePlayer.play([note.frequency], duration: _sequenceNoteDuration),
    );
    _update(() {
      _melodyMistake = false;
      if (_melodyIndex + 1 < melody.length) {
        _melodyIndex++;
      } else {
        _melodyDone = true;
      }
      _step = melody.steps[_melodyIndex];
    });
  }

  /// Plays the whole phrase so the learner can check their reading.
  ///
  /// The notes are queued one at a time, each awaited before the next is
  /// scheduled, because [NotePlayer.play] sounds its frequencies together (a
  /// chord). This is the same one-note-at-a-time approach the scale and
  /// progression sequences use, which keeps the notes distinct and even on
  /// mobile.
  Future<void> _playMelody() async {
    final melody = _melody;
    if (melody == null) return;
    _stopSequence();
    final token = ++_melodyToken;
    for (final step in melody.steps) {
      if (!mounted || token != _melodyToken) return;
      await _notePlayer.play([
        _key.applyTo(_clef.noteAt(step)).frequency,
      ], duration: _sequenceNoteDuration);
      if (!mounted || token != _melodyToken) return;
      await Future<void>.delayed(_sequenceStepGap);
    }
  }

  /// Stops a phrase playback in progress.
  void _stopMelody() {
    _melodyToken++;
  }

  void _nextLessonStep() {
    if (!_practiceMatched) return;
    if (!_isLastStep) {
      _update(() {
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
    _update(() {
      if (_stepIndex > 0) {
        _stepIndex--;
      } else {
        _lessonIndex--;
        _stepIndex = _lessons[_lessonIndex].steps.length - 1;
      }
    });
    _applyLessonStep();
  }
}
