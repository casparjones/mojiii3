// ignore_for_file: avoid_print
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int sampleRate = 44100;
const int bitsPerSample = 16;
const int numChannels = 2; // Stereo
const double bpm = 80.0;

/// Duration of one beat in seconds.
final double beatDuration = 60.0 / bpm;

/// Total duration in seconds (~45 seconds, 60 beats at 80 BPM).
final int totalBeats = 60;
final double totalDuration = totalBeats * beatDuration;
final int totalSamples = (totalDuration * sampleRate).round();

// ---------------------------------------------------------------------------
// Note frequencies (Hz) for the chord progression: C - Am - F - G
// Each chord lasts 4 beats. The progression repeats.
// ---------------------------------------------------------------------------

// Chord root notes (octave 3 for bass, octave 4 for pads, octave 5 for melody)
const double c3 = 130.81;
const double d3 = 146.83;
const double e3 = 164.81;
const double f3 = 174.61;
const double g3 = 196.00;
const double a3 = 220.00;
const double b3 = 246.94;

const double c4 = 261.63;
const double d4 = 293.66;
const double e4 = 329.63;
const double f4 = 349.23;
const double g4 = 392.00;
const double a4 = 440.00;
const double b4 = 493.88;

const double c5 = 523.25;
const double d5 = 587.33;
const double e5 = 659.25;
const double f5 = 698.46;
const double g5 = 783.99;
const double a5 = 880.00;

/// Chord definitions: each chord is [root, third, fifth] in octave 4.
class Chord {
  final double bass; // bass note (octave 3)
  final List<double> padNotes; // pad notes (octave 4)
  final List<double> melodyPool; // available melody notes (octave 5)

  const Chord(this.bass, this.padNotes, this.melodyPool);
}

// C major: C-E-G
const chordC = Chord(c3, [c4, e4, g4], [c5, e5, g5]);
// A minor: A-C-E
const chordAm = Chord(a3, [a4, c4, e4], [a5, c5, e5]);
// F major: F-A-C
const chordF = Chord(f3, [f4, a4, c4], [f5, a5, c5]);
// G major: G-B-D
const chordG = Chord(g3, [g4, b4, d4], [g5, b4, d5]);

/// The 4-chord progression, each lasting 4 beats.
const List<Chord> progression = [chordC, chordAm, chordF, chordG];

/// Soft sine wave oscillator.
double sineOsc(double phase) => sin(phase);

/// Triangle wave oscillator (softer than square).
double triangleOsc(double phase) {
  final p = (phase / (2 * pi)) % 1.0;
  if (p < 0.25) return 4.0 * p;
  if (p < 0.75) return 2.0 - 4.0 * p;
  return -4.0 + 4.0 * p;
}

/// Soft saw (filtered-ish) - mix of sine harmonics.
double softSawOsc(double phase) {
  return sineOsc(phase) * 0.6 +
      sineOsc(phase * 2) * 0.25 +
      sineOsc(phase * 3) * 0.1 +
      sineOsc(phase * 4) * 0.05;
}

/// Simple low-pass filter (single-pole IIR).
class LowPassFilter {
  double _prev = 0.0;
  final double alpha;

  LowPassFilter(double cutoffHz)
      : alpha = (2.0 * pi * cutoffHz / sampleRate) /
            (1.0 + 2.0 * pi * cutoffHz / sampleRate);

  double process(double input) {
    _prev = _prev + alpha * (input - _prev);
    return _prev;
  }
}

