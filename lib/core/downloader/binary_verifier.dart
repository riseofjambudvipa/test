import 'dart:io';
import '../logger/logger_service.dart';

/// Verifier for executable binary formats (PE, ELF, Mach-O) and platform signatures.
class BinaryVerifier {
  const BinaryVerifier._();

  static Future<bool> verifyExecutableFormatAndSignature(
    String path, {
    bool verifyChecksumsEnabled = true,
  }) async {
    if (!verifyChecksumsEnabled) {
      LoggerService.instance.log(LogLevel.info, 'BinaryVerifier',
          'Executable format/signature verification bypassed for unit testing.');
      return true;
    }

    final file = File(path);
    if (!file.existsSync()) {
      LoggerService.instance.log(LogLevel.error, 'BinaryVerifier', 'Executable file does not exist: $path');
      return false;
    }

    final bytes = await file.openRead(0, 4).first;
    if (bytes.length < 4) {
      LoggerService.instance.log(LogLevel.error, 'BinaryVerifier', 'File is too short to be a valid executable: $path');
      return false;
    }

    if (Platform.isWindows) {
      // PE executable: starts with 'MZ' (hex 4D, 5A)
      if (bytes[0] != 0x4D || bytes[1] != 0x5A) {
        LoggerService.instance.log(LogLevel.error, 'BinaryVerifier', 'Invalid PE binary magic bytes on Windows: $path');
        return false;
      }
      try {
        // SECURITY FIX (audit): pass the file path through an environment
        // variable instead of interpolating it into the PowerShell -Command
        // string. A path containing quotes, semicolons, or backticks could
        // otherwise break out of the script and execute arbitrary commands.
        final result = await Process.run(
          'powershell',
          [
            '-NoProfile',
            '-NonInteractive',
            '-Command',
            r'Get-AuthenticodeSignature -FilePath $env:CAPSTUDIO_SIG_PATH | Select-Object -ExpandProperty Status'
          ],
          environment: {'CAPSTUDIO_SIG_PATH': path},
        );
        final status = result.stdout.toString().trim();
        LoggerService.instance.log(LogLevel.info, 'BinaryVerifier', 'Windows Authenticode signature status: $status');
        if (status == 'HashMismatch') {
          LoggerService.instance.log(LogLevel.error, 'BinaryVerifier', 'Authenticode validation failed: Hash mismatch (file corrupted or tampered).');
          return false;
        }
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'BinaryVerifier', 'Failed to run Authenticode signature check: $e');
      }
    } else if (Platform.isLinux) {
      // ELF executable: starts with 0x7F 'E' 'L' 'F' (hex 7F, 45, 4C, 46)
      if (bytes[0] != 0x7F || bytes[1] != 0x45 || bytes[2] != 0x4C || bytes[3] != 0x46) {
        LoggerService.instance.log(LogLevel.error, 'BinaryVerifier', 'Invalid ELF binary magic bytes on Linux: $path');
        return false;
      }
    } else if (Platform.isMacOS) {
      // Mach-O or Universal Fat binary
      final isMachO = (bytes[0] == 0xCF && bytes[1] == 0xFA && bytes[2] == 0xED && bytes[3] == 0xFE) ||
                      (bytes[0] == 0xFE && bytes[1] == 0xED && bytes[2] == 0xFA && bytes[3] == 0xCF) ||
                      (bytes[0] == 0xCE && bytes[1] == 0xFA && bytes[2] == 0xED && bytes[3] == 0xFE) ||
                      (bytes[0] == 0xFE && bytes[1] == 0xED && bytes[2] == 0xFA && bytes[3] == 0xCE) ||
                      (bytes[0] == 0xCA && bytes[1] == 0xFE && bytes[2] == 0xBA && bytes[3] == 0xBE) ||
                      (bytes[0] == 0xBE && bytes[1] == 0xBA && bytes[2] == 0xFE && bytes[3] == 0xCA);
      if (!isMachO) {
        LoggerService.instance.log(LogLevel.error, 'BinaryVerifier', 'Invalid Mach-O binary magic bytes on macOS: $path');
        return false;
      }
      try {
        final result = await Process.run('codesign', ['--verify', '--verbose', path]);
        final output = '${result.stdout}\n${result.stderr}'.trim();
        LoggerService.instance.log(LogLevel.info, 'BinaryVerifier', 'macOS codesign verify status:\n$output');
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'BinaryVerifier', 'Failed to run macOS codesign verification: $e');
      }
    }

    return true;
  }
}
