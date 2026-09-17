part of '../home_page.dart';

extension _HomeMetronome on _HomePageState {
  /// Starts or stops the metronome click. Register playback is stopped first so
  /// the two never fight over the single audio player.
  void _toggleMetronome() {
    if (_metronomeOn) {
      _stopMetronome();
      return;
    }
    _stopRegister();
    _stopSequence();
    _update(() => _metronomeOn = true);
    _restartClick();
  }

  /// Starts the looping click and re-anchors the beat dots to it. The whole
  /// bar is rendered and looped by the audio backend, so the click stays even
  /// and the dots only have to follow it.
  void _restartClick() {
    if (!_metronomeOn) return;
    _bpmRestartTimer?.cancel();
    _bpmRestartTimer = null;
    unawaited(
      _notePlayer.startClickTrack([
        _clickAccentHz,
        ...List.filled(_beatsPerBar - 1, _clickBeatHz),
      ], beatInterval(_bpm)),
    );
    _lastBeatAt = null;
    _beat.value = _beatsPerBar - 1;
    _advanceBeat();
  }

  /// Advances the beat dots. The click itself comes from the looping track, so
  /// this only keeps the on-screen pulse lined up with it.
  void _advanceBeat() {
    if (!_metronomeOn) return;
    _lastBeatAt = DateTime.now();
    _beat.value = (_beat.value + 1) % _beatsPerBar;
    _scheduleNextBeat();
  }

  /// Queues the next beat on the timeline anchored at [_lastBeatAt], so the
  /// gap is measured from when the beat sounded rather than from when its
  /// callback finished. If a long frame made us fall behind the timeline, the
  /// anchor is reset instead of firing a burst of catch-up updates.
  void _scheduleNextBeat() {
    _metronomeTimer?.cancel();
    final interval = beatInterval(_bpm);
    final base = _lastBeatAt;
    var delay = base == null
        ? interval
        : base.add(interval).difference(DateTime.now());
    if (delay.isNegative) {
      _lastBeatAt = DateTime.now();
      delay = interval;
    }
    _metronomeTimer = Timer(delay, _advanceBeat);
  }

  void _stopMetronome() {
    final wasOn = _metronomeOn;
    _metronomeTimer?.cancel();
    _metronomeTimer = null;
    _bpmRestartTimer?.cancel();
    _bpmRestartTimer = null;
    if (wasOn || _beat.value != 0) {
      _metronomeOn = false;
      _beat.value = 0;
      _update(() {});
    }
    // Only touch the player when a click could be sounding; this must not pull
    // an audio plugin into existence just because the user changed tabs.
    if (wasOn) unawaited(_notePlayer.stopClickTrack());
  }

  void _setBpm(int bpm) {
    final clamped = bpm.clamp(kMinBpm, kMaxBpm);
    if (clamped == _bpm) return;
    _update(() => _bpm = clamped);
    if (!_metronomeOn) return;
    // Restarting the loop on every drag step would stutter the click, so the
    // new tempo is applied once the user pauses.
    _bpmRestartTimer?.cancel();
    _bpmRestartTimer = Timer(const Duration(milliseconds: 150), _restartClick);
  }

  void _setBeatsPerBar(int beats) {
    if (beats == _beatsPerBar) return;
    _update(() => _beatsPerBar = beats);
    // The bar is baked into the click track, so it has to be re-rendered.
    if (_metronomeOn) _restartClick();
  }

  /// Plays the register finder's current note once.
  void _playRegisterNote() {
    _stopSequence();
    _stopRegister();
    unawaited(
      _notePlayer.play([
        frequencyForPitchClass(_registerPitchClass, _registerZone),
      ]),
    );
  }

  /// Holds the register note, sounding it over and over until stopped.
  void _toggleRegisterLoop() {
    if (_registerLooping) {
      _stopRegister();
      return;
    }
    _stopMetronome();
    _stopSequence();
    _stopRegister();
    final token = ++_registerToken;
    _update(() {
      _registerLooping = true;
      _registerSweeping = false;
    });
    _loopRegister(token);
  }

  void _loopRegister(int token) {
    if (token != _registerToken) return;
    // A tone slightly shorter than the gap ends on its own release instead of
    // being cut off by the next one, which would click.
    unawaited(
      _notePlayer.play([
        frequencyForPitchClass(_registerPitchClass, _registerZone),
      ], duration: const Duration(milliseconds: 650)),
    );
    _registerTimer = Timer(
      const Duration(milliseconds: 700),
      () => _loopRegister(token),
    );
  }

  /// Walks the selected note across every zone, moving the octave selection
  /// with each note so the learner hears the same pitch in each register.
  void _sweepRegister() {
    if (_registerSweeping) {
      _stopRegister();
      return;
    }
    _stopMetronome();
    _stopSequence();
    _stopRegister();
    final token = ++_registerToken;
    _update(() => _registerSweeping = true);
    _sweepStep(token, kMinZone);
  }

  void _sweepStep(int token, int zone) {
    if (token != _registerToken) return;
    _update(() => _registerZone = zone);
    // Shorter than the 500 ms step so each note finishes before the next.
    unawaited(
      _notePlayer.play([
        frequencyForPitchClass(_registerPitchClass, zone),
      ], duration: const Duration(milliseconds: 450)),
    );
    final done = zone >= kMaxZone;
    _registerTimer = Timer(const Duration(milliseconds: 500), () {
      if (token != _registerToken) return;
      if (done) {
        _stopRegister();
      } else {
        _sweepStep(token, zone + 1);
      }
    });
  }

  void _stopRegister() {
    _registerTimer?.cancel();
    _registerTimer = null;
    _registerToken++;
    if (_registerLooping || _registerSweeping) {
      _update(() {
        _registerLooping = false;
        _registerSweeping = false;
      });
    }
  }
}
