part of '../chord_builder_panel.dart';

class ChordStaff extends StatefulWidget {
  const ChordStaff({
    super.key,
    required this.clef,
    required this.keySignature,
    required this.notes,
    required this.selectedIndex,
    required this.highlightPitchClasses,
    required this.maxNotes,
    required this.onSelect,
    required this.onAdd,
    required this.onMove,
  });

  final Clef clef;
  final MusicalKey keySignature;
  final List<Note> notes;
  final int? selectedIndex;

  /// Pitch classes of the selected chord, ringed on the staff.
  final Set<int> highlightPitchClasses;
  final int maxNotes;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onAdd;
  final void Function(int index, int step) onMove;

  @override
  State<ChordStaff> createState() => _ChordStaffState();
}

class _ChordStaffState extends State<ChordStaff> {
  int? _dragIndex;
  int? _dragStartStep;
  double _dragStartY = 0;

  int _stepAt(StaffGeometry geometry, double y) => clampStaffStep(
    geometry.stepForY(y).round(),
    minStep: geometry.minStep,
    maxStep: geometry.maxStep,
  );

  /// The placed note whose notehead is nearest [y], if the tap is close enough
  /// to one; otherwise `null` so the tap falls through to "add a note".
  int? _nearestIndex(StaffGeometry geometry, double y) {
    int? best;
    var bestDistance = double.infinity;
    for (var index = 0; index < widget.notes.length; index++) {
      final noteY = geometry.yForStep(widget.clef.stepOf(widget.notes[index]));
      final distance = (noteY - y).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = index;
      }
    }
    return bestDistance <= geometry.halfSpace * 1.4 ? best : null;
  }

  void _handleTap(StaffGeometry geometry, Offset position) {
    final index = _nearestIndex(geometry, position.dy);
    if (index != null) {
      widget.onSelect(index);
      return;
    }
    if (widget.notes.length >= widget.maxNotes) return;
    widget.onAdd(_stepAt(geometry, position.dy));
  }

  /// Starts dragging the note under the finger, or the selected note when the
  /// finger is away from any notehead, so the whole staff is a grab target.
  void _handleDragStart(StaffGeometry geometry, Offset position) {
    final nearest = _nearestIndex(geometry, position.dy);
    final index = nearest ?? widget.selectedIndex;
    if (index == null || index >= widget.notes.length) {
      _dragIndex = null;
      return;
    }
    _dragIndex = index;
    _dragStartStep = widget.clef.stepOf(widget.notes[index]);
    _dragStartY = position.dy;
    if (nearest != null) widget.onSelect(nearest);
  }

  /// Moves the dragged note by whole steps relative to where the drag began,
  /// so a note grabbed anywhere keeps its shape instead of jumping to the
  /// finger.
  void _handleDragUpdate(StaffGeometry geometry, Offset position) {
    final index = _dragIndex;
    final start = _dragStartStep;
    if (index == null || start == null || index >= widget.notes.length) return;
    final deltaSteps = ((_dragStartY - position.dy) / geometry.halfSpace)
        .round();
    final step = clampStaffStep(
      start + deltaSteps,
      minStep: geometry.minStep,
      maxStep: geometry.maxStep,
    );
    if (step != widget.clef.stepOf(widget.notes[index])) {
      widget.onMove(index, step);
    }
  }

  void _handleDragEnd() {
    _dragIndex = null;
    _dragStartStep = null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final geometry = StaffGeometry.forSize(
          Size(constraints.maxWidth, constraints.maxHeight),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _handleTap(geometry, details.localPosition),
          onVerticalDragStart: (details) =>
              _handleDragStart(geometry, details.localPosition),
          onVerticalDragUpdate: (details) =>
              _handleDragUpdate(geometry, details.localPosition),
          onVerticalDragEnd: (_) => _handleDragEnd(),
          onVerticalDragCancel: _handleDragEnd,
          child: Semantics(
            label: context.l10n.chordStaff,
            hint: context.l10n.chordStaffHint,
            child: CustomPaint(
              size: Size.infinite,
              painter: ChordBuilderPainter(
                geometry: geometry,
                clef: widget.clef,
                key: widget.keySignature,
                notes: widget.notes,
                selectedIndex: widget.selectedIndex,
                highlightPitchClasses: widget.highlightPitchClasses,
                lineColor: scheme.onSurface.withValues(alpha: 0.85),
                noteColor: scheme.tertiary,
                selectedColor: scheme.primary,
                highlightColor: scheme.secondary,
                accidentalColor: scheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }
}
