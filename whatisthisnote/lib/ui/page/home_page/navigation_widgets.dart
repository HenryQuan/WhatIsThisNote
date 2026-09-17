part of '../home_page.dart';

class _SidebarResizer extends StatelessWidget {
  const _SidebarResizer({required this.onDrag});

  /// Called with the horizontal drag delta (positive when dragging right).
  final ValueChanged<double> onDrag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragUpdate: (details) => onDrag(details.delta.dx),
        child: Semantics(
          label: context.l10n.resizeControlsPanel,
          child: SizedBox(
            width: 12,
            child: Center(
              child: Container(width: 1, color: scheme.outlineVariant),
            ),
          ),
        ),
      ),
    );
  }
}

/// The one-time first-run coach mark shown over the staff. It explains the two
/// core gestures and can be dismissed with a single tap.
class _CoachMark extends StatelessWidget {
  const _CoachMark({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Semantics(
      liveRegion: true,
      label: l10n.onboardingSemantics,
      child: Stack(
        children: [
          // The card body lets gestures fall through to the staff underneath;
          // only the "Got it" button is interactive, so the coach mark never
          // blocks the very gesture it is teaching.
          IgnorePointer(
            child: Material(
              key: const Key('onboarding-coach'),
              color: scheme.inverseSurface,
              elevation: 6,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Icon(Icons.touch_app, color: scheme.onInverseSurface),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.onboardingBody,
                        style: TextStyle(color: scheme.onInverseSurface),
                      ),
                    ),
                    const SizedBox(width: 84),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: Center(
              child: TextButton(
                key: const Key('onboarding-dismiss'),
                onPressed: onDismiss,
                style: TextButton.styleFrom(
                  foregroundColor: scheme.onInverseSurface,
                ),
                child: Text(l10n.gotIt),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The panel shown while the guided theory path is active. It replaces the
/// manual controls with the current step and Back / Next navigation.
