import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:ffmpeg_kit_flutter_new/level.dart';
import '../../../core/database/schemas/project.dart';
import '../../../core/database/schemas/word.dart';
import '../../../core/audio/audio_service.dart';
import '../../../core/emoji/emoji_service.dart';
import '../../../core/assets/emoji_image.dart';
import '../../../core/logger/logger_service.dart';
import '../../../core/settings/settings_service.dart';
import '../../editor/domain/caption_engine.dart';
import '../../../core/utils/app_dirs.dart';
import '../../../core/utils/text_layout_utils.dart';
import '../../../core/utils/ass_position_utils.dart';
import '../../../core/utils/ass_color_utils.dart';
import '../../../core/assets/asset_path_service.dart';
import '../../../core/utils/font_metadata_reader.dart';

const List<String> _bundledFontAssets = [
  'Anton-Regular.ttf',
  'Bangers-Regular.ttf',
  'BebasNeue-Regular.ttf',
  'BlackHanSans-Regular.ttf',
  'Caveat-Variable.ttf',
  'ComicNeue-Bold.ttf',
  'DancingScript-Variable.ttf',
  'DMSerifDisplay-Regular.ttf',
  'Exo2-Variable.ttf',
  'Fraunces-Variable.ttf',
  'Gabarito-Variable.ttf',
  'Lobster-Regular.ttf',
  'Montserrat-Variable.ttf',
  'NotoNastaliqUrdu-Variable.ttf',
  'NotoSans-Variable.ttf',
  'NotoSansArabic-Variable.ttf',
  'NotoSansArmenian-Variable.ttf',
  'NotoSansBengali-Variable.ttf',
  'NotoSansDevanagari-Variable.ttf',
  'NotoSansEthiopic-Variable.ttf',
  'NotoSansGeorgian-Variable.ttf',
  'NotoSansGujarati-Variable.ttf',
  'NotoSansGurmukhi-Variable.ttf',
  'NotoSansHebrew-Variable.ttf',
  'NotoSansJP-Bold.ttf',
  'NotoSansKannada-Variable.ttf',
  'NotoSansKhmer-Variable.ttf',
  'NotoSansKR-Bold.ttf',
  'NotoSansLao-Variable.ttf',
  'NotoSansMalayalam-Variable.ttf',
  'NotoSansMyanmar-Variable.ttf',
  'NotoSansOriya-Variable.ttf',
  'NotoSansSC-Bold.ttf',
  'NotoSansSinhala-Variable.ttf',
  'NotoSansTamil-Variable.ttf',
  'NotoSansTC-Bold.ttf',
  'NotoSansTelugu-Variable.ttf',
  'NotoSansThai-Variable.ttf',
  'Nunito-Variable.ttf',
  'Orbitron-Variable.ttf',
  'Oswald-Variable.ttf',
  'Outfit-Variable.ttf',
  'Pacifico-Regular.ttf',
  'PlayfairDisplay-Variable.ttf',
  'Poppins-Bold.ttf',
  'Poppins-ExtraBold.ttf',
  'PressStart2P-Regular.ttf',
  'Raleway-Variable.ttf',
  'Righteous-Regular.ttf',
  'RubikGlitch-Regular.ttf',
  'SpaceGrotesk-Variable.ttf',
  'Urbanist-Variable.ttf',
];

class ExportProgress {
  final double progress; // 0.0 to 1.0
  final String status;   // 'rendering' | 'completed' | 'failed'
  final String? error;

  const ExportProgress({
    required this.progress,
    required this.status,
    this.error,
  });
}

class SfxExportItem {
  final String soundEffect;
  final int soundVolume;
  final double start;
  final double end;
  final String resolvedPath;
  SfxExportItem({
    required this.soundEffect,
    required this.soundVolume,
    required this.start,
    required this.end,
    required this.resolvedPath,
  });
}

class FfmpegExporter {
  static bool _fontsPrepared = false;
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

