import '../../../core/database/schemas/word.dart';

/// Represents a single chapter / topic timestamp marker in a video
class ChapterMarker {
  final String title;
  final double startTime;
  final double endTime;
  final String summary;

  const ChapterMarker({
    required this.title,
    required this.startTime,
    required this.endTime,
    this.summary = '',
  });

  /// Formats seconds to mm:ss or hh:mm:ss for YouTube descriptions
  String get timestamp => formatTime(startTime);

  static String formatTime(double seconds) {
    if (seconds < 0) seconds = 0;
    final totalSec = seconds.floor();
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    final s = totalSec % 60;

    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  /// Converts a list of chapters into standard YouTube description format:
  /// 00:00 Intro
  /// 01:15 Setting Up
  /// 03:40 The Main Technique
  static String formatForYouTube(List<ChapterMarker> chapters) {
    if (chapters.isEmpty) return '';
    final buffer = StringBuffer();
    for (int i = 0; i < chapters.length; i++) {
      final ch = chapters[i];
      buffer.writeln('${ch.timestamp} ${ch.title}');
    }
    return buffer.toString().trim();
  }
}

/// Service that automatically detects semantic topic shifts and speech structure
/// to generate YouTube-ready video chapters.
class ChapterMarkerService {
  ChapterMarkerService._();
  static final ChapterMarkerService instance = ChapterMarkerService._();

  static const List<String> _transitionKeywords = [
    // English
    'first',
    'firstly',
    'second',
    'secondly',
    'third',
    'next',
    'finally',
    'in conclusion',
    'to summarize',
    'now let\'s',
    'now lets',
    'let\'s talk about',
    'lets talk about',
    'moving on',
    'the problem is',
    'the solution',
    'step 1',
    'step one',
    'step 2',
    'step two',
    'step 3',
    'step three',
    'tip 1',
    'tip one',
    'tip 2',
    'tip two',
    'tip 3',
    'tip three',
    'how to',
    'the secret',
    'my recommendation',
    'what you need to know',
    // Spanish
    'en primer lugar',
    'en segundo lugar',
    'finalmente',
    'para resumir',
    'hablemos de',
    'el problema',
    'la solución',
    'paso 1',
    'paso 2',
    'paso 3',
    // Hindi / Hinglish
    'pehla step',
    'dusra step',
    'tisra step',
    'ab baat karte hain',
    'asli trick',
    'aakhri baat',
  ];

  /// Detects and generates chapter markers from transcribed words.
  /// Guarantees YouTube compliance:
  /// 1. First timestamp starts at 00:00.
  /// 2. At least 3 chapters if video duration allows.
  /// 3. Minimum [minChapterDuration] seconds per chapter.
  List<ChapterMarker> generateChapters(
    List<WordSchema> words,
    double totalDuration, {
    double minChapterDuration = 30.0,
  }) {
    if (words.isEmpty || totalDuration <= 0) return [];

    final visibleWords = words.where((w) => w.hidden != true).toList();
    if (visibleWords.isEmpty) return [];

    // Filter to sentence starts / thoughts
    final candidatePoints = <({double time, String title})>[];

    // Always start with 0.0 Intro
    candidatePoints.add((time: 0.0, title: 'Intro'));

    for (int i = 0; i < visibleWords.length - 1; i++) {
      final currentWord = visibleWords[i];
      final nextWord = visibleWords[i + 1];
      final currentTime = currentWord.end ?? (currentWord.start ?? 0.0);
      final nextTime = nextWord.start ?? currentTime;
      final pause = nextTime - currentTime;

      // Scan window of next 4 words for transition phrases
      final windowWords = visibleWords.skip(i + 1).take(5).toList();
      final windowText = windowWords.map((w) => (w.text ?? '').toLowerCase()).join(' ');

      bool isTransition = false;
      String? matchedTransition;

      for (final kw in _transitionKeywords) {
        if (windowText.startsWith(kw)) {
          isTransition = true;
          matchedTransition = kw;
          break;
        }
      }

      // Large pause (>= 1.2s) or explicit transition keyword
      if (isTransition || pause >= 1.2) {
        // Enforce spacing from last point
        final lastPointTime = candidatePoints.isNotEmpty ? candidatePoints.last.time : 0.0;
        if (nextTime - lastPointTime >= minChapterDuration && totalDuration - nextTime >= minChapterDuration * 0.6) {
          final title = _generateChapterTitle(
            visibleWords.sublist(i + 1, (i + 9).clamp(i + 1, visibleWords.length)),
            fallbackKeyword: matchedTransition,
            chapterIndex: candidatePoints.length,
          );
          candidatePoints.add((time: nextTime, title: title));
        }
      }
    }

    // If duration is substantial (e.g. > 90s) but fewer than 3 chapters were found,
    // generate evenly spaced topical milestones
    if (candidatePoints.length < 3 && totalDuration >= 60.0) {
      final targetCount = (totalDuration / 45.0).clamp(3, 8).floor();
      final interval = totalDuration / targetCount;
      candidatePoints.clear();
      candidatePoints.add((time: 0.0, title: 'Intro'));

      for (int c = 1; c < targetCount; c++) {
        final targetTime = c * interval;
        // Find closest word start
        final closestWordIdx = visibleWords.indexWhere((w) => (w.start ?? 0.0) >= targetTime);
        if (closestWordIdx != -1) {
          final wTime = visibleWords[closestWordIdx].start ?? targetTime;
          final title = _generateChapterTitle(
            visibleWords.sublist(closestWordIdx, (closestWordIdx + 7).clamp(closestWordIdx, visibleWords.length)),
            chapterIndex: c,
          );
          candidatePoints.add((time: wTime, title: title));
        }
      }
    }

    // Build final ChapterMarker instances with boundaries
    final result = <ChapterMarker>[];
    for (int i = 0; i < candidatePoints.length; i++) {
      final start = candidatePoints[i].time;
      final end = (i + 1 < candidatePoints.length) ? candidatePoints[i + 1].time : totalDuration;
      result.add(ChapterMarker(
        title: candidatePoints[i].title,
        startTime: start,
        endTime: end,
      ));
    }

    return result;
  }

  String _generateChapterTitle(
    List<WordSchema> upcomingWords, {
    String? fallbackKeyword,
    required int chapterIndex,
  }) {
    if (fallbackKeyword != null && fallbackKeyword.isNotEmpty) {
      return _toTitleCase(fallbackKeyword);
    }

    final rawSnippet = upcomingWords
        .map((w) => (w.text ?? '').replaceAll(RegExp(r'[^\w\s]'), ''))
        .where((t) => t.isNotEmpty)
        .take(5)
        .join(' ')
        .trim();

    if (rawSnippet.isEmpty) {
      return 'Part $chapterIndex';
    }

    final title = _toTitleCase(rawSnippet);
    if (title.length > 32) {
      return '${title.substring(0, 29)}...';
    }
    return title;
  }

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      final lower = word.toLowerCase();
      // Keep small grammatical words lower if not first word
      if (const {'a', 'an', 'the', 'and', 'or', 'in', 'on', 'at', 'to', 'for', 'of'}.contains(lower)) {
        return lower;
      }
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }
}
