import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/whisper/whisper_locator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    WhisperLocator.instance.clearCache();
  });

  tearDown(() {
    WhisperLocator.instance.clearCache();
  });

  group('WhisperLocator', () {
    test('returns the explicitly configured path verbatim and never caches it', () {
      expect(WhisperLocator.instance.resolve(configured: 'C:/tools/whisper-cli.exe'),
          'C:/tools/whisper-cli.exe');
      // A different explicit path takes effect immediately (no stale cache).
      expect(WhisperLocator.instance.resolve(configured: 'D:/other/whisper-cli.exe'),
          'D:/other/whisper-cli.exe');
    });

    test('discovers a bundled binary in dev-tree paths and caches the result', () {
      final exe = Platform.isWindows ? 'whisper-cli.exe' : 'whisper-cli';
      final binDir = Directory(p.join(Directory.current.path, 'assets', 'bin'));
      binDir.createSync(recursive: true);
      final bundled = File(p.join(binDir.path, exe))
        ..writeAsBytesSync([0x4D, 0x5A]);

      try {
        final first = WhisperLocator.instance.resolve();
        expect(first, bundled.path);

        // Cache hit — returns same path without re-scanning.
        expect(WhisperLocator.instance.resolve(), bundled.path);

        // After the binary is removed and the cache cleared, falls back to the default exe name.
        bundled.deleteSync();
        WhisperLocator.instance.clearCache();
        expect(WhisperLocator.instance.resolve(), exe);
      } finally {
        try {
          if (bundled.existsSync()) bundled.deleteSync();
        } catch (_) {}
        try {
          binDir.deleteSync();
        } catch (_) {}
        WhisperLocator.instance.clearCache();
      }
    });

    test('tryPath gracefully catches exceptions and returns empty string', () {
      final res = WhisperLocator.tryPath(() {
        throw StateError('AppDirs uninitialized');
      });
      expect(res, '');
    });

    test('tryPath returns resolver output on success', () {
      final res = WhisperLocator.tryPath(() => 'valid/path');
      expect(res, 'valid/path');
    });
  });
}
