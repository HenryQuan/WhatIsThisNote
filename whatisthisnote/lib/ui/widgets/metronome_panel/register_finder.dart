part of '../metronome_panel.dart';

class _RegisterFinder extends StatelessWidget {
  const _RegisterFinder({
    required this.pitchClass,
    required this.onPitchClassChanged,
    required this.zone,
    required this.onZoneChanged,
    required this.looping,
    required this.sweeping,
    required this.onPlayNote,
    required this.onToggleLoop,
    required this.onSweep,
  });

  final int pitchClass;
  final ValueChanged<int> onPitchClassChanged;
  final int zone;
  final ValueChanged<int> onZoneChanged;
  final bool looping;
  final bool sweeping;
  final VoidCallback onPlayNote;
  final VoidCallback onToggleLoop;
  final VoidCallback onSweep;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final frequency = frequencyForPitchClass(pitchClass, zone);

    return _SectionCard(
      icon: Icons.hearing,
      title: l10n.registerFinder,
      children: [
        _FieldLabel(l10n.registerNote),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (var pc = 0; pc < 12; pc++)
              ChoiceChip(
                key: Key('register-note-$pc'),
                selected: pc == pitchClass,
                onSelected: (_) => onPitchClassChanged(pc),
                label: Text(pitchClassName(pc)),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _FieldLabel(l10n.registerZone),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (var value = kMinZone; value <= kMaxZone; value++)
              ChoiceChip(
                key: Key('register-zone-$value'),
                selected: value == zone,
                onSelected: (_) => onZoneChanged(value),
                label: Text('$value'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                key: const Key('register-play'),
                onPressed: onPlayNote,
                icon: const Icon(Icons.volume_up),
                label: Text(l10n.playNote),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              key: const Key('register-loop'),
              tooltip: looping ? l10n.stopLoop : l10n.holdThisNote,
              isSelected: looping,
              onPressed: onToggleLoop,
              icon: const Icon(Icons.loop),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              key: const Key('register-sweep'),
              tooltip: sweeping
                  ? l10n.stopSweep
                  : l10n.sweepRange(
                      '${pitchClassName(pitchClass)}$kMinZone',
                      '${pitchClassName(pitchClass)}$kMaxZone',
                    ),
              isSelected: sweeping,
              onPressed: onSweep,
              icon: const Icon(Icons.swap_vert),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.registerReadout(
            '${pitchClassName(pitchClass)}$zone',
            frequency.toStringAsFixed(1),
          ),
          key: const Key('register-readout'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          l10n.registerHint(
            '${pitchClassName(pitchClass)}$kMinZone',
            '${pitchClassName(pitchClass)}$kMaxZone',
          ),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}


