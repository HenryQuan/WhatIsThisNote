import 'chord.dart';
import 'chord_finder.dart';
import 'note.dart';

/// A chord name that spells out how the staff deviates from the closest shape:
/// the tones it adds and the chord tones it leaves out.
class ChordName {
  const ChordName({
    required this.symbol,
    required this.added,
    required this.missing,
  });

  /// Symbol with added tones merged in and omissions in parentheses, e.g.
  /// `Cadd9`, `Cadd9\u266F11` or `C7(no5)`.
  final String symbol;

  /// Tones on the staff the closest shape does not use.
  final List<ChordTone> added;

  /// Chord tones the staff leaves out.
  final List<ChordTone> missing;

  bool get isPlain => added.isEmpty && missing.isEmpty;
}

/// A chord tone with its note name and scale-degree label.
class ChordTone {
  const ChordTone({
    required this.noteName,
    required this.degree,
    this.accidental = '',
    required this.label,
  });

  /// Spelled note name, e.g. `D` or `F\u266F`.
  final String noteName;

  /// Scale degree number, e.g. `9` or `5`.
  final int degree;

  /// `''`, `\u266D` or `\u266F`.
  final String accidental;

  /// Human readable degree for beginners, e.g. `9th` or `\u266F11`.
  final String label;

  /// Compact token used inside a chord symbol, e.g. `9` or `\u266F11`.
  String get token => '$accidental$degree';
}

const _majorScaleSemitones = [0, 2, 4, 5, 7, 9, 11];

/// Names [match] the modern way: the closest shape's symbol with the tones the
/// staff adds merged in and the chord tones it omits in parentheses.
///
/// [root] spells the chord and [staffNotes] spell the added tones.
ChordName nameChordMatch(
  ChordMatch match, {
  required Note root,
  required List<Note> staffNotes,
}) {
  final chord = Chord.onNote(root, match.quality);
  final added = <ChordTone>[];
  for (final pitchClass in match.extra) {
    final note = _staffNote(staffNotes, pitchClass);
    if (note != null) added.add(_addedTone(note, root));
  }
  final missing = [
    for (final pitchClass in match.missing)
      _missingTone(chord, match, pitchClass),
  ];
  added.sort((a, b) => a.degree.compareTo(b.degree));
  missing.sort((a, b) => a.degree.compareTo(b.degree));
  return ChordName(
    symbol: _symbol(chord.symbol, added, missing),
    added: added,
    missing: missing,
  );
}

Note? _staffNote(List<Note> notes, int pitchClass) {
  for (final note in notes) {
    if (note.midi % 12 == pitchClass) return note;
  }
  return null;
}

/// Names a tone the staff adds but the closest shape does not use, as a
/// compound scale degree (the 2nd becomes the 9th, the 4th the 11th).
ChordTone _addedTone(Note note, Note root) {
  final step = (note.letter.index - root.letter.index) % 7;
  final degree = _compoundDegree(step);
  final interval = (note.midi - root.midi) % 12;
  var offset = (interval - _majorScaleSemitones[step]) % 12;
  if (offset > 6) offset -= 12;
  final accidental = offset < 0
      ? offset == -2
            ? '\u{1D12B}'
            : '\u266D'
      : offset > 0
      ? offset == 2
            ? '\u{1D12A}'
            : '\u266F'
      : '';
  return ChordTone(
    noteName: note.pitchName,
    degree: degree,
    accidental: accidental,
    label: '$accidental${_ordinal(degree)}',
  );
}

/// Names a chord tone the staff omits, by the degree it plays in the shape.
ChordTone _missingTone(Chord chord, ChordMatch match, int pitchClass) {
  final intervals = match.quality.intervals;
  for (var i = 0; i < intervals.length; i++) {
    if ((match.rootPitchClass + intervals[i]) % 12 == pitchClass) {
      final degree = _degreeFromStep(match.quality.scaleSteps[i]);
      return ChordTone(
        noteName: chord.noteNames[i],
        degree: degree,
        label: _ordinal(degree),
      );
    }
  }
  return ChordTone(noteName: chord.rootName, degree: 1, label: '1st');
}

String _symbol(String base, List<ChordTone> added, List<ChordTone> missing) {
  if (added.isEmpty && missing.isEmpty) return base;
  // A single added tone rides on the base (`Cadd9`); anything more goes in one
  // clear group so mixed additions and omissions never run together
  // (`C7(add9,no5)`).
  if (added.length == 1 && missing.isEmpty) {
    final token = added.first.token;
    return base.contains('add')
        ? '$base($token)'
        : '$base'
              'add$token';
  }
  final parts = [
    for (final tone in added) 'add${tone.token}',
    for (final tone in missing) 'no${tone.degree}',
  ];
  return '$base(${parts.join(',')})';
}

/// The compound degree number for a diatonic [step] above the root.
int _compoundDegree(int step) {
  switch (step) {
    case 1:
      return 9;
    case 2:
      return 3;
    case 3:
      return 11;
    case 4:
      return 5;
    case 5:
      return 13;
    case 6:
      return 7;
    default:
      return 8;
  }
}

/// The degree number for a scale step of a chord quality.
int _degreeFromStep(int step) {
  switch (step) {
    case 8:
      return 9;
    case 10:
      return 11;
    case 12:
      return 13;
    default:
      return step + 1;
  }
}

String _ordinal(int number) {
  final mod100 = number % 100;
  if (mod100 >= 11 && mod100 <= 13) return '${number}th';
  switch (number % 10) {
    case 1:
      return '${number}st';
    case 2:
      return '${number}nd';
    case 3:
      return '${number}rd';
    default:
      return '${number}th';
  }
}
