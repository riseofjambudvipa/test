import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/app/theme.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/style_panel/brand_kit_dialog.dart';
import '../../../../../../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BrandKitDialog Widget Tests', () {
    late MockIsarService mockIsarService;
    late Project testProject;

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

      testProject = Project()
        ..projectId = 'proj_brand_dialog'
        ..name = 'Brand Dialog Test'
        ..videoPath = 'test.mp4'
        ..duration = 10.0
        ..width = 1080
        ..height = 1920
        ..config = (ProjectConfigSchema()
          ..style = (StyleConfigSchema()
            ..fontFamily = 'Arial'
            ..fontWeight = '900')
          ..highlightStyle = HighlightStyleSchema());
    });

    Widget buildTestApp(ProviderContainer container) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => BrandKitDialog.show(context),
                  child: const Text('Open Brand Kits'),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('renders search, buttons, and default brand kits', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      container.read(editorProvider.notifier).setProject(testProject);

      await tester.pumpWidget(buildTestApp(container));
      await tester.tap(find.text('Open Brand Kits'));
      await tester.pumpAndSettle();

      expect(find.text('BRAND KITS & CREATOR IDENTITIES'), findsOneWidget);
      expect(find.text('NEW BRAND KIT'), findsOneWidget);
      expect(find.text('IMPORT .CAPBRAND'), findsOneWidget);

      expect(find.text('Viral Creator Hype'), findsOneWidget);
      expect(find.text('@viralcreator'), findsOneWidget);
      expect(find.text('Thought Leader & Podcast'), findsOneWidget);
      container.dispose();
    });

    testWidgets('search filters brand kits by name or handle', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      container.read(editorProvider.notifier).setProject(testProject);

      await tester.pumpWidget(buildTestApp(container));
      await tester.tap(find.text('Open Brand Kits'));
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'podcast');
      await tester.pumpAndSettle();

      expect(find.text('Thought Leader & Podcast'), findsOneWidget);
      expect(find.text('Viral Creator Hype'), findsNothing);
      container.dispose();
    });

    testWidgets('tapping APPLY applies brand kit styles to current project', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      container.read(editorProvider.notifier).setProject(testProject);

      await tester.pumpWidget(buildTestApp(container));
      await tester.tap(find.text('Open Brand Kits'));
      await tester.pumpAndSettle();

      // Tap the first APPLY button
      final applyButton = find.text('APPLY').first;
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('BRAND KITS & CREATOR IDENTITIES'), findsNothing);

      // Verify the controller received the brand kit styles
      final project = container.read(editorProvider).project;
      expect(project, isNotNull);
      expect(project!.config.style.fontFamily, equals('Outfit'));
      expect(project.config.highlightStyle.mainColor, equals('#F97316'));
      expect(project.config.highlightStyle.secondColor, equals('#06B6D4'));
      expect(project.config.highlightStyle.thirdColor, equals('#EC4899'));

      // Flush debounce timer
      await tester.pump(const Duration(seconds: 4));
      container.dispose();
    });
  });
}
