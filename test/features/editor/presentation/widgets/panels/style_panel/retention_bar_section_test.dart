import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/app/theme.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/video/retention_progress_bar_models.dart';
import 'package:capstudio/core/video/retention_progress_bar_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/style_panel/retention_bar_section.dart';
import '../../../../../../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RetentionBarSection Widget Tests', () {
    late MockIsarService mockIsarService;
    late Project testProject;

    setUpAll(() {
      registerFallbackValue(Project());
    });

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.instance.init();
      RetentionProgressBarService.instance.clearCache();

      mockIsarService = MockIsarService();
      when(() => mockIsarService.isInitialized).thenReturn(true);
      when(() => mockIsarService.saveProject(any())).thenAnswer((_) async {});
      IsarService.instance = mockIsarService;

      testProject = Project()
        ..projectId = 'proj_retention_test'
        ..name = 'Retention Bar Test'
        ..videoPath = 'test.mp4'
        ..duration = 15.0
        ..width = 1080
        ..height = 1920
        ..config = (ProjectConfigSchema()
          ..style = (StyleConfigSchema()..fontFamily = 'Arial')
          ..highlightStyle = HighlightStyleSchema());
    });

    testWidgets('Renders section title, badge, and toggle switch', (tester) async {
      final container = ProviderContainer();
      addTearDown(() {
        container.dispose();
      });

      container.read(editorProvider.notifier).setProject(testProject);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: RetentionBarSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('RETENTION PROGRESS BAR'), findsOneWidget);
      expect(find.text('VIRAL RETENTION'), findsOneWidget);
      expect(find.text('Animated Progress Bar'), findsOneWidget);

      // Initially disabled -> sliders and presets not shown
      expect(find.text('QUICK PRESETS'), findsNothing);
      expect(find.text('BAR POSITION'), findsNothing);
    });

    testWidgets('Toggling switch ON reveals presets, position, and sliders', (tester) async {
      final container = ProviderContainer();
      addTearDown(() {
        container.dispose();
      });

      container.read(editorProvider.notifier).setProject(testProject);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: RetentionBarSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Enable the retention progress bar
      container.read(editorProvider.notifier).updateRetentionBarConfig(
            const RetentionProgressBarConfig(enabled: true),
          );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('QUICK PRESETS'), findsOneWidget);
      expect(find.text('BAR POSITION'), findsOneWidget);
      expect(find.text('THICKNESS'), findsOneWidget);
      expect(find.text('EDGE OFFSET'), findsOneWidget);
      expect(find.text('BAR COLOR'), findsOneWidget);
      expect(find.text('Viral Ember'), findsOneWidget);
      expect(find.text('Electric Cyan'), findsOneWidget);
      expect(find.text('Bottom Edge'), findsOneWidget);
      expect(find.text('Top Edge'), findsOneWidget);
    });

    testWidgets('Tapping a preset chip updates the controller retentionBarConfig', (tester) async {
      final container = ProviderContainer();
      addTearDown(() {
        container.dispose();
      });

      container.read(editorProvider.notifier).setProject(testProject);
      container.read(editorProvider.notifier).updateRetentionBarConfig(
            const RetentionProgressBarConfig(enabled: true),
          );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: SingleChildScrollView(
                child: RetentionBarSection(),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      // Tap on 'Electric Cyan' preset
      await tester.tap(find.text('Electric Cyan'));
      await tester.pump(const Duration(milliseconds: 50));

      final currentConfig = container.read(editorProvider).retentionBarConfig;
      expect(currentConfig.color, '#06b6d4');
      expect(currentConfig.enabled, true);
    });
  });
}
