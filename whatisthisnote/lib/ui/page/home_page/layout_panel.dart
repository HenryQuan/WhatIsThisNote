part of '../home_page.dart';

extension _HomeLayoutPanel on _HomePageState {
  Widget _homePanel(
    BuildContext context,
    bool sidebar,
    List<ChordMatch> builderMatches,
    ChordMatch? builderIdeal,
    Map<int, String> builderChordLabels,
    Scale? scale,
    Chord? chord,
    Scale chordScale,
    int? playingPitchClass,
    bool playingUpperOctave,
    bool guidedActive,
    bool readActive,
  ) {
    return switch (_tab) {
      _HomeTab.note => _Controls(
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
        onPlayHighlight: () => _toggleSequence(_Playback.highlight),
        onPlayProgression: () => _toggleSequence(_Playback.progression),
        onClefChanged: (clef) {
          _stopSequence();
          _update(() => _clef = clef);
        },
        onKeyChanged: (key) {
          _stopSequence();
          _update(() => _key = key);
        },
        onScaleTypeChanged: (type) {
          _stopSequence();
          _update(() => _scaleType = type);
        },
        onChordModeChanged: _setChordMode,
        onQualitySelected: _selectChordQuality,
        onInversionChanged: (value) {
          _stopSequence();
          _update(() => _inversion = value);
        },
        onProgressionChanged: (value) {
          _stopSequence();
          _update(() => _progression = value);
        },
        onDegreeSelected: _moveToDegree,
        onStepChanged: (step) {
          _stopSequence();
          _setStep(step);
        },
      ),
      _HomeTab.practice =>
        guidedActive
            ? _GuidedPanel(
                key: const Key('guided-panel'),
                lesson: _lesson,
                step: _lessonStep,
                lessonIndex: _lessonIndex,
                stepIndex: _stepIndex,
                totalSteps: _totalSteps,
                totalLessons: _lessons.length,
                completedSteps: _completedSteps,
                isLastStep: _isLastStep,
                matched: _practiceMatched,
                onBack: _previousLessonStep,
                onNext: _nextLessonStep,
                onExit: _exitGuided,
              )
            : readActive
            ? _ReadPanel(
                key: const Key('read-panel'),
                melody: _melody!,
                index: _melodyIndex,
                mistake: _melodyMistake,
                done: _melodyDone,
                clef: _clef,
                keySignature: _key,
                onTapPitchClass: _tapMelodyKey,
                onPlay: _playMelody,
                onNext: _nextMelody,
                onExit: _exitRead,
              )
            : _question == null
            ? const SizedBox.shrink()
            : _PracticePanel(
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
              ),
      _HomeTab.metronome => MetronomePanel(
        bpm: _bpm,
        onBpmChanged: _setBpm,
        onBeatsPerBarChanged: _setBeatsPerBar,
        playing: _metronomeOn,
        beat: _beat,
        beatsPerBar: _beatsPerBar,
        onToggle: _toggleMetronome,
        pitchClass: _registerPitchClass,
        onPitchClassChanged: (pitchClass) {
          _stopRegister();
          _update(() => _registerPitchClass = pitchClass);
        },
        zone: _registerZone,
        onZoneChanged: (zone) {
          _stopRegister();
          _update(() => _registerZone = zone);
        },
        looping: _registerLooping,
        sweeping: _registerSweeping,
        onPlayNote: _playRegisterNote,
        onToggleLoop: _toggleRegisterLoop,
        onSweep: _sweepRegister,
      ),
      _HomeTab.chords => ChordBuilderPanel(
        sidebar: sidebar,
        notes: _builderNotes,
        selectedIndex: _builderSelected,
        matches: builderMatches,
        selectedMatch: _builderMatch,
        maxNotes: _maxBuilderNotes,
        rootNoteFor: _builderRootNote,
        onSelectNote: (index) => _update(() => _builderSelected = index),
        onAccidentalChanged: _setBuilderAccidental,
        onRemoveNote: _removeBuilderNote,
        onShowSuggestions: _addBuilderNoteAbove,
        onAddBelow: _addBuilderNoteBelow,
        onNudgeSelected: _nudgeBuilderNote,
        onPlayChord: _playBuilderChord,
        onPlayMatch: _playBuilderMatch,
        onSelectMatch: _selectBuilderMatch,
        onClearAll: _clearBuilderNotes,
        keySelector: _KeySelector(
          value: _key,
          onChanged: (key) => _update(() => _key = key),
        ),
      ),
      _HomeTab.about => AboutPanel(
        themeMode: widget.themeMode,
        onThemeModeChanged: widget.onThemeModeChanged,
        display: widget.display,
        onDisplayChanged: widget.onDisplayChanged,
      ),
    };
  }
}
