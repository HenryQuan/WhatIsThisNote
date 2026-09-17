import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/accidental.dart';
import '../../core/chord.dart';
import '../../core/clef.dart';
import '../../core/display_preferences.dart';
import '../../core/key.dart';
import '../../core/note.dart';
import '../../core/staff_geometry.dart';
import '../notation_glyphs.dart';

part 'notation_painter/painter.dart';
part 'notation_painter/staff_drawing.dart';
part 'notation_painter/label_drawing.dart';

/// Default solfege spelling for the on-staff label. UI code swaps this out for
/// a localized resolver; the plain English/Italian names keep the painter
/// usable on its own (for example in tests).
String _defaultSolfegeName(Note note) => note.solfege;

/// Paints a five line staff, a clef, the key signature, the ledger lines
/// required by the current note and the note itself (with stem). Also paints a
/// small label next to the note showing its scientific and solfege names.
