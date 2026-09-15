import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/display_preferences.dart';
import 'display_settings.dart';

/// Links shown in the About tab.
const String kRepoUrl = 'https://github.com/HenryQuan/WhatIsThisNote';
const String kWebUrl = 'https://note.tragichero.win';
const String kEmail = 'the@tragichero.win';
const String kBravuraUrl = 'https://github.com/steinbergmedia/bravura';

/// The app's release version. Keep this in step with `version:` in pubspec.yaml
/// (`0.2.0+1` means the displayed version here is `0.2`).
const String kAppVersion = '0.2';

/// Adds the bundled Bravura music font to the open-source license list.
///
/// Flutter registers the licenses of its own packages automatically; a font
/// shipped in `assets/` is not a package, so it has to be added by hand.
void registerBravuraLicense() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks(
      const ['Bravura'],
      'Bravura is (c) Steinberg Media Technologies GmbH and is licensed '
      'under the SIL Open Font License, Version 1.1.\n'
      'Full text: https://scripts.sil.org/OFL\n'
      'Source: $kBravuraUrl',
    );
  });
}

/// The About tab: the display and theme preferences moved out of the app bar,
/// plus the project, feedback and open-source details.
class AboutPanel extends StatelessWidget {
  const AboutPanel({
    super.key,
    required this.themeMode,
    required this.onThemeModeChanged,
    required this.display,
    required this.onDisplayChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final DisplayPreferences display;
  final ValueChanged<DisplayPreferences> onDisplayChanged;

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri)) {
      debugPrint('Could not open $url');
    }
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'What is this note?',
      applicationVersion: kAppVersion,
      applicationLegalese:
          'Bravura music font \u00A9 Steinberg Media Technologies GmbH, '
          'SIL Open Font License 1.1.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.music_note, size: 48, color: scheme.primary),
              const SizedBox(height: 8),
              Text(
                'What is this note?',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Learn to read music by dragging a note around the staff. '
                'Ledger lines, key signatures and note names update as you go.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version $kAppVersion',
                key: const Key('about-version'),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              _Section(title: 'Display'),
              DisplaySettings(
                preferences: display,
                onChanged: onDisplayChanged,
              ),
              const SizedBox(height: 24),

              _Section(title: 'Theme'),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                key: const Key('theme-mode'),
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ThemeMode.system, label: Text('System')),
                  ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) =>
                    onThemeModeChanged(selection.first),
              ),
              const SizedBox(height: 24),

              _Section(title: 'Feedback'),
              const SizedBox(height: 8),
              Text(
                'This app is made by a beginner, not a music teacher. If '
                'something here does not make sense, or is simply wrong, '
                'please open an issue or drop me an email. Feature requests are welcome too, as long as '
                'they help you read notes, understand chords, or find a note '
                'or a sound. It is a companion for learning and practising, '
                'not a tool for composing or producing music.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              _LinkTile(
                key: const Key('about-github'),
                icon: Icons.code,
                title: 'GitHub repository',
                subtitle: kRepoUrl,
                onTap: () => _open(kRepoUrl),
              ),
              _LinkTile(
                key: const Key('about-email'),
                icon: Icons.mail_outline,
                title: 'Email',
                subtitle: kEmail,
                onTap: () => _open('mailto:$kEmail'),
              ),
              _LinkTile(
                key: const Key('about-web'),
                icon: Icons.public,
                title: 'Web version',
                subtitle: 'note.tragichero.win',
                onTap: () => _open(kWebUrl),
              ),
              const SizedBox(height: 24),

              _Section(title: 'Open source'),
              const SizedBox(height: 8),
              Text(
                'This app is built with Flutter, an open-source UI toolkit, '
                'and reads the bundled Bravura music font.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              _LinkTile(
                key: const Key('about-bravura'),
                icon: Icons.text_fields,
                title: 'Bravura music font',
                subtitle: 'SIL Open Font License 1.1',
                onTap: () => _open(kBravuraUrl),
              ),
              _LinkTile(
                key: const Key('about-licenses'),
                icon: Icons.article_outlined,
                title: 'Open-source licenses',
                subtitle: 'Flutter, packages and Bravura',
                onTap: () => _showLicenses(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small uppercase section heading, matching the control panels.
class _Section extends StatelessWidget {
  const _Section({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

/// A tappable row that opens an external link.
class _LinkTile extends StatelessWidget {
  const _LinkTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new, size: 18),
      onTap: onTap,
    );
  }
}
