import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:ffmpeg_kit_flutter_new/level.dart';
import '../../../core/database/schemas/project.dart';
import '../../../core/database/schemas/word.dart';
import '../../../core/ffmpeg/ffmpeg_locator.dart';
import '../../../core/logger/logger_service.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/assets/emoji_image.dart';
import '../../../core/video/viral_clip_models.dart' show AspectConversionMode;
import '../../../core/video/video_probe.dart' show probeVideoMetadata;
import '../../editor/domain/caption_engine.dart';
import 'ass_script_builder.dart' show generateAssScript;
import 'ffmpeg_filters.dart' show FfmpegFilterBuilder;
import '../../../core/video/background_music_models.dart' show BackgroundMusicConfig;
import '../../../core/video/b_roll_models.dart' show BRollClip;
import '../../../core/video/retention_progress_bar_models.dart';
import '../../../core/audio/audio_mastering_models.dart' show AudioMasteringConfig;
import '../../../core/audio/speaker_diarization_service.dart' show SpeakerInterval;
import '../../../core/utils/schema_clones.dart';
import 'ffmpeg_exporter.dart' show ExportProgress, SfxExportItem;

part 'ffmpeg_mobile_execution.dart';
part 'ffmpeg_desktop_execution.dart';

/// Probes the local FFmpeg build to see which hardware encoders are available
Future<List<String>> probeAvailableEncoders(String ffmpegPath) async {
  try {
    final res = await Process.run(ffmpegPath, ['-encoders']);
    if (res.exitCode != 0) return [];

    final output = res.stdout.toString();
    final List<String> available = [];
    if (output.contains('h264_nvenc')) {
      available.add('h264_nvenc');
    }
    if (output.contains('h264_videotoolbox')) {
      available.add('h264_videotoolbox');
    }
    if (output.contains('h264_qsv')) {
      available.add('h264_qsv');
    }
    return available;
  } catch (e) {
    LoggerService.instance.debug('probeAvailableEncoders failed: $e');
    return [];
  }
}

