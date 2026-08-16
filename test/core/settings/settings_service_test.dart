import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/whisper/whisper_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
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
  });
}
