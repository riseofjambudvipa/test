import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path/path.dart' as p;
import '../logger/logger_service.dart';
import '../ffmpeg/ffmpeg_service.dart';
import '../assets/asset_path_service.dart';
import 'waveform_web_helper.dart';

class WaveformService {
  WaveformService._internal();
  static final WaveformService instance = WaveformService._internal();

  @visibleForTesting
  static bool bypassExtractionForTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  /// Mockable process runner for unit testing offline
  Future<ProcessResult> Function(String executable, List<String> arguments)? processRunner;

  static const int _maxCacheSize = 20;
  final Map<String, List<double>> _cache = {};

  List<double>? _readFromCache(String key) {
    if (!_cache.containsKey(key)) return null;
    final value = _cache.remove(key); // Remove and re-insert to mark as recently used
    _cache[key] = value!;
    return value;
  }

  void _writeToCache(String key, List<double> value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key); // Remove to update insertion order on re-write
    }
    _cache[key] = value;
    if (_cache.length > _maxCacheSize) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey);
    }
  }

  /// Extract real waveform amplitudes from video file using FFmpeg.
  /// Returns a list of normalized amplitude values (0.0–1.0).
  /// [sampleCount] is the number of data points.
  Future<List<double>> extractWaveform({
    required String videoPath,
    required String ffmpegPath,
    int sampleCount = 800,
  }) async {
    if (bypassExtractionForTesting) {
      return _fallbackWaveform(sampleCount);
    }
    if (kIsWeb) {
      final cacheKey = '${videoPath}_$sampleCount';
      final cached = _readFromCache(cacheKey);
      if (cached != null) return cached;

      try {
        final amplitudes = await extractWaveformWeb(videoPath, sampleCount);
        _writeToCache(cacheKey, amplitudes);
        return amplitudes;
      } catch (e, stackTrace) {
        LoggerService.instance.log(LogLevel.error, 'WaveformService', 'Web Audio API decoding failed: $e', stackTrace: stackTrace);
        final fb = _fallbackWaveform(sampleCount);
        _writeToCache(cacheKey, fb);
        return fb;
      }
    }

    final file = File(videoPath);
    final modifiedMs = file.existsSync()
        ? file.lastModifiedSync().millisecondsSinceEpoch
        : 0;
    final cacheKey = '${videoPath}_${sampleCount}_$modifiedMs';
    
    final cached = _readFromCache(cacheKey);
    if (cached != null) return cached;


    if (Platform.isAndroid || Platform.isIOS) {
      final amplitudes = await FfmpegService.instance.extractWaveform(videoPath, sampleCount);
      _writeToCache(cacheKey, amplitudes);
      return amplitudes;
    }

    String? wavPath;
    try {
      final tempDir = AssetPathService.instance.tempDir;
      final uniqueId = '${DateTime.now().microsecondsSinceEpoch}_${math.Random().nextInt(100000)}';
      wavPath = p.join(tempDir, 'waveform_${uniqueId}_${p.basenameWithoutExtension(videoPath)}.wav');

      // Extract low-quality mono audio for analysis only (1 channel, 8000Hz, s16le PCM format)
      final extractResult = processRunner != null
          ? await processRunner!(ffmpegPath, [
              '-y', '-i', videoPath,
              '-vn', '-ac', '1', '-ar', '8000',
              '-acodec', 'pcm_s16le', wavPath,
            ])
          : await Process.run(ffmpegPath, [
              '-y', '-i', videoPath,
              '-vn', '-ac', '1', '-ar', '8000',
              '-acodec', 'pcm_s16le', wavPath,
            ]);

      if (extractResult.exitCode != 0) {
        LoggerService.instance.log(LogLevel.warning, 'WaveformService', 'FFmpeg audio extraction failed with exit code ${extractResult.exitCode}. Falling back to flat waveform.');
        final fb = _fallbackWaveform(sampleCount);
        _writeToCache(cacheKey, fb);
        return fb;
      }

      final wavFile = File(wavPath);
      if (!wavFile.existsSync()) {
        LoggerService.instance.log(LogLevel.warning, 'WaveformService', 'Extracted wav file not found on disk. Falling back.');
        final fb = _fallbackWaveform(sampleCount);
        _writeToCache(cacheKey, fb);
        return fb;
      }

      final bytes = await wavFile.readAsBytes();
      // PCM s16le WAV: skip 44-byte standard header, then pairs of bytes = int16 samples
      const headerSize = 44;
      if (bytes.length <= headerSize) {
        final fb = _fallbackWaveform(sampleCount);
        _writeToCache(cacheKey, fb);
        return fb;
      }

      final totalSamples = (bytes.length - headerSize) ~/ 2;
      if (totalSamples <= 0) {
        final fb = _fallbackWaveform(sampleCount);
        _writeToCache(cacheKey, fb);
        return fb;
      }

      // Use a direct view over the raw byte buffer to avoid memory copies and manual sign extraction loops.
      // Safe approach: sublist first to guarantee own buffer, ensuring alignment
      final pcmBytes = bytes.sublist(headerSize);
      final int16Data = Int16List.view(pcmBytes.buffer, pcmBytes.offsetInBytes, totalSamples);

      final safeSampleCount = sampleCount.clamp(1, totalSamples);
      final chunkSize = totalSamples ~/ safeSampleCount;

      final amplitudes = <double>[];
      for (int i = 0; i < sampleCount; i++) {
        double sumSquares = 0;
        final start = i * chunkSize;
        if (start >= totalSamples) {
          amplitudes.add(0.0);
          continue;
        }
        final end = math.min(start + chunkSize, totalSamples);
        int count = 0;
        for (int j = start; j < end; j++) {
          final double signed = int16Data[j].toDouble();
          sumSquares += signed * signed;
          count++;
        }
        final rms = count > 0 ? math.sqrt(sumSquares / count) / 32768.0 : 0.0;
        amplitudes.add(rms.clamp(0.0, 1.0));
      }

      // Normalize to 0.0–1.0 range
      final maxAmp = amplitudes.isEmpty ? 0.0 : amplitudes.reduce(math.max);
      final normalized = maxAmp > 0
          ? amplitudes.map((a) => a / maxAmp).toList()
          : amplitudes;

      _writeToCache(cacheKey, normalized);
      return normalized;
    } catch (e, stackTrace) {
      LoggerService.instance.log(LogLevel.error, 'WaveformService', 'Error extracting real audio waveform: $e', stackTrace: stackTrace);
      final fb = _fallbackWaveform(sampleCount);
      _writeToCache(cacheKey, fb);
      return fb;
    } finally {
      if (wavPath != null) {
        try {
          final file = File(wavPath);
          if (file.existsSync()) {
            await file.delete();
          }
        } catch (e, stackTrace) {
          LoggerService.instance.log(LogLevel.warning, 'WaveformService', 'Failed to delete temporary WAV file: $e', stackTrace: stackTrace);
        }
      }
    }
  }

  List<double> _fallbackWaveform(int count) {
    // Return a slightly fluctuating baseline instead of random spikes or empty lists
    final random = math.Random(5678);
    return List.generate(count, (index) => 0.2 + random.nextDouble() * 0.15);
  }

  void clearCache() => _cache.clear();
}
