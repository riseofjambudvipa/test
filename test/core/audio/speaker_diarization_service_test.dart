import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/core/audio/speaker_diarization_service.dart';
import 'package:capstudio/features/editor/domain/caption_engine.dart';

void main() {
  group('SpeakerDiarizationService Tests', () {
    test('detectSpeakers detects turns on questions and long pauses', () {
      final words = [
        WordSchema()
          ..wordId = 'w1'
          ..text = 'What'
          ..start = 0.0
          ..end = 0.4,
        WordSchema()
          ..wordId = 'w2'
          ..text = 'happened?'
          ..start = 0.5
          ..end = 1.0,
        // 0.5s pause after question
        WordSchema()
          ..wordId = 'w3'
          ..text = 'Well'
          ..start = 1.5
          ..end = 1.8,
        WordSchema()
          ..wordId = 'w4'
          ..text = 'we'
          ..start = 1.9
          ..end = 2.1,
        WordSchema()
          ..wordId = 'w5'
          ..text = 'won.'
          ..start = 2.2
          ..end = 2.5,
        // 0.8s pause -> back to Speaker 1
        WordSchema()
          ..wordId = 'w6'
          ..text = 'That'
          ..start = 3.3
          ..end = 3.6,
        WordSchema()
          ..wordId = 'w7'
          ..text = 'is'
          ..start = 3.7
          ..end = 3.9,
        WordSchema()
          ..wordId = 'w8'
          ..text = 'amazing!'
          ..start = 4.0
          ..end = 4.5,
      ];

      final tagged = SpeakerDiarizationService.instance.detectSpeakers(words, speakerCount: 2);
      expect(tagged.length, equals(8));
      expect(tagged[0].speaker, equals('Speaker 1'));
      expect(tagged[1].speaker, equals('Speaker 1'));
      expect(tagged[2].speaker, equals('Speaker 2'));
      expect(tagged[3].speaker, equals('Speaker 2'));
      expect(tagged[4].speaker, equals('Speaker 2'));
      expect(tagged[5].speaker, equals('Speaker 1'));
      expect(tagged[6].speaker, equals('Speaker 1'));
      expect(tagged[7].speaker, equals('Speaker 1'));
    });

    test('renameSpeaker replaces speaker names correctly', () {
      final words = [
        WordSchema()
          ..wordId = 'w1'
          ..text = 'Hello'
          ..speaker = 'Speaker 1',
        WordSchema()
          ..wordId = 'w2'
          ..text = 'Hi'
          ..speaker = 'Speaker 2',
      ];

      final renamed = SpeakerDiarizationService.instance.renameSpeaker(words, 'Speaker 1', 'Host Alex');
      expect(renamed[0].speaker, equals('Host Alex'));
      expect(renamed[1].speaker, equals('Speaker 2'));
    });

    test('calculateStats produces accurate speaking time and word counts', () {
      final words = [
        WordSchema()
          ..wordId = 'w1'
          ..start = 0.0
          ..end = 1.0
          ..speaker = 'Host',
        WordSchema()
          ..wordId = 'w2'
          ..start = 1.0
          ..end = 2.0
          ..speaker = 'Host',
        WordSchema()
          ..wordId = 'w3'
          ..start = 2.0
          ..end = 3.0
          ..speaker = 'Guest',
      ];

      final stats = SpeakerDiarizationService.instance.calculateStats(words);
      expect(stats.length, equals(2));
      final hostStat = stats.firstWhere((s) => s.speaker == 'Host');
      final guestStat = stats.firstWhere((s) => s.speaker == 'Guest');

      expect(hostStat.wordCount, equals(2));
      expect(guestStat.wordCount, equals(1));
      expect(hostStat.talkTimeSeconds, equals(2.0));
      expect(guestStat.talkTimeSeconds, equals(1.0));
      expect(hostStat.percentage, closeTo(66.6, 0.5));
      expect(guestStat.percentage, closeTo(33.3, 0.5));
    });

    test('CaptionEngine preserves speaker tag on Chunk and flushes on speaker boundary', () {
      final words = [
        WordSchema()
          ..wordId = 'w1'
          ..text = 'Hello'
          ..start = 0.0
          ..end = 0.5
          ..speaker = 'Host',
        WordSchema()
          ..wordId = 'w2'
          ..text = 'there'
          ..start = 0.5
          ..end = 1.0
          ..speaker = 'Host',
        WordSchema()
          ..wordId = 'w3'
          ..text = 'General'
          ..start = 1.1
          ..end = 1.5
          ..speaker = 'Kenobi',
      ];

      final chunks = CaptionEngine.buildChunks(words, null, 0, 0, 5, 40);
      expect(chunks.length, equals(2));
      expect(chunks[0].speaker, equals('Host'));
      expect(chunks[0].words.length, equals(2));
      expect(chunks[1].speaker, equals('Kenobi'));
      expect(chunks[1].words.length, equals(1));
    });

    test('getSpeakerIntervals groups contiguous words into intervals', () {
      final words = [
        WordSchema()..text = 'Welcome'..start = 0.0..end = 0.5..speaker = 'Host',
        WordSchema()..text = 'back'..start = 0.5..end = 1.0..speaker = 'Host',
        WordSchema()..text = 'Thank'..start = 1.5..end = 1.9..speaker = 'Guest',
        WordSchema()..text = 'you'..start = 1.9..end = 2.4..speaker = 'Guest',
        WordSchema()..text = 'So'..start = 3.0..end = 3.5..speaker = 'Host',
      ];

      final intervals = SpeakerDiarizationService.instance.getSpeakerIntervals(words);
      expect(intervals.length, equals(3));
      expect(intervals[0].speaker, equals('Host'));
      expect(intervals[0].start, equals(0.0));
      expect(intervals[0].end, equals(1.0));
      expect(intervals[0].duration, equals(1.0));

      expect(intervals[1].speaker, equals('Guest'));
      expect(intervals[1].start, equals(1.5));
      expect(intervals[1].end, equals(2.4));

      expect(intervals[2].speaker, equals('Host'));
      expect(intervals[2].start, equals(3.0));
      expect(intervals[2].end, equals(3.5));
    });

    test('computeSpeakerFocalPoints handles 1, 2, and 3 speakers properly', () {
      final one = SpeakerDiarizationService.instance.computeSpeakerFocalPoints(['Host']);
      expect(one['Host'], equals(0.50));

      final two = SpeakerDiarizationService.instance.computeSpeakerFocalPoints(['Host', 'Guest']);
      expect(two['Host'], equals(0.20));
      expect(two['Guest'], equals(0.80));

      final three = SpeakerDiarizationService.instance.computeSpeakerFocalPoints(['Host', 'Guest A', 'Guest B']);
      expect(three['Host'], equals(0.18));
      expect(three['Guest A'], equals(0.50));
      expect(three['Guest B'], equals(0.82));
    });

    test('buildSpeakerCropExpression generates valid FFmpeg crop timeline expression', () {
      const intervals = [
        SpeakerInterval(speaker: 'Host', speakerIndex: 0, start: 0.0, end: 2.5),
        SpeakerInterval(speaker: 'Guest', speakerIndex: 1, start: 2.5, end: 6.0),
      ];

      final expr = SpeakerDiarizationService.instance.buildSpeakerCropExpression(
        intervals: intervals,
      );

      expect(expr, contains('between(t,0.00,2.50)'));
      expect(expr, contains('(in_w-out_w)*0.2'));
      expect(expr, contains('between(t,2.50,6.00)'));
      expect(expr, contains('(in_w-out_w)*0.8'));
    });
  });
}
