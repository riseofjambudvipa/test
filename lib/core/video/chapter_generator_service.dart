import 'dart:math' as math;
import 'package:uuid/uuid.dart';
import '../database/schemas/word.dart';
import '../logger/logger_service.dart';
import 'chapter_models.dart';

/// Automatic AI-driven Chapter / Topic Marker Generation Service.
/// Parses transcripts for transition indicators, pause boundaries,
/// and topic changes to produce clean, YouTube-ready chapters.
class ChapterGeneratorService {
  ChapterGeneratorService._();
  static final ChapterGeneratorService instance = ChapterGeneratorService._();

  static const List<String> _transitionPhrases = [
    // English
    'let\'s talk about',
    'let us talk about',
    'talking about',
    'moving on to',
    'moving on',
    'next up',
    'next is',
    'next step',
    'in this part',
    'in this section',
    'first of all',
    'firstly',
    'secondly',
    'thirdly',
    'the secret to',
    'the reason why',
    'here is why',
    'this is why',
    'biggest mistake',
    'common mistake',
    'step one',
    'step two',
    'step three',
    'step four',
    'step five',
    'tip number',
    'finally',
    'in conclusion',
    'to summarize',
    'wrapping up',
    'final thoughts',
    'summary',

    // Spanish
    'hablemos de',
    'el siguiente paso',
    'en esta parte',
    'en esta sección',
    'primero que nada',
    'en segundo lugar',
    'el mayor error',
    'finalmente',
    'en conclusión',

    // Hindi / Hinglish
    'aaj hum baat karenge',
    'agla topic',
    'agla step',
    'shuruat karte hain',
    'pehle step',
    'doosra step',
    'sabse badi galti',
    'aakhir mein',

    // French
    'parlons de',
    'passons à',
    'dans cette partie',
    'premièrement',
    'deuxièmement',
    'la plus grande erreur',
    'enfin',
    'en conclusion',
  ];

  static const Set<String> _stopWords = {
    'the', 'be', 'to', 'of', 'and', 'a', 'in', 'that', 'have',
    'it', 'for', 'not', 'on', 'with', 'he', 'as', 'you', 'do',
    'at', 'this', 'but', 'his', 'by', 'from', 'they', 'we', 'say',
    'her', 'she', 'or', 'an', 'will', 'my', 'one', 'all', 'would',
    'there', 'their', 'what', 'so', 'up', 'out', 'if', 'about', 'who',
    'get', 'which', 'go', 'me', 'when', 'make', 'can', 'like', 'time',
    'no', 'just', 'him', 'know', 'take', 'people', 'into', 'year',
    'your', 'good', 'some', 'could', 'them', 'see', 'other', 'than',
    'then', 'now', 'look', 'only', 'come', 'its', 'over', 'think',
    'also', 'back', 'after', 'use', 'two', 'how', 'our', 'work',
    'well', 'way', 'even', 'new', 'want', 'because', 'any', 'these',
    'give', 'day', 'most', 'us', 'is', 'are', 'was', 'were', 'been',
  };

  final _uuid = const Uuid();

  /// Generates a list of chapters from transcript words.
  /// Guarantees:
  /// - Chapter 1 is anchored at 00:00 (Introduction).
  /// - Each subsequent chapter is spaced at least [minGapSeconds] apart.
  /// - Titles are clean and capitalized.
  List<VideoChapter> generateChapters({
    required List<WordSchema> words,
    double totalDuration = 0.0,
    double minGapSeconds = 30.0,
  }) {
    if (words.isEmpty) {
      if (totalDuration > 0) {
        return [
          VideoChapter(
            id: _uuid.v4(),
            startTime: 0.0,
            title: 'Introduction',
          ),
        ];
      }
      return [];
    }

    final effectiveDuration = totalDuration > 0
        ? totalDuration
        : (words.last.end ?? words.last.start ?? 0.0);

    final chapters = <VideoChapter>[
      VideoChapter(
        id: _uuid.v4(),
        startTime: 0.0,
        title: 'Introduction',
      ),
    ];

    double lastChapterTime = 0.0;

    // Build lowercase text stream with timestamps
    final fullTextLower =
        words.map((w) => (w.text ?? '').toLowerCase()).toList();

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final wordStart = word.start ?? 0.0;

      // Don't place chapters too close to the last chapter or too close to end
      if (wordStart - lastChapterTime < minGapSeconds) continue;
      if (effectiveDuration - wordStart < 15.0) continue;

      // 1. Check for explicit transition phrase match
      final window = fullTextLower.skip(i).take(6).join(' ');
      String? matchedTransition;
      for (final phrase in _transitionPhrases) {
        if (window.startsWith(phrase)) {
          matchedTransition = phrase;
          break;
        }
      }

      // 2. Check for substantial speaker pause (>= 1.5s) indicating section break
      bool isSubstantialPause = false;
      if (i > 0) {
        final prevEnd = words[i - 1].end ?? words[i - 1].start ?? 0.0;
        if (wordStart - prevEnd >= 1.5) {
          isSubstantialPause = true;
        }
      }

      if (matchedTransition != null || isSubstantialPause) {
        // Extract topic for the chapter title
        final followingWords = words.skip(i).take(20).toList();
        final title = _generateChapterTitle(
          followingWords,
          matchedTransition: matchedTransition,
        );

        chapters.add(
          VideoChapter(
            id: _uuid.v4(),
            startTime: wordStart,
            title: title,
          ),
        );
        lastChapterTime = wordStart;
      }
    }