/// Generate the background music as stereo interleaved samples.
List<int> generateMusic() {
  final rng = Random(42); // deterministic seed for reproducibility
  final samplesL = Float64List(totalSamples);
  final samplesR = Float64List(totalSamples);

  // Phase accumulators for each voice
  double bassPhase = 0.0;
  double pad1Phase = 0.0;
  double pad2Phase = 0.0;
  double pad3Phase = 0.0;
  double melodyPhase = 0.0;
  double ambientPhase1 = 0.0;
  double ambientPhase2 = 0.0;

  // Filters
  final bassFilter = LowPassFilter(300.0);
  final padFilter = LowPassFilter(2000.0);
  final melodyFilter = LowPassFilter(3000.0);

  // Melody pattern: pre-generate a simple repeating pattern
  // Each melody note lasts 2 beats, picking from chord tones
  final melodyNotes = <double>[];
  final melodyStarts = <int>[]; // sample index where each note starts
  final melodyDurations = <int>[]; // duration in samples

  // Generate melody pattern for all beats
  for (int beat = 0; beat < totalBeats; beat += 2) {
    final chordIndex = ((beat ~/ 4) % progression.length);
    final chord = progression[chordIndex];
    final noteIdx = rng.nextInt(chord.melodyPool.length);
    melodyNotes.add(chord.melodyPool[noteIdx]);
    melodyStarts.add((beat * beatDuration * sampleRate).round());
    melodyDurations.add((2 * beatDuration * sampleRate).round());
  }

  // Current melody note index
  int currentMelodyIdx = 0;
  double currentMelodyFreq = melodyNotes[0];
  double melodyEnvelope = 0.0;

  for (int i = 0; i < totalSamples; i++) {
    final t = i / sampleRate; // time in seconds
    final beat = t / beatDuration; // current beat (fractional)
    final chordIndex = ((beat ~/ 4).toInt() % progression.length);
    final chord = progression[chordIndex];

    // -----------------------------------------------------------------------
    // Bass: long sustained notes, one per chord (4 beats)
    // -----------------------------------------------------------------------
    final bassFreq = chord.bass;
    bassPhase += 2 * pi * bassFreq / sampleRate;
    final beatInChord = beat % 4.0;
    // Gentle envelope: fade in over first half-beat, sustain, fade out last half-beat
    double bassEnv = 1.0;
    if (beatInChord < 0.5) {
      bassEnv = beatInChord / 0.5;
    } else if (beatInChord > 3.5) {
      bassEnv = (4.0 - beatInChord) / 0.5;
    }
    final bassSample =
        triangleOsc(bassPhase) * 0.18 * bassEnv;
    final bassFiltered = bassFilter.process(bassSample);

    // -----------------------------------------------------------------------
    // Pad: 3-note chord, sustained with slow tremolo
    // -----------------------------------------------------------------------
    pad1Phase += 2 * pi * chord.padNotes[0] / sampleRate;
    pad2Phase += 2 * pi * chord.padNotes[1] / sampleRate;
    pad3Phase += 2 * pi * chord.padNotes[2] / sampleRate;

    // Slow tremolo for movement
    final tremolo = 0.85 + 0.15 * sin(2 * pi * 0.3 * t);
    // Pad envelope similar to bass
    double padEnv = 1.0;
    if (beatInChord < 1.0) {
      padEnv = beatInChord;
    } else if (beatInChord > 3.0) {
      padEnv = (4.0 - beatInChord);
    }

    final padSample = (sineOsc(pad1Phase) * 0.08 +
            sineOsc(pad2Phase) * 0.06 +
            sineOsc(pad3Phase) * 0.06) *
        tremolo *
        padEnv;
    final padFiltered = padFilter.process(padSample);

    // -----------------------------------------------------------------------
    // Melody: simple notes every 2 beats
    // -----------------------------------------------------------------------
    // Update current melody note
    if (currentMelodyIdx < melodyNotes.length - 1 &&
        i >= melodyStarts[currentMelodyIdx + 1]) {
      currentMelodyIdx++;
      currentMelodyFreq = melodyNotes[currentMelodyIdx];
    }

    // Melody envelope: attack and decay
    final melStart = melodyStarts[currentMelodyIdx];
    final melDur = melodyDurations[currentMelodyIdx];
    final melPos = i - melStart;
    if (melPos >= 0 && melPos < melDur) {
      final relPos = melPos / melDur;
      // Quick attack, long decay
      if (relPos < 0.05) {
        melodyEnvelope = relPos / 0.05;
      } else {
        melodyEnvelope = 1.0 - (relPos - 0.05) * 0.7;
        if (melodyEnvelope < 0) melodyEnvelope = 0;
      }
    } else {
      melodyEnvelope = 0;
    }

    melodyPhase += 2 * pi * currentMelodyFreq / sampleRate;
    final melodySample =
        sineOsc(melodyPhase) * 0.10 * melodyEnvelope;
    final melodyFiltered = melodyFilter.process(melodySample);

    // -----------------------------------------------------------------------
    // Ambient texture: high-frequency whispy tones
    // -----------------------------------------------------------------------
    final ambFreq1 = 1200.0 + 200.0 * sin(2 * pi * 0.07 * t);
    final ambFreq2 = 1600.0 + 300.0 * sin(2 * pi * 0.05 * t + 1.0);
    ambientPhase1 += 2 * pi * ambFreq1 / sampleRate;
    ambientPhase2 += 2 * pi * ambFreq2 / sampleRate;
    final ambientSample = (sineOsc(ambientPhase1) * 0.02 +
            sineOsc(ambientPhase2) * 0.015) *
        (0.7 + 0.3 * sin(2 * pi * 0.1 * t));

    // -----------------------------------------------------------------------
    // Mix – stereo spread: bass center, pad slightly wide, melody slightly
    // offset, ambient wide
    samplesL[i] = bassFiltered +
        padFiltered * 0.9 +
        melodyFiltered * 1.1 +
        ambientSample * 1.2;
    samplesR[i] = bassFiltered +
        padFiltered * 1.1 +
        melodyFiltered * 0.9 +
        ambientSample * 0.8;

    // Keep phase accumulators from growing too large
    if (bassPhase > 2 * pi * 1000) bassPhase -= 2 * pi * 1000;
    if (pad1Phase > 2 * pi * 1000) pad1Phase -= 2 * pi * 1000;
    if (pad2Phase > 2 * pi * 1000) pad2Phase -= 2 * pi * 1000;
    if (pad3Phase > 2 * pi * 1000) pad3Phase -= 2 * pi * 1000;
    if (melodyPhase > 2 * pi * 1000) melodyPhase -= 2 * pi * 1000;
    if (ambientPhase1 > 2 * pi * 1000) ambientPhase1 -= 2 * pi * 1000;
    if (ambientPhase2 > 2 * pi * 1000) ambientPhase2 -= 2 * pi * 1000;
  }

  // -------------------------------------------------------------------------
  // Post-processing: fade in/out and loop crossfade
  // -------------------------------------------------------------------------
  final fadeInSamples = (3.0 * sampleRate).round(); // 3 second fade in
  final crossfadeSamples = (2.0 * sampleRate).round(); // 2 second crossfade

  // Fade in
  for (int i = 0; i < fadeInSamples && i < totalSamples; i++) {
    final envelope = i / fadeInSamples;
    samplesL[i] *= envelope;
    samplesR[i] *= envelope;
  }

  // Crossfade: blend the end into the beginning for seamless looping
  // The last crossfadeSamples of the track are blended with the first
  // crossfadeSamples
  for (int i = 0; i < crossfadeSamples; i++) {
    final endIdx = totalSamples - crossfadeSamples + i;
    if (endIdx < 0 || endIdx >= totalSamples) continue;
    final fadeOut = 1.0 - (i / crossfadeSamples); // 1 -> 0
    final fadeIn = i / crossfadeSamples; // 0 -> 1

    // Blend end samples into beginning
    samplesL[i] = samplesL[i] * fadeIn + samplesL[endIdx] * fadeOut;
    samplesR[i] = samplesR[i] * fadeIn + samplesR[endIdx] * fadeOut;

    // Fade out the end
    samplesL[endIdx] *= fadeOut;
    samplesR[endIdx] *= fadeOut;
  }

  // -------------------------------------------------------------------------
  // Normalize and convert to 16-bit interleaved stereo
  // -------------------------------------------------------------------------
  double maxVal = 0;
  for (int i = 0; i < totalSamples; i++) {
    if (samplesL[i].abs() > maxVal) maxVal = samplesL[i].abs();
    if (samplesR[i].abs() > maxVal) maxVal = samplesR[i].abs();
  }

  // Normalize to 0.7 peak (leave headroom, keep it quiet)
  final normalizeGain = maxVal > 0 ? 0.7 / maxVal : 1.0;

  final interleaved = <int>[];
  for (int i = 0; i < totalSamples; i++) {
    final l = (samplesL[i] * normalizeGain * 32767).round().clamp(-32768, 32767);
    final r = (samplesR[i] * normalizeGain * 32767).round().clamp(-32768, 32767);
    interleaved.add(l);
    interleaved.add(r);
  }

  return interleaved;
}

