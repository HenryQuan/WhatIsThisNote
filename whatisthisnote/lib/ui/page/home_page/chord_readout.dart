part of '../home_page.dart';

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
    final l10n = context.l10n;
    final chord = this.chord;
    final caption = chord == null
        ? l10n.noDiatonicChord
        : chord.diatonic
        ? l10n.diatonicChordCaption(
            chord.romanNumeral,
            l10n.chordQualityName(chord.quality),
            l10n.inversionLabel(chord.inversion),
            l10n.scaleLabel(chordScale),
          )
        : chord.chromatic
        ? l10n.chromaticChordCaption(
            chord.romanNumeral,
            l10n.chordQualityName(chord.quality),
            l10n.inversionLabel(chord.inversion),
          )
        : l10n.chosenChordCaption(
            l10n.chordQualityName(chord.quality),
            l10n.inversionLabel(chord.inversion),
          );
    return Row(
      children: [
        PopupMenuButton<ChordQuality>(
          key: const Key('chord-menu'),
          tooltip: l10n.chooseChord,
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
    final l10n = context.l10n;
    final notes = musicalKey.signatureNotes;
    final signature = l10n.keySignatureLabel(musicalKey);
    final detail = notes.isEmpty ? signature : '$signature \u00B7 $notes';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.keyName(musicalKey)),
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
