part of '../home_page.dart';

class _GuidedPanel extends StatelessWidget {
  const _GuidedPanel({
    super.key,
    required this.lesson,
    required this.step,
    required this.lessonIndex,
    required this.stepIndex,
    required this.totalSteps,
    required this.totalLessons,
    required this.completedSteps,
    required this.isLastStep,
    required this.matched,
    required this.onBack,
    required this.onNext,
    required this.onExit,
  });

  final Lesson lesson;
  final LessonStep step;
  final int lessonIndex;
  final int stepIndex;
  final int totalSteps;
  final int totalLessons;
  final int completedSteps;
  final bool isLastStep;
  final bool matched;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final canGoBack = lessonIndex > 0 || stepIndex > 0;
    final canAdvance = !step.isPractice || matched;

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
                  Icon(Icons.school, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.guidedLesson(
                        lessonIndex + 1,
                        totalLessons,
                        lesson.title,
                      ),
                      key: const Key('guided-lesson'),
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  IconButton(
                    key: const Key('guided-exit'),
                    tooltip: l10n.guidedExit,
                    icon: const Icon(Icons.close),
                    onPressed: onExit,
                  ),
                ],
              ),
              LinearProgressIndicator(
                key: const Key('guided-progress'),
                value: (completedSteps + 1) / totalSteps,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Text(
                step.title,
                key: const Key('guided-step-title'),
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                step.instruction,
                key: const Key('guided-instruction'),
                style: theme.textTheme.bodyMedium,
              ),
              if (step.isPractice) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      matched ? Icons.check_circle : Icons.touch_app,
                      size: 18,
                      color: matched ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        matched ? l10n.guidedWellDone : l10n.guidedDragToTarget,
                        key: const Key('guided-status'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: matched
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
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
                      key: const Key('guided-back'),
                      onPressed: canGoBack ? onBack : null,
                      child: Text(l10n.back),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      key: const Key('guided-next'),
                      onPressed: canAdvance ? onNext : null,
                      child: Text(isLastStep ? l10n.finish : l10n.next),
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
}

/// The panel shown in practice mode. It replaces the manual controls with a
/// name-the-note quiz: the staff hides the answer and the learner picks the
/// name from five choices.
