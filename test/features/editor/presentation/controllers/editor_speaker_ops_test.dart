import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/features/editor/domain/caption_engine.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import '../../../../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EditorController Speaker Operations', () {
    late ProviderContainer container;
    late EditorController controller;
    late Project testProject;
    late MockIsarService mockIsarService;

    setUpAll(() {
      registerFallbackValue(Project());
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.instance.init();

      mockIsarService = MockIsarService();
      when(() => mockIsarService.isInitialized).thenReturn(true);
      when(() => mockIsarService.saveProject(any())).thenAnswer((_) async {});
      IsarService.instance = mockIsarService;

      container = ProviderContainer();
      controller = container.read(editorProvider.notifier);

      testProject = Project()
        ..projectId = 'proj_test_speakers'
        ..name = 'Speaker Test Project'
        ..videoPath = '/dummy/path.mp4'
        ..duration = 10.0
        ..width = 1920
        ..height = 1080
        ..words = [
          WordSchema()
            ..wordId = 'w1'
            ..text = 'Who'
            ..start = 0.0
            ..end = 0.5,
          WordSchema()
            ..wordId = 'w2'
            ..text = 'are you?'
            ..start = 0.5
            ..end = 1.0,
          WordSchema()
            ..wordId = 'w3'
            ..text = 'I am the guest.'
            ..start = 1.6
            ..end = 2.5,
        ];

      controller.setProjectForTesting(testProject);
    });

    tearDown(() {
      container.dispose();
    });

    test('autoDetectSpeakers assigns speakers and updates project state', () {
      final detected = controller.autoDetectSpeakers(speakerCount: 2);
      expect(detected, equals(2));

      final project = controller.state.project!;
      expect(project.words[0].speaker, equals('Speaker 1'));
      expect(project.words[1].speaker, equals('Speaker 1'));
      expect(project.words[2].speaker, equals('Speaker 2'));
    });

    test('renameSpeaker replaces speaker names globally across project', () {
      controller.autoDetectSpeakers(speakerCount: 2);
      controller.renameSpeaker('Speaker 1', 'Host Lex');

      final project = controller.state.project!;
      expect(project.words[0].speaker, equals('Host Lex'));
      expect(project.words[1].speaker, equals('Host Lex'));
      expect(project.words[2].speaker, equals('Speaker 2'));
    });

    test('setChunkSpeaker reassigns speaker for words in chunk', () {
      controller.autoDetectSpeakers(speakerCount: 2);
      final chunks = CaptionEngine.buildChunks(controller.state.project!.words, null, 0, 0, 5, 40);
      expect(chunks.length, greaterThanOrEqualTo(2));

      controller.setChunkSpeaker(chunks[1], 'Special Guest');
      final project = controller.state.project!;
      expect(project.words[2].speaker, equals('Special Guest'));
    });

    test('getSpeakerStats and getUniqueSpeakers return correct data', () {
      controller.autoDetectSpeakers(speakerCount: 2);
      final stats = controller.getSpeakerStats();
      expect(stats.length, equals(2));

      final unique = controller.getUniqueSpeakers();
      expect(unique.contains('Speaker 1'), isTrue);
      expect(unique.contains('Speaker 2'), isTrue);
    });
  });
}

extension on EditorController {
  void setProjectForTesting(Project p) {
    state = state.copyWith(project: p, revision: 1);
  }
}
