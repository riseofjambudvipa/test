import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:isolate';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:meta/meta.dart';
import '../logger/logger_service.dart';
import '../settings/settings_service.dart';
import '../utils/app_dirs.dart';

enum BinaryDownloadStatus { idle, downloading, extracting, verifying, complete, failed }

class BinaryDownloadProgress {
  final String toolId;
  final BinaryDownloadStatus status;
  final double downloadProgress; // 0.0 - 1.0
  final double extractProgress;  // 0.0 - 1.0
  final int bytesReceived;
  final int totalBytes;
  final double speedBytesPerSec;
  final Duration? eta;
  final String? error;

  const BinaryDownloadProgress({
    required this.toolId,
    required this.status,
    this.downloadProgress = 0.0,
    this.extractProgress = 0.0,
    this.bytesReceived = 0,
    this.totalBytes = 0,
    this.speedBytesPerSec = 0.0,
    this.eta,
    this.error,
  });

  double get overall => (downloadProgress * 0.7) + (extractProgress * 0.3);

  String get label => switch (status) {
    BinaryDownloadStatus.idle        => 'Ready to install',
    BinaryDownloadStatus.downloading => 'Downloading ${_fmt(bytesReceived)} / ${_fmt(totalBytes)}',
    BinaryDownloadStatus.extracting  => 'Extracting executables...',
    BinaryDownloadStatus.verifying   => 'Verifying installation...',
    BinaryDownloadStatus.complete    => 'Ready and active',
    BinaryDownloadStatus.failed      => 'Error: ${error ?? "Installation failed"}',
  };

  String _fmt(int b) {
    if (b < 1024) return '$b B';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(1)} KB';
    return '${(b / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class ManualInstallStep {
  final String title;
  final String command;

  const ManualInstallStep({required this.title, required this.command});
}

class ManualInstallRequiredException implements Exception {
  final String platform;
  final String toolId;
  final List<ManualInstallStep> steps;

  ManualInstallRequiredException({
    required this.platform,
    required this.toolId,
    required this.steps,
  });

  @override
  String toString() {
    return 'Manual installation required for $toolId on $platform.';
  }
}

class BinaryDownloaderService {
  BinaryDownloaderService._();
  static final BinaryDownloaderService instance = BinaryDownloaderService._();

  /// Mockable HTTP client for offline unit testing
  @visibleForTesting
  HttpClient? httpClient;

  /// Enable checksum verification. Can be disabled in unit tests to allow mock payloads.
  @visibleForTesting
  bool verifyChecksumsEnabled = true;

  final Map<String, StreamController<BinaryDownloadProgress>> _streams = {};
  final Map<String, HttpClient> _ioClients = {};
  final Map<String, Isolate> _activeIsolates = {};

  Stream<BinaryDownloadProgress> stream(String toolId) {
    _streams[toolId] ??= StreamController<BinaryDownloadProgress>.broadcast();
    return _streams[toolId]!.stream;
  }

