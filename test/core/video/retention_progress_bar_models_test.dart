import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/video/retention_progress_bar_models.dart';

void main() {
  group('RetentionProgressBarConfig Model Tests', () {
    test('Default values are correct', () {
      const config = RetentionProgressBarConfig();
      expect(config.enabled, false);
      expect(config.position, 'bottom');
      expect(config.height, 6.0);
      expect(config.color, '#f97316');
      expect(config.backgroundColor, '#00000066');
      expect(config.padding, 0.0);
      expect(config.roundedCorners, false);
    });

    test('copyWith modifies only targeted fields', () {
      const original = RetentionProgressBarConfig();
      final updated = original.copyWith(
        enabled: true,
        position: 'top',
        height: 10.0,
        color: '#06b6d4',
        backgroundColor: '#00000080',
        padding: 5.0,
        roundedCorners: true,
      );

      expect(updated.enabled, true);
      expect(updated.position, 'top');
      expect(updated.height, 10.0);
      expect(updated.color, '#06b6d4');
      expect(updated.backgroundColor, '#00000080');
      expect(updated.padding, 5.0);
      expect(updated.roundedCorners, true);
    });

    test('toJson and fromJson roundtrip cleanly', () {
      const config = RetentionProgressBarConfig(
        enabled: true,
        position: 'top',
        height: 8.5,
        color: '#ec4899',
        backgroundColor: '#00000099',
        padding: 4.0,
        roundedCorners: true,
      );

      final json = config.toJson();
      final restored = RetentionProgressBarConfig.fromJson(json);

      expect(restored, config);
      expect(restored.hashCode, config.hashCode);
    });

    test('toFfmpegColor converts colors accurately', () {
      const config = RetentionProgressBarConfig();

      // Standard 6-digit hex
      final fg = config.toFfmpegColor('#f97316');
      expect(fg, '0xf97316@1.00');

      // White
      final white = config.toFfmpegColor('#ffffff');
      expect(white, '0xffffff@1.00');

      // 8-digit hex with alpha
      final bg = config.toFfmpegColor('#00000066');
      expect(bg.startsWith('0x000000@'), true);
    });

    test('Presets have expected signature properties', () {
      expect(RetentionProgressBarConfig.viralEmber.enabled, true);
      expect(RetentionProgressBarConfig.viralEmber.color, '#f97316');
      expect(RetentionProgressBarConfig.viralEmber.position, 'bottom');

      expect(RetentionProgressBarConfig.electricCyan.color, '#06b6d4');
      expect(RetentionProgressBarConfig.hotMagenta.color, '#ec4899');
      expect(RetentionProgressBarConfig.acidGreen.color, '#22c55e');
      expect(RetentionProgressBarConfig.pureMinimalist.color, '#ffffff');
      expect(RetentionProgressBarConfig.topHeader.position, 'top');
    });
  });
}
