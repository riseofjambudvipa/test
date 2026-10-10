import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/style_panel/position_settings_section.dart';
import '../../../../../../helpers/project_fixture.dart';
import '../../../../../../helpers/widget_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'auto_save_enabled': false});
    await SettingsService.instance.init();
  });

  Future<ProviderContainer> pumpSection(
    WidgetTester tester, {
    double top = 50.0,
    double left = 50.0,
    bool highlightBackground = false,
    int chunkSize = 3,
    int chunkLineMaxLength = 20,
  }) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final config = makeConfig(
      top: top,
      highlightBackground: highlightBackground,
      chunkSize: chunkSize,
      chunkLineMaxLength: chunkLineMaxLength,
    );
    config.style.left = left;

    container.read(editorProvider.notifier).setProject(
      makeProject(config: config),
    );

    await pumpTestWidget(
      tester,
      PositionSettingsSection(config: config),
      container: container,
    );
    return container;
  }

  group('PositionSettingsSection', () {
    testWidgets('renders all section controls', (tester) async {
      await pumpSection(tester);

      expect(find.text('SIZE & POSITION'), findsOneWidget);
      expect(find.text('Vertical Y Position (%)'), findsOneWidget);
      expect(find.text('Horizontal X Position (%)'), findsOneWidget);
      expect(find.text('Left (20%)'), findsOneWidget);
      expect(find.text('Center (50%)'), findsOneWidget);
      expect(find.text('Right (80%)'), findsOneWidget);
      expect(find.text('Word Highlight Box'), findsOneWidget);
      expect(find.text('Max Words per Subtitle Chunk'), findsOneWidget);
      expect(find.text('Max Characters per Subtitle Line'), findsOneWidget);
    });

    testWidgets('tapping quick alignment buttons updates style.left', (tester) async {
      final container = await pumpSection(tester, left: 50.0);

      // Tap Left (20%)
      await tester.tap(find.text('Left (20%)'));
      await tester.pumpAndSettle();
      expect(container.read(editorProvider).project!.config.style.left, equals(20.0));

      // Tap Right (80%)
      await tester.tap(find.text('Right (80%)'));
      await tester.pumpAndSettle();
      expect(container.read(editorProvider).project!.config.style.left, equals(80.0));

      // Tap Center (50%)
      await tester.tap(find.text('Center (50%)'));
      await tester.pumpAndSettle();
      expect(container.read(editorProvider).project!.config.style.left, equals(50.0));
    });

    testWidgets('toggling Word Highlight Box switch updates highlightBackground', (tester) async {
      final container = await pumpSection(tester, highlightBackground: false);

      expect(container.read(editorProvider).project!.config.style.highlightBackground, isFalse);

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      expect(container.read(editorProvider).project!.config.style.highlightBackground, isTrue);
    });
  });
}
