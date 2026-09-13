import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatisthisnote/audio/note_player.dart';
import 'package:whatisthisnote/core/chord.dart';
import 'package:whatisthisnote/core/clef.dart';
import 'package:whatisthisnote/core/display_preferences.dart';
import 'package:whatisthisnote/core/metronome.dart';
import 'package:whatisthisnote/core/display_preferences_store.dart';
import 'package:whatisthisnote/core/onboarding.dart';
import 'package:whatisthisnote/core/staff_geometry.dart';
import 'package:whatisthisnote/main.dart';
import 'package:whatisthisnote/ui/painters/notation_painter.dart';
import 'package:whatisthisnote/ui/widgets/piano_keyboard.dart';
import 'package:whatisthisnote/ui/widgets/staff_view.dart';

void main() {
  testWidgets('shows the default treble middle line note', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    expect(tester.widget<Text>(find.byKey(const Key('note-name'))).data, 'B4');
    expect(
      tester.widget<Text>(find.byKey(const Key('note-solfege'))).data,
      'Si',
    );
    expect(tester.widget<Text>(find.byKey(const Key('note-degree'))).data, '7');
  });

  testWidgets('the destinations switch between tabs', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());
    expect(find.byKey(const Key('controls')), findsOneWidget);

    await tester.tap(find.byTooltip('Metronome'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('metronome-toggle')), findsOneWidget);
    expect(find.byKey(const Key('register-readout')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byTooltip('Chords'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('builder-add')), findsOneWidget);
    expect(find.textContaining('Add at least two notes'), findsOneWidget);

    await tester.tap(find.byTooltip('Note'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('controls')), findsOneWidget);
  });

  testWidgets('wide windows use a navigation rail', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.pumpAndSettle();

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    // The rail spells the destination out under its icon.
    expect(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Metronome'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the metronome tempo can be changed', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.tap(find.byTooltip('Metronome'));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(const Key('bpm-value'))).data, '90');
    await tester.tap(find.byKey(const Key('bpm-up')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('bpm-value'))).data, '91');
    await tester.tap(find.byKey(const Key('bpm-down')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('bpm-value'))).data, '90');
    await tester.tap(find.byKey(const Key('bpm-up-10')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('bpm-value'))).data, '100');
    await tester.tap(find.byKey(const Key('bpm-down-10')));
    await tester.pump();
    expect(tester.widget<Text>(find.byKey(const Key('bpm-value'))).data, '90');
  });

  testWidgets('the metronome click starts and stops', (tester) async {
    final player = _RecordingNotePlayer();
    await tester.pumpWidget(WhatIsThisNoteApp(notePlayer: player));
    await tester.tap(find.byTooltip('Metronome'));
    await tester.pumpAndSettle();

    Color dotColor(int beat) =>
        (tester
                    .widget<AnimatedContainer>(
                      find.byKey(Key('metronome-beat-$beat')),
                    )
                    .decoration!
                as BoxDecoration)
            .color!;

    await tester.tap(find.byKey(const Key('metronome-toggle')));
    await tester.pump();
    // The click is one looping bar; the dots follow it on their own clock.
    expect(player.clickTracks, hasLength(1));
    expect(player.clickTracks.single.beat, beatInterval(90));
    expect(player.clickTracks.single.clicks, [1318.51, 880.0, 880.0, 880.0]);

    final accent = dotColor(0);
    expect(dotColor(0), isNot(dotColor(1)));
    await tester.pump(const Duration(milliseconds: 700));
    expect(dotColor(1), accent);

    await tester.tap(find.byKey(const Key('metronome-toggle')));
    await tester.pumpAndSettle();
    expect(player.clickStops, 1);
  });

  testWidgets('changing the tempo restarts the click track', (tester) async {
    final player = _RecordingNotePlayer();
    await tester.pumpWidget(WhatIsThisNoteApp(notePlayer: player));
    await tester.tap(find.byTooltip('Metronome'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('metronome-toggle')));
    await tester.pump();
    expect(player.clickTracks, hasLength(1));

    await tester.tap(find.byKey(const Key('bpm-up-10')));
    await tester.pump(const Duration(milliseconds: 200));
    expect(player.clickTracks, hasLength(2));
    expect(player.clickTracks.last.beat, beatInterval(100));

    await tester.tap(find.byKey(const Key('metronome-toggle')));
    await tester.pumpAndSettle();
  });

  testWidgets('the time signature changes the length of the bar', (
    tester,
  ) async {
    final player = _RecordingNotePlayer();
    await tester.pumpWidget(WhatIsThisNoteApp(notePlayer: player));
    await tester.tap(find.byTooltip('Metronome'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('3/4'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('metronome-toggle')));
    await tester.pump();
    expect(player.clickTracks.single.clicks, [1318.51, 880.0, 880.0]);
    expect(find.byKey(const Key('metronome-beat-3')), findsNothing);

    await tester.tap(find.byKey(const Key('metronome-toggle')));
    await tester.pumpAndSettle();
  });

  testWidgets('the register finder plays the selected pitch', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final player = _RecordingNotePlayer();
    await tester.pumpWidget(WhatIsThisNoteApp(notePlayer: player));
    await tester.tap(find.byTooltip('Metronome'));
    await tester.pumpAndSettle();

    // The finder opens on C4.
    await tester.ensureVisible(find.byKey(const Key('register-play')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('register-play')));
    await tester.pump();
    expect(player.played.single.single, closeTo(261.6256, 0.01));

    await tester.ensureVisible(find.byKey(const Key('register-zone-5')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('register-zone-5')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('register-play')));
    await tester.pump();
    expect(player.played.last.single, closeTo(523.2511, 0.01));
  });

  testWidgets('the sweep walks the selected note across the zones', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final player = _RecordingNotePlayer();
    await tester.pumpWidget(WhatIsThisNoteApp(notePlayer: player));
    await tester.tap(find.byTooltip('Metronome'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('register-note-2'))); // D
    await tester.pump();
    player.played.clear();

    await tester.ensureVisible(find.byKey(const Key('register-sweep')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('register-sweep')));
    await tester.pump();
    expect(
      player.played.single.single,
      closeTo(frequencyForPitchClass(2, kMinZone), 0.01),
    );

    await tester.pump(const Duration(milliseconds: 500));
    expect(
      player.played.last.single,
      closeTo(frequencyForPitchClass(2, kMinZone + 1), 0.01),
    );

    await tester.tap(find.byKey(const Key('register-sweep')));
    await tester.pumpAndSettle();
  });

  testWidgets('the chord builder names the notes it is given', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byTooltip('Chords'),
      ),
    );
    await tester.pumpAndSettle();

    // The add button stacks a third at a time: D, F, A.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('builder-add')));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Dm'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('builder-count'))).data,
      '3 of 8 notes',
    );
  });

  testWidgets('the chord builder suggests the closest chord', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byTooltip('Chords'),
      ),
    );
    await tester.pumpAndSettle();

    // D and F alone spell no triad; Dm is one A away.
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const Key('builder-add')));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(find.text('Dm'), findsOneWidget);
    expect(find.text('add A'), findsOneWidget);
  });

  testWidgets('the chord builder plays the notes the learner stacked', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final player = _RecordingNotePlayer();
    await tester.pumpWidget(WhatIsThisNoteApp(notePlayer: player));
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byTooltip('Chords'),
      ),
    );
    await tester.pumpAndSettle();

    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byKey(const Key('builder-add')));
      await tester.pump();
    }
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('builder-play')));
    await tester.pump();

    expect(player.played, hasLength(1));
    expect(player.played.single, hasLength(2));
  });

  testWidgets('shows a piano keyboard for the current note', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    final piano = tester.widget<PianoKeyboard>(find.byType(PianoKeyboard));
    expect(piano.midi, 71); // B4
    expect(piano.label, 'B');
  });

  testWidgets('the higher button moves the note up the staff', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    await tester.tap(find.byTooltip('Higher'));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(const Key('note-name'))).data, 'C5');
  });

  testWidgets('switching clef changes the note name', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    await tester.tap(find.text('Bass'));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(const Key('note-name'))).data, 'D3');
  });

  testWidgets('dragging the staff changes the note', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    await tester.drag(find.byType(StaffView), const Offset(0, -60));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('note-name'))).data,
      isNot('B4'),
    );
  });

  testWidgets('selecting a key applies its signature to the note', (
    tester,
  ) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    await tester.tap(find.byKey(const Key('key-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('G major').last);
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('key-label'))).data,
      'Key: G major',
    );

    // Move up four steps from the middle line (B4) to the F line (F5).
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byTooltip('Higher'));
      await tester.pumpAndSettle();
    }

    expect(
      tester.widget<Text>(find.byKey(const Key('note-name'))).data,
      'F\u266F5',
    );
  });

  testWidgets('key menu shows the sharps or flats of each key', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    await tester.tap(find.byKey(const Key('key-label')));
    await tester.pumpAndSettle();

    expect(find.text('no sharps or flats'), findsWidgets);
    expect(find.text('1 sharp \u00B7 F\u266F'), findsWidgets);
    expect(find.text('2 sharps \u00B7 F\u266F, C\u266F'), findsWidgets);
  });

  testWidgets('practice mode is a separate quiz mode', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    expect(find.byKey(const Key('controls')), findsOneWidget);
    expect(tester.widget<StaffView>(find.byType(StaffView)).showLabel, isTrue);

    await tester.tap(find.byTooltip('Practice'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('controls')), findsNothing);
    expect(find.byKey(const Key('practice-panel')), findsOneWidget);
    expect(tester.widget<StaffView>(find.byType(StaffView)).showLabel, isFalse);
    expect(
      tester.widget<StaffView>(find.byType(StaffView)).interactive,
      isFalse,
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('practice-score'))).data,
      '0 / 0',
    );

    final step = tester.widget<StaffView>(find.byType(StaffView)).step;
    final answer = Clef.treble.noteAt(step).pitchName;
    final choice = find.byKey(Key('practice-choice-$answer'));
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('practice-score'))).data,
      '1 / 1',
    );
    expect(find.byKey(const Key('practice-feedback')), findsOneWidget);
    expect(tester.widget<StaffView>(find.byType(StaffView)).showLabel, isTrue);

    await tester.tap(find.byKey(const Key('practice-next')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('practice-score'))).data,
      '1 / 1',
    );
    expect(tester.widget<StaffView>(find.byType(StaffView)).showLabel, isFalse);

    await tester.tap(find.byKey(const Key('practice-exit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('controls')), findsOneWidget);
  });

  testWidgets('scale highlight is off by default and can be enabled', (
    tester,
  ) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    expect(
      tester.widget<Text>(find.byKey(const Key('scale-label'))).data,
      'Highlight: Off',
    );
    expect(
      tester
          .widget<PianoKeyboard>(find.byType(PianoKeyboard))
          .highlightPitchClasses,
      isNull,
    );

    await tester.tap(find.byKey(const Key('scale-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Blues').last);
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('scale-label'))).data,
      'Highlight: Blues',
    );
    expect(
      tester
          .widget<PianoKeyboard>(find.byType(PianoKeyboard))
          .highlightPitchClasses,
      {0, 3, 5, 6, 7, 10},
    );
    // B4 is outside the C blues scale.
    expect(
      tester.widget<Text>(find.byKey(const Key('note-degree'))).data,
      '\u2013',
    );

    await tester.tap(find.byTooltip('Higher')); // C5 is the tonic.
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('note-degree'))).data, '1');
  });

  testWidgets('chord lab is off by default and builds diatonic triads', (
    tester,
  ) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    expect(
      tester.widget<Text>(find.byKey(const Key('chord-label'))).data,
      'Chords: Off',
    );
    expect(find.byKey(const Key('chord-symbol')), findsNothing);

    await tester.tap(find.byKey(const Key('chord-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Triads').last);
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('chord-label'))).data,
      'Chords: Triads',
    );
    // B4 is degree 7 of C major, so the triad is B diminished (B D F).
    expect(
      tester.widget<Text>(find.byKey(const Key('chord-symbol'))).data,
      'Bdim',
    );
    expect(
      tester
          .widget<PianoKeyboard>(find.byType(PianoKeyboard))
          .chordPitchClasses,
      {11, 2, 5},
    );
    expect(tester.widget<StaffView>(find.byType(StaffView)).chordSteps, [
      4,
      6,
      8,
    ]);
    expect(
      tester.widget<Text>(find.byKey(const Key('chord-caption'))).data,
      contains('vii'),
    );
  });

  testWidgets('extended chords update the progression chips', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    await tester.tap(find.byKey(const Key('chord-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ninths').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('progression-label')));
    await tester.tap(find.byKey(const Key('progression-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(kProgressions.first.name).last);
    await tester.pumpAndSettle();

    // The pop progression in C major: Imaj9, V9, vi9, IVmaj9.
    expect(find.text('Imaj9'), findsOneWidget);
    expect(find.text('V9'), findsOneWidget);
    expect(find.text('vi9'), findsOneWidget);
  });

  testWidgets('tapping the chord symbol picks a specific chord', (
    tester,
  ) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    await tester.tap(find.byKey(const Key('chord-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Triads').last);
    await tester.pumpAndSettle();
    // B4 is degree vii of C major, so the diatonic triad is B diminished.
    expect(
      tester.widget<Text>(find.byKey(const Key('chord-symbol'))).data,
      'Bdim',
    );

    await tester.tap(find.byKey(const Key('chord-symbol')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(CheckedPopupMenuItem<ChordQuality>, 'Bmaj7').last,
    );
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('chord-symbol'))).data,
      'Bmaj7',
    );
    expect(
      tester
          .widget<PianoKeyboard>(find.byType(PianoKeyboard))
          .chordPitchClasses,
      {11, 3, 6, 10},
    );
  });

  testWidgets('an out-of-scale note gets a transformed chord', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    // C\u266F major with a C\u266F harmonic minor highlight: E\u266F is in the key
    // but outside the highlight, so its diatonic chord is transformed.
    await tester.tap(find.byKey(const Key('key-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('C\u266F major').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('scale-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Harmonic minor').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chord-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Triads').last);
    await tester.pumpAndSettle();

    // The middle line reads B\u266F in C\u266F major; four steps down is E\u266F.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byTooltip('Lower'));
      await tester.pumpAndSettle();
    }

    expect(
      tester.widget<Text>(find.byKey(const Key('chord-symbol'))).data,
      'E\u266Fm',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('chord-caption'))).data,
      contains('chromatic'),
    );
    expect(
      tester
          .widget<PianoKeyboard>(find.byType(PianoKeyboard))
          .chordPitchClasses,
      {5, 8, 0},
    );
  });

  testWidgets('changing inversion rotates the chord and names the bass', (
    tester,
  ) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.tap(find.byKey(const Key('chord-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Triads').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('1st'));
    await tester.tap(find.text('1st'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('chord-symbol'))).data,
      'Bdim/D',
    );
    expect(tester.widget<StaffView>(find.byType(StaffView)).chordSteps, [
      6,
      8,
      11,
    ]);
    expect(
      tester.widget<Text>(find.byKey(const Key('chord-caption'))).data,
      contains('1st inversion'),
    );
  });

  testWidgets('the note label follows the chord bass when inverted', (
    tester,
  ) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.tap(find.byKey(const Key('chord-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Triads').last);
    await tester.pumpAndSettle();

    NotationPainter painter() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((custom) => custom.painter)
        .whereType<NotationPainter>()
        .single;

    // Root position: B diminished (B D F), so the label is B.
    expect(painter().labelStep, 4);
    expect(painter().labelNoteName, 'B');

    await tester.ensureVisible(find.text('1st'));
    await tester.tap(find.text('1st'));
    await tester.pumpAndSettle();
    expect(painter().labelStep, 6);
    expect(painter().labelNoteName, 'D');

    await tester.ensureVisible(find.text('2nd'));
    await tester.tap(find.text('2nd'));
    await tester.pumpAndSettle();
    expect(painter().labelStep, 8);
    expect(painter().labelNoteName, 'F');
  });

  testWidgets('a progression exposes chips that move the note', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.tap(find.byKey(const Key('chord-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Triads').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('progression-label')));
    await tester.tap(find.byKey(const Key('progression-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pop \u2013 I V vi IV').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('prog-0')), findsOneWidget);

    // The default note is B4 (degree 7); the I chip moves it to C5.
    await tester.ensureVisible(find.byKey(const Key('prog-0')));
    await tester.tap(find.byKey(const Key('prog-0')));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('note-name'))).data, 'C5');
  });

  testWidgets('a long progression stays on one horizontal row', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.tap(find.byKey(const Key('chord-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Triads').last);
    await tester.pumpAndSettle();

    Future<void> choose(String name) async {
      await tester.ensureVisible(find.byKey(const Key('progression-label')));
      await tester.tap(find.byKey(const Key('progression-label')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }

    await choose('Pop \u2013 I V vi IV');
    final popHeight = tester
        .getSize(find.byKey(const Key('progression-chips')))
        .height;

    await choose('Canon \u2013 I V vi iii IV I IV V');
    expect(find.byKey(const Key('prog-7')), findsOneWidget);
    final canonHeight = tester
        .getSize(find.byKey(const Key('progression-chips')))
        .height;

    expect(
      tester
          .widget<SingleChildScrollView>(
            find.byKey(const Key('progression-chips')),
          )
          .scrollDirection,
      Axis.horizontal,
    );
    // Eight chips must not wrap onto a second row.
    expect(canonHeight, popHeight);
  });

  testWidgets('turning chords off clears the progression', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.tap(find.byKey(const Key('chord-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Triads').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('progression-label')));
    await tester.tap(find.byKey(const Key('progression-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pop \u2013 I V vi IV').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('progression-chips')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chord-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Off').last);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('progression-chips')), findsNothing);
    expect(find.byKey(const Key('progression-label')), findsNothing);

    // Re-enabling the lab does not resurrect the cleared progression.
    await tester.tap(find.byKey(const Key('chord-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Triads').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('progression-chips')), findsNothing);
  });

  testWidgets('switching progressions does not jump the controls rail', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('chord-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sevenths').last);
    await tester.pumpAndSettle();

    Future<void> choose(String name) async {
      await tester.tap(find.byKey(const Key('progression-label')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(name).last);
      await tester.pumpAndSettle();
    }

    void scrollToBottom() {
      final scrollable = find.descendant(
        of: find.byKey(const Key('controls')),
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(scrollable.first).position;
      position.jumpTo(position.maxScrollExtent);
    }

    await choose('Canon \u2013 I V vi iii IV I IV V');
    scrollToBottom();
    await tester.pumpAndSettle();
    final before = tester.getTopLeft(find.byKey(const Key('scale-label'))).dy;

    await choose('Pop \u2013 I V vi IV');
    final after = tester.getTopLeft(find.byKey(const Key('scale-label'))).dy;

    // The chip area reserves the tallest progression, so no scroll clamp
    // shoves the controls above it when a shorter progression is selected.
    expect(after, before);
  });

  testWidgets('the staff size does not jump when controls change', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.pumpAndSettle();

    final baseline = tester.getSize(find.byType(StaffView)).height;

    for (final clef in ['Bass', 'Alto', 'Treble']) {
      await tester.tap(find.text(clef));
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(StaffView)).height,
        baseline,
        reason: '$clef clef resized the staff',
      );
    }

    await tester.tap(find.byKey(const Key('key-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('G major').last);
    await tester.pumpAndSettle();

    for (var i = 0; i < 10; i++) {
      await tester.tap(find.byTooltip('Higher'));
      await tester.pumpAndSettle();
    }
    expect(
      tester.getSize(find.byType(StaffView)).height,
      baseline,
      reason: 'changing the note resized the staff',
    );

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('the guided path starts on the first lesson', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    expect(find.byKey(const Key('guided-panel')), findsNothing);

    await tester.tap(find.byTooltip('Practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guided path'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('guided-panel')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('guided-lesson'))).data,
      contains('The five lines'),
    );
    expect(tester.widget<StaffView>(find.byType(StaffView)).step, 4);

    await tester.tap(find.byKey(const Key('guided-next')));
    await tester.pumpAndSettle();
    expect(tester.widget<StaffView>(find.byType(StaffView)).step, 2);

    await tester.tap(find.byKey(const Key('guided-exit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('guided-panel')), findsNothing);
    expect(find.byKey(const Key('controls')), findsOneWidget);
  });

  testWidgets('a practice step unlocks Next when the note reaches the target', (
    tester,
  ) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.tap(find.byTooltip('Practice'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Guided path'));
    await tester.pumpAndSettle();

    // Three explanation steps, then the first practice step.
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('guided-next')));
      await tester.pumpAndSettle();
    }

    FilledButton next() =>
        tester.widget<FilledButton>(find.byKey(const Key('guided-next')));

    expect(tester.widget<StaffView>(find.byType(StaffView)).step, 6);
    expect(find.byKey(const Key('guided-status')), findsOneWidget);
    expect(next().onPressed, isNull);

    // Drag the note down to the middle line by tapping the staff there.
    final rect = tester.getRect(find.byType(StaffView));
    final geometry = StaffGeometry.forSize(rect.size);
    await tester.tapAt(Offset(rect.center.dx, rect.top + geometry.yForStep(4)));
    await tester.pumpAndSettle();

    expect(tester.widget<StaffView>(find.byType(StaffView)).step, 4);
    expect(next().onPressed, isNotNull);
    expect(
      tester.widget<Text>(find.byKey(const Key('guided-status'))).data,
      contains('Well done'),
    );
  });

  testWidgets('the dark theme renders the staff', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    await tester.tap(find.byTooltip('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(StaffView), findsOneWidget);
  });

  testWidgets('the play button plays the current note', (tester) async {
    final player = _RecordingNotePlayer();
    await tester.pumpWidget(WhatIsThisNoteApp(notePlayer: player));

    await tester.tap(find.byKey(const Key('play-note')));
    await tester.pump();

    // The default note is B4 (MIDI 71, A4 == 440 Hz).
    expect(player.played, hasLength(1));
    expect(player.played.single, hasLength(1));
    expect(player.played.single.single, closeTo(493.883, 0.01));
  });

  testWidgets('the play button plays the chord when the chord lab is on', (
    tester,
  ) async {
    final player = _RecordingNotePlayer();
    await tester.pumpWidget(WhatIsThisNoteApp(notePlayer: player));
    await tester.tap(find.byKey(const Key('chord-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Triads').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('play-note')));
    await tester.pump();

    // B diminished (B D F), voiced low to high.
    expect(player.played.single, hasLength(3));
    final frequencies = player.played.single;
    expect(frequencies[0], lessThan(frequencies[1]));
    expect(frequencies[1], lessThan(frequencies[2]));
  });

  testWidgets('the highlight play button plays the scale note by note', (
    tester,
  ) async {
    final player = _RecordingNotePlayer();
    await tester.pumpWidget(WhatIsThisNoteApp(notePlayer: player));

    await tester.tap(find.byKey(const Key('scale-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Major').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('play-highlight')));
    await tester.pump();

    // The C major scale, ascending C4 to B4 and closing on C5.
    expect(player.played, hasLength(1));
    expect(player.played.first.single, closeTo(261.63, 0.01));
    final firstPiano = tester.widget<PianoKeyboard>(find.byType(PianoKeyboard));
    expect(firstPiano.playingPitchClass, 0);
    expect(firstPiano.playingUpperOctave, isFalse);

    for (var i = 0; i < 7; i++) {
      await tester.pump(const Duration(milliseconds: 450));
    }
    expect(player.played, hasLength(8));
    expect(player.played.last.single, closeTo(523.25, 0.01)); // C5
    final lastPiano = tester.widget<PianoKeyboard>(find.byType(PianoKeyboard));
    expect(lastPiano.playingPitchClass, 0);
    expect(lastPiano.playingUpperOctave, isTrue);

    // The sequence ends on its own and does not loop.
    await tester.pump(const Duration(seconds: 2));
    expect(player.played, hasLength(8));
    expect(
      tester
          .widget<PianoKeyboard>(find.byType(PianoKeyboard))
          .playingPitchClass,
      isNull,
    );
  });

  testWidgets('the progression play button plays the chords in order', (
    tester,
  ) async {
    final player = _RecordingNotePlayer();
    await tester.pumpWidget(WhatIsThisNoteApp(notePlayer: player));

    await tester.tap(find.byKey(const Key('chord-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Triads').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('progression-label')));
    await tester.tap(find.byKey(const Key('progression-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(kProgressions.first.name).last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('play-progression')));
    await tester.tap(find.byKey(const Key('play-progression')));
    await tester.pump();

    // The pop progression opens on I: the note moves to C5 and C E G sounds.
    expect(player.played, hasLength(1));
    expect(player.played.single, hasLength(3));
    expect(tester.widget<Text>(find.byKey(const Key('note-name'))).data, 'C5');
    // The chip for the chord that is sounding is emphasised.
    expect(
      tester
          .widget<ActionChip>(find.byKey(const Key('prog-0')))
          .backgroundColor,
      isNotNull,
    );

    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 450));
    }
    expect(player.played, hasLength(kProgressions.first.degrees.length));
    expect(player.played.every((chord) => chord.length == 3), isTrue);
    // When the sequence ends the emphasis is cleared.
    expect(
      tester
          .widget<ActionChip>(find.byKey(const Key('prog-0')))
          .backgroundColor,
      isNull,
    );
  });

  testWidgets('pressing the play button again stops the sequence', (
    tester,
  ) async {
    final player = _RecordingNotePlayer();
    await tester.pumpWidget(WhatIsThisNoteApp(notePlayer: player));

    await tester.tap(find.byKey(const Key('scale-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Major').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('play-highlight')));
    await tester.pump();
    expect(player.played, hasLength(1));

    // The button becomes a stop control; pressing it halts the sequence.
    await tester.tap(find.byKey(const Key('play-highlight')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(player.played, hasLength(1));
  });

  testWidgets('dragging the staff stops the running sequence', (tester) async {
    final player = _RecordingNotePlayer();
    await tester.pumpWidget(WhatIsThisNoteApp(notePlayer: player));

    await tester.tap(find.byKey(const Key('scale-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Major').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('play-highlight')));
    await tester.pump();
    expect(player.played, hasLength(1));

    // Moving the note halts playback so the scale cannot jump octaves.
    await tester.drag(find.byType(StaffView), const Offset(0, -60));
    await tester.pump(const Duration(seconds: 2));
    expect(player.played, hasLength(1));
  });

  testWidgets('display settings switch the naming system', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    await tester.tap(find.byKey(const Key('display-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Solfege'));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(const Key('note-name'))).data, 'Si');
    expect(tester.widget<Text>(find.byKey(const Key('note-pitch'))).data, 'B4');
    final painter = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .map((custom) => custom.painter)
        .whereType<NotationPainter>()
        .single;
    expect(painter.labelNoteName, 'Si');
  });

  testWidgets('display settings hide the on-staff note name', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());
    expect(tester.widget<StaffView>(find.byType(StaffView)).showLabel, isTrue);

    await tester.tap(find.byKey(const Key('display-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggle-staff-label')));
    await tester.pumpAndSettle();

    expect(tester.widget<StaffView>(find.byType(StaffView)).showLabel, isFalse);
  });

  testWidgets('enharmonic equivalent shows the twin spelling', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    await tester.tap(find.byKey(const Key('key-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('G major').last);
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byTooltip('Higher'));
      await tester.pumpAndSettle();
    }
    expect(
      tester.widget<Text>(find.byKey(const Key('note-name'))).data,
      'F\u266F5',
    );
    expect(find.byKey(const Key('note-enharmonic')), findsNothing);

    await tester.tap(find.byKey(const Key('display-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('toggle-enharmonic')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('note-enharmonic'))).data,
      '\u2248 G\u266D5',
    );
  });

  testWidgets('the readout reserves room for a sharp or flat', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    // F5 in C major: natural, but the readout reserves an accidental glyph.
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byTooltip('Higher'));
      await tester.pumpAndSettle();
    }
    expect(tester.widget<Text>(find.byKey(const Key('note-name'))).data, 'F5');
    final natural = _readoutRight(tester);
    expect(find.byKey(const Key('note-name-reserve')), findsOneWidget);

    // The same staff position in G major is F♯5, one glyph wider.
    await tester.tap(find.byKey(const Key('key-label')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('G major').last);
    await tester.pumpAndSettle();
    expect(
      tester.widget<Text>(find.byKey(const Key('note-name'))).data,
      'F\u266F5',
    );
    final accidental = _readoutRight(tester);

    // The reserved glyph exactly offsets the accidental, so nothing shifts.
    expect(accidental, closeTo(natural, 0.5));
  });

  testWidgets('the first-run coach mark shows once and can be dismissed', (
    tester,
  ) async {
    final store = InMemoryOnboardingStore(seen: false);
    await tester.pumpWidget(WhatIsThisNoteApp(onboardingStore: store));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-coach')), findsOneWidget);
    expect(store.seen, isFalse);

    await tester.tap(find.byKey(const Key('onboarding-dismiss')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-coach')), findsNothing);
    expect(store.seen, isTrue);
  });

  testWidgets('the coach mark does not block dragging the note', (
    tester,
  ) async {
    final store = InMemoryOnboardingStore(seen: false);
    await tester.pumpWidget(WhatIsThisNoteApp(onboardingStore: store));
    await tester.pumpAndSettle();

    final staff = tester.getRect(find.byType(StaffView));
    await tester.dragFrom(staff.center, const Offset(0, -80));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('note-name'))).data,
      isNot('B4'),
    );
    expect(find.byKey(const Key('onboarding-coach')), findsOneWidget);
  });

  testWidgets('no coach mark once it has been seen', (tester) async {
    await tester.pumpWidget(
      WhatIsThisNoteApp(onboardingStore: InMemoryOnboardingStore()),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('onboarding-coach')), findsNothing);
  });

  testWidgets('a narrow large-text layout does not overflow', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.4;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('display-settings')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a small window scrolls the controls to grow the staff', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.pumpAndSettle();

    // The panel scrolls instead of squeezing the notation into a thin strip.
    final controls = find.byKey(const Key('controls'));
    final scrollable = find.descendant(
      of: controls,
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      greaterThan(0),
      reason: 'the controls should scroll to leave the staff more room',
    );

    final baseline = tester.getSize(find.byType(StaffView)).height;
    expect(
      baseline,
      greaterThan(tester.getSize(controls).height * 0.5),
      reason: 'the staff should get the larger share of a small window',
    );

    for (var i = 0; i < 12; i++) {
      await tester.dragFrom(
        tester.getRect(find.byType(StaffView)).center,
        const Offset(0, -10),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(StaffView)).height,
        baseline,
        reason: 'dragging the note resized the staff',
      );
    }
  });

  testWidgets('display preferences are restored on start', (tester) async {
    final store = InMemoryDisplayPreferencesStore(
      preferences: const DisplayPreferences(naming: NamingSystem.solfege),
    );

    await tester.pumpWidget(WhatIsThisNoteApp(displayPreferencesStore: store));
    await tester.pumpAndSettle();

    expect(tester.widget<Text>(find.byKey(const Key('note-name'))).data, 'Si');
  });

  testWidgets('changing display preferences saves them', (tester) async {
    final store = InMemoryDisplayPreferencesStore();

    await tester.pumpWidget(WhatIsThisNoteApp(displayPreferencesStore: store));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('display-settings')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Numbered'));
    await tester.pumpAndSettle();

    expect((await store.load()).naming, NamingSystem.jianpu);
  });

  testWidgets('the staff exposes the note to assistive tech', (tester) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.pumpAndSettle();

    final staff = find.bySemanticsLabel('Note staff');
    expect(staff, findsOneWidget);
    final data = tester.getSemantics(staff).getSemanticsData();
    expect(data.value, 'B4');
    expect(data.hasAction(SemanticsAction.increase), isTrue);
    expect(data.hasAction(SemanticsAction.decrease), isTrue);

    handle.dispose();
  });

  testWidgets('practice mode does not announce the note answer', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();

    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Practice'));
    await tester.pumpAndSettle();

    final data = tester
        .getSemantics(find.bySemanticsLabel('Note staff'))
        .getSemanticsData();
    expect(data.value, isEmpty);

    handle.dispose();
  });

  testWidgets('arrow keys nudge the note on a keyboard', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('note-name'))).data, 'C5');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.byKey(const Key('note-name'))).data, 'B4');
  });

  testWidgets('reduce motion snaps the note without animating', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);

    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(_paintedStep(tester), 5.0);
  });

  testWidgets('the snap animates by default', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();

    expect(_paintedStep(tester), lessThan(5.0));
  });

  testWidgets('space plays the current note', (tester) async {
    final player = _RecordingNotePlayer();
    await tester.pumpWidget(WhatIsThisNoteApp(notePlayer: player));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();

    // The default note is B4 (MIDI 71, A4 == 440 Hz).
    expect(player.played, hasLength(1));
    expect(player.played.single, hasLength(1));
    expect(player.played.single.single, closeTo(493.883, 0.01));
  });

  testWidgets('a wide window packs the controls and grows the staff', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(600, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const WhatIsThisNoteApp());
    await tester.pumpAndSettle();
    final narrowStaff = tester.getSize(find.byType(StaffView)).height;

    await tester.binding.setSurfaceSize(const Size(900, 600));
    await tester.pumpAndSettle();
    final wideStaff = tester.getSize(find.byType(StaffView)).height;

    expect(wideStaff, greaterThan(narrowStaff));

    final scrollable = find.descendant(
      of: find.byKey(const Key('controls')),
      matching: find.byType(Scrollable),
    );
    expect(
      tester.state<ScrollableState>(scrollable).position.maxScrollExtent,
      0,
      reason: 'the compact controls should not need to scroll',
    );
  });
}

/// Right edge of the primary note-name slot, including the transparent
/// accidental reserve when the note is natural.
double _readoutRight(WidgetTester tester) {
  var right = tester.getRect(find.byKey(const Key('note-name'))).right;
  final reserve = find.byKey(const Key('note-name-reserve'));
  if (reserve.evaluate().isNotEmpty) {
    right = tester.getRect(reserve).right;
  }
  return right;
}

double _paintedStep(WidgetTester tester) {
  final painter = tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .map((paint) => paint.painter)
      .whereType<NotationPainter>()
      .first;
  return painter.step;
}

class _RecordingNotePlayer implements NotePlayer {
  final List<List<double>> played = [];
  final List<({List<double> clicks, Duration beat})> clickTracks = [];
  int clickStops = 0;

  @override
  Future<void> play(Iterable<double> frequencies, {Duration? duration}) async {
    played.add(frequencies.toList(growable: false));
  }

  @override
  Future<void> startClickTrack(List<double> clicks, Duration beat) async {
    clickTracks.add((clicks: clicks.toList(growable: false), beat: beat));
  }

  @override
  Future<void> stopClickTrack() async {
    clickStops++;
  }

  @override
  Future<void> dispose() async {}
}
