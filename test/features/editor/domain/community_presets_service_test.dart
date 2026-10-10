import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/features/editor/domain/community_presets_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CommunityPresetsService Tests', () {
    test('Service has curated creator packs with valid templates', () {
      final packs = CommunityPresetsService.instance.packs;
      expect(packs.isNotEmpty, isTrue);
      expect(packs.length, greaterThanOrEqualTo(4));

      for (final pack in packs) {
        expect(pack.id.isNotEmpty, isTrue);
        expect(pack.title.isNotEmpty, isTrue);
        expect(pack.creator.isNotEmpty, isTrue);
        expect(pack.presets.isNotEmpty, isTrue);

        for (final preset in pack.presets) {
          expect(preset.id.isNotEmpty, isTrue);
          expect(preset.name.isNotEmpty, isTrue);
          expect(preset.fontFamily.isNotEmpty, isTrue);
          expect(preset.color.isNotEmpty, isTrue);
          expect(preset.mainColor.isNotEmpty, isTrue);

          // Verify serialization roundtrip
          final jsonMap = preset.toJson();
          expect(jsonMap['id'], preset.id);
          expect(jsonMap['name'], preset.name);
        }
      }
    });

    test('installPack successfully saves presets into SharedPreferences', () async {
      final service = CommunityPresetsService.instance;
      final pack = service.packs.first;

      final initialInstalled = await service.isPackInstalled(pack.id);
      expect(initialInstalled, isFalse);

      final addedCount = await service.installPack(pack);
      expect(addedCount, pack.presets.length);

      final isInstalledNow = await service.isPackInstalled(pack.id);
      expect(isInstalledNow, isTrue);

      // Verify SharedPreferences has the saved presets
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('custom_presets') ?? [];
      expect(list.length, pack.presets.length);

      // Installing again should add 0 new presets (deduplication)
      final secondInstallCount = await service.installPack(pack);
      expect(secondInstallCount, 0);
    });

    test('searchPacks filters correctly by query and tag', () {
      final service = CommunityPresetsService.instance;
      
      final hormoziSearch = service.searchPacks(query: 'Hormozi');
      expect(hormoziSearch.any((p) => p.title.contains('Retention') || p.creator.contains('Hormozi')), isTrue);

      final podcastSearch = service.searchPacks(tag: 'Podcast');
      expect(podcastSearch.isNotEmpty, isTrue);
      expect(podcastSearch.every((p) => p.tags.contains('Podcast')), isTrue);
    });
  });
}
