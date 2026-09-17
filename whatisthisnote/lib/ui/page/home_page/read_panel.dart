part of '../home_page.dart';

class _ReadPanel extends StatelessWidget {
  const _ReadPanel({
    super.key,
    required this.melody,
    required this.index,
    required this.mistake,
    required this.done,
    required this.clef,
    required this.keySignature,
    required this.onTapPitchClass,
    required this.onPlay,
    required this.onNext,
    required this.onExit,
  });

  final Melody melody;

  /// Index of the phrase note the learner is reading.
  final int index;

  /// True after a key that was not the next note was tapped.
  final bool mistake;

  /// True once every note has been played.
  final bool done;

  final Clef clef;
  final MusicalKey keySignature;
  final ValueChanged<int> onTapPitchClass;
  final VoidCallback onPlay;
  final VoidCallback onNext;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final note = keySignature.applyTo(clef.noteAt(melody.steps[index]));

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(Icons.piano, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.readTitle,
                      key: const Key('read-title'),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    '${index + 1} / ${melody.length}',
                    key: const Key('read-progress'),
                    style: theme.textTheme.titleSmall,
                  ),
                  IconButton(
                    key: const Key('read-exit'),
                    tooltip: l10n.readExit,
                    icon: const Icon(Icons.close),
                    onPressed: onExit,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                done
                    ? l10n.readPhraseComplete
                    : mistake
                    ? l10n.readTryAgain
                    : l10n.readPrompt,
                key: const Key('read-prompt'),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: mistake ? scheme.error : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.readHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: const Key('read-play'),
                      onPressed: onPlay,
                      icon: const Icon(Icons.volume_up),
                      label: Text(l10n.hearPhrase),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: const Key('read-next'),
                      onPressed: onNext,
                      icon: const Icon(Icons.refresh),
                      label: Text(done ? l10n.newPhrase : l10n.skip),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              PianoKeyboard(
                key: const Key('read-keyboard'),
                midi: note.midi,
                height: 92,
                showHighlight: false,
                onPitchClassTap: onTapPitchClass,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reserves the width of one accidental glyph in the note readout so that a
/// sharp or flat appearing mid-drag never reflows the panel. The glyph itself
/// is fully transparent and hidden from assistive tech.
