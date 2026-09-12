import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'audio/note_player.dart';
import 'core/display_preferences.dart';
import 'core/display_preferences_store.dart';
import 'core/onboarding.dart';
import 'ui/page/home_page.dart';
import 'ui/theme.dart';

void main() => runApp(
  WhatIsThisNoteApp(
    onboardingStore: SharedPreferencesOnboardingStore(),
    displayPreferencesStore: SharedPreferencesDisplayPreferencesStore(),
  ),
);

class WhatIsThisNoteApp extends StatefulWidget {
  const WhatIsThisNoteApp({
    super.key,
    this.notePlayer,
    this.onboardingStore,
    this.displayPreferencesStore,
  });

  /// Overrides the audio player, used by tests to avoid the native plugin.
  final NotePlayer? notePlayer;

  /// Persists the first-run coach mark. Defaults to an in-memory store that
  /// reports the mark as already seen, so tests and previews stay clean.
  final OnboardingStore? onboardingStore;

  /// Persists the display preferences. Defaults to an in-memory store.
  final DisplayPreferencesStore? displayPreferencesStore;

  @override
  State<WhatIsThisNoteApp> createState() => _WhatIsThisNoteAppState();
}

class _WhatIsThisNoteAppState extends State<WhatIsThisNoteApp> {
  ThemeMode _themeMode = ThemeMode.system;

  /// Display preferences, restored from and saved to [_displayStore].
  DisplayPreferences _display = const DisplayPreferences();

  late final OnboardingStore _onboardingStore =
      widget.onboardingStore ?? InMemoryOnboardingStore();

  late final DisplayPreferencesStore _displayStore =
      widget.displayPreferencesStore ?? InMemoryDisplayPreferencesStore();

  bool _showCoachMark = false;

  @override
  void initState() {
    super.initState();
    _onboardingStore.hasSeenCoachMark().then((seen) {
      if (!mounted || seen) return;
      setState(() => _showCoachMark = true);
    });
    _displayStore.load().then((display) {
      if (!mounted || display == _display) return;
      setState(() => _display = display);
    });
  }

  void _changeDisplay(DisplayPreferences display) {
    setState(() => _display = display);
    _displayStore.save(display);
  }

  void _dismissCoachMark() {
    _onboardingStore.markCoachMarkSeen();
    setState(() => _showCoachMark = false);
  }

  /// Material You dynamic color is an Android feature; other platforms (and
  /// web) keep the app's brand palette.
  bool get _useDynamicColor =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final dynamicLight = _useDynamicColor ? lightDynamic : null;
        final dynamicDark = _useDynamicColor ? darkDynamic : null;
        return MaterialApp(
          title: 'WhatIsThisNote',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(dynamicLight),
          darkTheme: AppTheme.dark(dynamicDark),
          themeMode: _themeMode,
          home: HomePage(
            themeMode: _themeMode,
            onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
            display: _display,
            onDisplayChanged: _changeDisplay,
            notePlayer: widget.notePlayer,
            showCoachMark: _showCoachMark,
            onCoachMarkDismissed: _dismissCoachMark,
          ),
        );
      },
    );
  }
}
