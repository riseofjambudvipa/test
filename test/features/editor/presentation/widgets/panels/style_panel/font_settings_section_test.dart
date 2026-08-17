import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/style_panel/font_settings_section.dart';
import '../../../../../../helpers/project_fixture.dart';
import '../../../../../../helpers/widget_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    // EditorController._autoSave reads SettingsService; init it with autosave
    // off so style updates don't schedule pending timers in tests.
    SharedPreferences.setMockInitialValues({'auto_save_enabled': false});
    await SettingsService.instance.init();
  });

  Future<ProviderContainer> pumpSection(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorProvider.notifier).setProject(makeProject());
    await pumpTestWidget(
      tester,
      FontSettingsSection(config: makeConfig()),
      container: container,
    );
    return container;
  }

  group('FontSettingsSection', () {
    testWidgets('renders header, dropdowns, import button and sliders', (tester) async {
      await pumpSection(tester);

      expect(find.text('FONT CONFIGURATION'), findsOneWidget);
      expect(find.text('Font Family'), findsOneWidget);
      expect(find.text('Font Weight'), findsOneWidget);
      expect(find.text('Text Case'), findsOneWidget);
      expect(find.textContaining('IMPORT CUSTOM FONT'), findsOneWidget);
      expect(find.text('Font Size'), findsOneWidget);
      expect(find.text('Letter Spacing'), findsOneWidget);
      expect(find.text('Line Height'), findsOneWidget);
      expect(find.byType(Slider), findsNWidgets(3));
    });

    testWidgets('changing the font family updates config.style.fontFamily', (tester) async {
      final container = await pumpSection(tester);

      await tester.tap(find.text('Montserrat').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Anton').last);
      await tester.pumpAndSettle();

      expect(container.read(editorProvider).project!.config.style.fontFamily, 'Anton');
    });

    testWidgets('changing font weight updates config.style.fontWeight', (tester) async {
      final container = await pumpSection(tester);

      await tester.tap(find.text('Black').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Extra Bold').last);
      await tester.pumpAndSettle();

      expect(container.read(editorProvider).project!.config.style.fontWeight, '800');
    });

    testWidgets('changing text case updates config.style.textTransform', (tester) async {
      final container = await pumpSection(tester);

      await tester.tap(find.text('UPPERCASE').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Capitalize').last);
      await tester.pumpAndSettle();

      expect(container.read(editorProvider).project!.config.style.textTransform, 'capitalize');
    });

    testWidgets('dragging the font size slider increases style.fontSize', (tester) async {
      final container = await pumpSection(tester);
      final before = container.read(editorProvider).project!.config.style.fontSize;

      await tester.drag(find.byType(Slider).first, const Offset(80, 0));
      await tester.pumpAndSettle();

      final after = container.read(editorProvider).project!.config.style.fontSize;
      expect(after, greaterThan(before));
      expect(after, lessThanOrEqualTo(72.0));
    });

    testWidgets('renders the current font weight and size values', (tester) async {
      await pumpSection(tester);

      // makeConfig: fontWeight '900', fontSize 42.0 (displayed as "42").
      expect(find.text('Black'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });
  });
}
