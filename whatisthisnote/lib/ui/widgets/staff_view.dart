import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/accidental.dart';
import '../../core/chord.dart';
import '../../core/clef.dart';
import '../../core/display_preferences.dart';
import '../../core/key.dart';
import '../../core/staff_geometry.dart';
import '../../l10n/l10n.dart';
import '../painters/notation_painter.dart';

part 'staff_view/state.dart';

/// An interactive staff. The note can be dragged vertically to change its
/// pitch; it snaps to the nearest staff position and animates into place.
/// Dragging horizontally moves the note along the staff. The widget must be
/// placed below the app's [AppLocalizations] delegate because the staff label
/// and accessibility text are localized.
class StaffView extends StatefulWidget {
  const StaffView({
    super.key,
    required this.clef,
    required this.keySignature,
    required this.step,
    required this.onStepChanged,
    this.chordTones = const [],
    this.targetStep,
    this.accidental,
    this.targetAccidental,
    this.melodySteps = const [],
    this.melodyIndex = 0,
    this.minStep = -6,
    this.maxStep = 14,
    this.showLabel = true,
    this.interactive = true,
    this.naming = NamingSystem.scientific,
    this.showEnharmonic = false,
    this.semanticValue,
  });

  final Clef clef;
  final MusicalKey keySignature;

  /// The settled (integer) staff step.
  final int step;

  /// Exact tones of an optional chord to draw around the note, low to high.
  final List<ChordToneAtStaff> chordTones;

  /// Staff steps of [chordTones]. Kept as a small convenience for tests and
  /// callers that only need the layout positions.
  List<int> get chordSteps => [for (final tone in chordTones) tone.staffStep];

  /// Optional staff step to hint at, drawn as a hollow target notehead (used by
  /// the guided theory path).
  final int? targetStep;

  /// Accidental to write on the note, overriding the key signature. `null`
  /// uses the key's accidental for the note's letter.
  final Accidental? accidental;

  /// Accidental to write on the hollow [targetStep] notehead.
  final Accidental? targetAccidental;

  /// Staff steps of a phrase to draw left to right (used by read-and-play).
  /// Empty for the normal single note.
  final List<int> melodySteps;

  /// Index of the phrase note currently being read, drawn highlighted.
  final int melodyIndex;

  /// Called whenever the snapped step changes, including while dragging.
  final ValueChanged<int> onStepChanged;

  final int minStep;
  final int maxStep;

  /// Whether to draw the note name label next to the note. Hidden while
  /// practising so the answer is not given away.
  final bool showLabel;

  /// Whether the note can be dragged or the staff tapped.
  final bool interactive;

  /// Which naming system the on-staff label uses, and whether to show the
  /// enharmonic spelling next to it.
  final NamingSystem naming;
  final bool showEnharmonic;

  /// The note name announced to screen readers, for example `B4`. The staff
  /// otherwise draws the note as a glyph that assistive tech cannot read.
  final String? semanticValue;

  @override
  State<StaffView> createState() => _StaffViewState();
}
