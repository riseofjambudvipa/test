import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/assets/asset_path_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('capstudio_assets_test_');
    AppDirs.setSupportPathForTesting(tempDir.path);
    await AppDirs.init();
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('AssetPathService Tests', () {
    test('static packFolderName maps correctly', () {
      expect(AssetPathService.packFolderName('googleAnimated'), 'google_noto_emojis_animated_pack');
      expect(AssetPathService.packFolderName('microsoftNonAnimated'), 'microsoft_fluentui_emoji_non_animated_pack');
      expect(AssetPathService.packFolderName('unknown'), isNull);
    });

    test('static packSubdir maps correctly', () {
      expect(AssetPathService.packSubdir('googleAnimated'), '512x512/');
      expect(AssetPathService.packSubdir('microsoftAnimated'), '256x256/');
      expect(AssetPathService.packSubdir('openmoji'), '618x618/');
      expect(AssetPathService.packSubdir('unknown'), '');
    });

    test('initialization resolves assetsRoot and subdirectories', () async {
      final service = AssetPathService.instance;
      await service.init();
      
      expect(service.assetsRoot, isNotEmpty);
      expect(service.emojisDir, p.join(service.assetsRoot, 'emojis'));
      expect(service.fontsDir, p.join(service.assetsRoot, 'fonts'));
      expect(service.sfxDir, p.join(service.assetsRoot, 'sfx'));
      expect(service.tempDir, p.join(service.assetsRoot, 'temp'));
      expect(service.customStickersDir, p.join(service.assetsRoot, 'custom_stickers'));

      // Check directories actually got created
      expect(Directory(service.assetsRoot).existsSync(), isTrue);
      expect(Directory(service.emojisDir).existsSync(), isTrue);
      expect(Directory(service.fontsDir).existsSync(), isTrue);
    });

    test('setDesktopAssetsFolder overrides folder and persists to SharedPreferences', () async {
      final service = AssetPathService.instance;
      await service.init();

      final customFolder = Directory(p.join(tempDir.path, 'MyCustomAssets')).path;
      
      // Call setDesktopAssetsFolder
      await service.setDesktopAssetsFolder(customFolder);
      
      // Expected custom folder format: since the custom folder doesn't have emojis/fonts directly,
      // it should append 'CapStudio/assets'
      final expectedPath = p.join(customFolder, 'CapStudio', 'assets');
      expect(service.assetsRoot, expectedPath);
      expect(Directory(expectedPath).existsSync(), isTrue);
      
      // Verify stored preference in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('capstudio_assets_folder'), expectedPath);
      
      expect(await service.hasConfiguredAssetsFolder, isTrue);
    });

    test('setDesktopAssetsFolder without CapStudio suffix if emojis folder already exists', () async {
      final service = AssetPathService.instance;
      await service.init();

      final customFolder = p.join(tempDir.path, 'MyDirectAssets');
      Directory(p.join(customFolder, 'emojis')).createSync(recursive: true);
      
      await service.setDesktopAssetsFolder(customFolder);
      
      // Should not append CapStudio/assets since emojis directory was found
      expect(service.assetsRoot, customFolder);
    });
  });
}
