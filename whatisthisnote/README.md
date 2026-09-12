# whatisthisnote

The Flutter app for [WhatIsThisNote](../README.md). Drag a note around the
staff to learn to read music; ledger lines and note names update live.

## Run

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter analyze
flutter test
```

## Project layout

- `lib/core` - music theory and staff geometry (pure Dart, unit tested)
- `lib/ui/painters` - the `CustomPainter` that draws the staff and note
- `lib/ui/widgets` - the interactive, draggable `StaffView`
- `lib/ui/page` - the home screen
