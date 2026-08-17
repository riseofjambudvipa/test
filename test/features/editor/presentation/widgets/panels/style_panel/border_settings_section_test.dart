import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/style_panel/border_settings_section.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/style_panel/color_picker_row.dart';
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

  Future<ProviderContainer> pumpSection(
    WidgetTester tester, {
    String? background,
  }) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorProvider.notifier).setProject(
      makeProject(config: makeConfig(background: background)),
    );
    await pumpTestWidget(
      tester,
      BorderSettingsSection(config: makeConfig(background: background)),
      container: container,
    );
    return container;
  }

  // Opens a DropdownButtonFormField and selects the menu item with [label].
  Future<void> selectDropdown(WidgetTester tester, String currentLabel, String label) async {
    await tester.tap(find.text(currentLabel).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  group('BorderSettingsSection', () {
    testWidgets('renders header and all three dropdowns', (tester) async {
      await pumpSection(tester);

      expect(find.text('OUTLINES & EFFECTS'), findsOneWidget);
      expect(find.text('Outline Stroke'), findsOneWidget);
      expect(find.text('Active Word Animation'), findsOneWidget);
      expect(find.text('Drop Shadow'), findsOneWidget);
      expect(find.byType(ColorPickerRow), findsOneWidget);
    });

    testWidgets('changing outline stroke updates config.stroke', (tester) async {
      final container = await pumpSection(tester);

      await selectDropdown(tester, 'Thick Outline', 'None (Flat)');

      expect(container.read(editorProvider).project!.config.stroke, 'none');
    });

    testWidgets('changing animation updates config.animation', (tester) async {
      final container = await pumpSection(tester);

      await selectDropdown(tester, 'Active Pop', 'Active Bounce Jump');

      expect(container.read(editorProvider).project!.config.animation, 'bounce');
    });

    testWidgets('changing drop shadow updates config.shadow', (tester) async {
      final container = await pumpSection(tester);

      // makeConfig defaults shadow to 'none'.
      await selectDropdown(tester, 'None', 'Soft Shadow');

      expect(container.read(editorProvider).project!.config.shadow, 'soft');
    });

    testWidgets('selecting a background color updates config.background', (tester) async {
      final container = await pumpSection(tester);

      final row = tester.widget<ColorPickerRow>(find.byType(ColorPickerRow).first);
      final green = find.descendant(
        of: find.byWidgetPredicate((w) => identical(w, row)),
        matching: find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).shape == BoxShape.circle &&
              (w.decoration as BoxDecoration).color == const Color(0xFF22c55e),
        ),
      );
      await tester.tap(green);

      expect(container.read(editorProvider).project!.config.background, '#22c55e');
    });

    testWidgets('with a background set, the remove button clears it', (tester) async {
      final container = await pumpSection(tester, background: '#000000');

      expect(find.text('REMOVE BACKGROUND FILL'), findsOneWidget);
      await tester.tap(find.text('REMOVE BACKGROUND FILL'));
      await tester.pumpAndSettle();

      expect(container.read(editorProvider).project!.config.background, isNull);
    });

    testWidgets('without a background, no remove button is shown', (tester) async {
      await pumpSection(tester);

      expect(find.text('REMOVE BACKGROUND FILL'), findsNothing);
    });
  });
}
