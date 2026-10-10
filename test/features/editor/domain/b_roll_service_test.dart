import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/features/editor/domain/b_roll_service.dart';

void main() {
  group('BRollSuggestionService Tests', () {
    test('suggestBRoll detects visual keywords and creates well-spaced cues', () {
      final words = <WordSchema>[
        WordSchema()..wordId = '1'..text = 'Here'..start = 0.0..end = 0.4,
        WordSchema()..wordId = '2'..text = 'is'..start = 0.4..end = 0.6,
        WordSchema()..wordId = '3'..text = 'how'..start = 0.6..end = 0.8,
        WordSchema()..wordId = '4'..text = 'we'..start = 0.8..end = 1.0,
        WordSchema()..wordId = '5'..text = 'make'..start = 1.0..end = 1.3,
        WordSchema()..wordId = '6'..text = 'money'..start = 1.3..end = 1.7, // Visual cue 1: money
        WordSchema()..wordId = '7'..text = 'with'..start = 1.7..end = 2.0,
        WordSchema()..wordId = '8'..text = 'coding'..start = 2.0..end = 2.4, // Too close (< 4s), should be skipped

        // Visual cue 2 at 10.0s
        WordSchema()..wordId = '9'..text = 'Our'..start = 9.5..end = 9.8,
        WordSchema()..wordId = '10'..text = 'rocket'..start = 10.0..end = 10.5, // Visual cue 2: rocket
        WordSchema()..wordId = '11'..text = 'growth'..start = 10.5..end = 11.0,
      ];

      final cues = BRollSuggestionService.instance.suggestBRoll(words, minGapBetweenCues: 4.0);

      expect(cues.length, equals(2));

      // Cue 1
      expect(cues[0].keyword, equals('money'));
      expect(cues[0].category, equals('Finance'));
      expect(cues[0].startTime, equals(1.3));
      expect(cues[0].pexelsUrl, contains('pexels.com/search/videos'));

      // Cue 2
      expect(cues[1].keyword, equals('rocket'));
      expect(cues[1].category, equals('Growth'));
      expect(cues[1].startTime, equals(10.0));
      expect(cues[1].pixabayUrl, contains('pixabay.com/videos/search'));
    });

    test('suggestBRoll handles empty input gracefully', () {
      final cues = BRollSuggestionService.instance.suggestBRoll([]);
      expect(cues, isEmpty);
    });

    test('suggestBRoll detects multilingual keywords in Spanish, French, German, Italian, Portuguese, and Hindi', () {
      final words = <WordSchema>[
        // Spanish with punctuation & accent
        WordSchema()..wordId = 's1'..text = '¡Tenemos'..start = 1.0..end = 1.4,
        WordSchema()..wordId = 's2'..text = 'éxito!'..start = 1.4..end = 1.8, // Spanish: éxito (accented) -> Achievement
        // French
        WordSchema()..wordId = 'f1'..text = 'Notre'..start = 11.0..end = 11.3,
        WordSchema()..wordId = 'f2'..text = 'voyage'..start = 11.3..end = 11.8, // French: voyage -> Travel
        // German
        WordSchema()..wordId = 'g1'..text = 'Grosser'..start = 21.0..end = 21.4,
        WordSchema()..wordId = 'g2'..text = 'Geld'..start = 21.4..end = 21.8, // German: geld -> Finance
        // Portuguese
        WordSchema()..wordId = 'p1'..text = 'Mais'..start = 31.0..end = 31.3,
        WordSchema()..wordId = 'p2'..text = 'sucesso'..start = 31.3..end = 31.8, // Portuguese: sucesso -> Achievement
        // Italian
        WordSchema()..wordId = 'i1'..text = 'Buon'..start = 41.0..end = 41.3,
        WordSchema()..wordId = 'i2'..text = 'viaggio'..start = 41.3..end = 41.8, // Italian: viaggio -> Travel
        // Hindi
        WordSchema()..wordId = 'h1'..text = 'Bahut'..start = 51.0..end = 51.3,
        WordSchema()..wordId = 'h2'..text = 'paise'..start = 51.3..end = 51.8, // Hindi: paise -> Finance
      ];

      final cues = BRollSuggestionService.instance.suggestBRoll(words, minGapBetweenCues: 4.0);

      expect(cues.length, equals(6));

      // Spanish cue: éxito
      expect(cues[0].category, equals('Achievement'));
      expect(cues[0].searchTopic, contains('podium'));

      // French cue: voyage
      expect(cues[1].category, equals('Travel'));
      expect(cues[1].searchTopic, contains('airplane travel'));

      // German cue: geld
      expect(cues[2].category, equals('Finance'));
      expect(cues[2].searchTopic, contains('cash money'));

      // Portuguese cue: sucesso
      expect(cues[3].category, equals('Achievement'));

      // Italian cue: viaggio
      expect(cues[4].category, equals('Travel'));

      // Hindi cue: paise
      expect(cues[5].category, equals('Finance'));
    });
  });
}
