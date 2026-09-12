import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatisthisnote/core/clef.dart';
import 'package:whatisthisnote/core/note.dart';
import 'package:whatisthisnote/core/staff_geometry.dart';

void main() {
  group('Note', () {
    test('maps letters and octaves to a diatonic index', () {
      expect(Note.fromLetter(NoteLetter.c, 4).diatonicIndex, 28);
      expect(Note.fromLetter(NoteLetter.b, 3).diatonicIndex, 27);
      expect(Note.fromLetter(NoteLetter.e, 4).name, 'E4');
    });

    test('computes scientific names', () {
      expect(Note.fromLetter(NoteLetter.c, 4).name, 'C4');
      expect(Note.fromLetter(NoteLetter.b, 3).name, 'B3');
      expect(Note(27).name, 'B3');
    });

    test('computes solfege names', () {
      expect(Note.fromLetter(NoteLetter.c, 4).solfege, 'Do');
      expect(Note.fromLetter(NoteLetter.e, 4).solfege, 'Mi');
      expect(Note.fromLetter(NoteLetter.b, 3).solfege, 'Si');
    });

    test('computes MIDI numbers and frequencies', () {
      expect(Note.fromLetter(NoteLetter.c, 4).midi, 60);
      expect(Note.fromLetter(NoteLetter.a, 4).midi, 69);
      expect(Note.fromLetter(NoteLetter.a, 4).frequency, closeTo(440, 0.0001));
      expect(
        Note.fromLetter(NoteLetter.c, 4).frequency,
        closeTo(261.6256, 0.001),
      );
    });

    test('transposes and compares', () {
      expect(Note(27).transpose(1), Note.fromLetter(NoteLetter.c, 4));
      expect(Note(27).compareTo(Note(28)) < 0, isTrue);
    });
  });

  group('Clef', () {
    test('treble maps steps to notes', () {
      expect(Clef.treble.noteAt(0).name, 'E4');
      expect(Clef.treble.noteAt(4).name, 'B4');
      expect(Clef.treble.noteAt(8).name, 'F5');
      expect(Clef.treble.noteAt(-2).name, 'C4');
      expect(Clef.treble.noteAt(10).name, 'A5');
    });

    test('bass maps steps to notes', () {
      expect(Clef.bass.noteAt(0).name, 'G2');
      expect(Clef.bass.noteAt(4).name, 'D3');
      expect(Clef.bass.noteAt(6).name, 'F3');
      expect(Clef.bass.noteAt(8).name, 'A3');
    });

    test('alto maps steps to notes', () {
      expect(Clef.alto.noteAt(0).name, 'F3');
      expect(Clef.alto.noteAt(4).name, 'C4');
      expect(Clef.alto.noteAt(8).name, 'G4');
    });

    test('stepOf is the inverse of noteAt', () {
      for (final clef in Clef.values) {
        for (var step = -4; step <= 12; step++) {
          expect(clef.stepOf(clef.noteAt(step)), step);
        }
      }
    });
  });

  group('StaffGeometry', () {
    const geometry = StaffGeometry(
      size: Size(400, 800),
      space: 20,
      staffLeft: 20,
      staffRight: 380,
    );

    test('places the bottom and top lines symmetrically', () {
      expect(geometry.yForStep(0) - geometry.yForStep(8), closeTo(80, 1e-9));
    });

    test('stepForY is the inverse of yForStep', () {
      for (var step = -6; step <= 14; step++) {
        expect(geometry.stepForY(geometry.yForStep(step)), closeTo(step, 1e-9));
      }
    });

    test('no ledger lines are needed inside the staff', () {
      for (var step = -1; step <= 9; step++) {
        expect(geometry.ledgerStepsFor(step), isEmpty);
      }
    });

    test('ledger lines appear above the staff', () {
      expect(geometry.ledgerStepsFor(10), [10]);
      expect(geometry.ledgerStepsFor(11), [10]);
      expect(geometry.ledgerStepsFor(13), [10, 12]);
    });

    test('ledger lines appear below the staff', () {
      expect(geometry.ledgerStepsFor(-2), [-2]);
      expect(geometry.ledgerStepsFor(-3), [-2]);
      expect(geometry.ledgerStepsFor(-5), [-2, -4]);
    });

    test('clamps steps to the draggable range', () {
      expect(geometry.clampStep(-100), kMinStaffStep);
      expect(geometry.clampStep(100), kMaxStaffStep);
    });
  });
}
