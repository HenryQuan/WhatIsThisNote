import 'dart:math';

import 'accidental.dart';
import 'clef.dart';
import 'key.dart';
import 'note.dart';

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
class QuizBuilder {
  QuizBuilder({required this.clef, required this.key, Random? random})
    : _random = random ?? Random();

  final Clef clef;
  final MusicalKey key;
  final Random _random;

  /// Steps a question may use, kept inside the staff for readability.
  static const List<int> steps = [0, 1, 2, 3, 4, 5, 6, 7, 8];

  /// Number of choices shown per question.
  static const int choiceCount = 4;

  /// The seven note names a written note can take in this key, in letter
  /// order (C, D, E, ...), each with the key signature's accidental.
  List<String> get noteNames => [
    for (final letter in NoteLetter.values)
      '${letter.name}${_suffix(key.accidentalFor(letter))}',
  ];

  /// Builds the next question.
  QuizQuestion next() {
    final step = steps[_random.nextInt(steps.length)];
    final answer = key.applyTo(clef.noteAt(step)).pitchName;
    final distractors = noteNames.where((name) => name != answer).toList()
      ..shuffle(_random);
    final choices = [answer, ...distractors.take(choiceCount - 1)]
      ..shuffle(_random);
    return QuizQuestion(step: step, answer: answer, choices: choices);
  }

  static String _suffix(Accidental accidental) =>
      accidental == Accidental.natural ? '' : accidental.text;
}
