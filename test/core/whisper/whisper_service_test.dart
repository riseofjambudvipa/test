import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/whisper/whisper_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import '../../test_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  registerTestEnvironment(silenceLogs: true);

  late WhisperService service;
  late String testTempPath;

  setUp(() {
    service = WhisperService.instance;
    service.processRunner = null;
    service.configureCli('whisper-cli');
    service.configureFfmpeg('ffmpeg');
    
    testTempPath = AppDirs.support;
    final dummyModel = File(p.join(testTempPath, 'ggml-base.bin'))..createSync();
    service.configureModel(dummyModel.path);
  });

  tearDown(() {
    service.processRunner = null;
  });

  group('WhisperService Configurations', () {
    test('should update config paths correctly', () {
      service.configureCli('custom-whisper');
      service.configureFfmpeg('custom-ffmpeg');
      service.configureModel('models/ggml-medium.bin');

      expect(service.whisperCliPath, 'custom-whisper');
      expect(service.ffmpegCliPath, 'custom-ffmpeg');
      expect(service.modelPath, 'models/ggml-medium.bin');
    });

    test('should discover a bundled FFmpeg binary (bundle-relative lookup)', () {
      // Regression guard for the platform-gap fix: the getter previously only
      // checked `Directory.current`-relative paths, so a binary bundled into a
      // packaged app (whose cwd is NOT the bundle) could never be found.
      // It must now find a binary in the bundle-relative candidate paths.
      final exe = Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
      final binDir = Directory(p.join(Directory.current.path, 'assets', 'bin'));
      binDir.createSync(recursive: true);
      final bundled = File(p.join(binDir.path, exe))..writeAsBytesSync([0x4D, 0x5A]);

      try {
        // Reset to a pristine instance so `_ffmpegCliPath` is the default
        // and `_cachedFfmpegPath` is empty — forcing the discovery path.
        WhisperService.resetForTesting();
        final fresh = WhisperService.instance;
        fresh.configureFfmpeg('ffmpeg');

        expect(fresh.ffmpegCliPath, bundled.path);
        // Cache hit returns the same path without re-scanning.
        expect(fresh.ffmpegCliPath, bundled.path);
      } finally {
        bundled.deleteSync();
        try {
          binDir.deleteSync();
        } catch (_) {}
        WhisperService.resetForTesting();
      }
    });
  });

  group('WhisperService Audio Extraction', () {
    test('should extract mono 16kHz WAV and verify FFmpeg parameters', () async {
      final tempDir = Directory.systemTemp.createTempSync('whisper_test_audio_');
      final mockVideo = File(p.join(tempDir.path, 'video.mp4'))..createSync();

      try {
        final List<String> capturedArgs = [];
        service.processRunner = (executable, arguments, {stderrEncoding, stdoutEncoding}) async {
          capturedArgs.addAll(arguments);
          return ProcessResult(123, 0, 'success', 'success');
        };

        final outputWav = await service.extractAudio(mockVideo.path, tempDir.path);

        expect(outputWav, contains('video_16k.wav'));
        expect(capturedArgs, containsAll(['-vn', '-ac', '1', '-ar', '16000', '-acodec', 'pcm_s16le']));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should throw FileSystemException if the video file does not exist', () async {
      expect(
        () => service.extractAudio('invalid/path.mp4', 'temp/'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('should throw ProcessException when FFmpeg extraction fails', () async {
      final tempDir = Directory.systemTemp.createTempSync('whisper_test_fail_');
      final mockVideo = File(p.join(tempDir.path, 'video.mp4'))..createSync();

      try {
        service.processRunner = (executable, arguments, {stderrEncoding, stdoutEncoding}) async {
          return ProcessResult(124, 1, '', 'FFmpeg format conversion error');
        };

        expect(
          () => service.extractAudio(mockVideo.path, tempDir.path),
          throwsA(isA<ProcessException>()),
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('WhisperService Transcription & Timing Parsing', () {
    test('should parse Whisper JSON output, autodetect milliseconds, and clean up temp files', () async {
      final tempDir = Directory.systemTemp.createTempSync('whisper_test_transcribe_');
      final mockWav = File(p.join(tempDir.path, 'audio_16k.wav'))..createSync();

      // Create a mock timing JSON file that whisper-cli would generate
      final mockJsonFile = File('${mockWav.path}.json');
      final mockJsonContent = {
        'language': 'fr',
        'segments': [
          {
            'words': [
              {
                'word': 'Bonjour',
                'start': 500, // 500ms -> should be auto-converted to 0.5s
                'end': 1200,   // 1200ms -> should be auto-converted to 1.2s
                'confidence': 0.92
              },
              {
                'word': 'monde',
                'start': 1500,
                'end': 2000,
                'confidence': 0.98
              }
            ]
          }
        ]
      };
      await mockJsonFile.writeAsString(jsonEncode(mockJsonContent));

      try {
        service.processRunner = (executable, arguments, {stderrEncoding, stdoutEncoding}) async {
          return ProcessResult(125, 0, 'success', 'success');
        };

        final result = await service.transcribe(
          wavPath: mockWav.path,
          language: 'fr',
          useVad: true,
          vadThreshold: 0.65,
          expectedDuration: 2.0,
        );

        // Verify outputs
        expect(result.language, 'fr');
        expect(result.words.length, 2);

        // Timings autodetected from milliseconds
        expect(result.words[0].text, 'Bonjour');
        expect(result.words[0].start, 0.5);
        expect(result.words[0].end, 1.2);
        expect(result.words[0].confidence, 0.92);

        expect(result.words[1].text, 'monde');
        expect(result.words[1].start, 1.5);
        expect(result.words[1].end, 2.0);

        // JSON file should have been deleted for cleanup
        expect(mockJsonFile.existsSync(), isFalse);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should throw StateError if model is not configured', () async {
      final tempDir = Directory.systemTemp.createTempSync('whisper_test_model_');
      final mockWav = File(p.join(tempDir.path, 'audio_16k.wav'))..createSync();

      try {
        service.configureModel('');
        expect(
          () => service.transcribe(wavPath: mockWav.path),
          throwsA(isA<StateError>()),
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should throw ProcessException if Whisper transcription fails', () async {
      final tempDir = Directory.systemTemp.createTempSync('whisper_test_cli_fail_');
      final mockWav = File(p.join(tempDir.path, 'audio_16k.wav'))..createSync();

      try {
        service.processRunner = (executable, arguments, {stderrEncoding, stdoutEncoding}) async {
          return ProcessResult(126, 1, '', 'Whisper model out of memory');
        };

        expect(
          () => service.transcribe(wavPath: mockWav.path),
          throwsA(isA<ProcessException>()),
        );
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should clean up JSON and TXT output files on transcription failure', () async {
      final tempDir = Directory.systemTemp.createTempSync('whisper_test_cleanup_fail_');
      final mockWav = File(p.join(tempDir.path, 'audio_16k.wav'))..createSync();
      final mockJsonFile = File('${mockWav.path}.json')..createSync();
      final mockTxtFile = File('${mockWav.path}.txt')..createSync();

      try {
        service.processRunner = (executable, arguments, {stderrEncoding, stdoutEncoding}) async {
          return ProcessResult(126, 1, '', 'Whisper execution error');
        };

        await expectLater(
          () => service.transcribe(wavPath: mockWav.path),
          throwsA(isA<ProcessException>()),
        );

        expect(mockJsonFile.existsSync(), isFalse);
        expect(mockTxtFile.existsSync(), isFalse);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should invoke whisper-cli with dynamic thread count argument when whisperThreads is 0', () async {
      final tempDir = Directory.systemTemp.createTempSync('whisper_test_threads_');
      final mockWav = File(p.join(tempDir.path, 'audio_16k.wav'))..createSync();
      final mockJsonFile = File('${mockWav.path}.json');
      await mockJsonFile.writeAsString(jsonEncode({'segments': []}));

      try {
        final settings = SettingsService.instance;
        await settings.setWhisperThreads(0); // Set to Auto-Detect

        List<String>? capturedArgs;
        service.processRunner = (executable, arguments, {stderrEncoding, stdoutEncoding}) async {
          capturedArgs = arguments;
          return ProcessResult(127, 0, 'success', 'success');
        };

        await service.transcribe(wavPath: mockWav.path);

        expect(capturedArgs, isNotNull);
        expect(capturedArgs, contains('-t'));
        final threadIdx = capturedArgs!.indexOf('-t');
        expect(threadIdx, isNot(-1));
        final assignedThreads = int.parse(capturedArgs![threadIdx + 1]);
        expect(assignedThreads, greaterThanOrEqualTo(1));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('sanitizeLanguage normalizes valid, invalid, and auto language codes', () {
      expect(WhisperService.sanitizeLanguage(null), 'auto');
      expect(WhisperService.sanitizeLanguage(''), 'auto');
      expect(WhisperService.sanitizeLanguage('   '), 'auto');
      expect(WhisperService.sanitizeLanguage('auto'), 'auto');
      expect(WhisperService.sanitizeLanguage('AUTO'), 'auto');
      expect(WhisperService.sanitizeLanguage('en'), 'en');
      expect(WhisperService.sanitizeLanguage('es'), 'es');
      expect(WhisperService.sanitizeLanguage('zh-CN'), 'zh-CN');
      expect(WhisperService.sanitizeLanguage('en_US'), 'en_US');
      expect(WhisperService.sanitizeLanguage('fr;rm -rf /'), 'frrm-rf');
      expect(WhisperService.sanitizeLanguage('!@#\$%^&*()'), 'auto');
    });

    test('isGpuFailure detects GPU and driver errors in stderr', () {
      expect(WhisperService.isGpuFailure('ggml_cuda_init: failed to initialize CUDA'), isTrue);
      expect(WhisperService.isGpuFailure('ggml_vulkan: memory allocation failed'), isTrue);
      expect(WhisperService.isGpuFailure('OpenCL error: clCreateContext failed'), isTrue);
      expect(WhisperService.isGpuFailure('ggml_backend: failed to allocate buffer'), isTrue);
      expect(WhisperService.isGpuFailure('CUDA out of memory'), isTrue);
      expect(WhisperService.isGpuFailure('File not found: /path/to/wav'), isFalse);
    });

    test('should pass -ng when useGpu is false', () async {
      final tempDir = Directory.systemTemp.createTempSync('whisper_test_gpu_off_');
      final mockWav = File(p.join(tempDir.path, 'audio_16k.wav'))..createSync();
      final mockJsonFile = File('${mockWav.path}.json');
      await mockJsonFile.writeAsString(jsonEncode({'segments': []}));

      try {
        List<String>? capturedArgs;
        service.processRunner = (executable, arguments, {stderrEncoding, stdoutEncoding}) async {
          capturedArgs = arguments;
          return ProcessResult(128, 0, 'success', 'success');
        };

        await service.transcribe(wavPath: mockWav.path, useGpu: false);

        expect(capturedArgs, isNotNull);
        expect(capturedArgs, contains('-ng'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should omit -ng when useGpu is true', () async {
      final tempDir = Directory.systemTemp.createTempSync('whisper_test_gpu_on_');
      final mockWav = File(p.join(tempDir.path, 'audio_16k.wav'))..createSync();
      final mockJsonFile = File('${mockWav.path}.json');
      await mockJsonFile.writeAsString(jsonEncode({'segments': []}));

      try {
        List<String>? capturedArgs;
        service.processRunner = (executable, arguments, {stderrEncoding, stdoutEncoding}) async {
          capturedArgs = arguments;
          return ProcessResult(129, 0, 'success', 'success');
        };

        await service.transcribe(wavPath: mockWav.path, useGpu: true);

        expect(capturedArgs, isNotNull);
        expect(capturedArgs, isNot(contains('-ng')));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should automatically retry with -ng when GPU fails with isGpuFailure error', () async {
      final tempDir = Directory.systemTemp.createTempSync('whisper_test_gpu_retry_');
      final mockWav = File(p.join(tempDir.path, 'audio_16k.wav'))..createSync();
      final mockJsonFile = File('${mockWav.path}.json');

      try {
        int callCount = 0;
        final List<List<String>> recordedInvocations = [];
        service.processRunner = (executable, arguments, {stderrEncoding, stdoutEncoding}) async {
          callCount++;
          recordedInvocations.add(arguments);
          if (callCount == 1) {
            // First call with GPU fails with CUDA out of memory
            return ProcessResult(130, 1, '', 'CUDA error: out of memory in ggml_cuda_init');
          } else {
            // Second call succeeds with fallback
            await mockJsonFile.writeAsString(jsonEncode({'segments': []}));
            return ProcessResult(130, 0, 'success', 'success');
          }
        };

        final result = await service.transcribe(wavPath: mockWav.path, useGpu: true);

        expect(callCount, 2);
        expect(recordedInvocations[0], isNot(contains('-ng')));
        expect(recordedInvocations[1], contains('-ng'));
        expect(result.words, isEmpty);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('should retry without -ng when binary does not support -ng (unknown argument: -ng)', () async {
      final tempDir = Directory.systemTemp.createTempSync('whisper_test_legacy_bin_');
      final mockWav = File(p.join(tempDir.path, 'audio_16k.wav'))..createSync();
      final mockJsonFile = File('${mockWav.path}.json');

      try {
        int callCount = 0;
        final List<List<String>> recordedInvocations = [];
        service.processRunner = (executable, arguments, {stderrEncoding, stdoutEncoding}) async {
          callCount++;
          recordedInvocations.add(arguments);
          if (callCount == 1) {
            return ProcessResult(131, 1, '', 'unknown argument: -ng\nusage: whisper-cli [options]');
          } else {
            await mockJsonFile.writeAsString(jsonEncode({'segments': []}));
            return ProcessResult(131, 0, 'success', 'success');
          }
        };

        final result = await service.transcribe(wavPath: mockWav.path, useGpu: false);

        expect(callCount, 2);
        expect(recordedInvocations[0], contains('-ng'));
        expect(recordedInvocations[1], isNot(contains('-ng')));
        expect(result.words, isEmpty);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
