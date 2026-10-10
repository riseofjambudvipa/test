import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/utils/time_format_utils.dart';

void main() {
  group('TimeFormatUtils.formatSecondsToMmSs', () {
    test('formats standard seconds with padding', () {
      expect(TimeFormatUtils.formatSecondsToMmSs(65), equals('01:05'));
      expect(TimeFormatUtils.formatSecondsToMmSs(0), equals('00:00'));
      expect(TimeFormatUtils.formatSecondsToMmSs(59), equals('00:59'));
    });

    test('formats without padding minutes when requested', () {
      expect(TimeFormatUtils.formatSecondsToMmSs(65, padMinutes: false), equals('1:05'));
      expect(TimeFormatUtils.formatSecondsToMmSs(5, padMinutes: false), equals('0:05'));
    });

    test('handles negative, NaN, and infinite values safely', () {
      expect(TimeFormatUtils.formatSecondsToMmSs(-10), equals('00:00'));
      expect(TimeFormatUtils.formatSecondsToMmSs(double.nan), equals('00:00'));
      expect(TimeFormatUtils.formatSecondsToMmSs(double.infinity), equals('00:00'));
    });
  });

  group('TimeFormatUtils.formatSmartTime', () {
    test('formats under an hour without hours prefix', () {
      expect(TimeFormatUtils.formatSmartTime(45), equals('00:45'));
      expect(TimeFormatUtils.formatSmartTime(125), equals('02:05'));
    });

    test('formats over an hour with hours prefix', () {
      expect(TimeFormatUtils.formatSmartTime(3665), equals('01:01:05'));
      expect(TimeFormatUtils.formatSmartTime(7200), equals('02:00:00'));
    });
  });

  group('TimeFormatUtils.formatPreciseTime', () {
    test('formats with centiseconds', () {
      expect(TimeFormatUtils.formatPreciseTime(65.45), equals('01:05.45'));
      expect(TimeFormatUtils.formatPreciseTime(0.0), equals('00:00.00'));
    });
  });

  group('TimeFormatUtils.formatDuration', () {
    test('formats Duration instances', () {
      expect(TimeFormatUtils.formatDuration(const Duration(minutes: 2, seconds: 30)), equals('02:30'));
      expect(TimeFormatUtils.formatDuration(const Duration(hours: 1, minutes: 1, seconds: 1)), equals('01:01:01'));
    });
  });
}
