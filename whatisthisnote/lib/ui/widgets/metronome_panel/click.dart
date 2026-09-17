part of '../metronome_panel.dart';

class _MetronomeClick extends StatelessWidget {
  const _MetronomeClick({
    required this.bpm,
    required this.onBpmChanged,
    required this.onBeatsPerBarChanged,
    required this.playing,
    required this.beat,
    required this.beatsPerBar,
    required this.onToggle,
  });

  final int bpm;
  final ValueChanged<int> onBpmChanged;
  final ValueChanged<int> onBeatsPerBarChanged;
  final bool playing;
  final ValueListenable<int> beat;
  final int beatsPerBar;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return _SectionCard(
      icon: Icons.av_timer,
      title: l10n.metronomeTitle,
      trailing: FilledButton.tonalIcon(
        key: const Key('metronome-toggle'),
        onPressed: onToggle,
        icon: Icon(playing ? Icons.stop : Icons.play_arrow),
        label: Text(playing ? l10n.stop : l10n.start),
      ),
      children: [
        Center(
          child: Column(
            children: [
              Text(
                '$bpm',
                key: const Key('bpm-value'),
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                l10n.beatsPerMinute(l10n.tempoLabel(bpm)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          key: const Key('bpm-slider'),
          value: bpm.toDouble(),
          min: kMinBpm.toDouble(),
          max: kMaxBpm.toDouble(),
          onChanged: (value) => onBpmChanged(value.round()),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$kMinBpm', style: theme.textTheme.labelSmall),
            Text('$kMaxBpm', style: theme.textTheme.labelSmall),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TempoStep(
              key: const Key('bpm-down-10'),
              tooltip: l10n.tenSlower,
              icon: Icons.replay_10,
              onPressed: bpm > kMinBpm ? () => onBpmChanged(bpm - 10) : null,
            ),
            _TempoStep(
              key: const Key('bpm-down'),
              tooltip: l10n.slower,
              icon: Icons.remove,
              onPressed: bpm > kMinBpm ? () => onBpmChanged(bpm - 1) : null,
            ),
            const SizedBox(width: 16),
            _TempoStep(
              key: const Key('bpm-up'),
              tooltip: l10n.faster,
              icon: Icons.add,
              onPressed: bpm < kMaxBpm ? () => onBpmChanged(bpm + 1) : null,
            ),
            _TempoStep(
              key: const Key('bpm-up-10'),
              tooltip: l10n.tenFaster,
              icon: Icons.forward_10,
              onPressed: bpm < kMaxBpm ? () => onBpmChanged(bpm + 10) : null,
            ),
          ],
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<int>(
          valueListenable: beat,
          builder: (context, beat, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < beatsPerBar; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: AnimatedContainer(
                    key: Key('metronome-beat-$i'),
                    duration: const Duration(milliseconds: 90),
                    width: i == 0 ? 20 : 16,
                    height: i == 0 ? 20 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: playing && beat == i
                          ? theme.colorScheme.primary
                          : theme.colorScheme.surfaceContainerHighest,
                      border: Border.all(
                        color: i == 0
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant,
                        width: i == 0 ? 2 : 1,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _FieldLabel(l10n.timeSignature),
        const SizedBox(height: 6),
        SegmentedButton<int>(
          key: const Key('beats-per-bar'),
          showSelectedIcon: false,
          segments: [
            for (final beats in kBeatCounts)
              ButtonSegment(value: beats, label: Text('$beats/4')),
          ],
          selected: {beatsPerBar},
          onSelectionChanged: (selection) =>
              onBeatsPerBarChanged(selection.first),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.firstBeatAccented,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}


