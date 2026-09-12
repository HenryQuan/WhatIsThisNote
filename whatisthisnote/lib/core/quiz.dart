import 'dart:math';

import 'accidental.dart';
import 'clef.dart';
import 'key.dart';
import 'note.dart';
import 'staff_geometry.dart';

/// One name-the-note question: a written [step] on a clef, its correct
/// [answer] and the [choices] to pick from (shuffled, including the answer).
class QuizQuestion {
  const QuizQuestion({
    required this.step,
    required this.answer,
    required this.choices,
  });

  /// Staff step of the written note.
  final int step;

  /// Correct note name without the octave, e.g. `F♯`.
  final String answer;

  /// Answer choices, shuffled, containing [answer] exactly once.
  final List<String> choices;

  /// True when [choice] is the correct answer.
  bool isCorrect(String choice) => choice == answer;
}

/// Builds random name-the-note questions for a clef and key.
///
/// Consecutive notes move around the staff in small leaps (two or three steps
/// up or down) so the learner reads the written pitch instead of anchoring on
/// one line, with an occasional free jump for variety.
class QuizBuilder {
  QuizBuilder({required this.clef, required this.key, Random? random})
    : _random = random ?? Random();

  final Clef clef;
  final MusicalKey key;
  final Random _random;

  /// Steps a question may use: the whole readable staff, from three ledger
  /// lines below to three ledger lines above (roughly three octaves).
  static final List<int> steps = [
    for (var step = kMinStaffStep; step <= kMaxStaffStep; step++) step,
  ];

  /// Number of choices shown per question.
  static const int choiceCount = 5;

  /// Smallest and largest leap, in staff steps, between two questions.
  static const int minLeap = 2;
  static const int maxLeap = 3;

  int? _lastStep;

  /// The seven note names a written note can take in this key, in letter
  /// order (C, D, E, ...), each with the key signature's accidental.
  List<String> get noteNames => [
    for (final letter in NoteLetter.values)
      '${letter.name}${_suffix(key.accidentalFor(letter))}',
  ];

  /// Builds the next question.
  QuizQuestion next() {
    final step = _pickStep();
    _lastStep = step;
    final answer = key.applyTo(clef.noteAt(step)).pitchName;
    final distractors = noteNames.where((name) => name != answer).toList()
      ..shuffle(_random);
    final choices = [answer, ...distractors.take(choiceCount - 1)]
      ..shuffle(_random);
    return QuizQuestion(step: step, answer: answer, choices: choices);
  }

  /// Picks the next staff step.
  ///
  /// The first question can be anywhere in the staff. After that the note
  /// leaps [minLeap]..[maxLeap] steps up or down and bounces off the staff
  /// edges, with an occasional free jump so every position is still reached.
  int _pickStep() {
    final anywhere = steps[_random.nextInt(steps.length)];
    final last = _lastStep;
    if (last == null || _random.nextInt(4) == 0) return anywhere;

    final leap =
        (minLeap + _random.nextInt(maxLeap - minLeap + 1)) *
        (_random.nextBool() ? 1 : -1);
    final target = last + leap;
    if (target >= steps.first && target <= steps.last) return target;
    return last - leap;
  }

  static String _suffix(Accidental accidental) =>
      accidental == Accidental.natural ? '' : accidental.text;
}
