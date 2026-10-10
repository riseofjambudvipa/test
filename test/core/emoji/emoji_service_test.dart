import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/emoji/emoji_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import '../../test_environment.dart';

void main() {
  // Ensure Flutter binding is initialized (needed for compute isolate in tests)
  TestWidgetsFlutterBinding.ensureInitialized();

  registerTestEnvironment(silenceLogs: true);

  group('EmojiService Tests', () {
    late String mockMetadataPath;
    late String mockAssetsDir;

    setUp(() {
      EmojiService.instance.resetForTesting();
      // Locate the mock JSON file inside the test directory
      mockMetadataPath = 'test/mock_metadata.json';
      
      // Use the centralized temp folder from AppDirs
      mockAssetsDir = AppDirs.support;

      // Create the expected subdirectories so EmojiService scan finds them and doesn't log warnings
      final packs = [
        'googleAnimated',
        'googleNonAnimated',
        'microsoftAnimated',
        'microsoftNonAnimated',
        'openmoji'
      ];
      
      for (final pack in packs) {
        // Create the pack root directory (also used as assetsBaseDir fallback)
        Directory(p.join(mockAssetsDir, pack)).createSync(recursive: true);

        // After the emoji folder reorganisation, files live inside a category
        // subfolder (e.g. googleAnimated/Activities/1f381.gif).  The scan uses
        // p.relative so it stores 'Activities/1f381.gif' as the subpath.
        if (pack == 'googleAnimated') {
          final catDir = Directory(p.join(mockAssetsDir, pack, 'Activities'))
            ..createSync(recursive: true);
          File(p.join(catDir.path, '1f381.png')).writeAsStringSync('dummy_anim');
          File(p.join(catDir.path, '1f389.png')).writeAsStringSync('dummy_anim_2');
        } else if (pack == 'googleNonAnimated') {
          final catDir = Directory(p.join(mockAssetsDir, pack, 'Activities'))
            ..createSync(recursive: true);
          File(p.join(catDir.path, '1f381.png')).writeAsStringSync('dummy_static');
        }
      }
    });

    test('should load metadata and index emojis in background', () async {
      final service = EmojiService.instance;
      
      // Load metadata
      await service.loadMetadata(mockMetadataPath, mockAssetsDir);

      expect(service.isLoaded, isTrue);

      // Verify group search works on compiled registry
      final activities = service.getByGroup('Activities');
      expect(activities, isNotEmpty);
      final hasPresent = activities.any((e) => e.unicode == '1f381');
      expect(hasPresent, isTrue);
    });

    test('should search emojis by exact keyword and synonym matches', () async {
      final service = EmojiService.instance;
      await service.loadMetadata(mockMetadataPath, mockAssetsDir);

      // Exact keyword match: 'present'
      final searchGift = service.search('present');
      expect(searchGift, isNotEmpty);
      expect(searchGift.any((e) => e.keywords.contains('present')), isTrue);

      // Prefix match: 'conf' matches 'confetti' / 'congratulations'
      final searchConf = service.search('conf');
      expect(searchConf, isNotEmpty);
      expect(searchConf.any((e) => e.name.contains('confetti') || e.name.contains('congratulations') || e.keywords.any((k) => k.startsWith('conf'))), isTrue);

      // Substring name match: 'wrapped' matches 'wrapped gift'
      final searchPresent = service.search('wrapped');
      expect(searchPresent, isNotEmpty);
      expect(searchPresent.any((e) => e.glyph == '🎁'), isTrue);
      
      // Multilingual search match: Spanish 'gato' should return the cat emoji (1f431)
      await service.setLanguage('es');
      final searchGato = service.search('gato');
      expect(searchGato, isNotEmpty);
      expect(searchGato.any((e) => e.unicode == '1f431' || e.glyph == '🐱'), isTrue);
    });

    test('should find all prefix matches across the sorted key range', () async {
      final service = EmojiService.instance;
      await service.loadMetadata(mockMetadataPath, mockAssetsDir);

      // 'p' is a short prefix whose matches ('party', 'popper', 'present')
      // are spread across the sorted keyword keyspace — the binary-search
      // prefix range must find them all, not just keys adjacent to an exact
      // match (regression for the old scan-every-key loop).
      final searchP = service.search('p');
      expect(searchP, isNotEmpty);
      for (final e in searchP) {
        final matches = e.name.contains('p') ||
            e.keywords.any((k) => k.startsWith('p'));
        expect(matches, isTrue,
            reason: 'result "${e.name}" should match prefix "p"');
      }

      // A prefix with no matching keys returns empty without error (the
      // binary-search "first key >= query" result is absent).
      final searchZzz = service.search('zzzzzzzz');
      expect(searchZzz, isEmpty);
    });

    test('should resolve asset path based on pack selection', () async {
      final service = EmojiService.instance;
      await service.loadMetadata(mockMetadataPath, mockAssetsDir);

      final activities = service.getByGroup('Activities');
      final presentEmoji = activities.firstWhere((e) => e.unicode == '1f381');

      // 1. Google Animated path resolution
      final animAsset = service.getAssetPath(presentEmoji, 'googleAnimated');
      expect(animAsset, isNotNull);
      expect(animAsset!.filename, '1f381.png');
      // Path uses the mapped pack folder (google_noto_emojis_animated_pack/512x512)
      // and includes the category subfolder (Activities/) after reorganisation.
      final animPath = animAsset.absolutePath.replaceAll('\\', '/');
      expect(animPath, contains('1f381.png'));
      expect(animPath, contains('Activities'));

      // 2. Google Non-Animated path resolution
      final staticAsset = service.getAssetPath(presentEmoji, 'googleNonAnimated');
      expect(staticAsset, isNotNull);
      expect(staticAsset!.filename, '1f381.png');
      final staticPath = staticAsset.absolutePath.replaceAll('\\', '/');
      expect(staticPath, contains('1f381.png'));
      expect(staticPath, contains('Activities'));
    });

    test('should scan custom stickers and index them for search', () async {
      final service = EmojiService.instance;
      
      final customDir = Directory(p.join(p.dirname(mockAssetsDir), 'custom_stickers'));
      if (customDir.existsSync()) {
        customDir.deleteSync(recursive: true);
      }
      customDir.createSync(recursive: true);
      
      final dummyPng = File(p.join(customDir.path, 'sparkles_sticker.png'))..createSync();
      final dummyJpg = File(p.join(customDir.path, 'fire_sticker.jpg'))..createSync();
      File(p.join(customDir.path, 'not_a_sticker.txt')).createSync();

      try {
        await service.loadMetadata(mockMetadataPath, mockAssetsDir);

        // Verify search matching for sparkles_sticker
        final sparklesSearch = service.search('sparkles_sticker');
        expect(sparklesSearch, isNotEmpty);
        expect(sparklesSearch[0].name, 'sparkles_sticker');
        expect(sparklesSearch[0].group, 'Custom Stickers');
        expect(sparklesSearch[0].glyph, dummyPng.path);

        // Verify search matching for fire_sticker
        final fireSearch = service.search('fire_sticker');
        expect(fireSearch, isNotEmpty);
        expect(fireSearch[0].name, 'fire_sticker');
        expect(fireSearch[0].glyph, dummyJpg.path);

        // Verify non-sticker txt file is not indexed
        final txtSearch = service.search('not_a_sticker');
        expect(txtSearch, isEmpty);
      } finally {
        if (customDir.existsSync()) {
          customDir.deleteSync(recursive: true);
        }
      }
    });

    test('should resolve asset path for custom stickers directly from their glyph path', () async {
      final service = EmojiService.instance;
      
      const customStickerEmoji = EmojiModel(
        unicode: '',
        glyph: 'absolute/path/to/custom_sticker.png',
        name: 'custom_sticker',
        keywords: ['custom_sticker', 'custom', 'sticker'],
        group: 'Custom Stickers',
        styles: {
          'googleAnimated': 'custom_sticker.png',
          'googleNonAnimated': 'custom_sticker.png',
          'custom': 'custom_sticker.png',
        },
        shortcodes: ['custom_sticker'],
        parentUnicode: null,
      );

      final asset = service.getAssetPath(customStickerEmoji, 'anyPack');
      expect(asset, isNotNull);
      expect(asset!.packId, 'custom');
      expect(asset.filename, 'custom_sticker.png');
      expect(asset.absolutePath, 'absolute/path/to/custom_sticker.png');
    });
  });
}
