import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/video/video_probe.dart';

/// Simple fake runner returning a canned stdout for ffprobe.
Future<ProcessResult> Function(String, List<String>) _runner(String stdout,
    {int exitCode = 0}) {
  return (executable, arguments) async =>
      ProcessResult(0, exitCode, stdout, '');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('probeVideoMetadata', () {
    const validJson = '''
    {"streams":[{"width":1920,"height":1080,"side_data_list":[
      {"side_data_type":"Display Matrix","rotation":90}],"tags":{}}],
     "format":{"duration":"10.5"}}
    ''';

    test('parses duration, dimensions, and rotation', () async {
      final meta = await probeVideoMetadata(
        videoPath: 'video.mp4',
        processRunner: _runner(validJson),
      );
      expect(meta, isNotNull);
      expect(meta!.duration, 10.5);
      expect(meta.rotation, 90);
      // 90-degree rotation swaps display width/height.
      expect(meta.width, 1080);
      expect(meta.height, 1920);
    });

    test('applies rotation tag fallback when side_data is absent', () async {
      const json = '''
      {"streams":[{"width":1280,"height":720,"tags":{"rotate":"270"}}],
       "format":{"duration":"5.0"}}
      ''';
      final meta = await probeVideoMetadata(
        videoPath: 'video.mp4',
        processRunner: _runner(json),
      );
      expect(meta, isNotNull);
      expect(meta!.rotation, 270);
      expect(meta.width, 720);
      expect(meta.height, 1280);
    });

    test('keeps landscape dimensions when rotation is 0', () async {
      const json = '''
      {"streams":[{"width":1920,"height":1080,"tags":{}}],
       "format":{"duration":"3.0"}}
      ''';
      final meta = await probeVideoMetadata(
        videoPath: 'video.mp4',
        processRunner: _runner(json),
      );
      expect(meta, isNotNull);
      expect(meta!.width, 1920);
      expect(meta.height, 1080);
      expect(meta.rotation, 0);
    });

    test('returns null when ffprobe exits non-zero', () async {
      final meta = await probeVideoMetadata(
        videoPath: 'video.mp4',
        processRunner: _runner('', exitCode: 1),
      );
      expect(meta, isNull);
    });

    test('returns null on malformed JSON output', () async {
      final meta = await probeVideoMetadata(
        videoPath: 'video.mp4',
        processRunner: _runner('N/A'),
      );
      expect(meta, isNull);
    });

    test('rethrows ProcessException so callers can surface missing binary',
        () async {
      Future<ProcessResult> throwMissingBinary(
              String executable, List<String> arguments) async =>
          throw const ProcessException('ffprobe', ['-v', 'error']);

      expect(
        () => probeVideoMetadata(
          videoPath: 'video.mp4',
          processRunner: throwMissingBinary,
        ),
        throwsA(isA<ProcessException>()),
      );
    });
  });
}
