import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/video/viral_clip_models.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/viral_clipping_panel.dart';
import '../../../../../helpers/widget_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('BatchExportSheet renders title, controls, candidates and export button', (tester) async {
    final project = Project()
      ..projectId = 'proj_test_batch'
      ..name = 'Viral Clips Project'
      ..width = 1920
      ..height = 1080
      ..duration = 60.0;

    final candidates = [
      ViralClipCandidate(
        id: 'clip_1',
        start: 0.0,
        end: 15.0,
        duration: 15.0,
        score: 85.0,
        hookText: 'Did you know',
        summary: 'Best Hook Moment',
        wordCount: 30,
        wordsPerMinute: 120.0,
        hookScore: 35.0,
        energyScore: 18.0,
        wpmScore: 16.0,
        hookInFirstFive: true,
        questionCount: 1,
      ),
      ViralClipCandidate(
        id: 'clip_2',
        start: 20.0,
        end: 40.0,
        duration: 20.0,
        score: 72.0,
        hookText: 'Here is the trick',
        summary: 'Insightful Explanation',
        wordCount: 45,
        wordsPerMinute: 135.0,
        hookScore: 28.0,
        energyScore: 14.0,
        wpmScore: 15.0,
        hookInFirstFive: false,
        questionCount: 0,
      ),
    ];

    await pumpTestWidget(
      tester,
      Scaffold(
        body: BatchExportSheet(
          candidates: candidates,
          project: project,
          conversionMode: AspectConversionMode.centerCrop,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify title with total count
    expect(find.textContaining('BATCH EXPORT 2 CLIP(S)'), findsOneWidget);

    // Verify output directory picker hint
    expect(find.textContaining('Tap to choose output folder'), findsOneWidget);

    // Verify burn subtitles switch
    expect(find.textContaining('Burn Dynamic Captions on Clips'), findsOneWidget);

    // Verify candidates are listed by their hookText
    expect(find.textContaining('Did you know'), findsOneWidget);
    expect(find.textContaining('Here is the trick'), findsOneWidget);

    // Verify start export button
    expect(find.textContaining('START EXPORT'), findsOneWidget);
  });
}
