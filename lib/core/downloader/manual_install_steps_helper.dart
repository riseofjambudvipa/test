import 'dart:io';
import 'package:path/path.dart' as p;
import '../logger/logger_service.dart';
import '../utils/app_dirs.dart';
import 'binary_download_models.dart';

/// Helper to generate step-by-step fallback commands for manual compilation
/// of whisper.cpp when pre-compiled binary downloads are unavailable.
class ManualInstallStepsHelper {
  ManualInstallStepsHelper._();

  /// Steps for compiling or installing Whisper CLI on Linux distros.
  static Future<List<ManualInstallStep>> getLinuxWhisperSteps() async {
    String distro = 'Ubuntu';
    try {
      final f = File('/etc/os-release');
      if (f.existsSync()) {
        final content = await f.readAsString();
        if (content.contains('fedora')) {
          distro = 'Fedora';
        } else if (content.contains('arch')) {
          distro = 'Arch';
        }
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'ManualInstallStepsHelper',
          'Failed to read /etc/os-release: $e');
    }

    final String targetBinPath = p.join(AppDirs.bin, 'whisper-cli');

    if (distro == 'Fedora') {
      return [
        const ManualInstallStep(
          title: 'Install compilation dependencies',
          command: 'sudo dnf install -y git make gcc-c++ sdl2-devel',
        ),
        const ManualInstallStep(
          title: 'Clone and build whisper.cpp',
          command: 'git clone https://github.com/ggerganov/whisper.cpp.git && cd whisper.cpp && make',
        ),
        ManualInstallStep(
          title: 'Copy compiled binary to CapStudio bin path',
          command: 'cp whisper.cpp/main "$targetBinPath"',
        ),
      ];
    } else if (distro == 'Arch') {
      return [
        const ManualInstallStep(
          title: 'Install whisper-cpp from AUR or official packages',
          command: 'sudo pacman -S whisper-cpp',
        ),
        ManualInstallStep(
          title: 'Link or copy package executable to CapStudio bin',
          command: 'ln -s /usr/bin/whisper-cpp "$targetBinPath"',
        ),
      ];
    } else {
      // Ubuntu/Debian fallback
      return [
        const ManualInstallStep(
          title: 'Install compilation dependencies',
          command: 'sudo apt update && sudo apt install -y git build-essential',
        ),
        const ManualInstallStep(
          title: 'Clone and compile whisper.cpp',
          command: 'git clone https://github.com/ggerganov/whisper.cpp.git && cd whisper.cpp && make',
        ),
        ManualInstallStep(
          title: 'Copy built executable to CapStudio',
          command: 'cp whisper.cpp/main "$targetBinPath"',
        ),
      ];
    }
  }

  /// Steps for installing Whisper CLI on macOS (Homebrew or Xcode Command Line Tools).
  static Future<List<ManualInstallStep>> getMacWhisperSteps() async {
    final String targetBinPath = p.join(AppDirs.bin, 'whisper-cli');

    try {
      final result = await Process.run('brew', ['--version']);
      if (result.exitCode == 0) {
        return [
          const ManualInstallStep(
            title: 'Install whisper-cpp via Homebrew',
            command: 'brew install whisper-cpp',
          ),
          ManualInstallStep(
            title: 'Link executable to CapStudio bin path',
            command: 'ln -sf "\$(brew --prefix whisper-cpp)/bin/whisper-cli" "$targetBinPath"',
          ),
        ];
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'ManualInstallStepsHelper',
          'Failed to check Homebrew version: $e');
    }

    return [
      const ManualInstallStep(
        title: 'Install Xcode Command Line Tools (if missing)',
        command: 'xcode-select --install',
      ),
      const ManualInstallStep(
        title: 'Clone and build whisper.cpp',
        command: 'git clone https://github.com/ggerganov/whisper.cpp.git && cd whisper.cpp && make',
      ),
      ManualInstallStep(
        title: 'Copy compiled binary to CapStudio bin path',
        command: 'cp whisper.cpp/main "$targetBinPath"',
      ),
    ];
  }
}
