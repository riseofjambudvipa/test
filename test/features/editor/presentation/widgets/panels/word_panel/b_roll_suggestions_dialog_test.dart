import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/core/video/b_roll_models.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/word_panel/b_roll_suggestions_dialog.dart';
import '../../../../../../test_environment.dart';

void main() {
  registerTestEnvironment(silenceLogs: true);

  testWidgets('BRollSuggestionsDialog renders AI Cues and Attached Overlays tabs', (tester) async {
    final words = [
      WordSchema()
        ..wordId = 'w1'
        ..text = 'We'
        ..start = 0.0
        ..end = 0.4,
      WordSchema()
        ..wordId = 'w2'
        ..text = 'launched'
        ..start = 0.5
        ..end = 0.9,
      WordSchema()
        ..wordId = 'w3'
        ..text = 'a'
        ..start = 1.0
        ..end = 1.2,
      WordSchema()
        ..wordId = 'w4'
        ..text = 'rocket'
        ..start = 1.3
        ..end = 1.8,
    ];

    final project = Project()
      ..projectId = 'test_proj'
      ..name = 'Test Video'
      ..videoPath = 'test.mp4'
      ..duration = 5.0
      ..words = words;

    const attachedClip = BRollClip(
      id: 'clip_1',
      mediaPath: 'rocket_launch.mp4',
      name: 'rocket_launch.mp4',
      startTime: 1.0,
      endTime: 3.5,
      isPictureInPicture: false,
    );

    String? removedClipId;
    BRollClip? updatedClip;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BRollSuggestionsDialog(
            project: project,
            activeClips: const [attachedClip],
            onRemoveClip: (id) => removedClipId = id,
            onUpdateClip: (clip) => updatedClip = clip,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify dialog header
    expect(find.text('AI B-ROLL STUDIO'), findsOneWidget);

    // Verify tabs
    expect(find.textContaining('AI CUES'), findsOneWidget);
    expect(find.textContaining('ATTACHED OVERLAYS (1)'), findsOneWidget);

    // AI Cues detected 'rocket' with category 'GROWTH'
    expect(find.textContaining('GROWTH'), findsOneWidget);
    expect(find.textContaining('rocket'), findsOneWidget);

    // Switch to Attached Overlays tab
    await tester.tap(find.textContaining('ATTACHED OVERLAYS'));
    await tester.pumpAndSettle();

    // Verify attached clip card
    expect(find.text('rocket_launch.mp4'), findsOneWidget);
    expect(find.text('1.0s - 3.5s'), findsOneWidget);
    expect(find.text('Fullscreen Cutaway'), findsOneWidget);
    expect(find.text('Picture-in-Picture (PiP)'), findsOneWidget);

    // Switch mode to PiP
    await tester.tap(find.text('Picture-in-Picture (PiP)'));
    await tester.pumpAndSettle();
    expect(updatedClip, isNotNull);
    expect(updatedClip!.isPictureInPicture, isTrue);

    // Verify corner selector chips
    expect(find.text('Top-R'), findsOneWidget);
    expect(find.text('Top-L'), findsOneWidget);

    // Remove the clip
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();
    expect(removedClipId, equals('clip_1'));
  });
}
