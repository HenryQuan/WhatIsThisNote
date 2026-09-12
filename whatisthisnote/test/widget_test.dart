import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatisthisnote/main.dart';
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
}
