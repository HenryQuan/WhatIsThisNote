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

### Add-ons (off by default)

- [x] Scale highlight: major, natural/harmonic/melodic minor, major/minor
      pentatonic and blues, tinted on the piano keyboard with the note's scale
      degree
- [x] Chords and harmony lab: diatonic triads and seventh chords shown on the
      staff and piano with their chord symbol and Roman numeral, root/1st/2nd/
      3rd inversion with slash-bass names, and tappable progressions
      (I-V-vi-IV, ii-V-I, canon, Andalusian)
- [x] Guided theory path: short lessons on the staff, its lines and spaces, the
      bass clef and sharps/flats. Each lesson explains a little and then asks
      you to drag the note to a target, drawn as a hollow notehead

The chord lab works from the note's scale degree and only builds chords on
seven-note scales; it falls back to the key's major or natural minor scale and
shows no chord for chromatic notes. Progressions are selected and tapped
rather than played (there is no audio engine). Sharps and flats in the guided
path come from key signatures, so the path does not yet show accidentals that
are not in the key.

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
