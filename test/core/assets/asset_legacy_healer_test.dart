import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/assets/asset_legacy_healer.dart';
import 'package:capstudio/core/assets/asset_path_service.dart';
import 'package:capstudio/core/assets/asset_verification_service.dart';
import 'package:capstudio/core/assets/asset_manifest.dart';
import 'package:capstudio/core/fonts/font_service.dart';
import '../../test_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerTestEnvironment(silenceLogs: true);

  group('AssetLegacyHealer Tests', () {
    late Directory tempRoot;
    late String emojisDir;

    setUp(() async {
      await AssetPathService.instance.init();
      final rootPath = AssetPathService.instance.assetsRoot;
      tempRoot = Directory(rootPath);
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
      tempRoot.createSync(recursive: true);
      emojisDir = AssetPathService.instance.emojisDir;
      Directory(emojisDir).createSync(recursive: true);
      await FontService.instance.init();
    });

    tearDown(() {
      try {
        if (tempRoot.existsSync()) {
          tempRoot.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('heals loose 618x618 directory and LICENSE.md into openmoji_non_animated_pack', () async {
      // Setup loose files as created by the previous buggy extraction
      final loose618 = Directory(p.join(emojisDir, '618x618', 'Activities'));
      loose618.createSync(recursive: true);
      File(p.join(loose618.path, '1f380.png')).writeAsBytesSync([1, 2, 3]);

      final looseLicense = File(p.join(emojisDir, 'LICENSE.md'));
      looseLicense.writeAsStringSync('# OpenMoji License\nCC BY-SA 4.0');

      // Run healer
      final healed = await AssetLegacyHealer.heal(emojisDir);

      expect(healed.contains('openmoji'), isTrue);

      // Verify loose folder was moved
      expect(Directory(p.join(emojisDir, '618x618')).existsSync(), isFalse);
      expect(File(p.join(emojisDir, 'LICENSE.md')).existsSync(), isFalse);

      // Verify target pack directory has the files
      final targetFile = File(p.join(emojisDir, 'openmoji_non_animated_pack', '618x618', 'Activities', '1f380.png'));
      expect(targetFile.existsSync(), isTrue);
      expect(targetFile.readAsBytesSync(), [1, 2, 3]);

      final targetLicense = File(p.join(emojisDir, 'openmoji_non_animated_pack', 'LICENSE.md'));
      expect(targetLicense.existsSync(), isTrue);
      expect(targetLicense.readAsStringSync(), contains('OpenMoji'));
    });

    test('heals loose 512x512 png directory into google_noto_emojis_non_animated_pack', () async {
      final loose512 = Directory(p.join(emojisDir, '512x512', 'Smileys'));
      loose512.createSync(recursive: true);
      File(p.join(loose512.path, '1f600.png')).writeAsBytesSync([10, 20]);

      final healed = await AssetLegacyHealer.heal(emojisDir);

      expect(healed.contains('googleNonAnimated'), isTrue);
      expect(Directory(p.join(emojisDir, '512x512')).existsSync(), isFalse);

      final targetFile = File(p.join(emojisDir, 'google_noto_emojis_non_animated_pack', '512x512', 'Smileys', '1f600.png'));
      expect(targetFile.existsSync(), isTrue);
    });

    test('heals loose 512x512 animated (gif) directory into google_noto_emojis_animated_pack', () async {
      final loose512 = Directory(p.join(emojisDir, '512x512', 'Smileys'));
      loose512.createSync(recursive: true);
      File(p.join(loose512.path, '1f600.gif')).writeAsBytesSync([10, 20]);

      final healed = await AssetLegacyHealer.heal(emojisDir);

      expect(healed.contains('googleAnimated'), isTrue);
      expect(Directory(p.join(emojisDir, '512x512')).existsSync(), isFalse);

      final targetFile = File(p.join(emojisDir, 'google_noto_emojis_animated_pack', '512x512', 'Smileys', '1f600.gif'));
      expect(targetFile.existsSync(), isTrue);
    });

    test('heals loose 256x256 directory into microsoft_fluentui_emoji_non_animated_pack', () async {
      final loose256 = Directory(p.join(emojisDir, '256x256', 'Smileys'));
      loose256.createSync(recursive: true);
      File(p.join(loose256.path, '1f600.png')).writeAsBytesSync([30, 40]);

      final healed = await AssetLegacyHealer.heal(emojisDir);

      expect(healed.contains('microsoftNonAnimated'), isTrue);
      expect(Directory(p.join(emojisDir, '256x256')).existsSync(), isFalse);

      final targetFile = File(p.join(emojisDir, 'microsoft_fluentui_emoji_non_animated_pack', '256x256', 'Smileys', '1f600.png'));
      expect(targetFile.existsSync(), isTrue);
    });

    test('heals legacy pack ID directory to localFolder name', () async {
      final legacyDir = Directory(p.join(emojisDir, 'openmoji', '618x618'));
      legacyDir.createSync(recursive: true);
      File(p.join(legacyDir.path, '1f380.png')).writeAsBytesSync([5, 6]);

      final healed = await AssetLegacyHealer.heal(emojisDir);

      expect(healed.contains('openmoji'), isTrue);
      expect(Directory(p.join(emojisDir, 'openmoji')).existsSync(), isFalse);

      final targetFile = File(p.join(emojisDir, 'openmoji_non_animated_pack', '618x618', '1f380.png'));
      expect(targetFile.existsSync(), isTrue);
    });

    test('un-nests double nested folder', () async {
      final doubleNestedDir = Directory(p.join(emojisDir, 'openmoji_non_animated_pack', 'openmoji_non_animated_pack', '618x618'));
      doubleNestedDir.createSync(recursive: true);
      File(p.join(doubleNestedDir.path, '1f380.png')).writeAsBytesSync([7, 8]);

      final healed = await AssetLegacyHealer.heal(emojisDir);

      expect(healed.contains('openmoji'), isTrue);
      expect(Directory(p.join(emojisDir, 'openmoji_non_animated_pack', 'openmoji_non_animated_pack')).existsSync(), isFalse);

      final targetFile = File(p.join(emojisDir, 'openmoji_non_animated_pack', '618x618', '1f380.png'));
      expect(targetFile.existsSync(), isTrue);
    });

    test('AssetVerificationService automatically invokes healer and detects healed pack', () async {
      // Simulate user having loose 618x618 from old buggy extraction
      final loose618 = Directory(p.join(emojisDir, '618x618'));
      loose618.createSync(recursive: true);
      // Create 15 files so fileCount verification passes
      for (int i = 0; i < 15; i++) {
        File(p.join(loose618.path, 'emoji_$i.png')).writeAsBytesSync([i]);
      }

      final manifest = AssetManifest(
        version: '1.0',
        emojis: [],
        packs: [
          const AssetPack(
            id: 'openmoji',
            name: 'OpenMoji',
            description: 'OpenMoji',
            required: false,
            sizeBytes: 100,
            compressedSizeBytes: 50,
            downloadUrl: '',
            checksum: '',
            version: '1.0',
            fileCount: 15,
            format: 'png',
            animated: false,
            localFolder: 'openmoji_non_animated_pack',
          ),
        ],
      );

      final result = await AssetVerificationService.instance.verify(manifest);

      expect(result.installedPackIds.contains('openmoji'), isTrue);
      expect(result.missing.where((m) => m.packId == 'openmoji'), isEmpty);
      expect(Directory(p.join(emojisDir, '618x618')).existsSync(), isFalse);
      expect(Directory(p.join(emojisDir, 'openmoji_non_animated_pack')).existsSync(), isTrue);
    });
  });
}
