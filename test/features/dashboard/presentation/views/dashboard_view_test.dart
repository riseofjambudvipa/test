import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/features/dashboard/presentation/views/dashboard_screen.dart';
import 'package:capstudio/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import 'package:capstudio/core/assets/asset_manifest.dart';
import 'package:capstudio/core/assets/asset_verification_service.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../../helpers/widget_helpers.dart';
import '../../../../helpers/project_fixture.dart';

class TestDashboardController extends DashboardController {
  TestDashboardController(DashboardState initialState) : super() {
    state = initialState;
  }

  @override
  Future<void> loadProjects() async {
    // No-op to prevent loading from Isar
  }

  @override
  Future<void> deleteProject(String projectId) async {
    // No-op
  }
}

class MockDashboardController extends TestDashboardController {
  String? deletedProjectId;
  String? renamedProjectId;
  String? renamedNewName;
  MockDashboardController(super.initialState);

  @override
  Future<void> deleteProject(String projectId) async {
    deletedProjectId = projectId;
  }

  @override
  Future<void> renameProject(String projectId, String newName) async {
    renamedProjectId = projectId;
    renamedNewName = newName;
  }

  @override
  Future<Project?> importVideo({
    required String videoPath,
    required String projectName,
    required bool useMockTranscription,
    String? subtitlePath,
    String? language,
    String? modelSize,
    String? whisperCliPath,
    String? whisperModelPath,
    String? ffmpegCliPath,
    bool? useVad,
    double? vadThreshold,
    bool? translate,
  }) async {
    state = state.copyWith(errorMessage: 'Database write error!');
    return null;
  }
}

class FakeAssetVerificationNotifier extends AssetVerificationNotifier {
  FakeAssetVerificationNotifier(super.state);

