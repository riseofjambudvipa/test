import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/core/video/chapter_models.dart';
import 'package:capstudio/core/video/chapter_generator_service.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Chapter Models & Formatting Tests', () {
    test('VideoChapter.formattedTimestamp formats mm:ss and hh:mm:ss accurately', () {
      const c1 = VideoChapter(id: '1', startTime: 0.0, title: 'Intro');
      expect(c1.formattedTimestamp, equals('00:00'));

      const c2 = VideoChapter(id: '2', startTime: 75.0, title: 'Topic');
      expect(c2.formattedTimestamp, equals('01:15'));

      const c3 = VideoChapter(id: '3', startTime: 3665.0, title: 'Deep Dive');
      expect(c3.formattedTimestamp, equals('01:01:05'));
    });

    test('ChapterListUtils.formatForYouTube produces standard YouTube chapter list', () {
      final chapters = [
        const VideoChapter(id: '1', startTime: 0.0, title: 'Introduction'),
        const VideoChapter(id: '2', startTime: 90.0, title: 'The Problem'),
        const VideoChapter(id: '3', startTime: 210.0, title: 'The Solution'),
      ];

      final ytText = ChapterListUtils.formatForYouTube(chapters);
      expect(
        ytText,
        equals('00:00 Introduction\n01:30 The Problem\n03:30 The Solution'),
      );

      final ytDashText = ChapterListUtils.formatForYouTube(chapters, useDash: true);
      expect(
        ytDashText,
        equals('00:00 - Introduction\n01:30 - The Problem\n03:30 - The Solution'),
      );
    });

    test('ChapterListUtils.isValidForYouTube validates official YouTube criteria', () {
      // Valid list
      final validChapters = [
        const VideoChapter(id: '1', startTime: 0.0, title: 'Intro'),
        const VideoChapter(id: '2', startTime: 25.0, title: 'Part 1'),
        const VideoChapter(id: '3', startTime: 50.0, title: 'Part 2'),
      ];
      expect(ChapterListUtils.isValidForYouTube(validChapters), isTrue);

      // Invalid: Fewer than 3 chapters
      expect(
        ChapterListUtils.isValidForYouTube(validChapters.take(2).toList()),
        isFalse,
      );

      // Invalid: First does not start at 00:00
      final nonZeroStart = [
        const VideoChapter(id: '1', startTime: 5.0, title: 'Intro'),
        const VideoChapter(id: '2', startTime: 25.0, title: 'Part 1'),
        const VideoChapter(id: '3', startTime: 50.0, title: 'Part 2'),
      ];
      expect(ChapterListUtils.isValidForYouTube(nonZeroStart), isFalse);

      // Invalid: Chapters too close (< 10 seconds)
      final tooClose = [
        const VideoChapter(id: '1', startTime: 0.0, title: 'Intro'),
        const VideoChapter(id: '2', startTime: 5.0, title: 'Part 1'),
        const VideoChapter(id: '3', startTime: 50.0, title: 'Part 2'),
      ];
      expect(ChapterListUtils.isValidForYouTube(tooClose), isFalse);
    });
  });

  group('ChapterGeneratorService Tests', () {
    test('generateChapters creates first chapter at 00:00 even for empty transcript', () {
      final chapters = ChapterGeneratorService.instance.generateChapters(
        words: [],
        totalDuration: 120.0,
      );
      expect(chapters.length, equals(1));
      expect(chapters.first.startTime, equals(0.0));
      expect(chapters.first.title, equals('Introduction'));
    });

    test('generateChapters detects transition phrases and creates spaced chapters', () {
      final words = <WordSchema>[
        // Intro words
        WordSchema()..text = 'Welcome'..start = 0.0..end = 0.5,
        WordSchema()..text = 'everyone'..start = 0.5..end = 1.0,

        // Transition at 40s
        WordSchema()..text = 'moving'..start = 40.0..end = 40.4,
        WordSchema()..text = 'on'..start = 40.4..end = 40.7,
        WordSchema()..text = 'to'..start = 40.7..end = 41.0,
        WordSchema()..text = 'python'..start = 41.0..end = 41.5,
        WordSchema()..text = 'programming'..start = 41.5..end = 42.0,

        // Transition at 90s
        WordSchema()..text = 'in'..start = 90.0..end = 90.3,
        WordSchema()..text = 'conclusion'..start = 90.3..end = 90.9,
        WordSchema()..text = 'thank'..start = 91.0..end = 91.4,
        WordSchema()..text = 'you.'..start = 91.4..end = 92.0,
      ];

      final chapters = ChapterGeneratorService.instance.generateChapters(
        words: words,
        totalDuration: 120.0,
        minGapSeconds: 20.0,
      );

      expect(chapters.length, greaterThanOrEqualTo(3));
      expect(chapters[0].startTime, equals(0.0));
      expect(chapters[0].title, equals('Introduction'));

      expect(chapters[1].startTime, equals(40.0));
      expect(chapters[1].title, contains('Python'));

      expect(chapters[2].startTime, equals(90.0));
      expect(chapters[2].title, contains('Final Thoughts'));
    });

    test('generateChapters creates distributed chapters for long videos with minimal transitions', () {
      // 5-minute video with words every 10s
      final words = <WordSchema>[];
      for (int i = 0; i < 30; i++) {
        final t = i * 10.0;
        words.add(WordSchema()
          ..text = (i % 5 == 0) ? 'architecture' : 'word$i'
          ..start = t
          ..end = t + 2.0);
      }

      final chapters = ChapterGeneratorService.instance.generateChapters(
        words: words,
        totalDuration: 300.0, // 5 minutes
      );

      expect(chapters.length, greaterThanOrEqualTo(3));
      expect(chapters.first.startTime, equals(0.0));
      expect(ChapterListUtils.isValidForYouTube(chapters), isTrue);
    });
  });
}
