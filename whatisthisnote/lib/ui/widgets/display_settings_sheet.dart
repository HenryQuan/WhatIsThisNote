import 'package:flutter/material.dart';

import '../../core/display_preferences.dart';

/// A bottom sheet for the display preferences: the naming system, the on-staff
/// label and the enharmonic spelling.
class DisplaySettingsSheet extends StatefulWidget {
  const DisplaySettingsSheet({
    super.key,
    required this.preferences,
    required this.onChanged,
  });

  final DisplayPreferences preferences;

  /// Called on every change so the screen behind the sheet updates live.
  final ValueChanged<DisplayPreferences> onChanged;

  @override
  State<DisplaySettingsSheet> createState() => _DisplaySettingsSheetState();
}

class _DisplaySettingsSheetState extends State<DisplaySettingsSheet> {
  late DisplayPreferences _preferences = widget.preferences;

  void _update(DisplayPreferences preferences) {
    setState(() => _preferences = preferences);
    widget.onChanged(preferences);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Display', style: theme.textTheme.titleLarge),
              const SizedBox(height: 16),
              Text('Note naming', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<NamingSystem>(
                key: const Key('naming-system'),
                showSelectedIcon: false,
                segments: [
                  for (final system in NamingSystem.values)
                    ButtonSegment<NamingSystem>(
                      value: system,
                      label: Text(system.label),
                    ),
                ],
                selected: {_preferences.naming},
                onSelectionChanged: (selection) =>
                    _update(_preferences.copyWith(naming: selection.first)),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                key: const Key('toggle-staff-label'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Note name on staff'),
                value: _preferences.showStaffLabel,
                onChanged: (value) =>
                    _update(_preferences.copyWith(showStaffLabel: value)),
              ),
              SwitchListTile(
                key: const Key('toggle-enharmonic'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Enharmonic equivalent'),
                subtitle: const Text('F\u266F ~ G\u266D'),
                value: _preferences.showEnharmonic,
                onChanged: (value) =>
                    _update(_preferences.copyWith(showEnharmonic: value)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
