import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/features/editor/domain/caption_engine.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import '../../../helpers/project_fixture.dart';

void main() {
  group('CaptionEngine Boundary & Edge Cases', () {
    test('buildChunks handles empty inputs and only-hidden/punctuation inputs safely', () {
      // 1. Empty words list
      expect(CaptionEngine.buildChunks([], null, 0.0, 0.0, 4, 30), isEmpty);

      // 2. Only hidden words
      final onlyHidden = [
        makeWord(wordId: 'w1', text: 'hello', hidden: true),
        makeWord(wordId: 'w2', text: 'world', hidden: true),
      ];
      expect(CaptionEngine.buildChunks(onlyHidden, null, 0.0, 0.0, 4, 30), isEmpty);

      // 3. Only punctuation words
      final onlyPunct = [
        makeWord(wordId: 'w1', text: ',', type: 'punctuation'),
        makeWord(wordId: 'w2', text: '.', type: 'punctuation'),
      ];
      expect(CaptionEngine.buildChunks(onlyPunct, null, 0.0, 0.0, 4, 30), isEmpty);
    });

    test('buildChunks handles consecutive splitBefore = true correctly without producing empty chunks', () {
      final words = [
        makeWord(wordId: 'w1', text: 'One', start: 0.0, end: 0.5),
        makeWord(wordId: 'w2', text: 'Two', start: 0.6, end: 1.1, splitBefore: true),
        makeWord(wordId: 'w3', text: 'Three', start: 1.2, end: 1.7, splitBefore: true),
      ];

      final chunks = CaptionEngine.buildChunks(words, null, 0.0, 0.0, 4, 30);
      
      expect(chunks.length, 3);
      expect(chunks[0].words.map((w) => w.text), ['One']);
      expect(chunks[1].words.map((w) => w.text), ['Two']);
      expect(chunks[2].words.map((w) => w.text), ['Three']);
    });

    test('buildChunks handles small chunkSize constraint = 1 correctly', () {
      final words = [
        makeWord(wordId: 'w1', text: 'Hello', start: 0.0, end: 0.5),
        makeWord(wordId: 'w2', text: 'big', start: 0.6, end: 0.9),
        makeWord(wordId: 'w3', text: 'world', start: 1.0, end: 1.5),
      ];

      // chunkSize = 1
      final chunks = CaptionEngine.buildChunks(words, null, 0.0, 0.0, 1, 30);
      
      expect(chunks.length, 3);
      for (final chunk in chunks) {
        expect(chunk.words.length, 1);
      }
      expect(chunks[0].words.first.text, 'Hello');
      expect(chunks[1].words.first.text, 'big');
      expect(chunks[2].words.first.text, 'world');
    });

    test('buildChunks filters correctly using trimStart and trimEnd boundaries', () {
      final words = [
        makeWord(wordId: 'w1', text: 'Too', start: 0.0, end: 0.5),
        makeWord(wordId: 'w2', text: 'Early', start: 0.6, end: 1.0),
        makeWord(wordId: 'w3', text: 'In', start: 1.1, end: 1.5),
        makeWord(wordId: 'w4', text: 'Time', start: 1.6, end: 2.1),
        makeWord(wordId: 'w5', text: 'Too', start: 2.2, end: 2.7),
        makeWord(wordId: 'w6', text: 'Late', start: 2.8, end: 3.3),
      ];

      // Trim boundaries: trimStart = 1.1, trimEnd = 2.5
      // Expected active: 'In' (1.1 to 1.5), 'Time' (1.6 to 2.1)
      final chunks = CaptionEngine.buildChunks(words, null, 1.1, 2.5, 4, 30);
      
      expect(chunks.length, 1);
      expect(chunks[0].words.length, 2);
      expect(chunks[0].words[0].text, 'In');
      expect(chunks[0].words[1].text, 'Time');
    });

    test('buildChunks filters correctly using segments list', () {
      final words = [
        makeWord(wordId: 'w1', text: 'First', start: 0.5, end: 1.0), // Mid = 0.75
        makeWord(wordId: 'w2', text: 'Second', start: 1.5, end: 2.0), // Mid = 1.75
        makeWord(wordId: 'w3', text: 'Third', start: 2.5, end: 3.0), // Mid = 2.75
        makeWord(wordId: 'w4', text: 'Fourth', start: 3.5, end: 4.0), // Mid = 3.75
      ];

      final segments = [
        VideoSegmentSchema()..start = 0.0..end = 1.2..isDeleted = false, // contains First
        VideoSegmentSchema()..start = 1.3..end = 2.2..isDeleted = true,  // Second (deleted)
        VideoSegmentSchema()..start = 2.3..end = 3.2..isDeleted = false, // contains Third
        // Fourth is not covered by any segment (so it will be excluded)
      ];

      final chunks = CaptionEngine.buildChunks(words, segments, 0.0, 0.0, 4, 30);

      // Since First (mid 0.75) and Third (mid 2.75) are active, they are separated by Second (deleted, mid 1.75),
      // wait, they have a gap: 2.5 - 1.0 = 1.5 seconds.
      // Gap > 400ms triggers a split in CaptionEngine!
      // So they should split into 2 chunks.
      expect(chunks.length, 2);
      expect(chunks[0].words.length, 1);
      expect(chunks[0].words.first.text, 'First');
      expect(chunks[1].words.length, 1);
      expect(chunks[1].words.first.text, 'Third');
    });

    test('getActiveChunk binary search returns correct chunk', () {
      final chunks = [
        const Chunk(index: 0, startTime: 0.0, endTime: 1.0, words: []),
        const Chunk(index: 1, startTime: 1.5, endTime: 2.5, words: []),
        const Chunk(index: 2, startTime: 3.0, endTime: 4.5, words: []),
      ];

      expect(CaptionEngine.getActiveChunk(chunks, 0.5), chunks[0]);
      expect(CaptionEngine.getActiveChunk(chunks, 1.0), chunks[0]);
      expect(CaptionEngine.getActiveChunk(chunks, 1.2), isNull); // gap
      expect(CaptionEngine.getActiveChunk(chunks, 2.0), chunks[1]);
      expect(CaptionEngine.getActiveChunk(chunks, 4.0), chunks[2]);
      expect(CaptionEngine.getActiveChunk(chunks, 5.0), isNull); // out of bounds
    });
  });
}
