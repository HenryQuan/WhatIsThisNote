import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whatisthisnote/audio/tone.dart';
import 'package:whatisthisnote/core/accidental.dart';
import 'package:whatisthisnote/core/chord.dart';
import 'package:whatisthisnote/core/clef.dart';
import 'package:whatisthisnote/core/key.dart';
import 'package:whatisthisnote/core/lesson.dart';
import 'package:whatisthisnote/core/note.dart';
import 'package:whatisthisnote/core/quiz.dart';
import 'package:whatisthisnote/core/scale.dart';
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
      final fSharp = Note.fromLetter(
        NoteLetter.f,
        4,
      ).withAccidental(Accidental.sharp);
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

    test('describes the notes altered by the signature', () {
      expect(cMajor.signatureNotes, '');
      expect(gMajor.signatureNotes, 'F\u266F');
      expect(fMajor.signatureNotes, 'B\u266D');
      expect(
        MusicalKey('D', KeyMode.major, 2).signatureNotes,
        'F\u266F, C\u266F',
      );
      expect(
        MusicalKey('B\u266D', KeyMode.major, -2).signatureNotes,
        'B\u266D, E\u266D',
      );
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
      expect(treble.map((e) => e.accidental), everyElement(Accidental.sharp));
      expect(treble.map((e) => e.step), [8, 5]);

      final bFlatMajor = MusicalKey('B\u266D', KeyMode.major, -2);
      expect(bFlatMajor.signatureFor(Clef.treble).map((e) => e.step), [4, 7]);
    });

    test('C major and A minor have empty signatures', () {
      expect(cMajor.signatureFor(Clef.treble), isEmpty);
      expect(kMinorKeys.first.signatureFor(Clef.bass), isEmpty);
    });
  });

  group('Scale', () {
    test('parses the tonic pitch class of a key', () {
      expect(kMajorKeys[0].tonicPitchClass, 0); // C
      MusicalKey g = MusicalKey('G', KeyMode.major, 1);
      expect(g.tonicPitchClass, 7);
      MusicalKey fSharp = MusicalKey('F\u266F', KeyMode.major, 6);
      expect(fSharp.tonicPitchClass, 6);
      MusicalKey bFlat = MusicalKey('B\u266D', KeyMode.major, -2);
      expect(bFlat.tonicPitchClass, 10);
    });

    test('major and minor scales use the diatonic set', () {
      const cMajor = Scale('C', 0, ScaleType.major);
      expect(cMajor.pitchClasses, {0, 2, 4, 5, 7, 9, 11});

      const aMinor = Scale('A', 9, ScaleType.naturalMinor);
      expect(aMinor.pitchClasses, {9, 11, 0, 2, 4, 5, 7});
    });

    test('pentatonic and blues sets include their characteristic notes', () {
      const cMajorPent = Scale('C', 0, ScaleType.majorPentatonic);
      expect(cMajorPent.pitchClasses, {0, 2, 4, 7, 9});

      const cMinorPent = Scale('C', 0, ScaleType.minorPentatonic);
      expect(cMinorPent.pitchClasses, {0, 3, 5, 7, 10});

      const cBlues = Scale('C', 0, ScaleType.blues);
      expect(cBlues.pitchClasses, {0, 3, 5, 6, 7, 10});
    });

    test('transposes to any tonic', () {
      const gBlues = Scale('G', 7, ScaleType.blues);
      expect(gBlues.pitchClasses, {7, 10, 0, 1, 2, 5});
      expect(gBlues.contains(Note.fromLetter(NoteLetter.g, 4).midi), isTrue);
      expect(gBlues.contains(Note.fromLetter(NoteLetter.c, 5).midi), isTrue);
      expect(gBlues.contains(Note.fromLetter(NoteLetter.b, 4).midi), isFalse);
    });

    test('reports scale degrees and notes outside the scale', () {
      const cBlues = Scale('C', 0, ScaleType.blues);
      final eFlat = Note.fromLetter(
        NoteLetter.e,
        4,
      ).withAccidental(Accidental.flat);
      expect(cBlues.degreeLabelFor(eFlat.midi), '\u266D3');
      expect(cBlues.degreeLabelFor(Note.fromLetter(NoteLetter.f, 4).midi), '4');
      expect(
        cBlues.degreeLabelFor(
          Note.fromLetter(
            NoteLetter.f,
            4,
          ).withAccidental(Accidental.sharp).midi,
        ),
        '\u266D5',
      );
      expect(
        cBlues.degreeLabelFor(Note.fromLetter(NoteLetter.d, 4).midi),
        isNull,
      );
      expect(cBlues.label, 'C Blues');
    });

    test('harmonic and melodic minor differ on the sixth and seventh', () {
      const harmonic = Scale('C', 0, ScaleType.harmonicMinor);
      expect(harmonic.pitchClasses, {0, 2, 3, 5, 7, 8, 11});

      const melodic = Scale('C', 0, ScaleType.melodicMinor);
      expect(melodic.pitchClasses, {0, 2, 3, 5, 7, 9, 11});
    });
  });

  group('Chord', () {
    const cMajor = Scale('C', 0, ScaleType.major);

    test('builds the diatonic triads of a major key', () {
      final chords = [
        for (var degree = 1; degree <= 7; degree++)
          Chord.diatonic(cMajor, degree),
      ];
      expect(chords.map((c) => c.symbol), [
        'C',
        'Dm',
        'Em',
        'F',
        'G',
        'Am',
        'Bdim',
      ]);
      expect(chords.map((c) => c.romanNumeral), [
        'I',
        'ii',
        'iii',
        'IV',
        'V',
        'vi',
        'vii\u00B0',
      ]);
      expect(chords[0].quality, ChordQuality.major);
      expect(chords[1].quality, ChordQuality.minor);
      expect(chords[6].quality, ChordQuality.diminished);
    });

    test('builds the diatonic seventh chords of a major key', () {
      final chords = [
        for (var degree = 1; degree <= 7; degree++)
          Chord.diatonic(cMajor, degree, seventh: true),
      ];
      expect(chords.map((c) => c.symbol), [
        'Cmaj7',
        'Dm7',
        'Em7',
        'Fmaj7',
        'G7',
        'Am7',
        'Bm7\u266D5',
      ]);
      expect(chords.map((c) => c.romanNumeral), [
        'Imaj7',
        'ii7',
        'iii7',
        'IVmaj7',
        'V7',
        'vi7',
        'vii\u00F87',
      ]);
      expect(chords[4].quality, ChordQuality.dominantSeventh);
      expect(chords[4].pitchClasses, [7, 11, 2, 5]);
      expect(chords[6].quality, ChordQuality.halfDiminishedSeventh);
    });

    test('rotates the chord tones for inversions', () {
      final c = Chord.diatonic(cMajor, 1);
      expect(c.pitchClasses, [0, 4, 7]);
      expect(c.displaySymbol, 'C');

      final first = Chord.diatonic(cMajor, 1, inversion: 1);
      expect(first.pitchClasses, [4, 7, 0]);
      expect(first.bassName, 'E');
      expect(first.displaySymbol, 'C/E');
      expect(first.inversionLabel, '1st inversion');

      final second = Chord.diatonic(cMajor, 1, inversion: 2);
      expect(second.pitchClasses, [7, 0, 4]);
      expect(second.bassName, 'G');
      expect(second.displaySymbol, 'C/G');
    });

    test('voices the chord as staff steps', () {
      final c = Chord.diatonic(cMajor, 1);
      expect(c.staffSteps(4), [4, 6, 8]);
      expect(Chord.diatonic(cMajor, 1, inversion: 1).staffSteps(4), [6, 8, 11]);
      expect(Chord.diatonic(cMajor, 1, inversion: 2).staffSteps(4), [
        8,
        11,
        13,
      ]);
    });

    test('uses flat numerals in minor keys', () {
      const aMinor = Scale('A', 9, ScaleType.naturalMinor);
      expect(Chord.diatonic(aMinor, 1).romanNumeral, 'i');
      expect(Chord.diatonic(aMinor, 3).romanNumeral, '\u266DIII');
      expect(Chord.diatonic(aMinor, 7).romanNumeral, '\u266DVII');
    });

    test('lists playable progressions', () {
      expect(kProgressions, isNotEmpty);
      expect(kProgressions.first.degrees, [1, 5, 6, 4]);
    });
  });

  group('Quiz', () {
    test('builds distinct choices that include the answer', () {
      final builder = QuizBuilder(
        clef: Clef.treble,
        key: kMajorKeys.first,
        random: Random(1),
      );
      for (var i = 0; i < 50; i++) {
        final question = builder.next();
        expect(QuizBuilder.steps, contains(question.step));
        expect(question.choices.length, QuizBuilder.choiceCount);
        expect(question.choices.toSet().length, QuizBuilder.choiceCount);
        expect(question.choices, contains(question.answer));
        expect(question.isCorrect(question.answer), isTrue);
        for (final choice in question.choices) {
          if (choice != question.answer) {
            expect(question.isCorrect(choice), isFalse);
          }
        }
      }
    });

    test('uses the key signature accidentals in the choices', () {
      final builder = QuizBuilder(
        clef: Clef.treble,
        key: MusicalKey('G', KeyMode.major, 1),
        random: Random(2),
      );
      expect(builder.noteNames, contains('F\u266F'));
      expect(builder.noteNames, isNot(contains('F')));
    });

    test('reads the answer with the clef', () {
      final treble = QuizBuilder(
        clef: Clef.treble,
        key: kMajorKeys.first,
        random: Random(3),
      );
      final bass = QuizBuilder(
        clef: Clef.bass,
        key: kMajorKeys.first,
        random: Random(3),
      );
      final trebleQuestion = treble.next();
      final bassQuestion = bass.next();
      expect(trebleQuestion.step, bassQuestion.step);
      expect(
        trebleQuestion.answer,
        Clef.treble.noteAt(trebleQuestion.step).pitchName,
      );
      expect(
        bassQuestion.answer,
        Clef.bass.noteAt(bassQuestion.step).pitchName,
      );
    });
  });

  group('Lesson', () {
    test('has well formed steps', () {
      expect(kLessons, isNotEmpty);
      for (final lesson in kLessons) {
        expect(lesson.title, isNotEmpty);
        expect(lesson.steps, isNotEmpty);
        expect(
          lesson.steps.any((step) => step.isPractice),
          isTrue,
          reason: '${lesson.title} needs at least one practice step',
        );
        for (final step in lesson.steps) {
          expect(step.title, isNotEmpty);
          expect(step.instruction, isNotEmpty);
          expect(step.step, inInclusiveRange(kMinStaffStep, kMaxStaffStep));
          if (step.isPractice) {
            expect(step.targetStep, isNotNull);
            expect(step.targetStep, isNot(step.step));
            expect(
              step.targetStep,
              inInclusiveRange(kMinStaffStep, kMaxStaffStep),
            );
          } else {
            expect(step.targetStep, isNull);
          }
        }
      }
    });
  });

  group('Tone', () {
    test('renders a valid 16-bit mono WAV', () {
      final bytes = toneWav(
        [440.0],
        duration: const Duration(milliseconds: 125),
        sampleRate: 8000,
      );
      final data = ByteData.sublistView(bytes);
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
      expect(String.fromCharCodes(bytes.sublist(12, 16)), 'fmt ');
      expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');
      expect(data.getUint32(4, Endian.little), bytes.length - 8);
      expect(data.getUint16(20, Endian.little), 1); // PCM
      expect(data.getUint16(22, Endian.little), 1); // mono
      expect(data.getUint32(24, Endian.little), 8000);
      expect(data.getUint16(34, Endian.little), 16); // bits per sample
      expect(data.getUint32(40, Endian.little), 2000); // 8000 * 0.125 * 2
      expect(bytes.length, 44 + 2000);
    });

    test('renders silence when there is nothing to play', () {
      final bytes = toneWav(
        const [],
        duration: const Duration(milliseconds: 10),
        sampleRate: 8000,
      );
      final data = ByteData.sublistView(bytes);
      for (var i = 44; i < bytes.length; i += 2) {
        expect(data.getInt16(i, Endian.little), 0);
      }
    });

    test('mixes every frequency into the samples', () {
      final one = toneWav(
        [440.0],
        duration: const Duration(milliseconds: 50),
        sampleRate: 8000,
      );
      final two = toneWav(
        [440.0, 660.0],
        duration: const Duration(milliseconds: 50),
        sampleRate: 8000,
      );
      expect(two.length, one.length);
      final a = ByteData.sublistView(one);
      final b = ByteData.sublistView(two);
      var differs = false;
      for (var i = 44; i < one.length; i += 2) {
        if (a.getInt16(i, Endian.little) != b.getInt16(i, Endian.little)) {
          differs = true;
          break;
        }
      }
      expect(differs, isTrue);
    });
  });
}
