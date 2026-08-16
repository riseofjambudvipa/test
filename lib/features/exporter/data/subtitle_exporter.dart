import 'dart:convert';
import 'dart:io';
import 'package:meta/meta.dart';
import '../../../core/database/schemas/project.dart';
import '../../../core/database/schemas/word.dart';
import '../../../core/emoji/emoji_model.dart';
import '../../../core/utils/ass_position_utils.dart';
import '../../../core/utils/ass_color_utils.dart';
import '../../editor/domain/caption_engine.dart';

class SubtitleExporter {

  /// Export as SRT (SubRip) format
  /// Standard format: index, timecode, text, blank line
  static String toSrt(Project project) {
    final chunks = CaptionEngine.buildChunks(
      project.words,
      project.segments,
      project.trimStart,
      project.trimEnd,
      project.config.subs.chunkSize,
      project.config.subs.chunkLineMaxLength,
    );

    final buffer = StringBuffer();
    int index = 1;

    for (final chunk in chunks) {
      if (chunk.words.isEmpty) continue;
      final visibleWords = chunk.words.where((w) => w.hidden != true).toList();
      if (visibleWords.isEmpty) continue;

      final start = _toSrtTime(chunk.startTime);
      final end = _toSrtTime(chunk.endTime);
      final text = _buildChunkText(visibleWords, project.config);

      buffer.writeln(index++);
      buffer.writeln('$start --> $end');
      buffer.writeln(text);
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Export as WebVTT format (for web video players)
  static String toVtt(Project project) {
    final chunks = CaptionEngine.buildChunks(
      project.words,
      project.segments,
      project.trimStart,
      project.trimEnd,
      project.config.subs.chunkSize,
      project.config.subs.chunkLineMaxLength,
    );

    final buffer = StringBuffer();
    buffer.writeln('WEBVTT');
    buffer.writeln();

    int index = 1;
    for (final chunk in chunks) {
      if (chunk.words.isEmpty) continue;
      final visibleWords = chunk.words.where((w) => w.hidden != true).toList();
      if (visibleWords.isEmpty) continue;

      final start = _toVttTime(chunk.startTime);
      final end = _toVttTime(chunk.endTime);
      final text = _buildChunkText(visibleWords, project.config);

      buffer.writeln('${index++}');
      buffer.writeln('$start --> $end');
      buffer.writeln(text);
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Export as plain TXT (one line per chunk, timestamped)
  static String toTxt(Project project) {
    final chunks = CaptionEngine.buildChunks(
      project.words,
      project.segments,
      project.trimStart,
      project.trimEnd,
      project.config.subs.chunkSize,
      project.config.subs.chunkLineMaxLength,
    );

    final buffer = StringBuffer();
    for (final chunk in chunks) {
      final visibleWords = chunk.words.where((w) => w.hidden != true).toList();
      if (visibleWords.isEmpty) continue;
      final text = _buildChunkText(visibleWords, project.config);
      buffer.writeln('[${_toSrtTime(chunk.startTime)}] $text');
    }

    return buffer.toString();
  }

  /// Save to a file path and return the written file path
  static Future<String> saveToFile(String content, String outputPath) async {
    final file = File(outputPath);
    await file.writeAsString(content, encoding: utf8);
    return file.path;
  }

  /// Export as ASS (Advanced SubStation Alpha) format with embedded styles
  static String toAss(Project project) {
    final chunks = CaptionEngine.buildChunks(
      project.words,
      project.segments,
      project.trimStart,
      project.trimEnd,
      project.config.subs.chunkSize,
      project.config.subs.chunkLineMaxLength,
    );

    final config = project.config;
    final style = config.style;
    final hs = config.highlightStyle;
    
    final primaryColor = _hexToAssColor(style.color);
    final highlightColor = _hexToAssColor(hs.mainColor);
    final outlineColor = config.stroke == 'thick' ? '&H00000000&' : '&H00FFFFFF&';
    final shadowColor = '&H80000000&'; // 50% transparent black
    
    final width = project.width > 0 ? project.width : 1920;
    final height = project.height > 0 ? project.height : 1080;

    final double exportScale = height / 640.0;
    final double assFontSize = style.fontSize * exportScale;
    final double outlineWidth = config.stroke == 'thick' ? 6.0 * exportScale : 0.0;
    final double shadowWidth = config.shadow == 'soft' ? 2.0 * exportScale : 0.0;

    // Bold flag: ASS uses -1 for bold, 0 for normal.
    final int assBold = (style.fontWeight == 'bold' ||
                         style.fontWeight == '600' ||
                         style.fontWeight == '700' ||
                         style.fontWeight == '800' ||
                         style.fontWeight == '900')
        ? -1
        : 0;

    // Spacing
    final double assSpacing = (style.letterSpacing ?? 0.0) * exportScale;

    // Background box configuration
    final String finalBackColor = config.background != null 
        ? _hexToAssColor(config.background!) 
        : shadowColor;
    final int borderStyle = config.background != null ? 3 : 1;
    final double finalOutlineWidth = config.background != null
        ? (outlineWidth > 0 ? outlineWidth : 6.0 * exportScale)
        : outlineWidth;
    final String finalOutlineColor = config.background != null ? finalBackColor : outlineColor;

    final buffer = StringBuffer();
    buffer.writeln('[Script Info]');
    buffer.writeln('; Script generated by CapStudio');
    buffer.writeln('Title: CapStudio Subtitles');
    buffer.writeln('ScriptType: v4.00+');
    buffer.writeln('PlayResX: $width');
    buffer.writeln('PlayResY: $height');
    buffer.writeln('ScaledBorderAndShadow: yes');
    buffer.writeln();

    buffer.writeln('[V4+ Styles]');
    buffer.writeln('Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding');
    buffer.writeln('Style: Default,${style.fontFamily},${assFontSize.toInt()},$primaryColor,$highlightColor,$finalOutlineColor,$finalBackColor,$assBold,0,0,0,100,100,${assSpacing.toStringAsFixed(1)},0,$borderStyle,${finalOutlineWidth.toStringAsFixed(1)},${shadowWidth.toStringAsFixed(1)},5,10,10,0,1');
    buffer.writeln();

    buffer.writeln('[Events]');
    buffer.writeln('Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');

    for (final chunk in chunks) {
      if (chunk.words.isEmpty) continue;
      final visibleWords = chunk.words.where((w) => w.hidden != true).toList();
      if (visibleWords.isEmpty) continue;

      final start = _toAssTime(chunk.startTime);
      final end = _toAssTime(chunk.endTime);
      
      final pos = AssPositionUtils.calculatePosition(
        projectWidth: width.toDouble(),
        projectHeight: height.toDouble(),
        styleTop: style.top,
        fontFamily: style.fontFamily,
        fontSize: style.fontSize,
        fontWeight: style.fontWeight,
        letterSpacing: style.letterSpacing,
        words: visibleWords,
      );

      final text = _buildChunkTextWithAssTags(visibleWords, config);
      final posTag = '{\\an5\\pos(${pos.x.round()},${pos.y.round()})}';

      buffer.writeln('Dialogue: 0,$start,$end,Default,,0000,0000,0000,,$posTag$text');
    }

    return buffer.toString();
  }

  // --- Helpers ---

  static String _buildChunkText(List<WordSchema> words, ProjectConfigSchema config) {
    final transformed = words.map((w) {
      String text = w.text ?? '';
      switch (config.style.textTransform) {
        case 'uppercase':
          text = text.toUpperCase();
          break;
        case 'capitalize':
          if (text.isNotEmpty) {
            text = text[0].toUpperCase() + text.substring(1);
          }
          break;
      }

      if (w.emoji != null && w.emoji!.isNotEmpty && w.emoji != 'none') {
        final parsed = EmojiPackParser.parse(w.emoji!, '');
        if (text.isEmpty) {
          text = parsed.glyph;
        } else {
          text = '$text ${parsed.glyph}';
        }
      }

      return text;
    });
    return transformed.join(' ');
  }

  /// Builds the subtitle chunk text with inline ASS style tags for highlighting
  static String _buildChunkTextWithAssTags(List<WordSchema> words, ProjectConfigSchema config) {
    final hs = config.highlightStyle;
    final defaultColor = _hexToAssColor(config.style.color);
    
    final parts = <String>[];
    for (final w in words) {
      String text = w.text ?? '';
      switch (config.style.textTransform) {
        case 'uppercase': text = text.toUpperCase(); break;
        case 'capitalize':
          if (text.isNotEmpty) text = text[0].toUpperCase() + text.substring(1);
          break;
      }

      if (w.emoji != null && w.emoji!.isNotEmpty && w.emoji != 'none') {
        final parsed = EmojiPackParser.parse(w.emoji!, '');
        if (text.isEmpty) {
          text = parsed.glyph;
        } else {
          text = '$text ${parsed.glyph}';
        }
      }

      if (w.className != null && w.className != 'none') {
        String colorCode = defaultColor;
        if (w.className == 'mainColor') colorCode = _hexToAssColor(hs.mainColor);
        if (w.className == 'secondColor') colorCode = _hexToAssColor(hs.secondColor);
        if (w.className == 'thirdColor') colorCode = _hexToAssColor(hs.thirdColor);
        parts.add('{\\c$colorCode}$text{\\c}');
      } else {
        parts.add(text);
      }
    }
    return parts.join(' ');
  }

  @visibleForTesting
  static String hexToAssColor(String hex) => _hexToAssColor(hex);

  /// Convert standard Hex color code to ASS format (&H00BBGGRR or &HAABBGGRR)
  // FIX (Issue #11, CapStudio 1.0 audit): delegates to the shared
  // AssColorUtils, which validates input before converting — this file's
  // version previously had no validation and could produce a malformed ASS
  // color code on unexpected input, unlike ffmpeg_exporter.dart's version.
  static String _hexToAssColor(String hex) => AssColorUtils.hexToAssColor(hex);

  // SRT format: HH:MM:SS,mmm
  static String _toSrtTime(double seconds) {
    if (seconds < 0) seconds = 0;
    final totalMs = (seconds * 1000).round();
    final h = totalMs ~/ 3600000;
    final m = (totalMs % 3600000) ~/ 60000;
    final s = (totalMs % 60000) ~/ 1000;
    final ms = totalMs % 1000;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')},${ms.toString().padLeft(3, '0')}';
  }

  // VTT format: HH:MM:SS.mmm
  static String _toVttTime(double seconds) =>
      _toSrtTime(seconds).replaceAll(',', '.');

  /// Format time for ASS Subtitle format: H:MM:SS.cs
  static String _toAssTime(double seconds) {
    if (seconds < 0) seconds = 0;
    final totalCs = (seconds * 100).round();
    final h = totalCs ~/ 360000;
    final m = (totalCs % 360000) ~/ 6000;
    final s = (totalCs % 6000) ~/ 100;
    final cs = totalCs % 100;
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
  }
}
