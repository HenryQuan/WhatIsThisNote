import 'package:flutter/material.dart';

import '../../core/accidental.dart';
import '../../core/chord.dart';
import '../../core/chord_finder.dart';
import '../../core/chord_namer.dart';
import '../../core/clef.dart';
import '../../core/key.dart';
import '../../core/note.dart';
import '../../core/staff_geometry.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/l10n.dart';
import '../painters/chord_builder_painter.dart';

part 'chord_builder/match_list.dart';
part 'chord_builder/staff.dart';

/// The Chords tab: stack notes on a small staff, play them, and see every
/// chord they could spell, with the closest shapes when they spell none.
class ChordBuilderPanel extends StatelessWidget {
  const ChordBuilderPanel({
    super.key,
    this.sidebar = false,
    required this.notes,
    required this.selectedIndex,
    required this.matches,
    required this.selectedMatch,
    required this.maxNotes,
    required this.rootNoteFor,
    required this.onSelectNote,
    required this.onAccidentalChanged,
    required this.onRemoveNote,
    required this.onShowSuggestions,
    required this.onAddBelow,
    required this.onNudgeSelected,
    required this.onPlayChord,
    required this.onPlayMatch,
    required this.onSelectMatch,
    required this.onClearAll,
    required this.keySelector,
  });

  /// Whether the panel sits in a full-height rail beside the staff instead of
  /// below it.
  final bool sidebar;

  final List<Note> notes;
  final int? selectedIndex;
  final List<ChordMatch> matches;

  /// The chord the learner tapped, highlighted on the staff and in the list.
  final ChordMatch? selectedMatch;
  final int maxNotes;

  /// Spells a root pitch class using a placed note where possible.
  final Note Function(int pitchClass) rootNoteFor;

  final ValueChanged<int> onSelectNote;
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

  /// Removes every placed note.
  final VoidCallback onClearAll;

  final Widget keySelector;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final selected = selectedIndex != null && selectedIndex! < notes.length
        ? notes[selectedIndex!]
        : null;

    return ConstrainedBox(
      constraints: BoxConstraints(
        // On phones the staff above keeps the larger share; the panel scrolls
        // itself so the notation is never squeezed.
        maxHeight: sidebar
            ? double.infinity
            : MediaQuery.sizeOf(context).height * 0.5,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            keySelector,
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.buildAChord,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton.icon(
                  key: const Key('builder-clear'),
                  onPressed: notes.isEmpty ? null : onClearAll,
                  icon: const Icon(Icons.clear_all, size: 18),
                  label: Text(l10n.clearAll),
                ),
              ],
            ),
            Text(
              l10n.builderHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
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
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    key: const Key('builder-add'),
                    onPressed: notes.length < maxNotes
                        ? onShowSuggestions
                        : null,
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    label: Text(l10n.addAbove),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    key: const Key('builder-add-below'),
                    onPressed: notes.length < maxNotes ? onAddBelow : null,
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    label: Text(l10n.addBelow),
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
                    l10n.notesCount(notes.length, maxNotes),
                    key: const Key('builder-count'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                IconButton(
                  key: const Key('builder-up'),
                  tooltip: l10n.moveNoteUp,
                  onPressed: selected == null ? null : () => onNudgeSelected(1),
                  icon: const Icon(Icons.keyboard_arrow_up),
                ),
                IconButton(
                  key: const Key('builder-down'),
                  tooltip: l10n.moveNoteDown,
                  onPressed: selected == null
                      ? null
                      : () => onNudgeSelected(-1),
                  icon: const Icon(Icons.keyboard_arrow_down),
                ),
                const SizedBox(width: 4),
                FilledButton.tonalIcon(
                  key: const Key('builder-play'),
                  onPressed: notes.length >= 2 ? onPlayChord : null,
                  icon: const Icon(Icons.volume_up),
                  label: Text(l10n.play),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(l10n.possibleChords, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            _matchList(context),
          ],
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
        context.l10n.bestMatch,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// The interactive mini staff used to place and adjust the chord's notes.
