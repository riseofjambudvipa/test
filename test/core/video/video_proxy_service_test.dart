import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/video/video_proxy_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VideoProxyService service;
  late Directory tempDir;
  late String dummySourcePath;

  setUp(() async {
    service = VideoProxyService.instance;
    tempDir = await Directory.systemTemp.createTemp('capstudio_proxy_test_');
    final dummy = File(p.join(tempDir.path, 'source.mp4'));
    await dummy.create();
    await dummy.writeAsBytes(List.filled(1024, 0));
    dummySourcePath = dummy.path;
  });

  tearDown(() async {
    service.processRunner = null;
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('VideoProxyService.shouldSuggestProxy', () {
    test('suggests proxy for 4K landscape and portrait footage', () {
      expect(
        service.shouldSuggestProxy(width: 3840, height: 2160),
        isTrue,
      );
      expect(
        service.shouldSuggestProxy(width: 2160, height: 3840),
        isTrue,
      );
    });

    test('suggests proxy for 1440p (2K QHD) footage', () {
      expect(
        service.shouldSuggestProxy(width: 2560, height: 1440),
        isTrue,
      );
    });

    test('suggests proxy for long 1080p footage (> 10 minutes)', () {
      expect(
        service.shouldSuggestProxy(width: 1920, height: 1080, duration: 605.0),
        isTrue,
      );
    });

    test('does not suggest proxy for short 1080p footage (<= 10 minutes)', () {
      expect(
        service.shouldSuggestProxy(width: 1920, height: 1080, duration: 300.0),
        isFalse,
      );
      expect(
        service.shouldSuggestProxy(width: 1920, height: 1080),
        isFalse,
      );
    });

    test('does not suggest proxy for standard 720p or lower footage', () {
      expect(
        service.shouldSuggestProxy(width: 1280, height: 720, duration: 1200.0),
        isFalse,
      );
      expect(
        service.shouldSuggestProxy(width: 854, height: 480),
        isFalse,
      );
    });
  });

  group('VideoProxyService.getProxyPath', () {
    test('computes deterministic proxy path with sanitized project ID', () {
      final path = service.getProxyPath('proj:123/special#name', 'input.mp4');
      final fileName = p.basename(path);
      expect(fileName, equals('proj_123_special_name_proxy_720p.mp4'));
      expect(fileName, isNot(contains(':')));
      expect(fileName, isNot(contains('#')));
      expect(fileName, isNot(contains('/')));
    });
  });

  group('VideoProxyService.getProxyInfo', () {
    test('returns exists=false when proxy does not exist', () async {
      final info = await service.getProxyInfo('non_existent_project', dummySourcePath);
      expect(info.exists, isFalse);
      expect(info.fileSizeMB, 0.0);
      expect(info.targetResolutionHeight, 720);
    });

    test('returns exists=true with size when proxy exists and is non-empty', () async {
      final projectId = 'test_proj_${DateTime.now().microsecondsSinceEpoch}';
      final proxyPath = service.getProxyPath(projectId, dummySourcePath);
      final proxyFile = File(proxyPath);
      await proxyFile.create(recursive: true);
      await proxyFile.writeAsBytes(List.filled(20480, 42)); // ~20KB

      try {
        final info = await service.getProxyInfo(projectId, dummySourcePath);
        expect(info.exists, isTrue);
        expect(info.fileSizeMB, greaterThan(0.01));
      } finally {
        if (await proxyFile.exists()) {
          await proxyFile.delete();
        }
      }
    });
  });

  group('VideoProxyService.generateProxy', () {
    test('returns existing proxy immediately without transcoding if already exists', () async {
      final projectId = 'existing_proj_${DateTime.now().microsecondsSinceEpoch}';
      final proxyPath = service.getProxyPath(projectId, dummySourcePath);
      final proxyFile = File(proxyPath);
      await proxyFile.create(recursive: true);
      await proxyFile.writeAsBytes(List.filled(10000, 1));

      bool runnerCalled = false;
      service.processRunner = (executable, arguments) async {
        runnerCalled = true;
        return ProcessResult(0, 0, '', '');
      };

      try {
        final result = await service.generateProxy(
          projectId: projectId,
          sourceVideoPath: dummySourcePath,
          forceRegenerate: false,
        );
        expect(result, equals(proxyPath));
        expect(runnerCalled, isFalse);
      } finally {
        if (await proxyFile.exists()) {
          await proxyFile.delete();
        }
      }
    });

    test('invokes processRunner with FFmpeg proxy scale arguments on success', () async {
      final projectId = 'gen_proj_${DateTime.now().microsecondsSinceEpoch}';
      final proxyPath = service.getProxyPath(projectId, dummySourcePath);
      final stagingPath = '$proxyPath.partial';
      final proxyFile = File(proxyPath);
      final stagingFile = File(stagingPath);

      List<String>? capturedArgs;
      service.processRunner = (executable, arguments) async {
        capturedArgs = arguments;
        // Mock FFmpeg producing the output partial file
        await stagingFile.create(recursive: true);
        await stagingFile.writeAsBytes(List.filled(5000, 7));
        return ProcessResult(0, 0, '', '');
      };

      double lastProgress = 0.0;
      try {
        final result = await service.generateProxy(
          projectId: projectId,
          sourceVideoPath: dummySourcePath,
          onProgress: (p) => lastProgress = p,
        );

        expect(result, equals(proxyPath));
        expect(capturedArgs, isNotNull);
        expect(capturedArgs, contains('-c:v'));
        expect(capturedArgs, contains('libx264'));
        expect(capturedArgs, contains('-preset'));
        expect(capturedArgs, contains('veryfast'));
        expect(lastProgress, equals(1.0));
        expect(await proxyFile.exists(), isTrue);
      } finally {
        if (await proxyFile.exists()) await proxyFile.delete();
        if (await stagingFile.exists()) await stagingFile.delete();
      }
    });

    test('returns null when FFmpeg process runner returns non-zero error', () async {
      final projectId = 'fail_proj_${DateTime.now().microsecondsSinceEpoch}';
      service.processRunner = (executable, arguments) async {
        return ProcessResult(0, 1, '', 'Decoder error');
      };

      final result = await service.generateProxy(
        projectId: projectId,
        sourceVideoPath: dummySourcePath,
      );
      expect(result, isNull);
    });
  });

  group('VideoProxyService.deleteProxy', () {
    test('returns false when proxy file does not exist', () async {
      final result = await service.deleteProxy('proj_missing', dummySourcePath);
      expect(result, isFalse);
    });

    test('deletes existing proxy file and returns true', () async {
      final projectId = 'del_proj_${DateTime.now().microsecondsSinceEpoch}';
      final proxyPath = service.getProxyPath(projectId, dummySourcePath);
      final proxyFile = File(proxyPath);
      await proxyFile.create(recursive: true);
      await proxyFile.writeAsBytes([1, 2, 3]);

      expect(await proxyFile.exists(), isTrue);
      final result = await service.deleteProxy(projectId, dummySourcePath);
      expect(result, isTrue);
      expect(await proxyFile.exists(), isFalse);
    });
  });
}
