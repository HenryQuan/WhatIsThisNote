import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatisthisnote/core/accidental.dart';
import 'package:whatisthisnote/core/clef.dart';
import 'package:whatisthisnote/core/key.dart';
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

    test('computes numbered notation degrees', () {
      expect(Note.fromLetter(NoteLetter.c, 4).degree, 1);
      expect(Note.fromLetter(NoteLetter.g, 4).degree, 5);
      expect(Note.fromLetter(NoteLetter.b, 3).degree, 7);
    });

    test('pitch names omit the octave but keep the accidental', () {
      expect(Note.fromLetter(NoteLetter.g, 4).pitchName, 'G');
      final fSharp = Note.fromLetter(NoteLetter.f, 4)
          .withAccidental(Accidental.sharp);
      expect(fSharp.pitchName, 'F\u266F');
      expect(fSharp.name, 'F\u266F4');
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

  group('Key', () {
    final cMajor = kMajorKeys[0];
    final gMajor = MusicalKey('G', KeyMode.major, 1);
    final fMajor = MusicalKey('F', KeyMode.major, -1);
    final eMinor = MusicalKey('E', KeyMode.minor, 1);

    test('provides fifteen major and fifteen minor keys', () {
      expect(kMajorKeys.length, 15);
      expect(kMinorKeys.length, 15);
      expect(kAllKeys.length, 30);
    });

    test('C major has no accidentals', () {
      for (final letter in NoteLetter.values) {
        expect(cMajor.accidentalFor(letter), Accidental.natural);
      }
      expect(cMajor.signatureLabel, 'no sharps or flats');
    });

    test('sharp keys alter letters in the order F C G D A E B', () {
      expect(gMajor.accidentalFor(NoteLetter.f), Accidental.sharp);
      expect(gMajor.accidentalFor(NoteLetter.c), Accidental.natural);
      expect(gMajor.signatureLabel, '1 sharp');

      final dMajor = MusicalKey('D', KeyMode.major, 2);
      expect(dMajor.accidentalFor(NoteLetter.f), Accidental.sharp);
      expect(dMajor.accidentalFor(NoteLetter.c), Accidental.sharp);
      expect(dMajor.accidentalFor(NoteLetter.g), Accidental.natural);

      final cSharpMajor = MusicalKey('C\u266F', KeyMode.major, 7);
      for (final letter in NoteLetter.values) {
        expect(cSharpMajor.accidentalFor(letter), Accidental.sharp);
      }
    });

    test('flat keys alter letters in the order B E A D G C F', () {
      expect(fMajor.accidentalFor(NoteLetter.b), Accidental.flat);
      expect(fMajor.accidentalFor(NoteLetter.e), Accidental.natural);
      expect(fMajor.signatureLabel, '1 flat');

      final bFlatMajor = MusicalKey('B\u266D', KeyMode.major, -2);
      expect(bFlatMajor.accidentalFor(NoteLetter.b), Accidental.flat);
      expect(bFlatMajor.accidentalFor(NoteLetter.e), Accidental.flat);
      expect(bFlatMajor.accidentalFor(NoteLetter.a), Accidental.natural);
    });

    test('minor keys use the same signatures as their relative major', () {
      expect(eMinor.accidentalFor(NoteLetter.f), Accidental.sharp);
      expect(eMinor.accidentalFor(NoteLetter.c), Accidental.natural);
    });

    test('applyTo names notes according to the key', () {
      expect(gMajor.applyTo(Clef.treble.noteAt(8)).name, 'F\u266F5');
      expect(fMajor.applyTo(Clef.treble.noteAt(8)).name, 'F5');
      expect(gMajor.applyTo(Clef.treble.noteAt(0)).name, 'E4');
      expect(gMajor.applyTo(Clef.bass.noteAt(6)).name, 'F\u266F3');
    });

    test('accidentals change the sounding pitch', () {
      final fSharp = gMajor.applyTo(Clef.treble.noteAt(8));
      expect(fSharp.midi, 78); // F#5
      expect(fSharp.isNatural, isFalse);
      expect(fSharp.withAccidental(Accidental.natural).midi, 77);
    });

    test('signature positions depend on the clef', () {
      expect(gMajor.signatureFor(Clef.treble).single.step, 8);
      expect(gMajor.signatureFor(Clef.bass).single.step, 6);
      expect(gMajor.signatureFor(Clef.alto).single.step, 7);

      expect(fMajor.signatureFor(Clef.treble).single.step, 4);
      expect(fMajor.signatureFor(Clef.bass).single.step, 2);
      expect(fMajor.signatureFor(Clef.alto).single.step, 3);
    });

    test('signatures grow in the standard order', () {
      final dMajor = MusicalKey('D', KeyMode.major, 2);
      final treble = dMajor.signatureFor(Clef.treble);
      expect(treble.map((e) => e.accidental),
          everyElement(Accidental.sharp));
      expect(treble.map((e) => e.step), [8, 5]);

      final bFlatMajor = MusicalKey('B\u266D', KeyMode.major, -2);
      expect(
        bFlatMajor.signatureFor(Clef.treble).map((e) => e.step),
        [4, 7],
      );
    });

    test('C major and A minor have empty signatures', () {
      expect(cMajor.signatureFor(Clef.treble), isEmpty);
      expect(kMinorKeys.first.signatureFor(Clef.bass), isEmpty);
    });
  });
}
