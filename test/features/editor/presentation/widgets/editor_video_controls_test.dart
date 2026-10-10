import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/features/editor/presentation/widgets/editor_video_controls.dart';
import 'package:capstudio/features/editor/presentation/widgets/safe_zone_overlay.dart';
import '../../../../helpers/project_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testProject = makeProject(
    projectId: 'p_controls_test',
    duration: 60.0,
  );

  Widget buildTestableControls({
    double currentTime = 15.0,
    bool isPlaying = false,
    double volume = 1.0,
    bool isMuted = false,
    double playbackRate = 1.0,
    bool isFullscreen = false,
    SafeZonePlatform safeZoneGuide = SafeZonePlatform.none,
    bool isProxyActive = false,
    bool isGeneratingProxy = false,
    double proxyProgress = 0.0,
    VoidCallback? onToggleProxy,
    VoidCallback? onTogglePlayback,
    ValueChanged<double>? onSeek,
    ValueChanged<double>? onSeekEnd,
    VoidCallback? onToggleMute,
    ValueChanged<double>? onSetVolume,
    ValueChanged<double>? onPlaybackRateChanged,
    VoidCallback? onToggleFullscreen,
    ValueChanged<SafeZonePlatform>? onSafeZoneChanged,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 800,
            child: EditorVideoControls(
              project: testProject,
              currentTime: currentTime,
              isPlaying: isPlaying,
              volume: volume,
              isMuted: isMuted,
              playbackRate: playbackRate,
              isFullscreen: isFullscreen,
              safeZoneGuide: safeZoneGuide,
              isProxyActive: isProxyActive,
              isGeneratingProxy: isGeneratingProxy,
              proxyProgress: proxyProgress,
              onToggleProxy: onToggleProxy ?? () {},
              onTogglePlayback: onTogglePlayback ?? () {},
              onSeek: onSeek ?? (_) {},
              onSeekEnd: onSeekEnd ?? (_) {},
              onToggleMute: onToggleMute ?? () {},
              onSetVolume: onSetVolume ?? (_) {},
              onPlaybackRateChanged: onPlaybackRateChanged ?? (_) {},
              onToggleFullscreen: onToggleFullscreen ?? () {},
              onSafeZoneChanged: onSafeZoneChanged,
            ),
          ),
        ),
      ),
    );
  }

  group('EditorVideoControls Playback & Time Display Tests', () {
    testWidgets('displays play icon when paused and pause icon when playing', (tester) async {
      await tester.pumpWidget(buildTestableControls(isPlaying: false));
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.pause_rounded), findsNothing);

      await tester.pumpWidget(buildTestableControls(isPlaying: true));
      expect(find.byIcon(Icons.pause_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('tapping play button triggers onTogglePlayback', (tester) async {
      bool toggled = false;
      await tester.pumpWidget(
        buildTestableControls(
          isPlaying: false,
          onTogglePlayback: () => toggled = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.play_arrow_rounded));
      await tester.pump();
      expect(toggled, isTrue);
    });

    testWidgets('displays formatted current time and duration', (tester) async {
      await tester.pumpWidget(buildTestableControls(currentTime: 15.0));
      expect(find.text('00:15 / 01:00'), findsOneWidget);
    });
  });

  group('EditorVideoControls 4K Proxy Pipeline Tests', () {
    testWidgets('displays flash_off icon with original media tooltip when proxy is inactive', (tester) async {
      bool proxyToggled = false;
      await tester.pumpWidget(
        buildTestableControls(
          isProxyActive: false,
          isGeneratingProxy: false,
          onToggleProxy: () => proxyToggled = true,
        ),
      );

      final proxyButton = find.byTooltip('Original Media — Tap to Generate/Switch to 720p Proxy');
      expect(proxyButton, findsOneWidget);
      expect(find.byIcon(Icons.flash_off_rounded), findsOneWidget);

      await tester.tap(proxyButton);
      await tester.pump();
      expect(proxyToggled, isTrue);
    });

    testWidgets('displays flash_on icon with fluid 60fps tooltip when proxy is active', (tester) async {
      bool proxyToggled = false;
      await tester.pumpWidget(
        buildTestableControls(
          isProxyActive: true,
          isGeneratingProxy: false,
          onToggleProxy: () => proxyToggled = true,
        ),
      );

      final proxyButton = find.byTooltip('Proxy Active (Fluid 60fps) — Tap for Original Media');
      expect(proxyButton, findsOneWidget);
      expect(find.byIcon(Icons.flash_on_rounded), findsOneWidget);

      await tester.tap(proxyButton);
      await tester.pump();
      expect(proxyToggled, isTrue);
    });

    testWidgets('displays circular progress indicator during proxy generation', (tester) async {
      await tester.pumpWidget(
        buildTestableControls(
          isProxyActive: false,
          isGeneratingProxy: true,
          proxyProgress: 0.45,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byIcon(Icons.flash_off_rounded), findsNothing);
      expect(find.byIcon(Icons.flash_on_rounded), findsNothing);
    });
  });

  group('EditorVideoControls Volume & Playback Rate Tests', () {
    testWidgets('displays volume_up icon when unmuted and volume_off when muted', (tester) async {
      await tester.pumpWidget(buildTestableControls(isMuted: false, volume: 0.8));
      expect(find.byIcon(Icons.volume_up), findsOneWidget);

      await tester.pumpWidget(buildTestableControls(isMuted: true));
      expect(find.byIcon(Icons.volume_off), findsOneWidget);
    });

    testWidgets('playback speed selector opens popup with rate choices', (tester) async {
      double? selectedRate;
      await tester.pumpWidget(
        buildTestableControls(
          playbackRate: 1.0,
          onPlaybackRateChanged: (rate) => selectedRate = rate,
        ),
      );

      final speedButton = find.byTooltip('Playback Speed');
      expect(speedButton, findsOneWidget);

      await tester.tap(speedButton);
      await tester.pumpAndSettle();

      expect(find.text('0.5x'), findsOneWidget);
      expect(find.text('2.0x'), findsOneWidget);

      await tester.tap(find.text('1.5x'));
      await tester.pumpAndSettle();
      expect(selectedRate, equals(1.5));
    });
  });
}
