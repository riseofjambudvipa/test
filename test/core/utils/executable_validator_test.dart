import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/utils/executable_validator.dart';
import '../../test_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final env = TestEnvironment();

  setUp(() async {
    await env.initialize(silenceLogs: true);
  });

  tearDown(() async {
    await env.cleanUp();
  });

  group('ExecutableValidator Tests', () {
    final shell = Platform.isWindows ? 'cmd.exe' : '/bin/sh';
    List<String> shellArgs(String command) =>
        Platform.isWindows ? ['/c', command] : ['-c', command];

    group('Valid vs Invalid Executable Paths and Extensions', () {
      test('validates a known valid executable on the current platform', () async {
        // Platform.resolvedExecutable is the Dart/Flutter test binary currently running
        bool avxCalled = false;
        final isValid = await validateExecutable(
          Platform.resolvedExecutable,
          ['--version'],
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isTrue);
        expect(avxCalled, isFalse);
      });

      test('ExecutableValidator class validate method delegates to validateExecutable', () async {
        bool avxCalled = false;
        final isValid = await ExecutableValidator.validate(
          Platform.resolvedExecutable,
          ['--version'],
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isTrue);
        expect(avxCalled, isFalse);
      });

      test('validates a valid script/executable via platform shell', () async {
        bool avxCalled = false;
        final isValid = await validateExecutable(
          shell,
          shellArgs('exit 0'),
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isTrue);
        expect(avxCalled, isFalse);
      });

      test('returns false for text files (.txt)', () async {
        final textFile = File(p.join(env.tempDir.path, 'sample.txt'))
          ..writeAsStringSync('This is not an executable file.');

        bool avxCalled = false;
        final isValid = await validateExecutable(
          textFile.path,
          [],
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isFalse);
        expect(avxCalled, isFalse);
      });

      test('returns false for JSON and other non-executable file extensions', () async {
        final jsonFile = File(p.join(env.tempDir.path, 'config.json'))
          ..writeAsStringSync('{"key": "value"}');

        bool avxCalled = false;
        final isJsonValid = await validateExecutable(
          jsonFile.path,
          [],
          onAvxDetected: () async => avxCalled = true,
        );
        expect(isJsonValid, isFalse);

        final pngFile = File(p.join(env.tempDir.path, 'image.png'))
          ..writeAsBytesSync([0x89, 0x50, 0x4E, 0x47]);
        final isPngValid = await validateExecutable(
          pngFile.path,
          [],
          onAvxDetected: () async => avxCalled = true,
        );
        expect(isPngValid, isFalse);
        expect(avxCalled, isFalse);
      });
    });

    group('Non-Existent Files and Directories', () {
      test('returns false for non-existent executable file path', () async {
        final missingPath = p.join(env.tempDir.path, 'completely_missing_binary.exe');

        bool avxCalled = false;
        final isValid = await validateExecutable(
          missingPath,
          ['--version'],
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isFalse);
        expect(avxCalled, isFalse);
      });

      test('returns false for non-existent nested directory path', () async {
        final missingNestedPath = p.join(
          env.tempDir.path,
          'non_existent_folder',
          'nested',
          'binary.exe',
        );

        bool avxCalled = false;
        final isValid = await validateExecutable(
          missingNestedPath,
          [],
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isFalse);
        expect(avxCalled, isFalse);
      });

      test('returns false for a directory path', () async {
        bool avxCalled = false;
        // Attempting to execute a directory must return false without throwing
        final isValid = await validateExecutable(
          env.tempDir.path,
          [],
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isFalse);
        expect(avxCalled, isFalse);
      });

      test('returns false for system temp directory', () async {
        bool avxCalled = false;
        final isValid = await validateExecutable(
          Directory.systemTemp.path,
          [],
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isFalse);
        expect(avxCalled, isFalse);
      });

      test('returns false for empty or whitespace paths', () async {
        bool avxCalled = false;
        expect(
          await validateExecutable('', [], onAvxDetected: () async => avxCalled = true),
          isFalse,
        );
        expect(
          await validateExecutable('   ', [], onAvxDetected: () async => avxCalled = true),
          isFalse,
        );
        expect(avxCalled, isFalse);
      });
    });

    group('FFmpeg Validation (-version check)', () {
      test('returns true when exit code is 0 and output contains ffmpeg', () async {
        bool avxCalled = false;
        final args = ['-version', ...shellArgs('echo ffmpeg version 6.1.1-full_build')];
        final isValid = await validateExecutable(
          shell,
          args,
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isTrue);
        expect(avxCalled, isFalse);
      });

      test('returns false when output does not contain ffmpeg', () async {
        bool avxCalled = false;
        final args = ['-version', ...shellArgs('echo some_other_utility v1.0.0')];
        final isValid = await validateExecutable(
          shell,
          args,
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isFalse);
        expect(avxCalled, isFalse);
      });

      test('returns false when output contains ffmpeg but exit code is non-zero', () async {
        bool avxCalled = false;
        // Output contains ffmpeg but exit code is 2
        final cmd = Platform.isWindows
            ? 'echo ffmpeg version && exit 2'
            : 'echo ffmpeg version && exit 2';
        final args = ['-version', ...shellArgs(cmd)];
        final isValid = await validateExecutable(
          shell,
          args,
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isFalse);
        expect(avxCalled, isFalse);
      });
    });

    group('Whisper Validation (--help and -h check)', () {
      test('returns true when --help output contains usage', () async {
        bool avxCalled = false;
        final args = ['--help', ...shellArgs('echo usage: whisper [options]')];
        final isValid = await validateExecutable(
          shell,
          args,
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isTrue);
        expect(avxCalled, isFalse);
      });

      test('returns true when -h output contains whisper keyword and exit code is 1', () async {
        bool avxCalled = false;
        final cmd = Platform.isWindows
            ? 'echo whisper cli options && exit 1'
            : 'echo whisper cli options && exit 1';
        final args = ['-h', ...shellArgs(cmd)];
        final isValid = await validateExecutable(
          shell,
          args,
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isTrue);
        expect(avxCalled, isFalse);
      });

      test('returns true when output contains model keyword', () async {
        bool avxCalled = false;
        final args = ['--help', ...shellArgs('echo available ggml model options')];
        final isValid = await validateExecutable(
          shell,
          args,
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isTrue);
        expect(avxCalled, isFalse);
      });

      test('returns false when help output does not contain usage, whisper, or model', () async {
        bool avxCalled = false;
        final args = ['--help', ...shellArgs('echo unrelated generic output')];
        final isValid = await validateExecutable(
          shell,
          args,
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isFalse);
        expect(avxCalled, isFalse);
      });

      test('returns false when help output has keywords but exit code is > 1', () async {
        bool avxCalled = false;
        final cmd = Platform.isWindows
            ? 'echo usage whisper model && exit 2'
            : 'echo usage whisper model && exit 2';
        final args = ['--help', ...shellArgs(cmd)];
        final isValid = await validateExecutable(
          shell,
          args,
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isFalse);
        expect(avxCalled, isFalse);
      });
    });

    group('AVX Crash Detection and Auto-Recovery', () {
      test('detects STATUS_ILLEGAL_INSTRUCTION (-1073741795 / 0xC000001D) and triggers onAvxDetected', () async {
        bool avxCalled = false;
        final cmd = Platform.isWindows
            ? 'exit -1073741795'
            : 'exit 255'; // on Linux, test with negative code simulation
        final args = shellArgs(cmd);

        if (Platform.isWindows) {
          final isValid = await validateExecutable(
            shell,
            args,
            onAvxDetected: () async => avxCalled = true,
          );

          expect(isValid, isFalse);
          expect(avxCalled, isTrue);
          expect(SettingsService.instance.forceNoAvx, isTrue);
        }
      });

      test('detects SIGILL (-4) exit code and triggers onAvxDetected', () async {
        bool avxCalled = false;
        final cmd = 'exit -4';
        final args = shellArgs(cmd);

        final isValid = await validateExecutable(
          shell,
          args,
          onAvxDetected: () async => avxCalled = true,
        );

        expect(isValid, isFalse);
        expect(avxCalled, isTrue);
        expect(SettingsService.instance.forceNoAvx, isTrue);
      });
    });

    group('downloadNoAvxWhisperAndRevalidate', () {
      test('handles errors gracefully without unhandled exceptions', () async {
        bool revalidated = false;

        await downloadNoAvxWhisperAndRevalidate(
          onPathResolved: (_) {},
          revalidate: () async => revalidated = true,
        );

        // Regardless of whether download succeeded or failed in test environment,
        // revalidate callback must be called so caller clears in-flight state.
        expect(revalidated, isTrue);
      });
    });
  });
}
