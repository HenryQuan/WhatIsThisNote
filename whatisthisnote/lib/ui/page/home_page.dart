import 'package:flutter/material.dart';

import '../../core/clef.dart';
import '../../core/key.dart';
import '../../core/scale.dart';
import '../../core/staff_geometry.dart';
import '../widgets/piano_keyboard.dart';
import '../widgets/staff_view.dart';

/// The main screen: an interactive staff plus controls for the clef, the key,
/// an optional scale highlight, the note position and the theme.
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
  MusicalKey _key = kMajorKeys.first;

  /// Optional scale highlight (an add-on), off by default.
  ScaleType? _scaleType;

  /// Middle line of the treble staff (B4).
  int _step = 4;

  void _setStep(int step) {
    setState(() => _step = step.clamp(kMinStaffStep, kMaxStaffStep));
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scaleType == null
        ? null
        : Scale(_key.tonic, _key.tonicPitchClass, _scaleType!);

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
                keySignature: _key,
                step: _step,
                onStepChanged: (step) {
                  if (step != _step) setState(() => _step = step);
                },
              ),
            ),
            _Controls(
              key: const Key('controls'),
              clef: _clef,
              keySignature: _key,
              scale: scale,
              step: _step,
              onClefChanged: (clef) => setState(() => _clef = clef),
              onKeyChanged: (key) => setState(() => _key = key),
              onScaleTypeChanged: (type) => setState(() => _scaleType = type),
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
    super.key,
    required this.clef,
    required this.keySignature,
    required this.scale,
    required this.step,
    required this.onClefChanged,
    required this.onKeyChanged,
    required this.onScaleTypeChanged,
    required this.onStepChanged,
  });

  final Clef clef;
  final MusicalKey keySignature;
  final Scale? scale;
  final int step;
  final ValueChanged<Clef> onClefChanged;
  final ValueChanged<MusicalKey> onKeyChanged;
  final ValueChanged<ScaleType?> onScaleTypeChanged;
  final ValueChanged<int> onStepChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final note = keySignature.applyTo(clef.noteAt(step));

    final scaleDegree = scale?.degreeLabelFor(note.midi);
    final inScale = scaleDegree != null;
    final badgeColor = scale == null || inScale
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final badgeTextColor = scale == null || inScale
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurfaceVariant;
    final badgeLabel = scale == null ? '${note.degree}' : (scaleDegree ?? '–');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badgeLabel,
                            key: const Key('note-degree'),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: badgeTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            scale == null
                                ? 'numbered notation (1 = Do … 8 = Do)'
                                : '${scale!.label} · '
                                    '${inScale ? 'degree $scaleDegree' : 'outside scale'}',
                            key: const Key('note-scale-caption'),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
          PianoKeyboard(
            midi: note.midi,
            label: note.pitchName,
            highlightPitchClasses: scale?.pitchClasses,
          ),
          const SizedBox(height: 12),
          SegmentedButton<Clef>(
            showSelectedIcon: false,
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
          const SizedBox(height: 8),
          _KeySelector(value: keySignature, onChanged: onKeyChanged),
          const SizedBox(height: 8),
          _ScaleSelector(value: scale?.type, onChanged: onScaleTypeChanged),
        ],
      ),
    );
  }
}

class _KeySelector extends StatelessWidget {
  const _KeySelector({required this.value, required this.onChanged});

  final MusicalKey value;
  final ValueChanged<MusicalKey> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<MusicalKey>(
      tooltip: 'Key signature',
      onSelected: onChanged,
      itemBuilder: (context) => [
        const PopupMenuItem<MusicalKey>(
          enabled: false,
          height: 34,
          child: _MenuHeader('Major'),
        ),
        for (final key in kMajorKeys)
          PopupMenuItem<MusicalKey>(value: key, child: Text(key.label)),
        const PopupMenuDivider(),
        const PopupMenuItem<MusicalKey>(
          enabled: false,
          height: 34,
          child: _MenuHeader('Minor'),
        ),
        for (final key in kMinorKeys)
          PopupMenuItem<MusicalKey>(value: key, child: Text(key.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.piano, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Key: ${value.label}',
                key: const Key('key-label'),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value.signatureLabel,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _ScaleSelector extends StatelessWidget {
  const _ScaleSelector({required this.value, required this.onChanged});

  final ScaleType? value;
  final ValueChanged<ScaleType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton<_ScaleOption>(
      tooltip: 'Scale highlight',
      onSelected: (option) => onChanged(option.type),
      itemBuilder: (context) => [
        const PopupMenuItem<_ScaleOption>(
          value: _ScaleOption(null),
          child: Text('Off'),
        ),
        const PopupMenuDivider(),
        for (final type in ScaleType.values)
          PopupMenuItem<_ScaleOption>(
            value: _ScaleOption(type),
            child: Text(type.label),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.highlight, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Highlight: ${value?.label ?? 'Off'}',
                key: const Key('scale-label'),
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}

class _ScaleOption {
  const _ScaleOption(this.type);

  final ScaleType? type;
}

class _MenuHeader extends StatelessWidget {
  const _MenuHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      label.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
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
