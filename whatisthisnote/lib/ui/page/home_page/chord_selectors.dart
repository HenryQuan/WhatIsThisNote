part of '../home_page.dart';

class _ChordSelector extends StatelessWidget {
  const _ChordSelector({required this.value, required this.onChanged});

  final ChordMode value;
  final ValueChanged<ChordMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return PopupMenuButton<ChordMode>(
      tooltip: l10n.chordsTitle,
      initialValue: value,
      onSelected: onChanged,
      itemBuilder: (context) => [
        for (final mode in ChordMode.values)
          PopupMenuItem<ChordMode>(
            value: mode,
            child: Text(l10n.chordModeName(mode)),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.multitrack_audio, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.chordsLabel(l10n.chordModeName(value)),
                key: const Key('chord-label'),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _InversionSelector extends StatelessWidget {
  const _InversionSelector({
    required this.value,
    required this.count,
    required this.onChanged,
  });

  final int value;
  final int count;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SegmentedButton<int>(
      showSelectedIcon: false,
      segments: [
        for (var i = 0; i < count; i++)
          ButtonSegment<int>(
            value: i,
            label: Text(l10n.inversionShortLabel(i)),
          ),
      ],
      selected: {value.clamp(0, count - 1)},
      onSelectionChanged: (selection) => onChanged(selection.first),
    );
  }
}
