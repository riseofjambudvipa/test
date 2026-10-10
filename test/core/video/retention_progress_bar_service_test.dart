import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/video/retention_progress_bar_models.dart';
import 'package:capstudio/core/video/retention_progress_bar_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RetentionProgressBarService.instance.clearCache();
  });

  group('RetentionProgressBarService Tests', () {
    test('getConfig returns default config when not cached or saved', () {
      final config = RetentionProgressBarService.instance.getConfig('test_proj_1');
      expect(config.enabled, false);
      expect(config.color, '#f97316');
    });

    test('saveConfig caches in memory and persists to storage', () async {
      const customConfig = RetentionProgressBarConfig(
        enabled: true,
        position: 'top',
        height: 12.0,
        color: '#06b6d4',
      );

      await RetentionProgressBarService.instance.saveConfig('proj_abc', customConfig);

      // Verify in-memory cache hit
      final cached = RetentionProgressBarService.instance.getConfig('proj_abc');
      expect(cached.enabled, true);
      expect(cached.position, 'top');
      expect(cached.color, '#06b6d4');

      // Clear memory cache to force load from SharedPreferences
      RetentionProgressBarService.instance.clearCache();
      expect(RetentionProgressBarService.instance.getConfig('proj_abc').enabled, false);

      final loaded = await RetentionProgressBarService.instance.loadConfig('proj_abc');
      expect(loaded.enabled, true);
      expect(loaded.position, 'top');
      expect(loaded.color, '#06b6d4');
    });

    test('getPresets returns all standard presets', () {
      final presets = RetentionProgressBarService.instance.getPresets();
      expect(presets.containsKey('Viral Ember'), true);
      expect(presets.containsKey('Electric Cyan'), true);
      expect(presets.containsKey('Hot Magenta'), true);
      expect(presets.containsKey('Acid Green'), true);
      expect(presets.containsKey('Pure Minimalist'), true);
      expect(presets.containsKey('Top Header'), true);
    });
  });
}
