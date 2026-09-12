import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'audio/note_player.dart';
import 'core/display_preferences.dart';
import 'ui/page/home_page.dart';
import 'ui/theme.dart';

void main() => runApp(const WhatIsThisNoteApp());

class WhatIsThisNoteApp extends StatefulWidget {
  const WhatIsThisNoteApp({super.key, this.notePlayer});

  /// Overrides the audio player, used by tests to avoid the native plugin.
  final NotePlayer? notePlayer;

  @override
  State<WhatIsThisNoteApp> createState() => _WhatIsThisNoteAppState();
}

class _WhatIsThisNoteAppState extends State<WhatIsThisNoteApp> {
  ThemeMode _themeMode = ThemeMode.system;

  /// Display preferences. Held here (not persisted yet) so a future
  /// `shared_preferences` load/save only has to touch this one place.
  DisplayPreferences _display = const DisplayPreferences();

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
            onDisplayChanged: (display) =>
                setState(() => _display = display),
            notePlayer: widget.notePlayer,
          ),
        );
      },
    );
  }
}
