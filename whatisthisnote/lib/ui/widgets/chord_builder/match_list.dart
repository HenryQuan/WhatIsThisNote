part of '../chord_builder_panel.dart';

extension on ChordBuilderPanel {
  Widget _matchList(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    if (notes.length < 2) {
      return _hint(theme, l10n.possibleChordsHint);
    }
    if (matches.isEmpty) {
      return _hint(theme, l10n.noCloseChord);
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
                child: _matchCard(theme, l10n, index, matches[index]),
              ),
          ],
        );
      },
    );
  }

  /// One candidate chord as a compact card, so the list wraps across the row
  /// instead of stacking one full-width tile per line.
  Widget _matchCard(
    ThemeData theme,
    AppLocalizations l10n,
    int index,
    ChordMatch match,
  ) {
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
                    Expanded(
                      child: _matchSubtitle(theme, l10n, match, chord, name),
                    ),
                    IconButton(
                      tooltip: l10n.playSymbol(symbol),
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
    AppLocalizations l10n,
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
      final role = index == null
          ? l10n.inversionRoot
          : l10n.inversionLabel(index);
      final tag = _isEnharmonic(match) ? ' \u00B7 ${l10n.enharmonicTag}' : '';
      lines.add(Text(l10n.roleWithBass(role, bassName) + tag, style: style));
    } else {
      final hints = <String>[];
      if (name.added.isNotEmpty) {
        hints.add(
          l10n.addedTones(name.added.map((tone) => _toneHint(tone)).join(', ')),
        );
      }
      if (name.missing.isNotEmpty) {
        hints.add(
          l10n.missingTones(
            name.missing.map((tone) => _toneHint(tone)).join(', '),
          ),
        );
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

  /// A beginner-facing hint for one added or omitted tone, e.g. `D (9)`.
  /// Uses the compact music-theory token instead of the English ordinal stored
  /// by the core matcher, so this hint remains language-neutral.
  String _toneHint(ChordTone tone) => '${tone.noteName} (${tone.token})';

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
