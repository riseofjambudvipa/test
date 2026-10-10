import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path/path.dart' as p;
import '../utils/app_dirs.dart';
import '../ffmpeg/ffmpeg_locator.dart';
import '../logger/logger_service.dart';
import 'video_probe.dart';

/// Configuration and status for an editing proxy stream.
class VideoProxyInfo {
  final String sourcePath;
  final String proxyPath;
  final bool exists;
  final int targetResolutionHeight;
  final double fileSizeMB;

  const VideoProxyInfo({
    required this.sourcePath,
    required this.proxyPath,
    required this.exists,
    this.targetResolutionHeight = 720,
    this.fileSizeMB = 0.0,
  });
}

/// Manages lightweight editing proxies for 4K / high-bitrate video footage.
///
/// Offline AI editing of 4K ProRes/HEVC files often causes frame drops and
/// scrubber lag during editing on mid-tier hardware. [VideoProxyService]
/// provides transparent fast 720p H.264 proxy transcode with seamless
/// player switching and automatic uncompromised 4K final export.
class VideoProxyService {
  VideoProxyService._internal();
  static final VideoProxyService instance = VideoProxyService._internal();

  @visibleForTesting
  Future<ProcessResult> Function(
    String executable,
    List<String> arguments,
  )? processRunner;

  /// Returns directory where proxy videos are cached.
  String get proxyDirectory {
    try {
      final dir = p.join(AppDirs.support, 'proxies');
      if (!kIsWeb) {
        Directory(dir).createSync(recursive: true);
      }
      return dir;
    } catch (_) {
      final fallback = p.join(Directory.systemTemp.path, 'capstudio_proxies');
      try {
        Directory(fallback).createSync(recursive: true);
      } catch (_) {}
      return fallback;
    }
  }

  /// Calculates canonical proxy file path for a project.
  String getProxyPath(String projectId, [String? sourceVideoPath]) {
    final sanitizedId = projectId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return p.join(proxyDirectory, '${sanitizedId}_proxy_720p.mp4');
  }

  /// Determines if a video would benefit from proxy editing (e.g. 1080p60, 1440p, 4K, 8K).
  bool shouldSuggestProxy({
    required int width,
    required int height,
    double? duration,
  }) {
    // 4K and ultra HD
    if (width >= 3840 || height >= 2160) return true;
    // Ultrawide or 1440p
    if (width >= 2560 || height >= 1440) return true;
    // Standard 1080p with long duration (> 10 minutes)
    if (duration != null && duration > 600 && (width >= 1920 || height >= 1080)) {
      return true;
    }
    return false;
  }

  /// Returns information about the proxy file for [projectId] and [sourceVideoPath].
  Future<VideoProxyInfo> getProxyInfo(String projectId, String sourceVideoPath) async {
    final proxyPath = getProxyPath(projectId, sourceVideoPath);
    final proxyFile = File(proxyPath);
    final exists = await proxyFile.exists();
    double sizeMB = 0.0;
    if (exists) {
      try {
        final bytes = await proxyFile.length();
        sizeMB = bytes / (1024 * 1024);
      } catch (_) {}
    }
    return VideoProxyInfo(
      sourcePath: sourceVideoPath,
      proxyPath: proxyPath,
      exists: exists && sizeMB > 0.01,
      targetResolutionHeight: 720,
      fileSizeMB: sizeMB,
    );
  }

