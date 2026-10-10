import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/features/editor/domain/auto_enhancement_service.dart';

void main() {
  group('AutoEnhancementService Tests', () {
    late AutoEnhancementService service;

    setUp(() {
      service = AutoEnhancementService.instance;
    });

    test('should auto-assign magic emojis to matching keywords with spacing', () {
      final words = [
        WordSchema()..text = 'This',
        WordSchema()..text = 'is',
        WordSchema()..text = 'fire', // should match 🔥
        WordSchema()..text = 'and',
        WordSchema()..text = 'hot',  // skipped due to spacing (within 4 words)
        WordSchema()..text = 'new',
        WordSchema()..text = 'money', // should match 💰
      ];

      final count = service.autoApplyEmojis(words, minWordSpacing: 3);

      expect(count, 2);
      expect(words[2].emoji, contains('🔥'));
      expect(words[6].emoji, contains('💰'));
    });

    test('should auto-assign magic SFX to matching keywords with time gap', () {
      final words = [
        WordSchema()..text = 'Look'..start = 1.0,  // should match pop
        WordSchema()..text = 'at'..start = 1.5,
        WordSchema()..text = 'this'..start = 2.0,
        WordSchema()..text = 'fast'..start = 2.5,  // skipped (gap < 3.0s)
        WordSchema()..text = 'winner'..start = 5.0, // should match coin
      ];

      final count = service.autoApplySfx(words, minTimeGapSec: 3.0);

      expect(count, 2);
      expect(words[0].soundEffect, contains('pop'));
      expect(words[4].soundEffect, contains('coin'));
    });

    test('should detect and remove filler words', () {
      final words = [
        WordSchema()..text = 'Um'..hidden = false,
        WordSchema()..text = 'so'..hidden = false,
        WordSchema()..text = 'basically'..hidden = false,
        WordSchema()..text = 'we'..hidden = false,
        WordSchema()..text = 'did'..hidden = false,
        WordSchema()..text = 'it'..hidden = false,
      ];

      final detected = service.countFillerWords(words);
      expect(detected, 2);

      final removed = service.removeFillerWords(words);
      expect(removed, 2);
      expect(words[0].hidden, isTrue); // 'Um' hidden
      expect(words[1].hidden, isFalse);
      expect(words[2].hidden, isTrue); // 'basically' hidden
      expect(words[3].hidden, isFalse);
    });

    test('should clear all emojis and SFX cleanly', () {
      final words = [
        WordSchema()..text = 'Test'..emoji = 'notoColorEmoji:🔥'..soundEffect = 'coin:100',
        WordSchema()..text = 'Two'..emoji = 'notoColorEmoji:🚀'..soundEffect = 'pop:80',
      ];

      expect(service.clearAllEmojis(words), 2);
      expect(words[0].emoji, isNull);
      expect(words[1].emoji, isNull);

      expect(service.clearAllSfx(words), 2);
      expect(words[0].soundEffect, isNull);
      expect(words[1].soundEffect, isNull);
    });
  });
}