/// Executes FFmpeg exports (mobile via ffmpeg_kit, desktop via subprocesses)
/// and exposes the public export API of [FfmpegExporter]. Mixed into the
/// exporter class after the filter builder and font preparation mixins.
mixin FfmpegExecutor on FfmpegFilterBuilder {
  String _ffmpegCliPath = 'ffmpeg';
  Process? _activeProcess;
  FFmpegSession? _activeSession;

  /// Mockable process starter for unit testing offline
  @visibleForTesting
  Future<Process> Function(String executable, List<String> arguments)?
      processStarter;

  void cancelExport() {
    if (_activeProcess != null) {
      try {
        if (Platform.isWindows) {
          Process.runSync(
              'taskkill', ['/F', '/T', '/PID', _activeProcess!.pid.toString()]);
        } else {
          _activeProcess!.kill(ProcessSignal.sigkill);
        }
      } catch (e) {
        LoggerService.instance.log(LogLevel.error, 'FfmpegExporter',
            'Process force kill taskkill/sigkill failed: $e. Falling back to simple kill.');
        _activeProcess!.kill();
      }
      _activeProcess = null;
      LoggerService.instance.log(LogLevel.action, 'FfmpegExporter',
          'Active FFmpeg export process manually cancelled.');
    }

    if (_activeSession != null) {
      try {
        final sessionId = _activeSession!.getSessionId();
        FFmpegKit.cancel(sessionId);
        LoggerService.instance.log(LogLevel.action, 'FfmpegExporter',
            'Active FFmpeg mobile session $sessionId manually cancelled.');
      } catch (e) {
        LoggerService.instance.log(LogLevel.error, 'FfmpegExporter',
            'FFmpeg mobile session cancel failed: $e. Falling back to cancelAll.');
        FFmpegKit.cancel();
      }
      _activeSession = null;
    }
  }

  String get ffmpegCliPath {
    // Shared locator: explicitly-configured path wins; otherwise discovery
    // includes bundle-relative paths so a packaged app's bundled FFmpeg is
    // found (previously only Directory.current was checked, which misses the
    // bundle). See FfmpegLocator.
    return FfmpegLocator.instance.resolve(
      configured: _ffmpegCliPath == 'ffmpeg' ? null : _ffmpegCliPath,
    );
  }

  /// Configure local FFmpeg executable path
  void configureCli(String path) {
    if (path.trim().isNotEmpty) {
      _ffmpegCliPath = path;
      FfmpegLocator.instance.clearCache(); // Invalidate discovery cache
    }
  }

  /// Checks if the running FFmpeg build has subtitle/ass filter support enabled.
  Future<bool> isSubtitlesFilterSupported() async {
    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
      // Desktop bundled/system FFmpeg supports libass/subtitles.
      return true;
    }
    // For mobile (Android/iOS) running via ffmpeg_kit, check output of "-filters" command.
    try {
      final session = await FFmpegKit.execute("-filters");
      final output = await session.getOutput();
      if (output != null &&
          (output.contains('subtitles') || output.contains('ass'))) {
        return true;
      }
    } catch (e) {
      LoggerService.instance.debug('FFmpegKit execute filters check failed: $e');
    }
    return false;
  }

  /// Execute FFmpeg in a background process to burn subtitles into output video
  Stream<ExportProgress> exportVideo({
    required Project project,
    required List<Chunk> chunks,
    required String outputFilePath,
    required String tempDir,
    AspectConversionMode? conversionMode,
    bool enableAudioCrossfade = false,
    double audioCrossfadeDuration = 0.05,
    bool enableStudioSound = false,
    AudioMasteringConfig? audioMastering,
    RetentionProgressBarConfig? progressBarConfig,
    BackgroundMusicConfig? backgroundMusic,
    List<SpeakerInterval>? speakerIntervals,
    List<BRollClip>? bRollClips,
  }) async* {
    if (!Platform.environment.containsKey('FLUTTER_TEST') &&
        !File(project.videoPath).existsSync()) {
      throw FileSystemException(
          'Source video file does not exist: ${project.videoPath}',
          project.videoPath);
    }
    await prepareFonts();
    final tempFontsPath = await prepareTempFontsDir(tempDir);
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        yield* _exportVideoMobile(
          project: project,
          chunks: chunks,
          outputFilePath: outputFilePath,
          tempDir: tempDir,
          tempFontsDir: tempFontsPath,
          conversionMode: conversionMode,
          enableAudioCrossfade: enableAudioCrossfade,
          audioCrossfadeDuration: audioCrossfadeDuration,
          enableStudioSound: enableStudioSound,
          audioMastering: audioMastering,
          progressBarConfig: progressBarConfig,
          backgroundMusic: backgroundMusic,
          speakerIntervals: speakerIntervals,
          bRollClips: bRollClips,
        );
      } else {
        yield* _exportVideoDesktop(
          project: project,
          chunks: chunks,
          outputFilePath: outputFilePath,
          tempDir: tempDir,
          tempFontsDir: tempFontsPath,
          conversionMode: conversionMode,
          enableAudioCrossfade: enableAudioCrossfade,
          audioCrossfadeDuration: audioCrossfadeDuration,
          enableStudioSound: enableStudioSound,
          audioMastering: audioMastering,
          progressBarConfig: progressBarConfig,
          backgroundMusic: backgroundMusic,
          speakerIntervals: speakerIntervals,
          bRollClips: bRollClips,
        );
      }
    } finally {
      // Clean up dynamic flat fonts directory
      try {
        final dir = Directory(tempFontsPath);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      } catch (e) {
        LoggerService.instance.debug('Failed to clean up tempFontsPath: $e');
      }
    }
  }

  double _toAbsoluteTime(
      double trimmedTime, List<VideoSegmentSchema> segmentsToUse) {
    double accumulatedTrimmed = 0.0;
    for (final seg in segmentsToUse) {
      final start = seg.start ?? 0.0;
      final end = seg.end ?? 0.0;
      final duration = end - start;
      if (trimmedTime <= accumulatedTrimmed + duration) {
        return start + (trimmedTime - accumulatedTrimmed);
      }
      accumulatedTrimmed += duration;
    }
    if (segmentsToUse.isEmpty) return trimmedTime;
    return segmentsToUse.last.end ?? trimmedTime;
  }

  Stream<ExportProgress> exportVideoSlow({
    required Project project,
    required List<Chunk> chunks,
    required String outputFilePath,
    required String tempDir,
    required int fps,
    required Future<Uint8List?> Function(double time,
            {double? relativeTime, double? exportDuration})
        renderFrame,
    AspectConversionMode? conversionMode,
    bool enableAudioCrossfade = false,
    double audioCrossfadeDuration = 0.05,
    bool enableStudioSound = false,
    AudioMasteringConfig? audioMastering,
    RetentionProgressBarConfig? progressBarConfig,
    BackgroundMusicConfig? backgroundMusic,
    List<SpeakerInterval>? speakerIntervals,
    List<BRollClip>? bRollClips,
  }) async* {
    if (!Platform.environment.containsKey('FLUTTER_TEST') &&
        !File(project.videoPath).existsSync()) {
      throw FileSystemException(
          'Source video file does not exist: ${project.videoPath}',
          project.videoPath);
    }
    LoggerService.instance.log(LogLevel.action, 'FfmpegExporter',
        'Starting Slow Export (1:1 Render) at $fps FPS');
    yield const ExportProgress(progress: 0.0, status: 'rendering');

    final segmentsToUse = _buildSegments(project);
    final trimmedChunks = _buildTrimmedChunks(chunks, segmentsToUse);

    double totalDuration = 0.0;
    for (final seg in segmentsToUse) {
      totalDuration += ((seg.end ?? 0.0) - (seg.start ?? 0.0));
    }
    if (totalDuration <= 0.0) {
      totalDuration = project.duration;
    }

    final int totalFrames = (totalDuration * fps).ceil();
    // FIX (audit, unbounded growth): slow mode writes one PNG per frame, and
    // a long video at high FPS can produce tens of thousands of them (tens of
    // GB of disk). Fail fast with a clear message instead of filling the disk.
    const int maxSlowExportFrames = 50000;
    if (totalFrames > maxSlowExportFrames) {
      throw Exception(
        'Slow export would render $totalFrames frames (over the '
        '$maxSlowExportFrames limit). Use a lower target FPS or trim the '
        'video for slow mode.',
      );
    }
    final double frameDuration = 1.0 / fps;

    final String frameDir =
        p.join(tempDir, 'capstudio_frames_${project.projectId}');
    final Directory dir = Directory(frameDir);
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } catch (e) {
        LoggerService.instance.debug('Failed to delete existing frameDir: $e');
      }
    }
    dir.createSync(recursive: true);

    final List<SfxExportItem> sfxItems = [];
    final List<(WordSchema, String)> validEmojiWords = [];
    await collectEmojiAndSfx(trimmedChunks, project.config.emojiPack,
        validEmojiWords, sfxItems, tempDir);

    // Pre-decode all animated emojis into the synchronous cache
    for (final item in validEmojiWords) {
      if (await isAnimatedFile(item.$2)) {
        try {
          await EmojiFrameCache.instance.getFrames(item.$2);
        } catch (e) {
          LoggerService.instance.debug('Failed to pre-decode animated emoji: $e');
        }
      }
    }

    try {
      // 1. Render loop
      for (int i = 0; i < totalFrames; i++) {
        final double time = i * frameDuration;
        final double absoluteTime = _toAbsoluteTime(time, segmentsToUse);

        final bytes = await renderFrame(
          absoluteTime,
          relativeTime: time,
          exportDuration: totalDuration,
        );
        if (bytes == null) {
          throw Exception('Failed to render frame $i at time $absoluteTime');
        }

        final framePath =
            p.join(frameDir, 'frame_${i.toString().padLeft(8, '0')}.png');
        await File(framePath).writeAsBytes(bytes);

        final double renderProgress = (i / totalFrames) * 0.70;
        yield ExportProgress(
          progress: renderProgress,
          status: 'rendering',
        );
      }

      // 2. Prepare FFmpeg overlay command

      final List<String> baseArgs = ['-y', '-i', project.videoPath];
      final String inputSeqPattern = p.join(frameDir, 'frame_%08d.png');
      baseArgs.addAll(['-framerate', '$fps', '-i', inputSeqPattern]);

      final validBRoll = (bRollClips ?? [])
          .where((c) => c.mediaPath.isNotEmpty && File(c.mediaPath).existsSync())
          .toList();
      for (final clip in validBRoll) {
        if (clip.isVideo) {
          baseArgs.addAll(['-stream_loop', '-1', '-i', clip.mediaPath]);
        } else {
          baseArgs.addAll(['-loop', '1', '-i', clip.mediaPath]);
        }
      }

      if (backgroundMusic != null && backgroundMusic.hasMusic) {
        baseArgs.addAll(['-i', backgroundMusic.musicPath!]);
      }

      for (final item in sfxItems) {
        baseArgs.addAll(['-i', item.resolvedPath]);
      }

      int? sourceWidth;
      int? sourceHeight;
      if (conversionMode != null || project.height > project.width) {
        try {
          final metadata = await probeVideoMetadata(
            videoPath: project.videoPath,
            ffprobePath: FfmpegLocator.instance.resolveFfprobe(
              configured: SettingsService.instance.ffmpegCliPath,
            ),
          );
          if (metadata != null) {
            sourceWidth = metadata.width;
            sourceHeight = metadata.height;
          }
        } catch (e) {
          LoggerService.instance.debug('Failed to probe source dimensions in slow export: $e');
        }
      }

      final isProjectVertical = project.height > project.width;
      final Project projectForExport =
          (conversionMode != null && !isProjectVertical)
              ? (SchemaClones.cloneProjectDeep(project)
                ..width = 1080
                ..height = 1920)
              : project;

      final filterComplex = buildFilterComplexSlow(
        project: projectForExport,
        segmentsToUse: segmentsToUse,
        sfxItems: sfxItems,
        conversionMode: conversionMode,
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
        enableAudioCrossfade: enableAudioCrossfade,
        audioCrossfadeDuration: audioCrossfadeDuration,
        enableStudioSound: enableStudioSound,
        audioMastering: audioMastering,
        backgroundMusic: backgroundMusic,
        speakerIntervals: speakerIntervals,
        bRollClips: validBRoll,
      );

      baseArgs.addAll(['-filter_complex', filterComplex]);
      baseArgs.addAll(['-map', '[v_final]']);
      baseArgs.addAll(['-map', '[a_final]']);

      final settings = SettingsService.instance;
      final List<String> activeCodecArgs = [];
      bool isHardwareEncoder = false;

      if (Platform.isIOS) {
        activeCodecArgs.addAll([
          '-c:v',
          'h264_videotoolbox',
          '-b:v',
          '8M',
          '-pix_fmt',
          'yuv420p',
          '-threads',
          '${_getOptimalExportThreads()}'
        ]);
        isHardwareEncoder = true;
      } else if (Platform.isAndroid) {
        if (settings.useGpu) {
          activeCodecArgs.addAll([
            '-c:v',
            'h264_mediacodec',
            '-b:v',
            '8M',
            '-pix_fmt',
            'yuv420p',
            '-threads',
            '${_getOptimalExportThreads()}'
          ]);
          isHardwareEncoder = true;
        } else {
          activeCodecArgs.addAll([
            '-c:v',
            'libx264',
            '-preset',
            'ultrafast',
            '-crf',
            '23',
            '-pix_fmt',
            'yuv420p',
            '-threads',
            '${_getOptimalExportThreads()}'
          ]);
        }
      } else {
        if (settings.useGpu) {
          final encoder = settings.gpuEncoder;
          if (encoder == 'h264_nvenc') {
            activeCodecArgs.addAll(['-c:v', 'h264_nvenc', '-preset', 'p4']);
            isHardwareEncoder = true;
          } else if (encoder == 'h264_videotoolbox') {
            activeCodecArgs.addAll(['-c:v', 'h264_videotoolbox']);
            isHardwareEncoder = true;
          } else if (encoder == 'h264_qsv') {
            activeCodecArgs.addAll(['-c:v', 'h264_qsv']);
            isHardwareEncoder = true;
          } else {
            final available = await probeAvailableEncoders(ffmpegCliPath);
            if (available.contains('h264_videotoolbox')) {
              activeCodecArgs.addAll(['-c:v', 'h264_videotoolbox']);
              isHardwareEncoder = true;
            } else if (available.contains('h264_nvenc')) {
              activeCodecArgs.addAll(['-c:v', 'h264_nvenc', '-preset', 'p4']);
              isHardwareEncoder = true;
            } else if (available.contains('h264_qsv')) {
              activeCodecArgs.addAll(['-c:v', 'h264_qsv']);
              isHardwareEncoder = true;
            } else {
              activeCodecArgs.addAll([
                '-c:v',
                'libx264',
                '-preset',
                'fast',
                '-crf',
                '22',
                '-pix_fmt',
                'yuv420p'
              ]);
            }
          }
        } else {
          activeCodecArgs.addAll([
            '-c:v',
            'libx264',
            '-preset',
            'fast',
            '-crf',
            '22',
            '-pix_fmt',
            'yuv420p'
          ]);
        }
      }

      final ext = p.extension(outputFilePath);
      final safeExt = ext.isNotEmpty ? ext : '.mp4';
      final stagingPath = '${p.withoutExtension(outputFilePath)}_partial$safeExt';
      final stagingFile = File(stagingPath);
      final String containerFormat = safeExt.replaceFirst('.', '').toLowerCase();

      final List<String> primaryArgs = [
        ...baseArgs,
        ...activeCodecArgs,
        '-c:a',
        'aac',
        '-b:a',
        '192k',
        '-f',
        containerFormat,
        stagingPath,
      ];

      bool success = false;
      String? lastError;

      if (Platform.isAndroid || Platform.isIOS) {
        await for (final prog
            in _executeMobileFFmpeg(primaryArgs, totalDuration)) {
          final double mappedProgress = 0.70 + (prog.progress * 0.30);
          yield ExportProgress(
              progress: mappedProgress, status: prog.status, error: prog.error);
          if (prog.status == 'completed') success = true;
          if (prog.status == 'failed') lastError = prog.error;
        }
      } else {
        try {
          await for (final prog
              in _executeDesktopFFmpegProcess(primaryArgs, totalDuration)) {
            final double mappedProgress = 0.70 + (prog.progress * 0.30);
            yield ExportProgress(
                progress: mappedProgress,
                status: prog.status,
                error: prog.error);
          }
          success = true;
        } catch (e) {
          lastError = e.toString();
          if (isHardwareEncoder) {
            LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter',
                'Desktop slow hardware export failed. Falling back to software libx264.');
            final List<String> fallbackCodecArgs = [
              '-c:v',
              'libx264',
              '-preset',
              'fast',
              '-crf',
              '22',
              '-pix_fmt',
              'yuv420p'
            ];
            final List<String> fallbackArgs = [
              ...baseArgs,
              ...fallbackCodecArgs,
              '-c:a',
              'aac',
              '-b:a',
              '192k',
              '-f',
              containerFormat,
              stagingPath,
            ];
            try {
              await for (final prog in _executeDesktopFFmpegProcess(
                  fallbackArgs, totalDuration)) {
                final double mappedProgress = 0.70 + (prog.progress * 0.30);
                yield ExportProgress(
                    progress: mappedProgress,
                    status: prog.status,
                    error: prog.error);
              }
              success = true;
            } catch (fallbackErr) {
              LoggerService.instance.log(LogLevel.error, 'FfmpegExecutor', 'Fallback export failed: $fallbackErr');
              lastError = fallbackErr.toString();
              success = false;
            }
          }
        }
      }

      if (success) {
        if (stagingFile.existsSync()) {
          try {
            final destFile = File(outputFilePath);
            if (destFile.existsSync()) await destFile.delete();
            await stagingFile.rename(outputFilePath);
          } catch (e) {
            success = false;
            lastError = 'Failed to finalize staged export file: $e';
          }
        }
      }

      if (success) {
        yield const ExportProgress(progress: 1.0, status: 'completed');
      } else {
        yield ExportProgress(
            progress: 0.0,
            status: 'failed',
            error: lastError ?? 'FFmpeg slow export failed.');
      }
    } finally {
      try {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      } catch (e) {
        LoggerService.instance.debug('Failed to delete frame dir in finally: $e');
      }
    }
  }

  List<VideoSegmentSchema> _buildSegments(Project project) {
    final maxDur = project.duration > 0 ? project.duration : double.infinity;
    final activeSegments = (project.segments ?? [])
        .where((s) => !(s.isDeleted ?? false))
        .map((s) {
          final start = (s.start ?? 0.0).clamp(0.0, maxDur);
          final end = (s.end ?? maxDur).clamp(start, maxDur);
          return VideoSegmentSchema()
            ..start = start
            ..end = end
            ..isDeleted = false;
        })
        .where((s) => (s.end! - s.start!) > 0.001)
        .toList();

    if (activeSegments.isEmpty) {
      final tStart = project.trimStart.clamp(0.0, maxDur);
      final rawEnd = project.trimEnd > 0 ? project.trimEnd : project.duration;
      final tEnd = rawEnd.clamp(tStart, maxDur);
      return [
        VideoSegmentSchema()
          ..start = tStart
          ..end = tEnd > tStart ? tEnd : maxDur
          ..isDeleted = false,
      ];
    }
    return activeSegments;
  }

  double _toTrimmedTime(
      double absoluteTime, List<VideoSegmentSchema> segmentsToUse) {
    double trimmedTime = 0.0;
    for (final seg in segmentsToUse) {
      final start = seg.start ?? 0.0;
      final end = seg.end ?? 0.0;
      if (absoluteTime >= start && absoluteTime <= end) {
        return trimmedTime + (absoluteTime - start);
      }
      trimmedTime += (end - start);
    }
    if (segmentsToUse.isEmpty) return absoluteTime;
    if (absoluteTime < (segmentsToUse.first.start ?? 0.0)) return 0.0;
    return trimmedTime;
  }

  List<Chunk> _buildTrimmedChunks(
      List<Chunk> chunks, List<VideoSegmentSchema> segmentsToUse) {
    final rawTrimmed = chunks.map((c) {
      final shiftedWords = c.words.map((w) {
        final cloned = WordSchema()
          ..wordId = w.wordId
          ..text = w.text
          ..start =
              w.start != null ? _toTrimmedTime(w.start!, segmentsToUse) : null
          ..end = w.end != null ? _toTrimmedTime(w.end!, segmentsToUse) : null
          ..type = w.type
          ..confidence = w.confidence
          ..splitBefore = w.splitBefore
          ..hidden = w.hidden
          ..emoji = w.emoji
          ..soundEffect = w.soundEffect
          ..soundVolume = w.soundVolume
          ..className = w.className;
        if (w.emojiConfig != null) {
          cloned.emojiConfig = EmojiConfigSchema()
            ..x = w.emojiConfig!.x
            ..y = w.emojiConfig!.y
            ..scale = w.emojiConfig!.scale
            ..speed = w.emojiConfig!.speed;
        }
        return cloned;
      }).toList();

      return Chunk(
        index: c.index,
        startTime: _toTrimmedTime(c.startTime, segmentsToUse),
        endTime: _toTrimmedTime(c.endTime, segmentsToUse),
        words: shiftedWords,
      );
    }).toList();

    // Enforce strict non-overlapping boundary invariant between consecutive chunks
    final result = <Chunk>[];
    for (int i = 0; i < rawTrimmed.length; i++) {
      final current = rawTrimmed[i];
      double clampedEnd = current.endTime;
      if (i + 1 < rawTrimmed.length) {
        final nextStart = rawTrimmed[i + 1].startTime;
        if (clampedEnd > nextStart) {
          clampedEnd = math.max(current.startTime + 0.01, nextStart);
        }
      }
      result.add(Chunk(
        index: current.index,
        startTime: current.startTime,
        endTime: clampedEnd,
        words: current.words,
      ));
    }
    return result;
  }

  int _getOptimalExportThreads() {
    try {
      final userSetting = SettingsService.instance.exportThreads;
      if (userSetting > 0) {
        return userSetting;
      }
      final cores = Platform.numberOfProcessors;
      if (Platform.isAndroid || Platform.isIOS) {
        return cores > 4 ? 4 : 2;
      }
      return cores > 8 ? 8 : 4;
    } catch (e) {
      LoggerService.instance.debug('Error detecting optimal export threads: $e');
      return 2;
    }
  }
}
