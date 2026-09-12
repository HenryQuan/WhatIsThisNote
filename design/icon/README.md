# WhatIsThisNote icon

A single vector design — a soft-black quarter note centred on a faint grey
five-line staff over a plain white tile — rendered into every platform's
required format by one Dart generator.

## Source of truth

`generate_icons_test.dart` defines the geometry once, then:

- renders **PNGs** directly with `dart:ui` (no ImageMagick/Inkscape needed),
- writes the **SVG** masters in this folder,
- writes the **Android VectorDrawable** files.

Edit the geometry constants at the top of the generator, not the exports.

## Regenerate

```bash
cd whatisthisnote
flutter test ../design/icon/generate_icons_test.dart
```

The command prints an ASCII preview of the icon so the layout can be checked
without opening an image viewer.

## Outputs

| File | Used by |
| --- | --- |
| `icon.svg` | master, opaque square |
| `icon-rounded.svg` | favicon / legacy launcher |
| `icon-maskable.svg` | PWA `maskable` icons |
| `icon-foreground.svg` | adaptive-icon foreground reference |
| `icon-monochrome.svg` | themed-icon reference |
| `preview.png` | 256px preview |
| `whatisthisnote/ios/.../AppIcon.appiconset/*.png` | iOS |
| `whatisthisnote/android/.../mipmap-*/ic_launcher[_round].png` | Android (pre-API 26) |
| `whatisthisnote/android/.../drawable/ic_launcher_foreground.xml` | Android adaptive icon |
| `whatisthisnote/android/.../drawable/ic_launcher_monochrome.xml` | Android themed icon (Material You) |
| `whatisthisnote/android/.../mipmap-anydpi-v26/ic_launcher*.xml` | Android adaptive icon |
| `whatisthisnote/web/favicon.png`, `web/icons/*.png` | web / PWA |

## Android theming

`mipmap-anydpi-v26/ic_launcher.xml` ships a `<monochrome>` layer, so Android 13+
can tint the icon to the user's Material You palette. Devices or launchers that
do not support adaptive/themed icons fall back to the `mipmap-*/ic_launcher.png`
artwork (white tile with a faint staff and a soft-black note).
