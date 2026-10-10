import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/video/background_music_models.dart';
import 'package:capstudio/core/video/background_music_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BackgroundMusicService.instance.clearCache();
  });

  group('BackgroundMusicService Tests', () {
    test('getConfig returns default config for unconfigured project', () {
      final config = BackgroundMusicService.instance.getConfig('proj_1');
      expect(config.hasMusic, isFalse);
      expect(config.volume, 0.20);
    });

    test('saveConfig persists config and retrieves via loadConfig', () async {
      const config = BackgroundMusicConfig(
        musicPath: '/path/to/beat.mp3',
        volume: 0.35,
        loop: true,
        enableDucking: true,
        duckingRatio: 5.0,
      );

      await BackgroundMusicService.instance.saveConfig('proj_test', config);

      // Verify cached retrieval
      final cached = BackgroundMusicService.instance.getConfig('proj_test');
      expect(cached, equals(config));

      // Clear cache to verify SharedPreferences retrieval
      BackgroundMusicService.instance.clearCache();
      final loaded = await BackgroundMusicService.instance.loadConfig('proj_test');
      expect(loaded, equals(config));
    });

    test('loadConfig returns default on empty projectId or missing data', () async {
      final config = await BackgroundMusicService.instance.loadConfig('');
      expect(config.hasMusic, isFalse);

      final configMissing = await BackgroundMusicService.instance.loadConfig('proj_nonexistent');
      expect(configMissing.hasMusic, isFalse);
    });
  });
}
