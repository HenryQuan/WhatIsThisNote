import 'package:flutter/material.dart';

import '../../core/accidental.dart';
import '../../core/chord.dart';
import '../../core/chord_finder.dart';
import '../../core/clef.dart';
import '../../core/key.dart';
import '../../core/metronome.dart';
import '../../core/note.dart';
import '../../core/staff_geometry.dart';
import '../painters/chord_builder_painter.dart';

/// The Chords tab: stack notes on a small staff, play them, and see every
/// chord they could spell, with the closest shapes when they spell none.
class ChordBuilderPanel extends StatelessWidget {
  const ChordBuilderPanel({
    super.key,
    required this.notes,
    required this.selectedIndex,
    required this.clef,
    required this.keySignature,
    required this.matches,
    required this.maxNotes,
    required this.rootNoteFor,
    required this.onSelectNote,
    required this.onAddNote,
    required this.onMoveNote,
    required this.onAccidentalChanged,
    required this.onRemoveNote,
    required this.onShowSuggestions,
    required this.onPlayChord,
    required this.onPlayMatch,
    required this.keySelector,
    required this.scaleSelector,
  });

  final List<Note> notes;
  final int? selectedIndex;
  final Clef clef;
  final MusicalKey keySignature;
  final List<ChordMatch> matches;
  final int maxNotes;

  /// Spells a root pitch class using a placed note where possible.
  final Note Function(int pitchClass) rootNoteFor;

  final ValueChanged<int> onSelectNote;
  final ValueChanged<int> onAddNote;
  final void Function(int index, int step) onMoveNote;
  final void Function(int index, Accidental accidental) onAccidentalChanged;
  final ValueChanged<int> onRemoveNote;

  /// Adds a note above the current stack, for a precise, tappable way in.
  final VoidCallback onShowSuggestions;
  final VoidCallback onPlayChord;
  final ValueChanged<ChordMatch> onPlayMatch;

  final Widget keySelector;
  final Widget scaleSelector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = selectedIndex != null && selectedIndex! < notes.length
        ? notes[selectedIndex!]
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: keySelector),
              const SizedBox(width: 8),
              Expanded(child: scaleSelector),
            ],
          ),
          const SizedBox(height: 12),
          Text('Build a chord', style: theme.textTheme.titleMedium),
          Text(
            'Tap the staff to add a note, tap a note to pick it, then drag it '
            'up or down.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: ChordStaff(
              clef: clef,
              keySignature: keySignature,
              notes: notes,
              selectedIndex: selectedIndex,
              maxNotes: maxNotes,
              onSelect: onSelectNote,
              onAdd: onAddNote,
              onMove: onMoveNote,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (var index = 0; index < notes.length; index++)
                InputChip(
                  key: Key('builder-note-$index'),
                  label: Text(notes[index].name),
                  selected: index == selectedIndex,
                  onPressed: () => onSelectNote(index),
                  onDeleted: () => onRemoveNote(index),
                  deleteIcon: const Icon(Icons.close, size: 16),
                ),
              ActionChip(
                key: const Key('builder-add'),
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Add'),
                onPressed: notes.length < maxNotes ? onShowSuggestions : null,
              ),
            ],
          ),
          if (selected != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  'Accidental',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                SegmentedButton<Accidental>(
                  key: const Key('builder-accidental'),
                  showSelectedIcon: false,
                  segments: [
                    for (final accidental in Accidental.values)
                      ButtonSegment<Accidental>(
                        value: accidental,
                        label: Text(accidental.text),
                      ),
                  ],
                  selected: {selected.accidental},
                  onSelectionChanged: (selection) =>
                      onAccidentalChanged(selectedIndex!, selection.first),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${notes.length} of $maxNotes notes',
                  key: const Key('builder-count'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              FilledButton.tonalIcon(
                key: const Key('builder-play'),
                onPressed: notes.length >= 2 ? onPlayChord : null,
                icon: const Icon(Icons.volume_up),
                label: const Text('Play'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Possible chords', style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          _matchList(context),
        ],
      ),
    );
  }

  Widget _matchList(BuildContext context) {
    final theme = Theme.of(context);
    if (notes.length < 2) {
      return _hint(
        theme,
        'Add at least two notes and every chord they could spell appears here.',
      );
    }
    if (matches.isEmpty) {
      return _hint(theme, 'No close chord found. Try moving a note.');
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final match = matches[index];
        final symbol = Chord.onNote(
          rootNoteFor(match.rootPitchClass),
          match.quality,
        ).symbol;
        return ListTile(
          key: Key('chord-match-$index'),
          contentPadding: EdgeInsets.zero,
          title: Text(
            symbol,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(_describe(match)),
          trailing: const Icon(Icons.play_arrow),
          onTap: () => onPlayMatch(match),
        );
      },
    );
  }

  Widget _hint(ThemeData theme, String text) {
    return Align(
      alignment: Alignment.topLeft,
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  /// Describes a near match from the learner's point of view: which notes to
  /// add to hear the chord, and which of their notes it leaves out.
  String _describe(ChordMatch match) {
    if (match.isExact) return match.quality.label;
    final parts = <String>[];
    if (match.missing.isNotEmpty) {
      parts.add('add ${match.missing.map(pitchClassName).join(', ')}');
    }
    if (match.extra.isNotEmpty) {
      parts.add('omit ${match.extra.map(pitchClassName).join(', ')}');
    }
    return parts.join(' · ');
  }
}

/// The interactive mini staff used to place and adjust the chord's notes.
class ChordStaff extends StatefulWidget {
  const ChordStaff({
    super.key,
    required this.clef,
    required this.keySignature,
    required this.notes,
    required this.selectedIndex,
    required this.maxNotes,
    required this.onSelect,
    required this.onAdd,
    required this.onMove,
  });

  final Clef clef;
  final MusicalKey keySignature;
  final List<Note> notes;
  final int? selectedIndex;
  final int maxNotes;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onAdd;
  final void Function(int index, int step) onMove;

  @override
  State<ChordStaff> createState() => _ChordStaffState();
}

class _ChordStaffState extends State<ChordStaff> {
  int? _dragIndex;

  int _stepAt(StaffGeometry geometry, double y) =>
      geometry.clampStep(geometry.stepForY(y).round()).round();

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
    return bestDistance <= geometry.halfSpace * 1.1 ? best : null;
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

  void _handleDragStart(StaffGeometry geometry, Offset position) {
    final index = _nearestIndex(geometry, position.dy);
    _dragIndex = index;
    if (index != null) widget.onSelect(index);
  }

  void _handleDragUpdate(StaffGeometry geometry, Offset position) {
    final index = _dragIndex;
    if (index == null || index >= widget.notes.length) return;
    final step = _stepAt(geometry, position.dy);
    if (step != widget.clef.stepOf(widget.notes[index])) {
      widget.onMove(index, step);
    }
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
          onVerticalDragEnd: (_) => _dragIndex = null,
          child: Semantics(
            label: 'Chord staff',
            hint: 'Tap to add a note, drag a note up or down to change it.',
            child: CustomPaint(
              size: Size.infinite,
              painter: ChordBuilderPainter(
                geometry: geometry,
                clef: widget.clef,
                key: widget.keySignature,
                notes: widget.notes,
                selectedIndex: widget.selectedIndex,
                lineColor: scheme.onSurface.withValues(alpha: 0.85),
                noteColor: scheme.tertiary,
                selectedColor: scheme.primary,
                accidentalColor: scheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }
}
