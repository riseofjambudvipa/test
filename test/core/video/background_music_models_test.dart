import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/video/background_music_models.dart';

void main() {
  group('BackgroundMusicConfig Tests', () {
    test('default constructor initializes standard defaults', () {
      const config = BackgroundMusicConfig();
      expect(config.musicPath, isNull);
      expect(config.volume, 0.20);
      expect(config.loop, isTrue);
      expect(config.enableDucking, isTrue);
      expect(config.duckingRatio, 4.0);
      expect(config.hasMusic, isFalse);
    });

    test('hasMusic detects valid audio path correctly', () {
      const emptyConfig = BackgroundMusicConfig(musicPath: '');
      expect(emptyConfig.hasMusic, isFalse);

      const whitespaceConfig = BackgroundMusicConfig(musicPath: '   ');
      expect(whitespaceConfig.hasMusic, isFalse);

      const validConfig = BackgroundMusicConfig(musicPath: '/path/to/audio.mp3');
      expect(validConfig.hasMusic, isTrue);
    });

    test('copyWith updates specified fields immutably', () {
      const initial = BackgroundMusicConfig(musicPath: '/orig.mp3', volume: 0.15);
      final updated = initial.copyWith(
        volume: 0.35,
        enableDucking: false,
        duckingRatio: 6.0,
      );

      expect(updated.musicPath, '/orig.mp3');
      expect(updated.volume, 0.35);
      expect(updated.loop, isTrue);
      expect(updated.enableDucking, isFalse);
      expect(updated.duckingRatio, 6.0);
    });

    test('value equality and hashCode match identical configs', () {
      const c1 = BackgroundMusicConfig(
        musicPath: '/track.wav',
        volume: 0.25,
        loop: true,
        enableDucking: true,
        duckingRatio: 4.0,
      );
      const c2 = BackgroundMusicConfig(
        musicPath: '/track.wav',
        volume: 0.25,
        loop: true,
        enableDucking: true,
        duckingRatio: 4.0,
      );
      const c3 = BackgroundMusicConfig(
        musicPath: '/track2.wav',
        volume: 0.25,
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1 == c3, isFalse);
    });
  });
}
