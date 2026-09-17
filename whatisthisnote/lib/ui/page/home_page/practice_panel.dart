part of '../home_page.dart';

class _PracticePanel extends StatelessWidget {
  const _PracticePanel({
    super.key,
    required this.question,
    required this.answered,
    required this.attempts,
    required this.correctAnswers,
    required this.streak,
    required this.bestStreak,
    required this.onAnswer,
    required this.onNext,
    required this.onReset,
    required this.onExit,
  });

  final QuizQuestion question;
  final String? answered;
  final int attempts;
  final int correctAnswers;
  final int streak;
  final int bestStreak;
  final ValueChanged<String> onAnswer;
  final VoidCallback onNext;
  final VoidCallback onReset;
  final VoidCallback onExit;

  bool get _revealed => answered != null;
  bool get _wasCorrect => _revealed && question.isCorrect(answered!);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

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
                  Icon(Icons.quiz, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.practiceTitle,
                      key: const Key('practice-title'),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  if (streak > 0) ...[
                    Icon(
                      Icons.local_fire_department,
                      size: 18,
                      color: scheme.tertiary,
                    ),
                    Text(
                      '$streak',
                      key: const Key('practice-streak'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: scheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Text(
                    '$correctAnswers / $attempts',
                    key: const Key('practice-score'),
                    style: theme.textTheme.titleSmall,
                  ),
                  IconButton(
                    key: const Key('practice-exit'),
                    tooltip: l10n.practiceExit,
                    icon: const Icon(Icons.close),
                    onPressed: onExit,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.practicePrompt,
                key: const Key('practice-prompt'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.practicePromptHint(bestStreak),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: [
                  for (final choice in question.choices)
                    _answerButton(context, choice),
                ],
              ),
              if (_revealed) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _wasCorrect ? Icons.check_circle : Icons.cancel,
                      size: 18,
                      color: _wasCorrect ? scheme.primary : scheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _wasCorrect
                            ? l10n.practiceCorrect(question.answer)
                            : l10n.practiceWrong(question.answer),
                        key: const Key('practice-feedback'),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _wasCorrect ? scheme.primary : scheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('practice-reset'),
                      onPressed: onReset,
                      child: Text(l10n.reset),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      key: const Key('practice-next'),
                      onPressed: _revealed ? onNext : null,
                      child: Text(l10n.nextNote),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _answerButton(BuildContext context, String choice) {
    final scheme = Theme.of(context).colorScheme;
    final isAnswer = choice == question.answer;
    final isPicked = choice == answered;
    Color background;
    Color foreground;
    if (!_revealed) {
      background = scheme.surfaceContainerHighest;
      foreground = scheme.onSurface;
    } else if (isAnswer) {
      background = scheme.primary;
      foreground = scheme.onPrimary;
    } else if (isPicked) {
      background = scheme.errorContainer;
      foreground = scheme.onErrorContainer;
    } else {
      background = scheme.surfaceContainerHighest.withValues(alpha: 0.4);
      foreground = scheme.onSurfaceVariant;
    }
    return FilledButton(
      key: Key('practice-choice-$choice'),
      onPressed: _revealed ? null : () => onAnswer(choice),
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        disabledBackgroundColor: background,
        disabledForegroundColor: foreground,
        minimumSize: const Size(76, 54),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      child: Text(choice),
    );
  }
}

/// The read-and-play panel: a random phrase is drawn on the staff and the
/// learner plays it back, in order, on the tappable keyboard below.
