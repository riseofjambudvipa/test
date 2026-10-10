import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/core/project/project_bundle_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProjectBundleService Tests', () {
    late Project sampleProject;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      sampleProject = Project()
        ..projectId = 'proj_sample_bundle_123'
        ..name = 'Sample Podcast Project'
        ..videoPath = '/media/podcast.mp4'
        ..duration = 45.5
        ..width = 1080
        ..height = 1920
        ..trimStart = 2.0
        ..trimEnd = 40.0
        ..status = 'draft'
        ..config = (ProjectConfigSchema()
          ..name = 'Podcast Layout'
          ..animation = 'pop'
          ..stroke = 'thick'
          ..shadow = 'hard'
          ..style = (StyleConfigSchema()
            ..fontFamily = 'Montserrat'
            ..fontWeight = '800'
            ..textTransform = 'uppercase'
            ..color = '#ffffff'
            ..fontSize = 32.0
            ..top = 55.0
            ..left = 50.0)
          ..highlightStyle = (HighlightStyleSchema()
            ..mainColor = '#f97316'
            ..secondColor = '#06b6d4')
          ..subs = (SubtitleConfigSchema()
            ..chunkSize = 4
            ..chunkLineMaxLength = 22))
        ..words = [
          WordSchema()
            ..wordId = 'w1'
            ..text = 'Welcome'
            ..start = 2.0
            ..end = 2.4
            ..speaker = 'Host'
            ..emoji = '👋'
            ..soundEffect = 'whoosh.mp3'
            ..soundVolume = 85,
          WordSchema()
            ..wordId = 'w2'
            ..text = 'everyone!'
            ..start = 2.5
            ..end = 3.0
            ..speaker = 'Host'
            ..className = 'mainColor',
          WordSchema()
            ..wordId = 'w3'
            ..text = 'Thanks!'
            ..start = 3.5
            ..end = 4.0
            ..speaker = 'Guest',
        ]
        ..segments = [
          VideoSegmentSchema()
            ..start = 0.0
            ..end = 10.0
            ..isDeleted = false,
          VideoSegmentSchema()
            ..start = 10.0
            ..end = 15.0
            ..isDeleted = true,
        ];
    });

    test('serialize converts complete Project graph to JSON map', () {
      final map = ProjectBundleService.instance.serialize(sampleProject);
      expect(map['format'], equals('CapStudioProject'));
      expect(map['bundleVersion'], equals('1.0'));

      final proj = map['project'] as Map<String, dynamic>;
      expect(proj['name'], equals('Sample Podcast Project'));
      expect(proj['duration'], equals(45.5));
      expect(proj['width'], equals(1080));
      expect(proj['height'], equals(1920));

      final words = proj['words'] as List<dynamic>;
      expect(words.length, equals(3));
      expect(words[0]['text'], equals('Welcome'));
      expect(words[0]['speaker'], equals('Host'));
      expect(words[0]['emoji'], equals('👋'));
      expect(words[0]['soundEffect'], equals('whoosh.mp3'));
      expect(words[0]['soundVolume'], equals(85));
      expect(words[2]['speaker'], equals('Guest'));

      final segments = proj['segments'] as List<dynamic>;
      expect(segments.length, equals(2));
      expect(segments[1]['isDeleted'], isTrue);
    });

    test('deserialize reconstructs Project with all fields intact', () {
      final map = ProjectBundleService.instance.serialize(sampleProject);
      final restored = ProjectBundleService.instance.deserialize(map, generateNewId: false);

      expect(restored.projectId, equals('proj_sample_bundle_123'));
      expect(restored.name, equals('Sample Podcast Project'));
      expect(restored.videoPath, equals('/media/podcast.mp4'));
      expect(restored.duration, equals(45.5));
      expect(restored.config.style.fontFamily, equals('Montserrat'));
      expect(restored.config.style.fontWeight, equals('800'));
      expect(restored.config.style.fontSize, equals(32.0));
      expect(restored.config.highlightStyle.mainColor, equals('#f97316'));
      expect(restored.config.animation, equals('pop'));

      expect(restored.words.length, equals(3));
      expect(restored.words[0].text, equals('Welcome'));
      expect(restored.words[0].speaker, equals('Host'));
      expect(restored.words[0].emoji, equals('👋'));
      expect(restored.words[0].soundEffect, equals('whoosh.mp3'));
      expect(restored.words[0].soundVolume, equals(85));
      expect(restored.words[2].speaker, equals('Guest'));

      expect(restored.segments?.length, equals(2));
      expect(restored.segments?[1].isDeleted, isTrue);
    });

    test('deserialize generates unique ID when generateNewId is true', () {
      final map = ProjectBundleService.instance.serialize(sampleProject);
      final imported = ProjectBundleService.instance.deserialize(map, generateNewId: true);

      expect(imported.projectId, isNot(equals('proj_sample_bundle_123')));
      expect(imported.projectId.startsWith('proj_'), isTrue);
    });

    test('file export and import roundtrip preserves data', () async {
      final tempDir = await Directory.systemTemp.createTemp('capstudio_bundle_test_');
      try {
        final filePath = '${tempDir.path}/test_project.capstudio';
        final file = await ProjectBundleService.instance.exportProjectToFile(sampleProject, filePath);
        expect(await file.exists(), isTrue);

        final rawJson = await file.readAsString();
        expect(rawJson, contains('"format": "CapStudioProject"'));
        expect(rawJson, contains('"Sample Podcast Project"'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('deserializeDynamic handles project wrapped in a List', () {
      final map = ProjectBundleService.instance.serialize(sampleProject);
      final list = [map];
      final project = ProjectBundleService.instance.deserializeDynamic(list, generateNewId: false);

      expect(project.name, equals('Sample Podcast Project'));
      expect(project.words.length, equals(3));
    });

    test('deserializeDynamic handles caption list input', () {
      final captionList = [
        {'text': 'Hello', 'start': 0.0, 'end': 1.0},
        {'text': 'World', 'start': 1.0, 'end': 2.5},
      ];
      final project = ProjectBundleService.instance.deserializeDynamic(
        captionList,
        defaultName: 'My Captions',
      );

      expect(project.name, equals('My Captions'));
      expect(project.words.length, equals(2));
      expect(project.words[0].text, equals('Hello'));
      expect(project.words[1].text, equals('World'));
      expect(project.duration, equals(2.5));
    });

    test('deserialize safely handles Map<dynamic, dynamic>', () {
      final dynamic raw = <dynamic, dynamic>{
        'name': 'Dynamic Map Project',
        'config': <dynamic, dynamic>{
          'style': <dynamic, dynamic>{
            'fontFamily': 'Roboto',
          },
        },
        'words': <dynamic>[
          <dynamic, dynamic>{
            'text': 'Test',
            'start': 0.5,
            'end': 1.5,
          },
        ],
      };

      final project = ProjectBundleService.instance.deserialize(Map<String, dynamic>.from(raw));
      expect(project.name, equals('Dynamic Map Project'));
      expect(project.config.style.fontFamily, equals('Roboto'));
      expect(project.words.length, equals(1));
      expect(project.words.first.text, equals('Test'));
    });
  });
}
