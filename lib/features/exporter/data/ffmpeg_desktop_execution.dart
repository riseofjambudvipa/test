part of 'ffmpeg_execution.dart';

extension _FfmpegDesktopExecution on FfmpegExecutor {
  Stream<ExportProgress> _exportVideoDesktop({
    required Project project,
    required List<Chunk> chunks,
    required String outputFilePath,
    required String tempDir,
    String? tempFontsDir,
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
    LoggerService.instance.log(LogLevel.action, 'FfmpegExporter',
        'Starting video export to: $outputFilePath');
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

    final isProjectVertical = project.height > project.width;
    final Project projectForExport =
        (conversionMode != null && !isProjectVertical)
            ? (SchemaClones.cloneProjectDeep(project)
              ..width = 1080
              ..height = 1920)
            : project;

    final assContent = generateAssScript(projectForExport, trimmedChunks);
    final assPath = p.join(tempDir, '${project.projectId}_export.ass');
    final assFile = File(assPath);
    await assFile.writeAsString(assContent);
    LoggerService.instance.log(LogLevel.info, 'FfmpegExporter',
        'Generated ASS subtitle timing script. Path: $assPath');

    // FIX: render to a staging path with the correct container extension so FFmpeg
    // can determine the output muxer, and only move it over the final file on success.
    final outputFile = File(outputFilePath);
    final ext = p.extension(outputFilePath);
    final safeExt = ext.isNotEmpty ? ext : '.mp4';
    final stagingPath = '${p.withoutExtension(outputFilePath)}_partial$safeExt';
    final stagingFile = File(stagingPath);
    if (stagingFile.existsSync()) {
      try {
        await stagingFile.delete();
      } catch (e) {
        LoggerService.instance.debug('Failed to delete existing desktop stagingFile: $e');
      }
    }
    final List<(WordSchema, String)> validEmojiWords = [];
    final List<SfxExportItem> sfxItems = [];
    bool success = false;
    String? lastError;
    try {
      await collectEmojiAndSfx(trimmedChunks, project.config.emojiPack,
          validEmojiWords, sfxItems, tempDir);
      LoggerService.instance.log(LogLevel.info, 'FfmpegExporter',
          'Found ${validEmojiWords.length} emojis and ${sfxItems.length} sound effects to mix.');

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
      bool hasAudio = true;
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
          hasAudio = metadata.hasAudio;
        }
      } catch (e) {
        LoggerService.instance.debug('probeVideoMetadata failed on desktop export: $e');
      }

      final filterComplex = buildVideoFilterComplex(
        project: projectForExport,
        segmentsToUse: segmentsToUse,
        trimmedChunks: trimmedChunks,
        validEmojiWords: validEmojiWords,
        sfxItems: sfxItems,
        assPath: assPath,
        tempFontsDir: tempFontsDir,
        conversionMode: conversionMode,
        sourceWidth: sourceWidth,
        sourceHeight: sourceHeight,
        enableAudioCrossfade: enableAudioCrossfade,
        audioCrossfadeDuration: audioCrossfadeDuration,
        hasAudio: hasAudio,
        enableStudioSound: enableStudioSound,
        audioMastering: audioMastering,
        progressBarConfig: progressBarConfig,
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

      if (settings.useGpu) {
        final encoder = settings.gpuEncoder;
        if (encoder == 'h264_nvenc') {
          LoggerService.instance.log(LogLevel.info, 'FfmpegExporter',
              'Configuring NVENC hardware acceleration.');
          activeCodecArgs.addAll([
            '-c:v', 'h264_nvenc',
            '-preset', 'p4',
          ]);
          isHardwareEncoder = true;
        } else if (encoder == 'h264_videotoolbox') {
          LoggerService.instance.log(LogLevel.info, 'FfmpegExporter',
              'Configuring VideoToolbox Apple Silicon acceleration.');
          activeCodecArgs.addAll([
            '-c:v', 'h264_videotoolbox',
          ]);
          isHardwareEncoder = true;
        } else if (encoder == 'h264_qsv') {
          LoggerService.instance.log(LogLevel.info, 'FfmpegExporter',
              'Configuring QSV Intel QuickSync acceleration.');
          activeCodecArgs.addAll([
            '-c:v', 'h264_qsv',
          ]);
          isHardwareEncoder = true;
        } else {
          final available = await probeAvailableEncoders(ffmpegCliPath);
          if (available.contains('h264_videotoolbox')) {
            LoggerService.instance.log(LogLevel.info, 'FfmpegExporter',
                'Auto-detected VideoToolbox Apple Silicon acceleration.');
            activeCodecArgs.addAll([
              '-c:v', 'h264_videotoolbox',
            ]);
            isHardwareEncoder = true;
          } else if (available.contains('h264_nvenc')) {
            LoggerService.instance.log(LogLevel.info, 'FfmpegExporter',
                'Auto-detected NVENC hardware acceleration.');
            activeCodecArgs.addAll([
              '-c:v', 'h264_nvenc',
              '-preset', 'p4',
            ]);
            isHardwareEncoder = true;
          } else if (available.contains('h264_qsv')) {
            LoggerService.instance.log(LogLevel.info, 'FfmpegExporter',
                'Auto-detected QSV Intel QuickSync acceleration.');
            activeCodecArgs.addAll([
              '-c:v', 'h264_qsv',
            ]);
            isHardwareEncoder = true;
          } else {
            LoggerService.instance.log(LogLevel.info, 'FfmpegExporter',
                'No compatible hardware acceleration detected — falling back to standard CPU rendering.');
            activeCodecArgs.addAll([
              '-c:v', 'libx264',
              '-preset', 'fast',
              '-crf', '22',
              '-pix_fmt', 'yuv420p',
              '-threads', '${_getOptimalExportThreads()}',
            ]);
          }
        }
      } else {
        activeCodecArgs.addAll([
          '-c:v', 'libx264',
          '-preset', 'fast',
          '-crf', '22',
          '-pix_fmt', 'yuv420p',
          '-threads', '${_getOptimalExportThreads()}',
        ]);
      }

      final String containerFormat = safeExt.replaceFirst('.', '').toLowerCase();
      final List<String> primaryArgs = [
        ...baseArgs,
        ...activeCodecArgs,
        '-c:a',
        'aac',
        '-b:a',
        '192k',
        '-t',
        totalDuration.toStringAsFixed(3),
        '-f',
        containerFormat,
        stagingPath
      ];
      LoggerService.instance.log(LogLevel.info, 'FfmpegExporter',
          'Desktop FFmpeg primary args: ${primaryArgs.join(" ")}');

      try {
        await for (final prog
            in _executeDesktopFFmpegProcess(primaryArgs, totalDuration)) {
          yield prog;
        }
        success = true;
      } catch (e) {
        lastError = e.toString();
        if (isHardwareEncoder) {
          LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter',
              'Desktop hardware export failed. Falling back to software libx264.');
          yield const ExportProgress(
              progress: 0.1,
              status: 'rendering',
              error:
                  'Hardware export failed. Retrying with software encoder...');

          if (stagingFile.existsSync()) {
            try {
              await stagingFile.delete();
            } catch (e) {
              LoggerService.instance.debug('Failed to delete stagingFile before desktop fallback: $e');
            }
          }

          final List<String> fallbackCodecArgs = [
            '-c:v',
            'libx264',
            '-preset',
            'fast',
            '-crf',
            '22',
            '-pix_fmt',
            'yuv420p',
            '-threads',
            '${_getOptimalExportThreads()}',
          ];
          final List<String> fallbackArgs = [
            ...baseArgs,
            ...fallbackCodecArgs,
            '-c:a',
            'aac',
            '-b:a',
            '192k',
            '-t',
            totalDuration.toStringAsFixed(3),
            '-f',
            containerFormat,
            stagingPath
          ];
          LoggerService.instance.log(LogLevel.info, 'FfmpegExporter',
              'Desktop FFmpeg fallback args: ${fallbackArgs.join(" ")}');

          try {
            await for (final prog
                in _executeDesktopFFmpegProcess(fallbackArgs, totalDuration)) {
              yield prog;
            }
            success = true;
          } catch (fallbackError) {
            LoggerService.instance.log(LogLevel.error, 'FfmpegExporter', 'Desktop fallback export failed: $fallbackError');
            lastError = fallbackError.toString();
            success = false;
          }
        } else {
          success = false;
        }
      }

      // Promote the staged render to the final path before entering finally
      if (success) {
        if (stagingFile.existsSync()) {
          try {
            if (outputFile.existsSync()) {
              await outputFile.delete();
            }
            try {
              await stagingFile.rename(outputFilePath);
            } catch (_) {
              await stagingFile.copy(outputFilePath);
              if (stagingFile.existsSync()) await stagingFile.delete();
            }
            LoggerService.instance.log(LogLevel.info, 'FfmpegExporter',
                'Desktop export promoted staging file to $outputFilePath');
          } catch (e) {
            success = false;
            lastError = 'Failed to finalize staged export: $e';
            LoggerService.instance.log(LogLevel.error, 'FfmpegExporter',
                'Failed to finalize staged export: $e');
          }
        } else {
          LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter',
              'Export reported success but no staging file was produced at $stagingPath');
        }
      }
    } finally {
      try {
        await assFile.delete();
      } catch (e) {
        LoggerService.instance.debug('Failed to delete temp assFile on desktop: $e');
      }
      // Only delete staging output if export failed or threw an error
      if (!success) {
        try {
          if (stagingFile.existsSync()) await stagingFile.delete();
        } catch (e) {
          LoggerService.instance.debug('Failed to delete residual stagingFile on desktop: $e');
        }
      }
      for (final item in validEmojiWords) {
        if (item.$2.contains('rendered_emoji_')) {
          try {
            final f = File(item.$2);
            if (f.existsSync()) await f.delete();
          } catch (e) {
            LoggerService.instance.debug('Failed to delete temporary rendered emoji: $e');
          }
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

  Stream<ExportProgress> _executeDesktopFFmpegProcess(
      List<String> args, double duration) async* {
    Process? process;
    bool processExited = false;
    try {
      LoggerService.instance.log(LogLevel.info, 'FfmpegExporter',
          'Spawning FFmpeg. Command: $ffmpegCliPath ${args.join(" ")}');
      process = processStarter != null
          ? await processStarter!(ffmpegCliPath, args)
          : await Process.start(ffmpegCliPath, args);

      _activeProcess = process;

      process.stdout.listen((_) {});

      final lineStream = process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter());

      final recentStderr = <String>[];
      const maxRecentStderr = 25;

      await for (final line in lineStream) {
        if (recentStderr.length >= maxRecentStderr) {
          recentStderr.removeAt(0);
        }
        recentStderr.add(line);

        // Skip harmless/spammy warnings that pollute logs and diagnostics
        if (line.contains('Changing video frame properties') ||
            line.contains('all_channel_counts') ||
            line.contains('filter context - w:') ||
            line.contains('Guessed Channel Layout')) {
          continue;
        }
        if (line.contains('Error') ||
            line.contains('failed') ||
            line.contains('invalid') ||
            line.contains('Invalid')) {
          LoggerService.instance.log(
              LogLevel.error, 'FfmpegExporter', '[FFmpeg Stream Error] $line');
        } else if (line.contains('warning') || line.contains('Warning')) {
          LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter',
              '[FFmpeg Stream Warning] $line');
        } else if (line.contains('Duration:') ||
            line.contains('Stream #') ||
            line.contains('Output #') ||
            line.contains('Successfully')) {
          LoggerService.instance.log(LogLevel.info, 'FfmpegExporter',
              '[FFmpeg Stream Metadata] $line');
        } else {
          LoggerService.instance
              .log(LogLevel.debug, 'FfmpegExporter', '[FFmpeg Stream] $line');
        }

        if (line.contains('time=')) {
          final timeMatch =
              RegExp(r'time=(\d+):(\d+):(\d+)\.(\d+)').firstMatch(line);
          if (timeMatch != null) {
            final h = int.parse(timeMatch.group(1)!);
            final m = int.parse(timeMatch.group(2)!);
            final s = int.parse(timeMatch.group(3)!);
            final subseconds = double.parse('0.${timeMatch.group(4)!}');

            final currentProgressTime = h * 3600 + m * 60 + s + subseconds;
            final progressPercent =
                (currentProgressTime / duration).clamp(0.0, 0.99);

            yield ExportProgress(
                progress: progressPercent, status: 'rendering');
          }
        }
      }

      final exitCode = await process.exitCode;
      processExited = true;

      if (exitCode != 0) {
        final errorDetails = recentStderr
            .where((l) => l.trim().isNotEmpty)
            .toList();
        final summary = errorDetails.isNotEmpty
            ? errorDetails.sublist(
                errorDetails.length > 8 ? errorDetails.length - 8 : 0)
                .join('\n')
            : 'No diagnostic output captured from stderr.';
        throw ProcessException(
          ffmpegCliPath,
          args,
          'FFmpeg export failed with exit code $exitCode:\n$summary',
          exitCode,
        );
      }
    } finally {
      if (!processExited && process != null && _activeProcess == process) {
        // Only kill if this process is still the active one and hasn't exited cleanly.
        // If it exited normally (exit code checked above), the OS already cleaned up the process.
        // Calling kill on an exited process is a no-op on most OSes but avoids PID reuse races.
        try {
          process.kill();
        } catch (e) {
          LoggerService.instance.debug('Process kill exception in finally: $e');
        }
      }
      _activeProcess = null;
    }
  }
}