  /// Probes the local FFmpeg build to see which hardware encoders are available
  static Future<List<String>> probeAvailableEncoders(String ffmpegPath) async {
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

  /// Escapes ASS path for FFmpeg subtitles filter
  static String _escapeAssPath(String path) {
    return path
        .replaceAll('\\', '/')
        .replaceAll(':', r'\:')
        .replaceAll("'", r"'\''");
  }

  /// Converts a Hex color (e.g. '#f97316') to ASS color format (&HBBGGRR&).
  /// Note that ASS uses Alpha Blue Green Red (AABBGGRR) hex mapping in reverse.
  // FIX (Issue #11, CapStudio 1.0 audit): delegates to the shared
  // AssColorUtils so this and subtitle_exporter.dart can never drift again.
  static String _toAssColor(String hex) => AssColorUtils.hexToAssColor(hex);

  /// Converts seconds to ASS time format (H:MM:SS.CC where CC is centiseconds)
  static String _toAssTime(double seconds) {
    if (seconds < 0) seconds = 0;
    final totalCs = (seconds * 100).round();
    final h = totalCs ~/ 360000;
    final m = (totalCs % 360000) ~/ 6000;
    final s = (totalCs % 6000) ~/ 100;
    final cs = totalCs % 100;
    
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}.${cs.toString().padLeft(2, '0')}';
  }

