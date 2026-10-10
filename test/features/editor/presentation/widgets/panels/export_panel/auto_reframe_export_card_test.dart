import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/app/theme.dart';
import 'package:capstudio/core/video/viral_clip_models.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/export_panel/auto_reframe_export_card.dart';

void main() {
  group('AutoReframeExportCard Tests', () {
    testWidgets('renders all reframe options for landscape projects and triggers callbacks',
        (tester) async {
      AspectConversionMode? selectedMode;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: AutoReframeExportCard(
                    selectedMode: selectedMode,
                    onModeChanged: (mode) {
                      setState(() {
                        selectedMode = mode;
                      });
                    },
                    isLandscapeProject: true,
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Verify title & badges
      expect(find.text('Export 9:16 Vertical Reframe'), findsOneWidget);
      expect(find.text('AI AUTO-FRAME'), findsOneWidget);

      // Verify landscape option is present
      expect(find.text('Original Canvas (16:9 Landscape)'), findsOneWidget);
      expect(find.text('Blur Pillarbox (Recommended)'), findsOneWidget);
      expect(find.text('Center Smart Crop'), findsOneWidget);
      expect(find.text('AI Smart Face Track (OpusClip)'), findsOneWidget);
      expect(find.text('Split Screen / Dual Layer'), findsOneWidget);

      // Tap Blur Pillarbox
      await tester.tap(find.text('Blur Pillarbox (Recommended)'));
      await tester.pumpAndSettle();
      expect(selectedMode, AspectConversionMode.blurPillarbox);

      // Tap Center Smart Crop
      await tester.tap(find.text('Center Smart Crop'));
      await tester.pumpAndSettle();
      expect(selectedMode, AspectConversionMode.centerCrop);

      // Tap AI Smart Face Track
      await tester.tap(find.text('AI Smart Face Track (OpusClip)'));
      await tester.pumpAndSettle();
      expect(selectedMode, AspectConversionMode.smartFaceTrack);

      // Tap Split Screen
      await tester.tap(find.text('Split Screen / Dual Layer'));
      await tester.pumpAndSettle();
      expect(selectedMode, AspectConversionMode.splitScreen);

      // Tap Original Canvas to reset back to null
      await tester.tap(find.text('Original Canvas (16:9 Landscape)'));
      await tester.pumpAndSettle();
      expect(selectedMode, isNull);
    });

    testWidgets('omits original canvas tile for vertical 9:16 projects',
        (tester) async {
      AspectConversionMode? selectedMode = AspectConversionMode.blurPillarbox;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.darkTheme,
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SingleChildScrollView(
                  child: AutoReframeExportCard(
                    selectedMode: selectedMode,
                    onModeChanged: (mode) {
                      setState(() {
                        selectedMode = mode;
                      });
                    },
                    isLandscapeProject: false,
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Title should be 'Vertical Reframe Mode'
      expect(find.text('Vertical Reframe Mode'), findsOneWidget);
      // Original 16:9 canvas option should NOT be present
      expect(find.text('Original Canvas (16:9 Landscape)'), findsNothing);

      // 4 vertical reframe modes should be present
      expect(find.text('Blur Pillarbox (Recommended)'), findsOneWidget);
      expect(find.text('Center Smart Crop'), findsOneWidget);
      expect(find.text('AI Smart Face Track (OpusClip)'), findsOneWidget);
      expect(find.text('Split Screen / Dual Layer'), findsOneWidget);
    });
  });
}
