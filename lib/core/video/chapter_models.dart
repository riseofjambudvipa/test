/// Represents a single video chapter / topic segment.
class VideoChapter {
  final String id;
  final double startTime;
  final String title;
  final String? summary;

  const VideoChapter({
    required this.id,
    required this.startTime,
    required this.title,
    this.summary,
  });

  /// Formatted timestamp (e.g., "00:00", "01:23", or "01:05:30")
  String get formattedTimestamp {
    final totalSeconds = startTime.floor();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    if (hours > 0) {
      final h = hours.toString().padLeft(2, '0');
      final m = minutes.toString().padLeft(2, '0');
      final s = seconds.toString().padLeft(2, '0');
      return '$h:$m:$s';
    } else {
      final m = minutes.toString().padLeft(2, '0');
      final s = seconds.toString().padLeft(2, '0');
      return '$m:$s';
    }
  }

  /// Single line in standard YouTube video description format:
  /// e.g. "01:23 - The Secret to Growth" or "01:23 The Secret to Growth"
  String toYouTubeLine({bool useDash = false}) {
    return useDash
        ? '$formattedTimestamp - $title'
        : '$formattedTimestamp $title';
  }

  VideoChapter copyWith({
    String? id,
    double? startTime,
    String? title,
    String? summary,
  }) {
    return VideoChapter(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      title: title ?? this.title,
      summary: summary ?? this.summary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'startTime': startTime,
      'title': title,
      if (summary != null) 'summary': summary,
    };
  }

  factory VideoChapter.fromJson(Map<String, dynamic> json) {
    return VideoChapter(
      id: json['id'] as String? ?? '',
      startTime: (json['startTime'] as num?)?.toDouble() ?? 0.0,
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoChapter &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          (startTime - other.startTime).abs() < 0.001 &&
          title == other.title;

  @override
  int get hashCode => id.hashCode ^ startTime.hashCode ^ title.hashCode;
}

/// Helper methods for formatting and validating chapter lists
class ChapterListUtils {
  /// Formats a list of chapters into standard YouTube description format
  static String formatForYouTube(List<VideoChapter> chapters, {bool useDash = false}) {
    if (chapters.isEmpty) return '';
    final sorted = List<VideoChapter>.from(chapters)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return sorted.map((c) => c.toYouTubeLine(useDash: useDash)).join('\n');
  }

  /// Verifies if chapters fulfill YouTube's official criteria:
  /// 1. At least 3 chapters in ascending order.
  /// 2. First chapter starts at 00:00 (or <= 0.5s).
  /// 3. Minimum duration between chapters is at least 10 seconds.
  static bool isValidForYouTube(List<VideoChapter> chapters) {
    if (chapters.length < 3) return false;
    final sorted = List<VideoChapter>.from(chapters)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // First chapter must start at 0
    if (sorted.first.startTime > 0.5) return false;

    // Minimum 10 seconds between each chapter
    for (int i = 0; i < sorted.length - 1; i++) {
      if (sorted[i + 1].startTime - sorted[i].startTime < 9.5) {
        return false;
      }
    }
    return true;
  }
}
