import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
import '../../../core/logger/logger_service.dart';
import '../../../core/settings/settings_service.dart';
import '../../../core/assets/emoji_image.dart';
import '../../editor/domain/caption_engine.dart';
import 'ass_script_builder.dart' show generateAssScript;
import 'ffmpeg_filters.dart' show FfmpegFilterBuilder;
import 'ffmpeg_exporter.dart' show ExportProgress, SfxExportItem;

/// Probes the local FFmpeg build to see which hardware encoders are available
Future<List<String>> probeAvailableEncoders(String ffmpegPath) async {
  try {
    final res = await Process.run(ffmpegPath, ['-encoders']);
    if (res.exitCode != 0) return [];

    final output = res.stdout.toString();
    final List<String> available = [];
    if (output.contains('h264_nvenc')) available.add('h264_nvenc');
    if (output.contains('h264_videotoolbox')) available.add('h264_videotoolbox');
    if (output.contains('h264_qsv')) available.add('h264_qsv');
    return available;
  } catch (_) {
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
  Future<Process> Function(String executable, List<String> arguments)? processStarter;

  void cancelExport() {
    if (_activeProcess != null) {
      try {
        if (Platform.isWindows) {
          Process.runSync('taskkill', ['/F', '/T', '/PID', _activeProcess!.pid.toString()]);
        } else {
          _activeProcess!.kill(ProcessSignal.sigkill);
        }
      } catch (e) {
        LoggerService.instance.log(LogLevel.error, 'FfmpegExporter', 'Process force kill taskkill/sigkill failed: $e. Falling back to simple kill.');
        _activeProcess!.kill();
      }
      _activeProcess = null;
      LoggerService.instance.log(LogLevel.action, 'FfmpegExporter', 'Active FFmpeg export process manually cancelled.');
    }

    if (_activeSession != null) {
      try {
        final sessionId = _activeSession!.getSessionId();
        FFmpegKit.cancel(sessionId);
        LoggerService.instance.log(LogLevel.action, 'FfmpegExporter', 'Active FFmpeg mobile session $sessionId manually cancelled.');
      } catch (e) {
        LoggerService.instance.log(LogLevel.error, 'FfmpegExporter', 'FFmpeg mobile session cancel failed: $e. Falling back to cancelAll.');
        FFmpegKit.cancel();
      }
      _activeSession = null;
    }
  }

  String get ffmpegCliPath {
    if (_ffmpegCliPath == 'ffmpeg') {
      final paths = [
        p.join(Directory.current.path, 'assets', 'bin', Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg'),
        p.join(Directory.current.path, 'Capstudio Flutter', 'assets', 'bin', Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg'),
        p.join(Directory.current.path, 'data', 'flutter_assets', 'assets', 'bin', Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg'),
      ];
      for (final path in paths) {
        if (File(path).existsSync()) {
          return path;
        }
      }
    }
    return _ffmpegCliPath;
  }

  /// Configure local FFmpeg executable path
  void configureCli(String path) {
    if (path.trim().isNotEmpty) {
      _ffmpegCliPath = path;
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
      if (output != null && (output.contains('subtitles') || output.contains('ass'))) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Execute FFmpeg in a background process to burn subtitles into output video
  Stream<ExportProgress> exportVideo({
    required Project project,
    required List<Chunk> chunks,
    required String outputFilePath,
    required String tempDir,
  }) async* {
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
        );
      } else {
        yield* _exportVideoDesktop(
          project: project,
          chunks: chunks,
          outputFilePath: outputFilePath,
          tempDir: tempDir,
          tempFontsDir: tempFontsPath,
        );
      }
    } finally {
      // Clean up dynamic flat fonts directory
      try {
        final dir = Directory(tempFontsPath);
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      } catch (_) {}
    }
  }

  double _toAbsoluteTime(double trimmedTime, List<VideoSegmentSchema> segmentsToUse) {
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
    required Future<Uint8List?> Function(double time) renderFrame,
  }) async* {
    LoggerService.instance.log(LogLevel.action, 'FfmpegExporter', 'Starting Slow Export (1:1 Render) at $fps FPS');
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
    final double frameDuration = 1.0 / fps;

    final String frameDir = p.join(tempDir, 'capstudio_frames_${project.projectId}');
    final Directory dir = Directory(frameDir);
    if (dir.existsSync()) {
      try {
        dir.deleteSync(recursive: true);
      } catch (_) {}
    }
    dir.createSync(recursive: true);

    final List<SfxExportItem> sfxItems = [];
    final List<(WordSchema, String)> validEmojiWords = [];
    await collectEmojiAndSfx(trimmedChunks, project.config.emojiPack, validEmojiWords, sfxItems, tempDir);

    // Pre-decode all animated emojis into the synchronous cache
    for (final item in validEmojiWords) {
      if (await isAnimatedFile(item.$2)) {
        try {
          await EmojiFrameCache.instance.getFrames(item.$2);
        } catch (_) {}
      }
    }

    try {
      // 1. Render loop
      for (int i = 0; i < totalFrames; i++) {
        final double time = i * frameDuration;
        final double absoluteTime = _toAbsoluteTime(time, segmentsToUse);

        final bytes = await renderFrame(absoluteTime);
        if (bytes == null) {
          throw Exception('Failed to render frame $i at time $absoluteTime');
        }

        final framePath = p.join(frameDir, 'frame_${i.toString().padLeft(8, '0')}.png');
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

      for (final item in sfxItems) {
        baseArgs.addAll(['-i', item.resolvedPath]);
      }

      final filterComplex = buildFilterComplexSlow(
        project: project,
        segmentsToUse: segmentsToUse,
        sfxItems: sfxItems,
      );

      baseArgs.addAll(['-filter_complex', filterComplex]);
      baseArgs.addAll(['-map', '[v_final]']);
      baseArgs.addAll(['-map', '[a_final]']);

      final settings = SettingsService.instance;
      final List<String> activeCodecArgs = [];
      bool isHardwareEncoder = false;

      if (Platform.isIOS) {
        activeCodecArgs.addAll(['-c:v', 'h264_videotoolbox', '-b:v', '8M', '-pix_fmt', 'yuv420p', '-threads', '${_getOptimalExportThreads()}']);
        isHardwareEncoder = true;
      } else if (Platform.isAndroid) {
        if (settings.useGpu) {
          activeCodecArgs.addAll(['-c:v', 'h264_mediacodec', '-b:v', '8M', '-pix_fmt', 'yuv420p', '-threads', '${_getOptimalExportThreads()}']);
          isHardwareEncoder = true;
        } else {
          activeCodecArgs.addAll(['-c:v', 'libx264', '-preset', 'ultrafast', '-crf', '23', '-pix_fmt', 'yuv420p', '-threads', '${_getOptimalExportThreads()}']);
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
              activeCodecArgs.addAll(['-c:v', 'libx264', '-preset', 'fast', '-crf', '22', '-pix_fmt', 'yuv420p']);
            }
          }
        } else {
          activeCodecArgs.addAll(['-c:v', 'libx264', '-preset', 'fast', '-crf', '22', '-pix_fmt', 'yuv420p']);
        }
      }

      final List<String> primaryArgs = [...baseArgs, ...activeCodecArgs, '-c:a', 'aac', '-b:a', '192k', outputFilePath];

      bool success = false;
      String? lastError;

      if (Platform.isAndroid || Platform.isIOS) {
        await for (final prog in _executeMobileFFmpeg(primaryArgs, totalDuration)) {
          final double mappedProgress = 0.70 + (prog.progress * 0.30);
          yield ExportProgress(progress: mappedProgress, status: prog.status, error: prog.error);
          if (prog.status == 'completed') success = true;
          if (prog.status == 'failed') lastError = prog.error;
        }
      } else {
        try {
          await for (final prog in _executeDesktopFFmpegProcess(primaryArgs, totalDuration)) {
            final double mappedProgress = 0.70 + (prog.progress * 0.30);
            yield ExportProgress(progress: mappedProgress, status: prog.status, error: prog.error);
          }
          success = true;
        } catch (e) {
          lastError = e.toString();
          if (isHardwareEncoder) {
            LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter', 'Desktop slow hardware export failed. Falling back to software libx264.');
            final List<String> fallbackCodecArgs = ['-c:v', 'libx264', '-preset', 'fast', '-crf', '22', '-pix_fmt', 'yuv420p'];
            final List<String> fallbackArgs = [...baseArgs, ...fallbackCodecArgs, '-c:a', 'aac', '-b:a', '192k', outputFilePath];
            try {
              await for (final prog in _executeDesktopFFmpegProcess(fallbackArgs, totalDuration)) {
                final double mappedProgress = 0.70 + (prog.progress * 0.30);
                yield ExportProgress(progress: mappedProgress, status: prog.status, error: prog.error);
              }
              success = true;
            } catch (fallbackErr) {
              lastError = fallbackErr.toString();
              success = false;
            }
          }
        }
      }

      if (success) {
        yield const ExportProgress(progress: 1.0, status: 'completed');
      } else {
        yield ExportProgress(progress: 0.0, status: 'failed', error: lastError ?? 'FFmpeg slow export failed.');
      }
    } finally {
      try {
        if (dir.existsSync()) {
          dir.deleteSync(recursive: true);
        }
      } catch (_) {}
    }
  }

  List<VideoSegmentSchema> _buildSegments(Project project) {
    final activeSegments = (project.segments ?? []).where((s) => !(s.isDeleted ?? false)).toList();
    if (activeSegments.isEmpty) {
      return [
        VideoSegmentSchema()
          ..start = project.trimStart
          ..end = project.trimEnd > 0 ? project.trimEnd : project.duration
          ..isDeleted = false,
      ];
    }
    return activeSegments;
  }

  double _toTrimmedTime(double absoluteTime, List<VideoSegmentSchema> segmentsToUse) {
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

  List<Chunk> _buildTrimmedChunks(List<Chunk> chunks, List<VideoSegmentSchema> segmentsToUse) {
    return chunks.map((c) {
      final shiftedWords = c.words.map((w) {
        final cloned = WordSchema()
          ..wordId = w.wordId
          ..text = w.text
          ..start = w.start != null ? _toTrimmedTime(w.start!, segmentsToUse) : null
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
  }

  /// Mobile-specific video export using ffmpeg_kit_flutter
  Stream<ExportProgress> _exportVideoMobile({
    required Project project,
    required List<Chunk> chunks,
    required String outputFilePath,
    required String tempDir,
    String? tempFontsDir,
  }) async* {
    LoggerService.instance.log(LogLevel.action, 'FfmpegExporter', 'Starting video export to: $outputFilePath (Mobile)');
    yield const ExportProgress(progress: 0.0, status: 'rendering');

    if (tempFontsDir != null) {
      final String fontsConfigDir = p.dirname(tempFontsDir);
      await FFmpegKitConfig.setFontDirectory(fontsConfigDir);
      // Overwrite the autogenerated fonts.conf to exclude scanning /system/fonts (which consumes massive memory on low-end devices)
      try {
        final fontsConfFile = File(p.join(fontsConfigDir, 'fonts.conf'));
        final customConfig = '''
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <dir>$tempFontsDir</dir>
    <cachedir>$tempFontsDir/cache</cachedir>
    <config></config>
</fontconfig>
''';
        await fontsConfFile.writeAsString(customConfig);
        LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Customized fonts.conf to exclude system fonts and save memory.');
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter', 'Failed to customize fonts.conf: $e');
      }
    }

    final segmentsToUse = _buildSegments(project);
    final trimmedChunks = _buildTrimmedChunks(chunks, segmentsToUse);

    double totalDuration = 0.0;
    for (final seg in segmentsToUse) {
      totalDuration += ((seg.end ?? 0.0) - (seg.start ?? 0.0));
    }
    if (totalDuration <= 0.0) {
      totalDuration = project.duration;
    }

    final assContent = generateAssScript(project, trimmedChunks);
    final assPath = p.join(tempDir, '${project.projectId}_export.ass');
    final assFile = File(assPath);
    await assFile.writeAsString(assContent);
    LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Generated ASS subtitle timing script. Path: $assPath');
    LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'ASS Content:\n$assContent');

    final outputFile = File(outputFilePath);
    if (outputFile.existsSync()) {
      try {
        await outputFile.delete();
      } catch (_) {}
    }

    // FIX (Issue #2b, CapStudio 1.0 audit): everything from here down that can
    // throw is wrapped in try/finally so temp files (ASS script, fonts.conf,
    // converted emoji PNGs) are always cleaned up, even if collectEmojiAndSfx,
    // convertToPngOnMobile, or buildFilterComplex throws partway through.
    // This mirrors the guarantee _exportVideoDesktop already had — previously
    // only the desktop path cleaned up reliably on exception; mobile leaked.
    // success/temporaryConvertedFiles are declared here (outside the try) so
    // both the finally block and the post-try yield can see them.
    bool success = false;
    final List<String> temporaryConvertedFiles = [];

    try {
      final List<(WordSchema, String)> validEmojiWords = [];
      final List<SfxExportItem> sfxItems = [];
      await collectEmojiAndSfx(trimmedChunks, project.config.emojiPack, validEmojiWords, sfxItems, tempDir);
      LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Found ${validEmojiWords.length} emojis and ${sfxItems.length} sound effects to mix.');

      // On mobile, FFmpeg's decoder does not support animated WebP.
      // We convert WebP emojis to static PNGs using Flutter's native image decoder.
      final List<(WordSchema, String)> processedEmojiWords = [];
      for (final item in validEmojiWords) {
        final processedPath = await convertToPngOnMobile(item.$2, tempDir);
        processedEmojiWords.add((item.$1, processedPath));
        if (processedPath != item.$2) {
          temporaryConvertedFiles.add(processedPath);
        }
        if (item.$2.contains('rendered_emoji_')) {
          temporaryConvertedFiles.add(item.$2);
        }
      }

      final List<String> ffmpegArgs = ['-y', '-i', project.videoPath];
      for (final item in processedEmojiWords) {
        final path = item.$2.toLowerCase();
        final isAnimated = await isAnimatedFile(item.$2);
        if (path.endsWith('.gif') || (path.endsWith('.png') && isAnimated)) {
          ffmpegArgs.addAll(['-ignore_loop', '0', '-i', item.$2]);
        } else if (path.endsWith('.webp')) {
          ffmpegArgs.addAll(['-loop', '0', '-i', item.$2]);
        } else {
          ffmpegArgs.addAll(['-i', item.$2]);
        }
      }
      for (final item in sfxItems) {
        ffmpegArgs.addAll(['-i', item.resolvedPath]);
      }

      final filterComplex = buildFilterComplex(
        project: project,
        segmentsToUse: segmentsToUse,
        trimmedChunks: trimmedChunks,
        validEmojiWords: processedEmojiWords,
        sfxItems: sfxItems,
        assPath: assPath,
        tempFontsDir: tempFontsDir,
      );

      ffmpegArgs.addAll(['-filter_complex', filterComplex]);
      ffmpegArgs.addAll(['-map', '[v_final]']);
      ffmpegArgs.addAll(['-map', '[a_final]']);

      final settings = SettingsService.instance;
      final List<String> activeCodecArgs = [];
      bool isAndroidHardware = false;

      if (Platform.isIOS) {
        activeCodecArgs.addAll([
          '-c:v', 'h264_videotoolbox',
          '-b:v', '8M',
          '-pix_fmt', 'yuv420p',
          '-threads', '${_getOptimalExportThreads()}',
        ]);
      } else if (Platform.isAndroid && settings.useGpu && processedEmojiWords.isEmpty) {
        isAndroidHardware = true;
        activeCodecArgs.addAll([
          '-c:v', 'h264_mediacodec',
          '-b:v', '8M',
          '-pix_fmt', 'yuv420p',
          '-threads', '${_getOptimalExportThreads()}',
        ]);
      } else {
        activeCodecArgs.addAll([
          '-c:v', 'libx264',
          '-preset', 'ultrafast',
          '-crf', '23',
          '-pix_fmt', 'yuv420p',
          '-threads', '${_getOptimalExportThreads()}',
        ]);
      }

      final List<String> primaryArgs = [...ffmpegArgs, ...activeCodecArgs, '-c:a', 'aac', '-b:a', '192k', '-t', totalDuration.toStringAsFixed(3), outputFilePath];
      LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Mobile FFmpeg primary args: ${primaryArgs.join(" ")}');

      await for (final prog in _executeMobileFFmpeg(primaryArgs, totalDuration)) {
        yield prog;
        if (prog.status == 'completed') success = true;
      }

      // Fallback if Android hardware encoder fails
      if (!success && isAndroidHardware) {
        LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter', 'Android hardware h264_mediacodec export failed. Falling back to software libx264.');
        yield const ExportProgress(progress: 0.1, status: 'rendering', error: 'Hardware export failed. Retrying with software encoder...');

        if (outputFile.existsSync()) {
          try {
            await outputFile.delete();
          } catch (_) {}
        }

        final List<String> fallbackCodecArgs = [
          '-c:v', 'libx264',
          '-preset', 'ultrafast',
          '-crf', '23',
          '-pix_fmt', 'yuv420p',
          '-threads', '${_getOptimalExportThreads()}',
        ];
        final List<String> fallbackArgs = [...ffmpegArgs, ...fallbackCodecArgs, '-c:a', 'aac', '-b:a', '192k', '-t', totalDuration.toStringAsFixed(3), outputFilePath];
        LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Mobile FFmpeg fallback args: ${fallbackArgs.join(" ")}');

        await for (final prog in _executeMobileFFmpeg(fallbackArgs, totalDuration)) {
          yield prog;
          if (prog.status == 'completed') success = true;
        }
      }
    } finally {
      // Always runs — on success, on normal failure, AND on a thrown exception.
      try {
        await assFile.delete();
      } catch (_) {}

      // Clean up temporary fonts.conf
      if (tempFontsDir != null) {
        try {
          final configDir = p.dirname(tempFontsDir);
          final fontsConfFile = File(p.join(configDir, 'fonts.conf'));
          if (fontsConfFile.existsSync()) {
            await fontsConfFile.delete();
          }
        } catch (_) {}
      }

      // Clean up temporary converted PNG files on mobile
      for (final path in temporaryConvertedFiles) {
        try {
          final f = File(path);
          if (f.existsSync()) await f.delete();
        } catch (_) {}
      }
    }

    if (success) {
      yield const ExportProgress(progress: 1.0, status: 'completed');
    } else {
      yield const ExportProgress(
        progress: 0.0,
        status: 'failed',
        error: 'FFmpeg mobile export failed. Check logs.',
      );
    }
  }

  Stream<ExportProgress> _executeMobileFFmpeg(List<String> args, double duration) async* {
    final progressCtrl = StreamController<ExportProgress>();
    progressCtrl.add(const ExportProgress(progress: 0.2, status: 'rendering'));

    try {
      final session = await FFmpegKit.executeWithArgumentsAsync(
        args,
        (session) async {
          try {
            final rc = await session.getReturnCode();
            final success = ReturnCode.isSuccess(rc);

            // Print all FFmpeg logs for diagnostics
            final logs = await session.getLogs();
             for (final log in logs) {
               final msg = log.getMessage();
                // Skip harmless/spammy warnings that pollute logs and diagnostics
                if (msg.contains('Changing video frame properties') ||
                    msg.contains('all_channel_counts') ||
                    msg.contains('filter context - w:') ||
                    msg.contains('Guessed Channel Layout')) {
                  continue;
                }
               final level = log.getLevel();
               final isError = level == Level.avLogError || level == Level.avLogFatal || level == Level.avLogPanic;
               final isWarning = level == Level.avLogWarning;
               LoggerService.instance.log(
                 isError
                     ? LogLevel.error
                     : isWarning
                         ? LogLevel.warning
                         : LogLevel.info,
                 'FFmpegSessionLog',
                 msg,
               );
             }
            final failStackTrace = await session.getFailStackTrace();
            if (failStackTrace != null && failStackTrace.isNotEmpty) {
              LoggerService.instance.log(
                LogLevel.error,
                'FFmpegSessionFailStackTrace',
                failStackTrace,
              );
            }

            if (!progressCtrl.isClosed) {
              progressCtrl.add(ExportProgress(
                progress: success ? 1.0 : 0.0,
                status: success ? 'completed' : 'failed',
                error: success ? null : 'FFmpeg mobile export failed with return code $rc',
              ));
            }
          } catch (e) {
            if (!progressCtrl.isClosed) {
              progressCtrl.addError(e);
            }
          } finally {
            if (session == _activeSession) {
              _activeSession = null;
            }
            if (!progressCtrl.isClosed) {
              await progressCtrl.close();
            }
          }
        },
        null,
        (Statistics stats) {
          final timeMs = stats.getTime();
          if (timeMs > 0 && duration > 0) {
            final p = (0.2 + (timeMs / 1000.0 / duration) * 0.78).clamp(0.2, 0.99);
            if (!progressCtrl.isClosed) {
              progressCtrl.add(ExportProgress(progress: p, status: 'rendering'));
            }
          }
        },
      );
      _activeSession = session;
    } catch (e) {
      if (!progressCtrl.isClosed) {
        progressCtrl.add(ExportProgress(progress: 0.0, status: 'failed', error: e.toString()));
        await progressCtrl.close();
      }
      rethrow;
    }

    yield* progressCtrl.stream;
  }

  Stream<ExportProgress> _exportVideoDesktop({
    required Project project,
    required List<Chunk> chunks,
    required String outputFilePath,
    required String tempDir,
    String? tempFontsDir,
  }) async* {
    LoggerService.instance.log(LogLevel.action, 'FfmpegExporter', 'Starting video export to: $outputFilePath');
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

    final assContent = generateAssScript(project, trimmedChunks);
    final assPath = p.join(tempDir, '${project.projectId}_export.ass');
    final assFile = File(assPath);
    await assFile.writeAsString(assContent);
    LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Generated ASS subtitle timing script. Path: $assPath');

    final outputFile = File(outputFilePath);
    if (outputFile.existsSync()) {
      try {
        await outputFile.delete();
      } catch (_) {}
    }    final List<(WordSchema, String)> validEmojiWords = [];
    final List<SfxExportItem> sfxItems = [];
    bool success = false;
    String? lastError;
    try {
      await collectEmojiAndSfx(trimmedChunks, project.config.emojiPack, validEmojiWords, sfxItems, tempDir);
      LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Found ${validEmojiWords.length} emojis and ${sfxItems.length} sound effects to mix.');

      final List<String> baseArgs = ['-y', '-i', project.videoPath];
      for (final item in validEmojiWords) {
        final path = item.$2.toLowerCase();
        final isAnimated = await isAnimatedFile(item.$2);
        if (path.endsWith('.gif') || (path.endsWith('.png') && isAnimated)) {
          baseArgs.addAll(['-ignore_loop', '0', '-i', item.$2]);
        } else if (path.endsWith('.webp')) {
          baseArgs.addAll(['-loop', '0', '-i', item.$2]);
        } else {
          baseArgs.addAll(['-i', item.$2]);
        }
      }
      for (final item in sfxItems) {
        baseArgs.addAll(['-i', item.resolvedPath]);
      }

      final filterComplex = buildFilterComplex(
        project: project,
        segmentsToUse: segmentsToUse,
        trimmedChunks: trimmedChunks,
        validEmojiWords: validEmojiWords,
        sfxItems: sfxItems,
        assPath: assPath,
        tempFontsDir: tempFontsDir,
      );

      baseArgs.addAll(['-filter_complex', filterComplex]);
      baseArgs.addAll(['-map', '[v_final]']);
      baseArgs.addAll(['-map', '[a_final]']);

      final settings = SettingsService.instance;
      final List<String> activeCodecArgs = [];
      bool isHardwareEncoder = false;

      if (settings.useGpu) {
        final encoder = settings.gpuEncoder;
        if (encoder == 'h264_nvenc') {
          LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Configuring NVENC hardware acceleration.');
          activeCodecArgs.addAll([
            '-c:v', 'h264_nvenc',
            '-preset', 'p4',
          ]);
          isHardwareEncoder = true;
        } else if (encoder == 'h264_videotoolbox') {
          LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Configuring VideoToolbox Apple Silicon acceleration.');
          activeCodecArgs.addAll([
            '-c:v', 'h264_videotoolbox',
          ]);
          isHardwareEncoder = true;
        } else if (encoder == 'h264_qsv') {
          LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Configuring QSV Intel QuickSync acceleration.');
          activeCodecArgs.addAll([
            '-c:v', 'h264_qsv',
          ]);
          isHardwareEncoder = true;
        } else { // auto detection
          final available = await probeAvailableEncoders(ffmpegCliPath);
          if (available.contains('h264_videotoolbox')) {
            LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Auto-detected VideoToolbox Apple Silicon acceleration.');
            activeCodecArgs.addAll([
              '-c:v', 'h264_videotoolbox',
            ]);
            isHardwareEncoder = true;
          } else if (available.contains('h264_nvenc')) {
            LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Auto-detected NVENC hardware acceleration.');
            activeCodecArgs.addAll([
              '-c:v', 'h264_nvenc',
              '-preset', 'p4',
            ]);
            isHardwareEncoder = true;
          } else if (available.contains('h264_qsv')) {
            LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Auto-detected QSV Intel QuickSync acceleration.');
            activeCodecArgs.addAll([
              '-c:v', 'h264_qsv',
            ]);
            isHardwareEncoder = true;
          } else {
            LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'No compatible hardware acceleration detected — falling back to standard CPU rendering.');
            activeCodecArgs.addAll([
              '-c:v', 'libx264',
              '-preset', 'fast',
              '-crf', '22',
              '-pix_fmt', 'yuv420p',
            ]);
          }
        }
      } else {
        activeCodecArgs.addAll([
          '-c:v', 'libx264',
          '-preset', 'fast',
          '-crf', '22',
          '-pix_fmt', 'yuv420p',
        ]);
      }

      final List<String> primaryArgs = [...baseArgs, ...activeCodecArgs, '-c:a', 'aac', '-b:a', '192k', '-t', totalDuration.toStringAsFixed(3), outputFilePath];

      success = false;
      lastError = null;
      try {
        await for (final prog in _executeDesktopFFmpegProcess(primaryArgs, totalDuration)) {
          yield prog;
        }
        success = true;
      } catch (e) {
        lastError = e.toString();

        // Fallback if desktop hardware encoder fails
        if (isHardwareEncoder) {
          LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter', 'Desktop hardware export failed. Falling back to software libx264.');
          yield const ExportProgress(progress: 0.1, status: 'rendering', error: 'Hardware export failed. Retrying with software encoder...');

          if (outputFile.existsSync()) {
            try {
              await outputFile.delete();
            } catch (_) {}
          }

          final List<String> fallbackCodecArgs = [
            '-c:v', 'libx264',
            '-preset', 'fast',
            '-crf', '22',
            '-pix_fmt', 'yuv420p',
          ];
          final List<String> fallbackArgs = [...baseArgs, ...fallbackCodecArgs, '-c:a', 'aac', '-b:a', '192k', '-t', totalDuration.toStringAsFixed(3), outputFilePath];
          LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Desktop FFmpeg fallback args: ${fallbackArgs.join(" ")}');

          try {
            await for (final prog in _executeDesktopFFmpegProcess(fallbackArgs, totalDuration)) {
              yield prog;
            }
            success = true;
          } catch (fallbackError) {
            lastError = fallbackError.toString();
            success = false;
          }
        } else {
          success = false;
        }
      }
    } finally {
      try {
        await assFile.delete();
      } catch (_) {}
      for (final item in validEmojiWords) {
        if (item.$2.contains('rendered_emoji_')) {
          try {
            final f = File(item.$2);
            if (f.existsSync()) await f.delete();
          } catch (_) {}
        }
      }
    }

    if (success) {
      yield const ExportProgress(progress: 1.0, status: 'completed');
    } else {
      yield ExportProgress(
        progress: 0.0,
        status: 'failed',
        error: lastError ?? 'FFmpeg desktop export failed. Check logs.',
      );
    }
  }

  Stream<ExportProgress> _executeDesktopFFmpegProcess(List<String> args, double duration) async* {
    Process? process;
    bool processExited = false;
    try {
      LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Spawning FFmpeg. Command: $ffmpegCliPath ${args.join(" ")}');
      process = processStarter != null
          ? await processStarter!(ffmpegCliPath, args)
          : await Process.start(ffmpegCliPath, args);

      _activeProcess = process;

      process.stdout.listen((_) {});

      final lineStream = process.stderr.transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter());

      await for (final line in lineStream) {
        // Skip harmless/spammy warnings that pollute logs and diagnostics
        if (line.contains('Changing video frame properties') ||
            line.contains('all_channel_counts') ||
            line.contains('filter context - w:') ||
            line.contains('Guessed Channel Layout')) {
          continue;
        }
        if (line.contains('Error') || line.contains('failed') || line.contains('invalid') || line.contains('Invalid')) {
          LoggerService.instance.log(LogLevel.error, 'FfmpegExporter', '[FFmpeg Stream Error] $line');
        } else if (line.contains('warning') || line.contains('Warning')) {
          LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter', '[FFmpeg Stream Warning] $line');
        } else if (line.contains('Duration:') || line.contains('Stream #') || line.contains('Output #') || line.contains('Successfully')) {
          LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', '[FFmpeg Stream Metadata] $line');
        } else {
          LoggerService.instance.log(LogLevel.debug, 'FfmpegExporter', '[FFmpeg Stream] $line');
        }

        if (line.contains('time=')) {
          final timeMatch = RegExp(r'time=(\d+):(\d+):(\d+)\.(\d+)').firstMatch(line);
          if (timeMatch != null) {
            final h = int.parse(timeMatch.group(1)!);
            final m = int.parse(timeMatch.group(2)!);
            final s = int.parse(timeMatch.group(3)!);
            final subseconds = double.parse('0.${timeMatch.group(4)!}');

            final currentProgressTime = h * 3600 + m * 60 + s + subseconds;
            final progressPercent = (currentProgressTime / duration).clamp(0.0, 0.99);

            yield ExportProgress(progress: progressPercent, status: 'rendering');
          }
        }
      }

      final exitCode = await process.exitCode;
      processExited = true;

      if (exitCode != 0) {
        throw ProcessException(ffmpegCliPath, args, 'FFmpeg processing failed with exit code $exitCode', exitCode);
      }
    } finally {
      if (!processExited && process != null && _activeProcess == process) {
        // Only kill if this process is still the active one and hasn't exited cleanly.
        // If it exited normally (exit code checked above), the OS already cleaned up the process.
        // Calling kill on an exited process is a no-op on most OSes but avoids PID reuse races.
        try {
          process.kill();
        } catch (_) {}
      }
      _activeProcess = null;
    }
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
    } catch (_) {
      return 2;
    }
  }
}
