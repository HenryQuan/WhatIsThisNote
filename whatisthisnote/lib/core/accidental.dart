/// A pitch alteration applied to a [NoteLetter].
enum Accidental {
  doubleFlat('𝄫', -2, '\uE264'),
  flat('♭', -1, '\uE260'),
  natural('♮', 0, '\uE261'),
  sharp('♯', 1, '\uE262'),
  doubleSharp('𝄪', 2, '\uE263');

  const Accidental(this.text, this.offset, this.glyph);

  /// Unicode symbol used in text, e.g. `♯` or `𝄪`.
  final String text;

  /// Semitone offset from the natural note.
  final int offset;

  /// SMuFL code point used to draw the accidental with a music font.
  final String glyph;
}
