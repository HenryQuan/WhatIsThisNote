import 'package:flutter/material.dart';

import '../../core/display_preferences.dart';

/// The display preferences form: the naming system, the on-staff label and the
/// enharmonic spelling. Shared by the About tab and, if ever needed, a sheet.
class DisplaySettings extends StatelessWidget {
  const DisplaySettings({
    super.key,
    required this.preferences,
    required this.onChanged,
  });

  final DisplayPreferences preferences;

  /// Called on every change so the caller can save and rebuild.
  final ValueChanged<DisplayPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          selected: {preferences.naming},
          onSelectionChanged: (selection) =>
              onChanged(preferences.copyWith(naming: selection.first)),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          key: const Key('toggle-staff-label'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Note name on staff'),
          value: preferences.showStaffLabel,
          onChanged: (value) =>
              onChanged(preferences.copyWith(showStaffLabel: value)),
        ),
        SwitchListTile(
          key: const Key('toggle-enharmonic'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Enharmonic equivalent'),
          subtitle: const Text('F\u266F ~ G\u266D'),
          value: preferences.showEnharmonic,
          onChanged: (value) =>
              onChanged(preferences.copyWith(showEnharmonic: value)),
        ),
      ],
    );
  }
}