/// Write stereo interleaved samples as a 16-bit PCM WAV file.
void writeWavStereo(String path, List<int> interleavedSamples) {
  final numSampleFrames = interleavedSamples.length ~/ 2;
  final dataSize = interleavedSamples.length * 2; // 2 bytes per sample
  final fileSize = 36 + dataSize;

  final buffer = ByteData(44 + dataSize);
  int offset = 0;

  void writeString(String s) {
    for (int i = 0; i < s.length; i++) {
      buffer.setUint8(offset++, s.codeUnitAt(i));
    }
  }

  // RIFF header
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
  buffer.setUint16(offset, numChannels, Endian.little); // Channels
  offset += 2;
  buffer.setUint32(offset, sampleRate, Endian.little); // SampleRate
  offset += 4;
  buffer.setUint32(offset, sampleRate * numChannels * bitsPerSample ~/ 8,
      Endian.little); // ByteRate
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

  for (final sample in interleavedSamples) {
    buffer.setInt16(offset, sample, Endian.little);
    offset += 2;
  }

  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(buffer.buffer.asUint8List());
  print('Written: $path (${(fileSize / 1024).toStringAsFixed(1)} KB, '
      '${(numSampleFrames / sampleRate).toStringAsFixed(1)}s)');
}

void main() {
  print('Generating ambient background music...');
  print('  BPM: $bpm');
  print('  Duration: ${totalDuration.toStringAsFixed(1)}s ($totalBeats beats)');
  print('  Format: ${sampleRate}Hz, $bitsPerSample-bit, stereo');
  print('  Chord progression: C - Am - F - G');
  print('');

  final samples = generateMusic();
  writeWavStereo('assets/sounds/background_music.wav', samples);

  print('\nDone! Background music generated.');
}
