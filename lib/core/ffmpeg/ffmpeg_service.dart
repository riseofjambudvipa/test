import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:ffmpeg_kit_flutter_new/statistics.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import '../assets/asset_path_service.dart';
import '../logger/logger_service.dart';

/// Cross-platform FFmpeg bridge.
/// Desktop: delegates to FfmpegExporter which uses Process.start(ffmpegCliPath)
/// Mobile: uses ffmpeg_kit_flutter_new (bundled native library)
class FfmpegService {
  FfmpegService._();
  static final FfmpegService instance = FfmpegService._();

  static bool get isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Execute an FFmpeg command string.
  /// On desktop: NOT USED (FfmpegExporter handles desktop directly)
  /// On mobile: executes via ffmpeg_kit_flutter bundled library
  @Deprecated('Use executeWithArguments() instead to prevent command injection vulnerabilities')
  Future<bool> execute(
    String command, {
    void Function(double progress)? onProgress,
    double? totalDurationSec,
  }) async {
    if (!isMobile) {
      throw UnsupportedError('FfmpegService.execute() is for mobile only. Desktop uses Process.start().');
    }

    LoggerService.instance.log(LogLevel.info, 'FfmpegService', 'Executing: ${_redactPath(command)}');

    FFmpegSession? session;

    if (onProgress != null && totalDurationSec != null && totalDurationSec > 0) {
      session = await FFmpegKit.executeAsync(
        command,
        null,
        null,
        (Statistics stats) {
          // Parse time from statistics
          final timeMs = stats.getTime();
          if (timeMs > 0) {
            final progress = (timeMs / 1000.0) / totalDurationSec;
            onProgress(progress.clamp(0.0, 1.0));
          }
        },
      );
      // Wait for completion
      await session.getReturnCode();
    } else {
      session = await FFmpegKit.execute(command);
    }

    final returnCode = await session.getReturnCode();
    final success = ReturnCode.isSuccess(returnCode);

    if (!success) {
      final output = await session.getOutput();
      LoggerService.instance.log(
        LogLevel.error,
        'FfmpegService',
        'FFmpeg failed. Output: $output',
      );
    }

    return success;
  }

  /// Execute FFmpeg with argument list (safer — no shell injection)
  Future<bool> executeWithArguments(
    List<String> args, {
    void Function(double progress)? onProgress,
    double? totalDurationSec,
  }) async {
    if (!isMobile) {
      throw UnsupportedError('FfmpegService.executeWithArguments() is for mobile only.');
    }

    final redactedArgs = args.map((a) => _redactPath(a)).join(" ");
    LoggerService.instance.log(LogLevel.info, 'FfmpegService', 'Executing with args: $redactedArgs');

    FFmpegSession? session;

    if (onProgress != null && totalDurationSec != null && totalDurationSec > 0) {
      session = await FFmpegKit.executeWithArgumentsAsync(
        args,
        null,
        null,
        (Statistics stats) {
          final timeMs = stats.getTime();
          if (timeMs > 0) {
            final progress = (timeMs / 1000.0) / totalDurationSec;
            onProgress(progress.clamp(0.0, 1.0));
          }
        },
      );
      await session.getReturnCode();
    } else {
      session = await FFmpegKit.executeWithArguments(args);
    }

    final returnCode = await session.getReturnCode();
    final success = ReturnCode.isSuccess(returnCode);

    if (!success) {
      final output = await session.getOutput();
      LoggerService.instance.log(
        LogLevel.error,
        'FfmpegService',
        'FFmpeg failed. Output: $output',
      );
    }

    return success;
  }

  /// Probe video file metadata — returns {duration, width, height, rotation}
  Future<Map<String, dynamic>> probeVideo(String videoPath) async {
    if (!isMobile) {
      throw UnsupportedError('FfmpegService.probeVideo() is for mobile only.');
    }

    final session = await FFprobeKit.getMediaInformation(videoPath);
    final info = session.getMediaInformation();

    if (info == null) {
      throw Exception('ffprobe returned no information for: $videoPath');
    }

    final streams = info.getStreams();
    int width = 0, height = 0;
    double duration = 0.0;
    int rotation = 0;

    for (final stream in streams) {
      final codecType = stream.getType();
      if (codecType == 'video') {
        width = stream.getWidth() ?? 0;
        height = stream.getHeight() ?? 0;
        // Inspect both Display Matrix side data and the rotation tag (mirroring video_probe.dart)
        final allProps = stream.getAllProperties();
        if (allProps != null) {
          final sideDataList = allProps['side_data_list'];
          if (sideDataList is List) {
            for (final sideData in sideDataList) {
              if (sideData is Map &&
                  sideData['side_data_type'] == 'Display Matrix' &&
                  sideData['rotation'] != null) {
                final rotVal = sideData['rotation'];
                if (rotVal is num) {
                  rotation = rotVal.toInt();
                } else {
                  rotation = int.tryParse(rotVal.toString()) ?? rotation;
                }
                break;
              }
            }
          }

          final tags = allProps['tags'];
          if (tags is Map && tags['rotate'] != null) {
            rotation = int.tryParse(tags['rotate'].toString()) ?? rotation;
          }
        }
      }
    }

    // Parse duration from format
    final durationStr = info.getDuration();
    if (durationStr != null) {
      duration = double.tryParse(durationStr) ?? 0.0;
    }

    // Apply rotation correction (portrait videos)
    if (rotation == 90 || rotation == -90 || rotation == 270 || rotation == -270) {
      final tmp = width;
      width = height;
      height = tmp;
    }

    return {
      'duration': duration,
      'width': width,
      'height': height,
      'rotation': rotation,
    };
  }

