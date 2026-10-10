import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/video/b_roll_models.dart';
import 'package:capstudio/core/video/b_roll_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BRollStorageService.instance.clearCache();
  });

  group('BRollClip Model Tests', () {
    test('constructs and calculates duration properly', () {
      const clip = BRollClip(
        id: 'c1',
        mediaPath: '/media/stock.mp4',
        startTime: 2.0,
        endTime: 5.5,
        name: 'Money Stock',
        category: 'Finance',
      );

      expect(clip.id, equals('c1'));
      expect(clip.duration, equals(3.5));
      expect(clip.isVideo, isTrue);
      expect(clip.isPictureInPicture, isFalse);
    });

    test('isVideo detects image vs video extensions', () {
      const vid = BRollClip(
        id: 'c1',
        mediaPath: '/media/stock.MOV',
        startTime: 0.0,
        endTime: 2.0,
      );
      expect(vid.isVideo, isTrue);

      const img = BRollClip(
        id: 'c2',
        mediaPath: '/media/photo.png',
        startTime: 0.0,
        endTime: 2.0,
      );
      expect(img.isVideo, isFalse);
    });

    test('JSON serialization roundtrips correctly', () {
      const clip = BRollClip(
        id: 'c_json',
        mediaPath: '/assets/clip.webm',
        startTime: 1.0,
        endTime: 4.0,
        name: 'Chart Overlay',
        category: 'Business',
        isPictureInPicture: true,
        pipPosition: 'bottom_right',
        volume: 0.5,
      );

      final json = clip.toJson();
      final revived = BRollClip.fromJson(json);

      expect(revived, equals(clip));
      expect(revived.isPictureInPicture, isTrue);
      expect(revived.pipPosition, equals('bottom_right'));
      expect(revived.volume, equals(0.5));
    });
  });

  group('BRollStorageService Tests', () {
    test('getClips returns empty for uncached project', () {
      final clips = BRollStorageService.instance.getClips('proj_new');
      expect(clips, isEmpty);
    });

    test('saveClips persists and loads clips successfully', () async {
      const clips = [
        BRollClip(
          id: 'clip_1',
          mediaPath: '/path/broll1.mp4',
          startTime: 1.0,
          endTime: 3.0,
          name: 'Broll 1',
        ),
        BRollClip(
          id: 'clip_2',
          mediaPath: '/path/image.jpg',
          startTime: 4.0,
          endTime: 6.0,
          name: 'Photo',
        ),
      ];

      await BRollStorageService.instance.saveClips('proj_persist', clips);

      // Verify synchronous cache
      final cached = BRollStorageService.instance.getClips('proj_persist');
      expect(cached.length, equals(2));
      expect(cached[0].id, equals('clip_1'));

      // Clear cache and verify async load from storage
      BRollStorageService.instance.clearCache();
      final loaded = await BRollStorageService.instance.loadClips('proj_persist');
      expect(loaded.length, equals(2));
      expect(loaded[1].name, equals('Photo'));
    });
  });
}
