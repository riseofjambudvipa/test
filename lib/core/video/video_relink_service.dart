import 'dart:io';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import '../database/schemas/project.dart';
import '../logger/logger_service.dart';
import '../settings/settings_service.dart';
import '../ffmpeg/ffmpeg_service.dart';
import 'video_web_helper.dart';

class VideoRelinkService {
  VideoRelinkService._internal();
  static final VideoRelinkService instance = VideoRelinkService._internal();

  /// Mockable process runner for unit testing offline
  Future<ProcessResult> Function(String executable, List<String> arguments)? processRunner;

  /// Check if the video file exists locally on disk
  bool checkVideoExists(String path) {
    if (path.isEmpty) return false;
    if (kIsWeb) {
      return checkVideoExistsWeb(path);
    }
    final file = File(path);
    return file.existsSync();
  }

  /// Launch the native OS file picker to select a replacement video file
  Future<String?> pickVideoFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'webm', 'mkv', 'avi', 'm4v'],
      );

      if (result != null) {
        if (kIsWeb) {
          return getPlatformFilePathWeb(result.files.single);
        } else if (result.files.single.path != null) {
          return result.files.single.path;
        }
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'VideoRelinkService', 'Failed to open file picker: $e');
    }
    return null;
  }

  String _getFfprobePath() {
    // 1. Check if a custom ffmpeg path is set in SettingsService
    final customFfmpeg = SettingsService.instance.ffmpegCliPath;
    if (customFfmpeg != null && customFfmpeg.isNotEmpty) {
      final dir = p.dirname(customFfmpeg);
      final filename = Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';
      final path = p.join(dir, filename);
      if (File(path).existsSync()) {
        return path;
      }
    }

    // 2. Check bundled asset directories
    final filename = Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';
    final assetPaths = [
      p.join(Directory.current.path, 'assets', 'bin', filename),
      p.join(Directory.current.path, 'Capstudio Flutter', 'assets', 'bin', filename),
      p.join(Directory.current.path, 'data', 'flutter_assets', 'assets', 'bin', filename),
    ];
    for (final path in assetPaths) {
      if (File(path).existsSync()) {
        return path;
      }
    }

    // 3. Fallback to global command
    return 'ffprobe';
  }

  Future<double> _getVideoDuration(String path) async {
    if (kIsWeb) {
      return await getVideoDurationWeb(path);
    }
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final info = await FfmpegService.instance.probeVideo(path);
        final duration = (info['duration'] as num?)?.toDouble() ?? 0.0;
        LoggerService.instance.log(LogLevel.info, 'VideoRelink', 'Mobile ffprobe duration check: $duration');
        return duration;
      } catch (e) {
        LoggerService.instance.log(LogLevel.error, 'VideoRelinkService', 'Failed to probe video duration on mobile: $e');
        return 0.0;
      }
    }

    final ffprobeBin = _getFfprobePath();
    try {
      final process = processRunner != null
          ? await processRunner!(ffprobeBin, ['-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', path])
          : await Process.run(
              ffprobeBin,
              ['-v', 'error', '-show_entries', 'format=duration', '-of', 'default=noprint_wrappers=1:nokey=1', path],
            );
      if (process.exitCode == 0) {
        final out = process.stdout.toString().trim();
        final parsed = double.tryParse(out);
        if (parsed != null && parsed > 0) return parsed;
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'VideoRelinkService', 'Failed to probe video duration: $e');
    }
    return 0.0;
  }

  /// Validates if the selected video is consistent with the project and updates paths
  Future<RelinkResult> validateAndRelink({
    required Project project,
    required String newPath,
    required Future<void> Function() onSave,
    required void Function(Project) onReload,
  }) async {
    if (newPath.isEmpty) {
      return RelinkResult.failure('Selected path is empty.');
    }
    if (!checkVideoExists(newPath)) {
      return RelinkResult.failure('Selected video file does not exist on disk.');
    }

    // 1. Basic Filename sanity check (optional warning, but let them link)
    final oldName = p.basename(project.videoPath);
    final newName = p.basename(newPath);
    String? warningMessage;
    
    if (oldName != newName) {
      warningMessage = 'Re-linking file with a different name ($oldName -> $newName)';
      LoggerService.instance.log(LogLevel.warning, 'VideoRelinkService', warningMessage);
    }

    // 2. Validate duration compatibility to prevent out-of-bounds subtitle crashes (CAT-15)
    final newDuration = await _getVideoDuration(newPath);
    final tolerance = math.max(2.0, project.duration * 0.01);
    if (newDuration > 0.0 && (newDuration - project.duration).abs() > tolerance) {
      final error = 'Selected video duration (${newDuration.toStringAsFixed(2)}s) does not match original project duration (${project.duration.toStringAsFixed(2)}s).';
      LoggerService.instance.log(LogLevel.error, 'VideoRelinkService', 'Relink aborted: $error');
      return RelinkResult.failure(error);
    }

    // 3. Update the project state path
    final oldPath = project.videoPath;
    String finalPath = newPath;
    
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      try {
        final docDir = await getApplicationDocumentsDirectory();
        final videosDir = Directory(p.join(docDir.path, 'videos'));
        if (!await videosDir.exists()) {
          await videosDir.create(recursive: true);
        }
        final ext = p.extension(newPath);
        final newFileName = 'vid_${DateTime.now().millisecondsSinceEpoch}_relinked_${math.Random().nextInt(10000)}$ext';
        final newPersistentPath = p.join(videosDir.path, newFileName);
        
        LoggerService.instance.log(LogLevel.info, 'VideoRelinkService', 'Copying relinked video from $newPath to persistent path: $newPersistentPath');
        await File(newPath).copy(newPersistentPath);
        finalPath = newPersistentPath;
      } catch (e) {
        LoggerService.instance.log(LogLevel.error, 'VideoRelinkService', 'Failed to copy relinked video to persistent storage: $e');
        return RelinkResult.failure('Failed to copy video to app storage: $e');
      }
    }
    
    project.videoPath = finalPath;
    
    try {
      // Save to the database
      await onSave();
    } catch (e) {
      project.videoPath = oldPath;
      if (finalPath != oldPath) {
        try {
          final fileToDelete = File(finalPath);
          if (fileToDelete.existsSync()) {
            fileToDelete.deleteSync();
          }
        } catch (cleanupError) {
          LoggerService.instance.log(
            LogLevel.warning,
            'VideoRelinkService',
            'Failed to clean up orphaned relinked video file at $finalPath: $cleanupError',
          );
        }
      }
      LoggerService.instance.log(LogLevel.error, 'VideoRelinkService', 'Failed to save project after relink: $e');
      return RelinkResult.failure('Failed to save project after relink: $e');
    }
    
    // Emit new state to trigger preview reload
    onReload(project);
    return RelinkResult.success(warningMessage: warningMessage);
  }
}

class RelinkResult {
  final bool success;
  final String? errorMessage;
  final String? warningMessage;
  const RelinkResult({
    required this.success,
    this.errorMessage,
    this.warningMessage,
  });

  factory RelinkResult.success({String? warningMessage}) =>
      RelinkResult(success: true, warningMessage: warningMessage);

  factory RelinkResult.failure(String error) =>
      RelinkResult(success: false, errorMessage: error);
}
