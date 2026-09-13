import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/metronome.dart';

/// The Metronome tab: a tempo click, plus a register finder that plays a chosen
/// pitch or sweeps that same pitch across every zone so the learner can feel
/// where each octave sits.
class MetronomePanel extends StatelessWidget {
  const MetronomePanel({
    super.key,
    required this.bpm,
    required this.onBpmChanged,
    required this.onBeatsPerBarChanged,
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
  });

  final int bpm;
  final ValueChanged<int> onBpmChanged;
  final ValueChanged<int> onBeatsPerBarChanged;
  final bool playing;

  /// Index of the beat currently sounding, within a bar.
  final ValueListenable<int> beat;
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

  @override
  Widget build(BuildContext context) {
    final click = _MetronomeClick(
      bpm: bpm,
      onBpmChanged: onBpmChanged,
      onBeatsPerBarChanged: onBeatsPerBarChanged,
      playing: playing,
      beat: beat,
      beatsPerBar: beatsPerBar,
      onToggle: onToggle,
    );
    final finder = _RegisterFinder(
      pitchClass: pitchClass,
      onPitchClassChanged: onPitchClassChanged,
      zone: zone,
      onZoneChanged: onZoneChanged,
      looping: looping,
      sweeping: sweeping,
      onPlayNote: onPlayNote,
      onToggleLoop: onToggleLoop,
      onSweep: onSweep,
    );
    // On a wide window the two cards sit side by side so neither has to be
    // scrolled to; on a narrow one they stack into a single column.
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 720;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: click),
                        const SizedBox(width: 16),
                        Expanded(child: finder),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [click, const SizedBox(height: 16), finder],
                    ),
            ),
          ),
        );
      },
    );
  }
}

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
                '${tempoName(bpm)} · beats per minute',
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
              tooltip: '10 slower',
              icon: Icons.replay_10,
              onPressed: bpm > kMinBpm ? () => onBpmChanged(bpm - 10) : null,
            ),
            _TempoStep(
              key: const Key('bpm-down'),
              tooltip: 'Slower',
              icon: Icons.remove,
              onPressed: bpm > kMinBpm ? () => onBpmChanged(bpm - 1) : null,
            ),
            const SizedBox(width: 16),
            _TempoStep(
              key: const Key('bpm-up'),
              tooltip: 'Faster',
              icon: Icons.add,
              onPressed: bpm < kMaxBpm ? () => onBpmChanged(bpm + 1) : null,
            ),
            _TempoStep(
              key: const Key('bpm-up-10'),
              tooltip: '10 faster',
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
        _FieldLabel('Time signature'),
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
          'The first beat of each bar is accented.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// A round tempo nudge button that keeps its width no matter which icon it
/// shows, so the row does not jump when a limit disables one of them.
class _TempoStep extends StatelessWidget {
  const _TempoStep({
    super.key,
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: IconButton.filledTonal(
        tooltip: tooltip,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
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
    final frequency = frequencyForPitchClass(pitchClass, zone);

    return _SectionCard(
      icon: Icons.hearing,
      title: 'Register finder',
      children: [
        _FieldLabel('Note'),
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
        _FieldLabel('Zone'),
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
              tooltip: sweeping
                  ? 'Stop the sweep'
                  : 'Sweep ${pitchClassName(pitchClass)}$kMinZone to '
                        '${pitchClassName(pitchClass)}$kMaxZone',
              isSelected: sweeping,
              onPressed: onSweep,
              icon: const Icon(Icons.swap_vert),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '${pitchClassName(pitchClass)}$zone · ${frequency.toStringAsFixed(1)} Hz',
          key: const Key('register-readout'),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          'Loop holds the note steady; the sweep walks '
          '${pitchClassName(pitchClass)}$kMinZone to '
          '${pitchClassName(pitchClass)}$kMaxZone so you can hear the same '
          'note in each zone.',
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
