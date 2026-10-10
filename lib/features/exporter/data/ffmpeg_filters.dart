import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;
import '../../../core/database/schemas/project.dart';
import '../../../core/database/schemas/word.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/emoji/emoji_service.dart';
import '../../../core/logger/logger_service.dart';
import '../../editor/domain/caption_engine.dart';
import '../../../core/video/aspect_ratio_converter.dart';
import 'ass_script_builder.dart' show escapeAssPath, splitWordsIntoLines;
import 'ffmpeg_exporter.dart' show SfxExportItem;
import 'ffmpeg_font_preparer.dart' show FfmpegFontPreparation;
import '../../../core/video/retention_progress_bar_models.dart';
import '../../../core/video/background_music_models.dart';
import '../../../core/audio/audio_mastering_models.dart';
import '../../../core/audio/speaker_diarization_service.dart';
import '../../../core/video/b_roll_models.dart';

export '../../../core/video/viral_clip_models.dart' show AspectConversionMode;
export '../../../core/video/background_music_models.dart' show BackgroundMusicConfig;
export '../../../core/video/b_roll_models.dart' show BRollClip;
export '../../../core/audio/audio_mastering_models.dart'
    show AudioMasteringConfig, AudioMasteringPlatform;
export '../../../core/audio/speaker_diarization_service.dart' show SpeakerInterval;

