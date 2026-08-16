import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../downloader/binary_downloader_service.dart';
import '../settings/settings_service.dart';

/// FIX (Issue #6, CapStudio 1.0 audit): `_validateExecutable` — including
/// the AVX-crash-detection-and-auto-recovery flow — was duplicated
/// near-verbatim between `general_settings_section.dart` and
/// `tools_setup_step.dart`, with one small, easy-to-miss drift: the
/// settings version validated `--help` output content ("usage"/"whisper"/
/// "model"), the onboarding version only checked the exit code. Single
/// implementation now, unified on the stricter (settings) content check —
/// a real whisper-cli's `--help` output will contain one of those words
/// regardless of which screen triggered the check, so this doesn't change
/// behavior for legitimate binaries, only makes the check more robust
/// against an unrelated binary that happens to exit 0/1.
///
/// UI side effects (showing a message, updating a text field, re-running
/// validation) stay with each caller via [onAvxDetected], since those are
/// specific to each screen's widgets and context.
Future<bool> validateExecutable(
  String path,
  List<String> args, {
  required Future<void> Function() onAvxDetected,
}) async {
  if (kIsWeb || Platform.isAndroid || Platform.isIOS) return false;
  try {
    final res = await Process.run(path, args, stdoutEncoding: null, stderrEncoding: null)
        .timeout(const Duration(seconds: 5));
    final stdout = (res.stdout is List<int>) ? String.fromCharCodes(res.stdout as List<int>) : res.stdout.toString();
    final stderr = (res.stderr is List<int>) ? String.fromCharCodes(res.stderr as List<int>) : res.stderr.toString();
    final combined = '$stdout\n$stderr'.toLowerCase();

    // Detect STATUS_ILLEGAL_INSTRUCTION — binary requires AVX not present on this CPU
    if (res.exitCode == -1073741795 || res.exitCode == 0xC000001D) {
      await SettingsService.instance.setForceNoAvx(true);
      await onAvxDetected();
      return false;
    }

    if (args.contains('-version')) {
      return res.exitCode == 0 && combined.contains('ffmpeg');
    }
    if (args.contains('--help') || args.contains('-h')) {
      // ROBUSTNESS FIX (found in second-pass review): this previously had
      // a trailing `|| combined.isNotEmpty` clause that defeated the whole
      // point of checking for these specific words — ANY non-empty output
      // with exit code 0 or 1 would pass, meaning an unrelated binary that
      // happens to print something and exit 0/1 could be misidentified as
      // a working whisper-cli. Removed: now genuinely requires the output
      // to mention one of these words, which any real whisper-cli's
      // --help text will (it's a CLI tool named "whisper" dealing with
      // "models", and "usage" is close to universal for --help output).
      return res.exitCode == 0 || res.exitCode == 1
          ? (combined.contains('usage') || combined.contains('whisper') || combined.contains('model'))
          : false;
    }
    return res.exitCode == 0 || res.exitCode == 1;
  } catch (_) {
    return false;
  }
}

/// Triggers the shared "download the no-AVX whisper build and retry
/// validation" flow used after [onAvxDetected] fires. Kept separate from
/// the SnackBar-showing part since that's UI, not logic.
Future<void> downloadNoAvxWhisperAndRevalidate({
  required void Function(String path) onPathResolved,
  required Future<void> Function() revalidate,
}) async {
  await BinaryDownloaderService.instance.download('whisper').then((_) async {
    onPathResolved(SettingsService.instance.whisperCliPath ?? '');
    await revalidate();
  });
}
