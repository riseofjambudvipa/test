import 'dart:convert';
import 'dart:io';
import '../ffmpeg/ffmpeg_locator.dart';

/// Parsed video metadata from ffprobe.
class VideoMetadata {
  final double duration;
  final int width;
  final int height;
  final int rotation;
  final bool hasAudio;

  const VideoMetadata({
    this.duration = 60.0,
    this.width = 1920,
    this.height = 1080,
    this.rotation = 0,
    this.hasAudio = true,
  });
}

/// Probes [videoPath] with ffprobe and parses duration, dimensions,
/// rotation, and audio presence from a single JSON call.
///
/// Returns `null` on any failure (non-zero exit, malformed output) so
/// callers can apply their own fallbacks. A [ProcessException] (e.g. the
/// binary is missing) is rethrown so callers can surface a useful message.
/// [processRunner] is an optional mockable process runner (used by tests);
/// when omitted a real [Process.run] is used.
Future<VideoMetadata?> probeVideoMetadata({
  required String videoPath,
  String? ffprobePath,
  String? ffmpegPath,
  Future<ProcessResult> Function(String executable, List<String> arguments)?
      processRunner,
}) async {
  final List<String> args = [
    '-v',
    'error',
    '-show_entries',
    'stream=codec_type,width,height:stream_side_data=rotation:stream_tags=rotate:format=duration',
    '-of',
    'json',
    videoPath,
  ];

  String resolvedProbe = ffprobePath ?? 'ffprobe';
  if (resolvedProbe.toLowerCase().contains('ffmpeg')) {
    resolvedProbe = FfmpegLocator.instance.resolveFfprobe();
  }

  try {
    final ProcessResult process = processRunner != null
        ? await processRunner(resolvedProbe, args)
        : await Process.run(resolvedProbe, args);

    if (process.exitCode == 0) {
      final Map<String, dynamic> data =
          jsonDecode(process.stdout.toString()) as Map<String, dynamic>;
      final streams = data['streams'] as List<dynamic>?;
      final format = data['format'] as Map<String, dynamic>?;

      double duration = 0.0;
      if (format != null && format['duration'] != null) {
        duration = double.tryParse(format['duration'].toString()) ?? 0.0;
      }

      int width = 1920;
      int height = 1080;
      int rotation = 0;
      bool hasAudio = true;

      if (streams != null && streams.isNotEmpty) {
        final videoStream = streams.firstWhere(
          (s) => s['codec_type'] == null || s['codec_type'] == 'video',
          orElse: () => streams.first,
        );
        width = videoStream['width'] as int? ?? 1920;
        height = videoStream['height'] as int? ?? 1080;

        final sideDataList = videoStream['side_data_list'] as List<dynamic>?;
        if (sideDataList != null) {
          for (final sideData in sideDataList) {
            if (sideData['side_data_type'] == 'Display Matrix' &&
                sideData['rotation'] != null) {
              rotation = (sideData['rotation'] as num).toInt();
              break;
            }
          }
        }

        final tags = videoStream['tags'] as Map<String, dynamic>?;
        if (tags != null && tags['rotate'] != null) {
          rotation = int.tryParse(tags['rotate'].toString()) ?? rotation;
        }

        // Check for audio stream presence
        final hasCodecType = streams.any((s) => s is Map && s.containsKey('codec_type'));
        if (hasCodecType) {
          hasAudio = streams.any((s) => s is Map && s['codec_type'] == 'audio');
        }
      }

      // A 90/270-degree rotation means the decoded frame is in landscape, so
      // expose the display dimensions as width/height (matches legacy behavior).
      if (rotation == 90 ||
          rotation == -90 ||
          rotation == 270 ||
          rotation == -270) {
        final temp = width;
        width = height;
        height = temp;
      }

      if (duration > 0.0) {
        return VideoMetadata(
          duration: duration,
          width: width,
          height: height,
          rotation: rotation,
          hasAudio: hasAudio,
        );
      }
    }
  } on ProcessException {
    if (processRunner != null) rethrow;
  } catch (_) {
    // Fall through to FFmpeg fallback below
  }

  // Robust fallback: probe duration and resolution directly using FFmpeg -i
  return probeVideoWithFfmpeg(
    videoPath: videoPath,
    ffmpegPath: ffmpegPath,
    processRunner: processRunner,
  );
}

/// Fallback probe using FFmpeg -i to parse duration and resolution from stderr.
Future<VideoMetadata?> probeVideoWithFfmpeg({
  required String videoPath,
  String? ffmpegPath,
  Future<ProcessResult> Function(String executable, List<String> arguments)?
      processRunner,
}) async {
  try {
    final exe = (ffmpegPath != null && ffmpegPath.isNotEmpty)
        ? ffmpegPath
        : FfmpegLocator.instance.resolve();
    final ProcessResult process = processRunner != null
        ? await processRunner(exe, ['-i', videoPath])
        : await Process.run(exe, ['-i', videoPath]);

    final String output = '${process.stdout}\n${process.stderr}';
    return parseFfmpegProbeOutput(output);
  } catch (_) {
    return null;
  }
}

/// Parses FFmpeg banner output to extract duration, dimensions, rotation and audio presence.
VideoMetadata? parseFfmpegProbeOutput(String output) {
  final durMatch = RegExp(r'Duration:\s*(\d+):(\d+):([\d\.]+)').firstMatch(output);
  if (durMatch == null) return null;

  final h = int.tryParse(durMatch.group(1) ?? '0') ?? 0;
  final m = int.tryParse(durMatch.group(2) ?? '0') ?? 0;
  final s = double.tryParse(durMatch.group(3) ?? '0') ?? 0.0;
  final duration = h * 3600.0 + m * 60.0 + s;
  if (duration <= 0.0) return null;

  int width = 1920;
  int height = 1080;
  final vidMatch = RegExp(r'Stream #\d+:\d+.*?: Video: .*?,\s*(\d{2,5})x(\d{2,5})').firstMatch(output);
  if (vidMatch != null) {
    width = int.tryParse(vidMatch.group(1) ?? '1920') ?? 1920;
    height = int.tryParse(vidMatch.group(2) ?? '1080') ?? 1080;
  }

  int rotation = 0;
  final rotMatch = RegExp(r'(?:rotate|rotation)\s*:\s*(\d+)').firstMatch(output);
  if (rotMatch != null) {
    rotation = int.tryParse(rotMatch.group(1) ?? '0') ?? 0;
  }
  if (rotation == 90 || rotation == -90 || rotation == 270 || rotation == -270) {
    final temp = width;
    width = height;
    height = temp;
  }

  final hasAudio = RegExp(r'Stream #\d+:\d+.*?: Audio:').hasMatch(output);

  return VideoMetadata(
    duration: duration,
    width: width,
    height: height,
    rotation: rotation,
    hasAudio: hasAudio,
  );
}
