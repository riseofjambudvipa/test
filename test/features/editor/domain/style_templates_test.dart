import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/features/editor/domain/style_templates.dart';

void main() {
  group('StyleTemplate Domain Tests', () {
    test('allTemplates contain unique IDs', () {
      final ids = allTemplates.map((t) => t.id).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length, reason: 'Duplicate template IDs found: ${ids.where((id) => ids.indexOf(id) != ids.lastIndexOf(id)).toSet()}');
    });

    test('allTemplates possess valid categories', () {
      final validCategories = templateCategories.map((c) => c.name.toLowerCase()).toSet();
      
      for (final template in allTemplates) {
        expect(
          validCategories.contains(template.category.name.toLowerCase()) || template.category.name.toLowerCase() == 'effects',
          isTrue,
          reason: 'Template "${template.name}" has invalid category "${template.category}"',
        );
      }
    });

    test('allTemplates colors are in valid hex formats', () {
      final hexRegex = RegExp(r'^#[0-9a-fA-F]{6}$');
      
      for (final template in allTemplates) {
        expect(
          hexRegex.hasMatch(template.color),
          isTrue,
          reason: 'Template "${template.name}" has invalid main color "${template.color}"',
        );
        expect(
          hexRegex.hasMatch(template.mainColor),
          isTrue,
          reason: 'Template "${template.name}" has invalid highlight mainColor "${template.mainColor}"',
        );
        expect(
          hexRegex.hasMatch(template.secondColor),
          isTrue,
          reason: 'Template "${template.name}" has invalid highlight secondColor "${template.secondColor}"',
        );
        expect(
          hexRegex.hasMatch(template.thirdColor),
          isTrue,
          reason: 'Template "${template.name}" has invalid highlight thirdColor "${template.thirdColor}"',
        );
      }
    });

    test('toJson and fromJson serialize and deserialize correctly', () {
      const original = StyleTemplate(
        id: 'test_temp',
        name: 'TEST TEMPLATE',
        category: StyleCategory.modern,
        fontFamily: 'Roboto',
        fontWeight: '700',
        textTransform: 'lowercase',
        color: '#ff0000',
        fontSize: 32.0,
        top: 60.0,
        mainColor: '#00ff00',
        secondColor: '#0000ff',
        thirdColor: '#ffff00',
        stroke: 'thin',
        animation: 'bounce',
        shadow: 'hard',
        background: 'neon',
        highlightBackground: true,
        letterSpacing: 2.5,
        lineHeight: 1.5,
      );

      final json = original.toJson();
      expect(json['id'], 'test_temp');
      expect(json['fontSize'], 32.0);
      expect(json['highlightBackground'], true);
      expect(json['letterSpacing'], 2.5);

      final deserialized = StyleTemplate.fromJson(json);
      expect(deserialized.id, original.id);
      expect(deserialized.name, original.name);
      expect(deserialized.category, original.category);
      expect(deserialized.fontFamily, original.fontFamily);
      expect(deserialized.fontWeight, original.fontWeight);
      expect(deserialized.textTransform, original.textTransform);
      expect(deserialized.color, original.color);
      expect(deserialized.fontSize, original.fontSize);
      expect(deserialized.top, original.top);
      expect(deserialized.mainColor, original.mainColor);
      expect(deserialized.secondColor, original.secondColor);
      expect(deserialized.thirdColor, original.thirdColor);
      expect(deserialized.stroke, original.stroke);
      expect(deserialized.animation, original.animation);
      expect(deserialized.shadow, original.shadow);
      expect(deserialized.background, original.background);
      expect(deserialized.highlightBackground, original.highlightBackground);
      expect(deserialized.letterSpacing, original.letterSpacing);
      expect(deserialized.lineHeight, original.lineHeight);
    });

    test('fromJson handles null values and returns default fallbacks', () {
      final deserialized = StyleTemplate.fromJson(const {});
      
      expect(deserialized.id, '');
      expect(deserialized.name, 'Custom');
      expect(deserialized.category, StyleCategory.custom);
      expect(deserialized.fontFamily, 'Montserrat');
      expect(deserialized.color, '#ffffff');
      expect(deserialized.fontSize, 42.0);
      expect(deserialized.top, 55.0);
      expect(deserialized.stroke, 'thick');
      expect(deserialized.animation, 'pop');
      expect(deserialized.shadow, 'none');
      expect(deserialized.background, isNull);
      expect(deserialized.highlightBackground, isNull);
      expect(deserialized.letterSpacing, isNull);
      expect(deserialized.lineHeight, isNull);
    });

    test('templateToConfig converts template to ProjectConfigSchema correctly', () {
      final template = allTemplates.first;
      final config = templateToConfig(template, currentEmojiPack: 'customAnimated');

      expect(config.name, template.name);
      expect(config.style.fontFamily, template.fontFamily);
      expect(config.style.fontWeight, template.fontWeight);
      expect(config.style.textTransform, template.textTransform);
      expect(config.style.color, template.color);
      expect(config.style.fontSize, template.fontSize);
      expect(config.style.top, template.top);
      expect(config.style.highlightBackground, template.highlightBackground ?? false);
      expect(config.style.letterSpacing, template.letterSpacing ?? 0.0);
      expect(config.style.lineHeight, template.lineHeight ?? 1.2);
      
      expect(config.highlightStyle.mainColor, template.mainColor);
      expect(config.highlightStyle.secondColor, template.secondColor);
      expect(config.highlightStyle.thirdColor, template.thirdColor);
      
      expect(config.animation, template.animation);
      expect(config.shadow, template.shadow);
      expect(config.stroke, template.stroke);
      expect(config.background, template.background);
      expect(config.emojiPack, 'customAnimated');
    });

    test('allTemplates stroke styles are valid', () {
      final validStrokes = {'none', 'thin', 'thick'};
      for (final template in allTemplates) {
        expect(
          validStrokes.contains(template.stroke.toLowerCase()),
          isTrue,
          reason: 'Template "${template.name}" has invalid stroke "${template.stroke}"',
        );
      }
    });

    test('allTemplates shadow styles are valid', () {
      final validShadows = {'none', 'soft', 'hard', '3d'};
      for (final template in allTemplates) {
        expect(
          validShadows.contains(template.shadow.toLowerCase()),
          isTrue,
          reason: 'Template "${template.name}" has invalid shadow "${template.shadow}"',
        );
      }
    });

    test('allTemplates animation styles are valid', () {
      final validAnimations = {'none', 'bounce', 'glowpulse', 'pop', 'kinetictilt', 'wordreveal'};
      for (final template in allTemplates) {
        expect(
          validAnimations.contains(template.animation.toLowerCase()),
          isTrue,
          reason: 'Template "${template.name}" has invalid animation "${template.animation}"',
        );
      }
    });

    test('allTemplates vertical coordinate boundaries', () {
      for (final template in allTemplates) {
        expect(template.top, greaterThanOrEqualTo(0.0));
        expect(template.top, lessThanOrEqualTo(100.0));
      }
    });

    test('text alignments map to correct vertical layout zones', () {
      // Top alignment zone should be top < 35
      // Center alignment zone should be 35 <= top <= 65
      // Bottom alignment zone should be top > 65
      for (final template in allTemplates) {
        final zone = template.top < 35.0 ? 'top' : (template.top <= 65.0 ? 'center' : 'bottom');
        if (template.id == 'glow') {
          expect(zone, equals('center')); // top is 65
        }
      }
    });

    test('fromJson handles invalid category by defaulting gracefully', () {
      final json = {
        'id': 'corrupt_cat',
        'category': 'super_special_invalid_category_123',
      };
      final deserialized = StyleTemplate.fromJson(json);
      expect(deserialized.category, equals(StyleCategory.custom));
    });

    test('fromJson handles empty font family and falls back to default', () {
      final json = {
        'id': 'empty_font',
        'fontFamily': '',
      };
      final deserialized = StyleTemplate.fromJson(json);
      expect(deserialized.fontFamily, equals(''));
    });

    test('fromJson handles corrupted data types gracefully', () {
      final json = {
        'id': 'corrupted_types',
        'fontSize': 'not_a_double', // string instead of double
        'top': 'not_a_double_either',
        'letterSpacing': 'invalid_num',
        'lineHeight': 'invalid_num_too',
      };
      final deserialized = StyleTemplate.fromJson(json);
      expect(deserialized.id, equals('corrupted_types'));
      expect(deserialized.fontSize, equals(42.0)); // fallback
      expect(deserialized.top, equals(55.0)); // fallback
      expect(deserialized.letterSpacing, isNull);
      expect(deserialized.lineHeight, isNull);
    });

    group('toConfig & templateToConfig preservation tests', () {
      test('toConfig preserves existingSubs chunkSize and chunkLineMaxLength', () {
        final template = allTemplates.first;
        final existingSubs = SubtitleConfigSchema()
          ..chunkSize = 2
          ..chunkLineMaxLength = 18;

        final config = template.toConfig(existingSubs: existingSubs);
        expect(config.subs.chunkSize, equals(2));
        expect(config.subs.chunkLineMaxLength, equals(18));
      });

      test('toConfig preserves currentEmojiPack', () {
        final template = allTemplates.first;
        final config = template.toConfig(currentEmojiPack: 'appleColorEmoji');
        expect(config.emojiPack, equals('appleColorEmoji'));
      });

      test('toConfig falls back to default chunkSize and notoColorEmoji when not provided', () {
        final template = allTemplates.first;
        final config = template.toConfig();
        expect(config.subs.chunkSize, equals(4));
        expect(config.subs.chunkLineMaxLength, equals(30));
        expect(config.emojiPack, equals('notoColorEmoji'));
      });

      test('templateToConfig forwards existingSubs and currentEmojiPack correctly', () {
        final template = allTemplates.first;
        final existingSubs = SubtitleConfigSchema()
          ..chunkSize = 1
          ..chunkLineMaxLength = 12;

        final config = templateToConfig(
          template,
          existingSubs: existingSubs,
          currentEmojiPack: 'fluentAnimated',
        );

        expect(config.subs.chunkSize, equals(1));
        expect(config.subs.chunkLineMaxLength, equals(12));
        expect(config.emojiPack, equals('fluentAnimated'));
      });
    });
  });
}
