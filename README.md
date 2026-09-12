# WhatIsThisNote

I started playing piano in January 2018 and I couldn't read music sheets fast
enough. This app aims to solve that.

Drag the note up and down the staff and the app tells you what the note is,
automatically drawing ledger lines when the note goes above or below the five
lines.

## Features

- [x] Simple and clean Material 3 UI
- [x] Drag or tap the note to change its pitch; it snaps to the nearest position
- [x] Smooth snap animation
- [x] Automatic ledger lines above and below the staff
- [x] All 15 major and 15 minor key signatures, drawn on the staff
- [x] Note names in scientific pitch (C, D, E...) and fixed-do solfege (Do, Re, Mi...)
- [x] Numbered notation (jianpu) degree next to the name, 1 = Do ... 7 = Ti
- [x] Mini piano keyboard showing which key the note is on
- [x] Treble, bass and alto clefs
- [x] Responsive layout (line spacing scales with the screen)
- [x] Light and dark themes

### Pro features

- [ ] Quiz (time attack with levels)

## Getting started

```bash
cd whatisthisnote
flutter pub get
flutter run
```

The app renders clefs and noteheads with the bundled
[Bravura](https://github.com/steinbergmedia/bravura) music font (SIL OFL).
