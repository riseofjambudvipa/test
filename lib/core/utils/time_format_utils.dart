/// Centralized utility for formatting timestamps and durations.
class TimeFormatUtils {
  TimeFormatUtils._();

  /// Formats seconds to `m:ss` or `mm:ss` (e.g. `01:23` or `1:23`).
  static String formatSecondsToMmSs(double seconds, {bool padMinutes = true}) {
    if (seconds.isNaN || seconds.isInfinite || seconds < 0) {
      return padMinutes ? '00:00' : '0:00';
    }
    final totalSecs = seconds.floor();
    final mins = (totalSecs ~/ 60);
    final secs = totalSecs % 60;
    final minsStr = padMinutes ? mins.toString().padLeft(2, '0') : mins.toString();
    final secsStr = secs.toString().padLeft(2, '0');
    return '$minsStr:$secsStr';
  }

  /// Formats seconds to `hh:mm:ss` or `mm:ss` if hours is 0.
  static String formatSmartTime(double seconds) {
    if (seconds.isNaN || seconds.isInfinite || seconds < 0) return '00:00';
    final totalSecs = seconds.floor();
    final hours = totalSecs ~/ 3600;
    final mins = (totalSecs % 3600) ~/ 60;
    final secs = totalSecs % 60;

    final minsStr = mins.toString().padLeft(2, '0');
    final secsStr = secs.toString().padLeft(2, '0');

    if (hours > 0) {
      final hoursStr = hours.toString().padLeft(2, '0');
      return '$hoursStr:$minsStr:$secsStr';
    }
    return '$minsStr:$secsStr';
  }

  /// Formats seconds with centiseconds: `mm:ss.cs` (e.g. `01:23.45`).
  static String formatPreciseTime(double seconds) {
    if (seconds.isNaN || seconds.isInfinite || seconds < 0) return '00:00.00';
    final totalMs = (seconds * 1000).round();
    final mins = (totalMs ~/ 60000);
    final secs = (totalMs % 60000) ~/ 1000;
    final cs = (totalMs % 1000) ~/ 10;

    final minsStr = mins.toString().padLeft(2, '0');
    final secsStr = secs.toString().padLeft(2, '0');
    final csStr = cs.toString().padLeft(2, '0');
    return '$minsStr:$secsStr.$csStr';
  }

  /// Formats Duration to `m:ss` or `hh:mm:ss`.
  static String formatDuration(Duration duration) {
    return formatSmartTime(duration.inMilliseconds / 1000.0);
  }
}
