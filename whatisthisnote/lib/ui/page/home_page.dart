import 'package:flutter/material.dart';

import '../../core/clef.dart';
import '../../core/staff_geometry.dart';
import '../widgets/staff_view.dart';

/// The main screen: an interactive staff plus controls for the clef, the note
/// position and the theme.
class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Clef _clef = Clef.treble;

  /// Middle line of the treble staff (B4).
  int _step = 4;

  void _setStep(int step) {
    setState(() => _step = step.clamp(kMinStaffStep, kMaxStaffStep));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('What is this note?'),
        actions: [
          PopupMenuButton<ThemeMode>(
            tooltip: 'Theme',
            icon: Icon(_themeIcon(widget.themeMode)),
            initialValue: widget.themeMode,
            onSelected: widget.onThemeModeChanged,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ThemeMode.system,
                child: _ThemeOption(
                  icon: Icons.brightness_auto,
                  label: 'System',
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.light,
                child: _ThemeOption(
                  icon: Icons.light_mode,
                  label: 'Light',
                ),
              ),
              PopupMenuItem(
                value: ThemeMode.dark,
                child: _ThemeOption(
                  icon: Icons.dark_mode,
                  label: 'Dark',
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: StaffView(
                clef: _clef,
                step: _step,
                onStepChanged: (step) {
                  if (step != _step) setState(() => _step = step);
                },
              ),
            ),
            _Controls(
              clef: _clef,
              step: _step,
              onClefChanged: (clef) => setState(() => _clef = clef),
              onStepChanged: _setStep,
            ),
          ],
        ),
      ),
    );
  }

  IconData _themeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.system:
        return Icons.brightness_auto;
    }
  }
}

class _Controls extends StatelessWidget {
  const _Controls({
    required this.clef,
    required this.step,
    required this.onClefChanged,
    required this.onStepChanged,
  });

  final Clef clef;
  final int step;
  final ValueChanged<Clef> onClefChanged;
  final ValueChanged<int> onStepChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = clef.noteAt(step);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          note.name,
                          key: const Key('note-name'),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          note.solfege,
                          key: const Key('note-solfege'),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${clef.label} clef  ·  drag the note or tap the staff',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton.filledTonal(
                    onPressed: step < kMaxStaffStep
                        ? () => onStepChanged(step + 1)
                        : null,
                    icon: const Icon(Icons.keyboard_arrow_up),
                    tooltip: 'Higher',
                  ),
                  IconButton.filledTonal(
                    onPressed: step > kMinStaffStep
                        ? () => onStepChanged(step - 1)
                        : null,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    tooltip: 'Lower',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SegmentedButton<Clef>(
            segments: [
              for (final value in Clef.values)
                ButtonSegment<Clef>(
                  value: value,
                  label: Text(value.label),
                ),
            ],
            selected: {clef},
            onSelectionChanged: (selection) => onClefChanged(selection.first),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 12),
        Text(label),
      ],
    );
  }
}
