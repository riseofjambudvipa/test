import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/style_panel/color_picker_row.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/style_panel/color_settings_section.dart';
import '../../../../../../helpers/project_fixture.dart';
import '../../../../../../helpers/widget_helpers.dart';

Finder _greenPresetIn(ColorPickerRow row) {
  final target = const Color(0xFF22c55e);
  return find.descendant(
    of: find.byWidgetPredicate((w) => identical(w, row)),
    matching: find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.decoration is BoxDecoration &&
          (w.decoration as BoxDecoration).shape == BoxShape.circle &&
          (w.decoration as BoxDecoration).color == target,
    ),
  );
}

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
      ColorSettingsSection(config: makeConfig()),
      container: container,
    );
    return container;
  }

  group('ColorSettingsSection', () {
    testWidgets('renders section header and all four color rows', (tester) async {
      await pumpSection(tester);

      expect(find.text('CAPTION HIGHLIGHT COLORS'), findsOneWidget);
      expect(find.text('Highlight 1 (Active Word)'), findsOneWidget);
      expect(find.text('Highlight 2 (Emphasis 1)'), findsOneWidget);
      expect(find.text('Highlight 3 (Emphasis 2)'), findsOneWidget);
      expect(find.text('Base Subtitle Text Color'), findsOneWidget);
      expect(find.byType(ColorPickerRow), findsNWidgets(4));
    });

    testWidgets('selecting a highlight color updates highlightStyle.mainColor', (tester) async {
      final container = await pumpSection(tester);

      final firstRow = tester.widget<ColorPickerRow>(find.byType(ColorPickerRow).first);
      await tester.tap(_greenPresetIn(firstRow));

      final config = container.read(editorProvider).project!.config;
      expect(config.highlightStyle.mainColor, '#22c55e');
    });

    testWidgets('selecting a base text color updates style.color', (tester) async {
      final container = await pumpSection(tester);

      final baseRow = tester.widget<ColorPickerRow>(find.byType(ColorPickerRow).at(3));
      await tester.tap(_greenPresetIn(baseRow));

      final config = container.read(editorProvider).project!.config;
      expect(config.style.color, '#22c55e');
    });

    testWidgets('typing a hex into the base color field updates style.color', (tester) async {
      final container = await pumpSection(tester);

      // The 4th row's hex TextField.
      final baseField = find.descendant(
        of: find.byType(ColorPickerRow).at(3),
        matching: find.byType(TextField),
      );
      await tester.enterText(baseField, '112233');
      await tester.testTextInput.receiveAction(TextInputAction.done);

      expect(container.read(editorProvider).project!.config.style.color, '#112233');
    });

    testWidgets('rows render the current config colors in their fields', (tester) async {
      await pumpSection(tester);

      // makeConfig defaults: main #f97316, second #06b6d4, third #22c55e, style #ffffff.
      expect(find.text('F97316'), findsOneWidget);
      expect(find.text('06B6D4'), findsOneWidget);
      expect(find.text('22C55E'), findsOneWidget);
      expect(find.text('FFFFFF'), findsOneWidget);
    });
  });
}
