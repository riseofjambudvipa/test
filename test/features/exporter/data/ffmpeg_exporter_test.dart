import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/features/editor/domain/caption_engine.dart';
import 'package:capstudio/features/exporter/data/ffmpeg_exporter.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/audio/audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../mocks/mocks.dart';
import '../../../helpers/project_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Project project;
  late List<Chunk> chunks;
  late FfmpegExporter exporter;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
    exporter = FfmpegExporter();
    
    project = makeProject(
      projectId: 'proj_test_export',
      name: 'My Export Project',
      videoPath: 'input.mp4',
      duration: 10.0,
      width: 1080,
      height: 1920,
      config: makeConfig(
        name: 'default',
        fontFamily: 'Outfit',
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
        stroke: 'thick',
      ),
      words: [
        makeWord(wordId: 'w1', text: 'Hello', start: 0.0, end: 0.5),
        makeWord(wordId: 'w2', text: 'world', start: 0.6, end: 1.6, className: 'mainColor'),
        makeWord(wordId: 'w3', text: 'hidden', start: 1.7, end: 2.0, hidden: true),
      ],
    );

    chunks = CaptionEngine.buildChunks(
      project.words,
      null,
      0.0,
      0.0,
      2,
      20,
    );
  });

  group('FfmpegExporter ASS Script Generation', () {
    test('should generate correct ASS subtitles script with karaoke timing and style tags', () {
      final script = FfmpegExporter.generateAssScript(project, chunks);

      // Verify Script Info resolution configurations
      expect(script, contains('PlayResX: 1080'));
      expect(script, contains('PlayResY: 1920'));

      // Verify V4+ Styles font mapping and colors
      // Highlight color orange: &H001673f9&, Primary/Normal white: &H00ffffff&
      expect(script, contains('Default,Outfit,72,&H001673f9&,&H00ffffff&'));
      expect(script, contains('&H001673f9&'));

      // Verify Dialogue lines and centiseconds karaoke tags with active word pop animation tags
      // 'Hello' duration = 0.5s = 50 centiseconds -> {\k50} with anim: {\t(0,0,\fscx112\fscy112)\t(500,500,\fscx100\fscy100)} and reset: {\fscx100\fscy100}
      // 'world' duration = 1.0s = 100 centiseconds -> {\k100} with color tag {\c&H001673f9&}, anim: {\t(600,600,\fscx112\fscy112)\t(1600,1600,\fscx100\fscy100)} and reset: {\fscx100\fscy100}
      expect(script, contains('Dialogue: 0,0:00:00.00,0:00:01.60,Default'));
      expect(script, contains(r'\fad(25,50)'));
      // 'Hello' pop animation and karaoke duration (50 centiseconds)
      expect(script, contains(r'{\t(0,0,\fscx112\fscy112)\t(500,500,\fscx100\fscy100)}{\k50}HELLO{\fscx100\fscy100}'));
      // 'world' color tag, pop animation, duration (100 centiseconds), and reset color tag
      expect(script, contains(r'{\c&H001673f9&}'));
      expect(script, contains(r'{\t(600,600,\fscx112\fscy112)\t(1600,1600,\fscx100\fscy100)}{\k100}WORLD{\fscx100\fscy100}'));
      // Spanning back resets to the main highlight color
      expect(script, contains(r'{\c&H001673f9&}'));

      // Verify hidden word 'hidden' is filtered out and does not exist in script
      expect(script, isNot(contains('HIDDEN')));
    });

    test('should generate correct ASS animations for bounce, kineticTilt, wordReveal, and glowPulse styles', () {
      // 1. Bounce Animation
      project.config.animation = 'bounce';
      var script = FfmpegExporter.generateAssScript(project, chunks);
      expect(script, contains('{\\t(0,0,\\fscy125\\fscx85)\\t(500,500,\\fscx100\\fscy100)}'));

      // 2. Kinetic Tilt Animation
      project.config.animation = 'kineticTilt';
      script = FfmpegExporter.generateAssScript(project, chunks);
      // Index 0: Hello (i is even -> tiltDeg = 5)
      expect(script, contains('{\\t(0,0,\\frz5)\\t(500,500,\\frz0)}'));
      // Index 1: world (i is odd -> tiltDeg = -5)
      expect(script, contains('{\\t(600,600,\\frz-5)\\t(1600,1600,\\frz0)}'));

      // 3. Word Reveal Animation
      project.config.animation = 'wordReveal';
      script = FfmpegExporter.generateAssScript(project, chunks);
      expect(script, contains('{\\fscy0\\t(0,250,\\fscy100)}'));

      // 4. Glow Pulse Animation
      project.config.animation = 'glowPulse';
      script = FfmpegExporter.generateAssScript(project, chunks);
      // outlineWidth is 18.0 because stroke is 'thick' and exportScale is 3.0, expansion is 3.0 * 3.0 = 9.0 -> bord27.0
      expect(script, contains('{\\t(0,0,\\bord27.0)\\t(500,500,\\bord18.0)}'));
    });

    test('should map alignment and vertical margin based on style.top layout positions', () {
      // Top Position (top = 10%) -> \pos(540, 226)
      project.config.style.top = 10.0;
      var script = FfmpegExporter.generateAssScript(project, chunks);
      expect(script, contains(r'\pos(540,226)'));

      // Bottom Position (top = 80%) -> \pos(540, 1511)
      project.config.style.top = 80.0;
      script = FfmpegExporter.generateAssScript(project, chunks);
      expect(script, contains(r'\pos(540,1511)'));

      // Middle Position (top = 50%) -> \pos(540, 960)
      project.config.style.top = 50.0;
      script = FfmpegExporter.generateAssScript(project, chunks);
      expect(script, contains(r'\pos(540,960)'));
    });

    test('should verify outline width is 0.0 for stroke modes other than thick', () {
      project.config.stroke = 'soft';
      var script = FfmpegExporter.generateAssScript(project, chunks);
      expect(script, contains(',0.0,6.0,5,'));

      project.config.stroke = 'none';
      script = FfmpegExporter.generateAssScript(project, chunks);
      expect(script, contains(',0.0,6.0,5,'));

      project.config.stroke = 'thick';
      script = FfmpegExporter.generateAssScript(project, chunks);
      expect(script, contains(',18.0,6.0,5,'));
    });

    test('should set ASS bold flag (-1) for all bold-weight variants including w600, w800', () {
      // Bold weights: 600 (SemiBold), 700 (Bold), 800 (ExtraBold), 900 (Black), 'bold'
      for (final weight in ['600', '700', '800', '900', 'bold']) {
        project.config.style.fontWeight = weight;
        final script = FfmpegExporter.generateAssScript(project, chunks);
        // The ASS Style line contains bold flag as -1 when weight is bold
        // Format: ...,fontFamily,fontSize,primary,sec,outline,back,bold,...
        // Bold field position: after back color, value -1 = bold, 0 = normal
        expect(
          script,
          contains(',-1,0,0,0,100,100'),
          reason: 'fontWeight $weight should produce ASS bold flag -1',
        );
      }

      // Non-bold weights: 100, 200, 300, 400, 500
      for (final weight in ['100', '200', '300', '400', '500']) {
        project.config.style.fontWeight = weight;
        final script = FfmpegExporter.generateAssScript(project, chunks);
        expect(
          script,
          contains(',0,0,0,0,100,100'),
          reason: 'fontWeight $weight should produce ASS bold flag 0 (normal)',
        );
      }
    });
  });

  group('FfmpegExporter Subprocess Pipeline Tests', () {
    late MockProcess mockProcess;
    late StreamController<List<int>> stderrController;

    setUp(() {
      mockProcess = MockProcess();
      stderrController = StreamController<List<int>>();

      when(() => mockProcess.pid).thenReturn(9999);
      when(() => mockProcess.stderr).thenAnswer((_) => stderrController.stream);
      when(() => mockProcess.stdout).thenAnswer((_) => const Stream<List<int>>.empty());

      exporter.processStarter = (executable, arguments) async {
        return mockProcess;
      };
    });

    tearDown(() {
      stderrController.close();
    });

    test('exportVideo should yield correct progress percent parsing and complete on exit code 0', () async {
      when(() => mockProcess.exitCode).thenAnswer((_) async => 0);

      // Create an output path
      final tempDir = Directory.systemTemp.createTempSync('ffmpeg_test_out_');
      final outputFilePath = p.join(tempDir.path, 'exported.mp4');

      try {
        final progressStream = exporter.exportVideo(
          project: project,
          chunks: chunks,
          outputFilePath: outputFilePath,
          tempDir: tempDir.path,
        );
        final results = <ExportProgress>[];

        // Read progress asynchronously
        final done = progressStream.forEach((progress) {
          results.add(progress);
        });

        // Add progress logs over stderr
        stderrController.add(utf8.encode('frame=  12 time=00:00:02.50 bitrate=100kbps\n'));
        await Future.delayed(const Duration(milliseconds: 20));
        stderrController.add(utf8.encode('frame=  24 time=00:00:05.00 bitrate=100kbps\n'));
        await Future.delayed(const Duration(milliseconds: 20));
        stderrController.add(utf8.encode('frame=  48 time=00:00:07.50 bitrate=100kbps\n'));
        await Future.delayed(const Duration(milliseconds: 20));

        // Close stream
        await stderrController.close();
        await done;

        expect(results.length, 5);
        expect(results[0].progress, 0.0);
        expect(results[0].status, 'rendering');

        expect(results[1].progress, 0.25);
        expect(results[1].status, 'rendering');

        expect(results[2].progress, 0.50);
        expect(results[2].status, 'rendering');

        expect(results[3].progress, 0.75);
        expect(results[3].status, 'rendering');

        expect(results[4].progress, 1.0);
        expect(results[4].status, 'completed');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('exportVideo should fail and yield error status when exit code is non-zero', () async {
      when(() => mockProcess.exitCode).thenAnswer((_) async => 1);

      final tempDir = Directory.systemTemp.createTempSync('ffmpeg_test_fail_');
      final outputFilePath = p.join(tempDir.path, 'exported.mp4');

      try {
        final progressStream = exporter.exportVideo(
          project: project,
          chunks: chunks,
          outputFilePath: outputFilePath,
          tempDir: tempDir.path,
        );
        final results = <ExportProgress>[];

        final done = progressStream.forEach((progress) {
          results.add(progress);
        });

        // Add standard FFmpeg errors to stream
        stderrController.add(utf8.encode('Error: Invalid complex filter parameter\n'));
        await stderrController.close();
        await done;

        expect(results.length, 2);
        expect(results[0].progress, 0.0);
        expect(results[0].status, 'rendering');

        expect(results[1].status, 'failed');
        expect(results[1].progress, 0.0);
        expect(results[1].error, contains('failed with exit code 1'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('exportVideo should configure h264_nvenc when useGpu is true and encoder is nvenc', () async {
      when(() => mockProcess.exitCode).thenAnswer((_) async => 0);
      
      final tempDir = Directory.systemTemp.createTempSync('ffmpeg_test_gpu_');
      final outputFilePath = p.join(tempDir.path, 'exported.mp4');

      try {
        final settings = SettingsService.instance;
        await settings.setUseGpu(true);
        await settings.setGpuEncoder('h264_nvenc');

        List<String>? capturedArgs;
        exporter.processStarter = (executable, arguments) async {
          capturedArgs = arguments;
          return mockProcess;
        };

        final progressStream = exporter.exportVideo(
          project: project,
          chunks: chunks,
          outputFilePath: outputFilePath,
          tempDir: tempDir.path,
        );

        final done = progressStream.forEach((progress) {});

        await stderrController.close();
        await done;

        expect(capturedArgs, isNotNull);
        expect(capturedArgs, contains('-c:v'));
        expect(capturedArgs, contains('h264_nvenc'));
        expect(capturedArgs, contains('-preset'));
        expect(capturedArgs, contains('p4'));
      } finally {
        tempDir.deleteSync(recursive: true);
        await SettingsService.instance.setUseGpu(false);
      }
    });

    test('exportVideo should fall back to software libx264 when GPU hardware encoder fails on desktop', () async {
      final failProcess = MockProcess();
      final successProcess = MockProcess();

      when(() => failProcess.pid).thenReturn(1111);
      when(() => failProcess.exitCode).thenAnswer((_) async => 1);
      when(() => failProcess.stderr).thenAnswer((_) => const Stream<List<int>>.empty());
      when(() => failProcess.stdout).thenAnswer((_) => const Stream<List<int>>.empty());

      when(() => successProcess.pid).thenReturn(2222);
      when(() => successProcess.exitCode).thenAnswer((_) async => 0);
      when(() => successProcess.stderr).thenAnswer((_) => const Stream<List<int>>.empty());
      when(() => successProcess.stdout).thenAnswer((_) => const Stream<List<int>>.empty());

      final settings = SettingsService.instance;
      await settings.setUseGpu(true);
      await settings.setGpuEncoder('h264_nvenc');

      final capturedRuns = <List<String>>[];
      exporter.processStarter = (executable, arguments) async {
        capturedRuns.add(arguments);
        if (capturedRuns.length == 1) {
          return failProcess;
        } else {
          return successProcess;
        }
      };

      final tempDir = Directory.systemTemp.createTempSync('ffmpeg_test_fallback_');
      final outputFilePath = p.join(tempDir.path, 'exported.mp4');

      try {
        final progressStream = exporter.exportVideo(
          project: project,
          chunks: chunks,
          outputFilePath: outputFilePath,
          tempDir: tempDir.path,
        );

        final results = <ExportProgress>[];
        await progressStream.forEach((progress) {
          results.add(progress);
        });

        expect(capturedRuns.length, 2);
        expect(capturedRuns[0], contains('h264_nvenc'));
        expect(capturedRuns[1], contains('libx264'));

        expect(results.any((r) => r.error != null && r.error!.contains('Hardware export failed')), isTrue);
        expect(results.last.status, 'completed');
      } finally {
        tempDir.deleteSync(recursive: true);
        await settings.setUseGpu(false);
      }
    });

    test('exportVideo should configure audio mixing filter with dynamic afade parameters', () async {
      when(() => mockProcess.exitCode).thenAnswer((_) async => 0);
      
      final tempDir = Directory.systemTemp.createTempSync('ffmpeg_test_audio_');
      final outputFilePath = p.join(tempDir.path, 'exported.mp4');
      final dummySfxFile = File(p.join(tempDir.path, 'dummy_sfx.wav'))..writeAsBytesSync([0, 1, 2, 3]);

      try {
        AudioService.instance.registerSfx('laser_shot', dummySfxFile.path);

        // Add a word with SFX to the project
        project.words.add(
          WordSchema()
            ..wordId = 'w4'
            ..text = 'boom!'
            ..start = 2.0
            ..end = 2.4
            ..type = 'word'
            ..soundEffect = 'laser_shot'
            ..soundVolume = 80,
        );

        // Re-build chunks to include the new word
        final updatedChunks = CaptionEngine.buildChunks(
          project.words,
          null,
          0.0,
          0.0,
          2,
          20,
        );

        List<String>? capturedArgs;
        exporter.processStarter = (executable, arguments) async {
          capturedArgs = arguments;
          return mockProcess;
        };

        final progressStream = exporter.exportVideo(
          project: project,
          chunks: updatedChunks,
          outputFilePath: outputFilePath,
          tempDir: tempDir.path,
        );

        final done = progressStream.forEach((progress) {});

        await stderrController.close();
        await done;

        expect(capturedArgs, isNotNull);
        final complexFilter = capturedArgs![capturedArgs!.indexOf('-filter_complex') + 1];
        
        // Assert dynamic afade is present in the filter complex
        // sfxDuration = 2.4 - 2.0 = 0.4s
        // fadeDuration = 0.4 * 0.25 = 0.10s (within clamp range 0.01 to 0.15)
        // fadeOutStart = 0.4 - 0.10 = 0.30s
        expect(complexFilter, contains('afade=t=in:ss=0:d=0.100'));
        expect(complexFilter, contains('afade=t=out:ss=0.300:d=0.100'));
        expect(complexFilter, contains('volume=volume=0.8'));
        expect(complexFilter, contains('amix=inputs=2:duration=first:normalize=0'));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });

  group('FfmpegExporter Active GPU Encoder Probing', () {
    test('should parse encoders command output correctly', () async {
      final results = await FfmpegExporter.probeAvailableEncoders('invalid/ffmpeg');
      expect(results, isEmpty);
    });
  });
}
