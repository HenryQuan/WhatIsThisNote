part of '../home_page.dart';

extension _HomePlayback on _HomePageState {
  /// Plays whatever is currently shown, including the chord-lab voicing.
  Future<void> _playCurrent({Duration? duration}) {
    final scale = _selectedScale;
    final note = _writtenNote;
    return _playSound(
      note,
      ChordService.chordFor(
        mode: _chordMode,
        quality: _chordQuality,
        scale: ChordService.scaleForChords(_key, scale),
        note: note,
        inversion: _inversion,
      ),
      duration: duration,
    );
  }

  /// Plays the current note/chord and cancels any running sequence, used by
  /// the play button and the space shortcut.
  void _playNow() {
    _stopSequence();
    unawaited(_playCurrent());
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
    // Only the Note and Chords tabs drive the staff from the keyboard; the
    // other destinations ignore the arrow keys and space bar.
    if (_tab == _HomeTab.note) {
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
    } else if (_tab == _HomeTab.chords) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _nudgeBuilderNote(1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _nudgeBuilderNote(-1);
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.space) {
        if (_builderNotes.isNotEmpty) _playBuilderChord();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  /// Plays the written [note], or [chord]'s tones when the chord lab is on.
  Future<void> _playSound(Note note, Chord? chord, {Duration? duration}) {
    final frequencies = chord == null
        ? <double>[note.frequency]
        : [for (final tone in chord.voicing(note, _step)) tone.note.frequency];
    return _notePlayer.play(frequencies, duration: duration);
  }

  /// Stops any automatic playback and clears its highlight.
  void _stopSequence() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    _playbackToken++;
    if (_playback != null || _playbackIndex != null) {
      _update(() {
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
    _update(() {
      _playback = kind;
      _playbackIndex = 0;
    });
    unawaited(_playSequenceStep(token, kind, 0));
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
  ///
  /// The step's tone is awaited before the next one is scheduled. Starting the
  /// next tone stops the current one, and on iOS starting a tone takes a moment
  /// (the bytes are written to a file and prepared), so overlapping starts used
  /// to cancel every note but the last. Waiting keeps each note sounding.
  Future<void> _playSequenceStep(int token, _Playback kind, int index) async {
    if (!mounted || token != _playbackToken) return;
    if (index >= _sequenceLength(kind)) {
      _stopSequence();
      return;
    }
    _update(() => _playbackIndex = index);

    if (kind == _Playback.highlight) {
      final scale = _selectedScale!;
      final octave = _key.applyTo(_clef.noteAt(_step)).octave;
      await _notePlayer.play(<double>[
        scale.frequencies(octave: octave, includeOctave: true)[index],
      ], duration: _sequenceNoteDuration);
    } else {
      _jumpToDegree(_progression!.degrees[index]);
      await _playCurrent(duration: _sequenceNoteDuration);
    }

    if (!mounted || token != _playbackToken) return;
    _playbackTimer = Timer(
      _sequenceStepGap,
      () => unawaited(_playSequenceStep(token, kind, index + 1)),
    );
  }

  Scale? get _selectedScale => _scaleType == null
      ? null
      : Scale(_key.tonic, _key.tonicPitchClass, _scaleType!);
}
