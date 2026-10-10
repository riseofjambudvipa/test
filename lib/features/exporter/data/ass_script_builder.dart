import 'package:meta/meta.dart';
import '../../../core/database/schemas/project.dart';
import '../../../core/database/schemas/word.dart';
import '../../editor/domain/caption_engine.dart';
import '../../../core/utils/text_layout_utils.dart';
import '../../../core/utils/ass_position_utils.dart';
import '../../../core/utils/ass_color_utils.dart';

/// Escapes a path for FFmpeg's subtitles filter.
String escapeAssPath(String path) {
  return path
      .replaceAll('\\', '/')
      .replaceAll(':', r'\:')
      .replaceAll("'", r"'\''");
}

/// Converts a Hex color (e.g. '#f97316') to ASS color format (&HBBGGRR&).
/// Note that ASS uses Alpha Blue Green Red (AABBGGRR) hex mapping in reverse.
// FIX (Issue #11, CapStudio 1.0 audit): delegates to the shared
// AssColorUtils so this and subtitle_exporter.dart can never drift again.
String _toAssColor(String hex) => AssColorUtils.hexToAssColor(hex);

/// Converts seconds to ASS time format (H:MM:SS.CC where CC is centiseconds)
String _toAssTime(double seconds) {
  if (seconds < 0) seconds = 0;
  final totalCs = (seconds * 100).round();
  final h = totalCs ~/ 360000;
  final m = (totalCs % 360000) ~/ 6000;
  final s = (totalCs % 6000) ~/ 100;
  final cs = totalCs % 100;

  return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
}

List<List<WordSchema>> splitWordsIntoLines({
  required List<WordSchema> words,
  required String fontFamily,
  required double fontSize,
  required String fontWeight,
  required double letterSpacing,
  required double maxPixelWidth,
}) {
  return TextLayoutUtils.splitWordsIntoLines(
    words: words,
    fontFamily: fontFamily,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    maxPixelWidth: maxPixelWidth,
  );
}

