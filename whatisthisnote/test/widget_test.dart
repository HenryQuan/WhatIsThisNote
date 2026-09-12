import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    await tester.tap(find.byTooltip('Guided path'));
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
    await tester.tap(find.byTooltip('Guided path'));
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
}
