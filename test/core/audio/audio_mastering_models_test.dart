import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/audio/audio_mastering_models.dart';

void main() {
  group('AudioMasteringPlatform', () {
    test('socialShorts contains -14 LUFS broadcast filter', () {
      const platform = AudioMasteringPlatform.socialShorts;
      expect(platform.targetLufs, -14.0);
      expect(platform.loudnormFilter, contains('loudnorm=I=-14:TP=-1.0:LRA=7'));
      expect(platform.label, contains('-14 LUFS'));
    });

    test('broadcastPodcast contains -16 LUFS filter', () {
      const platform = AudioMasteringPlatform.broadcastPodcast;
      expect(platform.targetLufs, -16.0);
      expect(platform.loudnormFilter, contains('loudnorm=I=-16:TP=-1.5:LRA=11'));
      expect(platform.label, contains('-16 LUFS'));
    });

    test('cinemaHeadroom contains -23 LUFS filter', () {
      const platform = AudioMasteringPlatform.cinemaHeadroom;
      expect(platform.targetLufs, -23.0);
      expect(platform.loudnormFilter, contains('loudnorm=I=-23:TP=-2.0:LRA=14'));
      expect(platform.label, contains('-23 LUFS'));
    });
  });

  group('AudioMasteringConfig', () {
    test('default configuration has correct defaults', () {
      const config = AudioMasteringConfig();
      expect(config.enableStudioSound, isFalse);
      expect(config.platform, AudioMasteringPlatform.socialShorts);
      expect(config.enableDeEsser, isTrue);
      expect(config.deEsserIntensity, 0.40);
    });

    test('copyWith updates fields correctly', () {
      const config = AudioMasteringConfig();
      final updated = config.copyWith(
        enableStudioSound: true,
        platform: AudioMasteringPlatform.broadcastPodcast,
        enableDeEsser: false,
        deEsserIntensity: 0.65,
      );

      expect(updated.enableStudioSound, isTrue);
      expect(updated.platform, AudioMasteringPlatform.broadcastPodcast);
      expect(updated.enableDeEsser, isFalse);
      expect(updated.deEsserIntensity, 0.65);
    });

    test('toJson and fromJson roundtrips accurately', () {
      const config = AudioMasteringConfig(
        enableStudioSound: true,
        platform: AudioMasteringPlatform.cinemaHeadroom,
        enableDeEsser: true,
        deEsserIntensity: 0.50,
      );

      final json = config.toJson();
      expect(json['enableStudioSound'], isTrue);
      expect(json['platform'], 'cinemaHeadroom');
      expect(json['enableDeEsser'], isTrue);
      expect(json['deEsserIntensity'], 0.50);

      final restored = AudioMasteringConfig.fromJson(json);
      expect(restored, equals(config));
    });

    test('equality and hashCode contract', () {
      const c1 = AudioMasteringConfig(
        enableStudioSound: true,
        platform: AudioMasteringPlatform.socialShorts,
        enableDeEsser: true,
        deEsserIntensity: 0.40,
      );
      const c2 = AudioMasteringConfig(
        enableStudioSound: true,
        platform: AudioMasteringPlatform.socialShorts,
        enableDeEsser: true,
        deEsserIntensity: 0.40,
      );
      const c3 = AudioMasteringConfig(
        enableStudioSound: false,
        platform: AudioMasteringPlatform.broadcastPodcast,
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });
  });
}
