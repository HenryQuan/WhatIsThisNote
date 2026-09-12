import 'dart:math' as math;
import 'dart:typed_data';

/// Renders [frequencies] (in hertz) mixed together into a short 16-bit mono
/// PCM WAV.
///
/// This is pure Dart, so the same sound is generated on every platform and
/// can be unit tested without an audio plugin. A soft attack, an exponential
/// decay and a short tail keep the tone click-free, and a quiet second
/// harmonic gives it a little body.
Uint8List toneWav(
  List<double> frequencies, {
  Duration duration = const Duration(milliseconds: 700),
  int sampleRate = 44100,
  double amplitude = 0.6,
}) {
  assert(sampleRate > 0, 'sampleRate must be positive');
  assert(
    duration > Duration.zero,
    'duration must be greater than zero',
  );

  final sampleCount =
      duration.inMicroseconds * sampleRate ~/ Duration.microsecondsPerSecond;
  final samples = Int16List(sampleCount);

  final voices = [
    for (final frequency in frequencies)
      if (frequency.isFinite && frequency > 0) frequency,
  ];
  if (voices.isNotEmpty) {
    // Split the amplitude between the voices so a chord does not clip.
    final peak = amplitude / voices.length;
    final attack = (sampleRate * 0.008).round().clamp(1, sampleCount);
    final release = (sampleRate * 0.02).round().clamp(1, sampleCount);
    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final progress = i / sampleCount;
      final attackGain = i < attack ? i / attack : 1.0;
      final releaseGain = sampleCount - i < release
          ? (sampleCount - i) / release
          : 1.0;
      final envelope =
          attackGain * releaseGain * math.exp(-2.5 * progress);

      var value = 0.0;
      for (final frequency in voices) {
        value +=
            math.sin(2 * math.pi * frequency * t) +
            0.25 * math.sin(4 * math.pi * frequency * t);
      }
      final scaled = (value * peak * envelope * 32767).round();
      samples[i] = scaled < -32768
          ? -32768
          : scaled > 32767
          ? 32767
          : scaled;
    }
  }

  return _wavBytes(samples, sampleRate);
}

/// Wraps [samples] in a standard little-endian WAV container.
Uint8List _wavBytes(Int16List samples, int sampleRate) {
  const channels = 1;
  const bitsPerSample = 16;
  final dataSize = samples.length * 2;
  final bytes = ByteData(44 + dataSize);

  void writeAscii(int offset, String text) {
    for (var i = 0; i < text.length; i++) {
      bytes.setUint8(offset + i, text.codeUnitAt(i));
    }
  }

  writeAscii(0, 'RIFF');
  bytes.setUint32(4, 36 + dataSize, Endian.little);
  writeAscii(8, 'WAVE');
  writeAscii(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little); // PCM
  bytes.setUint16(22, channels, Endian.little);
  bytes.setUint32(24, sampleRate, Endian.little);
  bytes.setUint32(
    28,
    sampleRate * channels * bitsPerSample ~/ 8,
    Endian.little,
  );
  bytes.setUint16(32, channels * bitsPerSample ~/ 8, Endian.little);
  bytes.setUint16(34, bitsPerSample, Endian.little);
  writeAscii(36, 'data');
  bytes.setUint32(40, dataSize, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    bytes.setInt16(44 + i * 2, samples[i], Endian.little);
  }

  return bytes.buffer.asUint8List();
}
