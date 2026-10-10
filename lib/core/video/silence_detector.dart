import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../database/schemas/word.dart';
import '../ffmpeg/ffmpeg_locator.dart';
import 'viral_clip_models.dart';
import '../logger/logger_service.dart';

class SilenceDetector {
  /// Detects silence intervals using transcript word boundaries (instant, cross-platform)
  /// or native FFmpeg silencedetect audio filter when executed on desktop/server.
  Future<List<SilenceSegment>> detectSilence({
    required String videoPath,
    String? ffmpegPath,
    double noiseThreshold = -35.0,
    double durationThreshold = 0.25,
    List<WordSchema>? words,
    double totalDuration = 0.0,
  }) async {
    LoggerService.instance.log(LogLevel.info, 'SilenceDetector', 'Starting silence detection on $videoPath');

    // On Web or when transcribed words are available, use instant high-precision word timing analysis
    if (kIsWeb || (words != null && words.isNotEmpty)) {
      if (words != null && words.isNotEmpty) {
        return detectSilenceFromWords(
          words,
          totalDuration: totalDuration,
          durationThreshold: durationThreshold,
        );
      }
      return [];
    }

    try {
      final resolvedFfmpeg = ffmpegPath ?? FfmpegLocator.instance.resolve();
      final result = await Process.run(resolvedFfmpeg, [
        '-i',
        videoPath,
        '-af',
        'silencedetect=noise=${noiseThreshold}dB:d=$durationThreshold',
        '-f',
        'null',
        '-'
      ]);

      final String output = result.stderr as String; // FFmpeg writes to stderr
      final lines = output.split('\n');

      final List<SilenceSegment> segments = [];
      double? currentStart;

      for (final line in lines) {
        if (line.contains('silence_start:')) {
          final match = RegExp(r'silence_start:\s+([\d\.]+)').firstMatch(line);
          if (match != null) {
            currentStart = double.tryParse(match.group(1) ?? '');
          }
        } else if (line.contains('silence_end:') && currentStart != null) {
          final matchEnd = RegExp(r'silence_end:\s+([\d\.]+)').firstMatch(line);
          final matchDuration = RegExp(r'silence_duration:\s+([\d\.]+)').firstMatch(line);
          if (matchEnd != null && matchDuration != null) {
            final end = double.tryParse(matchEnd.group(1) ?? '') ?? 0.0;
            final duration = double.tryParse(matchDuration.group(1) ?? '') ?? 0.0;
            segments.add(SilenceSegment(
              start: currentStart,
              end: end,
              duration: duration,
            ));
          }
          currentStart = null;
        }
      }

      LoggerService.instance.log(LogLevel.info, 'SilenceDetector', 'Detected ${segments.length} silence segments via FFmpeg');
      return segments;
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'SilenceDetector', 'FFmpeg silence detection failed ($e), falling back to words if available');
      if (words != null && words.isNotEmpty) {
        return detectSilenceFromWords(words, totalDuration: totalDuration, durationThreshold: durationThreshold);
      }
      return [];
    }
  }

  /// Calculates silence intervals from word timestamps.
  List<SilenceSegment> detectSilenceFromWords(
    List<WordSchema> words, {
    double totalDuration = 0.0,
    double durationThreshold = 0.25,
  }) {
    if (words.isEmpty) return [];

    final validWords = words
        .where((w) => w.start != null && w.end != null && (w.hidden != true))
        .toList()
      ..sort((a, b) => a.start!.compareTo(b.start!));

    if (validWords.isEmpty) return [];

    final List<SilenceSegment> segments = [];

    // 1. Check leading pause before first word
    final firstStart = validWords.first.start!;
    if (firstStart >= durationThreshold) {
      segments.add(SilenceSegment(
        start: 0.0,
        end: firstStart,
        duration: firstStart,
      ));
    }

    // 2. Check pauses between consecutive words
    for (int i = 0; i < validWords.length - 1; i++) {
      final currentEnd = validWords[i].end!;
      final nextStart = validWords[i + 1].start!;
      final gap = nextStart - currentEnd;
      if (gap >= durationThreshold) {
        segments.add(SilenceSegment(
          start: currentEnd,
          end: nextStart,
          duration: gap,
        ));
      }
    }

    // 3. Check trailing silence after last word
    final effectiveTotal = totalDuration > 0
        ? totalDuration
        : (validWords.last.end ?? 0.0);
    final lastEnd = validWords.last.end!;
    if (effectiveTotal > lastEnd && (effectiveTotal - lastEnd) >= durationThreshold) {
      segments.add(SilenceSegment(
        start: lastEnd,
        end: effectiveTotal,
        duration: effectiveTotal - lastEnd,
      ));
    }

    LoggerService.instance.log(LogLevel.info, 'SilenceDetector', 'Detected ${segments.length} silence segments via word timings');
    return segments;
  }

  List<SilenceSegment> generateActiveSegments({
    required List<SilenceSegment> silenceSegments,
    required double totalDuration,
  }) {
    if (totalDuration <= 0.0) return [];
    final List<SilenceSegment> activeSegments = [];
    double currentPos = 0.0;

    for (final silence in silenceSegments) {
      if (currentPos >= totalDuration) break;
      final silenceStart = math.min(silence.start, totalDuration);
      if (silenceStart > currentPos) {
        activeSegments.add(SilenceSegment(
          start: currentPos,
          end: silenceStart,
          duration: silenceStart - currentPos,
        ));
      }
      currentPos = math.min(silence.end, totalDuration);
    }

    if (currentPos < totalDuration) {
      activeSegments.add(SilenceSegment(
        start: currentPos,
        end: totalDuration,
        duration: totalDuration - currentPos,
      ));
    }

    return activeSegments;
  }
}
