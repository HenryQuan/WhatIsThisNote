import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/metronome.dart';
import '../../l10n/l10n.dart';

part 'metronome_panel/click.dart';
part 'metronome_panel/register_finder.dart';
part 'metronome_panel/common_widgets.dart';
part 'metronome_panel/section_card.dart';

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
