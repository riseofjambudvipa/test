import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';

void main() {
  group('Language Font Suggestion Tests', () {
    test('suggestFontForLanguage matches scripts correctly', () {
      // Devanagari script
      expect(suggestFontForLanguage('hi'), 'Noto Sans Devanagari');
      expect(suggestFontForLanguage('mr'), 'Noto Sans Devanagari');
      expect(suggestFontForLanguage('ne'), 'Noto Sans Devanagari');
      expect(suggestFontForLanguage('sa'), 'Noto Sans Devanagari');

      // Arabic script
      expect(suggestFontForLanguage('ar'), 'Noto Sans Arabic');
      expect(suggestFontForLanguage('fa'), 'Noto Sans Arabic');
      expect(suggestFontForLanguage('ps'), 'Noto Sans Arabic');

      // Urdu
      expect(suggestFontForLanguage('ur'), 'Noto Nastaliq Urdu');

      // Thai
      expect(suggestFontForLanguage('th'), 'Noto Sans Thai');

      // Hebrew
      expect(suggestFontForLanguage('he'), 'Noto Sans Hebrew');
      expect(suggestFontForLanguage('yi'), 'Noto Sans Hebrew');

      // Asian scripts
      expect(suggestFontForLanguage('ta'), 'Noto Sans Tamil');
      expect(suggestFontForLanguage('te'), 'Noto Sans Telugu');
      expect(suggestFontForLanguage('bn'), 'Noto Sans Bengali');
      expect(suggestFontForLanguage('gu'), 'Noto Sans Gujarati');
      expect(suggestFontForLanguage('kn'), 'Noto Sans Kannada');
      expect(suggestFontForLanguage('ml'), 'Noto Sans Malayalam');
      expect(suggestFontForLanguage('pa'), 'Noto Sans Gurmukhi');
      expect(suggestFontForLanguage('or'), 'Noto Sans Oriya');
      expect(suggestFontForLanguage('si'), 'Noto Sans Sinhala');
      expect(suggestFontForLanguage('my'), 'Noto Sans Myanmar');
      expect(suggestFontForLanguage('km'), 'Noto Sans Khmer');
      expect(suggestFontForLanguage('lo'), 'Noto Sans Lao');

      // Other scripts
      expect(suggestFontForLanguage('ka'), 'Noto Sans Georgian');
      expect(suggestFontForLanguage('hy'), 'Noto Sans Armenian');
      expect(suggestFontForLanguage('am'), 'Noto Sans Ethiopic');

      // CJK scripts
      expect(suggestFontForLanguage('zh'), 'Noto Sans SC');
      expect(suggestFontForLanguage('zh-CN'), 'Noto Sans SC');
      expect(suggestFontForLanguage('yue'), 'Noto Sans SC');
      expect(suggestFontForLanguage('zh-TW'), 'Noto Sans TC');
      expect(suggestFontForLanguage('ja'), 'Noto Sans JP');
      expect(suggestFontForLanguage('ko'), 'Noto Sans KR');

      // Latin / fallback scripts
      expect(suggestFontForLanguage('en'), 'Montserrat');
      expect(suggestFontForLanguage('fr'), 'Montserrat');
      expect(suggestFontForLanguage('es'), 'Montserrat');
      expect(suggestFontForLanguage('de'), 'Montserrat');
      expect(suggestFontForLanguage('unknown-lang-code'), 'Montserrat');
    });

    test('isCjkLanguage identifies CJK language codes correctly', () {
      final cjkCodes = ['zh', 'zh-CN', 'zh-TW', 'yue', 'ja', 'ko', 'ja-JP', 'ko-KR'];
      for (final code in cjkCodes) {
        expect(isCjkLanguage(code), isTrue, reason: '$code should be CJK');
      }

      final nonCjkCodes = ['en', 'hi', 'ar', 'ru', 'fr', 'es', 'de'];
      for (final code in nonCjkCodes) {
        expect(isCjkLanguage(code), isFalse, reason: '$code should NOT be CJK');
      }
    });

    test('suggestFontForLanguage handles CJK regional variants like zh-HK and zh-SG', () {
      expect(suggestFontForLanguage('zh-HK'), equals('Noto Sans TC'));
      expect(suggestFontForLanguage('zh-SG'), equals('Noto Sans SC'));
      expect(isCjkLanguage('zh-HK'), isTrue);
      expect(isCjkLanguage('zh-SG'), isTrue);
    });

    test('suggestFontForLanguage case sensitivity check', () {
      expect(suggestFontForLanguage('ZH'), equals('Noto Sans SC'));
      expect(suggestFontForLanguage('JA'), equals('Noto Sans JP'));
      expect(suggestFontForLanguage('HI'), equals('Noto Sans Devanagari'));
    });

    test('suggestFontForLanguage empty or whitespace string fallback', () {
      expect(suggestFontForLanguage(''), equals('Montserrat'));
      expect(suggestFontForLanguage('   '), equals('Montserrat'));
    });

    test('suggestFontForLanguage Cyrillic and Greek variants fallback to Montserrat', () {
      // Cyrillic
      expect(suggestFontForLanguage('ru'), equals('Montserrat'));
      expect(suggestFontForLanguage('uk'), equals('Montserrat'));
      expect(suggestFontForLanguage('bg'), equals('Montserrat'));
      // Greek
      expect(suggestFontForLanguage('el'), equals('Montserrat'));
    });

    test('suggestFontForLanguage Devanagari and Arabic variants return script fonts', () {
      expect(suggestFontForLanguage('hi'), equals('Noto Sans Devanagari'));
      expect(suggestFontForLanguage('ar'), equals('Noto Sans Arabic'));
      expect(suggestFontForLanguage('fa'), equals('Noto Sans Arabic'));
    });

    test('suggestFontForLanguage unknown language codes fallback to Montserrat', () {
      expect(suggestFontForLanguage('xyz'), equals('Montserrat'));
      expect(suggestFontForLanguage('123'), equals('Montserrat'));
    });
  });
}
