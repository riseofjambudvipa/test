import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/plugins/plugin_models.dart';
import 'package:capstudio/core/plugins/plugin_manager_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Plugin Models Tests', () {
    test('PluginManifest serializes and deserializes cleanly', () {
      const manifest = PluginManifest(
        id: 'com.test.pack',
        name: 'Test Creator Pack',
        version: '2.0.0',
        author: 'Creator Studios',
        description: 'Test pack description',
        tags: ['test', 'pack'],
        icon: 'star',
      );

      final json = manifest.toJson();
      final restored = PluginManifest.fromJson(json);

      expect(restored.id, 'com.test.pack');
      expect(restored.name, 'Test Creator Pack');
      expect(restored.version, '2.0.0');
      expect(restored.author, 'Creator Studios');
      expect(restored.tags, ['test', 'pack']);
      expect(restored.icon, 'star');
    });

    test('PluginPackage serializes hooks, emojis, and templates', () {
      final pkg = PluginPackage(
        manifest: const PluginManifest(
          id: 'com.custom.pack',
          name: 'Custom Niche Pack',
          version: '1.0.0',
          author: 'Me',
          description: 'Desc',
        ),
        installedAt: DateTime(2026, 1, 1),
        customHooks: const [
          PluginCustomHook(
            pattern: r'\b(crazy test)\b',
            weight: 15.0,
            tag: 'crazy_hook',
            explanation: 'Crazy test hook explanation',
          ),
        ],
        customEmojis: const {'crazy': '🤪'},
        customSfx: const {'crazy': 'whoosh'},
      );

      final json = pkg.toJson();
      final restored = PluginPackage.fromJson(json);

      expect(restored.manifest.id, 'com.custom.pack');
      expect(restored.customHooks.length, 1);
      expect(restored.customHooks.first.pattern, r'\b(crazy test)\b');
      expect(restored.customEmojis['crazy'], '🤪');
      expect(restored.customSfx['crazy'], 'whoosh');
    });
  });

  group('PluginManagerService Tests', () {
    test('Initializes with bundled official creator packs', () async {
      final service = PluginManagerService.instance;
      final plugins = await service.getInstalledPlugins();

      expect(plugins.length, greaterThanOrEqualTo(4));
      final ids = plugins.map((p) => p.manifest.id).toSet();
      expect(ids.contains('com.capstudio.pack.viralmaster'), isTrue);
      expect(ids.contains('com.capstudio.pack.cinemadoc'), isTrue);
      expect(ids.contains('com.capstudio.pack.fitnesspro'), isTrue);
      expect(ids.contains('com.capstudio.pack.techinsider'), isTrue);
    });

    test('getActiveCustomHooks aggregates hooks from all enabled plugins', () async {
      final service = PluginManagerService.instance;
      await service.getInstalledPlugins();

      final hooks = service.getActiveCustomHooks();
      expect(hooks, isNotEmpty);
      expect(hooks.any((h) => h.tag == 'pov_hook'), isTrue);
      expect(hooks.any((h) => h.tag == 'historical_hook'), isTrue);
    });

    test('getActiveCustomEmojis aggregates emojis from all enabled plugins', () async {
      final service = PluginManagerService.instance;
      await service.getInstalledPlugins();

      final emojis = service.getActiveCustomEmojis();
      expect(emojis['secret'], '🤫');
      expect(emojis['history'], '📜');
      expect(emojis['gym'], '🏋️');
      expect(emojis['code'], '💻');
    });

    test('installPluginFromJson successfully installs and enables custom plugin', () async {
      final service = PluginManagerService.instance;
      final customJson = jsonEncode({
        'format': 'CapStudioPlugin',
        'manifest': {
          'id': 'com.community.gaming',
          'name': 'Gaming & Esports Highlights',
          'version': '1.0.0',
          'author': 'Gamer123',
          'description': 'Packs for Twitch & YouTube Gaming',
          'tags': ['gaming', 'esports'],
          'icon': 'bolt',
        },
        'customHooks': [
          {
            'pattern': r'\b(insane clutch|no scope)\b',
            'weight': 18.0,
            'tag': 'clutch_moment',
            'explanation': 'Epic gaming play hook',
          }
        ],
        'customEmojis': {
          'clutch': '🎯',
          'gg': '👑',
        },
      });

      final installed = await service.installPluginFromJson(customJson);
      expect(installed.manifest.id, 'com.community.gaming');
      expect(installed.isBundled, isFalse);

      final hooks = service.getActiveCustomHooks();
      expect(hooks.any((h) => h.tag == 'clutch_moment'), isTrue);

      final emojis = service.getActiveCustomEmojis();
      expect(emojis['clutch'], '🎯');

      // Uninstall custom plugin
      final uninstalled = await service.uninstallPlugin('com.community.gaming');
      expect(uninstalled, isTrue);
    });

    test('togglePlugin disables hook and emoji aggregation', () async {
      final service = PluginManagerService.instance;
      await service.getInstalledPlugins();

      // Disable techinsider plugin
      await service.togglePlugin('com.capstudio.pack.techinsider', false);

      final emojis = service.getActiveCustomEmojis();
      expect(emojis.containsKey('robot'), isFalse);

      // Re-enable techinsider plugin
      await service.togglePlugin('com.capstudio.pack.techinsider', true);
      final reEnabledEmojis = service.getActiveCustomEmojis();
      expect(reEnabledEmojis.containsKey('robot'), isTrue);
    });
  });
}
