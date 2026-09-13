import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import 'tone.dart';

/// Plays short musical tones.
///
/// Views depend on this small interface rather than on a concrete audio
/// plugin, so they can be driven by a fake in tests.
abstract interface class NotePlayer {
  /// Plays [frequencies] (in hertz) together as a single short sound.
  ///
  /// [duration] controls how long the sound rings; when omitted the player's
  /// default is used. Sequences pass a shorter duration so the gap between
  /// notes stays tight.
  Future<void> play(Iterable<double> frequencies, {Duration? duration});

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
  static const Duration _defaultDuration = Duration(milliseconds: 700);

  final AudioPlayer _player = AudioPlayer();

  /// The newest play request. Rapid taps start several stop/play calls at
  /// once; the older ones bail out after their stop so they cannot start a
  /// second tone on top of the newest (which is the buzz heard on iOS and
  /// Android). The last request always wins.
  int _request = 0;

  @override
  Future<void> play(Iterable<double> frequencies, {Duration? duration}) async {
    final voices = frequencies.toList(growable: false);
    if (voices.isEmpty) return;
    try {
      final request = ++_request;
      final wav = toneWav(voices, duration: duration ?? _defaultDuration);
      await _player.stop();
      if (request != _request) return;
      await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
    } catch (error) {
      // Audio is a nice-to-have; never let a platform hiccup break the app.
      debugPrint('Could not play tone: $error');
    }
  }

  @override
  Future<void> dispose() {
    _request++;
    return _player.dispose();
  }
}