  /// Generates a fast 720p editing proxy for [sourceVideoPath] using local FFmpeg.
  Future<String?> generateProxy({
    required String projectId,
    required String sourceVideoPath,
    void Function(double progress)? onProgress,
    int targetHeight = 720,
    bool forceRegenerate = false,
  }) async {
    if (kIsWeb) return null;

    final sourceFile = File(sourceVideoPath);
    if (!await sourceFile.exists()) {
      LoggerService.instance.log(LogLevel.error, 'VideoProxyService',
          'Source video file does not exist: $sourceVideoPath');
      return null;
    }

    final proxyPath = getProxyPath(projectId, sourceVideoPath);
    final proxyFile = File(proxyPath);
    if (!forceRegenerate && await proxyFile.exists() && await proxyFile.length() > 1024) {
      onProgress?.call(1.0);
      return proxyPath;
    }

    final stagingPath = '$proxyPath.partial';
    final stagingFile = File(stagingPath);
    if (await stagingFile.exists()) {
      try {
        await stagingFile.delete();
      } catch (_) {}
    }

    final ffmpegPath = FfmpegLocator.instance.resolve();
    LoggerService.instance.log(LogLevel.action, 'VideoProxyService',
        'Generating editing proxy: $sourceVideoPath -> $proxyPath');

    // Probe duration to report accurate progress
    double totalDuration = 60.0;
    try {
      final meta = await probeVideoMetadata(
        videoPath: sourceVideoPath,
        ffprobePath: FfmpegLocator.instance.resolveFfprobe(),
      );
      if (meta != null && meta.duration > 0) {
        totalDuration = meta.duration;
      }
    } catch (e) {
      LoggerService.instance.debug('Could not probe video duration for proxy: $e');
    }

    // Build FFmpeg command for lightweight editing proxy
    // Scale preserving aspect ratio with even dimensions (width: -2, height: targetHeight)
    final scaleFilter = "scale='if(gt(iw,ih),-2,$targetHeight):if(gt(iw,ih),$targetHeight,-2)'";
    final List<String> args = [
      '-y',
      '-i', sourceVideoPath,
      '-vf', scaleFilter,
      '-c:v', 'libx264',
      '-preset', 'veryfast',
      '-crf', '24',
      '-c:a', 'aac',
      '-b:a', '128k',
      '-movflags', '+faststart',
      stagingPath,
    ];

    try {
      if (processRunner != null) {
        final res = await processRunner!(ffmpegPath, args);
        if (res.exitCode == 0) {
          if (await stagingFile.exists()) {
            await stagingFile.rename(proxyPath);
            onProgress?.call(1.0);
            return proxyPath;
          }
        }
        return null;
      }

      final process = await Process.start(ffmpegPath, args);
      unawaited(process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .forEach((line) {
        if (line.contains('time=') && onProgress != null) {
          final match = RegExp(r'time=(\d+):(\d+):(\d+\.?\d*)').firstMatch(line);
          if (match != null) {
            final h = double.tryParse(match.group(1) ?? '0') ?? 0;
            final m = double.tryParse(match.group(2) ?? '0') ?? 0;
            final s = double.tryParse(match.group(3) ?? '0') ?? 0;
            final currentSec = (h * 3600) + (m * 60) + s;
            final pct = (currentSec / totalDuration).clamp(0.0, 0.99);
            onProgress(pct);
          }
        }
      }));

      final exitCode = await process.exitCode;
      if (exitCode == 0 && await stagingFile.exists()) {
        await stagingFile.rename(proxyPath);
        onProgress?.call(1.0);
        LoggerService.instance.log(LogLevel.info, 'VideoProxyService',
            'Editing proxy generated successfully: $proxyPath');
        return proxyPath;
      } else {
        LoggerService.instance.log(LogLevel.error, 'VideoProxyService',
            'Editing proxy generation failed. Exit code: $exitCode');
        if (await stagingFile.exists()) {
          try { await stagingFile.delete(); } catch (_) {}
        }
        return null;
      }
    } catch (e, st) {
      LoggerService.instance.log(LogLevel.error, 'VideoProxyService',
          'Exception generating editing proxy: $e', stackTrace: st);
      if (await stagingFile.exists()) {
        try { await stagingFile.delete(); } catch (_) {}
      }
      return null;
    }
  }

  /// Deletes the proxy file for [projectId] if it exists. Returns true if deleted.
  Future<bool> deleteProxy(String projectId, String sourceVideoPath) async {
    try {
      final path = getProxyPath(projectId, sourceVideoPath);
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        LoggerService.instance.log(LogLevel.info, 'VideoProxyService',
            'Deleted editing proxy: $path');
        return true;
      }
      return false;
    } catch (e) {
      LoggerService.instance.debug('Error deleting proxy: $e');
      return false;
    }
  }

  /// Clears all stored editing proxies from cache.
  Future<int> clearAllProxies() async {
    int deletedCount = 0;
    try {
      final dir = Directory(proxyDirectory);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File && entity.path.endsWith('.mp4')) {
            try {
              await entity.delete();
              deletedCount++;
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      LoggerService.instance.debug('Error clearing proxy cache: $e');
    }
    return deletedCount;
  }
}