  /// Extract 16kHz mono WAV for Whisper transcription
  Future<String> extractAudioForWhisper(String videoPath, String outputWavPath) async {
    if (!isMobile) {
      throw UnsupportedError('Use WhisperService.extractAudio() on desktop.');
    }

    final success = await executeWithArguments([
      '-y',
      '-i', videoPath,
      '-vn',
      '-ac', '1',
      '-ar', '16000',
      '-acodec', 'pcm_s16le',
      outputWavPath,
    ]);

    if (!success) {
      throw Exception('Audio extraction failed for: $videoPath');
    }

    return outputWavPath;
  }

  /// Extract audio waveform amplitudes for timeline visualization
  Future<List<double>> extractWaveform(String videoPath, int sampleCount) async {
    if (!isMobile) {
      throw UnsupportedError('Use WaveformService on desktop.');
    }

    final uuid = const Uuid().v4();
    final tempWav = p.join(AssetPathService.instance.tempDir, 'waveform_$uuid.wav');

    try {
      final success = await executeWithArguments([
        '-y',
        '-i', videoPath,
        '-vn',
        '-ac', '1',
        '-ar', '8000',
        '-acodec', 'pcm_s16le',
        tempWav,
      ]);

      if (!success || !File(tempWav).existsSync()) {
        return _fallbackWaveform(sampleCount);
      }

      // Dynamic RIFF chunk parser
      final bytes = await File(tempWav).readAsBytes();
      if (bytes.length < 44) return _fallbackWaveform(sampleCount);

      // Check RIFF and WAVE signatures
      if (bytes[0] != 82 || bytes[1] != 73 || bytes[2] != 70 || bytes[3] != 70 ||
          bytes[8] != 87 || bytes[9] != 65 || bytes[10] != 86 || bytes[11] != 69) {
        return _fallbackWaveform(sampleCount);
      }

      int dataOffset = 12;
      int dataSize = 0;

      while (dataOffset + 8 <= bytes.length) {
        final chunkId = String.fromCharCodes(bytes.sublist(dataOffset, dataOffset + 4));
        final chunkSize = bytes[dataOffset + 4] | (bytes[dataOffset + 5] << 8) | (bytes[dataOffset + 6] << 16) | (bytes[dataOffset + 7] << 24);

        if (chunkId == 'data') {
          dataOffset += 8;
          dataSize = chunkSize;
          break;
        }

        dataOffset += 8 + chunkSize;
      }

      if (dataSize == 0 || dataOffset >= bytes.length) {
        return _fallbackWaveform(sampleCount);
      }

      final pcmBytesLength = math.min(dataSize, bytes.length - dataOffset);
      final pcmBytes = bytes.sublist(dataOffset, dataOffset + pcmBytesLength);
      final totalSamples = pcmBytes.length ~/ 2;
      final chunkSize = (totalSamples / sampleCount).ceil().clamp(1, totalSamples);

      final amplitudes = <double>[];
      for (int i = 0; i < sampleCount; i++) {
        final start = i * chunkSize * 2;
        if (start >= pcmBytes.length) {
          amplitudes.add(0.0);
          continue;
        }
        final end = ((start + chunkSize * 2)).clamp(0, pcmBytes.length);
        double sumSquares = 0;
        int count = 0;
        for (int j = start; j < end - 1; j += 2) {
          final sample = (pcmBytes[j] | (pcmBytes[j + 1] << 8)).toSigned(16);
          sumSquares += sample * sample;
          count++;
        }
        // RMS = sqrt(mean(squares)). Dividing by 32768.0 normalizes the amplitude to [0.0, 1.0].
        final double rms = count > 0 ? math.sqrt(sumSquares / count) / 32768.0 : 0.0;
        amplitudes.add(rms);
      }

      // Normalize
      final maxAmp = amplitudes.reduce((a, b) => a > b ? a : b);
      if (maxAmp > 0) {
        return amplitudes.map((a) => (a / maxAmp).clamp(0.0, 1.0)).toList();
      }
      return amplitudes;
    } finally {
      try {
        if (File(tempWav).existsSync()) await File(tempWav).delete();
      } catch (e) {
        LoggerService.instance.debug('Failed to delete tempWav in ffmpeg_service: $e');
      }
    }
  }

  /// Generate video thumbnail (first frame at 1 second)
  Future<String?> generateThumbnail(String videoPath, String outputJpgPath) async {
    if (!isMobile) {
      throw UnsupportedError('Use Process.run on desktop.');
    }

    final success = await executeWithArguments([
      '-y',
      '-i', videoPath,
      '-ss', '00:00:01',
      '-vframes', '1',
      '-vf', 'scale=320:-1',
      '-q:v', '5',
      outputJpgPath,
    ]);

    return success ? outputJpgPath : null;
  }

  List<double> _fallbackWaveform(int count) {
    return List.generate(count, (_) => 0.2);
  }

  String _redactPath(String path) {
    if (kIsWeb) return path;
    return LoggerService.instance.scrubPii(path);
  }
}