  static List<List<WordSchema>> _splitWordsIntoLines({
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
  static String generateAssScript(Project project, List<Chunk> chunks) {
    final config = project.config;
    final style = config.style;
    final hs = config.highlightStyle;

    final primaryColor = _toAssColor(style.color);
    final highlightColor = _toAssColor(hs.mainColor);
    
    // Outline and Back shadows
    final outlineColor = config.stroke == 'thick' ? '&H00000000&' : '&H00FFFFFF&';
    final shadowColor = '&H80000000&'; // 50% transparent black
    
    final double exportScale = project.height / 640.0;
    final double assFontSize = style.fontSize * exportScale;
    final double outlineWidth = config.stroke == 'thick' ? 6.0 * exportScale : 0.0;
    final double shadowWidth = config.shadow == 'soft' ? 2.0 * exportScale : 0.0;

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
    final String backColor = config.background != null 
        ? _toAssColor(config.background!) 
        : shadowColor;
    final int borderStyle = config.background != null ? 3 : 1;
    // For opaque box style (borderStyle = 3), use the outline width as padding.
    // If outline width is 0, provide a default padding of 6.0 * exportScale.
    final double finalOutlineWidth = config.background != null
        ? (outlineWidth > 0 ? outlineWidth : 6.0 * exportScale)
        : outlineWidth;
    final String finalOutlineColor = config.background != null ? backColor : outlineColor;

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
      final lines = _splitWordsIntoLines(
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

      buffer.writeln('Dialogue: 0,$startStr,$endStr,Default,,0,0,0,,$textBuffer');
    }

    return buffer.toString();
  }

  /// Computes and returns the standard ASS tags required to apply active word subtitle overlay animations.
  /// Returns a record/tuple `(animTag, animReset)` containing the animation string and its corresponding reset string.
  static (String, String) _getAnimationTags({
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

  static String _transformText(String s, String mode) {
    final clean = s.replaceAll('{', '').replaceAll('}', '');
    return switch (mode) {
      'uppercase'  => clean.toUpperCase(),
      'capitalize' => clean.isEmpty ? clean : clean[0].toUpperCase() + clean.substring(1),
      _            => clean,
    };
  }

  String? _getSafeFontsDir() {
    try {
      return AssetPathService.instance.fontsDir;
    } catch (_) {
      return null;
    }
  }

  String? _getSafeAppDirsFonts() {
    try {
      return AppDirs.fonts;
    } catch (_) {
      return null;
    }
  }

  static const Map<String, String> _fontFileToFamily = {
    'Anton-Regular.ttf': 'Anton',
    'Bangers-Regular.ttf': 'Bangers',
    'BebasNeue-Regular.ttf': 'Bebas Neue',
    'BlackHanSans-Regular.ttf': 'Black Han Sans',
    'Caveat-Variable.ttf': 'Caveat',
    'ComicNeue-Bold.ttf': 'Comic Neue',
    'DancingScript-Variable.ttf': 'Dancing Script',
    'DMSerifDisplay-Regular.ttf': 'DM Serif Display',
    'Exo2-Variable.ttf': 'Exo 2',
    'Fraunces-Variable.ttf': 'Fraunces',
    'Gabarito-Variable.ttf': 'Gabarito',
    'Lobster-Regular.ttf': 'Lobster',
    'Montserrat-Variable.ttf': 'Montserrat',
    'NotoNastaliqUrdu-Variable.ttf': 'Noto Nastaliq Urdu',
    'NotoSans-Variable.ttf': 'Noto Sans',
    'NotoSansArabic-Variable.ttf': 'Noto Sans Arabic',
    'NotoSansArmenian-Variable.ttf': 'Noto Sans Armenian',
    'NotoSansBengali-Variable.ttf': 'Noto Sans Bengali',
    'NotoSansDevanagari-Variable.ttf': 'Noto Sans Devanagari',
    'NotoSansEthiopic-Variable.ttf': 'Noto Sans Ethiopic',
    'NotoSansGeorgian-Variable.ttf': 'Noto Sans Georgian',
    'NotoSansGujarati-Variable.ttf': 'Noto Sans Gujarati',
    'NotoSansGurmukhi-Variable.ttf': 'Noto Sans Gurmukhi',
    'NotoSansHebrew-Variable.ttf': 'Noto Sans Hebrew',
    'NotoSansJP-Bold.ttf': 'Noto Sans JP',
    'NotoSansKannada-Variable.ttf': 'Noto Sans Kannada',
    'NotoSansKhmer-Variable.ttf': 'Noto Sans Khmer',
    'NotoSansKR-Bold.ttf': 'Noto Sans KR',
    'NotoSansLao-Variable.ttf': 'Noto Sans Lao',
    'NotoSansMalayalam-Variable.ttf': 'Noto Sans Malayalam',
    'NotoSansMyanmar-Variable.ttf': 'Noto Sans Myanmar',
    'NotoSansOriya-Variable.ttf': 'Noto Sans Oriya',
    'NotoSansSC-Bold.ttf': 'Noto Sans SC',
    'NotoSansSinhala-Variable.ttf': 'Noto Sans Sinhala',
    'NotoSansTamil-Variable.ttf': 'Noto Sans Tamil',
    'NotoSansTC-Bold.ttf': 'Noto Sans TC',
    'NotoSansTelugu-Variable.ttf': 'Noto Sans Telugu',
    'NotoSansThai-Variable.ttf': 'Noto Sans Thai',
    'Nunito-Variable.ttf': 'Nunito',
    'Orbitron-Variable.ttf': 'Orbitron',
    'Oswald-Variable.ttf': 'Oswald',
    'Outfit-Variable.ttf': 'Outfit',
    'Pacifico-Regular.ttf': 'Pacifico',
    'PlayfairDisplay-Variable.ttf': 'Playfair Display',
    'Poppins-Bold.ttf': 'Poppins',
    'Poppins-ExtraBold.ttf': 'Poppins',
    'PressStart2P-Regular.ttf': 'Press Start 2P',
    'Raleway-Variable.ttf': 'Raleway',
    'Righteous-Regular.ttf': 'Righteous',
    'RubikGlitch-Regular.ttf': 'Rubik Glitch',
    'SpaceGrotesk-Variable.ttf': 'Space Grotesk',
    'Urbanist-Variable.ttf': 'Urbanist',
  };

  Future<void> _prepareFonts() async {
    if (_fontsPrepared) {
      return;
    }
    final customPath = _getSafeAppDirsFonts();
    final destPath = _getSafeFontsDir();
    if (customPath == null || destPath == null) {
      LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'AppDirs or AssetPathService not initialized. Skipping font preparation.');
      return;
    }
    try {
      final destFontsDir = Directory(destPath);
      if (!destFontsDir.existsSync()) {
        await destFontsDir.create(recursive: true);
      }

      // Copy LICENSE.txt
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          final byteData = await rootBundle.load('assets/fonts/LICENSE.txt');
          final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
          final licenseFile = File(p.join(destFontsDir.path, 'LICENSE.txt'));
          await licenseFile.writeAsBytes(bytes);
          LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Copied LICENSE.txt to FFmpeg fonts directory.');
        } catch (e) {
          LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter', 'Failed to copy LICENSE.txt: $e');
        }

        // Copy bundled fonts to their structured subdirectories on mobile
        final allAssets = [
          ..._bundledFontAssets,
          'NotoColorEmoji.ttf',
        ];
        for (final fontName in allAssets) {
          String assetSubpath;
          if (fontName == 'NotoColorEmoji.ttf') {
            assetSubpath = 'emoji';
          } else if (fontName.startsWith('Noto')) {
            assetSubpath = 'languages';
          } else {
            assetSubpath = 'design';
          }

          final targetFolder = Directory(p.join(destFontsDir.path, assetSubpath));
          if (!targetFolder.existsSync()) {
            await targetFolder.create(recursive: true);
          }

          final destFile = File(p.join(targetFolder.path, fontName));
          if (!destFile.existsSync()) {
            try {
              final byteData = await rootBundle.load('assets/fonts/$assetSubpath/$fontName');
              final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
              await destFile.writeAsBytes(bytes);
              LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Copied bundled asset font $fontName to assets/fonts/$assetSubpath.');
            } catch (e) {
              LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter', 'Failed to copy bundled asset font $fontName: $e');
            }
          }
        }
      } else {
        // Desktop fallback: copy organized directories directly from app package/bundle
        final bundledPaths = [
          p.join(Directory.current.path, 'assets', 'fonts'),
          p.join(Directory.current.path, 'Capstudio Flutter', 'assets', 'fonts'),
          p.join(Directory.current.path, 'data', 'flutter_assets', 'assets', 'fonts'),
        ];
        
        for (final path in bundledPaths) {
          final dir = Directory(path);
          if (dir.existsSync()) {
            LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Found bundled fonts directory: $path');
            
            // Copy LICENSE.txt
            final licenseSource = File(p.join(dir.path, 'LICENSE.txt'));
            if (licenseSource.existsSync()) {
              final licenseDest = File(p.join(destFontsDir.path, 'LICENSE.txt'));
              await licenseSource.copy(licenseDest.path);
            }

            final subdirs = ['design', 'languages', 'emoji'];
            for (final subdir in subdirs) {
              final subFolder = Directory(p.join(dir.path, subdir));
              if (subFolder.existsSync()) {
                final targetSubfolder = Directory(p.join(destFontsDir.path, subdir));
                if (!targetSubfolder.existsSync()) {
                  await targetSubfolder.create(recursive: true);
                }

                await for (final entity in subFolder.list()) {
                  if (entity is File) {
                    final ext = p.extension(entity.path).toLowerCase();
                    if (ext == '.ttf' || ext == '.otf') {
                      final destFile = File(p.join(targetSubfolder.path, p.basename(entity.path)));
                      if (!destFile.existsSync()) {
                        await entity.copy(destFile.path);
                        LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Copied bundled font ${p.basename(entity.path)} to assets/fonts/$subdir.');
                      }
                    }
                  }
                }
              }
            }
            break; // Stop after finding the first valid folder
          }
        }
      }
      _fontsPrepared = true;
    } catch (e, stack) {
      LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter', 'Failed to copy fonts to assets/fonts: $e', stackTrace: stack);
    }
  }

  // Dynamic flat font creation and aliasing for FFmpeg
  Future<String> _prepareTempFontsDir(String tempDir) async {
    final tempFontsDir = Directory(p.join(tempDir, 'ffmpeg_fonts'));
    if (tempFontsDir.existsSync()) {
      try {
        tempFontsDir.deleteSync(recursive: true);
      } catch (_) {}
    }
    await tempFontsDir.create(recursive: true);

    final destPath = _getSafeFontsDir();
    final customPath = _getSafeAppDirsFonts();

    Future<void> createAlias(File file, String baseName) async {
      final meta = await FontMetadataReader.readMetadata(file);
      final familyName = meta?.familyName ?? _fontFileToFamily[baseName];
      if (familyName != null) {
        final ext = p.extension(baseName);
        final aliasFile = File(p.join(tempFontsDir.path, '$familyName$ext'));
        if (!aliasFile.existsSync()) {
          await file.copy(aliasFile.path);
        }
        final postScript = meta?.postScriptName;
        if (postScript != null && postScript != familyName) {
          final psFile = File(p.join(tempFontsDir.path, '$postScript$ext'));
          if (!psFile.existsSync()) {
            await file.copy(psFile.path);
          }
        }
      }
    }

    Future<void> copyFontsFromDir(Directory dir) async {
      if (!dir.existsSync()) return;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.ttf' || ext == '.otf') {
            final filename = p.basename(entity.path);
            if (filename == 'NotoColorEmoji.ttf') {
              continue; // Skip large color emoji font to prevent metadata warnings and save memory
            }
            final destFile = File(p.join(tempFontsDir.path, filename));
            if (!destFile.existsSync()) {
              await entity.copy(destFile.path);
            }
            await createAlias(destFile, filename);
          }
        }
      }
    }

    if (destPath != null) {
      await copyFontsFromDir(Directory(destPath));
    }
    if (customPath != null) {
      final customSubdir = Directory(p.join(customPath, 'Custom'));
      await copyFontsFromDir(customSubdir);
    }

    return tempFontsDir.path;
  }

  /// Execute FFmpeg in a background process to burn subtitles into output video
  Stream<ExportProgress> exportVideo({
    required Project project,
    required List<Chunk> chunks,
    required String outputFilePath,
    required String tempDir,
  }) async* {
    await _prepareFonts();
    final tempFontsPath = await _prepareTempFontsDir(tempDir);
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

  String _buildFilterComplexSlow({
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
    await _collectEmojiAndSfx(trimmedChunks, project.config.emojiPack, validEmojiWords, sfxItems, tempDir);

    // Pre-decode all animated emojis into the synchronous cache
    for (final item in validEmojiWords) {
      if (await _isAnimatedFile(item.$2)) {
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

      final filterComplex = _buildFilterComplexSlow(
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

  Future<void> _collectEmojiAndSfx(
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
                final tempPngPath = await _renderEmojiToTempPng(glyph, tempDir, activePack: activePack);
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

  Future<String> _renderEmojiToTempPng(String glyph, String tempDir, {String? activePack}) async {
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

  String _buildFilterComplex({
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

      final lines = _splitWordsIntoLines(
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
    final escapedAssPath = _escapeAssPath(assPath);
    final fontsDir = tempFontsDir ?? _getSafeFontsDir();
    if (fontsDir != null) {
      final escapedFontsDir = _escapeAssPath(fontsDir);
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
    // converted emoji PNGs) are always cleaned up, even if _collectEmojiAndSfx,
    // _convertToPngOnMobile, or _buildFilterComplex throws partway through.
    // This mirrors the guarantee _exportVideoDesktop already had — previously
    // only the desktop path cleaned up reliably on exception; mobile leaked.
    // success/temporaryConvertedFiles are declared here (outside the try) so
    // both the finally block and the post-try yield can see them.
    bool success = false;
    final List<String> temporaryConvertedFiles = [];

    try {
      final List<(WordSchema, String)> validEmojiWords = [];
      final List<SfxExportItem> sfxItems = [];
      await _collectEmojiAndSfx(trimmedChunks, project.config.emojiPack, validEmojiWords, sfxItems, tempDir);
      LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Found ${validEmojiWords.length} emojis and ${sfxItems.length} sound effects to mix.');

      // On mobile, FFmpeg's decoder does not support animated WebP.
      // We convert WebP emojis to static PNGs using Flutter's native image decoder.
      final List<(WordSchema, String)> processedEmojiWords = [];
      for (final item in validEmojiWords) {
        final processedPath = await _convertToPngOnMobile(item.$2, tempDir);
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
        final isAnimated = await _isAnimatedFile(item.$2);
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

      final filterComplex = _buildFilterComplex(
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

  Future<String> _convertToPngOnMobile(String filePath, String tempDir) async {
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
      await _collectEmojiAndSfx(trimmedChunks, project.config.emojiPack, validEmojiWords, sfxItems, tempDir);
      LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Found ${validEmojiWords.length} emojis and ${sfxItems.length} sound effects to mix.');

      final List<String> baseArgs = ['-y', '-i', project.videoPath];
      for (final item in validEmojiWords) {
        final path = item.$2.toLowerCase();
        final isAnimated = await _isAnimatedFile(item.$2);
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

      final filterComplex = _buildFilterComplex(
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

  Future<bool> _isAnimatedFile(String filePath) async {
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


