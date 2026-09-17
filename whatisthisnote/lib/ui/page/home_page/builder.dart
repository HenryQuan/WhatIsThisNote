part of '../home_page.dart';

extension _HomeBuilder on _HomePageState {
  /// Adds a note at [step] to the custom chord and selects it, so a new note is
  /// also the suggested root.
  void _addBuilderNote(int step) {
    if (_builderNotes.length >= _maxBuilderNotes) return;
    final note = _key.applyTo(_clef.noteAt(step));
    _update(() {
      _builderNotes.add(note);
      _builderSelected = _builderNotes.length - 1;
      _builderMatch = null;
    });
  }

  /// Adds the next note a third above the top of the stack, for a precise way
  /// in without tapping the staff. An empty builder starts on the middle line
  /// (B4), so the first taps stack up as D, F, A.
  void _addBuilderNoteAbove() {
    if (_builderNotes.isEmpty) {
      _addBuilderNote(6);
      return;
    }
    var topStep = _clef.stepOf(_builderNotes.first);
    for (final note in _builderNotes) {
      final step = _clef.stepOf(note);
      if (step > topStep) topStep = step;
    }
    _addBuilderNote(topStep + 2);
  }

  /// Adds the next note a third below the bottom of the stack, so a chord can
  /// be built downward without tapping a precise staff row.
  void _addBuilderNoteBelow() {
    var bottomStep = 4;
    if (_builderNotes.isNotEmpty) {
      bottomStep = _clef.stepOf(_builderNotes.first);
      for (final note in _builderNotes) {
        final step = _clef.stepOf(note);
        if (step < bottomStep) bottomStep = step;
      }
    }
    _addBuilderNote(bottomStep - 2);
  }

  /// Nudges the selected note by [delta] staff steps, a tap-only alternative
  /// to dragging on a small screen.
  void _nudgeBuilderNote(int delta) {
    final index = _builderSelected;
    if (index == null || index >= _builderNotes.length) return;
    _moveBuilderNote(index, _clef.stepOf(_builderNotes[index]) + delta);
  }

  void _moveBuilderNote(int index, int step) {
    if (index < 0 || index >= _builderNotes.length) return;
    final note = _builderNotes[index];
    _update(() {
      _builderNotes[index] = Note(
        _clef.bottomLine.diatonicIndex + step,
        note.accidental,
      );
      _builderMatch = null;
    });
  }

  void _setBuilderAccidental(int index, Accidental accidental) {
    if (index < 0 || index >= _builderNotes.length) return;
    _update(() {
      _builderNotes[index] = _builderNotes[index].withAccidental(accidental);
      _builderMatch = null;
    });
  }

  void _removeBuilderNote(int index) {
    if (index < 0 || index >= _builderNotes.length) return;
    _update(() {
      _builderNotes.removeAt(index);
      _builderMatch = null;
      final selected = _builderSelected;
      if (_builderNotes.isEmpty) {
        _builderSelected = null;
      } else if (selected != null) {
        if (selected > index) _builderSelected = selected - 1;
        if (_builderSelected! >= _builderNotes.length) {
          _builderSelected = _builderNotes.length - 1;
        }
      }
    });
  }

  /// Every chord the built notes could spell across all twelve roots, with the
  /// lowest note on the staff (the bass) as the suggested root, so a
  /// symmetrical shape is named in root position first.
  List<ChordMatch> _builderMatches() {
    return findChordMatches([
      for (final note in _builderNotes) note.midi % 12,
    ], preferredRoot: _builderBassPitchClass());
  }

  /// Pitch class of the lowest note on the chord staff, or `null` when empty.
  int? _builderBassPitchClass() {
    if (_builderNotes.isEmpty) return null;
    var lowest = _builderNotes.first;
    for (final note in _builderNotes) {
      if (note.midi < lowest.midi) lowest = note;
    }
    return lowest.midi % 12;
  }

  /// Clears every note from the custom chord builder.
  void _clearBuilderNotes() {
    if (_builderNotes.isEmpty) return;
    _update(() {
      _builderNotes.clear();
      _builderSelected = null;
      _builderMatch = null;
    });
  }

  /// Spells a root pitch class, preferring a note the learner placed and
  /// falling back to a sharp spelling.
  Note _builderRootNote(int pitchClass) {
    for (final note in _builderNotes) {
      if (note.midi % 12 == pitchClass) return note;
    }
    for (final letter in NoteLetter.values) {
      final difference = ((pitchClass - letter.semitone) % 12 + 12) % 12;
      if (difference == 0) return Note(letter.index);
      if (difference == 1) return Note(letter.index, Accidental.sharp);
    }
    return Note(NoteLetter.c.index);
  }

  void _playBuilderChord() {
    _stopSequence();
    unawaited(
      _notePlayer.play([for (final note in _builderNotes) note.frequency]),
    );
  }

  void _selectBuilderMatch(ChordMatch match) {
    _update(() {
      _builderMatch =
          _builderMatch == null ||
              _builderMatch!.rootPitchClass != match.rootPitchClass ||
              _builderMatch!.quality != match.quality
          ? match
          : null;
    });
  }

  void _playBuilderMatch(ChordMatch match) {
    _stopSequence();
    final rootMidi = midiForPitchClass(match.rootPitchClass, 4);
    unawaited(
      _notePlayer.play([
        for (final interval in match.quality.intervals)
          frequencyForMidi(rootMidi + interval),
      ]),
    );
  }
}
