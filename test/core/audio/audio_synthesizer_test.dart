import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/audio/audio_synthesizer.dart';

void main() {
  group('generateWavBytes', () {
    test('produces a valid RIFF/WAVE PCM header', () {
      final bytes = AudioSynthesizer.generateWavBytes(100, 16000, (t) => 0.0);
      expect(bytes.length, 44 + 100 * 2);

      final bd = ByteData.sublistView(Uint8List.fromList(bytes));
      // RIFF magic
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 16)), 'WAVEfmt ');
      // PCM, mono, 16-bit
      expect(bd.getUint16(20, Endian.little), 1); // audio format = PCM
      expect(bd.getUint16(22, Endian.little), 1); // channels
      expect(bd.getUint32(24, Endian.little), 16000); // sample rate
      expect(bd.getUint16(34, Endian.little), 16); // bits per sample
      expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');
    });

    test('synthesizes a sine wave into clamped 16-bit samples', () {
      final bytes = AudioSynthesizer.generateWavBytes(
        2000,
        16000,
        (t) => mathSin(2 * 3.14159 * 440 * t),
      );
      final bd = ByteData.sublistView(Uint8List.fromList(bytes));

      // Samples live in [-32767, 32767]; a pure sine must hit both extremes.
      int minV = 0, maxV = 0;
      for (int i = 0; i < 2000; i++) {
        final s = bd.getInt16(44 + i * 2, Endian.little);
        expect(s, inInclusiveRange(-32767, 32767));
        if (s < minV) minV = s;
        if (s > maxV) maxV = s;
      }
      expect(minV, lessThan(-30000));
      expect(maxV, greaterThan(30000));
    });

    test('clamps out-of-range synthesis values instead of overflowing', () {
      final bytes = AudioSynthesizer.generateWavBytes(10, 8000, (t) => 999.0);
      final bd = ByteData.sublistView(Uint8List.fromList(bytes));
      for (int i = 0; i < 10; i++) {
        expect(bd.getInt16(44 + i * 2, Endian.little), 32767);
      }
    });
  });

  group('sound effect generators', () {
    final generators = <String, List<int> Function(int)>{
      'whooshFast': AudioSynthesizer.generateWhooshFast,
      'whooshSlow': AudioSynthesizer.generateWhooshSlow,
      'swipe': (sr) => AudioSynthesizer.generateSwipe(sr, true),
      'sweepUp': AudioSynthesizer.generateSweepUp,
      'sweepDown': AudioSynthesizer.generateSweepDown,
      'pop': AudioSynthesizer.generatePop,
      'popDeep': AudioSynthesizer.generatePopDeep,
      'boom': AudioSynthesizer.generateBoom,
      'thud': AudioSynthesizer.generateThud,
      'punch': AudioSynthesizer.generatePunch,
      'stamp': AudioSynthesizer.generateStamp,
      'bell': AudioSynthesizer.generateBell,
      'chime': AudioSynthesizer.generateChime,
      'blip': AudioSynthesizer.generateBlip,
      'ding': AudioSynthesizer.generateDing,
      'ping': AudioSynthesizer.generatePing,
      'drop': AudioSynthesizer.generateDrop,
      'boing': AudioSynthesizer.generateBoing,
      'bounce': AudioSynthesizer.generateBounce,
      'squeak': AudioSynthesizer.generateSqueak,
      'coin': AudioSynthesizer.generateCoin,
      'sparkle': AudioSynthesizer.generateSparkle,
      'glitch': AudioSynthesizer.generateGlitch,
      'rise': AudioSynthesizer.generateRise,
      'tension': AudioSynthesizer.generateTension,
      'bassDrop': AudioSynthesizer.generateBassDrop,
      'reverse': AudioSynthesizer.generateReverse,
      'echo': AudioSynthesizer.generateEcho,
      'whoosh': AudioSynthesizer.generateWhoosh,
      'sweep': AudioSynthesizer.generateSweep,
      'tapeStop': AudioSynthesizer.generateTapeStop,
      'levelUp': AudioSynthesizer.generateLevelUp,
      'fail': AudioSynthesizer.generateFail,
      'correct': AudioSynthesizer.generateCorrect,
      'wrong': AudioSynthesizer.generateWrong,
      'powerUp': AudioSynthesizer.generatePowerUp,
      'gameOver': AudioSynthesizer.generateGameOver,
      'swishFuturistic': AudioSynthesizer.generateSwishFuturistic,
      'sparkleMagical': AudioSynthesizer.generateSparkleMagical,
      'cymbalSwell': AudioSynthesizer.generateCymbalSwell,
      'laserShot': AudioSynthesizer.generateLaserShot,
      'heavyImpact': AudioSynthesizer.generateHeavyImpact,
      'synthChime': AudioSynthesizer.generateSynthChime,
    };

    generators.forEach((name, gen) {
      test('$name produces a valid non-empty WAV at 44.1kHz', () {
        final bytes = gen(44100);
        expect(bytes.length, greaterThan(44), reason: '$name must have a header');
        expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(bytes.sublist(8, 16)), 'WAVEfmt ');
        expect(String.fromCharCodes(bytes.sublist(36, 40)), 'data');

        // Even-length sample data (16-bit mono).
        expect((bytes.length - 44) % 2, 0);

        final bd = ByteData.sublistView(Uint8List.fromList(bytes));
        final numSamples = (bytes.length - 44) ~/ 2;
        // All samples are in range.
        for (int i = 0; i < numSamples; i += 997) { // stride for speed
          expect(bd.getInt16(44 + i * 2, Endian.little), inInclusiveRange(-32767, 32767));
        }
      });
    });
  });
}

double mathSin(double x) {
  // Local sine to keep the fixture free of dart:math import noise in the test.
  var term = x;
  var sum = x;
  for (int n = 1; n < 6; n++) {
    term *= -x * x / ((2 * n) * (2 * n + 1));
    sum += term;
  }
  return sum;
}
