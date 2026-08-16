import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/features/dashboard/presentation/controllers/dashboard_controller.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/whisper/whisper_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import '../../../../mocks/mocks.dart';
import '../../../../helpers/project_fixture.dart';

class MockWhisperService extends Mock implements WhisperService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DashboardController controller;
  late MockIsarService mockIsar;
  late MockWhisperService mockWhisper;
  late Directory tempDir;

  setUpAll(() {
    registerFallbackValue(Project());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
    tempDir = Directory.systemTemp.createTempSync('capstudio_dashboard_test_');
    AppDirs.setSupportPathForTesting(tempDir.path);
    await AppDirs.init();

    mockIsar = MockIsarService();
    mockWhisper = MockWhisperService();

    // Inject our mocks
    IsarService.instance = mockIsar;
    WhisperService.instance = mockWhisper;

    // Default db mock stubs
    when(() => mockIsar.isInitialized).thenReturn(true);
    when(() => mockIsar.getAllProjects()).thenAnswer((_) async => []);
    when(() => mockIsar.getProject(any())).thenAnswer((invocation) async {
      final String arg = invocation.positionalArguments[0] as String;
      return Project()
        ..id = arg.hashCode
        ..projectId = arg
        ..name = 'Mock Project';
    });
    when(() => mockIsar.deleteProject(any())).thenAnswer((_) async => true);
    when(() => mockIsar.saveProject(any())).thenAnswer((_) async {});

    controller = DashboardController();
    controller.processRunner = (executable, arguments, {stdoutEncoding, stderrEncoding}) async {
      if (executable == 'ffprobe' && arguments.contains('format=duration')) {
        return ProcessResult(0, 0, '10.0', '');
      }
      if (executable == 'ffprobe' && arguments.contains('stream=width,height')) {
        return ProcessResult(0, 0, '1920x1080', '');
      }
      if (executable == 'ffprobe' && arguments.contains('stream_side_data=rotation')) {
        return ProcessResult(0, 0, '', '');
      }
      return ProcessResult(0, 0, '', '');
    };
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('DashboardController Tests', () {
    test('should initialize and load projects from Isar database successfully', () async {
      final mockProjects = [
        makeProject(projectId: '1', name: 'Project One', duration: 10.0),
        makeProject(projectId: '2', name: 'Project Two', duration: 20.0),
      ];

      when(() => mockIsar.getAllProjects()).thenAnswer((_) async => mockProjects);

      // Re-trigger load to read new mocked projects list
      await controller.loadProjects();

      expect(controller.state.projects, isNotEmpty);
      expect(controller.state.projects.length, 2);
      expect(controller.state.projects[0].name, 'Project One');
      expect(controller.state.isLoading, isFalse);
    });

    test('should handle database deletion correctly and reload updated list', () async {
      when(() => mockIsar.getAllProjects()).thenAnswer((_) async => []);

      await controller.deleteProject('proj_to_delete');

      verify(() => mockIsar.deleteProject('proj_to_delete'.hashCode)).called(1);
      verify(() => mockIsar.getAllProjects()).called(2); // Initial constructor + deletion reload
    });

    test('should delete the sidecar thumbnail file when a project is deleted', () async {
      when(() => mockIsar.getAllProjects()).thenAnswer((_) async => []);

      final thumbDir = Directory(p.join(AppDirs.support, 'thumbnails'));
      if (!thumbDir.existsSync()) {
        thumbDir.createSync(recursive: true);
      }
      final thumbFile = File(p.join(thumbDir.path, 'proj_to_delete.jpg'));
      thumbFile.createSync();
      expect(thumbFile.existsSync(), isTrue);

      await controller.deleteProject('proj_to_delete');

      expect(thumbFile.existsSync(), isFalse);
    });

    test('should throw FileSystemException on importVideo if file does not exist', () async {
      final project = await controller.importVideo(
        videoPath: 'missing_video.mp4',
        projectName: 'Non-existent Video',
        useMockTranscription: true,
      );

      expect(project, isNull);
      expect(controller.state.errorMessage, contains('Video file does not exist'));
    });

    test('should import and generate draft project structures with mock transcription successfully', () async {
      // Create a dummy video file on disk so the existence check passes
      final dummyVideo = File(p.join(tempDir.path, 'valid_video.mp4'));
      dummyVideo.createSync();

      final project = await controller.importVideo(
        videoPath: dummyVideo.path,
        projectName: 'Draft Video Project',
        useMockTranscription: true,
      );

      expect(project, isNotNull);
      expect(project!.name, 'Draft Video Project');
      expect(project.videoPath, dummyVideo.path);
      expect(project.words, isNotEmpty); // Ensure mock words are generated

      // Check premium styling defaults configured
      expect(project.config.style.fontFamily, 'Montserrat');
      expect(project.config.style.color, '#ffffff');
      expect(project.config.highlightStyle.mainColor, '#ffffff'); // White highlight
      expect(project.config.style.fontWeight, '600');
      expect(project.status, 'draft');

      verify(() => mockIsar.saveProject(any())).called(1);
    });

    test('should handle concurrent deletion of the same project ID safely without throwing exceptions', () async {
      when(() => mockIsar.getAllProjects()).thenAnswer((_) async => []);
      
      // Fire multiple deletions simultaneously
      await Future.wait([
        controller.deleteProject('concurrent_proj_1'),
        controller.deleteProject('concurrent_proj_1'),
        controller.deleteProject('concurrent_proj_1'),
      ]);

      verify(() => mockIsar.deleteProject('concurrent_proj_1'.hashCode)).called(3);
    });

    test('should handle concurrent deletion of different project IDs safely', () async {
      when(() => mockIsar.getAllProjects()).thenAnswer((_) async => []);

      await Future.wait([
        controller.deleteProject('concurrent_proj_a'),
        controller.deleteProject('concurrent_proj_b'),
      ]);

      verify(() => mockIsar.deleteProject('concurrent_proj_a'.hashCode)).called(1);
      verify(() => mockIsar.deleteProject('concurrent_proj_b'.hashCode)).called(1);
    });

    test('should fall back to 60.0s duration on importVideo if ffprobe exits with non-zero exit code', () async {
      final dummyVideo = File(p.join(tempDir.path, 'corrupt_probe.mp4'));
      dummyVideo.createSync();

      controller.processRunner = (executable, arguments, {stdoutEncoding, stderrEncoding}) async {
        if (executable == 'ffprobe') {
          return ProcessResult(1, 1, '', 'ffprobe failed to read file header');
        }
        return ProcessResult(0, 0, '', '');
      };

      final project = await controller.importVideo(
        videoPath: dummyVideo.path,
        projectName: 'Corrupt Video Test',
        useMockTranscription: true,
      );

      expect(project, isNotNull);
      expect(project!.duration, equals(60.0)); // Fallback duration
    });

    test('should fall back to 60.0s duration on importVideo if ffprobe outputs non-numeric duration', () async {
      final dummyVideo = File(p.join(tempDir.path, 'bad_duration.mp4'));
      dummyVideo.createSync();

      controller.processRunner = (executable, arguments, {stdoutEncoding, stderrEncoding}) async {
        if (executable == 'ffprobe' && arguments.contains('format=duration')) {
          return ProcessResult(0, 0, 'N/A', ''); // Non-numeric output
        }
        return ProcessResult(0, 0, '', '');
      };

      final project = await controller.importVideo(
        videoPath: dummyVideo.path,
        projectName: 'Bad Duration Test',
        useMockTranscription: true,
      );

      expect(project, isNotNull);
      expect(project!.duration, equals(60.0)); // Fallback duration
    });

    test('should set state error on importVideo if database save throws exception', () async {
      final dummyVideo = File(p.join(tempDir.path, 'db_save_error.mp4'));
      dummyVideo.createSync();

      when(() => mockIsar.saveProject(any())).thenThrow(Exception('Simulated database write failure'));

      final project = await controller.importVideo(
        videoPath: dummyVideo.path,
        projectName: 'Database Error Test',
        useMockTranscription: true,
      );

      expect(project, isNull);
      expect(controller.state.errorMessage, contains('Simulated database write failure'));
      expect(controller.state.isLoading, isFalse);
    });

    test('should load empty project list and set error state if getAllProjects throws exception', () async {
      when(() => mockIsar.getAllProjects()).thenThrow(Exception('Isar read failure'));

      final freshController = DashboardController();
      await Future.delayed(Duration.zero); // Wait for microtask load projects to complete

      expect(freshController.state.projects, isEmpty);
      expect(freshController.state.errorMessage, contains('Isar read failure'));
    });

    test('should import video with language parameter successfully', () async {
      final dummyVideo = File(p.join(tempDir.path, 'lang_video.mp4'));
      dummyVideo.createSync();

      final project = await controller.importVideo(
        videoPath: dummyVideo.path,
        projectName: 'Language Video Project',
        useMockTranscription: true,
        language: 'es',
      );

      expect(project, isNotNull);
      expect(project!.name, 'Language Video Project');
      expect(project.words, isNotEmpty);
    });

    test('should clean up temp files and set error state if transcription fails', () async {
      final dummyVideo = File(p.join(tempDir.path, 'transcribe_fail.mp4'));
      dummyVideo.createSync();

      when(() => mockWhisper.extractAudio(any(), any())).thenAnswer((_) async => 'extracted_audio.wav');
      when(() => mockWhisper.transcribe(
        wavPath: any(named: 'wavPath'),
        modelPath: any(named: 'modelPath'),
        language: any(named: 'language'),
        useVad: any(named: 'useVad'),
        vadThreshold: any(named: 'vadThreshold'),
        expectedDuration: any(named: 'expectedDuration'),
        whisperCliPath: any(named: 'whisperCliPath'),
        translate: any(named: 'translate'),
        onWebProgress: any(named: 'onWebProgress'),
      )).thenThrow(const ProcessException('whisper', [], 'Transcription process crashed'));

      final project = await controller.importVideo(
        videoPath: dummyVideo.path,
        projectName: 'Transcribe Fail Project',
        useMockTranscription: false,
      );

      expect(project, isNull);
      expect(controller.state.errorMessage, contains('Transcription process crashed'));
      expect(controller.state.isLoading, isFalse);
    });
  });

  group('DashboardController renameProject Tests', () {
    test('renameProject updates the project name in the database', () async {
      final original = makeProject(projectId: 'proj_rename_1', name: 'Original Name');
      when(() => mockIsar.getProject('proj_rename_1')).thenAnswer((_) async => original);
      when(() => mockIsar.getAllProjects()).thenAnswer((_) async => []);

      await controller.renameProject('proj_rename_1', 'New Name');

      // Verify saveProject was called with updated name
      final captured = verify(() => mockIsar.saveProject(captureAny())).captured;
      expect(captured.length, 1);
      final saved = captured.first as Project;
      expect(saved.name, equals('New Name'));
    });

    test('renameProject clones the project and does not mutate original object', () async {
      final original = makeProject(projectId: 'proj_rename_2', name: 'Immutable Name');
      when(() => mockIsar.getProject('proj_rename_2')).thenAnswer((_) async => original);
      when(() => mockIsar.getAllProjects()).thenAnswer((_) async => []);

      await controller.renameProject('proj_rename_2', 'Changed Name');

      // The ORIGINAL object must NOT be mutated — this verifies the clone-before-mutate fix.
      expect(original.name, equals('Immutable Name'));
    });

    test('renameProject preserves all other project fields unchanged', () async {
      final original = makeProject(
        projectId: 'proj_rename_3',
        name: 'Old Name',
        videoPath: '/videos/test.mp4',
        duration: 42.5,
        width: 1920,
        height: 1080,
      );
      when(() => mockIsar.getProject('proj_rename_3')).thenAnswer((_) async => original);
      when(() => mockIsar.getAllProjects()).thenAnswer((_) async => []);

      await controller.renameProject('proj_rename_3', 'New Name');

      final captured = verify(() => mockIsar.saveProject(captureAny())).captured;
      final saved = captured.first as Project;

      expect(saved.name, 'New Name');
      expect(saved.projectId, original.projectId);
      expect(saved.videoPath, original.videoPath);
      expect(saved.duration, original.duration);
      expect(saved.width, original.width);
      expect(saved.height, original.height);
    });

    test('renameProject handles non-existent projectId gracefully', () async {
      when(() => mockIsar.getProject('nonexistent')).thenAnswer((_) async => null);

      // Must not throw
      await controller.renameProject('nonexistent', 'Anything');

      // saveProject should not be called if project not found
      verifyNever(() => mockIsar.saveProject(any()));
    });
  });
}
