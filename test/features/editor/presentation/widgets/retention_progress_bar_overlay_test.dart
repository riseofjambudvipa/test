import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/video/retention_progress_bar_models.dart';
import 'package:capstudio/features/editor/presentation/widgets/retention_progress_bar_overlay.dart';

void main() {
  group('RetentionProgressBarOverlay Widget Tests', () {
    testWidgets('Renders SizedBox.shrink when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                RetentionProgressBarOverlay(
                  currentTime: 5.0,
                  duration: 20.0,
                  config: RetentionProgressBarConfig(enabled: false),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(FractionallySizedBox), findsNothing);
    });

    testWidgets('Renders FractionallySizedBox with correct progress when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                RetentionProgressBarOverlay(
                  currentTime: 10.0,
                  duration: 20.0,
                  config: RetentionProgressBarConfig(
                    enabled: true,
                    color: '#f97316',
                    height: 8.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final fractionalBox = tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
      expect(fractionalBox.widthFactor, 0.5); // 10 / 20 = 0.5
    });

    testWidgets('Clamps progress to 1.0 when currentTime exceeds duration', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                RetentionProgressBarOverlay(
                  currentTime: 25.0,
                  duration: 20.0,
                  config: RetentionProgressBarConfig(
                    enabled: true,
                    color: '#06b6d4',
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final fractionalBox = tester.widget<FractionallySizedBox>(find.byType(FractionallySizedBox));
      expect(fractionalBox.widthFactor, 1.0);
    });
  });
}