  void _closeStream(String toolId) {
    final ctrl = _streams.remove(toolId);
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.close();
    }
  }

  static const Map<String, String> _whisperModelSha1s = {
    'tiny.en': 'c78c86eb1a8faa21b369bcd33207cc90d64ae9df',
    'tiny': 'bd577a113a864445d4c299885e0cb97d4ba92b5f',
    'base.en': '137c40403d78fd54d454da0f9bd998f78703390c',
    'base': '465707469ff3a37a2b9b8d8f89f2f99de7299dac',
    'small.en': 'db8a495a91d927739e50b3fc1cc4c6b8f6c2d022',
    'small': '55356645c2b361a969dfd0ef2c5a50d530afd8d5',
    'medium': 'fd9727b6e1217c2f614f9b698455c4ffd82463b4',
    // FIX (supply-chain audit): 'medium.en' was in the model catalog but
    // missing from this checksum map, so its downloads silently skipped
    // integrity verification (empty expected → verify passed). SHA-1 taken
    // from whisper.cpp's official published model list
    // (github.com/ggml-org/whisper.cpp README / HF model card).
    'medium.en': '8c30f0e44ce9560643ebd10bbe50cd20eafd3723',
    'large-v3-turbo': '4af2b29d7ec73d781377bfd1758ca957a807e941',
  };

  // FIX (Issue #2, CapStudio 1.0 audit): these checksums were previously
  // scattered as inline string literals directly inside the
  // platform-branching logic below, with no explanation of *why* some
  // platforms fetch a checksum dynamically and others don't. The original
  // audit flagged this as "inconsistent" and suggested standardizing on
  // dynamic fetching everywhere — that turned out to be impossible for one
  // of these three, so the actual fix is: keep hardcoding where the
  // upstream source structurally can't support fetching, but centralize and
  // clearly document *which pinned version* each hash corresponds to, so
  // updating the pinned URL/version below and forgetting to update the
  // matching hash here is much harder to do by accident.
  //
  // - Windows FFmpeg (gyan.dev) and Linux FFmpeg (johnvansickle.com) DO
  //   publish fetchable `.sha256`/`.md5` companion files — those two stay
  //   on dynamic fetch via `_fetchChecksumFromUrl`, see `_downloadBinary`.
  // - macOS FFmpeg (evermeet.cx) does NOT publish a fetchable checksum for
  //   its static builds (confirmed: this is a known, reported limitation of
  //   evermeet.cx, not an oversight in this codebase) — pinning a known-good
  //   hash for the exact pinned version below is the correct approach here.
  // - The Windows whisper-cli binary is CapStudio's own custom build,
  //   distributed as a GitHub release rather than through a service with a
  //   checksum API — pinned for the same reason.
  //
  // IMPORTANT: if the pinned URLs in `_getDownloadUrl` below are ever
  // bumped to a newer version, these two hashes MUST be updated to match,
  // or every download on that platform will start failing checksum
  // verification. There is no dynamic-fetch fallback for these two.
  static const String _macOsFfmpeg71Sha256 =
      '5a1303c7babaffff3c32c141ff49c7f44bd3b3b3e7dcea992fd7d04b6558ef43'; // pinned to evermeet.cx ffmpeg-7.1.zip
  static const String _windowsWhisperCliAvxSha256 =
      '74f973345cb52ef5ba3ec9e7e7af8e48cc8c71722d1528603b80588a11f82e3e';
  static const String _windowsWhisperCliNoAvxSha256 =
      'da1a0c95fe9598073c4929479396c1d962ab1e777fcf5c6f1858bce679dbd6ee';


  Future<String> _fetchChecksumFromUrl(String url) async {
    final client = httpClient ?? HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      if (response.statusCode != 200) {
        throw Exception('Server returned HTTP status ${response.statusCode}');
      }
      final contents = await response.transform(const Utf8Decoder(allowMalformed: true)).join();
      return contents.trim();
    } finally {
      if (httpClient == null) {
        client.close();
      }
    }
  }

  Future<bool> _verifyChecksum(String filePath, String expectedHex) async {
    if (!verifyChecksumsEnabled) {
      LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
          'Checksum verification disabled for testing.');
      return true;
    }
    if (expectedHex.isEmpty) {
      // FIX (supply-chain audit): this used to log a warning and PASS, so any
      // download without a configured checksum was installed unverified.
      // Fail closed instead: no pinned/integrity-verified binary gets installed.
      LoggerService.instance.log(LogLevel.error, 'BinaryDownloaderService',
          'No checksum configured for $filePath. Refusing to install an unverified download.');
      return false;
    }
    try {
      final stream = File(filePath).openRead();
      String actual;
      final cleanExpected = expectedHex.trim().toLowerCase();

      if (cleanExpected.length == 32) {
        actual = (await md5.bind(stream).first).toString();
      } else if (cleanExpected.length == 40) {
        actual = (await sha1.bind(stream).first).toString();
      } else if (cleanExpected.length == 64) {
        actual = (await sha256.bind(stream).first).toString();
      } else {
        LoggerService.instance.log(LogLevel.error, 'BinaryDownloaderService',
            'Unsupported checksum format length: ${cleanExpected.length} for $filePath');
        return false;
      }

      if (actual != cleanExpected) {
        LoggerService.instance.log(LogLevel.error, 'BinaryDownloaderService',
            'Checksum mismatch for $filePath! Expected $cleanExpected, got $actual');
        return false;
      }
      return true;
    } catch (e, stackTrace) {
      LoggerService.instance.log(LogLevel.error, 'BinaryDownloaderService',
          'Failed to verify checksum for $filePath: $e', stackTrace: stackTrace);
      return false;
    }
  }


  Future<List<ManualInstallStep>> _getLinuxWhisperSteps() async {
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
    } catch (_) {}

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

  Future<String> _getLinuxArch() async {
    try {
      final result = await Process.run('uname', ['-m']);
      final out = result.stdout.toString().trim().toLowerCase();
      if (out == 'aarch64' || out == 'arm64') {
        return 'arm64';
      }
    } catch (_) {}
    return 'amd64';
  }

  // FIX (supply-chain audit): macOS whisper auto-install previously failed
  // with a generic network error and no guidance — the release URL 404s
  // because the mac-universal asset was never uploaded to the v0.0.1 GitHub
  // release. Mirror the Linux behavior: degrade to clear manual steps so the
  // user is told exactly what to run instead of staring at a vague failure.
  Future<List<ManualInstallStep>> _getMacWhisperSteps() async {
    final String targetBinPath = p.join(AppDirs.bin, 'whisper-cli');

    // Homebrew has an official whisper-cpp formula; check for it first.
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
    } catch (_) {}

    // No Homebrew — build from source (needs Xcode Command Line Tools).
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


  /// Resolve the correct download URL for a tool, auto-detecting CPU features.
  Future<String> getDownloadUrl(String toolId) async {
    if (kIsWeb) {
      throw UnsupportedError('Binary downloading is not supported on Web.');
    }
    const whisperBase = 'https://github.com/ggml-org/whisper.cpp/releases/download/v1.8.4';
    if (toolId == 'whisper') {
      if (Platform.isWindows) {
        final hasAvx = await AppDirs.cpuSupportsAvx();
        if (hasAvx) {
          LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
              'CPU supports AVX2 — downloading optimized x64 whisper build.');
          return '$whisperBase/whisper-bin-x64.zip';
        } else {
          LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
              'CPU does NOT support AVX2 — downloading custom generic (non-AVX2) whisper build.');
          return 'https://github.com/chyrenselin/Local-AI-Caption-Studio/releases/download/v0.0.1/whisper-cli-win-x64-noavx.zip';
        }
      } else if (Platform.isMacOS) {
        LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
            'macOS detected — downloading pre-compiled universal macOS whisper-cli binary.');
        return 'https://github.com/chyrenselin/Local-AI-Caption-Studio/releases/download/v0.0.1/whisper-cli-mac-universal.zip';
      } else {
        LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
            'Linux detected — downloading pre-compiled Linux whisper-cli binary.');
        return 'https://github.com/chyrenselin/Local-AI-Caption-Studio/releases/download/v0.0.1/whisper-cli-linux-x64.zip';
      }
    } else if (toolId == 'ffmpeg') {
      // GYan.dev provides official recommended Windows builds, pulling the latest stable release-essentials zip.
      if (Platform.isWindows) {
        return 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip';
      // Evermeet.cx offers macOS static builds; we pin to the stable 7.1 build to prevent runtime incompatibilities.
      } else if (Platform.isMacOS) {
        return 'https://evermeet.cx/ffmpeg/ffmpeg-7.1.zip';
      // johnvansickle.com provides stable Linux static builds; we query CPU architecture and download the corresponding release tar.xz.
      } else if (Platform.isLinux) {
        final arch = await _getLinuxArch();
        return 'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-$arch-static.tar.xz';
      }
    }
    throw ArgumentError('Unknown tool: $toolId');
  }

  Future<void> download(String toolId) async {
    if (kIsWeb) {
      throw UnsupportedError('Binary downloading is not supported on Web.');
    }
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      throw UnsupportedError('Binary downloading is not supported on mobile.');
    }
    final ctrl = _streams[toolId] ??= StreamController<BinaryDownloadProgress>.broadcast();
    void emit(BinaryDownloadProgress p) {
      if (!ctrl.isClosed) ctrl.add(p);
    }

    String? tempZipPath;
    try {
      // Use AppDirs.bin → AppData\Roaming\CapStudio\bin\
      final binDir = Directory(AppDirs.bin);
      if (!binDir.existsSync()) {
        binDir.createSync(recursive: true);
      }

      final url = await getDownloadUrl(toolId);
      final isTarXz = url.endsWith('.tar.xz');
      tempZipPath = p.join(AppDirs.support, 'temp_$toolId${isTarXz ? ".tar.xz" : ".zip"}');

      LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'Starting download of $toolId from $url');
      
      emit(BinaryDownloadProgress(
        toolId: toolId,
        status: BinaryDownloadStatus.downloading,
        downloadProgress: 0.0,
      ));

      // 1. Download with speed and ETA tracking
      await _downloadFile(
        url: url,
        savePath: tempZipPath,
        toolId: toolId,
        emit: emit,
      );

      String expectedChecksum = '';
      try {
        if (toolId == 'whisper') {
          final hasAvx = await AppDirs.cpuSupportsAvx();
          if (Platform.isWindows) {
            expectedChecksum = hasAvx
                ? _windowsWhisperCliAvxSha256
                : _windowsWhisperCliNoAvxSha256;
          }
          // FIX (supply-chain audit): macOS/Linux whisper-cli builds come from
          // the CapStudio GitHub release (v0.0.1). They previously had NO
          // checksum assigned, so — if the URL ever resolved — the download
          // would have been installed unverified. Those URLs currently 404
          // (the assets were never uploaded), and the download fails before
          // this point; the graceful manual-install fallback below handles it.
          // When real builds are published, pin their SHA-256 here so
          // verification is mandatory.
        } else if (toolId == 'ffmpeg') {
          if (Platform.isWindows) {
            expectedChecksum = await _fetchChecksumFromUrl('$url.sha256');
          } else if (Platform.isMacOS) {
            expectedChecksum = _macOsFfmpeg71Sha256;
          } else if (Platform.isLinux) {
            final rawMd5Info = await _fetchChecksumFromUrl('$url.md5');
            expectedChecksum = rawMd5Info.split(RegExp(r'\s+')).first;
          }
        }
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'BinaryDownloaderService',
            'Failed to retrieve remote checksum for $toolId: $e. Proceeding with caution.');
      }

      // 1.5 Verify checksum
      emit(BinaryDownloadProgress(
        toolId: toolId,
        status: BinaryDownloadStatus.verifying,
        downloadProgress: 1.0,
        extractProgress: 0.0,
      ));
      final checksumOk = await _verifyChecksum(tempZipPath, expectedChecksum);
      if (!checksumOk) {
        emit(BinaryDownloadProgress(
          toolId: toolId,
          status: BinaryDownloadStatus.failed,
          error: 'Download integrity check failed. File may be corrupted or tampered with.',
        ));
        try { File(tempZipPath).deleteSync(); } catch (_) {}
        _closeStream(toolId);
        return;
      }

      // 2. Extract files
      emit(BinaryDownloadProgress(
        toolId: toolId,
        status: BinaryDownloadStatus.extracting,
        downloadProgress: 1.0,
        extractProgress: 0.0,
      ));

      LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'Extracting $tempZipPath to ${binDir.path}');
      await _extractInIsolate(
        zipPath: tempZipPath,
        destDir: binDir.path,
        toolId: toolId,
        emit: emit,
      );

      // 3. Scan extracted files for the target executables
      emit(BinaryDownloadProgress(
        toolId: toolId,
        status: BinaryDownloadStatus.verifying,
        downloadProgress: 1.0,
        extractProgress: 1.0,
      ));

      final targetName = toolId == 'ffmpeg' 
          ? (Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg')
          : (Platform.isWindows ? 'whisper-cli.exe' : 'whisper-cli');

      String? foundPath;
      String? foundFfprobePath;
      final List<File> dllFiles = [];
      final ffprobeName = Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';

      // Traverse the directory tree once to find all necessary files
      final entities = binDir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          final filename = p.basename(entity.path);
          final lowerName = filename.toLowerCase();
          if (lowerName == targetName.toLowerCase()) {
            foundPath = entity.path;
          } else if (toolId == 'ffmpeg' && lowerName == ffprobeName.toLowerCase()) {
            foundFfprobePath = entity.path;
          } else if (Platform.isWindows && p.extension(entity.path).toLowerCase() == '.dll') {
            dllFiles.add(entity);
          }
        }
      }

      if (foundPath == null) {
        throw Exception('Could not find $targetName inside the downloaded package.');
      }

      // Helper to identify the root extracted directory to delete
      String? extractedDirToDelete;
      final relative = p.relative(foundPath, from: binDir.path);
      final parts = p.split(relative);
      if (parts.length > 1) {
        // The first part is the root folder name inside binDir
        extractedDirToDelete = p.join(binDir.path, parts.first);
      }

      // Copy to root binDir if needed
      final finalPath = p.join(binDir.path, targetName);
      if (foundPath != finalPath) {
        final destFile = File(finalPath);
        if (destFile.existsSync()) {
          destFile.deleteSync();
        }
        File(foundPath).copySync(finalPath);
        LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'Moved executable from $foundPath to $finalPath');
      }

      // Extract and preserve ffprobe if downloading ffmpeg
      if (toolId == 'ffmpeg' && foundFfprobePath != null) {
        final finalFfprobePath = p.join(binDir.path, ffprobeName);
        if (foundFfprobePath != finalFfprobePath) {
          final destFile = File(finalFfprobePath);
          if (destFile.existsSync()) {
            destFile.deleteSync();
          }
          File(foundFfprobePath).copySync(finalFfprobePath);
          LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'Moved ffprobe from $foundFfprobePath to $finalFfprobePath');
        }
        if (!Platform.isWindows) {
          await Process.run('chmod', ['+x', finalFfprobePath]);
        }
      }

      // Also copy all companion DLL files next to the executable on Windows
      if (Platform.isWindows) {
        for (final dllFile in dllFiles) {
          final dllName = p.basename(dllFile.path);
          final destDllPath = p.join(binDir.path, dllName);
          if (dllFile.path != destDllPath) {
            final destDllFile = File(destDllPath);
            if (destDllFile.existsSync()) {
              destDllFile.deleteSync();
            }
            dllFile.copySync(destDllPath);
            LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'Moved companion DLL: $dllName to root bin folder.');
          }
        }
      }

      // Set Executable Permissions and strip quarantine on Unix systems
      if (!Platform.isWindows) {
        LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'Granting executable permissions to $finalPath');
        final chmodResult = await Process.run('chmod', ['+x', finalPath]);
        if (chmodResult.exitCode != 0) {
          LoggerService.instance.log(LogLevel.warning, 'BinaryDownloaderService', 'chmod failed: ${chmodResult.stderr}');
        }

        if (Platform.isMacOS) {
          LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'Stripping macOS quarantine bit on $finalPath');
          final xattrResult = await Process.run('xattr', ['-d', 'com.apple.quarantine', finalPath]);
          if (xattrResult.exitCode != 0) {
            LoggerService.instance.log(LogLevel.warning, 'BinaryDownloaderService', 'xattr failed: ${xattrResult.stderr}');
          }
        }
      }

      // Clean up the temporary archive and only the specific extracted directory
      try {
        final f = File(tempZipPath);
        if (f.existsSync()) f.deleteSync();

        if (extractedDirToDelete != null) {
          final dir = Directory(extractedDirToDelete);
          if (dir.existsSync()) {
            dir.deleteSync(recursive: true);
            LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'Cleaned up extracted folder: $extractedDirToDelete');
          }
        }
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'BinaryDownloaderService', 'Cleanup failed: $e');
      }

      // Validate executable format and signature structure
      final isBinaryValid = await _verifyExecutableFormatAndSignature(finalPath);
      if (!isBinaryValid) {
        throw Exception('Downloaded file format or signature check failed for $finalPath.');
      }

      // Save paths to SharedPreferences and activate in services
      if (toolId == 'ffmpeg') {
        await SettingsService.instance.setFfmpegCliPath(finalPath);
      } else {
        await SettingsService.instance.setWhisperCliPath(finalPath);
      }

      LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'Successfully installed $toolId at $finalPath');

      emit(BinaryDownloadProgress(
        toolId: toolId,
        status: BinaryDownloadStatus.complete,
        downloadProgress: 1.0,
        extractProgress: 1.0,
      ));
      _closeStream(toolId);
    } catch (e) {
      if (tempZipPath != null) {
        try {
          final f = File(tempZipPath);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }
      LoggerService.instance.log(LogLevel.error, 'BinaryDownloaderService', 'Failed to install $toolId: $e');
      emit(BinaryDownloadProgress(
        toolId: toolId,
        status: BinaryDownloadStatus.failed,
        error: e.toString(),
      ));
      _closeStream(toolId);
      if (toolId == 'whisper' && Platform.isLinux) {
        final steps = await _getLinuxWhisperSteps();
        throw ManualInstallRequiredException(
          platform: 'Linux',
          toolId: 'whisper',
          steps: steps,
        );
      }
      if (toolId == 'whisper' && Platform.isMacOS) {
        final steps = await _getMacWhisperSteps();
        throw ManualInstallRequiredException(
          platform: 'macOS',
          toolId: 'whisper',
          steps: steps,
        );
      }
      rethrow; // Rethrow to let UI catch typed exceptions like ManualInstallRequiredException
    }
  }

  Future<void> downloadWhisperModel(String modelName) async {
    if (kIsWeb) {
      throw UnsupportedError('Whisper model downloading is not supported on Web.');
    }
    if (!RegExp(r'^[a-zA-Z0-9._-]+$').hasMatch(modelName)) {
      throw ArgumentError('Invalid whisper model name format.');
    }
    final toolId = 'model_$modelName';
    final ctrl = _streams[toolId] ??= StreamController<BinaryDownloadProgress>.broadcast();
    void emit(BinaryDownloadProgress p) {
      if (!ctrl.isClosed) ctrl.add(p);
    }

    try {
      final modelsDir = Directory(p.join(AppDirs.support, 'models'));
      if (!modelsDir.existsSync()) {
        modelsDir.createSync(recursive: true);
      }

      final savePath = p.join(modelsDir.path, 'ggml-$modelName.bin');
      final mirrors = [
        'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-$modelName.bin',
        'https://hf-mirror.com/ggerganov/whisper.cpp/resolve/main/ggml-$modelName.bin',
      ];

      String? activeUrl;
      Object? lastDownloadError;

      for (final url in mirrors) {
        try {
          LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'Starting download of whisper model $modelName from $url');
          emit(BinaryDownloadProgress(
            toolId: toolId,
            status: BinaryDownloadStatus.downloading,
            downloadProgress: 0.0,
          ));

          await _downloadFile(
            url: url,
            savePath: savePath,
            toolId: toolId,
            emit: emit,
          );
          activeUrl = url;
          break; // Download succeeded!
        } catch (e) {
          lastDownloadError = e;
          LoggerService.instance.log(LogLevel.warning, 'BinaryDownloaderService', 'Mirror $url failed: $e');
        }
      }

      if (activeUrl == null) {
        throw lastDownloadError ?? Exception('All mirrors failed to download ggml-$modelName.bin');
      }

      final expectedChecksum = _whisperModelSha1s[modelName] ?? '';

      emit(BinaryDownloadProgress(
        toolId: toolId,
        status: BinaryDownloadStatus.verifying,
        downloadProgress: 1.0,
        extractProgress: 0.0,
      ));
      final checksumOk = await _verifyChecksum(savePath, expectedChecksum);
      if (!checksumOk) {
        emit(BinaryDownloadProgress(
          toolId: toolId,
          status: BinaryDownloadStatus.failed,
          error: 'Download integrity check failed. File may be corrupted or tampered with.',
        ));
        try { File(savePath).deleteSync(); } catch (_) {}
        _closeStream(toolId);
        return;
      }

      emit(BinaryDownloadProgress(
        toolId: toolId,
        status: BinaryDownloadStatus.complete,
        downloadProgress: 1.0,
        extractProgress: 1.0,
      ));

      // Configure active model in settings
      await SettingsService.instance.setWhisperModelPath(savePath);
      await SettingsService.instance.setWhisperModelName(modelName);

      LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'Successfully downloaded and configured model $modelName');
      _closeStream(toolId);
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'BinaryDownloaderService', 'Failed to download model $modelName: $e');
      emit(BinaryDownloadProgress(
        toolId: toolId,
        status: BinaryDownloadStatus.failed,
        error: e.toString(),
      ));
      _closeStream(toolId);
    }
  }

  /// Download a file with proper redirect following and retry logic.
  Future<void> _downloadFile({
    required String url,
    required String savePath,
    required String toolId,
    required void Function(BinaryDownloadProgress) emit,
  }) async {
    const maxRetries = 3;
    Exception? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _downloadFileAttempt(
          url: url,
          savePath: savePath,
          toolId: toolId,
          emit: emit,
        );
        return; // Success!
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        LoggerService.instance.log(LogLevel.warning, 'BinaryDownloaderService',
            'Download attempt $attempt/$maxRetries failed: $e');

        if (attempt < maxRetries) {
          // Exponential backoff: 1s, 2s
          await Future<void>.delayed(Duration(seconds: attempt));
          emit(BinaryDownloadProgress(
            toolId: toolId,
            status: BinaryDownloadStatus.downloading,
            downloadProgress: 0.0,
            error: 'Retrying... (attempt ${attempt + 1}/$maxRetries)',
          ));
        }
      }
    }
    throw lastError ?? Exception('Download failed after $maxRetries attempts');
  }

  Future<void> _downloadFileAttempt({
    required String url,
    required String savePath,
    required String toolId,
    required void Function(BinaryDownloadProgress) emit,
  }) async {
    final file = File(savePath);
    if (file.existsSync()) {
      file.deleteSync();
    }

    final client = httpClient ?? HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    client.autoUncompress = false; // We want raw bytes
    _ioClients[toolId] = client;

    try {
      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = true;
      request.maxRedirects = 10;

      final response = await request.close();

      if (response.statusCode != 200) {
        throw Exception('Server returned HTTP status ${response.statusCode}');
      }

      final totalBytes = response.contentLength;
      int received = 0;
      final start = DateTime.now();

      // Use a scoped try/finally to guarantee the sink is always closed,
      // even if an exception is thrown during the data stream.
      final sink = file.openWrite();
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;

          final ms = DateTime.now().difference(start).inMilliseconds;
          final speed = ms > 0 ? received / (ms / 1000.0) : 0.0;
          final eta = speed > 0 && totalBytes > 0
              ? Duration(seconds: ((totalBytes - received) / speed).round())
              : null;

          emit(BinaryDownloadProgress(
            toolId: toolId,
            status: BinaryDownloadStatus.downloading,
            downloadProgress: totalBytes > 0 ? (received / totalBytes).clamp(0.0, 1.0) : 0.5,
            bytesReceived: received,
            totalBytes: totalBytes,
            speedBytesPerSec: speed,
            eta: eta,
          ));
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      // Validate that download is reasonably large (not a redirect/error HTML page)
      final downloadedSize = file.lengthSync();
      if (downloadedSize < 50 * 1024) { // Less than 50KB is suspicious (e.g. error HTML page)
        throw Exception(
          'Downloaded file is only ${(downloadedSize / 1024).toStringAsFixed(1)} KB — '
          'likely a redirect page or error. Expected a multi-MB archive.',
        );
      }

      LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
          'Download complete: ${(downloadedSize / (1024 * 1024)).toStringAsFixed(1)} MB');
    } finally {
      if (httpClient == null) {
        client.close();
      }
      _ioClients.remove(toolId);
    }
  }

  Future<void> _extractInIsolate({
    required String zipPath,
    required String destDir,
    required String toolId,
    required void Function(BinaryDownloadProgress) emit,
  }) async {
    final port = ReceivePort();
    final isolate = await Isolate.spawn(_extractEntry, [zipPath, destDir, port.sendPort]);
    _activeIsolates[toolId] = isolate;
    
    try {
      await for (final msg in port) {
        if (msg is double) {
          emit(BinaryDownloadProgress(
            toolId: toolId,
            status: BinaryDownloadStatus.extracting,
            downloadProgress: 1.0,
            extractProgress: msg,
          ));
        } else if (msg == 'done') {
          port.close();
          break;
        } else if (msg is String && msg.startsWith('err:')) {
          port.close();
          throw Exception(msg.substring(4));
        }
      }
    } finally {
      _activeIsolates.remove(toolId);
      port.close();
    }
  }

  static void _extractEntry(List<dynamic> args) {
    final zip = args[0] as String;
    final dest = args[1] as String;
    final port = args[2] as SendPort;
    try {
      // Check if it's a tar.xz archive (Linux static builds)
      if (zip.endsWith('.tar.xz')) {
        // Step 1: List entries and reject any with path traversal
        final listResult = Process.runSync('tar', ['-tf', zip]);
        if (listResult.exitCode != 0) {
          throw Exception('Failed to list tar.xz entries: ${listResult.stderr}');
        }
        final canonicalDest = p.canonicalize(dest);
        for (final entry in listResult.stdout.toString().split('\n')) {
          final trimmed = entry.trim();
          if (trimmed.isEmpty) continue;
          final resolved = p.canonicalize(p.join(dest, trimmed));
          if (!p.isWithin(canonicalDest, resolved) && resolved != canonicalDest) {
            throw Exception('Malicious tar entry detected (path traversal): $trimmed');
          }
        }
        // Step 2: Safe extraction
        final processResult = Process.runSync('tar', ['--no-overwrite-dir', '-xf', zip, '-C', dest]);
        if (processResult.exitCode != 0) {
          throw Exception('Failed to extract tar.xz archive: ${processResult.stderr}');
        }
        port.send(1.0);
      } else {
        final inputStream = InputFileStream(zip);
        final archive = ZipDecoder().decodeStream(inputStream);
        final total = archive.files.length;
        final String canonicalDest = p.canonicalize(dest);
        for (int i = 0; i < total; i++) {
          final f = archive.files[i];
          if (f.isFile) {
            final out = p.join(dest, f.name);
            final String canonicalOut = p.canonicalize(out);
            if (!p.isWithin(canonicalDest, canonicalOut) && canonicalOut != canonicalDest) {
              inputStream.close();
              throw Exception('Malicious zip entry path detected (Zip Slip): ${f.name}');
            }
            Directory(p.dirname(out)).createSync(recursive: true);
            final outStream = OutputFileStream(out);
            f.writeContent(outStream);
            outStream.close();
          }
          if (i % 20 == 0 || i == total - 1) {
            port.send((i + 1) / total);
          }
        }
        inputStream.close();
      }
      port.send('done');
    } catch (e) {
      port.send('err:$e');
    }
  }

  Future<bool> _verifyExecutableFormatAndSignature(String path) async {
    if (!verifyChecksumsEnabled) {
      LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
          'Executable format/signature verification bypassed for unit testing.');
      return true;
    }

    final file = File(path);
    if (!file.existsSync()) {
      LoggerService.instance.log(LogLevel.error, 'BinaryDownloaderService', 'Executable file does not exist: $path');
      return false;
    }

    final bytes = await file.openRead(0, 4).first;
    if (bytes.length < 4) {
      LoggerService.instance.log(LogLevel.error, 'BinaryDownloaderService', 'File is too short to be a valid executable: $path');
      return false;
    }

    if (Platform.isWindows) {
      // PE executable: starts with 'MZ' (hex 4D, 5A)
      if (bytes[0] != 0x4D || bytes[1] != 0x5A) {
        LoggerService.instance.log(LogLevel.error, 'BinaryDownloaderService', 'Invalid PE binary magic bytes on Windows: $path');
        return false;
      }
      try {
        final result = await Process.run('powershell', [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          'Get-AuthenticodeSignature -FilePath "$path" | Select-Object -ExpandProperty Status'
        ]);
        final status = result.stdout.toString().trim();
        LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'Windows Authenticode signature status: $status');
        if (status == 'HashMismatch') {
          LoggerService.instance.log(LogLevel.error, 'BinaryDownloaderService', 'Authenticode validation failed: Hash mismatch (file corrupted or tampered).');
          return false;
        }
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'BinaryDownloaderService', 'Failed to run Authenticode signature check: $e');
      }
    } else if (Platform.isLinux) {
      // ELF executable: starts with 0x7F 'E' 'L' 'F' (hex 7F, 45, 4C, 46)
      if (bytes[0] != 0x7F || bytes[1] != 0x45 || bytes[2] != 0x4C || bytes[3] != 0x46) {
        LoggerService.instance.log(LogLevel.error, 'BinaryDownloaderService', 'Invalid ELF binary magic bytes on Linux: $path');
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
        LoggerService.instance.log(LogLevel.error, 'BinaryDownloaderService', 'Invalid Mach-O binary magic bytes on macOS: $path');
        return false;
      }
      try {
        final result = await Process.run('codesign', ['--verify', '--verbose', path]);
        final output = '${result.stdout}\n${result.stderr}'.trim();
        LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'macOS codesign verify status:\n$output');
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'BinaryDownloaderService', 'Failed to run macOS codesign verification: $e');
      }
    }

    return true;
  }

  void cancel(String toolId) {
    _ioClients[toolId]?.close(force: true);
    _ioClients.remove(toolId);
    final isolate = _activeIsolates.remove(toolId);
    if (isolate != null) {
      try {
        isolate.kill(priority: Isolate.beforeNextEvent);
      } catch (_) {}
    }
    _closeStream(toolId);
  }
}
