import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capstudio/features/editor/presentation/widgets/safe_zone_overlay.dart';
import 'package:capstudio/features/editor/presentation/widgets/editor_video_controls.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_state.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import '../../../../helpers/project_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SafeZonePlatform Enum Tests', () {
    test('all platforms have descriptive labels and shortLabels', () {
      expect(SafeZonePlatform.none.label, 'Guides: Off');
      expect(SafeZonePlatform.none.shortLabel, 'Off');

      expect(SafeZonePlatform.tikTok.label, contains('TikTok'));
      expect(SafeZonePlatform.tikTok.shortLabel, 'TikTok');

      expect(SafeZonePlatform.instagramReels.label, contains('Reels'));
      expect(SafeZonePlatform.instagramReels.shortLabel, 'Reels');

      expect(SafeZonePlatform.youTubeShorts.label, contains('Shorts'));
      expect(SafeZonePlatform.youTubeShorts.shortLabel, 'Shorts');

      expect(SafeZonePlatform.broadcastSafe.label, contains('Broadcast Safe'));
      expect(SafeZonePlatform.broadcastSafe.shortLabel, 'SMPTE');
    });
  });

  group('SafeZoneOverlay Widget Tests', () {
    testWidgets('renders SizedBox.shrink when platform is none', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeZoneOverlay(
              platform: SafeZonePlatform.none,
              videoWidth: 1080,
              videoHeight: 1920,
            ),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(SafeZoneOverlay),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
      expect(find.text('Off'), findsNothing);
    });

    testWidgets('renders CustomPaint, IgnorePointer, and badge for TikTok', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: SafeZoneOverlay(
                platform: SafeZonePlatform.tikTok,
                videoWidth: 1080,
                videoHeight: 1920,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(IgnorePointer), findsWidgets);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('TikTok'), findsOneWidget);
    });

    testWidgets('renders CustomPaint and badge for Instagram Reels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: SafeZoneOverlay(
                platform: SafeZonePlatform.instagramReels,
                videoWidth: 1080,
                videoHeight: 1920,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Reels'), findsOneWidget);
    });

    testWidgets('renders CustomPaint and badge for YouTube Shorts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: SafeZoneOverlay(
                platform: SafeZonePlatform.youTubeShorts,
                videoWidth: 1080,
                videoHeight: 1920,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('Shorts'), findsOneWidget);
    });

    testWidgets('renders CustomPaint and badge for Broadcast Safe', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              height: 640,
              child: SafeZoneOverlay(
                platform: SafeZonePlatform.broadcastSafe,
                videoWidth: 1920,
                videoHeight: 1080,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CustomPaint), findsWidgets);
      expect(find.text('SMPTE'), findsOneWidget);
    });
  });

  group('EditorVideoControls Safe Zone Picker Tests', () {
    testWidgets('displays Safe Zone Guides button and triggers callback on change', (tester) async {
      final project = makeProject(projectId: 'p_safe_zone', duration: 30.0);
      SafeZonePlatform? selectedPlatform;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              child: EditorVideoControls(
                project: project,
                currentTime: 5.0,
                isPlaying: false,
                volume: 1.0,
                isMuted: false,
                playbackRate: 1.0,
                isFullscreen: false,
                safeZoneGuide: SafeZonePlatform.none,
                onSafeZoneChanged: (p) {
                  selectedPlatform = p;
                },
                onTogglePlayback: () {},
                onSeek: (_) {},
                onSeekEnd: (_) {},
                onToggleMute: () {},
                onSetVolume: (_) {},
                onPlaybackRateChanged: (_) {},
                onToggleFullscreen: () {},
              ),
            ),
          ),
        ),
      );

      final guideFinder = find.byTooltip('Safe Zone Guides (TikTok, Reels, Shorts)');
      expect(guideFinder, findsOneWidget);

      await tester.tap(guideFinder);
      await tester.pumpAndSettle();

      expect(find.text('TikTok Safe Zone (9:16)'), findsOneWidget);
      expect(find.text('Reels Safe Zone (9:16)'), findsOneWidget);
      expect(find.text('YouTube Shorts (9:16)'), findsOneWidget);

      await tester.tap(find.text('TikTok Safe Zone (9:16)'));
      await tester.pumpAndSettle();

      expect(selectedPlatform, SafeZonePlatform.tikTok);
    });
  });

  group('EditorController Safe Zone State Integration', () {
    test('EditorState.copyWith updates safeZoneGuide', () {
      const state = EditorState();
      expect(state.safeZoneGuide, SafeZonePlatform.none);

      final updated = state.copyWith(safeZoneGuide: SafeZonePlatform.youTubeShorts);
      expect(updated.safeZoneGuide, SafeZonePlatform.youTubeShorts);
    });

    test('EditorController.setSafeZoneGuide updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(editorProvider.notifier);
      expect(container.read(editorProvider).safeZoneGuide, SafeZonePlatform.none);

      controller.setSafeZoneGuide(SafeZonePlatform.tikTok);
      expect(container.read(editorProvider).safeZoneGuide, SafeZonePlatform.tikTok);

      controller.setSafeZoneGuide(SafeZonePlatform.none);
      expect(container.read(editorProvider).safeZoneGuide, SafeZonePlatform.none);
    });
  });
}
