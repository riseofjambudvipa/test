import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path/path.dart' as p;
import '../assets/asset_path_service.dart';
import '../ffmpeg/ffmpeg_service.dart';
import '../logger/logger_service.dart';
import '../utils/app_dirs.dart';
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

  String? _getDiskCacheDir() {
    if (kIsWeb) return null;
    try {
      return p.join(AppDirs.support, 'waveform_cache');
    } catch (_) {
      try {
        return p.join(AssetPathService.instance.tempDir, 'waveform_cache');
      } catch (_) {
        return p.join(Directory.systemTemp.path, 'capstudio_waveform_cache');
      }
    }
  }

  String? _cacheFilePath(String key) {
    final dir = _getDiskCacheDir();
    if (dir == null) return null;
    final hash = sha256.convert(utf8.encode(key)).toString();
    return p.join(dir, '$hash.wf');
  }

  List<double>? _readFromDiskSync(String key) {
    if (kIsWeb) return null;
    try {
      final filePath = _cacheFilePath(key);
      if (filePath == null) return null;
      final file = File(filePath);
      if (!file.existsSync()) return null;

      final bytes = file.readAsBytesSync();
      if (bytes.isEmpty || bytes.lengthInBytes % 4 != 0) return null;

      final byteData = ByteData.sublistView(bytes);
      final count = bytes.lengthInBytes ~/ 4;
      return List<double>.generate(
        count,
        (i) => byteData.getFloat32(i * 4, Endian.little),
      );
    } catch (e) {
      LoggerService.instance.log(
        LogLevel.debug,
        'WaveformService',
        'Disk cache read failed for key $key: $e',
      );
      return null;
    }
  }

  Future<void> _writeToDiskAsync(String key, List<double> value) async {
    if (kIsWeb || value.isEmpty) return;
    try {
      final filePath = _cacheFilePath(key);
      if (filePath == null) return;
      final file = File(filePath);
      if (!file.parent.existsSync()) {
        file.parent.createSync(recursive: true);
      }

      final byteData = ByteData(value.length * 4);
      for (int i = 0; i < value.length; i++) {
        byteData.setFloat32(i * 4, value[i], Endian.little);
      }
      final bytes = byteData.buffer.asUint8List();
      await file.writeAsBytes(bytes, flush: false);
    } catch (e) {
      LoggerService.instance.log(
        LogLevel.debug,
        'WaveformService',
        'Disk cache write failed for key $key: $e',
      );
    }
  }

  List<double>? _readFromCache(String key) {
    // 1. In-memory LRU cache
    if (_cache.containsKey(key)) {
      final value = _cache.remove(key); // Remove and re-insert to mark as recently used
      _cache[key] = value!;
      return value;
    }

    // 2. Disk cache fallback
    final diskCached = _readFromDiskSync(key);
    if (diskCached != null) {
      _cache[key] = diskCached;
      if (_cache.length > _maxCacheSize) {
        _cache.remove(_cache.keys.first);
      }
      return diskCached;
    }

    return null;
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

    // Persist to disk in background
    unawaited(_writeToDiskAsync(key, value));
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
      // FIX (audit): the mobile branch previously had no error handling — any
      // exception escaped uncaught and the caller got no waveform at all.
      // Fall back to a flat waveform instead.
      try {
        final amplitudes = await FfmpegService.instance.extractWaveform(videoPath, sampleCount);
        _writeToCache(cacheKey, amplitudes);
        return amplitudes;
      } catch (e, stackTrace) {
        LoggerService.instance.log(LogLevel.error, 'WaveformService',
            'Mobile waveform extraction failed: $e', stackTrace: stackTrace);
        final fb = _fallbackWaveform(sampleCount);
        _writeToCache(cacheKey, fb);
        return fb;
      }
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
      // FIX (audit): locate the PCM data chunk instead of assuming a fixed
      // 44-byte header — some encoders emit extended fmt chunks (74/78-byte
      // headers), which previously misaligned sample decoding.
      int headerSize = 44;
      final searchLimit = math.min(bytes.length - 8, 4096);
      for (int i = 12; i < searchLimit; i++) {
        if (bytes[i] == 0x64 && bytes[i + 1] == 0x61 && // 'da'
            bytes[i + 2] == 0x74 && bytes[i + 3] == 0x61) { // 'ta'
          headerSize = i + 8;
          break;
        }
      }
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

  void clearCache() {
    _cache.clear();
    if (kIsWeb) return;
    try {
      final dirPath = _getDiskCacheDir();
      if (dirPath != null) {
        final dir = Directory(dirPath);
        if (dir.existsSync()) {
          for (final entity in dir.listSync()) {
            try {
              if (entity is File) {
                entity.deleteSync();
              }
            } catch (e) {
              LoggerService.instance.log(LogLevel.error, 'WaveformService', 'Failed to delete file: $e');
            }
          }
        }
      }
    } catch (e) {
      LoggerService.instance.log(
        LogLevel.debug,
        'WaveformService',
        'Failed to clear disk waveform cache: $e',
      );
    }
  }
}
