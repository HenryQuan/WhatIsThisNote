part of '../home_page.dart';

extension _HomeLayoutContent on _HomePageState {
  Widget _buildResponsiveContent(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    final scale = _selectedScale;
    final chordScale = ChordService.scaleForChords(_key, scale);
    final note = _writtenNote;
    final chord = ChordService.chordFor(
      mode: _chordMode,
      quality: _chordQuality,
      scale: chordScale,
      note: note,
      inversion: _inversion,
    );
    final practiceActive = _tab == _HomeTab.practice && _practice;
    final guidedActive = _tab == _HomeTab.practice && _guided;
    final readActive = _tab == _HomeTab.practice && _read;
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

    // On a wide window the controls move into a right-hand rail so
    // the staff can use the full height instead of being squeezed
    // above a full-width control panel. Practice is a focused mode
    // and stays at the bottom even when wide. The same window width
    // decides whether the destinations are a rail or a bottom bar.
    final sidebar = constraints.maxWidth >= 900;
    final modePanel = _tab == _HomeTab.practice;
    final chordTones = readActive
        ? const <ChordToneAtStaff>[]
        : chord?.voicing(note, _step) ?? const <ChordToneAtStaff>[];

    final staff = Stack(
      fit: StackFit.expand,
      children: [
        StaffView(
          clef: _clef,
          keySignature: _key,
          step: _step,
          chordTones: chordTones,
          melodySteps: readActive ? _melody?.steps ?? const [] : const [],
          melodyIndex: _melodyIndex,
          targetStep: guidedActive ? _guidedTarget : null,
          targetAccidental: guidedActive ? _lessonStep.targetAccidental : null,
          accidental: guidedActive ? _guidedAccidentalAt(_step) : null,
          showLabel:
              widget.display.showStaffLabel &&
              !readActive &&
              (!practiceActive || _answered != null),
          interactive: !practiceActive && !readActive,
          naming: widget.display.naming,
          showEnharmonic: widget.display.showEnharmonic,
          semanticValue: (!readActive && (!practiceActive || _answered != null))
              ? note.name
              : null,
          onStepChanged: (step) {
            if (step == _step) return;
            _stopSequence();
            _update(() => _step = step);
          },
        ),
        if (widget.showCoachMark &&
            !practiceActive &&
            !guidedActive &&
            !readActive)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: _CoachMark(onDismiss: widget.onCoachMarkDismissed ?? () {}),
          ),
      ],
    );

    final selectedBuilderNote =
        _builderSelected != null && _builderSelected! < _builderNotes.length
        ? _builderNotes[_builderSelected!]
        : (_builderNotes.isNotEmpty ? _builderNotes.first : null);

    // The closest chord (or the one the learner picked) supplies the
    // ideal tones the keyboard outlines as a guide.
    final builderMatches = _builderMatches();
    final builderIdeal =
        _builderMatch ?? (builderMatches.isEmpty ? null : builderMatches.first);
    // Names written on the chord keys: the stacked notes win, so an
    // accidental the learner chose is spelled the way they wrote it.
    final builderChordLabels = <int, String>{
      if (builderIdeal != null)
        ...Chord.onNote(
          _builderRootNote(builderIdeal.rootPitchClass),
          builderIdeal.quality,
        ).pitchClassNames,
      for (final note in _builderNotes) note.midi % 12: note.pitchName,
    };

    final chordStaff = Column(
      children: [
        Expanded(
          child: ChordStaff(
            clef: _clef,
            keySignature: _key,
            notes: _builderNotes,
            selectedIndex: _builderSelected,
            highlightPitchClasses: _builderMatch?.pitchClasses ?? const <int>{},
            maxNotes: _maxBuilderNotes,
            onSelect: (index) => _update(() => _builderSelected = index),
            onAdd: _addBuilderNote,
            onMove: _moveBuilderNote,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: PianoKeyboard(
            key: const Key('chord-keyboard'),
            midi: selectedBuilderNote?.midi ?? 60,
            midiUpperOctave: _HomePageState._isUpperOctaveC(
              selectedBuilderNote,
            ),
            chordMidis: {
              for (final note in _builderNotes)
                _HomePageState._keyboardMidiFor(note.midi),
            },
            suggestedPitchClasses: builderIdeal?.pitchClasses ?? const <int>{},
            chordLabels: builderChordLabels,
            height: 64,
          ),
        ),
      ],
    );

    final panel = _homePanel(
      context,
      sidebar,
      builderMatches,
      builderIdeal,
      builderChordLabels,
      scale,
      chord,
      chordScale,
      playingPitchClass,
      playingUpperOctave,
      guidedActive,
      readActive,
    );

    if (_tab == _HomeTab.metronome || _tab == _HomeTab.about) {
      return _withNavigation(constraints.maxWidth, panel);
    }

    // The Note and Chords tabs share the same two layouts: a staff
    // on top with the controls below on phones, and a staff beside a
    // resizable controls rail on tablets. Practice stays stacked so
    // its mode switch keeps the full width.
    final main = _tab == _HomeTab.chords ? chordStaff : staff;
    if (_tab == _HomeTab.practice || !sidebar) {
      return _withNavigation(
        constraints.maxWidth,
        Column(
          children: [
            if (modePanel) _practiceModeToggle,
            Expanded(child: main),
            panel,
          ],
        ),
      );
    }

    return _staffWithPanel(constraints.maxWidth, main, panel);
  }
}
