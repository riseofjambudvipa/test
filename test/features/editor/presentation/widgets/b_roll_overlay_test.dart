import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/video/b_roll_models.dart';
import 'package:capstudio/features/editor/presentation/widgets/b_roll_overlay.dart';
import '../../../../test_environment.dart';

void main() {
  registerTestEnvironment(silenceLogs: true);

  group('BRollOverlay Widget Tests', () {
    const cutawayClip = BRollClip(
      id: 'clip_cutaway',
      mediaPath: 'test_cutaway.mp4',
      name: 'broll_cutaway.mp4',
      startTime: 2.0,
      endTime: 5.0,
      isPictureInPicture: false,
    );

    const pipClip = BRollClip(
      id: 'clip_pip',
      mediaPath: 'test_pip.mp4',
      name: 'reaction_pip.mp4',
      startTime: 6.0,
      endTime: 9.0,
      isPictureInPicture: true,
      pipPosition: 'top_right',
    );

    testWidgets('renders empty when currentTime is outside clip bounds',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                BRollOverlay(
                  currentTime: 1.0,
                  bRollClips: [cutawayClip, pipClip],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('B-ROLL CUTAWAY'), findsNothing);
      expect(find.text('PiP'), findsNothing);
    });

    testWidgets('renders Fullscreen Cutaway when within cutaway clip timestamp',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                BRollOverlay(
                  currentTime: 3.5,
                  bRollClips: [cutawayClip, pipClip],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('B-ROLL CUTAWAY: broll_cutaway.mp4'), findsOneWidget);
      expect(find.byIcon(Icons.video_library), findsOneWidget);
    });

    testWidgets('renders Picture-in-Picture window when within PiP clip timestamp',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                BRollOverlay(
                  currentTime: 7.5,
                  bRollClips: [cutawayClip, pipClip],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PiP'), findsOneWidget);
      expect(find.byIcon(Icons.picture_in_picture_alt), findsOneWidget);
      expect(find.text('reaction_pip.mp4'), findsOneWidget);
    });
  });
}
