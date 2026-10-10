import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/ffmpeg/ffmpeg_locator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FfmpegLocator.instance.clearCache();
  });

  tearDown(() {
    FfmpegLocator.instance.clearCache();
  });

  group('FfmpegLocator', () {
    test('returns the explicitly configured path verbatim and never caches it',
        () {
      expect(FfmpegLocator.instance.resolve(configured: 'C:/tools/ffmpeg.exe'),
          'C:/tools/ffmpeg.exe');
      // A different explicit path takes effect immediately (no stale cache).
      expect(FfmpegLocator.instance.resolve(configured: 'D:/other/ffmpeg.exe'),
          'D:/other/ffmpeg.exe');
    });

    test('discovers a bundled binary in dev-tree paths and caches the result',
        () {
      final exe = Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
      final binDir = Directory(p.join(Directory.current.path, 'assets', 'bin'));
      binDir.createSync(recursive: true);
      final bundled = File(p.join(binDir.path, exe))
        ..writeAsBytesSync([0x4D, 0x5A]);

      try {
        final first = FfmpegLocator.instance.resolve();
        expect(first, bundled.path);

        // Cache hit — no re-scan, same path.
        expect(FfmpegLocator.instance.resolve(), bundled.path);

        // After the binary is removed and the cache cleared, falls back to
        // the PATH name.
        bundled.deleteSync();
        FfmpegLocator.instance.clearCache();
        expect(FfmpegLocator.instance.resolve(), 'ffmpeg');
      } finally {
        try {
          if (bundled.existsSync()) bundled.deleteSync();
        } catch (_) {}
        try {
          binDir.deleteSync();
        } catch (_) {}
        FfmpegLocator.instance.clearCache();
      }
    });

    test('resolveFfprobe finds ffprobe next to a resolved ffmpeg binary', () {
      final exe = Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
      final probeExe = Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';
      final binDir = Directory(p.join(Directory.current.path, 'assets', 'bin'));
      binDir.createSync(recursive: true);
      final bundled = File(p.join(binDir.path, exe))
        ..writeAsBytesSync([0x4D, 0x5A]);
      final bundledProbe = File(p.join(binDir.path, probeExe))
        ..writeAsBytesSync([0x4D, 0x5A]);

      try {
        expect(FfmpegLocator.instance.resolveFfprobe(), bundledProbe.path);
      } finally {
        bundled.deleteSync();
        bundledProbe.deleteSync();
        try {
          binDir.deleteSync();
        } catch (_) {}
        FfmpegLocator.instance.clearCache();
      }
    });

    test('resolveFfprobe falls back to PATH name when no sibling exists', () {
      expect(FfmpegLocator.instance.resolveFfprobe(), 'ffprobe');
    });
  });
}
