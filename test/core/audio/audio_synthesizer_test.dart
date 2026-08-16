import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/audio/audio_synthesizer.dart';

void main() {
  group('AudioSynthesizer Tests', () {
    test('generateWavBytes produces correct WAV headers and PCM samples', () {
      const sampleRate = 44100;
      const numSamples = 100;
      final wav = AudioSynthesizer.generateWavBytes(
        numSamples,
        sampleRate,
        (t) => 0.5, // Constant amplitude signal
      );

      // Total WAV size should be 44 bytes header + 2 bytes per sample * 100
      expect(wav.length, equals(44 + numSamples * 2));

      // RIFF header
      expect(utf8.decode(wav.sublist(0, 4)), equals('RIFF'));

      // Chunk size = 36 + subchunk2Size (200 bytes) = 236 bytes
      final byteData = ByteData.sublistView(Uint8List.fromList(wav));
      expect(byteData.getUint32(4, Endian.little), equals(236));

      // WAVEfmt 
      expect(utf8.decode(wav.sublist(8, 16)), equals('WAVEfmt '));

      // Subchunk1Size
      expect(byteData.getUint32(16, Endian.little), equals(16));

      // AudioFormat (PCM = 1)
      expect(byteData.getUint16(20, Endian.little), equals(1));

      // NumChannels
      expect(byteData.getUint16(22, Endian.little), equals(1));

      // SampleRate
      expect(byteData.getUint32(24, Endian.little), equals(sampleRate));

      // BitsPerSample
      expect(byteData.getUint16(34, Endian.little), equals(16));

      // data subchunk ID
      expect(utf8.decode(wav.sublist(36, 40)), equals('data'));

      // Subchunk2Size (samples * channels * bytesPerSample = 100 * 1 * 2 = 200)
      expect(byteData.getUint32(40, Endian.little), equals(200));

      // Sample amplitude check (0.5 * 32767 = 16384)
      expect(byteData.getInt16(44, Endian.little), equals(16384));
    });

    test('predefined sfx generators produce non-empty valid wav lists', () {
      const sampleRate = 16000;
      
      final whooshFast = AudioSynthesizer.generateWhooshFast(sampleRate);
      expect(whooshFast, isNotEmpty);
      expect(whooshFast.length, greaterThan(44));
      expect(utf8.decode(whooshFast.sublist(0, 4)), equals('RIFF'));

      final whooshSlow = AudioSynthesizer.generateWhooshSlow(sampleRate);
      expect(whooshSlow, isNotEmpty);
      expect(whooshSlow.length, greaterThan(whooshFast.length));

      final swipeLeftToRight = AudioSynthesizer.generateSwipe(sampleRate, true);
      expect(swipeLeftToRight, isNotEmpty);
      expect(utf8.decode(swipeLeftToRight.sublist(0, 4)), equals('RIFF'));

      final swipeRightToLeft = AudioSynthesizer.generateSwipe(sampleRate, false);
      expect(swipeRightToLeft, isNotEmpty);
      expect(swipeRightToLeft.length, equals(swipeLeftToRight.length));
    });
  });
}
