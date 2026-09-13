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

  /// Starts a metronome click track. [clicks] is one bar of frequencies played
  /// in order, one every [beat], repeating until [stopClickTrack] is called.
  ///
  /// Unlike [play], the whole bar is rendered up front and looped by the audio
  /// backend, so the beats stay even and in time instead of being re-queued
  /// over a channel on every tick.
  Future<void> startClickTrack(List<double> clicks, Duration beat);

  /// Stops a track started by [startClickTrack].
  Future<void> stopClickTrack();

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

  /// A second player dedicated to the metronome so the click loop never has to
  /// stop the note player (and vice versa) when both are sounding.
  final AudioPlayer _clickPlayer = AudioPlayer();

  /// The newest play request. Rapid taps start several stop/play calls at
  /// once; the older ones bail out after their stop so they cannot start a
  /// second tone on top of the newest (which is the buzz heard on iOS and
  /// Android). The last request always wins.
  int _request = 0;

  /// Rendering a tone is pure-Dart DSP, and long low notes are the most
  /// expensive. The metronome and a held note repeat the same request over and
  /// over, so each distinct request is rendered once and reused. The map is a
  /// plain insertion-ordered map, and the oldest entry is dropped when the cap
  /// is reached to bound memory.
  final Map<String, Uint8List> _wavCache = {};
  static const int _maxCachedTones = 64;

  @override
  Future<void> play(Iterable<double> frequencies, {Duration? duration}) async {
    final voices = frequencies.toList(growable: false);
    if (voices.isEmpty) return;
    try {
      final request = ++_request;
      final wav = _wavFor(voices, duration);
      await _player.stop();
      if (request != _request) return;
      await _player.play(BytesSource(wav, mimeType: 'audio/wav'));
    } catch (error) {
      // Audio is a nice-to-have; never let a platform hiccup break the app.
      debugPrint('Could not play tone: $error');
    }
  }

  Uint8List _wavFor(List<double> voices, Duration? duration) {
    final key =
        '${voices.join(',')}|${(duration ?? _defaultDuration).inMicroseconds}';
    final cached = _wavCache[key];
    if (cached != null) return cached;
    final wav = toneWav(voices, duration: duration ?? _defaultDuration);
    if (_wavCache.length >= _maxCachedTones) {
      _wavCache.remove(_wavCache.keys.first);
    }
    return _wavCache[key] = wav;
  }

  /// Rendered bars, keyed by the click bar and beat, capped like [_wavCache].
  final Map<String, Uint8List> _barCache = {};
  static const int _maxCachedBars = 12;

  /// Newest click-track request, so a slow start cannot resume over a newer
  /// one after the user changed tempo or stopped.
  int _clickRequest = 0;

  @override
  Future<void> startClickTrack(List<double> clicks, Duration beat) async {
    final voices = clicks.toList(growable: false);
    if (voices.isEmpty || beat <= Duration.zero) return;
    try {
      final request = ++_clickRequest;
      final wav = _barFor(voices, beat);
      await _clickPlayer.setReleaseMode(ReleaseMode.loop);
      if (request != _clickRequest) return;
      await _clickPlayer.setSource(BytesSource(wav, mimeType: 'audio/wav'));
      if (request != _clickRequest) return;
      await _clickPlayer.resume();
    } catch (error) {
      debugPrint('Could not start click track: $error');
    }
  }

  @override
  Future<void> stopClickTrack() async {
    _clickRequest++;
    try {
      await _clickPlayer.stop();
    } catch (error) {
      debugPrint('Could not stop click track: $error');
    }
  }

  Uint8List _barFor(List<double> clicks, Duration beat) {
    final key = '${clicks.join(',')}|${beat.inMicroseconds}';
    final cached = _barCache[key];
    if (cached != null) return cached;
    final wav = barWav(clicks, step: beat);
    if (_barCache.length >= _maxCachedBars) {
      _barCache.remove(_barCache.keys.first);
    }
    return _barCache[key] = wav;
  }

  @override
  Future<void> dispose() {
    _request++;
    _clickRequest++;
    _wavCache.clear();
    _barCache.clear();
    _player.dispose();
    return _clickPlayer.dispose();
  }
}
