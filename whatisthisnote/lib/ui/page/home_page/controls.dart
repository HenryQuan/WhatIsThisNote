part of '../home_page.dart';

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
    final l10n = context.l10n;
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
      NamingSystem.solfege => l10n.solfegeFor(note),
      NamingSystem.jianpu => keySignature.jianpuFor(note),
    };
    final secondaryNames = <(Key, String)>[
      if (display.naming != NamingSystem.scientific)
        (const Key('note-pitch'), note.name),
      if (display.naming != NamingSystem.solfege)
        (const Key('note-solfege'), l10n.solfegeFor(note)),
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
          ButtonSegment<Clef>(value: value, label: Text(l10n.clefLabel(value))),
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
          tooltip: l10n.playScale,
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
          tooltip: l10n.playProgression,
        ),
      ],
    );

    return _buildControlsBody(
      context: context,
      theme: theme,
      l10n: l10n,
      note: note,
      scaleDegree: scaleDegree,
      inScale: inScale,
      badgeColor: badgeColor,
      badgeTextColor: badgeTextColor,
      badgeLabel: badgeLabel,
      primaryName: primaryName,
      secondaryNames: secondaryNames,
      enharmonic: enharmonic,
      wide: wide,
      clefSelector: clefSelector,
      keySelector: keySelector,
      scaleRow: scaleRow,
      chordSelector: chordSelector,
      inversionSelector: inversionSelector,
      progressionRow: progressionRow,
    );
  }
}
