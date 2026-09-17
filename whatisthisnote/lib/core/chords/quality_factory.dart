part of '../chord.dart';

ChordQuality chordQualityFromStack(List<int> scaleSteps, List<int> intervals) {
  final byStep = <int, int>{
    for (var i = 0; i < scaleSteps.length; i++) scaleSteps[i]: intervals[i],
  };
  final third = byStep[2]!;
  final fifth = byStep[4]!;
  final sixth = byStep[5];
  final seventh = byStep[6];
  final ninth = byStep[8];
  final eleventh = byStep[10];
  final thirteenth = byStep[12];

  // Triads and sixths are complete on their own.
  if (seventh == null) {
    if (sixth != null) {
      final six = sixth == 9 ? '6' : '\u266D6';
      final sixWord = sixth == 9 ? 'sixth' : 'flat sixth';
      if (third == 4 && fifth == 7) {
        return ChordQuality('major $sixWord', six, six, intervals, scaleSteps);
      }
      if (third == 3 && fifth == 7) {
        return ChordQuality(
          'minor $sixWord',
          'm$six',
          six,
          intervals,
          scaleSteps,
        );
      }
      if (third == 4 && fifth == 8) {
        return ChordQuality(
          'augmented $sixWord',
          'aug$six',
          '+$six',
          intervals,
          scaleSteps,
        );
      }
      return ChordQuality(
        'diminished $sixWord',
        'dim$six',
        '\u00B0$six',
        intervals,
        scaleSteps,
      );
    }
    if (third == 4 && fifth == 7) return ChordQuality.major;
    if (third == 3 && fifth == 7) return ChordQuality.minor;
    if (third == 4 && fifth == 8) return ChordQuality.augmented;
    return ChordQuality.diminished;
  }

  // Seventh quality, kept as the parts an extension number replaces.
  String base;
  String baseRoman;
  String baseLabel;
  String extSuffix;
  String extRoman;
  String extLabel;
  var flatFive = false;

  if (third == 3 && fifth == 6) {
    if (seventh == 9) {
      base = 'dim7';
      baseRoman = '\u00B07';
      baseLabel = 'diminished seventh';
      extSuffix = 'dim';
      extRoman = '\u00B0';
      extLabel = 'diminished ';
    } else if (seventh == 11) {
      base = 'mMaj7\u266D5';
      baseRoman = 'mMaj7\u266D5';
      baseLabel = 'minor-major seventh flat five';
      extSuffix = 'mMaj';
      extRoman = 'mMaj';
      extLabel = 'minor-major ';
      flatFive = true;
    } else {
      base = 'm7\u266D5';
      baseRoman = '\u00F87';
      baseLabel = 'half-diminished seventh';
      extSuffix = 'm';
      extRoman = '\u00F8';
      extLabel = 'half-diminished ';
      flatFive = true;
    }
  } else if (third == 3 && fifth == 7) {
    if (seventh == 11) {
      base = 'mMaj7';
      baseRoman = 'mMaj7';
      baseLabel = 'minor-major seventh';
      extSuffix = 'mMaj';
      extRoman = 'mMaj';
      extLabel = 'minor-major ';
    } else {
      base = 'm7';
      baseRoman = '7';
      baseLabel = 'minor seventh';
      extSuffix = 'm';
      extRoman = '';
      extLabel = 'minor ';
    }
  } else if (third == 4 && fifth == 7) {
    if (seventh == 11) {
      base = 'maj7';
      baseRoman = 'maj7';
      baseLabel = 'major seventh';
      extSuffix = 'maj';
      extRoman = 'maj';
      extLabel = 'major ';
    } else {
      base = '7';
      baseRoman = '7';
      baseLabel = 'dominant seventh';
      extSuffix = '';
      extRoman = '';
      extLabel = 'dominant ';
    }
  } else {
    if (seventh == 11) {
      base = 'augMaj7';
      baseRoman = '+maj7';
      baseLabel = 'augmented major seventh';
      extSuffix = 'augMaj';
      extRoman = '+maj';
      extLabel = 'augmented major ';
    } else {
      base = 'aug7';
      baseRoman = '+7';
      baseLabel = 'augmented seventh';
      extSuffix = 'aug';
      extRoman = '+';
      extLabel = 'augmented ';
    }
  }

  final hasNatural9 = ninth == 14;
  final hasNatural11 = eleventh == 17;
  final hasNatural13 = thirteenth == 21;

  String? primary;
  String? primaryWord;
  if (hasNatural13) {
    primary = '13';
    primaryWord = 'thirteenth';
  } else if (hasNatural11) {
    primary = '11';
    primaryWord = 'eleventh';
  } else if (hasNatural9) {
    primary = '9';
    primaryWord = 'ninth';
  }

  final alterations = <String>[];
  final alterationWords = <String>[];
  if (ninth != null && !hasNatural9) {
    alterations.add(ninth == 13 ? '\u266D9' : '\u266F9');
    alterationWords.add(ninth == 13 ? 'flat ninth' : 'sharp ninth');
  }
  if (eleventh != null && !hasNatural11) {
    alterations.add('\u266F11');
    alterationWords.add('sharp eleventh');
  }
  if (thirteenth != null && !hasNatural13) {
    alterations.add('\u266D13');
    alterationWords.add('flat thirteenth');
  }

  String suffix;
  String roman;
  String label;
  if (primary != null) {
    suffix = '$extSuffix$primary${flatFive ? '\u266D5' : ''}';
    roman =
        '$extRoman$primary'
        '${flatFive && extRoman != '\u00F8' ? '\u266D5' : ''}';
    label =
        '$extLabel$primaryWord'
        '${flatFive && extRoman != '\u00F8' ? ' flat five' : ''}';
  } else {
    suffix = base;
    roman = baseRoman;
    label = baseLabel;
  }
  if (alterations.isNotEmpty) {
    suffix += alterations.join();
    roman += alterations.join();
    label += ' ${alterationWords.join(' ')}';
  }
  return ChordQuality(label, suffix, roman, intervals, scaleSteps);
}
