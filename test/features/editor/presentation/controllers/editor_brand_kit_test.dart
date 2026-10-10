import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import '../../../../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EditorController Brand Kit Operations', () {
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
        ..projectId = 'proj_test_brand_kit'
        ..name = 'Brand Kit Test Project'
        ..videoPath = 'test.mp4'
        ..duration = 10.0
        ..width = 1080
        ..height = 1920
        ..config = (ProjectConfigSchema()
          ..style = (StyleConfigSchema()
            ..fontFamily = 'Arial'
            ..fontWeight = '900'
            ..color = '#FFFFFF')
          ..highlightStyle = (HighlightStyleSchema()
            ..mainColor = '#000000'
            ..secondColor = '#111111'
            ..thirdColor = '#222222'));

      controller.setProject(testProject);
    });

    tearDown(() async {
      // Drain any pending microtasks (e.g., setProject's async .then callbacks
      // for comments loading and proxy info) before the container is disposed.
      // Without this, those callbacks fire after dispose and throw
      // "Bad state: Tried to use EditorController after dispose".
      await Future<void>.delayed(Duration.zero);
      container.dispose();
    });

    test('applyBrandKit updates font family and 3 highlight colors with history entry', () {
      controller.applyBrandKit(
        primaryColor: '#F97316',
        secondaryColor: '#06B6D4',
        accentColor: '#EC4899',
        fontFamily: 'Outfit',
      );

      final updatedProject = container.read(editorProvider).project;
      expect(updatedProject, isNotNull);
      expect(updatedProject!.config.style.fontFamily, equals('Outfit'));
      expect(updatedProject.config.highlightStyle.mainColor, equals('#F97316'));
      expect(updatedProject.config.highlightStyle.secondColor, equals('#06B6D4'));
      expect(updatedProject.config.highlightStyle.thirdColor, equals('#EC4899'));

      // Verify undo works
      expect(container.read(editorProvider).canUndo, isTrue);
      controller.undo();

      final undoneProject = container.read(editorProvider).project;
      expect(undoneProject!.config.style.fontFamily, equals('Arial'));
      expect(undoneProject.config.highlightStyle.mainColor, equals('#000000'));
    });
  });
}