/// Generates the complete .ass subtitle script file content based on project caption data
String generateAssScript(Project project, List<Chunk> chunks) {
  final config = project.config;
  final style = config.style;
  final hs = config.highlightStyle;

  final primaryColor = _toAssColor(style.color);
  final highlightColor = _toAssColor(hs.mainColor);

  // Outline and Back shadows
  final outlineColor = (config.stroke == 'thick' || config.stroke == 'thin') ? '&H00000000&' : '&H00FFFFFF&';
  final shadowColor = '&H80000000&'; // 50% transparent black

  final double exportScale = project.height / 640.0;
  final double assFontSize = style.fontSize * exportScale;
  final double outlineWidth = config.stroke == 'thick' ? 6.0 * exportScale : (config.stroke == 'thin' ? 2.5 * exportScale : 0.0);
  final double shadowWidth = (config.shadow == '3d' || config.shadow == 'extruded')
      ? 5.0 * exportScale
      : (config.shadow == 'hard' ? 3.5 * exportScale : (config.shadow == 'soft' ? 2.0 * exportScale : 0.0));

  // Bold flag: ASS uses -1 for bold, 0 for normal.
  // Cover all font weights that render visually bold (600 = SemiBold and above).
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
  final bool hasBackgroundBox = config.background != null || style.highlightBackground == true;
  final String backColor = config.background != null
      ? _toAssColor(config.background!)
      : (style.highlightBackground == true ? highlightColor : shadowColor);
  final int borderStyle = hasBackgroundBox ? 3 : 1;
  // For opaque box style (borderStyle = 3), use the outline width as padding.
  // If outline width is 0, provide a default padding of 6.0 * exportScale.
  final double finalOutlineWidth = hasBackgroundBox
      ? (outlineWidth > 0 ? outlineWidth : 6.0 * exportScale)
      : outlineWidth;
  final String finalOutlineColor = hasBackgroundBox ? backColor : outlineColor;

  final buffer = StringBuffer()
    ..writeln('[Script Info]')
    ..writeln('Title: CapStudio Subtitles')
    ..writeln('ScriptType: v4.00+')
    ..writeln('PlayResX: ${project.width}')
    ..writeln('PlayResY: ${project.height}')
    ..writeln('ScaledBorderAndShadow: yes')
    ..writeln()
    ..writeln('[V4+ Styles]')
    ..writeln('Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding')
    // Note: Swap PrimaryColour and SecondaryColour so that un-highlighted text is primaryColor and highlighted text is highlightColor.
    ..writeln('Style: Default,${style.fontFamily},${assFontSize.toInt()},$highlightColor,$primaryColor,$finalOutlineColor,$backColor,$assBold,0,0,0,100,100,${assSpacing.toStringAsFixed(1)},0,$borderStyle,${finalOutlineWidth.toStringAsFixed(1)},${shadowWidth.toStringAsFixed(1)},5,10,10,0,1')
    ..writeln()
    ..writeln('[Events]')
    ..writeln('Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text');

  final double captionMaxW = project.width * 0.80;

  for (final chunk in chunks) {
    final startStr = _toAssTime(chunk.startTime);
    final endStr = _toAssTime(chunk.endTime);

    // 2. Wrap words into lines
    final lines = splitWordsIntoLines(
      words: chunk.words,
      fontFamily: style.fontFamily,
      fontSize: style.fontSize * exportScale,
      fontWeight: style.fontWeight,
      letterSpacing: (style.letterSpacing ?? 0.0) * exportScale,
      maxPixelWidth: captionMaxW,
    );

    final pos = AssPositionUtils.calculatePosition(
      projectWidth: project.width.toDouble(),
      projectHeight: project.height.toDouble(),
      styleTop: style.top,
      styleLeft: style.left,
      fontFamily: style.fontFamily,
      fontSize: style.fontSize,
      fontWeight: style.fontWeight,
      letterSpacing: style.letterSpacing,
      words: chunk.words,
    );

    final double xTextCenter = pos.x;
    final double yTextCenter = pos.y;

    // Chunk fade-in (25ms fade in, 50ms fade out) — makes entries smooth
    final fadeTag = '\\fad(25,50)';
    final textBuffer = StringBuffer()
      ..write('{\\an5\\pos(${xTextCenter.round()},${yTextCenter.round()})$fadeTag}');

    int wordIndexInChunk = 0;
    for (int lineIdx = 0; lineIdx < lines.length; lineIdx++) {
      final lineWords = lines[lineIdx];
      if (lineIdx > 0) {
        textBuffer.write('\\N');
      }
      for (int i = 0; i < lineWords.length; i++) {
        final w = lineWords[i];
        final rawDuration = (w.end ?? 0.0) - (w.start ?? 0.0);
        final durationCentiseconds = (rawDuration * 100).round().clamp(1, 9999);
        final String cleanText = _transformText((w.text ?? '').replaceAll('"', '').trim(), style.textTransform);

        // Emojis are overlayed as images, so we never burn them as text glyphs in the ASS subtitle file to prevent broken box glyphs.

        final spacePrefix = i == 0 ? '' : ' ';

        // Per-word color override based on className
        String colorTag = '';
        String colorReset = '';
        if (w.className != null) {
          final wordColor = switch (w.className) {
            'mainColor'   => _toAssColor(hs.mainColor),
            'secondColor' => _toAssColor(hs.secondColor),
            'thirdColor'  => _toAssColor(hs.thirdColor),
            _             => '',
          };
          if (wordColor.isNotEmpty) {
            colorTag  = '{\\c$wordColor}';
            // Since colors are swapped, we reset to the style's default highlight color
            colorReset = '{\\c$highlightColor}';
          }
        }

        // Active-word subtitle overlay animations
        final (animTag, animReset) = _getAnimationTags(
          word: w,
          chunk: chunk,
          config: config,
          outlineWidth: outlineWidth,
          exportScale: exportScale,
          wordIndex: wordIndexInChunk,
        );

        // \k = instant karaoke highlight.
        // Note: We use the simple \k (instant highlight) instead of \kf (gradual sweep/fill)
        // because the Flutter editor preview highlights the active word instantly.
        // Using \k ensures that the exported burned-in video matches the user's preview
        // perfectly with no timing or visual discrepancies.
        textBuffer.write('$spacePrefix$colorTag$animTag{\\k$durationCentiseconds}$cleanText$animReset$colorReset');
        wordIndexInChunk++;
      }
    }

    final speakerName = chunk.speaker ?? '';
    buffer.writeln('Dialogue: 0,$startStr,$endStr,Default,$speakerName,0,0,0,,$textBuffer');
  }

  return buffer.toString();
}

