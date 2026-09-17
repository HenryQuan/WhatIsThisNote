part of '../home_page.dart';

class _AccidentalReserve extends StatelessWidget {
  const _AccidentalReserve({super.key, required this.style});

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Text(
        '\u266F',
        maxLines: 1,
        style: (style ?? const TextStyle()).copyWith(
          color: const Color(0x00000000),
        ),
      ),
    );
  }
}

/// A small play/stop button shown beside the highlight and progression
/// selectors; it runs that sequence, or stops it while it is playing.
class _SequenceButton extends StatelessWidget {
  const _SequenceButton({
    super.key,
    required this.playing,
    required this.onPressed,
    required this.tooltip,
  });

  final bool playing;
  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      isSelected: playing,
      visualDensity: VisualDensity.compact,
      iconSize: 20,
      icon: Icon(playing ? Icons.stop : Icons.play_arrow),
      tooltip: playing ? context.l10n.stop : tooltip,
    );
  }
}
