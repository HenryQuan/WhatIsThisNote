part of '../home_page.dart';

extension _HomeChordLab on _HomePageState {
  /// Selects a specific chord for the current root, or clears the override when
  /// the diatonic chord is wanted again.
  void _selectChordQuality(ChordQuality quality) {
    _stopSequence();
    _update(() {
      _chordQuality = quality;
      _inversion = 0;
    });
  }

  void _setChordMode(ChordMode mode) {
    if (_playback != null) _stopSequence();
    _update(() {
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
    final scale = ChordService.scaleForChords(_key, _selectedScale);
    final note = _key.applyTo(_clef.noteAt(_step));
    var delta = (degree - ChordService.degreeOf(note, scale)) % 7;
    if (delta > 3) delta -= 7;
    _setStep(_step + delta);
  }
}
