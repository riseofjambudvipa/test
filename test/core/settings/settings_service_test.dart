import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/whisper/whisper_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import 'package:capstudio/core/logger/logger_service.dart';
import '../../test_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  registerTestEnvironment(
    initialPreferences: {
      'whisper_cli_path': 'stored/whisper',
      'ffmpeg_cli_path': 'stored/ffmpeg',
      'whisper_model_path': 'stored/ggml-base.bin',
      'force_no_avx': true,
    },
    silenceLogs: true,
  );

  late SettingsService service;

  setUp(() {
    service = SettingsService.instance;
  });

  group('SettingsService Tests', () {
    test('should load and apply stored settings on initialization', () async {
      expect(service.whisperCliPath, 'stored/whisper');
      expect(service.ffmpegCliPath, 'stored/ffmpeg');
      expect(service.whisperModelPath, 'stored/ggml-base.bin');
      expect(service.forceNoAvx, isTrue);

      // Verify immediate configuration side effects
      expect(WhisperService.instance.whisperCliPath, 'stored/whisper');
      expect(WhisperService.instance.ffmpegCliPath, 'stored/ffmpeg');
      expect(WhisperService.instance.modelPath, 'stored/ggml-base.bin');
      expect(await AppDirs.cpuSupportsAvx(), isFalse);
    });

    test('should return default values when preferences are not set', () async {
      SharedPreferences.setMockInitialValues({});
      await service.init();

      expect(service.defaultLanguage, 'auto');
      expect(service.useVad, isFalse);
      expect(service.vadThreshold, 0.5);
      expect(service.appTheme, 'obsidianAmber');
      expect(service.onboardingComplete, isFalse);
      expect(service.forceNoAvx, isFalse);
      expect(service.useGpu, isFalse);
      expect(service.gpuEncoder, 'none');
      expect(service.whisperThreads, 0); // 0 defaults to Auto-Detect
    });

    test('should persist and apply changes immediately when updating options', () async {
      SharedPreferences.setMockInitialValues({});
      await service.init();

      // Check setters
      await service.setWhisperCliPath('new/whisper');
      await service.setFfmpegCliPath('new/ffmpeg');
      await service.setWhisperModelPath('new/ggml-medium.bin');
      await service.setWhisperModelName('medium');
      await service.setForceNoAvx(true);
      await service.setDefaultLanguage('fr');
      await service.setUseVad(true);
      await service.setVadThreshold(0.75);
      await service.setAppTheme('neonCyan');
      await service.setOnboardingComplete();
      await service.setUseGpu(true);
      await service.setGpuEncoder('h264_nvenc');
      await service.setWhisperThreads(8);

      // Verify getters return the newly stored values
      expect(service.whisperCliPath, 'new/whisper');
      expect(service.ffmpegCliPath, 'new/ffmpeg');
      expect(service.whisperModelPath, anyOf('new/ggml-medium.bin', 'new\\ggml-medium.bin'));
      expect(service.whisperModelName, 'medium');
      expect(service.forceNoAvx, isTrue);
      expect(service.defaultLanguage, 'fr');
      expect(service.useVad, isTrue);
      expect(service.vadThreshold, 0.75);
      expect(service.appTheme, 'neonCyan');
      expect(service.onboardingComplete, isTrue);
      expect(service.useGpu, isTrue);
      expect(service.gpuEncoder, 'h264_nvenc');
      expect(service.whisperThreads, 8);

      // Verify service side effects are applied
      expect(WhisperService.instance.whisperCliPath, 'new/whisper');
      expect(WhisperService.instance.ffmpegCliPath, 'new/ffmpeg');
      expect(WhisperService.instance.modelPath, anyOf('new/ggml-medium.bin', 'new\\ggml-medium.bin'));
      expect(await AppDirs.cpuSupportsAvx(), isFalse);
    });

    test('should scrub PII from error logs and paths', () {
      final home = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (home != null && home.isNotEmpty) {
        final scrubbed = LoggerService.instance.scrubPii('Error in path: $home/model.bin');
        expect(scrubbed.contains(home), isFalse);
        expect(scrubbed.contains('<USER_HOME>'), isTrue);
      }
      expect(LoggerService.instance.scrubPii('Generic clean error'), 'Generic clean error');
    });

    test('should sanitize paths by stripping illegal chars, refusing UNC paths, and preserving colons/spaces/r/n', () async {
      SharedPreferences.setMockInitialValues({});
      await service.init();

      // 1. Preserves Windows drive-letter colons, backslashes, and words containing r and n
      const validWinPath = r'C:\runner\new_bin\ffmpeg.exe';
      await service.setFfmpegCliPath(validWinPath);
      expect(service.ffmpegCliPath, validWinPath);

      // 2. Preserves spaces, ampersands, dashes, and parentheses
      const pathWithSymbols = r'D:\Program Files (x86)\Cap & Studio\whisper-cli.exe';
      await service.setWhisperCliPath(pathWithSymbols);
      expect(service.whisperCliPath, pathWithSymbols);

      // 3. Rejects network UNC paths
      await service.setWhisperCliPath(r'\\remote_server\share\whisper.exe');
      expect(service.whisperCliPath, isEmpty);

      await service.setFfmpegCliPath('//nas/share/ffmpeg');
      expect(service.ffmpegCliPath, isEmpty);

      // 4. Strips illegal filename characters (<, >, ", |, ?, *) and control characters
      if (Platform.isWindows) {
        await service.setWhisperCliPath('C:\\tools<test>?*|">.exe');
        expect(service.whisperCliPath, 'C:\\toolstest.exe');
      }

      // 5. Cleans whitespace and clears in-memory config on empty
      await service.setFfmpegCliPath('   ');
      expect(service.ffmpegCliPath, isEmpty);
      expect(WhisperService.instance.ffmpegCliPath, 'ffmpeg');
    });
  });
}
