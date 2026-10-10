import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/video/retention_progress_bar_models.dart';
import 'package:capstudio/features/exporter/data/ffmpeg_filters.dart';

void main() {
  group('FFmpeg Retention Progress Bar Filter Tests', () {
    test('buildRetentionProgressBarFilter returns empty string when disabled', () {
      const config = RetentionProgressBarConfig(enabled: false);
      final filter = FfmpegFilterBuilder.buildRetentionProgressBarFilter(
        config: config,
        duration: 30.0,
        exportScale: 1.0,
      );
      expect(filter, isEmpty);
    });

    test('buildRetentionProgressBarFilter returns empty string when duration <= 0', () {
      const config = RetentionProgressBarConfig(enabled: true);
      final filter = FfmpegFilterBuilder.buildRetentionProgressBarFilter(
        config: config,
        duration: 0.0,
        exportScale: 1.0,
      );
      expect(filter, isEmpty);
    });

    test('buildRetentionProgressBarFilter generates bottom bar with background track', () {
      const config = RetentionProgressBarConfig(
        enabled: true,
        position: 'bottom',
        height: 6.0,
        color: '#f97316',
        backgroundColor: '#00000066',
        padding: 0.0,
      );

      final filter = FfmpegFilterBuilder.buildRetentionProgressBarFilter(
        config: config,
        duration: 25.0,
        exportScale: 1.5,
      );

      // Height: 6.0 * 1.5 = 9
      expect(filter, contains('drawbox=x=0:y=ih-9-0:w=iw:h=9:color=0x000000@'));
      expect(filter, contains('drawbox=x=0:y=ih-9-0:w=\'min(iw,iw*(t/25.000))\':h=9:color=0xf97316@1.00:t=fill'));
    });

    test('buildRetentionProgressBarFilter generates top bar with padding', () {
      const config = RetentionProgressBarConfig(
        enabled: true,
        position: 'top',
        height: 8.0,
        color: '#06b6d4',
        backgroundColor: '',
        padding: 10.0,
      );

      final filter = FfmpegFilterBuilder.buildRetentionProgressBarFilter(
        config: config,
        duration: 40.0,
        exportScale: 2.0,
      );

      // Height: 8.0 * 2.0 = 16, Padding: 10.0 * 2.0 = 20
      expect(filter.contains('drawbox=x=0:y=ih'), false);
      expect(filter, contains('y=20'));
      expect(filter, contains('h=16'));
      expect(filter, contains('color=0x06b6d4@1.00'));
      // No background track generated because backgroundColor is empty
      expect(filter.contains('w=iw:'), false);
    });
  });
}
