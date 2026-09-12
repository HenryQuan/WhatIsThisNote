/// A pitch alteration applied to a [NoteLetter].
enum Accidental {
  flat('♭', -1, '\uE260'),
  natural('♮', 0, '\uE261'),
  sharp('♯', 1, '\uE262');

  const Accidental(this.text, this.offset, this.glyph);

  /// Unicode symbol used in text, e.g. `♯`.
  final String text;

  /// Semitone offset from the natural note.
  final int offset;

  /// SMuFL code point used to draw the accidental with a music font.
  final String glyph;
}