/// Computes and returns the standard ASS tags required to apply active word subtitle overlay animations.
/// Returns a record/tuple `(animTag, animReset)` containing the animation string and its corresponding reset string.
(String, String) _getAnimationTags({
  required WordSchema word,
  required Chunk chunk,
  required ProjectConfigSchema config,
  required double outlineWidth,
  required double exportScale,
  required int wordIndex,
}) {
  if (word.start == null || word.end == null || word.start! >= word.end!) {
    return ('', '');
  }

  final wordStartRelative = word.start! - chunk.startTime;
  final wordEndRelative = word.end! - chunk.startTime;
  final startMs = (wordStartRelative * 1000).round().clamp(0, 999999);
  final endMs = (wordEndRelative * 1000).round().clamp(0, 999999);

  if (startMs >= endMs) {
    return ('', '');
  }

  switch (config.animation) {
    case 'pop':
      return (
        '{\\t($startMs,$startMs,\\fscx112\\fscy112)\\t($endMs,$endMs,\\fscx100\\fscy100)}',
        '{\\fscx100\\fscy100}'
      );
    case 'bounce':
      return (
        '{\\t($startMs,$startMs,\\fscy125\\fscx85)\\t($endMs,$endMs,\\fscx100\\fscy100)}',
        '{\\fscx100\\fscy100}'
      );
    case 'kineticTilt':
      final tiltDeg = wordIndex % 2 == 0 ? 5 : -5;
      return (
        '{\\t($startMs,$startMs,\\frz$tiltDeg)\\t($endMs,$endMs,\\frz0)}',
        '{\\frz0}'
      );
    case 'wordReveal':
      final midMs = ((startMs + endMs) ~/ 2);
      return (
        '{\\fscy0\\t($startMs,$midMs,\\fscy100)}',
        '{\\fscy100}'
      );
    case 'glowPulse':
      final expandedBord = outlineWidth + (3.0 * exportScale);
      return (
        '{\\t($startMs,$startMs,\\bord$expandedBord)\\t($endMs,$endMs,\\bord$outlineWidth)}',
        '{\\bord$outlineWidth}'
      );
    default:
      return ('', '');
  }
}

String _transformText(String s, String mode) {
  final clean = s.replaceAll('{', '').replaceAll('}', '').replaceAll('\r', '').replaceAll('\n', '');
  return switch (mode) {
    'uppercase'  => clean.toUpperCase(),
    'capitalize' => clean.isEmpty ? clean : clean[0].toUpperCase() + clean.substring(1),
    _            => clean,
  };
}

@visibleForTesting
(String, String) getAnimationTagsForTesting({
  required WordSchema word,
  required Chunk chunk,
  required ProjectConfigSchema config,
  required double outlineWidth,
  required double exportScale,
  required int wordIndex,
}) =>
    _getAnimationTags(
      word: word,
      chunk: chunk,
      config: config,
      outlineWidth: outlineWidth,
      exportScale: exportScale,
      wordIndex: wordIndex,
    );

@visibleForTesting
String transformTextForTesting(String s, String mode) =>
    _transformText(s, mode);

