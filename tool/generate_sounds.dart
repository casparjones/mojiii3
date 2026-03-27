// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 44100;
const int bitsPerSample = 16;
const int numChannels = 1;

/// Generate a sine wave tone with fade-in and fade-out to avoid clicks.
List<int> generateTone(double frequency, double durationMs,
    {double volume = 0.8}) {
  final numSamples = (sampleRate * durationMs / 1000).round();
  final samples = <int>[];
  final fadeLength = (numSamples * 0.05).round().clamp(10, 200);

  for (int i = 0; i < numSamples; i++) {
    double t = i / sampleRate;
    double sample = sin(2 * pi * frequency * t) * volume;

    // Fade in
    if (i < fadeLength) {
      sample *= i / fadeLength;
    }
    // Fade out
    if (i > numSamples - fadeLength) {
      sample *= (numSamples - i) / fadeLength;
    }

    samples.add((sample * 32767).round().clamp(-32768, 32767));
  }
  return samples;
}

/// Generate a frequency sweep from startFreq to endFreq.
List<int> generateSweep(double startFreq, double endFreq, double durationMs,
    {double volume = 0.8}) {
  final numSamples = (sampleRate * durationMs / 1000).round();
  final samples = <int>[];
  final fadeLength = (numSamples * 0.05).round().clamp(10, 200);

  double phase = 0;
  for (int i = 0; i < numSamples; i++) {
    double t = i / numSamples;
    double freq = startFreq + (endFreq - startFreq) * t;
    phase += 2 * pi * freq / sampleRate;
    double sample = sin(phase) * volume;

    // Fade in
    if (i < fadeLength) {
      sample *= i / fadeLength;
    }
    // Fade out
    if (i > numSamples - fadeLength) {
      sample *= (numSamples - i) / fadeLength;
    }

    samples.add((sample * 32767).round().clamp(-32768, 32767));
  }
  return samples;
}

/// Concatenate multiple tone segments into one.
List<int> concatenate(List<List<int>> segments) {
  final result = <int>[];
  for (final seg in segments) {
    result.addAll(seg);
  }
  return result;
}

/// Write samples as a 16-bit PCM mono WAV file.
void writeWav(String path, List<int> samples) {
  final dataSize = samples.length * 2; // 2 bytes per 16-bit sample
  final fileSize = 36 + dataSize;

  final buffer = ByteData(44 + dataSize);
  int offset = 0;

  // RIFF header
  void writeString(String s) {
    for (int i = 0; i < s.length; i++) {
      buffer.setUint8(offset++, s.codeUnitAt(i));
    }
  }

  writeString('RIFF');
  buffer.setUint32(offset, fileSize, Endian.little);
  offset += 4;
  writeString('WAVE');

  // fmt sub-chunk
  writeString('fmt ');
  buffer.setUint32(offset, 16, Endian.little); // SubChunk1Size
  offset += 4;
  buffer.setUint16(offset, 1, Endian.little); // AudioFormat (PCM)
  offset += 2;
  buffer.setUint16(offset, numChannels, Endian.little);
  offset += 2;
  buffer.setUint32(offset, sampleRate, Endian.little);
  offset += 4;
  buffer.setUint32(
      offset, sampleRate * numChannels * bitsPerSample ~/ 8, Endian.little);
  offset += 4;
  buffer.setUint16(
      offset, numChannels * bitsPerSample ~/ 8, Endian.little); // BlockAlign
  offset += 2;
  buffer.setUint16(offset, bitsPerSample, Endian.little);
  offset += 2;

  // data sub-chunk
  writeString('data');
  buffer.setUint32(offset, dataSize, Endian.little);
  offset += 4;

  for (final sample in samples) {
    buffer.setInt16(offset, sample, Endian.little);
    offset += 2;
  }

  File(path).writeAsBytesSync(buffer.buffer.asUint8List());
}

void main() {
  final outDir = 'assets/sounds';
  Directory(outDir).createSync(recursive: true);

  // 1. match.wav - ascending pling (880Hz + 1100Hz, each 80ms)
  final matchSamples = concatenate([
    generateTone(880, 80),
    generateTone(1100, 80),
  ]);
  writeWav('$outDir/match.wav', matchSamples);
  print('Generated match.wav (${matchSamples.length} samples)');

  // 2. swap.wav - fast whoosh (frequency sweep 300Hz -> 600Hz, 120ms)
  final swapSamples = generateSweep(300, 600, 120);
  writeWav('$outDir/swap.wav', swapSamples);
  print('Generated swap.wav (${swapSamples.length} samples)');

  // 3. combo.wav - ascending tone sequence (440, 660, 880Hz, each 60ms)
  final comboSamples = concatenate([
    generateTone(440, 60),
    generateTone(660, 60),
    generateTone(880, 60),
  ]);
  writeWav('$outDir/combo.wav', comboSamples);
  print('Generated combo.wav (${comboSamples.length} samples)');

  // 4. win.wav - C-E-G-C arpeggio ascending (each 100ms)
  final winSamples = concatenate([
    generateTone(523.25, 100), // C5
    generateTone(659.25, 100), // E5
    generateTone(783.99, 100), // G5
    generateTone(1046.50, 100), // C6
  ]);
  writeWav('$outDir/win.wav', winSamples);
  print('Generated win.wav (${winSamples.length} samples)');

  // 5. lose.wav - sad descending (400, 350, 300, 250Hz, each 120ms)
  final loseSamples = concatenate([
    generateTone(400, 120),
    generateTone(350, 120),
    generateTone(300, 120),
    generateTone(250, 120),
  ]);
  writeWav('$outDir/lose.wav', loseSamples);
  print('Generated lose.wav (${loseSamples.length} samples)');

  // 6. tap.wav - short click (1000Hz, 30ms)
  final tapSamples = generateTone(1000, 30);
  writeWav('$outDir/tap.wav', tapSamples);
  print('Generated tap.wav (${tapSamples.length} samples)');

  print('\nAll sounds generated in $outDir/');
}
