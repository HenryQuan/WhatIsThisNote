import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_language.dart';
import '../../core/display_preferences.dart';
import '../../l10n/l10n.dart';
import 'display_settings.dart';
import 'section_heading.dart';

/// Links shown in the About tab.
const String kRepoUrl = 'https://github.com/HenryQuan/WhatIsThisNote';
const String kWebUrl = 'https://note.tragichero.win';
const String kEmail = 'the@tragichero.win';
const String kBravuraUrl = 'https://github.com/steinbergmedia/bravura';

/// The app's release version. Keep this in step with `version:` in pubspec.yaml
/// (`0.3.0+1` means the displayed version here is `0.3`).
const String kAppVersion = '0.3';

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

/// The About tab: the display, language and theme preferences moved out of the
/// app bar, plus the project, feedback and open-source details.
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
    final l10n = context.l10n;
    showLicensePage(
      context: context,
      applicationName: l10n.appTitle,
      applicationVersion: kAppVersion,
      applicationLegalese: l10n.licenseLegalese,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

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
                l10n.appTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.aboutTagline,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.versionLabel(kAppVersion),
                key: const Key('about-version'),
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              SectionHeading(title: l10n.sectionDisplay),
              DisplaySettings(
                preferences: display,
                onChanged: onDisplayChanged,
              ),
              const SizedBox(height: 24),

              SectionHeading(title: l10n.sectionTheme),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                key: const Key('theme-mode'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(l10n.themeSystem),
                  ),
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(l10n.themeLight),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(l10n.themeDark),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (selection) =>
                    onThemeModeChanged(selection.first),
              ),
              const SizedBox(height: 24),

              SectionHeading(title: l10n.sectionLanguage),
              const SizedBox(height: 8),
              _LanguagePicker(
                value: display.language,
                onChanged: (language) =>
                    onDisplayChanged(display.copyWith(language: language)),
              ),
              const SizedBox(height: 24),

              SectionHeading(title: l10n.sectionFeedback),
              const SizedBox(height: 8),
              Text(l10n.aboutFeedbackBody, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              _LinkTile(
                key: const Key('about-github'),
                icon: Icons.code,
                title: l10n.aboutGithub,
                subtitle: kRepoUrl,
                onTap: () => _open(kRepoUrl),
              ),
              _LinkTile(
                key: const Key('about-email'),
                icon: Icons.mail_outline,
                title: l10n.aboutEmail,
                subtitle: kEmail,
                onTap: () => _open('mailto:$kEmail'),
              ),
              _LinkTile(
                key: const Key('about-web'),
                icon: Icons.public,
                title: l10n.aboutWeb,
                subtitle: 'note.tragichero.win',
                onTap: () => _open(kWebUrl),
              ),
              const SizedBox(height: 24),

              SectionHeading(title: l10n.sectionOpenSource),
              const SizedBox(height: 8),
              Text(l10n.aboutOpenSourceBody, style: theme.textTheme.bodyMedium),
              const SizedBox(height: 8),
              _LinkTile(
                key: const Key('about-bravura'),
                icon: Icons.text_fields,
                title: l10n.aboutBravura,
                subtitle: 'SIL Open Font License 1.1',
                onTap: () => _open(kBravuraUrl),
              ),
              _LinkTile(
                key: const Key('about-licenses'),
                icon: Icons.article_outlined,
                title: l10n.aboutLicenses,
                subtitle: l10n.aboutLicensesSubtitle,
                onTap: () => _showLicenses(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A compact language selector: the system default, or a fixed language.
class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.value, required this.onChanged});

  final AppLanguage value;
  final ValueChanged<AppLanguage> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DropdownButton<AppLanguage>(
      key: const Key('language-picker'),
      value: value,
      isExpanded: true,
      onChanged: (language) {
        if (language != null) onChanged(language);
      },
      items: [
        for (final language in AppLanguage.values)
          DropdownMenuItem<AppLanguage>(
            value: language,
            child: Text(
              language == AppLanguage.system
                  ? l10n.languageSystem
                  : language.nativeName,
            ),
          ),
      ],
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
