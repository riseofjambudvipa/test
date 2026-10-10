import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/whisper/whisper_service.dart';
import 'package:capstudio/core/logger/logger_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    LoggerService.resetForTesting();
    tempDir = Directory.systemTemp.createTempSync('whisper_parsing_test_');
    AppDirs.setSupportPathForTesting(tempDir.path);
    await AppDirs.init();
    await LoggerService.instance.init();
  });

  tearDown(() async {
    await LoggerService.instance.dispose();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('Whisper JSON Parsing Tests', () {
    test('parses Standard CLI JSON format with seconds correctly', () {
      final jsonStr = jsonEncode({
        'language': 'es',
        'segments': [
          {
            'id': 0,
            'text': 'Hola mundo',
            'words': [
              {'word': 'Hola', 'start': 0.0, 'end': 0.5, 'confidence': 0.95},
              {'word': 'mundo', 'start': 0.6, 'end': 1.2, 'confidence': 0.98}
            ]
          }
        ]
      });

      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, null);
      
      expect(result.language, 'es');
      expect(result.words.length, 2);
      expect(result.words[0].text, 'Hola');
      expect(result.words[0].start, 0.0);
      expect(result.words[0].end, 0.5);
      expect(result.words[0].confidence, 0.95);
      
      expect(result.words[1].text, 'mundo');
      expect(result.words[1].start, 0.6);
      expect(result.words[1].end, 1.2);
      expect(result.words[1].confidence, 0.98);
    });

    test('parses CLI JSON with millisecond thresholds correctly (converts to seconds)', () {
      final jsonStr = jsonEncode({
        'language': 'en',
        'segments': [
          {
            'id': 0,
            'text': 'Hello world',
            'words': [
              {'word': 'Hello', 'start': 200.0, 'end': 1500.0, 'confidence': 0.9}, // Wait, 200 and 1500 -> start is 200, end is 1500. Let's make sure it checks both start and end > 1000
              // Actually the logic is: if (startRaw > 1000.0 || endRaw > 1000.0) -> divide both by 1000
              {'word': 'world', 'start': 1600.0, 'end': 2800.0, 'confidence': 0.92}
            ]
          }
        ]
      });

      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, 3.0);
      
      expect(result.language, 'en');
      expect(result.words.length, 2);
      expect(result.words[0].text, 'Hello');
      expect(result.words[0].start, 0.2);
      expect(result.words[0].end, 1.5);
      
      expect(result.words[1].text, 'world');
      expect(result.words[1].start, 1.6);
      expect(result.words[1].end, 2.8);
    });

    test('parses Custom JNI Mobile format (transcription key) with from/to timestamps', () {
      final jsonStr = jsonEncode({
        'language': 'fr',
        'transcription': [
          {
            'text': 'Bonjour',
            'timestamps': {'from': 500, 'to': 1200},
            'p': 0.88
          },
          {
            'text': 'le monde',
            'timestamps': {'from': 1300, 'to': 2500},
            'p': 0.91
          }
        ]
      });

      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, 3.0);
      
      expect(result.language, 'fr');
      expect(result.words.length, 2);
      expect(result.words[0].text, 'Bonjour');
      expect(result.words[0].start, 0.5);
      expect(result.words[0].end, 1.2);
      expect(result.words[0].confidence, 0.88);
      
      expect(result.words[1].text, 'le monde');
      expect(result.words[1].start, 1.3);
      expect(result.words[1].end, 2.5);
      expect(result.words[1].confidence, 0.91);
    });

    test('applies exact hardware drift correction multiplier when expectedDuration > 1000.0 and close to known ratios', () {
      // whisperEnd is 1102.2s. Expected duration is 1199.7s.
      // Ratio = 1199.7 / 1102.2 = 1.08846. This is close to 48000 / 44100 = 1.088435.
      // The drift multiplier applied should be exactly 48000 / 44100.
      final double expectedDuration = 1199.7;
      final double whisperEndMs = 1102200.0;
      
      final jsonStr = jsonEncode({
        'language': 'en',
        'segments': [
          {
            'id': 0,
            'text': 'Start',
            'words': [
              {'word': 'Start', 'start': 0.0, 'end': 2000.0}
            ]
          },
          {
            'id': 1,
            'text': 'End',
            'words': [
              {'word': 'End', 'start': 1090000.0, 'end': whisperEndMs}
            ]
          }
        ]
      });

      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, expectedDuration);
      
      final double expectedRatio = 48000 / 44100;
      expect(result.words.length, 2);
      expect(result.words[1].end, closeTo(1102.2 * expectedRatio, 0.0001));
    });

    test('does not apply drift correction when expectedDuration <= 1000.0', () {
      final double expectedDuration = 500.0;
      final double whisperEndSecs = 480.0;
      
      final jsonStr = jsonEncode({
        'language': 'en',
        'segments': [
          {
            'id': 0,
            'text': 'End',
            'words': [
              {'word': 'End', 'start': 470.0, 'end': whisperEndSecs}
            ]
          }
        ]
      });

      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, expectedDuration);
      
      expect(result.words.length, 1);
      expect(result.words[0].end, whisperEndSecs); // remains exactly 480.0 (no ratio applied)
    });

    test('does not apply drift correction when ratio is not close to any known ratio', () {
      final double expectedDuration = 1200.0;
      final double whisperEndMs = 1010000.0;
      // Ratio = 1200 / 1010 = 1.188. Not close to any of: 1.0884, 0.9187, 1.0416, 0.96.
      
      final jsonStr = jsonEncode({
        'language': 'en',
        'segments': [
          {
            'id': 0,
            'text': 'End',
            'words': [
              {'word': 'End', 'start': 1000000.0, 'end': whisperEndMs}
            ]
          }
        ]
      });

      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, expectedDuration);
      
      expect(result.words.length, 1);
      expect(result.words[0].end, 1010.0); // remains exactly 1010.0 (no ratio applied)
    });

    test('throws FormatException when parsing invalid JSON string', () {
      expect(
        () => WhisperService.instance.parseTranscriptionJson('invalid-json', null),
        throwsFormatException,
      );
    });

    test('handles empty JSON object by returning empty words list and default language', () {
      final result = WhisperService.instance.parseTranscriptionJson('{}', null);
      expect(result.language, equals('en'));
      expect(result.words, isEmpty);
    });

    test('handles missing segments and transcription keys gracefully', () {
      final jsonStr = jsonEncode({
        'language': 'de',
      });
      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, null);
      expect(result.language, equals('de'));
      expect(result.words, isEmpty);
    });

    test('handles segments with empty words arrays gracefully', () {
      final jsonStr = jsonEncode({
        'language': 'fr',
        'segments': [
          {'id': 0, 'text': 'Hello', 'words': []}
        ]
      });
      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, null);
      expect(result.words, isEmpty);
    });

    test('handles mixed float and integer timestamps properly', () {
      final jsonStr = jsonEncode({
        'segments': [
          {
            'words': [
              {'word': 'one', 'start': 1, 'end': 1.5},
              {'word': 'two', 'start': 2.0, 'end': 3}
            ]
          }
        ]
      });
      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, null);
      expect(result.words.length, 2);
      expect(result.words[0].start, 1.0);
      expect(result.words[0].end, 1.5);
      expect(result.words[1].start, 2.0);
      expect(result.words[1].end, 3.0);
    });

    test('handles extreme drift correction calculations for >2 hours video length', () {
      // whisperEnd is 7200s (2 hours). Expected duration is 7836.7s.
      // Ratio = 7836.7 / 7200 = 1.08843. This is close to 48000 / 44100 = 1.088435.
      final double expectedDuration = 7836.7;
      final double whisperEndMs = 7200.0 * 1000.0;
      final jsonStr = jsonEncode({
        'segments': [
          {
            'words': [
              {'word': 'End', 'start': 7100.0 * 1000.0, 'end': whisperEndMs}
            ]
          }
        ]
      });
      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, expectedDuration);
      final double expectedRatio = 48000 / 44100;
      expect(result.words[0].end, closeTo(7200.0 * expectedRatio, 0.1));
    });

    test('prevents division by zero when last word end timestamp is zero during drift calculation', () {
      final double expectedDuration = 1200.0;
      final jsonStr = jsonEncode({
        'segments': [
          {
            'words': [
              {'word': 'Zero', 'start': 0.0, 'end': 0.0}
            ]
          }
        ]
      });
      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, expectedDuration);
      expect(result.words[0].end, equals(0.0));
    });

    test('handles missing confidence values and defaults to 1.0', () {
      final jsonStr = jsonEncode({
        'segments': [
          {
            'words': [
              {'word': 'NoConf', 'start': 0.0, 'end': 1.0}
            ]
          }
        ]
      });
      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, null);
      expect(result.words[0].confidence, equals(1.0));
    });

    test('generates unique UUID v4 for each parsed word', () {
      final jsonStr = jsonEncode({
        'segments': [
          {
            'words': [
              {'word': 'a', 'start': 0.0, 'end': 0.5},
              {'word': 'b', 'start': 0.6, 'end': 1.0}
            ]
          }
        ]
      });
      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, null);
      expect(result.words.length, 2);
      expect(result.words[0].wordId, isNotEmpty);
      expect(result.words[1].wordId, isNotEmpty);
      expect(result.words[0].wordId, isNot(equals(result.words[1].wordId)));
    });

    test('verifies all parsed words are categorized as type word', () {
      final jsonStr = jsonEncode({
        'segments': [
          {
            'words': [
              {'word': 'hello', 'start': 0.0, 'end': 1.0}
            ]
          }
        ]
      });
      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, null);
      expect(result.words[0].type, equals('word'));
    });

    test('parses CLI JSON with millisecond thresholds when expectedDuration is null', () {
      final jsonStr = jsonEncode({
        'language': 'en',
        'segments': [
          {
            'id': 0,
            'text': 'Test',
            'words': [
              {'word': 'Hello', 'start': 2000.0, 'end': 4000.0}
            ]
          }
        ]
      });

      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, null);
      
      expect(result.words.length, 1);
      expect(result.words[0].start, 2.0);
      expect(result.words[0].end, 4.0);
    });

    test('correctly preserves seconds for long video (>1000s) when expectedDuration is null', () {
      final jsonStr = jsonEncode({
        'language': 'en',
        'segments': [
          {
            'id': 0,
            'text': 'Late in the video',
            'words': [
              {'word': 'Late', 'start': 1100.0, 'end': 1100.4},
              {'word': 'in', 'start': 1100.5, 'end': 1100.8},
              {'word': 'video', 'start': 1101.0, 'end': 1101.5},
            ]
          }
        ]
      });

      final result = WhisperService.instance.parseTranscriptionJson(jsonStr, null);
      
      expect(result.words.length, 3);
      // Average word duration is ~0.4s (well below 5s), so units must NOT be misdetected as milliseconds
      expect(result.words[0].start, 1100.0);
      expect(result.words[0].end, 1100.4);
      expect(result.words[2].start, 1101.0);
      expect(result.words[2].end, 1101.5);
    });
  });
}
