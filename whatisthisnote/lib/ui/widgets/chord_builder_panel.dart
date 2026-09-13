import 'package:flutter/material.dart';

import '../../core/accidental.dart';
import '../../core/chord.dart';
import '../../core/chord_finder.dart';
import '../../core/chord_namer.dart';
import '../../core/clef.dart';
import '../../core/key.dart';
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
    required this.selectedMatch,
    required this.maxNotes,
    required this.rootNoteFor,
    required this.onSelectNote,
    required this.onAddNote,
    required this.onMoveNote,
    required this.onAccidentalChanged,
    required this.onRemoveNote,
    required this.onShowSuggestions,
    required this.onAddBelow,
    required this.onNudgeSelected,
    required this.onPlayChord,
    required this.onPlayMatch,
    required this.onSelectMatch,
    required this.keySelector,
  });

  final List<Note> notes;
  final int? selectedIndex;
  final Clef clef;
  final MusicalKey keySignature;
  final List<ChordMatch> matches;

  /// The chord the learner tapped, highlighted on the staff and in the list.
  final ChordMatch? selectedMatch;
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

  /// Adds a note below the current stack.
  final VoidCallback onAddBelow;

  /// Moves the selected note by [delta] staff steps.
  final ValueChanged<int> onNudgeSelected;
  final VoidCallback onPlayChord;
  final ValueChanged<ChordMatch> onPlayMatch;
  final ValueChanged<ChordMatch> onSelectMatch;

  final Widget keySelector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = selectedIndex != null && selectedIndex! < notes.length
        ? notes[selectedIndex!]
        : null;
    final highlighted = selectedMatch?.pitchClasses ?? const <int>{};

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          keySelector,
          const SizedBox(height: 12),
          Text('Build a chord', style: theme.textTheme.titleMedium),
          Text(
            'Tap the staff to add a note, then drag it or use the arrows. '
            'Tap a chord below to highlight its notes.',
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
              highlightPitchClasses: highlighted,
              maxNotes: maxNotes,
              onSelect: onSelectNote,
              onAdd: onAddNote,
              onMove: onMoveNote,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: notes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemBuilder: (context, index) => InputChip(
                key: Key('builder-note-$index'),
                label: Text(notes[index].name),
                selected: index == selectedIndex,
                onPressed: () => onSelectNote(index),
                onDeleted: () => onRemoveNote(index),
                deleteIcon: const Icon(Icons.close, size: 16),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('builder-add'),
                  onPressed: notes.length < maxNotes ? onShowSuggestions : null,
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  label: const Text('Add above'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.tonalIcon(
                  key: const Key('builder-add-below'),
                  onPressed: notes.length < maxNotes ? onAddBelow : null,
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  label: const Text('Add below'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<Accidental>(
              key: const Key('builder-accidental'),
              showSelectedIcon: false,
              segments: [
                for (final accidental in Accidental.values)
                  ButtonSegment<Accidental>(
                    value: accidental,
                    label: Text(accidental.text),
                  ),
              ],
              selected: {selected?.accidental ?? Accidental.natural},
              onSelectionChanged: selected == null
                  ? null
                  : (selection) =>
                        onAccidentalChanged(selectedIndex!, selection.first),
            ),
          ),
          const SizedBox(height: 8),
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
              IconButton(
                key: const Key('builder-up'),
                tooltip: 'Move the selected note up',
                onPressed: selected == null ? null : () => onNudgeSelected(1),
                icon: const Icon(Icons.keyboard_arrow_up),
              ),
              IconButton(
                key: const Key('builder-down'),
                tooltip: 'Move the selected note down',
                onPressed: selected == null ? null : () => onNudgeSelected(-1),
                icon: const Icon(Icons.keyboard_arrow_down),
              ),
              const SizedBox(width: 4),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final columns = constraints.maxWidth >= 700
            ? 3
            : constraints.maxWidth >= 320
            ? 2
            : 1;
        final width =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var index = 0; index < matches.length; index++)
              SizedBox(
                width: width,
                child: _matchCard(theme, index, matches[index]),
              ),
          ],
        );
      },
    );
  }

  /// One candidate chord as a compact card, so the list wraps across the row
  /// instead of stacking one full-width tile per line.
  Widget _matchCard(ThemeData theme, int index, ChordMatch match) {
    final root = rootNoteFor(match.rootPitchClass);
    final chord = Chord.onNote(root, match.quality);
    final name = nameChordMatch(match, root: root, staffNotes: notes);
    final symbol = name.symbol;
    final selected = _isSelectedMatch(match);
    // The finder ranks the root-position shape first, so the head of the list
    // is the best match; symmetrical shapes share its notes and are shown as
    // the enharmonic alternatives.
    final isBest = index == 0;
    final enharmonic = _isEnharmonic(match);
    return Opacity(
      opacity: enharmonic ? 0.55 : 1,
      child: Card(
        key: Key('chord-match-$index'),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        color: selected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
            : null,
        child: InkWell(
          onTap: () => onSelectMatch(match),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        symbol,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (isBest) ...[
                      const SizedBox(width: 6),
                      const _BestMatchBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: _matchSubtitle(theme, match, chord, name)),
                    IconButton(
                      tooltip: 'Play $symbol',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      iconSize: 20,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      icon: const Icon(Icons.play_arrow),
                      onPressed: () => onPlayMatch(match),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Whether [match] is the chord the learner has selected.
  bool _isSelectedMatch(ChordMatch match) {
    final current = selectedMatch;
    return current != null &&
        current.rootPitchClass == match.rootPitchClass &&
        current.quality == match.quality;
  }

  /// The lowest note on the chord staff, whose pitch fixes root position.
  Note? get _bassNote {
    if (notes.isEmpty) return null;
    var lowest = notes.first;
    for (final note in notes) {
      if (note.midi < lowest.midi) lowest = note;
    }
    return lowest;
  }

  /// The dynamic line under a match's name: the theoretical spelling, then the
  /// bass note's role for exact matches, or the added/omitted tones for the
  /// closest shape.
  Widget _matchSubtitle(
    ThemeData theme,
    ChordMatch match,
    Chord chord,
    ChordName name,
  ) {
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final bass = _bassNote;
    final lines = <Widget>[];
    if (match.isExact) {
      lines.add(Text(chord.noteNames.join(' \u2013 '), style: style));
      final index = _bassToneIndex(match);
      final bassName = bass?.pitchName ?? chord.rootName;
      final role = index == null ? 'Root position' : _inversionName(index);
      final tag = _isEnharmonic(match) ? ' \u00B7 enharmonic' : '';
      lines.add(Text('$role ($bassName in bass)$tag', style: style));
    } else {
      final hints = <String>[];
      if (name.added.isNotEmpty) {
        hints.add('Added: ${name.added.map(_toneHint).join(', ')}');
      }
      if (name.missing.isNotEmpty) {
        hints.add('Missing: ${name.missing.map(_toneHint).join(', ')}');
      }
      lines.add(Text(hints.join(' \u00B7 '), style: style));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) const SizedBox(height: 2),
          lines[i],
        ],
      ],
    );
  }

  /// A beginner-facing hint for one added or omitted tone, e.g. `D (9th)`.
  String _toneHint(ChordTone tone) => '${tone.noteName} (${tone.label})';

  /// Position of the bass note among a match's chord tones, or `null` when the
  /// bass is not a chord tone (an exact match always has one).
  int? _bassToneIndex(ChordMatch match) {
    final bass = _bassNote;
    if (bass == null) return null;
    final bassPitchClass = bass.midi % 12;
    for (var i = 0; i < match.quality.intervals.length; i++) {
      if ((match.rootPitchClass + match.quality.intervals[i]) % 12 ==
          bassPitchClass) {
        return i;
      }
    }
    return null;
  }

  /// Human readable inversion for a bass at chord-tone [index].
  String _inversionName(int index) {
    const labels = [
      'Root position',
      '1st inversion',
      '2nd inversion',
      '3rd inversion',
      '4th inversion',
    ];
    return index < labels.length ? labels[index] : '$index-th inversion';
  }

  /// Whether [match] is an exact match that spells the same notes as the best
  /// match under a different root (an augmented triad or a seventh chord with
  /// several symmetrical roots).
  bool _isEnharmonic(ChordMatch match) {
    if (!match.isExact || matches.isEmpty) return false;
    final best = matches.first;
    if (!best.isExact || best == match) return false;
    final notes = match.pitchClasses;
    final bestNotes = best.pitchClasses;
    return notes.length == bestNotes.length && notes.containsAll(bestNotes);
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
}

/// A green tag marking the highest ranked chord in the possible-chords list.
class _BestMatchBadge extends StatelessWidget {
  const _BestMatchBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.green.shade600,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        'Best match',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
