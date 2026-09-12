# whatisthisnote

The Flutter app for [WhatIsThisNote](../README.md). Drag a note around the
staff to learn to read music; ledger lines, key signatures, note names and a
mini piano keyboard update live. Optional add-ons (off by default) highlight
scales such as pentatonic and blues, build the diatonic chords of the key with
Roman numerals, inversions and simple progressions, and run a guided theory
path of short lessons with drag-to-target practice.

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

- `lib/core` - music theory (notes, clefs, keys, scales, chords, lessons) and
  staff geometry
- `lib/ui/painters` - the `CustomPainter` that draws the staff, clef, key
  signature, ledger lines, note, chord and practice target
- `lib/ui/widgets` - the interactive `StaffView` and the `PianoKeyboard`
- `lib/ui/page` - the home screen and the guided-lesson panel
