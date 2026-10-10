import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/features/editor/domain/chapter_marker_service.dart';

void main() {
  group('ChapterMarkerService Tests', () {
    test('generateChapters creates valid YouTube chapters starting at 00:00', () {
      final words = <WordSchema>[
        WordSchema()..wordId = '1'..text = 'Welcome'..start = 0.0..end = 0.5,
        WordSchema()..wordId = '2'..text = 'to'..start = 0.5..end = 0.8,
        WordSchema()..wordId = '3'..text = 'this'..start = 0.8..end = 1.1,
        WordSchema()..wordId = '4'..text = 'guide.'..start = 1.1..end = 1.6,

        // Transition 1 at 35s
        WordSchema()..wordId = '5'..text = 'First'..start = 35.0..end = 35.4,
        WordSchema()..wordId = '6'..text = 'we'..start = 35.4..end = 35.7,
        WordSchema()..wordId = '7'..text = 'configure'..start = 35.7..end = 36.3,
        WordSchema()..wordId = '8'..text = 'settings.'..start = 36.3..end = 37.0,

        // Transition 2 at 75s
        WordSchema()..wordId = '9'..text = 'Next'..start = 75.0..end = 75.4,
        WordSchema()..wordId = '10'..text = 'let\'s'..start = 75.4..end = 75.8,
        WordSchema()..wordId = '11'..text = 'export'..start = 75.8..end = 76.2,
        WordSchema()..wordId = '12'..text = 'video.'..start = 76.2..end = 76.8,
      ];

      final chapters = ChapterMarkerService.instance.generateChapters(
        words,
        120.0,
        minChapterDuration: 30.0,
      );

      expect(chapters, isNotEmpty);
      expect(chapters.first.startTime, equals(0.0));
      expect(chapters.first.timestamp, equals('00:00'));
      expect(chapters.first.title, contains('Intro'));

      expect(chapters.length, greaterThanOrEqualTo(3));
      expect(chapters[1].startTime, closeTo(35.0, 1.0));
      expect(chapters[1].timestamp, equals('00:35'));

      expect(chapters[2].startTime, closeTo(75.0, 1.0));
      expect(chapters[2].timestamp, equals('01:15'));

      // Test YouTube format output
      final ytText = ChapterMarker.formatForYouTube(chapters);
      expect(ytText, contains('00:00 Intro'));
      expect(ytText, contains('00:35'));
      expect(ytText, contains('01:15'));
    });

    test('formatTime formats seconds, minutes and hours properly', () {
      expect(ChapterMarker.formatTime(0.0), equals('00:00'));
      expect(ChapterMarker.formatTime(45.0), equals('00:45'));
      expect(ChapterMarker.formatTime(125.0), equals('02:05'));
      expect(ChapterMarker.formatTime(3665.0), equals('1:01:05'));
    });

    test('generateChapters handles empty words gracefully', () {
      final chapters = ChapterMarkerService.instance.generateChapters([], 60.0);
      expect(chapters, isEmpty);
    });
  });
}
