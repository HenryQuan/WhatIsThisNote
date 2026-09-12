import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatisthisnote/main.dart';
import 'package:whatisthisnote/ui/widgets/piano_keyboard.dart';
import 'package:whatisthisnote/ui/widgets/staff_view.dart';

void main() {
  testWidgets('shows the default treble middle line note', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    expect(
      tester.widget<Text>(find.byKey(const Key('note-name'))).data,
      'B4',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('note-solfege'))).data,
      'Si',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('note-degree'))).data,
      '7',
    );
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

    expect(
      tester.widget<Text>(find.byKey(const Key('note-name'))).data,
      'C5',
    );
  });

  testWidgets('switching clef changes the note name', (tester) async {
    await tester.pumpWidget(const WhatIsThisNoteApp());

    await tester.tap(find.text('Bass'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('note-name'))).data,
      'D3',
    );
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

  testWidgets('selecting a key applies its signature to the note',
      (tester) async {
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

  testWidgets('scale highlight is off by default and can be enabled',
      (tester) async {
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
    expect(
      tester.widget<Text>(find.byKey(const Key('note-degree'))).data,
      '1',
    );
  });

  testWidgets('the staff size does not jump when controls change',
      (tester) async {
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
}
