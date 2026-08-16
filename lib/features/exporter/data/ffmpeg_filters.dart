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
import 'ass_script_builder.dart' show escapeAssPath, splitWordsIntoLines;
import 'ffmpeg_exporter.dart' show SfxExportItem;
import 'ffmpeg_font_preparer.dart' show FfmpegFontPreparation;

/// Builds FFmpeg `-filter_complex` graphs and resolves emoji/SFX assets for
/// the video export. Mixed into [FfmpegExporter] alongside [FfmpegExecutor]
/// and the font preparation mixin.
mixin FfmpegFilterBuilder on FfmpegFontPreparation {
  String buildFilterComplexSlow({
    required Project project,
    required List<VideoSegmentSchema> segmentsToUse,
    required List<SfxExportItem> sfxItems,
  }) {
    final filterComplex = StringBuffer();

    // 1. Trim the video input [0:v] -> [v_trimmed]
    final int numSegments = segmentsToUse.length;
    if (numSegments == 1) {
      final start = segmentsToUse[0].start ?? 0.0;
      final end = segmentsToUse[0].end ?? 0.0;
      filterComplex.write('[0:v]trim=start=$start:end=$end,setpts=PTS-STARTPTS[v_trimmed]; ');
      filterComplex.write('[0:a]atrim=start=$start:end=$end,asetpts=PTS-STARTPTS[a_trimmed]');
    } else {
      filterComplex.write('[0:v]split=$numSegments');
      for (int i = 0; i < numSegments; i++) {
        filterComplex.write('[v_split_$i]');
      }
      filterComplex.write('; [0:a]asplit=$numSegments');
      for (int i = 0; i < numSegments; i++) {
        filterComplex.write('[a_split_$i]');
      }

      for (int i = 0; i < numSegments; i++) {
        final seg = segmentsToUse[i];
        final start = seg.start ?? 0.0;
        final end = seg.end ?? 0.0;
        filterComplex.write('; [v_split_$i]trim=start=$start:end=$end,setpts=PTS-STARTPTS[v_seg_$i]');
        filterComplex.write('; [a_split_$i]atrim=start=$start:end=$end,asetpts=PTS-STARTPTS[a_seg_$i]');
      }

      final concatInputs = StringBuffer();
      for (int i = 0; i < numSegments; i++) {
        concatInputs.write('[v_seg_$i][a_seg_$i]');
      }
      filterComplex.write('; ${concatInputs.toString()}concat=n=$numSegments:v=1:a=1[v_trimmed][a_trimmed]');
    }

    // 2. Overlay the raw PNG sequence [1:v] onto [v_trimmed] -> [v_final]
    filterComplex.write('; [v_trimmed][1:v]overlay=0:0[v_final]');

    // 3. Build audio mix filter if we have sound effects, producing [a_final]
    if (sfxItems.isNotEmpty) {
      final mixInputs = ['[a_trimmed]'];

      for (int i = 0; i < sfxItems.length; i++) {
        final item = sfxItems[i];
        final sfxInputIndex = 2 + i; // Index 0: original video, Index 1: PNG sequence, Index 2+: SFX files
        final int delayMs = ((item.start) * 1000).toInt();
        final double vol = item.soundVolume / 100.0;

        final sfxDuration = item.end - item.start;
        final double fadeDuration = (sfxDuration * 0.25).clamp(0.01, 0.15);
        final double fadeOutStart = math.max(0.0, sfxDuration - fadeDuration);

        filterComplex.write('; [$sfxInputIndex:a]volume=volume=$vol,afade=t=in:ss=0:d=${fadeDuration.toStringAsFixed(3)},afade=t=out:ss=${fadeOutStart.toStringAsFixed(3)}:d=${fadeDuration.toStringAsFixed(3)},adelay=$delayMs|$delayMs[sfx_delayed_$i]');
        mixInputs.add('[sfx_delayed_$i]');
      }

      filterComplex.write('; ${mixInputs.join('')}amix=inputs=${sfxItems.length + 1}:duration=first:normalize=0[a_final]');
    } else {
      filterComplex.write('; [a_trimmed]anull[a_final]');
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
        if (word.emoji != null && word.emoji!.isNotEmpty) {
          if (await File(word.emoji!).exists()) {
            validEmojiWords.add((word, word.emoji!));
          } else {
            // Parse the emoji and potential pack override
            final parseResult = EmojiPackParser.parse(word.emoji!, emojiPack ?? 'notoColorEmoji');
            final activePack = parseResult.pack;
            final glyph = parseResult.glyph;

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

  String buildFilterComplex({
    required Project project,
    required List<VideoSegmentSchema> segmentsToUse,
    required List<Chunk> trimmedChunks,
    required List<(WordSchema, String)> validEmojiWords,
    required List<SfxExportItem> sfxItems,
    required String assPath,
    String? tempFontsDir,
  }) {
    final filterComplex = StringBuffer();
    final double exportScale = project.height / 640.0;

    // Trim video and audio inputs first
    final int numSegments = segmentsToUse.length;
    if (numSegments == 1) {
      final start = segmentsToUse[0].start ?? 0.0;
      final end = segmentsToUse[0].end ?? 0.0;
      filterComplex.write('[0:v]trim=start=$start:end=$end,setpts=PTS-STARTPTS[v_trimmed]; ');
      filterComplex.write('[0:a]atrim=start=$start:end=$end,asetpts=PTS-STARTPTS[a_trimmed]');
    } else {
      filterComplex.write('[0:v]split=$numSegments');
      for (int i = 0; i < numSegments; i++) {
        filterComplex.write('[v_split_$i]');
      }
      filterComplex.write('; [0:a]asplit=$numSegments');
      for (int i = 0; i < numSegments; i++) {
        filterComplex.write('[a_split_$i]');
      }

      for (int i = 0; i < numSegments; i++) {
        final seg = segmentsToUse[i];
        final start = seg.start ?? 0.0;
        final end = seg.end ?? 0.0;
        filterComplex.write('; [v_split_$i]trim=start=$start:end=$end,setpts=PTS-STARTPTS[v_seg_$i]');
        filterComplex.write('; [a_split_$i]atrim=start=$start:end=$end,asetpts=PTS-STARTPTS[a_seg_$i]');
      }

      final concatInputs = StringBuffer();
      for (int i = 0; i < numSegments; i++) {
        concatInputs.write('[v_seg_$i][a_seg_$i]');
      }
      filterComplex.write('; ${concatInputs.toString()}concat=n=$numSegments:v=1:a=1[v_trimmed][a_trimmed]');
    }

    // Chain video overlays for emojis on [v_trimmed]
    String currentVideoStream = '[v_trimmed]';

    final style = project.config.style;
    final double captionMaxW = project.width * 0.80;

    for (int i = 0; i < validEmojiWords.length; i++) {
      final w = validEmojiWords[i];
      final wWord = w.$1;
      final emojiInputIndex = i + 1;

      final chunk = trimmedChunks.firstWhere(
        (c) => c.words.any((cw) => cw.wordId == wWord.wordId),
        orElse: () => Chunk(index: 0, startTime: wWord.start ?? 0.0, endTime: wWord.end ?? 0.0, words: []),
      );

      final double emojiScaleFactor = wWord.emojiConfig?.scale ?? 1.0;
      final int scaledW = (80.0 * exportScale * emojiScaleFactor).round();
      final int scaledH = (80.0 * exportScale * emojiScaleFactor).round();

      final double speed = wWord.emojiConfig?.speed ?? 1.0;
      final String speedFilter = speed != 1.0 ? '(1/$speed)*' : '';
      filterComplex.write('; [$emojiInputIndex:v]scale=$scaledW:$scaledH,format=rgba,setpts=$speedFilter(PTS-STARTPTS)+${chunk.startTime.toStringAsFixed(3)}/TB[emoji_scaled_$i]');

      final double xOffset = (wWord.emojiConfig?.x ?? 0.0) * exportScale;
      final double yOffset = (wWord.emojiConfig?.y ?? 0.0) * exportScale;
      final double xCoord = (project.width / 2.0) - (scaledW / 2.0) + xOffset;

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

    // Burn subtitles on top of the final video overlay stream, producing [v_final]
    final escapedAssPath = escapeAssPath(assPath);
    final fontsDir = tempFontsDir ?? getSafeFontsDir();
    if (fontsDir != null) {
      final escapedFontsDir = escapeAssPath(fontsDir);
      filterComplex.write('; ${currentVideoStream}subtitles=\'$escapedAssPath\':fontsdir=\'$escapedFontsDir\'[v_final]');
    } else {
      filterComplex.write('; ${currentVideoStream}subtitles=\'$escapedAssPath\'[v_final]');
    }

    // Build audio mix filter if we have sound effects, producing [a_final]
    if (sfxItems.isNotEmpty) {
      final mixInputs = ['[a_trimmed]'];

      for (int i = 0; i < sfxItems.length; i++) {
        final item = sfxItems[i];
        final sfxInputIndex = 1 + validEmojiWords.length + i;
        final int delayMs = ((item.start) * 1000).toInt();
        final double vol = item.soundVolume / 100.0;

        final sfxDuration = item.end - item.start;
        final double fadeDuration = (sfxDuration * 0.25).clamp(0.01, 0.15);
        final double fadeOutStart = math.max(0.0, sfxDuration - fadeDuration);

        filterComplex.write('; [$sfxInputIndex:a]volume=volume=$vol,afade=t=in:ss=0:d=${fadeDuration.toStringAsFixed(3)},afade=t=out:ss=${fadeOutStart.toStringAsFixed(3)}:d=${fadeDuration.toStringAsFixed(3)},adelay=$delayMs|$delayMs[sfx_delayed_$i]');
        mixInputs.add('[sfx_delayed_$i]');
      }

      filterComplex.write('; ${mixInputs.join('')}amix=inputs=${sfxItems.length + 1}:duration=first:normalize=0[a_final]');
    } else {
      filterComplex.write('; [a_trimmed]anull[a_final]');
    }

    return filterComplex.toString();
  }

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
      } catch (_) {}
    }
    return false;
  }
}
