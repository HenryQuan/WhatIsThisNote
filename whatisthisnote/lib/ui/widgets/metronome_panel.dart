import 'package:flutter/material.dart';

import '../../core/metronome.dart';
import '../../core/scale.dart';

/// The Metronome tab: a tempo click, plus a register finder that plays a chosen
/// pitch or sweeps C1 to C8 so the learner can feel where each octave sits.
class MetronomePanel extends StatelessWidget {
  const MetronomePanel({
    super.key,
    required this.bpm,
    required this.onBpmChanged,
    required this.playing,
    required this.beat,
    required this.beatsPerBar,
    required this.onToggle,
    required this.pitchClass,
    required this.onPitchClassChanged,
    required this.zone,
    required this.onZoneChanged,
    required this.looping,
    required this.sweeping,
    required this.onPlayNote,
    required this.onToggleLoop,
    required this.onSweep,
    required this.scale,
    required this.keySelector,
    required this.scaleSelector,
  });

  final int bpm;
  final ValueChanged<int> onBpmChanged;
  final bool playing;

  /// Index of the beat currently sounding, within a bar.
  final int beat;
  final int beatsPerBar;
  final VoidCallback onToggle;

  /// The register finder's selected pitch (0 == C) and octave.
  final int pitchClass;
  final ValueChanged<int> onPitchClassChanged;
  final int zone;
  final ValueChanged<int> onZoneChanged;

  final bool looping;
  final bool sweeping;
  final VoidCallback onPlayNote;
  final VoidCallback onToggleLoop;
  final VoidCallback onSweep;

  /// The scale used to label the selected pitch with its degree, if any.
  final Scale? scale;

  /// Selectors built by the page so this tab matches the Note tab exactly.
  final Widget keySelector;
  final Widget scaleSelector;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MetronomeClick(
                bpm: bpm,
                onBpmChanged: onBpmChanged,
                playing: playing,
                beat: beat,
                beatsPerBar: beatsPerBar,
                onToggle: onToggle,
              ),
              const SizedBox(height: 16),
              _RegisterFinder(
                pitchClass: pitchClass,
                onPitchClassChanged: onPitchClassChanged,
                zone: zone,
                onZoneChanged: onZoneChanged,
                looping: looping,
                sweeping: sweeping,
                onPlayNote: onPlayNote,
                onToggleLoop: onToggleLoop,
                onSweep: onSweep,
                scale: scale,
                keySelector: keySelector,
                scaleSelector: scaleSelector,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetronomeClick extends StatelessWidget {
  const _MetronomeClick({
    required this.bpm,
    required this.onBpmChanged,
    required this.playing,
    required this.beat,
    required this.beatsPerBar,
    required this.onToggle,
  });

  final int bpm;
  final ValueChanged<int> onBpmChanged;
  final bool playing;
  final int beat;
  final int beatsPerBar;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _SectionCard(
      icon: Icons.av_timer,
      title: 'Metronome',
      trailing: FilledButton.tonalIcon(
        key: const Key('metronome-toggle'),
        onPressed: onToggle,
        icon: Icon(playing ? Icons.stop : Icons.play_arrow),
        label: Text(playing ? 'Stop' : 'Start'),
      ),
      children: [
        Row(
          children: [
            IconButton.filledTonal(
              key: const Key('bpm-down'),
              tooltip: 'Slower',
              onPressed: bpm > kMinBpm ? () => onBpmChanged(bpm - 1) : null,
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$bpm',
                    key: const Key('bpm-value'),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'beats per minute',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              key: const Key('bpm-up'),
              tooltip: 'Faster',
              onPressed: bpm < kMaxBpm ? () => onBpmChanged(bpm + 1) : null,
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < beatsPerBar; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: AnimatedContainer(
                  key: Key('metronome-beat-$i'),
                  duration: const Duration(milliseconds: 90),
                  width: 16,
                  height: 16,
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
        const SizedBox(height: 4),
        Text(
          '4/4 · the first beat is accented',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

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
    required this.scale,
    required this.keySelector,
    required this.scaleSelector,
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
  final Scale? scale;
  final Widget keySelector;
  final Widget scaleSelector;

  String? _degreeLabel(int pitchClass) {
    final current = scale;
    if (current == null) return null;
    return current.degreeLabelFor(midiForPitchClass(pitchClass, zone));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final frequency = frequencyForPitchClass(pitchClass, zone);
    final degree = _degreeLabel(pitchClass);

    return _SectionCard(
      icon: Icons.hearing,
      title: 'Register finder',
      children: [
        Row(
          children: [
            Expanded(child: keySelector),
            const SizedBox(width: 8),
            Expanded(child: scaleSelector),
          ],
        ),
        const SizedBox(height: 16),
        _FieldLabel('Note'),
        const SizedBox(height: 6),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, pc) {
              final label = _degreeLabel(pc);
              return ChoiceChip(
                key: Key('register-note-$pc'),
                selected: pc == pitchClass,
                onSelected: (_) => onPitchClassChanged(pc),
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(pitchClassName(pc)),
                    if (label != null)
                      Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _FieldLabel('Zone'),
        const SizedBox(height: 6),
        SizedBox(
          height: 44,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kMaxZone - kMinZone + 1,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final value = kMinZone + index;
              return ChoiceChip(
                key: Key('register-zone-$value'),
                selected: value == zone,
                onSelected: (_) => onZoneChanged(value),
                label: Text('$value'),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                key: const Key('register-play'),
                onPressed: onPlayNote,
                icon: const Icon(Icons.volume_up),
                label: const Text('Play note'),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              key: const Key('register-loop'),
              tooltip: looping ? 'Stop the loop' : 'Hold this note',
              isSelected: looping,
              onPressed: onToggleLoop,
              icon: const Icon(Icons.loop),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              key: const Key('register-sweep'),
              tooltip: sweeping ? 'Stop the sweep' : 'Sweep C1 to C8',
              isSelected: sweeping,
              onPressed: onSweep,
              icon: const Icon(Icons.swap_vert),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${pitchClassName(pitchClass)}$zone · ${frequency.toStringAsFixed(1)} Hz'
          '${degree == null ? '' : ' · degree $degree'}',
          key: const Key('register-readout'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Loop holds the note steady; the sweep walks C1 to C8 so you can '
          'hear each zone in turn.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

/// A titled card with a leading icon, used for each section of the tab.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}