    // If video is long (>= 120s) and fewer than 3 chapters were detected,
    // generate natural evenly-spaced chapters based on dominant section topics.
    if (effectiveDuration >= 120.0 && chapters.length < 3) {
      final desiredCount = math.max(3, (effectiveDuration / 120.0).ceil());
      final interval = effectiveDuration / desiredCount;

      chapters.clear();
      chapters.add(
        VideoChapter(
          id: _uuid.v4(),
          startTime: 0.0,
          title: 'Introduction',
        ),
      );

      for (int c = 1; c < desiredCount; c++) {
        final targetTime = c * interval;
        // Find closest word to target time
        final closestIdx = words.indexWhere(
            (w) => (w.start ?? 0.0) >= targetTime);
        if (closestIdx != -1) {
          final word = words[closestIdx];
          final startTime = word.start ?? targetTime;
          final following = words.skip(closestIdx).take(20).toList();
          final title = _generateChapterTitle(following);
          chapters.add(
            VideoChapter(
              id: _uuid.v4(),
              startTime: startTime,
              title: title,
            ),
          );
        }
      }
    }

    LoggerService.instance.info(
      'ChapterGeneratorService',
      'Generated ${chapters.length} chapters across ${effectiveDuration.toStringAsFixed(1)}s video',
    );

    return chapters;
  }

  static String _generateChapterTitle(
    List<WordSchema> words, {
    String? matchedTransition,
  }) {
    if (words.isEmpty) return 'Overview';

    // 1. If explicit transition like 'step one' or 'biggest mistake'
    if (matchedTransition != null) {
      if (matchedTransition.startsWith('step')) {
        return _toTitleCase(matchedTransition);
      }
      if (matchedTransition.contains('mistake')) {
        return 'The Biggest Mistake';
      }
      if (matchedTransition.contains('secret')) {
        return 'The Untold Secret';
      }
      if (matchedTransition.contains('conclusion') ||
          matchedTransition.contains('summary') ||
          matchedTransition.contains('thoughts')) {
        return 'Final Thoughts & Summary';
      }
    }

    // 2. Extract top informative keywords from following words
    final counts = <String, int>{};
    for (final w in words) {
      final raw = (w.text ?? '')
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '');
      if (raw.length > 2 && !_stopWords.contains(raw)) {
        counts[raw] = (counts[raw] ?? 0) + 1;
      }
    }

    if (counts.isNotEmpty) {
      final sorted = counts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topWord = sorted.first.key;
      final secondWord =
          sorted.length > 1 ? sorted[1].key : '';

      if (secondWord.isNotEmpty && sorted.first.value == sorted[1].value) {
        return _toTitleCase('$topWord and $secondWord');
      }
      return _toTitleCase('Understanding $topWord');
    }

    // Fallback: take first 3 clean words
    final cleanWords = words
        .map((w) => (w.text ?? '').replaceAll(RegExp(r'[^\w\s]'), ''))
        .where((t) => t.isNotEmpty)
        .take(3)
        .join(' ');

    return cleanWords.isNotEmpty
        ? _toTitleCase(cleanWords)
        : 'Key Topic';
  }

  static String _toTitleCase(String text) {
    if (text.isEmpty) return '';
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