/// Builds FFmpeg `-filter_complex` graphs and resolves emoji/SFX assets for
/// the video export. Mixed into [FfmpegExporter] alongside [FfmpegExecutor]
/// and the font preparation mixin.
mixin FfmpegFilterBuilder on FfmpegFontPreparation {
  /// Generates the broadcast-quality audio DSP filter chain for studio voice enhancement:
  /// - High-pass 80Hz filter: eliminates HVAC rumble, desk bumps, mic handling noise
  /// - Low-pass 12kHz filter: removes high-frequency hiss, coil whine, harsh sibilance
  /// - afftdn (Adaptive FFT De-noise): cleans background ambient/fan noise (-25dB floor)
  /// - deesser: intelligent sibilance reduction taming piercing "s" sounds
  /// - compand: multi-stage vocal dynamics compression/expansion with +3dB makeup gain
  /// - loudnorm: Platform loudness mastering (-14 LUFS for Social Shorts/Reels/TikTok, -16 LUFS for Podcast/Broadcast, -23 LUFS for Cinema)
  static String buildStudioSoundFilter({
    AudioMasteringPlatform platform = AudioMasteringPlatform.broadcastPodcast,
    bool enableDeEsser = false,
    double deEsserIntensity = 0.40,
  }) {
    final filters = <String>[
      'highpass=f=80',
      'lowpass=f=12000',
      'afftdn=nf=-25',
    ];

    if (enableDeEsser) {
      final intensity = deEsserIntensity.clamp(0.1, 1.0).toStringAsFixed(2);
      filters.add('deesser=i=$intensity:m=0.5:f=0.5:s=o');
    }

    filters.add('compand=attacks=0.02:decays=0.2:points=-60/-60|-24/-12|0/-3:gain=3');
    filters.add(platform.loudnormFilter);

    return filters.join(',');
  }

  /// Builds FFmpeg `drawbox` video filters to burn the dynamic retention progress bar (Submagic & OpusClip parity).
  static String buildRetentionProgressBarFilter({
    required RetentionProgressBarConfig config,
    required double duration,
    required double exportScale,
  }) {
    if (!config.enabled || duration <= 0.0) return '';

    final safeDuration = math.max(0.1, duration);
    final int barH = (config.height * exportScale).round().clamp(2, 60);
    final int pad = (config.padding * exportScale).round().clamp(0, 150);
    final fgColor = config.toFfmpegColor(config.color);

    final yExpr = config.position == 'top' ? '$pad' : 'ih-$barH-$pad';

    final filters = <String>[];

    // Optional background track
    if (config.backgroundColor != null && config.backgroundColor!.isNotEmpty) {
      final bgColor = config.toFfmpegColor(config.backgroundColor!);
      filters.add('drawbox=x=0:y=$yExpr:w=iw:h=$barH:color=$bgColor:t=fill');
    }

    // Animated progress stripe
    final dStr = safeDuration.toStringAsFixed(3);
    filters.add('drawbox=x=0:y=$yExpr:w=\'min(iw,iw*(t/$dStr))\':h=$barH:color=$fgColor:t=fill');

    return filters.join(',');
  }

  /// Generates the FFmpeg video filter snippet to overlay a B-roll clip.
  /// Fullscreen cutaways are scaled and cropped to fill target dimensions.
  /// Picture-in-picture (PiP) clips scale down and anchor to the designated corner.
  static String buildBRollOverlayFilter({
    required BRollClip clip,
    required int inputIndex,
    required int targetWidth,
    required int targetHeight,
    required double exportScale,
    required String inputStream,
    required String outputStream,
  }) {
    final startStr = clip.startTime.clamp(0.0, 86400.0).toStringAsFixed(3);
    final endStr = clip.endTime.clamp(0.0, 86400.0).toStringAsFixed(3);

    if (clip.isPictureInPicture) {
      final int pipW = (targetWidth * 0.36).round();
      final int pad = (20.0 * exportScale).round().clamp(10, 60);
      final String posExpr = switch (clip.pipPosition) {
        'top_left' => 'x=$pad:y=$pad',
        'bottom_right' => 'x=W-w-$pad:y=H-h-$pad',
        'bottom_left' => 'x=$pad:y=H-h-$pad',
        _ => 'x=W-w-$pad:y=$pad', // 'top_right'
      };

      return '[$inputIndex:v]scale=$pipW:-2,format=rgba,setpts=PTS-STARTPTS+$startStr/TB[broll_scaled_$inputIndex]; '
          '$inputStream[broll_scaled_$inputIndex]overlay=$posExpr:eof_action=repeat:enable=\'between(t,$startStr,$endStr)\'$outputStream';
    } else {
      return '[$inputIndex:v]scale=$targetWidth:$targetHeight:force_original_aspect_ratio=increase,crop=$targetWidth:$targetHeight,format=rgba,setpts=PTS-STARTPTS+$startStr/TB[broll_scaled_$inputIndex]; '
          '$inputStream[broll_scaled_$inputIndex]overlay=x=0:y=0:eof_action=repeat:enable=\'between(t,$startStr,$endStr)\'$outputStream';
    }
  }

  String buildFilterComplexSlow({
    required Project project,
    required List<VideoSegmentSchema> segmentsToUse,
    required List<SfxExportItem> sfxItems,
    AspectConversionMode? conversionMode,
    int? sourceWidth,
    int? sourceHeight,
    bool enableAudioCrossfade = false,
    double audioCrossfadeDuration = 0.05,
    bool hasAudio = true,
    bool enableStudioSound = false,
    AudioMasteringConfig? audioMastering,
    BackgroundMusicConfig? backgroundMusic,
    List<SpeakerInterval>? speakerIntervals,
    List<BRollClip>? bRollClips,
  }) {
    final filterComplex = StringBuffer();

    // 1. Trim the video input [0:v] -> [v_trimmed]
    final int numSegments = segmentsToUse.length;
    if (numSegments == 1) {
      final start = segmentsToUse[0].start ?? 0.0;
      final end = segmentsToUse[0].end ?? 0.0;
      final segDuration = (end - start).clamp(0.1, 86400.0);
      filterComplex.write('[0:v]trim=start=$start:end=$end,setpts=PTS-STARTPTS[v_trimmed]; ');
      if (hasAudio) {
        filterComplex.write('[0:a]atrim=start=$start:end=$end,asetpts=PTS-STARTPTS[a_trimmed]');
      } else {
        filterComplex.write('anullsrc=r=48000:cl=stereo:d=${segDuration.toStringAsFixed(3)}[a_trimmed]');
      }
    } else {
      filterComplex.write('[0:v]split=$numSegments');
      for (int i = 0; i < numSegments; i++) {
        filterComplex.write('[v_split_$i]');
      }
      if (hasAudio) {
        filterComplex.write('; [0:a]asplit=$numSegments');
        for (int i = 0; i < numSegments; i++) {
          filterComplex.write('[a_split_$i]');
        }
      }

      for (int i = 0; i < numSegments; i++) {
        final seg = segmentsToUse[i];
        final start = seg.start ?? 0.0;
        final end = seg.end ?? 0.0;
        final segDuration = (end - start).clamp(0.1, 86400.0);
        filterComplex.write('; [v_split_$i]trim=start=$start:end=$end,setpts=PTS-STARTPTS[v_seg_$i]');
        if (hasAudio) {
          filterComplex.write('; [a_split_$i]atrim=start=$start:end=$end,asetpts=PTS-STARTPTS[a_seg_$i]');
        } else {
          filterComplex.write('; anullsrc=r=48000:cl=stereo:d=${segDuration.toStringAsFixed(3)}[a_seg_$i]');
        }
      }

      if (enableAudioCrossfade && numSegments > 1) {
        final vConcatInputs = StringBuffer();
        for (int i = 0; i < numSegments; i++) {
          vConcatInputs.write('[v_seg_$i]');
        }
        filterComplex.write('; ${vConcatInputs.toString()}concat=n=$numSegments:v=1:a=0[v_trimmed]');

        final dStr = audioCrossfadeDuration.toStringAsFixed(3);
        String currentAudio = '[a_seg_0]';
        for (int i = 1; i < numSegments; i++) {
          final nextAudio = '[a_seg_$i]';
          final outAudio = i == numSegments - 1 ? '[a_trimmed]' : '[a_xfade_$i]';
          filterComplex.write('; $currentAudio$nextAudio acrossfade=d=$dStr:c1=tri:c2=tri$outAudio');
          currentAudio = outAudio;
        }
      } else {
        final concatInputs = StringBuffer();
        for (int i = 0; i < numSegments; i++) {
          concatInputs.write('[v_seg_$i][a_seg_$i]');
        }
        filterComplex.write('; ${concatInputs.toString()}concat=n=$numSegments:v=1:a=1[v_trimmed][a_trimmed]');
      }
    }

    String currentVideoStream = '[v_trimmed]';
    final isProjectVertical = project.height > project.width;

    AspectConversionMode? effectiveMode = conversionMode;
    if (effectiveMode == null && isProjectVertical) {
      if (sourceWidth != null && sourceHeight != null && sourceWidth > sourceHeight) {
        effectiveMode = AspectConversionMode.blurPillarbox;
      }
    }

    final targetWidth = (effectiveMode != null && !isProjectVertical) ? 1080 : project.width;
    final targetHeight = (effectiveMode != null && !isProjectVertical) ? 1920 : project.height;
    final isTargetVertical = targetHeight > targetWidth;

    if (effectiveMode != null) {
      final inW = sourceWidth ?? (isTargetVertical ? 1920 : targetWidth);
      final inH = sourceHeight ?? (isTargetVertical ? 1080 : targetHeight);

      final reframeFilter = AspectRatioConverter.buildFilterForMode(
        mode: effectiveMode,
        inputWidth: inW,
        inputHeight: inH,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        speakerIntervals: speakerIntervals,
        inputStream: currentVideoStream,
        outputStream: '[v_reframed]',
      );
      filterComplex.write('; $reframeFilter');
      currentVideoStream = '[v_reframed]';
    }

    // Overlay B-roll clips onto currentVideoStream
    final validBRoll = (bRollClips ?? [])
        .where((c) => c.mediaPath.isNotEmpty && File(c.mediaPath).existsSync())
        .toList();

    for (int i = 0; i < validBRoll.length; i++) {
      final bRollInputIndex = 2 + i;
      final outStream = '[v_broll_$i]';
      final bFilter = buildBRollOverlayFilter(
        clip: validBRoll[i],
        inputIndex: bRollInputIndex,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        exportScale: 1.0,
        inputStream: currentVideoStream,
        outputStream: outStream,
      );
      filterComplex.write('; $bFilter');
      currentVideoStream = outStream;
    }

    // 2. Overlay the raw PNG sequence [1:v] onto currentVideoStream -> [v_final]
    filterComplex.write('; $currentVideoStream[1:v]overlay=0:0[v_final]');

    // 3. Build audio mix filter (with optional AI Studio Sound voice polishing and background music ducking)
    final hasBgm = backgroundMusic != null && backgroundMusic.hasMusic;
    final bgmInputIndex = 2 + validBRoll.length;
    final sfxBaseIndex = hasBgm ? bgmInputIndex + 1 : bgmInputIndex;
    final hasAdditionalAudio = hasBgm || sfxItems.isNotEmpty;

    final isStudioSoundActive = enableStudioSound || (audioMastering != null && audioMastering.enableStudioSound);
    final studioSoundFilter = audioMastering != null && audioMastering.enableStudioSound
        ? buildStudioSoundFilter(
            platform: audioMastering.platform,
            enableDeEsser: audioMastering.enableDeEsser,
            deEsserIntensity: audioMastering.deEsserIntensity,
          )
        : buildStudioSoundFilter();

    if (isStudioSoundActive && hasAudio && !hasAdditionalAudio) {
      filterComplex.write('; [a_trimmed]$studioSoundFilter[a_final]');
      return filterComplex.toString();
    }

    String voiceStream = '[a_trimmed]';
    if (isStudioSoundActive && hasAudio) {
      filterComplex.write('; [a_trimmed]$studioSoundFilter[a_polished]');
      voiceStream = '[a_polished]';
    }

    final mixInputs = <String>[voiceStream];

    if (hasBgm) {
      double totalExportDuration = 0.0;
      for (final seg in segmentsToUse) {
        final start = seg.start ?? 0.0;
        final end = seg.end ?? 0.0;
        totalExportDuration += math.max(0.1, end - start);
      }
      if (totalExportDuration <= 0.0) {
        totalExportDuration = math.max(0.1, project.duration);
      }
      final bgmVol = backgroundMusic.volume.clamp(0.0, 1.0);
      final durationStr = totalExportDuration.toStringAsFixed(3);
      if (backgroundMusic.loop) {
        filterComplex.write('; [$bgmInputIndex:a]aloop=loop=-1:size=2e+09,atrim=0:$durationStr,asetpts=PTS-STARTPTS,volume=${bgmVol.toStringAsFixed(2)}[bgm_vol]');
      } else {
        filterComplex.write('; [$bgmInputIndex:a]atrim=0:$durationStr,asetpts=PTS-STARTPTS,volume=${bgmVol.toStringAsFixed(2)}[bgm_vol]');
      }

      if (backgroundMusic.enableDucking && hasAudio) {
        final duckRatio = backgroundMusic.duckingRatio.clamp(1.5, 20.0);
        filterComplex.write('; [bgm_vol]$voiceStream sidechaincompress=threshold=0.08:ratio=${duckRatio.toStringAsFixed(1)}:attack=50:release=300:makeup=1[bgm_ducked]');
        mixInputs.add('[bgm_ducked]');
      } else {
        mixInputs.add('[bgm_vol]');
      }
    }

    // Mix B-roll video audio if clip has volume > 0 and audio track
    for (int i = 0; i < validBRoll.length; i++) {
      final clip = validBRoll[i];
      if (clip.isVideo && clip.hasAudio && clip.volume > 0.0) {
        final bRollInputIndex = 2 + i;
        final clipDuration = math.max(0.05, clip.endTime - clip.startTime);
        final int delayMs = ((clip.startTime) * 1000).toInt();
        final vol = clip.volume.clamp(0.0, 2.0);
        final dStr = clipDuration.toStringAsFixed(3);
        filterComplex.write('; [$bRollInputIndex:a]atrim=0:$dStr,asetpts=PTS-STARTPTS,volume=${vol.toStringAsFixed(2)},adelay=$delayMs|$delayMs[broll_audio_$i]');
        mixInputs.add('[broll_audio_$i]');
      }
    }

    for (int i = 0; i < sfxItems.length; i++) {
      final item = sfxItems[i];
      final sfxInputIndex = sfxBaseIndex + i; // Index 0: video, Index 1: PNG seq, Index 2: BGM (if present), Index 2+/3+: SFX files
      final int delayMs = ((item.start) * 1000).toInt();
      final double vol = item.soundVolume / 100.0;

      final sfxDuration = item.end - item.start;
      final double fadeDuration = (sfxDuration * 0.25).clamp(0.01, 0.15);
      final double fadeOutStart = math.max(0.0, sfxDuration - fadeDuration);

      filterComplex.write('; [$sfxInputIndex:a]volume=volume=$vol,afade=t=in:ss=0:d=${fadeDuration.toStringAsFixed(3)},afade=t=out:ss=${fadeOutStart.toStringAsFixed(3)}:d=${fadeDuration.toStringAsFixed(3)},adelay=$delayMs|$delayMs[sfx_delayed_$i]');
      mixInputs.add('[sfx_delayed_$i]');
    }

    if (mixInputs.length > 1) {
      filterComplex.write('; ${mixInputs.join('')}amix=inputs=${mixInputs.length}:duration=first:normalize=0[a_final]');
    } else {
      filterComplex.write('; ${voiceStream}anull[a_final]');
    }

    return filterComplex.toString();
  }

  Future<void> collectEmojiAndSfx(
    List<Chunk> trimmedChunks,
    String? emojiPack,
    List<(WordSchema, String)> validEmojiWords,
    List<SfxExportItem> sfxItems,
    String tempDir,
  ) async {
    for (final chunk in trimmedChunks) {
      for (final word in chunk.words) {
        if (word.emoji != null && word.emoji!.isNotEmpty && word.emoji != 'none') {
          final parseResult = EmojiPackParser.parse(word.emoji!, emojiPack ?? 'notoColorEmoji');
          final activePack = parseResult.pack;
          final glyph = parseResult.glyph;

          final resolvedSticker = EmojiService.resolveStickerPath(glyph) ??
              EmojiService.resolveStickerPath(word.emoji);

          if (resolvedSticker != null) {
            validEmojiWords.add((word, resolvedSticker));
            continue;
          }

          if (activePack == 'custom' ||
              glyph.endsWith('.png') ||
              glyph.endsWith('.webp') ||
              glyph.endsWith('.jpg') ||
              glyph.endsWith('.jpeg') ||
              glyph.endsWith('.gif') ||
              glyph.contains('/') ||
              glyph.contains('\\')) {
            LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter', 'Custom sticker file not found on disk: $glyph');
            // Crucial: NEVER call renderEmojiToTempPng on file paths or filenames!
            continue;
          }

          bool handled = false;
          if (activePack != 'systemDefault' && activePack != 'notoColorEmoji') {
            // Also check if the pack is downloaded/installed on disk.
            if (EmojiService.instance.isPackInstalled(activePack)) {
              final emojiModel = EmojiService.instance.findByGlyph(glyph);
              if (emojiModel != null) {
                final emojiAsset = EmojiService.instance.getAssetPath(emojiModel, activePack);
                if (emojiAsset != null && await File(emojiAsset.absolutePath).exists()) {
                  validEmojiWords.add((word, emojiAsset.absolutePath));
                  handled = true;
                }
              }
            }
          }

          if (!handled) {
            try {
              final tempPngPath = await renderEmojiToTempPng(glyph, tempDir, activePack: activePack);
              validEmojiWords.add((word, tempPngPath));
            } catch (e) {
              LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter', 'Failed to render fallback emoji PNG: $e');
            }
          }
        }

        if (word.soundEffect != null && word.soundEffect!.isNotEmpty) {
          final sfxData = SfxData.parse(word.soundEffect!, fallbackVolume: word.soundVolume ?? 100);
          if (sfxData.chunk != null) {
            final sfxPath = AudioService.instance.getSfxPath(sfxData.chunk!.name);
            if (sfxPath != null && await File(sfxPath).exists()) {
              sfxItems.add(SfxExportItem(
                soundEffect: sfxData.chunk!.name,
                soundVolume: sfxData.chunk!.volume,
                start: word.start ?? 0.0,
                end: word.end ?? 0.0,
                resolvedPath: sfxPath,
              ));
            }
          }
          if (sfxData.word != null) {
            final sfxPath = AudioService.instance.getSfxPath(sfxData.word!.name);
            if (sfxPath != null && await File(sfxPath).exists()) {
              sfxItems.add(SfxExportItem(
                soundEffect: sfxData.word!.name,
                soundVolume: sfxData.word!.volume,
                start: word.start ?? 0.0,
                end: word.end ?? 0.0,
                resolvedPath: sfxPath,
              ));
            }
          }
        }
      }
    }
  }

  Future<String> renderEmojiToTempPng(String glyph, String tempDir, {String? activePack}) async {
    if (glyph.contains('/') || glyph.contains('\\') || glyph.endsWith('.png') || glyph.endsWith('.webp') || glyph.endsWith('.jpg') || glyph.endsWith('.jpeg')) {
      throw ArgumentError('renderEmojiToTempPng cannot render file paths as text glyph: $glyph');
    }
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const double size = 256.0;

    final textPainter = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          fontSize: 180.0,
          fontFamily: activePack == 'notoColorEmoji'
              ? 'Noto Color Emoji'
              : switch (defaultTargetPlatform) {
                  TargetPlatform.android => null, // Let mobile devices use their native default system emoji font
                  TargetPlatform.macOS   => 'Apple Color Emoji',
                  TargetPlatform.windows => 'Segoe UI Emoji',
                  TargetPlatform.linux   => null,
                  _                      => null,
                },
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    final x = (size - textPainter.width) / 2.0;
    final y = (size - textPainter.height) / 2.0;
    textPainter.paint(canvas, Offset(x, y));

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    img.dispose();
    picture.dispose();

    if (byteData == null) {
      throw Exception('Failed to encode emoji image to PNG');
    }

    final pngBytes = byteData.buffer.asUint8List();
    final hexName = glyph.runes.map((r) => r.toRadixString(16)).join('_');
    final outPath = p.join(tempDir, 'rendered_emoji_$hexName.png');
    await File(outPath).writeAsBytes(pngBytes);
    return outPath;
  }

  String buildVideoFilterComplex({
    required Project project,
    required List<VideoSegmentSchema> segmentsToUse,
    required List<Chunk> trimmedChunks,
    required List<(WordSchema, String)> validEmojiWords,
    required List<SfxExportItem> sfxItems,
    required String assPath,
    String? tempFontsDir,
    AspectConversionMode? conversionMode,
    int? sourceWidth,
    int? sourceHeight,
    bool enableAudioCrossfade = false,
    double audioCrossfadeDuration = 0.05,
    bool hasAudio = true,
    bool enableStudioSound = false,
    AudioMasteringConfig? audioMastering,
    RetentionProgressBarConfig? progressBarConfig,
    BackgroundMusicConfig? backgroundMusic,
    List<SpeakerInterval>? speakerIntervals,
    List<BRollClip>? bRollClips,
  }) {
    final filterComplex = StringBuffer();
    final double exportScale = project.height / 640.0;

    // Trim video and audio inputs first
    final int numSegments = segmentsToUse.length;
    if (numSegments == 1) {
      final start = segmentsToUse[0].start ?? 0.0;
      final end = segmentsToUse[0].end ?? 0.0;
      final segDuration = (end - start).clamp(0.1, 86400.0);
      filterComplex.write('[0:v]trim=start=$start:end=$end,setpts=PTS-STARTPTS[v_trimmed]; ');
      if (hasAudio) {
        filterComplex.write('[0:a]atrim=start=$start:end=$end,asetpts=PTS-STARTPTS[a_trimmed]');
      } else {
        filterComplex.write('anullsrc=r=48000:cl=stereo:d=${segDuration.toStringAsFixed(3)}[a_trimmed]');
      }
    } else {
      filterComplex.write('[0:v]split=$numSegments');
      for (int i = 0; i < numSegments; i++) {
        filterComplex.write('[v_split_$i]');
      }
      if (hasAudio) {
        filterComplex.write('; [0:a]asplit=$numSegments');
        for (int i = 0; i < numSegments; i++) {
          filterComplex.write('[a_split_$i]');
        }
      }

      for (int i = 0; i < numSegments; i++) {
        final seg = segmentsToUse[i];
        final start = seg.start ?? 0.0;
        final end = seg.end ?? 0.0;
        final segDuration = (end - start).clamp(0.1, 86400.0);
        filterComplex.write('; [v_split_$i]trim=start=$start:end=$end,setpts=PTS-STARTPTS[v_seg_$i]');
        if (hasAudio) {
          filterComplex.write('; [a_split_$i]atrim=start=$start:end=$end,asetpts=PTS-STARTPTS[a_seg_$i]');
        } else {
          filterComplex.write('; anullsrc=r=48000:cl=stereo:d=${segDuration.toStringAsFixed(3)}[a_seg_$i]');
        }
      }

      if (enableAudioCrossfade && numSegments > 1) {
        final vConcatInputs = StringBuffer();
        for (int i = 0; i < numSegments; i++) {
          vConcatInputs.write('[v_seg_$i]');
        }
        filterComplex.write('; ${vConcatInputs.toString()}concat=n=$numSegments:v=1:a=0[v_trimmed]');

        final dStr = audioCrossfadeDuration.toStringAsFixed(3);
        String currentAudio = '[a_seg_0]';
        for (int i = 1; i < numSegments; i++) {
          final nextAudio = '[a_seg_$i]';
          final outAudio = i == numSegments - 1 ? '[a_trimmed]' : '[a_xfade_$i]';
          filterComplex.write('; $currentAudio$nextAudio acrossfade=d=$dStr:c1=tri:c2=tri$outAudio');
          currentAudio = outAudio;
        }
      } else {
        final concatInputs = StringBuffer();
        for (int i = 0; i < numSegments; i++) {
          concatInputs.write('[v_seg_$i][a_seg_$i]');
        }
        filterComplex.write('; ${concatInputs.toString()}concat=n=$numSegments:v=1:a=1[v_trimmed][a_trimmed]');
      }
    }

    String currentVideoStream = '[v_trimmed]';
    final isProjectVertical = project.height > project.width;

    AspectConversionMode? effectiveMode = conversionMode;
    if (effectiveMode == null && isProjectVertical) {
      if (sourceWidth != null && sourceHeight != null && sourceWidth > sourceHeight) {
        effectiveMode = AspectConversionMode.blurPillarbox;
      }
    }

    final targetWidth = (effectiveMode != null && !isProjectVertical) ? 1080 : project.width;
    final targetHeight = (effectiveMode != null && !isProjectVertical) ? 1920 : project.height;
    final isTargetVertical = targetHeight > targetWidth;

    if (effectiveMode != null) {
      final inW = sourceWidth ?? (isTargetVertical ? 1920 : targetWidth);
      final inH = sourceHeight ?? (isTargetVertical ? 1080 : targetHeight);

      final effectiveSpeakerIntervals = speakerIntervals ??
          (project.words.isNotEmpty
              ? SpeakerDiarizationService.instance.getSpeakerIntervals(project.words)
              : null);

      final reframeFilter = AspectRatioConverter.buildFilterForMode(
        mode: effectiveMode,
        inputWidth: inW,
        inputHeight: inH,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        speakerIntervals: effectiveSpeakerIntervals,
        inputStream: currentVideoStream,
        outputStream: '[v_reframed]',
      );
      filterComplex.write('; $reframeFilter');
      currentVideoStream = '[v_reframed]';
    }

    // Overlay B-roll clips onto currentVideoStream
    final validBRoll = (bRollClips ?? [])
        .where((c) => c.mediaPath.isNotEmpty && File(c.mediaPath).existsSync())
        .toList();
    final bRollBaseIndex = 1 + validEmojiWords.length;

    for (int i = 0; i < validBRoll.length; i++) {
      final bRollInputIndex = bRollBaseIndex + i;
      final outStream = '[v_broll_$i]';
      final bFilter = buildBRollOverlayFilter(
        clip: validBRoll[i],
        inputIndex: bRollInputIndex,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
        exportScale: exportScale,
        inputStream: currentVideoStream,
        outputStream: outStream,
      );
      filterComplex.write('; $bFilter');
      currentVideoStream = outStream;
    }

    // Chain video overlays for emojis on currentVideoStream
    final style = project.config.style;
    final double captionMaxW = project.width * 0.80;

    for (int i = 0; i < validEmojiWords.length; i++) {
      final w = validEmojiWords[i];
      final wWord = w.$1;
      final emojiInputIndex = i + 1;

      final chunk = trimmedChunks.firstWhere(
        (c) => c.words.any((cw) =>
            identical(cw, wWord) ||
            (cw.wordId != null && cw.wordId!.isNotEmpty && cw.wordId == wWord.wordId)),
        orElse: () => Chunk(index: 0, startTime: wWord.start ?? 0.0, endTime: wWord.end ?? 0.0, words: [wWord]),
      );

      final double emojiScaleFactor = wWord.emojiConfig?.scale ?? 1.0;
      final int scaledW = (80.0 * exportScale * emojiScaleFactor).round();
      final int scaledH = (80.0 * exportScale * emojiScaleFactor).round();

      final double speed = wWord.emojiConfig?.speed ?? 1.0;
      final String speedFilter = speed != 1.0 ? '(1/$speed)*' : '';
      filterComplex.write('; [$emojiInputIndex:v]scale=$scaledW:$scaledH,format=rgba,setpts=$speedFilter(PTS-STARTPTS)+${chunk.startTime.toStringAsFixed(3)}/TB[emoji_scaled_$i]');

      final double xOffset = (wWord.emojiConfig?.x ?? 0.0) * exportScale;
      final double yOffset = (wWord.emojiConfig?.y ?? 0.0) * exportScale;

      // Calculate inline horizontal position when multiple emojis belong to the same chunk
      final chunkEmojis = validEmojiWords.where((item) {
        return chunk.words.any((cw) =>
            identical(cw, item.$1) ||
            (cw.wordId != null && cw.wordId!.isNotEmpty && cw.wordId == item.$1.wordId));
      }).toList();
      if (!chunkEmojis.contains(w)) {
        chunkEmojis.add(w);
      }
      final int emojiIndexInChunk = chunkEmojis.indexOf(w);

      double xCoord;
      if (chunkEmojis.length > 1) {
        double totalEmojisW = 0.0;
        final emojiWidths = <double>[];
        for (final item in chunkEmojis) {
          final scaleF = item.$1.emojiConfig?.scale ?? 1.0;
          final itemW = 80.0 * exportScale * scaleF;
          emojiWidths.add(itemW);
          totalEmojisW += itemW;
        }
        final double spacing = 12.0 * exportScale;
        totalEmojisW += (chunkEmojis.length - 1) * spacing;

        final double startX = (project.width - totalEmojisW) / 2.0;
        double currentX = startX;
        final safeIdx = emojiIndexInChunk >= 0 ? emojiIndexInChunk : 0;
        for (int k = 0; k < safeIdx; k++) {
          currentX += emojiWidths[k] + spacing;
        }
        xCoord = currentX + xOffset;
      } else {
        xCoord = (project.width / 2.0) - (scaledW / 2.0) + xOffset;
      }

      final lines = splitWordsIntoLines(
        words: chunk.words,
        fontFamily: style.fontFamily,
        fontSize: style.fontSize * exportScale,
        fontWeight: style.fontWeight,
        letterSpacing: (style.letterSpacing ?? 0.0) * exportScale,
        maxPixelWidth: captionMaxW,
      );
      final double assFontSize = style.fontSize * exportScale;
      final double T = lines.length * (assFontSize + 4.0 * exportScale);

      final double E = 80.0 * exportScale;
      final double G = 12.0 * exportScale;
      final double H = E + G + T;

      final double topFraction = (style.top / 100.0).clamp(0.05, 0.95);
      final double yTop = (project.height - H) * topFraction;
      final double yCoord = yTop + E / 2.0 - scaledH / 2.0 + yOffset;

      final outStreamName = '[v_temp_$i]';
      filterComplex.write('; $currentVideoStream[emoji_scaled_$i]overlay=x=${xCoord.round()}:y=${yCoord.round()}:enable=\'between(t,${chunk.startTime},${chunk.endTime})\'$outStreamName');
      currentVideoStream = outStreamName;
    }

    // Burn subtitles on top of the final video overlay stream
    final escapedAssPath = escapeAssPath(assPath);
    final fontsDir = tempFontsDir ?? getSafeFontsDir();
    final hasRetentionBar = progressBarConfig != null && progressBarConfig.enabled;
    final subTargetStream = hasRetentionBar ? '[v_sub]' : '[v_final]';

    if (fontsDir != null) {
      final escapedFontsDir = escapeAssPath(fontsDir);
      filterComplex.write('; ${currentVideoStream}subtitles=\'$escapedAssPath\':fontsdir=\'$escapedFontsDir\'$subTargetStream');
    } else {
      filterComplex.write('; ${currentVideoStream}subtitles=\'$escapedAssPath\'$subTargetStream');
    }

    if (hasRetentionBar) {
      double totalExportDuration = 0.0;
      for (final seg in segmentsToUse) {
        final start = seg.start ?? 0.0;
        final end = seg.end ?? 0.0;
        totalExportDuration += math.max(0.1, end - start);
      }
      if (totalExportDuration <= 0.0) {
        totalExportDuration = math.max(0.1, project.duration);
      }

      final pBarFilter = buildRetentionProgressBarFilter(
        config: progressBarConfig,
        duration: totalExportDuration,
        exportScale: exportScale,
      );
      if (pBarFilter.isNotEmpty) {
        filterComplex.write('; [v_sub]$pBarFilter[v_final]');
      } else {
        filterComplex.write('; [v_sub]null[v_final]');
      }
    }

    // Build audio mix filter (with optional AI Studio Sound voice polishing and background music ducking)
    final hasBgm = backgroundMusic != null && backgroundMusic.hasMusic;
    final bgmInputIndex = bRollBaseIndex + validBRoll.length;
    final sfxBaseIndex = hasBgm ? bgmInputIndex + 1 : bgmInputIndex;
    final hasBRollAudio = validBRoll.any((c) => c.isVideo && c.hasAudio && c.volume > 0.0);
    final hasAdditionalAudio = hasBgm || sfxItems.isNotEmpty || hasBRollAudio;

    final isStudioSoundActive = enableStudioSound || (audioMastering != null && audioMastering.enableStudioSound);
    final studioSoundFilter = audioMastering != null && audioMastering.enableStudioSound
        ? buildStudioSoundFilter(
            platform: audioMastering.platform,
            enableDeEsser: audioMastering.enableDeEsser,
            deEsserIntensity: audioMastering.deEsserIntensity,
          )
        : buildStudioSoundFilter();

    if (isStudioSoundActive && hasAudio && !hasAdditionalAudio) {
      filterComplex.write('; [a_trimmed]$studioSoundFilter[a_final]');
      return filterComplex.toString();
    }

    String voiceStream = '[a_trimmed]';
    if (isStudioSoundActive && hasAudio) {
      filterComplex.write('; [a_trimmed]$studioSoundFilter[a_polished]');
      voiceStream = '[a_polished]';
    }

    final mixInputs = <String>[voiceStream];

    if (hasBgm) {
      double totalExportDuration = 0.0;
      for (final seg in segmentsToUse) {
        final start = seg.start ?? 0.0;
        final end = seg.end ?? 0.0;
        totalExportDuration += math.max(0.1, end - start);
      }
      if (totalExportDuration <= 0.0) {
        totalExportDuration = math.max(0.1, project.duration);
      }
      final bgmVol = backgroundMusic.volume.clamp(0.0, 1.0);
      final durationStr = totalExportDuration.toStringAsFixed(3);
      if (backgroundMusic.loop) {
        filterComplex.write('; [$bgmInputIndex:a]aloop=loop=-1:size=2e+09,atrim=0:$durationStr,asetpts=PTS-STARTPTS,volume=${bgmVol.toStringAsFixed(2)}[bgm_vol]');
      } else {
        filterComplex.write('; [$bgmInputIndex:a]atrim=0:$durationStr,asetpts=PTS-STARTPTS,volume=${bgmVol.toStringAsFixed(2)}[bgm_vol]');
      }

      if (backgroundMusic.enableDucking && hasAudio) {
        final duckRatio = backgroundMusic.duckingRatio.clamp(1.5, 20.0);
        filterComplex.write('; [bgm_vol]$voiceStream sidechaincompress=threshold=0.08:ratio=${duckRatio.toStringAsFixed(1)}:attack=50:release=300:makeup=1[bgm_ducked]');
        mixInputs.add('[bgm_ducked]');
      } else {
        mixInputs.add('[bgm_vol]');
      }
    }

    // Mix B-roll video audio if clip has volume > 0 and audio track
    for (int i = 0; i < validBRoll.length; i++) {
      final clip = validBRoll[i];
      if (clip.isVideo && clip.hasAudio && clip.volume > 0.0) {
        final bRollInputIndex = bRollBaseIndex + i;
        final clipDuration = math.max(0.05, clip.endTime - clip.startTime);
        final int delayMs = ((clip.startTime) * 1000).toInt();
        final vol = clip.volume.clamp(0.0, 2.0);
        final dStr = clipDuration.toStringAsFixed(3);
        filterComplex.write('; [$bRollInputIndex:a]atrim=0:$dStr,asetpts=PTS-STARTPTS,volume=${vol.toStringAsFixed(2)},adelay=$delayMs|$delayMs[broll_audio_$i]');
        mixInputs.add('[broll_audio_$i]');
      }
    }

    for (int i = 0; i < sfxItems.length; i++) {
      final item = sfxItems[i];
      final sfxInputIndex = sfxBaseIndex + i;
      final int delayMs = ((item.start) * 1000).toInt();
      final double vol = item.soundVolume / 100.0;

      final sfxDuration = item.end - item.start;
      final double fadeDuration = (sfxDuration * 0.25).clamp(0.01, 0.15);
      final double fadeOutStart = math.max(0.0, sfxDuration - fadeDuration);

      filterComplex.write('; [$sfxInputIndex:a]volume=volume=$vol,afade=t=in:ss=0:d=${fadeDuration.toStringAsFixed(3)},afade=t=out:ss=${fadeOutStart.toStringAsFixed(3)}:d=${fadeDuration.toStringAsFixed(3)},adelay=$delayMs|$delayMs[sfx_delayed_$i]');
      mixInputs.add('[sfx_delayed_$i]');
    }

    if (mixInputs.length > 1) {
      filterComplex.write('; ${mixInputs.join('')}amix=inputs=${mixInputs.length}:duration=first:normalize=0[a_final]');
    } else {
      filterComplex.write('; ${voiceStream}anull[a_final]');
    }

    return filterComplex.toString();
  }

  String buildFilterComplex({
    required Project project,
    required List<VideoSegmentSchema> segmentsToUse,
    required List<Chunk> trimmedChunks,
    required List<(WordSchema, String)> validEmojiWords,
    required List<SfxExportItem> sfxItems,
    required String assPath,
    String? tempFontsDir,
    AspectConversionMode? conversionMode,
    int? sourceWidth,
    int? sourceHeight,
    bool enableAudioCrossfade = false,
    double audioCrossfadeDuration = 0.05,
    bool hasAudio = true,
    bool enableStudioSound = false,
    AudioMasteringConfig? audioMastering,
    RetentionProgressBarConfig? progressBarConfig,
    BackgroundMusicConfig? backgroundMusic,
    List<SpeakerInterval>? speakerIntervals,
  }) =>
      buildVideoFilterComplex(
        project: project,
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
      );

  Future<String> convertToPngOnMobile(String filePath, String tempDir) async {
    // If not on mobile, or not a webp file, return original path
    if (!Platform.isAndroid && !Platform.isIOS) {
      return filePath;
    }
    if (!filePath.toLowerCase().endsWith('.webp')) {
      return filePath;
    }

    try {
      final file = File(filePath);
      if (!file.existsSync()) return filePath;

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return filePath;

      final pngBytes = byteData.buffer.asUint8List();
      final filename = '${p.basenameWithoutExtension(filePath)}.png';
      final outPath = p.join(tempDir, 'emoji_fallback_$filename');

      await File(outPath).writeAsBytes(pngBytes);
      return outPath;
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter', 'Failed to convert WebP emoji to PNG: $e');
      return filePath;
    }
  }

  Future<bool> isAnimatedFile(String filePath) async {
    final lowercasePath = filePath.toLowerCase();
    if (lowercasePath.endsWith('.gif') || lowercasePath.endsWith('.webp')) {
      return true;
    }
    if (lowercasePath.endsWith('.png')) {
      try {
        final file = File(filePath);
        if (file.existsSync()) {
          final bytes = await file.readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final isAnim = codec.frameCount > 1;
          codec.dispose();
          return isAnim;
        }
      } catch (e) {
        LoggerService.instance.debug('isAnimatedFile probe failed for $filePath: $e');
      }
    }
    return false;
  }
}
