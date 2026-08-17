import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/style_panel/color_picker_row.dart';
import '../../../../../../helpers/widget_helpers.dart';

// Finds the preset swatch circle for a given hex (unique among the 9 presets).
Finder presetCircle(String hex) {
  final target = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  return find.byWidgetPredicate(
    (w) =>
        w is Container &&
        w.decoration is BoxDecoration &&
        (w.decoration as BoxDecoration).shape == BoxShape.circle &&
        (w.decoration as BoxDecoration).color == target,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ColorPickerRow', () {
    testWidgets('renders label and hex value uppercased without the # prefix', (tester) async {
      await pumpTestWidget(
        tester,
        ColorPickerRow(
          label: 'Test Color',
          currentHex: '#f97316',
          onColorSelected: (_) {},
        ),
      );

      expect(find.text('Test Color'), findsOneWidget);
      expect(find.text('F97316'), findsOneWidget);
      // The swatch color parses the current hex.
      final swatch = find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).color == const Color(0xFFf97316),
      );
      expect(swatch, findsWidgets);
    });

    testWidgets('tapping a preset swatch fires onColorSelected with that hex', (tester) async {
      final selected = <String>[];
      await pumpTestWidget(
        tester,
        ColorPickerRow(
          label: 'Test Color',
          currentHex: '#f97316',
          onColorSelected: selected.add,
        ),
      );

      await tester.tap(presetCircle('#22c55e'));
      expect(selected, ['#22c55e']);
    });

    testWidgets('submitting a valid 6-digit hex fires onColorSelected with # prefix', (tester) async {
      final selected = <String>[];
      await pumpTestWidget(
        tester,
        ColorPickerRow(
          label: 'Test Color',
          currentHex: '#f97316',
          onColorSelected: selected.add,
        ),
      );

      await tester.enterText(find.byType(TextField), '112233');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(selected, ['#112233']);
    });

    testWidgets('submitting an invalid hex does not fire the callback', (tester) async {
      final selected = <String>[];
      await pumpTestWidget(
        tester,
        ColorPickerRow(
          label: 'Test Color',
          currentHex: '#f97316',
          onColorSelected: selected.add,
        ),
      );

      await tester.enterText(find.byType(TextField), 'xyz12');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(selected, isEmpty);
    });

    testWidgets('submitting a short hex does not fire the callback', (tester) async {
      final selected = <String>[];
      await pumpTestWidget(
        tester,
        ColorPickerRow(
          label: 'Test Color',
          currentHex: '#f97316',
          onColorSelected: selected.add,
        ),
      );

      await tester.enterText(find.byType(TextField), 'fff');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      expect(selected, isEmpty);
    });

    testWidgets('updates the field when currentHex changes (didUpdateWidget)', (tester) async {
      // Re-pumping with the same tree shape preserves State, exercising
      // didUpdateWidget's hex re-sync.
      await pumpTestWidget(
        tester,
        ColorPickerRow(
          label: 'Test Color',
          currentHex: '#f97316',
          onColorSelected: (_) {},
        ),
      );
      expect(find.text('F97316'), findsOneWidget);

      await pumpTestWidget(
        tester,
        ColorPickerRow(
          label: 'Test Color',
          currentHex: '#22c55e',
          onColorSelected: (_) {},
        ),
      );
      expect(find.text('22C55E'), findsOneWidget);
      expect(find.text('F97316'), findsNothing);
    });
  });
}
