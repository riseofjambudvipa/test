import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/assets/asset_manifest.dart';
import 'package:capstudio/core/assets/asset_path_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;

class MockHttpClient extends Mock implements http.Client {}
class FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUri());
  });

  group('AssetPack Tests', () {
    test('should compute correct MB size values', () {
      const pack = AssetPack(
        id: 'pack_1',
        name: 'Pack One',
        description: 'Test Description',
        required: true,
        sizeBytes: 10 * 1024 * 1024,
        compressedSizeBytes: 5 * 1024 * 1024,
        downloadUrl: 'http://example.com',
        checksum: '',
        version: '1.0',
        fileCount: 10,
        format: 'zip',
        animated: false,
        localFolder: 'pack_1',
      );

      expect(pack.sizeMB, 10.0);
      expect(pack.compressedSizeMB, 5.0);
    });
  });

  group('EmojiMeta Tests', () {
    test('should construct from json map correctly', () {
      final json = {
        'unicode': '1f600',
        'glyph': '😀',
        'name': 'grinning face',
        'group': 'Smileys',
        'unicodeVersion': '8.0',
        'keywords': ['face', 'smile'],
        'shortcodes': [':grinning:'],
        'styles': {
          'googleAnimated': '1f600.gif',
        },
      };

      final emoji = EmojiMeta.fromJson(json);

      expect(emoji.unicode, '1f600');
      expect(emoji.glyph, '😀');
      expect(emoji.name, 'grinning face');
      expect(emoji.group, 'Smileys');
      expect(emoji.unicodeVersion, '8.0');
      expect(emoji.keywords, containsAll(['face', 'smile']));
      expect(emoji.shortcodes, [':grinning:']);
      expect(emoji.supportsPack('googleAnimated'), isTrue);
      expect(emoji.supportsPack('openmoji'), isFalse);
    });
  });

  group('AssetManifest Tests', () {
    late AssetManifest manifest;

    setUp(() {
      final emojis = [
        EmojiMeta.fromJson({
          'unicode': '1f600',
          'glyph': '😀',
          'name': 'grinning face',
          'group': 'Smileys',
          'keywords': ['face', 'smile', 'happy'],
          'shortcodes': [':grinning:'],
          'styles': {'googleAnimated': '1f600.gif'},
        }),
        EmojiMeta.fromJson({
          'unicode': '1f609',
          'glyph': '😉',
          'name': 'winking face',
          'group': 'Smileys',
          'keywords': ['face', 'wink'],
          'shortcodes': [':wink:'],
          'styles': {'openmoji': '1f609.png'},
        }),
        EmojiMeta.fromJson({
          'unicode': '1f436',
          'glyph': '🐶',
          'name': 'dog face',
          'group': 'Animals',
          'keywords': ['animal', 'dog', 'puppy'],
          'shortcodes': [':dog:'],
          'styles': {'openmoji': '1f436.png'},
        }),
      ];

      manifest = AssetManifest(version: '2.0', packs: [], emojis: emojis);
    });

    test('should populate lookup maps correctly on initialization', () {
      expect(manifest.byUnicode.containsKey('1f600'), isTrue);
      expect(manifest.byGlyph.containsKey('😉'), isTrue);
      expect(manifest.byGroup['smileys']?.length, 2);
      expect(manifest.byGroup['animals']?.length, 1);
    });

    test('should search by query terms accurately across name, keywords, and shortcodes', () {
      // Name match
      final nameRes = manifest.search('winking');
      expect(nameRes.length, 1);
      expect(nameRes.first.unicode, '1f609');

      // Keyword match
      final keyRes = manifest.search('puppy');
      expect(keyRes.length, 1);
      expect(keyRes.first.unicode, '1f436');

      // Glyph match
      final glyphRes = manifest.search('🐶');
      expect(glyphRes.length, 1);
      expect(glyphRes.first.unicode, '1f436');

      // Empty query should return everything up to limit
      final emptyRes = manifest.search('');
      expect(emptyRes.length, 3);
    });

    test('should filter search results correctly based on pack support', () {
      // Grinning face supports googleAnimated, Winking face supports openmoji
      final searchAll = manifest.search('face');
      expect(searchAll.length, 3); // winking, grinning, dog

      final searchGoogle = manifest.search('face', packId: 'googleAnimated');
      expect(searchGoogle.length, 1);
      expect(searchGoogle.first.unicode, '1f600');

      final searchOpenmoji = manifest.search('face', packId: 'openmoji');
      expect(searchOpenmoji.length, 2); // winking, dog
      expect(searchOpenmoji.any((e) => e.unicode == '1f600'), isFalse);
    });

    test('AssetManifest.fromJson builds correctly with custom JSON map', () {
      final json = {
        'version': '3.0',
        'emojis': [
          {
            'unicode': '1f600',
            'glyph': '😀',
            'name': 'grinning',
            'group': 'Smileys',
            'unicodeVersion': '8.0',
            'keywords': ['happy'],
            'shortcodes': [':grinning:'],
            'styles': {'googleAnimated': '1f600.gif'}
          }
        ]
      };

      final parsed = AssetManifest.fromJson(json);
      expect(parsed.version, '3.0');
      expect(parsed.emojis.length, 1);
      expect(parsed.emojis.first.unicode, '1f600');
      expect(parsed.packs.length, greaterThanOrEqualTo(5)); // Verify hardcoded packs
    });



    test('should fall back to group Other when group is missing in EmojiMeta.fromJson', () {
      final json = {
        'unicode': '1f601',
        'name': 'beaming face',
      };
      final emoji = EmojiMeta.fromJson(json);
      expect(emoji.group, equals('Other'));
    });

    test('validate predefined asset pack checksums are valid hex strings or deferred to companion .sha256', () {
      final sha256Regex = RegExp(r'^[a-fA-F0-9]{64}$');
      final manifest = AssetManifest.fromJson({'emojis': []});
      for (final pack in manifest.packs) {
        expect(
          pack.checksum.isEmpty || sha256Regex.hasMatch(pack.checksum),
          isTrue,
          reason: 'Pack "${pack.name}" has invalid checksum format: "${pack.checksum}"',
        );
      }
    });

    test('validate sizeMB calculations for 0 bytes and large gigabyte pack', () {
      const smallPack = AssetPack(
        id: 'zero', name: 'Z', description: '', required: false,
        sizeBytes: 0, compressedSizeBytes: 0, downloadUrl: '',
        checksum: '', version: '1.0', fileCount: 0, format: 'zip',
        animated: false, localFolder: '',
      );
      expect(smallPack.sizeMB, equals(0.0));

      final manifest = AssetManifest.fromJson({'emojis': []});
      final microsoftAnimatedPack = manifest.packs.firstWhere((p) => p.id == 'microsoftAnimated');
      expect(microsoftAnimatedPack.sizeMB, closeTo(1610.36, 0.1));
    });

    test('validate that assetManifestProvider throws UnimplementedError by default', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(
        () => container.read(assetManifestProvider),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('search returns zero results when filtering by non-existent packId', () {
      final searchRes = manifest.search('face', packId: 'invalidPackId123');
      expect(searchRes, isEmpty);
    });

    test('search query respects the limit parameter', () {
      final searchLimit1 = manifest.search('', limit: 1);
      expect(searchLimit1.length, equals(1));

      final searchLimit2 = manifest.search('', limit: 2);
      expect(searchLimit2.length, equals(2));
    });

    test('all predefined default emoji packs are optional', () {
      final manifest = AssetManifest.fromJson({'emojis': []});
      for (final pack in manifest.packs) {
        expect(pack.required, isFalse, reason: 'Pack ${pack.name} must be optional');
      }
    });

    test('EmojiMeta handles missing optional fields with safe defaults', () {
      final json = {
        'unicode': '1f600',
        'name': 'grinning',
      };
      final emoji = EmojiMeta.fromJson(json);
      expect(emoji.glyph, equals(''));
      expect(emoji.unicodeVersion, equals('8.0'));
      expect(emoji.keywords, isEmpty);
      expect(emoji.shortcodes, isEmpty);
      expect(emoji.styles, isEmpty);
    });

    test('AssetManifest.load() handles remote fetch failure and falls back cleanly', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final tempDir = Directory.systemTemp.createTempSync('capstudio_manifest_test_');
      AppDirs.setSupportPathForTesting(tempDir.path);
      await AppDirs.init();
      SharedPreferences.setMockInitialValues({});
      await AssetPathService.instance.init();
      
      // Mock rootBundle for the new split emoji database files loaded by loadMetadata()
      final binaryMessenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      binaryMessenger.setMockMessageHandler('flutter/assets', (message) async {
        if (message == null) return null;
        final key = utf8.decode(message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes));
        if (key.contains('emoji_base.json')) {
          // Return a minimal valid emoji base JSON array
          final bytes = utf8.encoder.convert(jsonEncode([]));
          return bytes.buffer.asByteData();
        }
        if (key.contains('en.json')) {
          // Return a minimal valid language JSON map
          final bytes = utf8.encoder.convert(jsonEncode({}));
          return bytes.buffer.asByteData();
        }
        return null; // Fallback
      });
      
      try {
        final manifest = await AssetManifest.load();
        expect(manifest.packs, isNotEmpty);
        expect(manifest.packs.first.id, equals('googleNonAnimated'));
      } finally {
        binaryMessenger.setMockMessageHandler('flutter/assets', null);
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });
  });
}
