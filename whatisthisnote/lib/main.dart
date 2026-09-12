import 'package:flutter/material.dart';

import 'ui/page/home_page.dart';
import 'ui/theme.dart';

void main() => runApp(const WhatIsThisNoteApp());

class WhatIsThisNoteApp extends StatefulWidget {
  const WhatIsThisNoteApp({super.key});

  @override
  State<WhatIsThisNoteApp> createState() => _WhatIsThisNoteAppState();
}

class _WhatIsThisNoteAppState extends State<WhatIsThisNoteApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'What is this note?',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode,
      home: HomePage(
        themeMode: _themeMode,
        onThemeModeChanged: (mode) => setState(() => _themeMode = mode),
      ),
    );
  }
}
