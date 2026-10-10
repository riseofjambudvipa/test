import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/assets/asset_verification_service.dart';
import 'package:capstudio/core/assets/asset_path_service.dart';
import 'package:capstudio/core/assets/asset_manifest.dart';
import 'package:capstudio/core/fonts/font_service.dart';
import '../../test_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  registerTestEnvironment(silenceLogs: true);

  group('AssetVerificationService Tests', () {
    late String assetsRoot;
    late AssetManifest mockManifest;

    setUp(() async {
      // Initialize paths and services with our test directory
      await AssetPathService.instance.init();
      assetsRoot = AssetPathService.instance.assetsRoot;
      await FontService.instance.init();

      // Setup a clean assets root directory
      final dir = Directory(assetsRoot);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
      dir.createSync(recursive: true);

      // Create a mock manifest containing one font pack and one emoji pack
      mockManifest = AssetManifest(
        version: '1.0',
        emojis: [],
        packs: [
          const AssetPack(
            id: 'font_outfit',
            name: 'Outfit Font',
            description: 'Design font pack',
            required: true,
            sizeBytes: 100,
            compressedSizeBytes: 50,
            downloadUrl: '',
            checksum: '',
            version: '1.0',
            fileCount: 1,
            format: 'ttf',
            animated: false,
            localFolder: 'Outfit-Bold.ttf',
          ),
          const AssetPack(
            id: 'googleNonAnimated',
            name: 'Google Emojis (Static)',
            description: 'Static emoji pack',
            required: false,
            sizeBytes: 200,
            compressedSizeBytes: 100,
            downloadUrl: '',
            checksum: '',
            version: '1.0',
            fileCount: 15,
            format: 'png',
            animated: false,
            localFolder: 'google_noto_emojis_non_animated_pack',
          ),
        ],
      );
    });

    test('returns assetsRootMissing if the assets root folder does not exist', () async {
      // Delete the assets root directory to trigger failure
      final dir = Directory(assetsRoot);
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }

      final result = await AssetVerificationService.instance.verify(mockManifest);
      
      expect(result.allRequiredPresent, isFalse);
      expect(result.assetsRootMissing, isNotNull);
      expect(result.assetsRootMissing, assetsRoot);
      expect(result.installedPackIds, isEmpty);
      expect(result.hasAnyEmojis, isFalse);
    });

    test('returns missing packs when folders and files do not exist', () async {
      final result = await AssetVerificationService.instance.verify(mockManifest);
      
      // The font is required and missing, so allRequiredPresent must be false.
      expect(result.allRequiredPresent, isFalse);
      expect(result.missing.length, 2);
      expect(result.missing[0].packId, 'font_outfit');
      expect(result.missing[0].isRequired, isTrue);
      expect(result.missing[1].packId, 'googleNonAnimated');
      expect(result.missing[1].isRequired, isFalse);
    });

    test('detects installed and complete packs successfully', () async {
      // 1. Create the mock font file
      final fontFile = File(p.join(FontService.instance.fontsDirectory, 'Outfit-Bold.ttf'));
      fontFile.parent.createSync(recursive: true);
      fontFile.writeAsStringSync('dummy_font_bytes');

      // 2. Create the mock emoji pack folder and file count
      final emojiDir = Directory(AssetPathService.instance.emojiPackDir('google_noto_emojis_non_animated_pack'));
      emojiDir.createSync(recursive: true);
      
      // Write 5 dummy png files to satisfy the fileCount = 5 limit
      for (int i = 0; i < 5; i++) {
        File(p.join(emojiDir.path, 'emoji_$i.png')).writeAsStringSync('dummy_image_data');
      }

      final result = await AssetVerificationService.instance.verify(mockManifest);
      
      // Both packs are installed and complete, so allRequiredPresent should be true
      expect(result.allRequiredPresent, isTrue);
      expect(result.missing, isEmpty);
      expect(result.installedPackIds, containsAll(['font_outfit', 'googleNonAnimated']));
      expect(result.hasAnyEmojis, isTrue);
    });

    test('detects emoji pack as incomplete if file count is too low', () async {
      // 1. Create font file
      final fontFile = File(p.join(FontService.instance.fontsDirectory, 'Outfit-Bold.ttf'))..createSync(recursive: true);
      fontFile.writeAsStringSync('dummy');

      // 2. Create emoji pack folder but with only 1 file (required fileCount is 5)
      final emojiDir = Directory(AssetPathService.instance.emojiPackDir('google_noto_emojis_non_animated_pack'));
      emojiDir.createSync(recursive: true);
      File(p.join(emojiDir.path, 'emoji_0.png')).writeAsStringSync('dummy');

      final result = await AssetVerificationService.instance.verify(mockManifest);
      
      // The googleNonAnimated pack is incomplete (1 < 5 files), so it should be listed in missing
      expect(result.installedPackIds, contains('font_outfit'));
      expect(result.installedPackIds, isNot(contains('googleNonAnimated')));
      expect(result.missing.length, 1);
      expect(result.missing[0].packId, 'googleNonAnimated');
      expect(result.missing[0].userMessage, contains('incomplete (1/15 files)'));
    });

    test('verifies CJK font pack via TTF filename or localFolder', () async {
      const cjkPack = AssetPack(
        id: 'fontCjkSc',
        name: 'Simplified Chinese Font',
        description: 'CJK Sc font',
        required: false,
        sizeBytes: 100,
        compressedSizeBytes: 50,
        downloadUrl: 'https://example.com/fonts/NotoSansSC-Bold.ttf',
        checksum: 'abc',
        version: '1.0',
        fileCount: 1,
        format: 'ttf',
        animated: false,
        localFolder: 'fonts',
      );

      final manifestWithCjk = AssetManifest(
        version: '1.0',
        emojis: [],
        packs: [cjkPack],
      );

      // Initially not installed
      var isInstalled = await AssetVerificationService.instance.isPackInstalled('fontCjkSc', manifestWithCjk);
      expect(isInstalled, isFalse);

      // Create font file under fonts directory with filename matching downloadUrl
      final fontFile = File(p.join(FontService.instance.fontsDirectory, 'NotoSansSC-Bold.ttf'));
      fontFile.parent.createSync(recursive: true);
      fontFile.writeAsStringSync('cjk_font_bytes');

      isInstalled = await AssetVerificationService.instance.isPackInstalled('fontCjkSc', manifestWithCjk);
      expect(isInstalled, isTrue);

      final result = await AssetVerificationService.instance.verify(manifestWithCjk);
      expect(result.installedPackIds, contains('fontCjkSc'));
      expect(result.missing, isEmpty);
    });
  });
}
