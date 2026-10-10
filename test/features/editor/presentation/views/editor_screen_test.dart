import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import 'package:capstudio/core/audio/audio_service.dart';
import 'package:capstudio/features/editor/presentation/views/editor_screen.dart';
import 'package:capstudio/features/editor/presentation/widgets/editor_header_bar.dart';
import 'package:capstudio/core/assets/asset_manifest.dart';
import 'package:capstudio/core/assets/asset_verification_service.dart';
import 'package:capstudio/core/emoji/emoji_service.dart';
import '../../../../test_environment.dart';
import '../../../../helpers/project_fixture.dart';
import '../../../../mocks/mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(Project());
  });

  registerTestEnvironment(silenceLogs: true);

  final mockManifest = AssetManifest(version: '2.0', packs: [], emojis: []);
  const mockVerification = AssetVerificationResult(
    allRequiredPresent: true,
    missing: [],
    installedPackIds: [],
    hasAnyEmojis: true,
  );

  late Project testProject;
  late MockIsarService mockIsar;

  setUp(() {
    // Pre-populate AudioService to bypass Dynamic synthesis I/O in tests
    for (int i = 0; i < 44; i++) {
      AudioService.instance.registerSfx('sfx_$i', 'dummy_path');
    }

    // Pre-populate EmojiService to bypass metadata loading in tests
    EmojiService.instance.setEmojisForTesting([
      const EmojiModel(
        unicode: '1f381',
        glyph: '🎁',
        name: 'wrapped gift',
        keywords: ['gift', 'present', 'box', 'wrapped'],
        group: 'Activities',
        styles: {'googleNonAnimated': 'gift.png'},
        shortcodes: ['gift'],
      ),
    ]);

    mockIsar = MockIsarService();
    IsarService.instance = mockIsar;
    when(() => mockIsar.isInitialized).thenReturn(true);
    when(() => mockIsar.init()).thenAnswer((_) async {});
    when(() => mockIsar.saveProject(any())).thenAnswer((_) async {});

    testProject = makeProject(
      projectId: 'proj_test_456',
      name: 'Widget Test Project',
      videoPath: p.join(AppDirs.support, 'test.mp4'),
      duration: 10.0,
      width: 1920,
      height: 1080,
      trimStart: 0.0,
      trimEnd: 10.0,
      status: 'draft',
      config: makeConfig(
        name: 'default',
        fontFamily: 'Montserrat',
        fontWeight: '900',
        textTransform: 'uppercase',
        color: '#ffffff',
        fontSize: 24.0,
        top: 70.0,
      ),
      words: [],
    );
  });

  tearDown(() {
    // IsarService instance and EmojiService are automatically reset by registerTestEnvironment
  });

  testWidgets('EditorScreen shows error when project not found in database', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockIsar.getProject('proj_test_456')).thenAnswer((_) async => null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
          assetVerificationProvider.overrideWith((ref) => AssetVerificationNotifier(mockVerification)),
        ],
        child: const MaterialApp(
          home: EditorScreen(projectId: 'proj_test_456'),
        ),
      ),
    );

    // Wait for async project loading to complete
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify error message is rendered
    expect(find.text('Project not found in database.'), findsOneWidget);
  });

  testWidgets('EditorScreen shows error when video file does not exist', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockIsar.getProject('proj_test_456')).thenAnswer((_) async => testProject);

    // Ensure the video file path does NOT exist
    final file = File(testProject.videoPath);
    if (file.existsSync()) {
      file.deleteSync();
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
          assetVerificationProvider.overrideWith((ref) => AssetVerificationNotifier(mockVerification)),
        ],
        child: const MaterialApp(
          home: EditorScreen(projectId: 'proj_test_456'),
        ),
      ),
    );

    // Pump to trigger async load sequence
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // Verify friendly video file missing error is rendered
    expect(find.textContaining('Video file not found'), findsOneWidget);
  });

  testWidgets('EditorScreen renders header bar and main layout when project and video exist', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockIsar.getProject('proj_test_456')).thenAnswer((_) async => testProject);

    // Create the dummy video file to satisfy the exists check
    final file = File(testProject.videoPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('dummy_video_bytes');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
          assetVerificationProvider.overrideWith((ref) => AssetVerificationNotifier(mockVerification)),
        ],
        child: const MaterialApp(
          home: EditorScreen(projectId: 'proj_test_456'),
        ),
      ),
    );

    // Pump to trigger loading
    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    // Should successfully render the Editor screen layout
    expect(find.byType(EditorHeaderBar), findsOneWidget);
    expect(find.text('Widget Test Project'), findsOneWidget);
  });

  testWidgets('EditorScreen renders on narrow desktop window (< 600px) without clamp ArgumentError', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockIsar.getProject('proj_test_456')).thenAnswer((_) async => testProject);

    final file = File(testProject.videoPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('dummy_video_bytes');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
          assetVerificationProvider.overrideWith((ref) => AssetVerificationNotifier(mockVerification)),
        ],
        child: const MaterialApp(
          home: EditorScreen(projectId: 'proj_test_456'),
        ),
      ),
    );

    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.byType(EditorHeaderBar), findsOneWidget);
  });

  testWidgets('EditorScreen renders on mobile landscape (< 711px) without clamp ArgumentError', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(667, 375);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockIsar.getProject('proj_test_456')).thenAnswer((_) async => testProject);

    final file = File(testProject.videoPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('dummy_video_bytes');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
          assetVerificationProvider.overrideWith((ref) => AssetVerificationNotifier(mockVerification)),
        ],
        child: const MaterialApp(
          home: EditorScreen(projectId: 'proj_test_456'),
        ),
      ),
    );

    await tester.pump();
    await tester.runAsync(() async {
      await Future.delayed(const Duration(milliseconds: 300));
    });
    await tester.pump();

    expect(find.byType(EditorHeaderBar), findsOneWidget);
  });
}
