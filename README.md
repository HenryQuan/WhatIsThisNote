# WhatIsThisNote

I started playing piano in January 2018 and I couldn't read music sheets fast
enough. This app aims to solve that.

Drag the note up and down the staff and the app tells you what the note is,
automatically drawing ledger lines when the note goes above or below the five
lines.

DeepSeek has implemented everything after 7 years in one afternoon. I am shocked how far we have came. I always wanted to get this app out, so I can read notes faster. Now, I finally can and learn music theory better than before.

## Features

- [x] Simple and clean Material 3 UI
- [x] Drag or tap the note to change its pitch; it snaps to the nearest position
- [x] Smooth snap animation
- [x] First-run coach mark explaining the drag and tap gestures, shown once and
      remembered with `shared_preferences`
- [x] Stable layout: the staff fills the space the controls leave, and the
      readout can never change the panel's height, so the view does not jump
      while dragging
- [x] Automatic ledger lines above and below the staff
- [x] All 15 major and 15 minor key signatures, drawn on the staff
- [x] Note names in scientific pitch (C, D, E...) and fixed-do solfege (Do, Re, Mi...)
- [x] Numbered notation (jianpu) degree next to the name, 1 = Do ... 7 = Ti
- [x] Display preferences: pick the naming system (scientific, solfege or
      numbered), toggle the on-staff name label and show the enharmonic twin
      (F♯ ~ G♭). Saved between sessions with `shared_preferences`
- [x] Accessibility: the staff and note are labelled for screen readers (the
      answer stays hidden in practice), arrow keys nudge the note on a
      keyboard, and "reduce motion" makes the snap instant
- [x] Mini piano keyboard showing which key the note is on
- [x] Hear the note, or the current chord, with a built-in synthesizer (no audio assets)
- [x] Treble, bass and alto clefs
- [x] Localized into eight languages plus English (Simplified and Traditional
      Chinese, Japanese, Korean, Spanish, French, German and Portuguese). The
      language follows the system by default and can be changed in About,
      where the choice is saved between sessions
- [x] Responsive layout (line spacing scales with the screen)
- [x] Light and dark themes

### Add-ons (off by default)

- [x] Practice mode: a name-the-note quiz that hides the answer and asks you to
      pick from four choices, with a running score and a streak
- [x] Scale highlight: major, natural/harmonic/melodic minor, major/minor
      pentatonic and blues, tinted on the piano keyboard with the note's scale
      degree
- [x] Chords and harmony lab: diatonic triads and seventh chords shown on the
      staff and piano with their chord symbol and Roman numeral, root/1st/2nd/
      3rd inversion with slash-bass names, and tappable progressions
      (I-V-vi-IV, ii-V-I, canon, Andalusian)
- [x] Guided theory path: short lessons on the staff, its lines and spaces, the
      bass clef and sharps/flats. Each lesson explains a little and then asks
      you to drag the note to a target, drawn as a hollow notehead. Accidentals
      outside the key (sharps, flats and naturals) are written on the note and
      on the target

The chord lab works from the note's scale degree and only builds chords on
seven-note scales; it falls back to the key's major or natural minor scale and
shows no chord for chromatic notes. The play button sounds the written note,
or the chord's tones when the chord lab is on. Tones are synthesized in Dart
and played through `audioplayers`, which works on Android, iOS, web, Windows,
macOS and Linux. A progression is selected and tapped, then played as a
sequence with its play button. The guided path can write sharps, flats and
naturals that are not in the key on the note and on the practice target.

## Getting started

```bash
cd whatisthisnote
flutter pub get
flutter run
```

The app renders clefs and noteheads with the bundled
[Bravura](https://github.com/steinbergmedia/bravura) music font (SIL OFL).
