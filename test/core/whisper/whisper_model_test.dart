import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/whisper/whisper_model.dart';

void main() {
  group('WhisperModel Tests', () {
    test('should construct model and return correct download URLs', () {
      const model = WhisperModel(
        name: 'test-model',
        displayName: 'Test Model',
        description: 'Test description',
        sizeMb: 50.0,
        englishOnly: false,
        relativeSpeed: 5,
        relativeAccuracy: 5,
      );

      expect(model.name, 'test-model');
      expect(model.displayName, 'Test Model');
      expect(model.description, 'Test description');
      expect(model.sizeMb, 50.0);
      expect(model.englishOnly, isFalse);
      expect(model.relativeSpeed, 5);
      expect(model.relativeAccuracy, 5);
      expect(
        model.downloadUrl,
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-test-model.bin',
      );
    });

    test('should verify kWhisperModels constants catalog contains all required profiles', () {
      expect(kWhisperModels, isNotEmpty);
      // tiny/base/small/medium each have a multilingual + English-only (.en) variant, plus large-v3-turbo.
      expect(kWhisperModels.length, 9);

      // Verify all models have valid fields
      for (final m in kWhisperModels) {
        expect(m.name, isNotEmpty);
        expect(m.displayName, isNotEmpty);
        expect(m.description, isNotEmpty);
        expect(m.sizeMb, greaterThan(0));
        expect(m.downloadUrl, startsWith('https://huggingface.co/ggerganov/whisper.cpp/resolve/main/'));
        expect(m.downloadUrl, endsWith('.bin'));
      }

      final tiny = kWhisperModels.firstWhere((m) => m.name == 'tiny');
      expect(tiny.displayName, 'Tiny (Multilingual)');
      expect(tiny.sizeMb, 75.0);
      expect(tiny.englishOnly, isFalse);

      final base = kWhisperModels.firstWhere((m) => m.name == 'base');
      expect(base.displayName, 'Base (Multilingual)');
      expect(base.sizeMb, 142.0);
      expect(base.englishOnly, isFalse);

      final turbo = kWhisperModels.firstWhere((m) => m.name == 'large-v3-turbo');
      expect(turbo.displayName, 'Large v3 Turbo (Multilingual)');
      expect(turbo.sizeMb, 1540.0);
      expect(turbo.relativeAccuracy, 10);

      // English-only variants must exist so modelNameEn lookups never silently fall back.
      for (final enName in ['tiny.en', 'base.en', 'small.en', 'medium.en']) {
        final en = kWhisperModels.firstWhere((m) => m.name == enName);
        expect(en.englishOnly, isTrue);
      }
    });
  });
}
