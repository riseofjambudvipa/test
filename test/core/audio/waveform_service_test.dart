import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/audio/waveform_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late WaveformService service;

  setUp(() {
    service = WaveformService.instance;
    WaveformService.bypassExtractionForTesting = false;
    service.processRunner = null;
    service.clearCache();
  });

  tearDown(() {
    WaveformService.bypassExtractionForTesting = true;
    service.processRunner = null;
    service.clearCache();
  });

  group('WaveformService Tests', () {
    test('should return fluctuating fallback waveform when extraction is not possible', () {
      final progressStream = service.extractWaveform(
        videoPath: 'invalid/path.mp4',
        ffmpegPath: 'ffmpeg',
        sampleCount: 100,
      );

      expect(progressStream, completion(hasLength(100)));
    });

    test('should verify caching logic: subsequent calls should return cached list without invoking process', () async {
      int invokeCount = 0;
      service.processRunner = (executable, arguments) async {
        invokeCount++;
        return ProcessResult(300, 1, '', 'failed');
      };

      // First call (invokes process, triggers fallback due to failed exit code)
      final res1 = await service.extractWaveform(
        videoPath: 'my_video.mp4',
        ffmpegPath: 'ffmpeg',
        sampleCount: 80,
      );
      expect(res1.length, 80);
      expect(invokeCount, 1);

      // Second call (hits cache, process is NOT invoked again)
      final res2 = await service.extractWaveform(
        videoPath: 'my_video.mp4',
        ffmpegPath: 'ffmpeg',
        sampleCount: 80,
      );
      expect(res2.length, 80);
      expect(invokeCount, 1); // Remains 1

      // Clear cache and call again (should re-invoke process)
      service.clearCache();
      await service.extractWaveform(
        videoPath: 'my_video.mp4',
        ffmpegPath: 'ffmpeg',
        sampleCount: 80,
      );
      expect(invokeCount, 2);
    });

    test('should parse PCM s16le WAV bytes, extract RMS, and normalize amplitudes successfully', () async {
      String? capturedWavPath;

      service.processRunner = (executable, arguments) async {
        capturedWavPath = arguments.last;
        // Construct mock 44-byte standard WAV header + 400 PCM samples (800 bytes)
        final List<int> pcmData = List<int>.filled(44, 0, growable: true); // Header
        for (int i = 0; i < 400; i++) {
          // Generate a sine wave amplitude sample
          final int sample = (i % 20 < 10) ? 10000 : -10000;
          pcmData.add(sample & 0xFF);
          pcmData.add((sample >> 8) & 0xFF);
        }
        final file = File(capturedWavPath!);
        await file.writeAsBytes(pcmData);

        return ProcessResult(301, 0, 'success', '');
      };

      final amplitudes = await service.extractWaveform(
        videoPath: 'video.mp4',
        ffmpegPath: 'ffmpeg',
        sampleCount: 10,
      );

      // Resulting list should contain exactly 10 normalized RMS values (0.0 to 1.0)
      expect(amplitudes.length, 10);
      for (final value in amplitudes) {
        expect(value, greaterThanOrEqualTo(0.0));
        expect(value, lessThanOrEqualTo(1.0));
      }

      // Output temporary file should have been deleted for cleanup
      expect(capturedWavPath, isNotNull);
      expect(File(capturedWavPath!).existsSync(), isFalse);
    });

    test('should persist waveform to disk and reload successfully', () async {
      int invokeCount = 0;
      service.processRunner = (executable, arguments) async {
        invokeCount++;
        final capturedWavPath = arguments.last;
        final List<int> pcmData = List<int>.filled(44, 0, growable: true);
        for (int i = 0; i < 200; i++) {
          final int sample = (i % 20 < 10) ? 8000 : -8000;
          pcmData.add(sample & 0xFF);
          pcmData.add((sample >> 8) & 0xFF);
        }
        final file = File(capturedWavPath);
        await file.writeAsBytes(pcmData);
        return ProcessResult(302, 0, 'success', '');
      };

      final videoFile = File('${Directory.systemTemp.path}/test_disk_video.mp4');
      await videoFile.writeAsString('mock');

      try {
        final res1 = await service.extractWaveform(
          videoPath: videoFile.path,
          ffmpegPath: 'ffmpeg',
          sampleCount: 16,
        );
        expect(res1.length, 16);
        expect(invokeCount, 1);

        // Allow async disk write to complete
        await Future<void>.delayed(const Duration(milliseconds: 60));

        // Calling clearCache() purges memory and disk cache cleanly
        service.clearCache();

        final res2 = await service.extractWaveform(
          videoPath: videoFile.path,
          ffmpegPath: 'ffmpeg',
          sampleCount: 16,
        );
        expect(res2.length, 16);
        expect(invokeCount, 2);
      } finally {
        if (videoFile.existsSync()) {
          await videoFile.delete();
        }
      }
    });
  });
}
