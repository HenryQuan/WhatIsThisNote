import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/clef.dart';
import '../../core/key.dart';
import '../../core/note.dart';
import '../../core/staff_geometry.dart';
import '../notation_glyphs.dart';
import 'music_glyph.dart';

/// Paints the chord builder's staff: the five lines, the clef and key
/// signature, and each placed note as a notehead with its accidental.
///
/// Unlike the Note tab's painter this draws several independent noteheads (no
/// stem) so every note can be tapped and dragged on its own. Seconds are
/// staggered sideways, the usual way two adjacent noteheads are written.
class ChordBuilderPainter extends CustomPainter {
  ChordBuilderPainter({
    required this.geometry,
    required this.clef,
    required this.key,
    required this.notes,
    required this.selectedIndex,
    required this.lineColor,
    required this.noteColor,
    required this.selectedColor,
    required this.accidentalColor,
  });

  final StaffGeometry geometry;
  final Clef clef;
  final MusicalKey key;
  final List<Note> notes;
  final int? selectedIndex;
  final Color lineColor;
  final Color noteColor;
  final Color selectedColor;
  final Color accidentalColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = (geometry.space * 0.11).clamp(1.0, 4.0)
      ..strokeCap = StrokeCap.round;

    for (var line = 0; line < 5; line++) {
      final y = geometry.yForStep(line * 2);
      canvas.drawLine(
        Offset(geometry.staffLeft, y),
        Offset(geometry.staffRight, y),
        linePaint,
      );
    }

    _paintClef(canvas);
    final signatureRight = _paintKeySignature(canvas);
    if (notes.isEmpty) return;

    final contentLeft = signatureRight + geometry.space * 1.6;
    final contentRight = geometry.staffRight - geometry.space * 1.2;
    final centerX = (contentLeft + contentRight) / 2;

    // Sort by staff position so adjacent notes can be staggered.
    final order = List<int>.generate(notes.length, (index) => index)
      ..sort((a, b) {
        final byStep = clef.stepOf(notes[a]).compareTo(clef.stepOf(notes[b]));
        return byStep != 0 ? byStep : a.compareTo(b);
      });

    final noteX = <int, double>{};
    var previousStep = -1000;
    var offset = 0.0;
    for (final index in order) {
      final step = clef.stepOf(notes[index]);
      offset = step - previousStep == 1 ? (offset == 0 ? 1.0 : 0.0) : 0.0;
      noteX[index] = centerX + offset * geometry.space * 0.85;
      previousStep = step;
    }

    for (var index = 0; index < notes.length; index++) {
      final note = notes[index];
      final step = clef.stepOf(note);
      final x = noteX[index]!;
      final y = geometry.yForStep(step);
      final selected = index == selectedIndex;

      for (final ledgerStep in geometry.ledgerStepsFor(step)) {
        final ledgerY = geometry.yForStep(ledgerStep);
        canvas.drawLine(
          Offset(x - geometry.space * 0.95, ledgerY),
          Offset(x + geometry.space * 0.95, ledgerY),
          linePaint,
        );
      }

      if (selected) {
        canvas.drawCircle(
          Offset(x, y),
          geometry.space * 0.95,
          Paint()..color = selectedColor.withValues(alpha: 0.14),
        );
      }

      final expected = key.accidentalFor(note.letter);
      if (note.accidental != expected) {
        final accidental = layoutMusicGlyph(
          note.accidental.glyph,
          geometry.space * 3.2,
          accidentalColor,
        );
        paintMusicGlyph(
          canvas,
          accidental,
          centerX: x - geometry.space * 1.35,
          baselineY: y,
        );
      }

      final notehead = layoutMusicGlyph(
        NotationGlyphs.noteheadBlack,
        geometry.space * 4,
        selected ? selectedColor : noteColor,
      );
      paintMusicGlyph(canvas, notehead, centerX: x, baselineY: y);
    }
  }

  void _paintClef(Canvas canvas) {
    final clefGlyph = layoutMusicGlyph(
      clef.glyph,
      geometry.space * 4,
      lineColor,
    );
    paintMusicGlyph(
      canvas,
      clefGlyph,
      x: geometry.staffLeft + geometry.space * 0.15,
      baselineY: geometry.yForStep(clef.glyphStep),
    );
  }

  /// Draws the key signature and returns the x just after it.
  double _paintKeySignature(Canvas canvas) {
    final items = key.signatureFor(clef);
    final spacing = geometry.space * 0.9;
    var x = geometry.staffLeft + (clef.advance + 0.35) * geometry.space;
    for (final item in items) {
      final glyph = layoutMusicGlyph(
        item.accidental.glyph,
        geometry.space * 4,
        lineColor,
      );
      paintMusicGlyph(
        canvas,
        glyph,
        x: x,
        baselineY: geometry.yForStep(item.step),
      );
      x += spacing;
    }
    return x;
  }

  @override
  bool shouldRepaint(covariant ChordBuilderPainter old) {
    return old.geometry.size != geometry.size ||
        old.geometry.space != geometry.space ||
        old.clef != clef ||
        old.key != key ||
        !listEquals(old.notes, notes) ||
        old.selectedIndex != selectedIndex ||
        old.lineColor != lineColor ||
        old.noteColor != noteColor ||
        old.selectedColor != selectedColor ||
        old.accidentalColor != accidentalColor;
  }
}
