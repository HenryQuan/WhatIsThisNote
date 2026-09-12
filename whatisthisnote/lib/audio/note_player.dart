import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'tone.dart';

/// Plays short musical tones.
///
/// Views depend on this small interface rather than on a concrete audio
/// plugin, so they can be driven by a fake in tests.
abstract interface class NotePlayer {
  /// Plays [frequencies] (in hertz) together as a single short sound.
  Future<void> play(Iterable<double> frequencies);

  /// Releases any native resources held by the player.
  Future<void> dispose();
}

/// A [NotePlayer] backed by `audioplayers`, which supports Android, iOS, web,
/// Windows, macOS and Linux.
///
/// The tone is synthesized in Dart by [toneWav] and handed to the plugin as
/// raw bytes, so the app ships no audio assets. Platforms that cannot play a
/// byte array directly convert it internally, which the plugin handles.
class AudioNotePlayer implements NotePlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> play(Iterable<double> frequencies) async {
    final voices = frequencies.toList(growable: false);
    if (voices.isEmpty) return;
    try {
      await _player.stop();
      await _player.play(BytesSource(toneWav(voices), mimeType: 'audio/wav'));
    } catch (error) {
      // Audio is a nice-to-have; never let a platform hiccup break the app.
      debugPrint('Could not play tone: $error');
    }
  }

  @override
  Future<void> dispose() => _player.dispose();
}
