import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/brand/brand_kit_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('BrandKitService Tests', () {
    test('getBrandKits returns curated default kits when empty', () async {
      final kits = await BrandKitService.instance.getBrandKits();
      expect(kits, isNotEmpty);
      expect(kits.length, equals(BrandKitService.defaultBrandKits.length));
      expect(kits.any((k) => k.name == 'Viral Creator Hype'), isTrue);
      expect(kits.any((k) => k.handle == '@viralcreator'), isTrue);
    });

    test('saveBrandKit inserts new kit and updates existing kit', () async {
      final newKit = BrandKit(
        id: 'custom_brand_1',
        name: 'My Custom Brand',
        handle: '@mybrand',
        primaryColor: '#123456',
        secondaryColor: '#654321',
        accentColor: '#ABCDEF',
        fontFamily: 'Montserrat',
      );

      await BrandKitService.instance.saveBrandKit(newKit);

      var kits = await BrandKitService.instance.getBrandKits();
      expect(kits.any((k) => k.id == 'custom_brand_1'), isTrue);
      final saved = kits.firstWhere((k) => k.id == 'custom_brand_1');
      expect(saved.name, equals('My Custom Brand'));
      expect(saved.primaryColor, equals('#123456'));

      // Update existing
      final updated = saved.copyWith(name: 'Updated Brand Name', primaryColor: '#00FF00');
      await BrandKitService.instance.saveBrandKit(updated);

      kits = await BrandKitService.instance.getBrandKits();
      final reloaded = kits.firstWhere((k) => k.id == 'custom_brand_1');
      expect(reloaded.name, equals('Updated Brand Name'));
      expect(reloaded.primaryColor, equals('#00FF00'));
    });

    test('deleteBrandKit removes kit by id', () async {
      final kitsBefore = await BrandKitService.instance.getBrandKits();
      final idToDelete = kitsBefore.first.id;

      await BrandKitService.instance.deleteBrandKit(idToDelete);

      final kitsAfter = await BrandKitService.instance.getBrandKits();
      expect(kitsAfter.any((k) => k.id == idToDelete), isFalse);
    });

    test('export and import brand kit JSON preserves all attributes', () {
      final original = BrandKit(
        id: 'orig_123',
        name: 'Export Test Brand',
        handle: '@exporttest',
        primaryColor: '#E11D48',
        secondaryColor: '#2563EB',
        accentColor: '#10B981',
        fontFamily: 'Space Grotesk',
        logoPosition: 'bottomRight',
        logoOpacity: 0.85,
        logoScale: 0.6,
      );

      final jsonStr = BrandKitService.instance.exportBrandKitJson(original);
      expect(jsonStr, contains('capstudio_brand_kit'));
      expect(jsonStr, contains('Export Test Brand'));

      final imported = BrandKitService.instance.importBrandKitJson(jsonStr);
      expect(imported.name, equals(original.name));
      expect(imported.handle, equals(original.handle));
      expect(imported.primaryColor, equals(original.primaryColor));
      expect(imported.secondaryColor, equals(original.secondaryColor));
      expect(imported.accentColor, equals(original.accentColor));
      expect(imported.fontFamily, equals(original.fontFamily));
      expect(imported.logoPosition, equals(original.logoPosition));
      expect(imported.logoOpacity, equals(original.logoOpacity));
      expect(imported.logoScale, equals(original.logoScale));
      // ID should be freshly generated for imported kit
      expect(imported.id, isNot(equals(original.id)));
    });

    test('resetToDefaults restores initial curated kits', () async {
      await BrandKitService.instance.deleteBrandKit('kit_viral_hype');
      var kits = await BrandKitService.instance.getBrandKits();
      expect(kits.any((k) => k.id == 'kit_viral_hype'), isFalse);

      await BrandKitService.instance.resetToDefaults();
      kits = await BrandKitService.instance.getBrandKits();
      expect(kits.length, equals(BrandKitService.defaultBrandKits.length));
      expect(kits.any((k) => k.id == 'kit_viral_hype'), isTrue);
    });
  });
}
