import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/core/video/silence_detector.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SilenceDetector.detectSilenceFromWords', () {
    late SilenceDetector detector;

    setUp(() {
      detector = SilenceDetector();
    });

    test('returns empty list for empty words', () {
      final silences = detector.detectSilenceFromWords([]);
      expect(silences, isEmpty);
    });

    test('detects leading silence when speech starts after threshold', () {
      final words = [
        WordSchema()..text = 'Hello'..start = 1.2..end = 1.8,
        WordSchema()..text = 'World'..start = 1.9..end = 2.4,
      ];

      final silences = detector.detectSilenceFromWords(
        words,
        totalDuration: 2.5,
        durationThreshold: 0.4,
      );

      expect(silences.length, 1);
      expect(silences.first.start, 0.0);
      expect(silences.first.end, 1.2);
      expect(silences.first.duration, 1.2);
    });

    test('detects gaps between words exceeding threshold', () {
      final words = [
        WordSchema()..text = 'First'..start = 0.1..end = 0.5,
        WordSchema()..text = 'Second'..start = 1.5..end = 2.0, // 1.0s gap
      ];

      final silences = detector.detectSilenceFromWords(
        words,
        totalDuration: 2.1,
        durationThreshold: 0.4,
      );

      // 0.1s is < 0.4s (no leading silence)
      // 1.5 - 0.5 = 1.0s gap (silence)
      expect(silences.length, 1);
      expect(silences.first.start, 0.5);
      expect(silences.first.end, 1.5);
      expect(silences.first.duration, closeTo(1.0, 0.001));
    });

    test('detects trailing silence after speech ends', () {
      final words = [
        WordSchema()..text = 'Done'..start = 0.1..end = 1.0,
      ];

      final silences = detector.detectSilenceFromWords(
        words,
        totalDuration: 5.0,
        durationThreshold: 0.4,
      );

      expect(silences.length, 1);
      expect(silences.first.start, 1.0);
      expect(silences.first.end, 5.0);
      expect(silences.first.duration, closeTo(4.0, 0.001));
    });

    test('filters out hidden words when calculating silence', () {
      final words = [
        WordSchema()..text = 'Word1'..start = 0.0..end = 1.0,
        WordSchema()..text = 'Hidden'..start = 1.2..end = 1.8..hidden = true,
        WordSchema()..text = 'Word2'..start = 3.0..end = 4.0,
      ];

      final silences = detector.detectSilenceFromWords(
        words,
        totalDuration: 4.0,
        durationThreshold: 0.4,
      );

      // Since Hidden is ignored, gap is 3.0 - 1.0 = 2.0s
      expect(silences.length, 1);
      expect(silences.first.start, 1.0);
      expect(silences.first.end, 3.0);
      expect(silences.first.duration, closeTo(2.0, 0.001));
    });
  });
}
