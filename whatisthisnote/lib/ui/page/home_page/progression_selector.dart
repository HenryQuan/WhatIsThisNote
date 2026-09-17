part of '../home_page.dart';

class _ProgressionSelector extends StatelessWidget {
  const _ProgressionSelector({required this.value, required this.onChanged});

  final ChordProgression? value;
  final ValueChanged<ChordProgression?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final progression = value;
    return PopupMenuButton<_ProgressionOption>(
      tooltip: l10n.progressionTitle,
      onSelected: (option) => onChanged(option.value),
      itemBuilder: (context) => [
        PopupMenuItem<_ProgressionOption>(
          value: const _ProgressionOption(null),
          child: Text(l10n.off),
        ),
        const PopupMenuDivider(),
        for (final progression in kProgressions)
          PopupMenuItem<_ProgressionOption>(
            value: _ProgressionOption(progression),
            child: Text(l10n.progressionName(progression)),
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
            const Icon(Icons.queue_music, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.progressionLabel(
                  progression == null
                      ? l10n.off
                      : l10n.progressionName(progression),
                ),
                key: const Key('progression-label'),
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

class _ProgressionOption {
  const _ProgressionOption(this.value);

  final ChordProgression? value;
}

class _ProgressionChips extends StatelessWidget {
  const _ProgressionChips({
    required this.progression,
    required this.scale,
    required this.extension,
    required this.onSelected,
    this.alignment = MainAxisAlignment.start,
    this.wrap = false,
    this.activeIndex,
  });

  final ChordProgression progression;
  final Scale scale;
  final ChordExtension extension;
  final ValueChanged<int> onSelected;

  /// How the chips are aligned when they do not fill the row.
  final MainAxisAlignment alignment;

  /// Whether the chips flow onto multiple lines instead of scrolling
  /// horizontally. Used in the narrow controls rail so no chip is ever cut
  /// off at the edge.
  final bool wrap;

  /// The index of the chip whose chord is currently sounding, so it can be
  /// emphasised while the progression plays.
  final int? activeIndex;

  List<Widget> _buildChips(
    ChordProgression progression, {
    required bool keyed,
    required ColorScheme scheme,
  }) => [
    for (var i = 0; i < progression.degrees.length; i++)
      ActionChip(
        key: keyed ? Key('prog-$i') : null,
        visualDensity: VisualDensity.compact,
        backgroundColor: keyed && i == activeIndex
            ? scheme.secondaryContainer
            : null,
        label: Text(
          Chord.diatonic(
            scale,
            progression.degrees[i],
            extension: extension,
          ).romanNumeral,
          // Only the colour changes, never the weight, so the active chip
          // keeps its width and the row never reflows while playing.
          style: keyed && i == activeIndex
              ? TextStyle(color: scheme.onSecondaryContainer)
              : null,
        ),
        onPressed: () => onSelected(progression.degrees[i]),
      ),
  ];

  Wrap _wrapChips(List<Widget> chips) => Wrap(
    spacing: 8,
    runSpacing: 8,
    alignment: alignment == MainAxisAlignment.end
        ? WrapAlignment.end
        : WrapAlignment.start,
    children: chips,
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final chips = _buildChips(progression, keyed: true, scheme: scheme);
    if (wrap) {
      // Reserve the height needed by the longest built-in progression so the
      // rail does not resize (and the panel does not jump) when switching
      // between progressions with different numbers of chips.
      final longest = kProgressions.reduce(
        (a, b) => a.degrees.length >= b.degrees.length ? a : b,
      );
      return Stack(
        children: [
          if (longest != progression)
            ExcludeFocus(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Opacity(
                    opacity: 0,
                    child: _wrapChips(
                      _buildChips(longest, keyed: false, scheme: scheme),
                    ),
                  ),
                ),
              ),
            ),
          KeyedSubtree(
            key: const Key('progression-chips'),
            child: _wrapChips(chips),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: const Key('progression-chips'),
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: constraints.maxWidth),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: alignment,
            children: [
              for (var i = 0; i < chips.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                chips[i],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
