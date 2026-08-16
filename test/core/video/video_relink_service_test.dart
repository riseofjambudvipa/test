import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/video/video_relink_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import '../../mocks/mocks.dart';
import '../../helpers/project_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoRelinkService service;
  late Project project;
  late MockEditorController mockEditorController;

  setUpAll(() {
    registerFallbackValue(Project());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
    service = VideoRelinkService.instance;
    service.processRunner = null;

    mockEditorController = MockEditorController();
    when(() => mockEditorController.saveProject()).thenAnswer((_) async {});
    when(() => mockEditorController.setProject(any())).thenAnswer((_) {});

    project = makeProject(
      projectId: 'proj_relink_123',
      name: 'My Relink Video',
      videoPath: 'C:/movies/old_name.mp4',
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
        mainColor: '#f97316',
        secondColor: '#06b6d4',
        thirdColor: '#22c55e',
        chunkSize: 2,
        chunkLineMaxLength: 20,
        animation: 'pop',
        shadow: 'soft',
        stroke: 'none',
      ),
      words: [],
    );
  });

  tearDown(() {
    service.processRunner = null;
  });

  group('VideoRelinkService Tests', () {
    test('checkVideoExists should verify local disk files properly', () {
      expect(service.checkVideoExists(''), isFalse);
      expect(service.checkVideoExists('C:/invalid/path/to/video.mp4'), isFalse);

      final tempDir = Directory.systemTemp.createTempSync('relink_test_');
      final tempFile = File(p.join(tempDir.path, 'video.mp4'))..createSync();

      try {
        expect(service.checkVideoExists(tempFile.path), isTrue);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('validateAndRelink should successfully update video path when durations match', () async {
      final tempDir = Directory.systemTemp.createTempSync('relink_test_ok_');
      final tempFile = File(p.join(tempDir.path, 'new_name.mp4'))..createSync();

      try {
        // Mock ffprobe returning exactly 10.0s (duration matches original project duration)
        service.processRunner = (executable, arguments) async {
          return ProcessResult(200, 0, '10.0\n', '');
        };

        final result = await service.validateAndRelink(
          project: project,
          newPath: tempFile.path,
          onSave: () => mockEditorController.saveProject(),
          onReload: (p) => mockEditorController.setProject(p),
        );

        expect(result.success, isTrue);
        expect(project.videoPath, tempFile.path);
        verify(() => mockEditorController.saveProject()).called(1);
        verify(() => mockEditorController.setProject(project)).called(1);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('validateAndRelink should abort and return false when durations mismatch by more than 2 seconds', () async {
      final tempDir = Directory.systemTemp.createTempSync('relink_test_fail_');
      final tempFile = File(p.join(tempDir.path, 'new_name.mp4'))..createSync();

      try {
        // Mock ffprobe returning 15.0s (duration differs from 10.0s by 5 seconds, which is > 2s)
        service.processRunner = (executable, arguments) async {
          return ProcessResult(201, 0, '15.0\n', '');
        };

        final result = await service.validateAndRelink(
          project: project,
          newPath: tempFile.path,
          onSave: () => mockEditorController.saveProject(),
          onReload: (p) => mockEditorController.setProject(p),
        );

        expect(result.success, isFalse);
        // Original video path should be unchanged
        expect(project.videoPath, 'C:/movies/old_name.mp4');
        verifyNever(() => mockEditorController.saveProject());
        verifyNever(() => mockEditorController.setProject(any()));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('validateAndRelink should still succeed if duration check fails to probe (ffprobe exits non-zero)', () async {
      final tempDir = Directory.systemTemp.createTempSync('relink_test_probe_fail_');
      final tempFile = File(p.join(tempDir.path, 'new_name.mp4'))..createSync();

      try {
        // Mock ffprobe format error / command not found (exits non-zero)
        service.processRunner = (executable, arguments) async {
          return ProcessResult(202, 127, '', 'ffprobe not found');
        };

        // Fallback: should log warning but let the relink proceed to avoid blocking users
        final result = await service.validateAndRelink(
          project: project,
          newPath: tempFile.path,
          onSave: () => mockEditorController.saveProject(),
          onReload: (p) => mockEditorController.setProject(p),
        );

        expect(result.success, isTrue);
        expect(project.videoPath, tempFile.path);
        verify(() => mockEditorController.saveProject()).called(1);
        verify(() => mockEditorController.setProject(project)).called(1);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
