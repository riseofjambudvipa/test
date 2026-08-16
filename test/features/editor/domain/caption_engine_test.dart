import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/features/editor/domain/caption_engine.dart';

void main() {
  group('CaptionEngine Tests', () {
    late List<WordSchema> mockWords;

    setUp(() {
      mockWords = [
        WordSchema()
          ..wordId = '1'
          ..text = 'Hello'
          ..start = 0.0
          ..end = 0.5
          ..type = 'word',
        WordSchema()
          ..wordId = '2'
          ..text = 'world'
          ..start = 0.6
          ..end = 1.0
          ..type = 'word',
        WordSchema()
          ..wordId = '3'
          ..text = 'this'
          ..start = 1.1
          ..end = 1.5
          ..type = 'word',
        WordSchema()
          ..wordId = '4'
          ..text = 'is'
          ..start = 1.6
          ..end = 2.0
          ..type = 'word',
        WordSchema()
          ..wordId = '5'
          ..text = 'CapStudio'
          ..start = 2.1
          ..end = 3.0
          ..type = 'word',
      ];
    });

    test('should build chunks based on chunkSize constraint', () {
      final chunks = CaptionEngine.buildChunks(mockWords, null, 0.0, 0.0, 2, 100);

      expect(chunks.length, 3);
      
      expect(chunks[0].words.length, 2);
      expect(chunks[0].words[0].text, 'Hello');
      expect(chunks[0].words[1].text, 'world');
      expect(chunks[0].startTime, 0.0);
      expect(chunks[0].endTime, 1.0);

      expect(chunks[1].words.length, 2);
      expect(chunks[1].words[0].text, 'this');
      expect(chunks[1].words[1].text, 'is');
      expect(chunks[1].startTime, 1.1);
      expect(chunks[1].endTime, 2.0);

      expect(chunks[2].words.length, 1);
      expect(chunks[2].words[0].text, 'CapStudio');
      expect(chunks[2].startTime, 2.1);
      expect(chunks[2].endTime, 3.0);
    });

    test('should build chunks based on chunkLineMaxLength constraint', () {
      final chunks = CaptionEngine.buildChunks(mockWords, null, 0.0, 0.0, 5, 12);

      expect(chunks.length, 3);
      expect(chunks[0].words.length, 2);
      expect(chunks[0].words[0].text, 'Hello');
      expect(chunks[0].words[1].text, 'world');
      
      expect(chunks[1].words.length, 2);
      expect(chunks[1].words[0].text, 'this');
      expect(chunks[1].words[1].text, 'is');

      expect(chunks[2].words.length, 1);
      expect(chunks[2].words[0].text, 'CapStudio');
    });

    test('should force split when splitBefore is true', () {
      mockWords[2].splitBefore = true;

      final chunks = CaptionEngine.buildChunks(mockWords, null, 0.0, 0.0, 5, 100);

      expect(chunks.length, 2);
      expect(chunks[0].words.length, 2);
      expect(chunks[0].words[0].text, 'Hello');
      expect(chunks[0].words[1].text, 'world');
      
      expect(chunks[1].words.length, 3);
      expect(chunks[1].words[0].text, 'this');
      expect(chunks[1].words[1].text, 'is');
      expect(chunks[1].words[2].text, 'CapStudio');
    });

    test('should correctly find active chunk using binary search', () {
      final chunks = CaptionEngine.buildChunks(mockWords, null, 0.0, 0.0, 2, 100);

      final chunk1 = CaptionEngine.getActiveChunk(chunks, 0.8);
      expect(chunk1, isNotNull);
      expect(chunk1!.index, 0);

      final chunk2 = CaptionEngine.getActiveChunk(chunks, 1.8);
      expect(chunk2, isNotNull);
      expect(chunk2!.index, 1);

      final chunk3 = CaptionEngine.getActiveChunk(chunks, 1.05);
      expect(chunk3, isNull);
    });

    test('should merge punctuation-type words into the preceding word and filter out hidden words', () {
      mockWords[1].hidden = true; // 'world'
      mockWords[3].type = 'punctuation'; // 'is'

      // Adjust timings to prevent natural pause gap splits (>400ms)
      mockWords[2].start = 0.6; // 'this'
      mockWords[2].end = 1.0;
      mockWords[4].start = 1.1; // 'CapStudio'
      mockWords[4].end = 1.5;

      final chunks = CaptionEngine.buildChunks(mockWords, null, 0.0, 0.0, 5, 100);

      // Remaining words: 'Hello', 'thisis' (with punctuation merged), 'CapStudio'
      expect(chunks.length, 1);
      expect(chunks[0].words.length, 3);
      expect(chunks[0].words[0].text, 'Hello');
      expect(chunks[0].words[1].text, 'thisis');
      expect(chunks[0].words[2].text, 'CapStudio');
    });

    test('should filter out words outside trimStart and trimEnd boundaries', () {
      // trimStart = 0.55 (filters out 'Hello' at 0.0-0.5)
      // trimEnd = 2.05 (filters out 'CapStudio' at 2.1-3.0)
      final chunks = CaptionEngine.buildChunks(mockWords, null, 0.55, 2.05, 5, 100);

      expect(chunks.length, 1);
      expect(chunks[0].words.length, 3);
      expect(chunks[0].words[0].text, 'world');
      expect(chunks[0].words[1].text, 'this');
      expect(chunks[0].words[2].text, 'is');
    });

    test('should force split when there is a natural pause gap greater than 400ms', () {
      // 'world' ends at 1.0. If 'this' starts at 1.45 (gap = 450ms)
      mockWords[2].start = 1.45;
      mockWords[2].end = 1.85;

      final chunks = CaptionEngine.buildChunks(mockWords, null, 0.0, 0.0, 5, 100);

      // Should split between 'world' and 'this'
      expect(chunks.length, 2);
      expect(chunks[0].words.length, 2);
      expect(chunks[0].words[0].text, 'Hello');
      expect(chunks[0].words[1].text, 'world');

      expect(chunks[1].words.length, 3);
      expect(chunks[1].words[0].text, 'this');
    });

    test('should force split when previous word ends with sentence-ending punctuation', () {
      mockWords[1].text = 'world!'; // Sentence ending

      final chunks = CaptionEngine.buildChunks(mockWords, null, 0.0, 0.0, 5, 100);

      expect(chunks.length, 2);
      expect(chunks[0].words.length, 2);
      expect(chunks[0].words[0].text, 'Hello');
      expect(chunks[0].words[1].text, 'world!');

      expect(chunks[1].words.length, 3);
      expect(chunks[1].words[0].text, 'this');
    });

    test('should handle edge cases: empty input, single word, null safety', () {
      expect(CaptionEngine.buildChunks([], null, 0.0, 0.0, 5, 100), isEmpty);

      final singleWord = [
        WordSchema()
          ..wordId = '1'
          ..text = 'Hello'
          ..start = null
          ..end = null
          ..type = 'word'
      ];
      final chunks = CaptionEngine.buildChunks(singleWord, null, 0.0, 0.0, 5, 100);
      expect(chunks.length, 1);
      expect(chunks[0].words.first.text, 'Hello');
      expect(chunks[0].startTime, 0.0);
      expect(chunks[0].endTime, 0.1); // Enforced minimum duration of 100ms
    });

    test('should ensure minimum chunk duration for zero duration words', () {
      final zeroDurationWords = [
        WordSchema()
          ..wordId = '1'
          ..text = 'Zero'
          ..start = 1.0
          ..end = 1.0
          ..type = 'word'
      ];
      final chunks = CaptionEngine.buildChunks(zeroDurationWords, null, 0.0, 0.0, 5, 100);
      expect(chunks.length, 1);
      expect(chunks[0].startTime, 1.0);
      expect(chunks[0].endTime, 1.1); // Enforced minimum duration of 100ms
    });

    test('should filter out words inside deleted segments', () {
      final segments = [
        VideoSegmentSchema()
          ..start = 0.0
          ..end = 1.0
          ..isDeleted = false,
        VideoSegmentSchema()
          ..start = 1.0
          ..end = 2.0
          ..isDeleted = true,
        VideoSegmentSchema()
          ..start = 2.0
          ..end = 3.0
          ..isDeleted = false,
      ];
      final chunks = CaptionEngine.buildChunks(mockWords, segments, 0.0, 0.0, 5, 100);

      // Remaining words: 'Hello' (0.0-0.5), 'world' (0.6-1.0), and 'CapStudio' (2.1-3.0)
      // 'this' (1.1-1.5) and 'is' (1.6-2.0) fall inside the deleted segment [1.0 - 2.0]
      expect(chunks.length, 2);
      expect(chunks[0].words.length, 2);
      expect(chunks[0].words[0].text, 'Hello');
      expect(chunks[0].words[1].text, 'world');
      
      expect(chunks[1].words.length, 1);
      expect(chunks[1].words[0].text, 'CapStudio');
    });
  });
}
