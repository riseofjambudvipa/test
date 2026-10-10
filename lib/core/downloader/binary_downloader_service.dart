import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:isolate';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:meta/meta.dart';
import '../logger/logger_service.dart';
import '../settings/settings_service.dart';
import '../utils/app_dirs.dart';
import '../assets/asset_path_service.dart';
import 'binary_download_models.dart';
import 'binary_verifier.dart';
import 'archive_extractor.dart';
import 'manual_install_steps_helper.dart';
import 'http_file_downloader.dart';

export 'binary_download_models.dart';

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
        LoggerService.instance.log(LogLevel.warning, 'BinaryDownloaderService',
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
    return ManualInstallStepsHelper.getLinuxWhisperSteps();
  }

  Future<String> _getLinuxArch() async {
    try {
      final result = await Process.run('uname', ['-m']);
      final out = result.stdout.toString().trim().toLowerCase();
      if (out == 'aarch64' || out == 'arm64') {
        return 'arm64';
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'BinaryDownloaderService',
          'Failed to detect Linux architecture: $e');
    }
    return 'amd64';
  }

  Future<List<ManualInstallStep>> _getMacWhisperSteps() async {
    return ManualInstallStepsHelper.getMacWhisperSteps();
  }


  /// Resolve the primary download URL for a tool, auto-detecting CPU features.
  Future<String> getDownloadUrl(String toolId) async {
    final urls = await getDownloadUrls(toolId);
    return urls.first;
  }

  /// Resolve candidate download URLs (with fast CDN mirrors and official fallbacks).
  Future<List<String>> getDownloadUrls(String toolId) async {
    if (kIsWeb) {
      throw UnsupportedError('Binary downloading is not supported on Web.');
    }
    const releaseBase = 'https://github.com/riseofjambudvipa/test/releases/download/test';
    if (toolId == 'whisper') {
      if (Platform.isWindows) {
        final arch = AppDirs.getCpuArchitecture().toLowerCase();
        final isArm64 = arch.contains('arm') ||
            (Platform.environment['PROCESSOR_ARCHITECTURE']?.toUpperCase() == 'ARM64') ||
            (Platform.environment['PROCESSOR_ARCHITEW6432']?.toUpperCase() == 'ARM64');
        if (isArm64) {
          LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
              'Windows ARM64 detected — downloading whisper-cli-win-arm64.zip (fallback x64-noavx).');
          return [
            '$releaseBase/whisper-cli-win-arm64.zip',
            '$releaseBase/whisper-cli-win-x64-noavx.zip',
            '$releaseBase/whisper-windows.zip',
          ];
        }
        final forceNoAvx = SettingsService.instance.forceNoAvx;
        final hasAvx = !forceNoAvx && await AppDirs.cpuSupportsAvx();
        final zipName = hasAvx ? 'whisper-cli-win-x64-avx.zip' : 'whisper-cli-win-x64-noavx.zip';
        LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
            'Windows detected (${hasAvx ? "AVX" : "No-AVX"}) — downloading $zipName.');
        return ['$releaseBase/$zipName', '$releaseBase/whisper-cli-win-x64-noavx.zip', '$releaseBase/whisper-windows.zip'];
      } else if (Platform.isMacOS) {
        final isArm = AppDirs.isAppleSilicon();
        LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
            'macOS detected (${isArm ? "Apple Silicon" : "Intel"}) — downloading universal macOS whisper build.');
        return [
          '$releaseBase/whisper-cli-mac-universal.zip',
          if (isArm) '$releaseBase/whisper-cli-mac-arm64.zip',
          '$releaseBase/whisper-macos.zip',
        ];
      } else {
        final arch = await _getLinuxArch();
        LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
            'Linux detected ($arch) — downloading pre-compiled Linux whisper build.');
        if (arch == 'arm64') {
          return [
            '$releaseBase/whisper-cli-linux-arm64.zip',
            '$releaseBase/whisper-linux-arm64.zip',
            '$releaseBase/whisper-cli-linux-x64.zip',
            '$releaseBase/whisper-linux.zip',
          ];
        }
        return [
          '$releaseBase/whisper-cli-linux-x64.zip',
          '$releaseBase/whisper-linux.zip',
        ];
      }
    } else if (toolId == 'ffmpeg') {
      if (Platform.isWindows) {
        final arch = AppDirs.getCpuArchitecture().toLowerCase();
        final isArm64 = arch.contains('arm') ||
            (Platform.environment['PROCESSOR_ARCHITECTURE']?.toUpperCase() == 'ARM64') ||
            (Platform.environment['PROCESSOR_ARCHITEW6432']?.toUpperCase() == 'ARM64');
        if (isArm64) {
          return [
            '$releaseBase/ffmpeg-windows-arm64.zip',
            'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-winarm64-gpl.zip',
            '$releaseBase/ffmpeg-windows.zip',
          ];
        }
        // High-speed release bundle + GitHub CDN GyanD 7.1 mirror + gyan.dev fallback
        return [
          '$releaseBase/ffmpeg-windows.zip',
          'https://github.com/GyanD/codexffmpeg/releases/download/7.1/ffmpeg-7.1-essentials_build.zip',
          'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip',
        ];
      } else if (Platform.isMacOS) {
        final isArm = AppDirs.isAppleSilicon();
        return [
          if (isArm) '$releaseBase/ffmpeg-macos-arm64.zip',
          '$releaseBase/ffmpeg-macos-universal.zip',
          '$releaseBase/ffmpeg-macos.zip',
          'https://evermeet.cx/ffmpeg/ffmpeg-7.1.zip',
        ];
      } else if (Platform.isLinux) {
        final arch = await _getLinuxArch();
        return [
          '$releaseBase/ffmpeg-linux-$arch.zip',
          '$releaseBase/ffmpeg-linux.zip',
          if (arch == 'arm64')
            'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linuxarm64-gpl.tar.xz'
          else ...[
            'https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz',
            'https://johnvansickle.com/ffmpeg/releases/ffmpeg-release-amd64-static.tar.xz',
          ],
        ];
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
      // Use custom assets drive bin if configured, otherwise AppDirs.bin
      final binDir = AssetPathService.instance.hasCustomStorage
          ? Directory(AssetPathService.instance.binDir)
          : Directory(AppDirs.bin);
      if (!binDir.existsSync()) {
        binDir.createSync(recursive: true);
      }

      final mirrors = await getDownloadUrls(toolId);
      final isTarXz = mirrors.first.endsWith('.tar.xz');
      tempZipPath = p.join(AppDirs.support, 'temp_$toolId${isTarXz ? ".tar.xz" : ".zip"}');

      // Fast-path: check if a local whisper bundle is already present
      bool skipDownload = false;
      if (toolId == 'whisper' && httpClient == null) {
        final winArch = AppDirs.getCpuArchitecture().toLowerCase();
        final isWinArm = winArch.contains('arm') ||
            (Platform.environment['PROCESSOR_ARCHITECTURE']?.toUpperCase() == 'ARM64');
        final forceNoAvx = SettingsService.instance.forceNoAvx;
        final hasAvx = !forceNoAvx && await AppDirs.cpuSupportsAvx();
        final preferredWinZip = isWinArm
            ? 'whisper-cli-win-arm64.zip'
            : (hasAvx ? 'whisper-cli-win-x64-avx.zip' : 'whisper-cli-win-x64-noavx.zip');
        final linuxArch = Platform.isLinux ? await _getLinuxArch() : 'amd64';
        final candidateNames = Platform.isWindows
            ? [preferredWinZip, 'whisper-cli-win-arm64.zip', 'whisper-cli-win-x64-avx.zip', 'whisper-cli-win-x64-noavx.zip', 'whisper-windows.zip']
            : (Platform.isMacOS
                ? ['whisper-cli-mac-universal.zip', 'whisper-cli-mac-arm64.zip', 'whisper-macos.zip']
                : ['whisper-cli-linux-$linuxArch.zip', 'whisper-cli-linux-x64.zip', 'whisper-linux.zip']);
        final candidateDirs = [
          p.join(Directory.current.path, 'assets', 'archive'),
          p.join(p.dirname(Platform.resolvedExecutable), 'data', 'flutter_assets', 'assets', 'archive'),
          p.join(AppDirs.support, 'assets', 'archive'),
        ];
        for (final dir in candidateDirs) {
          for (final archiveName in candidateNames) {
            final localArchive = File(p.join(dir, archiveName));
            if (localArchive.existsSync() && localArchive.lengthSync() > 0) {
              LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
                  'Found local whisper archive bundle at ${localArchive.path}. Copying to temp.');
              localArchive.copySync(tempZipPath);
              skipDownload = true;
              break;
            }
          }
          if (skipDownload) break;
        }
      }

      bool installReady = false;
      if (skipDownload) {
        installReady = true;
      } else {
        for (final url in mirrors) {
          try {
            LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'Starting download of $toolId from $url');
            emit(BinaryDownloadProgress(
              toolId: toolId,
              status: BinaryDownloadStatus.downloading,
              downloadProgress: 0.0,
            ));

            await _downloadFile(
              url: url,
              savePath: tempZipPath,
              toolId: toolId,
              emit: emit,
            );

            String expectedChecksum = '';
            // 1. Dynamic fetch from companion file (.sha256 or .md5)
            try {
              final isMd5 = url.endsWith('.tar.xz');
              final companionExt = isMd5 ? '.md5' : '.sha256';
              final raw = await _fetchChecksumFromUrl('$url$companionExt');
              final candidate = raw.split(RegExp(r'\s+')).first.trim().toLowerCase();
              if (candidate.length == 32 || candidate.length == 40 || candidate.length == 64) {
                expectedChecksum = candidate;
                LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
                    'Resolved dynamic release checksum for $toolId: $expectedChecksum');
              }
            } catch (e) {
              LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
                  'Dynamic checksum not available for $url ($e).');
            }

            emit(BinaryDownloadProgress(
              toolId: toolId,
              status: BinaryDownloadStatus.verifying,
              downloadProgress: 1.0,
              extractProgress: 0.0,
            ));

            final checksumOk = await _verifyChecksum(tempZipPath, expectedChecksum);
            if (!checksumOk) {
              throw Exception('Download integrity check failed for $url');
            }

            installReady = true;
            break;
          } catch (e) {
            LoggerService.instance.log(LogLevel.warning, 'BinaryDownloaderService',
                'Download from mirror $url failed: $e');
            try {
              final f = File(tempZipPath);
              if (f.existsSync()) f.deleteSync();
              final part = File('$tempZipPath.part');
              if (part.existsSync()) part.deleteSync();
            } catch (_) {}
          }
        }

        if (!installReady) {
          emit(BinaryDownloadProgress(
            toolId: toolId,
            status: BinaryDownloadStatus.failed,
            error: 'Download integrity check failed. File may be corrupted or tampered with.',
          ));
          try {
            final f = File(tempZipPath);
            if (f.existsSync()) f.deleteSync();
            final part = File('$tempZipPath.part');
            if (part.existsSync()) part.deleteSync();
          } catch (_) {}
          _closeStream(toolId);
          return;
        }
      }

      // 2. Extract files
      emit(BinaryDownloadProgress(
        toolId: toolId,
        status: BinaryDownloadStatus.extracting,
        downloadProgress: 1.0,
        extractProgress: 0.0,
      ));

      LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService', 'Extracting $tempZipPath to ${binDir.path}');

      if (toolId == 'whisper') {
        final stagingDir = Directory(p.join(AppDirs.support, 'staging_whisper_${DateTime.now().millisecondsSinceEpoch}'));
        if (!stagingDir.existsSync()) stagingDir.createSync(recursive: true);

        try {
          await _extractInIsolate(
            zipPath: tempZipPath,
            destDir: stagingDir.path,
            toolId: toolId,
            emit: emit,
          );

          // Check if stagingDir contains nested zip archives or the binary directly
          final stagedFiles = stagingDir.listSync(recursive: true);
          File? innerZipToExtract;

          if (Platform.isWindows) {
            final winArch = AppDirs.getCpuArchitecture().toLowerCase();
            final isWinArm = winArch.contains('arm') ||
                (Platform.environment['PROCESSOR_ARCHITECTURE']?.toUpperCase() == 'ARM64');
            if (isWinArm) {
              final arm64Zip = File(p.join(stagingDir.path, 'whisper-cli-win-arm64.zip'));
              if (arm64Zip.existsSync()) innerZipToExtract = arm64Zip;
            }
            if (innerZipToExtract == null) {
              final hasAvx = await AppDirs.cpuSupportsAvx();
              LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
                  hasAvx ? 'CPU supports AVX2 — selecting AVX build.' : 'CPU lacks AVX2 — selecting non-AVX build.');
              final avxZip = File(p.join(stagingDir.path, 'whisper-cli-win-x64-avx.zip'));
              final noAvxZip = File(p.join(stagingDir.path, 'whisper-cli-win-x64-noavx.zip'));
              if (hasAvx && avxZip.existsSync()) {
                innerZipToExtract = avxZip;
              } else if (noAvxZip.existsSync()) {
                innerZipToExtract = noAvxZip;
              } else if (avxZip.existsSync()) {
                innerZipToExtract = avxZip;
              }
            }
          } else if (Platform.isMacOS) {
            final macZip = File(p.join(stagingDir.path, 'whisper-cli-mac-universal.zip'));
            final macArmZip = File(p.join(stagingDir.path, 'whisper-cli-mac-arm64.zip'));
            if (macZip.existsSync()) {
              innerZipToExtract = macZip;
            } else if (AppDirs.isAppleSilicon() && macArmZip.existsSync()) {
              innerZipToExtract = macArmZip;
            }
          } else if (Platform.isLinux) {
            final arch = await _getLinuxArch();
            final archZip = File(p.join(stagingDir.path, 'whisper-cli-linux-$arch.zip'));
            final linuxZip = File(p.join(stagingDir.path, 'whisper-cli-linux-x64.zip'));
            if (archZip.existsSync()) {
              innerZipToExtract = archZip;
            } else if (linuxZip.existsSync()) {
              innerZipToExtract = linuxZip;
            }
          }

          if (innerZipToExtract != null && innerZipToExtract.existsSync()) {
            final companionSha = File('${innerZipToExtract.path}.sha256');
            if (companionSha.existsSync()) {
              final expectedInnerSha = companionSha.readAsStringSync().split(RegExp(r'\s+')).first.trim();
              if (expectedInnerSha.isNotEmpty) {
                final innerOk = await _verifyChecksum(innerZipToExtract.path, expectedInnerSha);
                if (!innerOk) {
                  throw Exception('Nested archive integrity check failed for ${innerZipToExtract.path}');
                }
                LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
                    'Verified nested whisper archive checksum from staged companion .sha256.');
              }
            }
            LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
                'Extracting nested whisper binary archive: ${innerZipToExtract.path}');
            await _extractInIsolate(
              zipPath: innerZipToExtract.path,
              destDir: binDir.path,
              toolId: toolId,
              emit: emit,
            );
          } else {
            // Flat archive or mock test archive: copy staged files into binDir
            for (final entity in stagedFiles) {
              if (entity is File && !entity.path.endsWith('.zip') && !entity.path.endsWith('.sha256')) {
                final base = p.basename(entity.path);
                final lower = base.toLowerCase();
                final isLicense = lower.startsWith('license') || lower.startsWith('copying') || lower == 'gpl.txt';
                final destName = isLicense ? '${toolId}_LICENSE.txt' : base;
                final dest = p.join(binDir.path, destName);
                entity.copySync(dest);
              }
            }
          }
        } finally {
          try {
            if (stagingDir.existsSync()) stagingDir.deleteSync(recursive: true);
          } catch (e) {
            LoggerService.instance.debug('Error cleaning staging dir: $e');
          }
        }
      } else {
        await _extractInIsolate(
          zipPath: tempZipPath,
          destDir: binDir.path,
          toolId: toolId,
          emit: emit,
        );
      }

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
      File? foundLicenseFile;
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
          } else if (lowerName.startsWith('license') || lowerName.startsWith('copying') || lowerName == 'gpl.txt') {
            foundLicenseFile = entity;
          }
        }
      }

      if (foundPath == null) {
        throw Exception('Could not find $targetName inside the downloaded package.');
      }

      // Preserve open-source license as ${toolId}_LICENSE.txt so tools never overwrite each other
      final destLicensePath = p.join(binDir.path, '${toolId}_LICENSE.txt');
      if (foundLicenseFile != null && foundLicenseFile.path != destLicensePath) {
        try {
          foundLicenseFile.copySync(destLicensePath);
          LoggerService.instance.log(LogLevel.info, 'BinaryDownloaderService',
              'Preserved $toolId open-source license as ${toolId}_LICENSE.txt');
        } catch (_) {}
      }
      // Migrate un-namespaced generic LICENSE.txt in root binDir if present
      final genericLicense = File(p.join(binDir.path, 'LICENSE.txt'));
      if (genericLicense.existsSync()) {
        final targetLicense = File(destLicensePath);
        if (!targetLicense.existsSync()) {
          try {
            genericLicense.renameSync(targetLicense.path);
          } catch (_) {}
        } else {
          try {
            genericLicense.deleteSync();
          } catch (_) {}
        }
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
      final isBinaryValid = await BinaryVerifier.verifyExecutableFormatAndSignature(
        finalPath,
        verifyChecksumsEnabled: verifyChecksumsEnabled,
      );
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
        } catch (e) {
          LoggerService.instance.debug('Failed to delete tempZipPath on error: $e');
        }
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
      final modelsDir = Directory(AssetPathService.instance.modelsDir);
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

      String expectedChecksum = '';
      try {
        final raw = await _fetchChecksumFromUrl('$activeUrl.sha256');
        expectedChecksum = raw.split(RegExp(r'\s+')).first.trim();
      } catch (_) {
        try {
          final raw = await _fetchChecksumFromUrl('$activeUrl.sha1');
          expectedChecksum = raw.split(RegExp(r'\s+')).first.trim();
        } catch (_) {}
      }

      if (expectedChecksum.isNotEmpty) {
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
          try {
            File(savePath).deleteSync();
          } catch (e) {
            LoggerService.instance.debug('Failed to delete corrupted savePath: $e');
          }
          _closeStream(toolId);
          return;
        }
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
    await HttpFileDownloader.downloadFile(
      url: url,
      savePath: savePath,
      toolId: toolId,
      emit: emit,
      customHttpClient: httpClient,
      activeClients: _ioClients,
    );
  }

  Future<void> _extractInIsolate({
    required String zipPath,
    required String destDir,
    required String toolId,
    required void Function(BinaryDownloadProgress) emit,
  }) async {
    await ArchiveExtractor.extractInIsolate(
      zipPath: zipPath,
      destDir: destDir,
      toolId: toolId,
      emit: emit,
      onIsolateSpawned: (isolate) => _activeIsolates[toolId] = isolate,
      onIsolateCompleted: () => _activeIsolates.remove(toolId),
    );
  }

  void cancel(String toolId) {
    _ioClients[toolId]?.close(force: true);
    _ioClients.remove(toolId);
    final isolate = _activeIsolates.remove(toolId);
    if (isolate != null) {
      try {
        isolate.kill(priority: Isolate.beforeNextEvent);
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'BinaryDownloaderService',
            'Failed to kill isolate for $toolId: $e');
      }
    }
    _closeStream(toolId);
  }
}
