part of '../home_page.dart';

class _KeySelector extends StatelessWidget {
  const _KeySelector({required this.value, required this.onChanged});

  final MusicalKey value;
  final ValueChanged<MusicalKey> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return PopupMenuButton<MusicalKey>(
      tooltip: l10n.keySignature,
      onSelected: onChanged,
      itemBuilder: (context) => [
        PopupMenuItem<MusicalKey>(
          enabled: false,
          height: 34,
          child: SectionHeading(title: l10n.major),
        ),
        for (final key in kMajorKeys)
          PopupMenuItem<MusicalKey>(
            value: key,
            height: 64,
            child: _KeyMenuEntry(musicalKey: key),
          ),
        const PopupMenuDivider(),
        PopupMenuItem<MusicalKey>(
          enabled: false,
          height: 34,
          child: SectionHeading(title: l10n.minor),
        ),
        for (final key in kMinorKeys)
          PopupMenuItem<MusicalKey>(
            value: key,
            height: 64,
            child: _KeyMenuEntry(musicalKey: key),
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
            const Icon(Icons.piano, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      l10n.keyMenuLabel(l10n.keyName(value)),
                      key: const Key('key-label'),
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      l10n.keySignatureLabel(value),
                      textAlign: TextAlign.right,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _ScaleSelector extends StatelessWidget {
  const _ScaleSelector({required this.value, required this.onChanged});

  final ScaleType? value;
  final ValueChanged<ScaleType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final scaleType = value;
    return PopupMenuButton<_ScaleOption>(
      tooltip: l10n.scaleHighlight,
      onSelected: (option) => onChanged(option.type),
      itemBuilder: (context) => [
        PopupMenuItem<_ScaleOption>(
          value: const _ScaleOption(null),
          child: Text(l10n.off),
        ),
        const PopupMenuDivider(),
        for (final type in ScaleType.values)
          PopupMenuItem<_ScaleOption>(
            value: _ScaleOption(type),
            child: Text(l10n.scaleTypeName(type)),
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
            const Icon(Icons.highlight, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.highlightLabel(
                  scaleType == null ? l10n.off : l10n.scaleTypeName(scaleType),
                ),
                key: const Key('scale-label'),
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

class _ScaleOption {
  const _ScaleOption(this.type);

  final ScaleType? type;
}
