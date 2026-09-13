import 'dart:math' as math;
import 'dart:typed_data';

/// Renders [frequencies] (in hertz) mixed together into a short 16-bit mono
/// PCM WAV.
///
/// This is pure Dart, so the same sound is generated on every platform and
/// can be unit tested without an audio plugin. A soft attack, an exponential
/// decay and a short tail keep the tone click-free. Mid and high notes are a
/// fundamental with a quiet octave; low notes add overtones so they stay
/// audible on the small speakers phones use, without brightening the rest.
Uint8List toneWav(
  List<double> frequencies, {
  Duration duration = const Duration(milliseconds: 700),
  int sampleRate = 44100,
  double amplitude = 0.6,
}) => _wavBytes(
  _toneSamples(
    frequencies,
    duration: duration,
    sampleRate: sampleRate,
    amplitude: amplitude,
  ),
  sampleRate,
);

/// Renders one seamless bar for a loop player: [frequencies] are played one
/// after another, each starting every [step] and ringing for [tone]. The bar
/// is mostly silence with short clicks, so a loop player can repeat it without
/// a seam, which keeps a metronome's beats even and in time.
Uint8List barWav(
  List<double> frequencies, {
  required Duration step,
  Duration tone = const Duration(milliseconds: 45),
  int sampleRate = 44100,
  double amplitude = 0.6,
}) {
  assert(step > Duration.zero, 'step must be greater than zero');
  final stepSamples =
      step.inMicroseconds * sampleRate ~/ Duration.microsecondsPerSecond;
  final bar = Int16List(stepSamples * frequencies.length);
  final clicks = <double, Int16List>{};
  for (var i = 0; i < frequencies.length; i++) {
    final click = clicks.putIfAbsent(
      frequencies[i],
      () => _toneSamples(
        [frequencies[i]],
        duration: tone,
        sampleRate: sampleRate,
        amplitude: amplitude,
      ),
    );
    final start = i * stepSamples;
    final end = start + click.length < bar.length
        ? start + click.length
        : bar.length;
    bar.setRange(start, end, click);
  }
  return _wavBytes(bar, sampleRate);
}

Int16List _toneSamples(
  List<double> frequencies, {
  Duration duration = const Duration(milliseconds: 700),
  int sampleRate = 44100,
  double amplitude = 0.6,
}) {
  assert(sampleRate > 0, 'sampleRate must be positive');
  assert(duration > Duration.zero, 'duration must be greater than zero');

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
    // Precompute each voice's partials once so the sample loop only sums
    // sines, and normalise each voice so the mix still respects [peak].
    final voicePartials = [
      for (final frequency in voices) _partialsFor(frequency, sampleRate),
    ];
    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      final progress = i / sampleCount;
      final attackGain = i < attack ? i / attack : 1.0;
      final releaseGain = sampleCount - i < release
          ? (sampleCount - i) / release
          : 1.0;
      final envelope = attackGain * releaseGain * math.exp(-2.5 * progress);

      var value = 0.0;
      for (final partials in voicePartials) {
        for (final (frequency, gain) in partials) {
          value += gain * math.sin(2 * math.pi * frequency * t);
        }
      }
      final scaled = (value * peak * envelope * 32767).round();
      samples[i] = scaled < -32768
          ? -32768
          : scaled > 32767
          ? 32767
          : scaled;
    }
  }

  return samples;
}

/// Middle C's frequency, in hertz. Notes at or above it keep the original warm
/// tone; notes below it gain overtones so a phone speaker can still voice them.
const double _middleCHz = 261.6256;

/// The most overtones one low voice is given, however low it is.
const int _maxHarmonics = 16;

/// The `(frequency, gain)` partials that make up one voice.
///
/// The original tone is a fundamental plus a quiet octave, and it is kept
/// exactly for C4 and above. As a note drops below C4 it crossfades to a soft
/// sawtooth with more overtones: a bass fundamental is below what a phone
/// speaker reproduces, but its overtones are not. The crossfade keeps the
/// change gradual, and harmonics never reach Nyquist.
List<(double, double)> _partialsFor(double frequency, int sampleRate) {
  final nyquist = sampleRate / 2;
  final richness = (math.log(_middleCHz / frequency) / math.ln2).clamp(
    0.0,
    1.0,
  );
  if (richness == 0) {
    return [
      for (final (harmonic, gain) in const [(1, 1.0), (2, 0.25)])
        if (frequency * harmonic < nyquist) (frequency * harmonic, gain),
    ];
  }

  final count = math.min(_maxHarmonics, 2 + (richness * 14).round());
  final saw = <double>[];
  var sawSum = 0.0;
  for (var harmonic = 1; harmonic <= count; harmonic++) {
    if (frequency * harmonic >= nyquist) break;
    final gain = 1 / harmonic;
    saw.add(gain);
    sawSum += gain;
  }
  if (sawSum == 0) return const [];

  return [
    for (var i = 0; i < saw.length; i++)
      (
        frequency * (i + 1),
        switch (i) {
          0 => (1 - richness) + (saw[i] / sawSum) * richness,
          1 => 0.25 * (1 - richness) + (saw[i] / sawSum) * richness,
          _ => (saw[i] / sawSum) * richness,
        },
      ),
  ];
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