  @override
  Future<void> reVerify() async {
    // No-op
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AssetManifest testManifest;
  late AssetVerificationResult testVerification;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'app_theme': 'obsidianAmber',
    });
    tempDir = Directory.systemTemp.createTempSync('capstudio_dashboard_view_test_');
    AppDirs.setSupportPathForTesting(tempDir.path);
    await AppDirs.init();
    await SettingsService.instance.init();

    testManifest = AssetManifest(
      version: '2.0',
      packs: [
        const AssetPack(
          id: 'googleNonAnimated',
          name: 'Google Noto (Static)',
          description: 'High-quality flat Google Noto emoji set. Required for basic display.',
          required: true,
          sizeBytes: 10 * 1024 * 1024,
          compressedSizeBytes: 5 * 1024 * 1024,
          downloadUrl: 'http://example.com',
          checksum: '',
          version: '1.0',
          fileCount: 10,
          format: 'zip',
          animated: false,
          localFolder: 'google_noto_emojis_non_animated_pack',
        ),
      ],
      emojis: [],
    );

    testVerification = const AssetVerificationResult(
      allRequiredPresent: true,
      missing: [],
      installedPackIds: ['googleNonAnimated'],
      hasAnyEmojis: true,
    );
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('DashboardScreen Widget Tests', () {
    testWidgets('renders empty state when projects list is empty', (tester) async {
      final controller = TestDashboardController(
        const DashboardState(
          projects: [],
          isLoading: false,
        ),
      );

      await pumpTestWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((ref) => controller),
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      // Verify page headers
      expect(find.text('CapStudio'), findsOneWidget);
      expect(find.text('LOCAL OFFLINE'), findsOneWidget);

      // Verify empty state text
      expect(find.text('No projects created yet'), findsOneWidget);
      final emptyStateCenter = find.ancestor(
        of: find.text('No projects created yet'),
        matching: find.byType(Center),
      );
      expect(
        find.descendant(of: emptyStateCenter, matching: find.byIcon(Icons.video_library_outlined)),
        findsOneWidget,
      );
    });

    testWidgets('renders loading overlay when isLoading is true', (tester) async {
      final controller = TestDashboardController(
        const DashboardState(
          projects: [],
          isLoading: true,
          importStatusText: 'Analyzing video file...',
          importProgress: 0.45,
        ),
      );

      await pumpTestWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((ref) => controller),
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      // Verify loading progress bar and overlay elements are visible
      expect(find.text('Analyzing video file...'), findsOneWidget);
      expect(find.text('45% Completed'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders list of project cards correctly', (tester) async {
      final projects = [
        makeProject(
          projectId: 'p1',
          name: 'First Video Captioning',
          videoPath: 'c:/videos/v1.mp4',
          duration: 34.5,
        ),
        makeProject(
          projectId: 'p2',
          name: 'Second Promo Cap',
          videoPath: 'd:/videos/v2.mov',
          duration: 12.0,
        ),
      ];

      final controller = TestDashboardController(
        DashboardState(
          projects: projects,
          isLoading: false,
        ),
      );

      await pumpTestWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((ref) => controller),
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      // Verify no empty state message
      expect(find.text('No projects created yet'), findsNothing);

      // Verify project cards are rendered with names and video paths using substring matches
      expect(find.textContaining('First Video'), findsOneWidget);
      expect(find.textContaining('Second Promo'), findsOneWidget);
    });

    testWidgets('displays project deletion modal on delete icon tap', (tester) async {
      final projects = [
        makeProject(projectId: 'p1', name: 'Project to Delete', duration: 10.0),
      ];
      final controller = MockDashboardController(
        DashboardState(projects: projects, isLoading: false),
      );

      await pumpTestWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((ref) => controller),
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      // Verify project is visible
      expect(find.textContaining('Project to Delete'), findsOneWidget);

      // Tap on Delete icon button in HoverableProjectCard
      final deleteBtnFinder = find.byIcon(Icons.delete_forever_outlined);
      expect(deleteBtnFinder, findsOneWidget);
      await tester.tap(deleteBtnFinder);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify the Delete confirmation modal is displayed
      expect(find.text('Delete Project'), findsOneWidget);
      expect(find.textContaining('Are you sure you want to permanently delete'), findsOneWidget);
    });

    testWidgets('project deletion modal cancel button closes modal and does not delete', (tester) async {
      final projects = [
        makeProject(projectId: 'p1', name: 'Project to Delete', duration: 10.0),
      ];
      final controller = MockDashboardController(
        DashboardState(projects: projects, isLoading: false),
      );

      await pumpTestWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((ref) => controller),
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      await tester.tap(find.byIcon(Icons.delete_forever_outlined));
      await tester.pump(const Duration(milliseconds: 500));

      // Tap CANCEL button
      final cancelBtnFinder = find.text('CANCEL');
      expect(cancelBtnFinder, findsOneWidget);
      await tester.tap(cancelBtnFinder);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify modal is closed
      expect(find.text('Delete Project'), findsNothing);
      expect(controller.deletedProjectId, isNull); // Verify deleteProject was not called
    });

    testWidgets('project deletion modal confirm button closes modal and triggers deleteProject', (tester) async {
      final projects = [
        makeProject(projectId: 'p1', name: 'Project to Delete', duration: 10.0),
      ];
      final controller = MockDashboardController(
        DashboardState(projects: projects, isLoading: false),
      );

      await pumpTestWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((ref) => controller),
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      await tester.tap(find.byIcon(Icons.delete_forever_outlined));
      await tester.pump(const Duration(milliseconds: 500));

      // Tap DELETE button in dialog
      final confirmDeleteBtnFinder = find.widgetWithText(ElevatedButton, 'DELETE');
      expect(confirmDeleteBtnFinder, findsOneWidget);
      await tester.tap(confirmDeleteBtnFinder);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify modal is closed and deleteProject was called
      expect(find.text('Delete Project'), findsNothing);
      expect(controller.deletedProjectId, equals('p1'));
    });

    testWidgets('displays project rename modal on rename icon tap', (tester) async {
      final projects = [
        makeProject(projectId: 'p1', name: 'Project to Rename', duration: 10.0),
      ];
      final controller = MockDashboardController(
        DashboardState(projects: projects, isLoading: false),
      );

      await pumpTestWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((ref) => controller),
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      expect(find.textContaining('Project to Rename'), findsOneWidget);

      // Tap on Rename icon button
      final renameBtnFinder = find.byIcon(Icons.drive_file_rename_outline);
      expect(renameBtnFinder, findsOneWidget);
      await tester.tap(renameBtnFinder);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify the Rename confirmation modal is displayed
      expect(find.text('Rename Project'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      
      // Tap CANCEL button
      await tester.tap(find.text('CANCEL'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Rename Project'), findsNothing);
    });

    testWidgets('project rename modal confirm button triggers renameProject', (tester) async {
      final projects = [
        makeProject(projectId: 'p1', name: 'Project to Rename', duration: 10.0),
      ];
      final controller = MockDashboardController(
        DashboardState(projects: projects, isLoading: false),
      );

      await pumpTestWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((ref) => controller),
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      await tester.tap(find.byIcon(Icons.drive_file_rename_outline));
      await tester.pump(const Duration(milliseconds: 500));

      // Enter new name
      await tester.enterText(find.byType(TextField), 'Renamed Title');
      await tester.pump();

      // Tap RENAME button in dialog
      final confirmRenameBtnFinder = find.widgetWithText(ElevatedButton, 'RENAME');
      expect(confirmRenameBtnFinder, findsOneWidget);
      await tester.tap(confirmRenameBtnFinder);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify modal is closed and renameProject was called
      expect(find.text('Rename Project'), findsNothing);
      expect(controller.renamedProjectId, equals('p1'));
      expect(controller.renamedNewName, equals('Renamed Title'));
    });

    testWidgets('drag and drop enter sets isDragOver visual indicator', (tester) async {
      final controller = MockDashboardController(
        const DashboardState(projects: [], isLoading: false),
      );

      await pumpTestWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((ref) => controller),
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      // Verify drag overlay is not visible initially
      expect(find.text('DROP VIDEO HERE'), findsNothing);

      // Find DropTarget and trigger onDragEntered
      final dropTargetFinder = find.byType(DropTarget);
      expect(dropTargetFinder, findsOneWidget);
      final DropTarget dropTarget = tester.widget(dropTargetFinder);
      
      dropTarget.onDragEntered?.call(DropEventDetails(
        localPosition: Offset.zero,
        globalPosition: Offset.zero,
      ));
      await tester.pump();

      // Verify drag overlay is visible
      expect(find.text('DROP VIDEO HERE'), findsOneWidget);
    });

    testWidgets('drag and drop exit hides isDragOver visual indicator', (tester) async {
      final controller = MockDashboardController(
        const DashboardState(projects: [], isLoading: false),
      );

      await pumpTestWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((ref) => controller),
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      final dropTargetFinder = find.byType(DropTarget);
      final DropTarget dropTarget = tester.widget(dropTargetFinder);
      
      // Enter drag
      dropTarget.onDragEntered?.call(DropEventDetails(
        localPosition: Offset.zero,
        globalPosition: Offset.zero,
      ));
      await tester.pump();
      expect(find.text('DROP VIDEO HERE'), findsOneWidget);

      // Exit drag
      dropTarget.onDragExited?.call(DropEventDetails(
        localPosition: Offset.zero,
        globalPosition: Offset.zero,
      ));
      await tester.pump();

      // Verify drag overlay is hidden
      expect(find.text('DROP VIDEO HERE'), findsNothing);
    });

    testWidgets('drag and drop done with valid video triggers import dialog', (tester) async {
      final controller = MockDashboardController(
        const DashboardState(projects: [], isLoading: false),
      );

      await pumpTestWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((ref) => controller),
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      final dropTargetFinder = find.byType(DropTarget);
      final DropTarget dropTarget = tester.widget(dropTargetFinder);
      
      // Complete drag drop with valid video
      dropTarget.onDragDone?.call(DropDoneDetails(
        files: [DropItemFile('path/to/test_video.mp4')],
        localPosition: Offset.zero,
        globalPosition: Offset.zero,
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.idle();
      await tester.pump();

      // Verify the import dialog is opened
      expect(find.text('IMPORT NEW VIDEO'), findsOneWidget);
      expect(find.text('CREATE PROJECT'), findsOneWidget);

      // Ensure button is visible before tapping
      await tester.ensureVisible(find.text('CANCEL'));
      await tester.pump(const Duration(milliseconds: 100));

      // Dismiss dialog
      await tester.tap(find.text('CANCEL'));
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('drag and drop done with invalid file format shows error snackbar', (tester) async {
      final controller = MockDashboardController(
        const DashboardState(projects: [], isLoading: false),
      );

      await pumpTestWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((ref) => controller),
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      final dropTargetFinder = find.byType(DropTarget);
      final DropTarget dropTarget = tester.widget(dropTargetFinder);
      
      // Complete drag drop with invalid file format (txt)
      dropTarget.onDragDone?.call(DropDoneDetails(
        files: [DropItemFile('path/to/notes.txt')],
        localPosition: Offset.zero,
        globalPosition: Offset.zero,
      ));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify import dialog is NOT opened
      expect(find.text('IMPORT NEW VIDEO'), findsNothing);

      // Verify invalid file SnackBar is shown
      expect(find.text('Invalid file format. Please drop a video file.'), findsOneWidget);
    });

    testWidgets('shows SnackBar when importVideo fails and sets error message', (tester) async {
      final controller = MockDashboardController(
        const DashboardState(projects: [], isLoading: false),
      );

      // Create dummy model files to enable CREATE PROJECT button in standard mode
      final modelsDir = Directory(p.join(tempDir.path, 'models'));
      modelsDir.createSync(recursive: true);
      for (final name in ['tiny', 'tiny.en', 'small', 'small.en', 'large-v3-turbo']) {
        File(p.join(modelsDir.path, 'ggml-$name.bin')).writeAsStringSync('dummy model');
      }

      await pumpTestWidget(
        tester,
        const DashboardScreen(),
        overrides: [
          dashboardProvider.overrideWith((ref) => controller),
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      final dropTargetFinder = find.byType(DropTarget);
      final DropTarget dropTarget = tester.widget(dropTargetFinder);
      
      // Open import dialog
      dropTarget.onDragDone?.call(DropDoneDetails(
        files: [DropItemFile('path/to/test_video.mp4')],
        localPosition: Offset.zero,
        globalPosition: Offset.zero,
      ));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.idle();
      await tester.pump();

      // Ensure button is visible before tapping
      await tester.ensureVisible(find.text('CREATE PROJECT'));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap CREATE PROJECT button (triggers controller.importVideo which returns null and sets error state)
      await tester.tap(find.text('CREATE PROJECT'));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify SnackBar is shown with the correct database write error message
      expect(find.text('Database write error!'), findsOneWidget);
    });
  });
}
