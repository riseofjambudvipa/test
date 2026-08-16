import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/fonts/font_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late FontService service;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('font_service_test_');
    AppDirs.setSupportPathForTesting(tempDir.path);

    // Mock binary messenger channel for FontLoader: flutter/assets
    // FontLoader sends the loaded font using flutter/assets method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.skia, // Or any other channel FontLoader might use
      (MethodCall methodCall) async {
        return null;
      },
    );

    // We can also mock method calls to load font assets if necessary,
    // but in unit tests, FontLoader.load() might try to invoke native code unless mocked.
    // Let's see if we can register a simple mocked TTF file to test.
    service = FontService.instance;
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
    // Reset loaded fonts of service to avoid test pollution
    service.resetForTesting();
  });

  group('FontService Tests', () {
    test('init should create fonts directory and initialize successfully', () async {
      await service.init();
      expect(service.fontsDirectory, isNotEmpty);
      expect(Directory(service.fontsDirectory).existsSync(), isTrue);
    });

    test('should import and register custom TTF/OTF font file', () async {
      await service.init();

      // Create a fake font file
      final fakeFontFile = File('${tempDir.path}/TestFont-Regular.ttf');
      fakeFontFile.writeAsBytesSync(List.generate(100, (i) => i));

      // Import the font
      final fontName = await service.importFont(fakeFontFile.path);

      // Verify normalization and list addition
      expect(fontName, equals('TestFont'));
      expect(service.availableFonts, contains('TestFont'));

      // Check if file is copied to fonts directory
      final copiedFile = File('${service.fontsDirectory}/Custom/TestFont-Regular.ttf');
      expect(copiedFile.existsSync(), isTrue);
    });

    test('should register and unregister font successfully', () async {
      await service.init();

      final fakeFontFile = File('${tempDir.path}/AnotherFont.otf');
      fakeFontFile.writeAsBytesSync(List.generate(100, (i) => i));

      await service.registerDownloadedFont(fakeFontFile.path);
      expect(service.availableFonts, contains('AnotherFont'));

      service.unregisterFont('AnotherFont');
      expect(service.availableFonts, isNot(contains('AnotherFont')));
    });

    test('should scan and load existing fonts on initialization', () async {
      // First ensure the directory exists and has a font in it
      final fontsPath = '${tempDir.path}/fonts';
      final customFontsPath = '$fontsPath/Custom';
      Directory(customFontsPath).createSync(recursive: true);
      
      final existingFont = File('$customFontsPath/PreExisting-Regular.ttf');
      existingFont.writeAsBytesSync(List.generate(100, (i) => i));

      // Re-initialize with pre-populated directories
      await service.init();

      // It should automatically register PreExisting font
      expect(service.availableFonts, contains('PreExisting'));
    });

    test('should import font bytes and normalize name', () async {
      await service.init();
      
      final bytes = Uint8List.fromList(List.generate(100, (i) => i));
      final fontName = await service.importFontBytes(bytes, 'MyCustomFont-Bold');
      
      expect(fontName, equals('MyCustomFont'));
      expect(service.availableFonts, contains('MyCustomFont'));
      expect(service.availableFonts, isNot(contains('MyCustomFont-Bold')));
    });
  });
}
