part of '../home_page.dart';

extension _ControlsBody on _Controls {
  Widget _buildControlsBody({
    required BuildContext context,
    required ThemeData theme,
    required AppLocalizations l10n,
    required Note note,
    required String? scaleDegree,
    required bool inScale,
    required Color badgeColor,
    required Color badgeTextColor,
    required String badgeLabel,
    required String primaryName,
    required List<(Key, String)> secondaryNames,
    required String? enharmonic,
    required bool wide,
    required Widget clefSelector,
    required Widget keySelector,
    required Widget scaleRow,
    required Widget chordSelector,
    required Widget inversionSelector,
    required Widget progressionRow,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        // On phones the panel gives the staff the larger share and scrolls
        // itself, so the notation never gets squeezed into a thin strip.
        maxHeight: sidebar
            ? double.infinity
            : MediaQuery.sizeOf(context).height * 0.5,
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
                          l10n.clefName(l10n.clefLabel(clef)),
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
                                    ? l10n.jianpuHint
                                    : '${l10n.scaleLabel(scale!)} \u00B7 '
                                          '${inScale ? l10n.scaleDegree(scaleDegree!) : l10n.outsideScale}',
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
                        tooltip: chord == null ? l10n.playNote : l10n.playChord,
                      ),
                      IconButton.filledTonal(
                        onPressed: step < kMaxStaffStep
                            ? () => onStepChanged(step + 1)
                            : null,
                        icon: const Icon(Icons.keyboard_arrow_up),
                        tooltip: l10n.higher,
                      ),
                      IconButton.filledTonal(
                        onPressed: step > kMinStaffStep
                            ? () => onStepChanged(step - 1)
                            : null,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        tooltip: l10n.lower,
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
                        chordLabels: chord?.pitchClassNames,
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
                  chordLabels: chord?.pitchClassNames,
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
