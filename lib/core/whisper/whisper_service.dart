import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import '../database/schemas/word.dart';
import '../logger/logger_service.dart';
import '../settings/settings_service.dart';
import '../ffmpeg/ffmpeg_service.dart';
import '../utils/web_wasm_bridge.dart';
import 'whisper_mobile_service.dart';
import 'whisper_ffi_stub.dart' if (dart.library.ffi) 'whisper_ffi_service.dart';

class TranscriptionResult {
  final List<WordSchema> words;
  final String language;

  const TranscriptionResult({
    required this.words,
    required this.language,
  });
}

class WhisperService {
  static const _uuid = Uuid();
  WhisperService._internal();
  static WhisperService _instance = WhisperService._internal();
  static WhisperService get instance => _instance;

  @visibleForTesting
  static set instance(WhisperService newInstance) {
    _instance = newInstance;
  }

  @visibleForTesting
  static void resetForTesting() {
    _instance = WhisperService._internal();
  }

  /// Mockable process runner for unit testing offline
  @visibleForTesting
  Future<ProcessResult> Function(
    String executable,
    List<String> arguments, {
    Encoding? stdoutEncoding,
    Encoding? stderrEncoding,
  })? processRunner;

  String? _whisperCliPath;
  String _ffmpegCliPath = 'ffmpeg';
  String? _modelPath;
  String? _cachedFfmpegPath;
  final Set<Process> _activeProcesses = {};

  String get whisperCliPath => _whisperCliPath ?? 'whisper-cli';
  String? get modelPath => _modelPath;

  /// Cancels the active transcription process if one is running
  void cancelActiveTranscription() {
    if (_activeProcesses.isNotEmpty) {
      LoggerService.instance.log(LogLevel.action, 'WhisperService', 'Killing ${_activeProcesses.length} active processes');
      for (final process in _activeProcesses) {
        try {
          process.kill();
        } catch (_) {}
      }
      _activeProcesses.clear();
    }
  }
  
  String get ffmpegCliPath {
    if (kIsWeb) {
      return 'ffmpeg';
    }
    if (_ffmpegCliPath != 'ffmpeg') {
      return _ffmpegCliPath;
    }
    if (_cachedFfmpegPath != null) {
      return _cachedFfmpegPath!;
    }
    final paths = [
      p.join(Directory.current.path, 'assets', 'bin', Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg'),
      p.join(Directory.current.path, 'Capstudio Flutter', 'assets', 'bin', Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg'),
      p.join(Directory.current.path, 'data', 'flutter_assets', 'assets', 'bin', Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg'),
    ];
    for (final path in paths) {
      if (File(path).existsSync()) {
        _cachedFfmpegPath = path;
        return path;
      }
    }
    return 'ffmpeg';
  }

  /// Configure local whisper.cpp executable path
  void configureCli(String path) {
    _whisperCliPath = path;
    LoggerService.instance.log(LogLevel.info, 'WhisperService', 'Whisper CLI path configured: $path');
  }

  /// Configure local FFmpeg executable path
  void configureFfmpeg(String path) {
    if (path.trim().isNotEmpty) {
      _ffmpegCliPath = path;
      _cachedFfmpegPath = null; // Invalidate cache
      LoggerService.instance.log(LogLevel.info, 'WhisperService', 'FFmpeg path configured: $path');
    }
  }

  /// Configure active model path (.bin file)
  void configureModel(String path) {
    _modelPath = path;
    LoggerService.instance.log(LogLevel.info, 'WhisperService', 'Model path configured: $path');
  }

  /// Extracts mono 16kHz audio from a video using local FFmpeg (desktop) or native FFmpegKit (mobile)
  Future<String> extractAudio(String videoPath, String tempDir, {String? ffmpegCliPath}) async {
    if (kIsWeb) {
      throw UnsupportedError('Audio extraction is handled via browser Web Audio API on Web.');
    }
    final videoFile = File(videoPath);
    if (!videoFile.existsSync()) {
      LoggerService.instance.log(LogLevel.error, 'WhisperService', 'Audio extraction failed: Video file not found: $videoPath');
      throw FileSystemException('Video file not found', videoPath);
    }

    final outputWavPath = p.join(tempDir, '${p.basenameWithoutExtension(videoPath)}_16k.wav');

    if (Platform.isAndroid || Platform.isIOS) {
      return FfmpegService.instance.extractAudioForWhisper(videoPath, outputWavPath);
    }

    final wavFile = File(outputWavPath);
    if (wavFile.existsSync()) {
      await wavFile.delete(); // Delete previous extraction if any
    }

    final activeFfmpegPath = ffmpegCliPath ?? this.ffmpegCliPath;
    LoggerService.instance.log(LogLevel.info, 'WhisperService', 'Starting audio extraction: $videoPath -> $outputWavPath using $activeFfmpegPath');

    final int exitCode;
    final String stderrStr;

    if (processRunner != null) {
      final res = await processRunner!(
        activeFfmpegPath,
        ['-y', '-i', videoPath, '-vn', '-ac', '1', '-ar', '16000', '-acodec', 'pcm_s16le', outputWavPath],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      exitCode = res.exitCode;
      stderrStr = res.stderr.toString();
    } else {
      final process = await Process.start(
        activeFfmpegPath,
        ['-y', '-i', videoPath, '-vn', '-ac', '1', '-ar', '16000', '-acodec', 'pcm_s16le', outputWavPath],
      );
      _activeProcesses.add(process);

      try {
        final stderrFuture = process.stderr.transform(const Utf8Decoder(allowMalformed: true)).join();
        final stdoutFuture = process.stdout.transform(const Utf8Decoder(allowMalformed: true)).join();

        exitCode = await process.exitCode;
        stderrStr = await stderrFuture;
        await stdoutFuture;
      } finally {
        _activeProcesses.remove(process);
      }
    }

    if (exitCode != 0) {
      LoggerService.instance.log(LogLevel.error, 'WhisperService', 'FFmpeg audio extraction failed. Exit code: $exitCode, Error: $stderrStr');
      throw ProcessException(activeFfmpegPath, [], 'Audio extraction failed: $stderrStr', exitCode);
    }

    LoggerService.instance.log(LogLevel.info, 'WhisperService', 'Audio extraction successful: $outputWavPath');
    return outputWavPath;
  }

  /// Run local whisper.cpp transcription on the extracted WAV file
  Future<TranscriptionResult> transcribe({
    required String wavPath,
    String? modelPath,
    String? language,
    bool? useVad,
    double? vadThreshold,
    double? expectedDuration, // CAT-23 drift correction
    String? whisperCliPath,
    bool? translate,
    void Function(double progress, String status)? onWebProgress,
  }) async {
    if (kIsWeb) {
      String modelName = 'tiny';
      if (modelPath != null && modelPath.contains('ggml-')) {
        final startIdx = modelPath.indexOf('ggml-') + 5;
        final endIdx = modelPath.lastIndexOf('.bin');
        if (endIdx > startIdx) {
          modelName = modelPath.substring(startIdx, endIdx);
        }
      }
      try {
        final jsonStr = await WebWasmBridge.transcribe(
          videoUrl: wavPath,
          modelName: modelName,
          language: language ?? 'auto',
          translate: translate ?? false,
          onProgress: onWebProgress ?? (_, __) {},
        );
        return parseTranscriptionJson(jsonStr, expectedDuration);
      } catch (e) {
        LoggerService.instance.log(LogLevel.error, 'WhisperService', 'Web WASM transcription failed: $e');
        rethrow;
      }
    }
    if (Platform.isAndroid || Platform.isIOS) {
      if (modelPath != null && modelPath.isNotEmpty) {
        await WhisperMobileService.instance.loadModel(modelPath);
      }
      return WhisperMobileService.instance.transcribe(
        wavPath: wavPath,
        language: language,
        useVad: useVad,
        vadThreshold: vadThreshold,
        expectedDuration: expectedDuration,
        translate: translate,
      );
    }

    final wavFile = File(wavPath);
    if (!wavFile.existsSync()) {
      LoggerService.instance.log(LogLevel.error, 'WhisperService', 'Transcription failed: WAV file not found: $wavPath');
      throw FileSystemException('WAV file not found', wavPath);
    }

    final activeModelPath = modelPath ?? _modelPath;
    if (activeModelPath == null || activeModelPath.isEmpty) {
      LoggerService.instance.log(LogLevel.error, 'WhisperService', 'Transcription failed: No model configured.');
      throw StateError('No whisper model configured. Please download and configure a model first.');
    }

    final modelFile = File(activeModelPath);
    if (!modelFile.existsSync()) {
      LoggerService.instance.log(LogLevel.error, 'WhisperService', 'Transcription failed: Model file not found at: $activeModelPath');
      throw FileSystemException('Whisper model file not found. Please download and activate a model in Settings.', activeModelPath);
    }

    // Determine thread count (shared by both FFI and CLI modes)
    int activeThreads = SettingsService.instance.whisperThreads;
    if (activeThreads <= 0) {
      activeThreads = (Platform.numberOfProcessors - 1).clamp(1, 16);
      LoggerService.instance.log(LogLevel.info, 'WhisperService', 
          'Dynamic allocation active. Detected logical cores: ${Platform.numberOfProcessors}. Assigned threads: $activeThreads');
    }

    // Try FFI first for zero-setup execution (Windows/macOS/Linux)
    if (WhisperFfiService.instance.isAvailable) {
      try {
        LoggerService.instance.log(LogLevel.action, 'WhisperService', 'Attempting native FFI transcription...');
        return await WhisperFfiService.instance.transcribe(
          wavPath: wavPath,
          modelPath: activeModelPath,
          language: language,
          translate: translate,
          threads: activeThreads,
          useVad: useVad,
          vadThreshold: vadThreshold,
          expectedDuration: expectedDuration,
        );
      } catch (e, stackTrace) {
        LoggerService.instance.log(
          LogLevel.warning,
          'WhisperService',
          'Native FFI transcription failed. Falling back to CLI subprocess. Error: $e',
          stackTrace: stackTrace,
        );
      }
    }

    final activeWhisperCliPath = whisperCliPath ?? this.whisperCliPath;

    final List<String> args = [
      '-m', activeModelPath,
      '-f', wavPath,
      '-ojf', // Enable full JSON output format with token-level timestamps
      '-t', activeThreads.toString(),
    ];

    if (language != null && language != 'auto') {
      final sanitizedLanguage = language.replaceAll(RegExp(r'[^a-zA-Z_-]'), '');
      if (sanitizedLanguage.isNotEmpty) {
        args.addAll(['-l', sanitizedLanguage]);
      }
    }

    if (translate == true) {
      args.add('-tr');
    }

    if (useVad == true) {
      args.add('--vad');
      args.addAll(['--vad-threshold', (vadThreshold ?? 0.5).toStringAsFixed(2)]);
    }

    final redactedCli = _redactPath(activeWhisperCliPath);
    final redactedArgs = args.map((a) => _redactPath(a)).join(' ');
    LoggerService.instance.log(LogLevel.info, 'WhisperService', 'Running transcription CLI: $redactedCli $redactedArgs');

    final jsonFile = File('$wavPath.json');
    final txtFile = File('$wavPath.txt');
    try {
      final int exitCode;
      final String stdoutStr;
      final String stderrStr;

      if (processRunner != null) {
        final res = await processRunner!(activeWhisperCliPath, args, stdoutEncoding: utf8, stderrEncoding: utf8);
        exitCode = res.exitCode;
        stdoutStr = res.stdout.toString();
        stderrStr = res.stderr.toString();
      } else {
        final process = await Process.start(activeWhisperCliPath, args);
        _activeProcesses.add(process);

        final StringBuffer stderrBuffer = StringBuffer();
        final stdoutFuture = process.stdout.transform(const Utf8Decoder(allowMalformed: true)).join();
        
        final stderrFuture = process.stderr
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter())
            .forEach((line) {
          stderrBuffer.writeln(line);
          if (line.contains('progress =')) {
            final match = RegExp(r'progress\s*=\s*(\d+)%?').firstMatch(line);
            if (match != null) {
              final pct = int.tryParse(match.group(1) ?? '');
              if (pct != null && onWebProgress != null) {
                onWebProgress(pct / 100.0, 'Running local speech-to-text ($pct%)...');
              }
            }
          }
        });

        try {
          exitCode = await process.exitCode;
          stdoutStr = await stdoutFuture;
          await stderrFuture;
          stderrStr = stderrBuffer.toString();
        } finally {
          _activeProcesses.remove(process);
        }
      }
 
      LoggerService.instance.log(LogLevel.trace, 'WhisperService', 'Transcription CLI finished. Output: ${stdoutStr.trim()}');

      if (exitCode != 0) {
        LoggerService.instance.log(LogLevel.error, 'WhisperService', 'Whisper transcription failed. Exit code: $exitCode, Error: $stderrStr');
        throw ProcessException(activeWhisperCliPath, args, 'Transcription CLI failed: $stderrStr', exitCode);
      }

      if (!jsonFile.existsSync()) {
        LoggerService.instance.log(LogLevel.error, 'WhisperService', 'Whisper JSON output not found at ${jsonFile.path}');
        throw FileSystemException('Transcription JSON output not found', jsonFile.path);
      }

      final bytes = await jsonFile.readAsBytes();
      final jsonContent = utf8.decode(bytes, allowMalformed: true);
      return parseTranscriptionJson(jsonContent, expectedDuration);
    } finally {
      try {
        if (jsonFile.existsSync()) await jsonFile.delete();
      } catch (_) {}
      try {
        if (txtFile.existsSync()) await txtFile.delete();
      } catch (_) {}
    }
  }

  /// Parses JSON output containing segments and words timestamps.
  /// Shared between desktop file reading and mobile memory FFI result strings.
  TranscriptionResult parseTranscriptionJson(String jsonString, double? expectedDuration) {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'WhisperService', 'Failed to parse transcription JSON: $e');
      throw FormatException('Malformed transcription JSON output from Whisper CLI: $e', jsonString);
    }

    if (data.containsKey('error')) {
      final errorMsg = data['error'];
      LoggerService.instance.log(LogLevel.error, 'WhisperService', 'Transcription error: $errorMsg');
      throw Exception('Whisper transcription failed: $errorMsg');
    }

    final segmentsRaw = data['segments'] ?? data['transcription'];
    final List<dynamic> segments = segmentsRaw is List ? segmentsRaw : [];

    final List<WordSchema> words = [];
    String detectedLang = 'en';
    if (data.containsKey('language')) {
      detectedLang = data['language'] as String? ?? 'en';
    } else if (data['result'] is Map && (data['result'] as Map).containsKey('language')) {
      detectedLang = (data['result'] as Map)['language'] as String? ?? 'en';
    } else if (data['params'] is Map && (data['params'] as Map).containsKey('language')) {
      detectedLang = (data['params'] as Map)['language'] as String? ?? 'en';
    }

    // Scan raw timestamps to determine if unit is milliseconds or seconds
    double maxRawTimestamp = 0.0;
    for (final segment in segments) {
      if (segment is! Map) continue;
      if (segment.containsKey('tokens')) {
        final List<dynamic>? tokens = segment['tokens'] as List<dynamic>?;
        if (tokens != null) {
          for (final token in tokens) {
            if (token is! Map) continue;
            final offsets = token['offsets'] as Map<dynamic, dynamic>?;
            if (offsets != null) {
              final to = (offsets['to'] as num?)?.toDouble() ?? 0.0;
              if (to > maxRawTimestamp) maxRawTimestamp = to;
            }
          }
        }
      } else if (segment.containsKey('timestamps')) {
        final ts = segment['timestamps'];
        if (ts is Map) {
          final to = (ts['to'] as num?)?.toDouble() ?? 0.0;
          if (to > maxRawTimestamp) maxRawTimestamp = to;
        }
      } else {
        final List<dynamic> segmentWords = segment['words'] is List ? segment['words'] as List : [];
        for (final w in segmentWords) {
          if (w is! Map) continue;
          final end = (w['end'] as num?)?.toDouble() ?? 0.0;
          if (end > maxRawTimestamp) maxRawTimestamp = end;
        }
      }
    }

    final bool isMs = expectedDuration != null
        ? (maxRawTimestamp > expectedDuration * 1.5)
        : (maxRawTimestamp > 1000.0);

    // Calculate drift multiplier if expected duration is provided and transcription is very long (>1000s)
    double driftMultiplier = 1.0;
    if (expectedDuration != null && expectedDuration > 1000.0 && segments.isNotEmpty) {
      final lastSegment = segments.last;
      if (lastSegment is Map) {
        final lastSegmentWords = lastSegment['words'] is List ? lastSegment['words'] as List<dynamic> : const <dynamic>[];
        double whisperEnd = 0.0;
        if (lastSegmentWords.isNotEmpty) {
          final lastWord = lastSegmentWords.last;
          if (lastWord is Map) {
            whisperEnd = (lastWord['end'] as num?)?.toDouble() ?? 0.0;
          }
        } else if (lastSegment.containsKey('timestamps') && lastSegment['timestamps'] is Map) {
          final ts = lastSegment['timestamps'] as Map;
          whisperEnd = (ts['to'] as num?)?.toDouble() ?? 0.0;
        } else if (lastSegment.containsKey('end')) {
          whisperEnd = (lastSegment['end'] as num?)?.toDouble() ?? 0.0;
        } else if (lastSegment.containsKey('to')) {
          whisperEnd = (lastSegment['to'] as num?)?.toDouble() ?? 0.0;
        }

        if (isMs && whisperEnd > 0) {
          whisperEnd /= 1000.0;
        }

        if (whisperEnd > 0 && (expectedDuration - whisperEnd).abs() <= (expectedDuration * 0.10)) {
          final rawDrift = expectedDuration / whisperEnd;
          
          final knownRatios = [
            48000 / 44100, // 1.08843 (Audio sample rate mismatch)
            44100 / 48000, // 0.91875
            25 / 24,       // 1.04166 (PAL/Film framerate conversion drift)
            24 / 25,       // 0.96000
          ];
          
          for (final ratio in knownRatios) {
            if ((rawDrift - ratio).abs() < 0.005) {
              driftMultiplier = ratio;
              LoggerService.instance.log(LogLevel.info, 'WhisperService', 'Applied exact hardware drift correction multiplier: $driftMultiplier (matches known ratio $ratio)');
              break;
            }
          }
        }
      }
    }

    for (final segment in segments) {
      if (segment is! Map) continue;
      // Check if token-level timestamps are available
      final List<dynamic>? tokens = segment['tokens'] is List ? segment['tokens'] as List : null;
      if (tokens != null && tokens.isNotEmpty) {
        WordSchema? currentWord;
        for (final token in tokens) {
          if (token is! Map) continue;
          final textRaw = token['text']?.toString() ?? '';
          if (textRaw.startsWith('[') && textRaw.endsWith(']')) {
            continue;
          }
          final offsets = token['offsets'] is Map ? token['offsets'] as Map : null;
          if (offsets == null) continue;

          final startMs = (offsets['from'] as num?)?.toDouble() ?? 0.0;
          final endMs = (offsets['to'] as num?)?.toDouble() ?? 0.0;
          final double startSec = startMs / 1000.0;
          final double endSec = endMs / 1000.0;
          final double confidence = (token['p'] as num?)?.toDouble() ?? 1.0;

          final isWordStart = textRaw.startsWith(' ') || textRaw.startsWith('Ġ');
          final cleanText = textRaw.trim();
          if (cleanText.isEmpty) continue;

          if (currentWord == null || isWordStart) {
            currentWord = WordSchema()
              ..wordId = _uuid.v4()
              ..text = cleanText
              ..start = startSec * driftMultiplier
              ..end = endSec * driftMultiplier
              ..type = 'word'
              ..confidence = confidence;
            words.add(currentWord);
          } else {
            currentWord.text = (currentWord.text ?? '') + cleanText;
            currentWord.end = endSec * driftMultiplier;
            currentWord.confidence = ((currentWord.confidence ?? 1.0) + confidence) / 2.0;
          }
        }
      } else if (segment.containsKey('text') && segment.containsKey('timestamps')) {
        final timestamps = segment['timestamps'];
        final startRaw = timestamps is Map ? (timestamps['from'] as num?)?.toDouble() ?? 0.0 : 0.0;
        final endRaw = timestamps is Map ? (timestamps['to'] as num?)?.toDouble() ?? 0.0 : 0.0;

        final double startSec = isMs ? startRaw / 1000.0 : startRaw;
        final double endSec = isMs ? endRaw / 1000.0 : endRaw;

        words.add(
          WordSchema()
            ..wordId = _uuid.v4()
            ..text = (segment['text']?.toString() ?? '').trim()
            ..start = startSec * driftMultiplier
            ..end = endSec * driftMultiplier
            ..type = 'word'
            ..confidence = (segment['p'] as num?)?.toDouble() ?? 1.0,
        );
      } else {
        final List<dynamic> segmentWords = segment['words'] is List ? segment['words'] as List : [];
        for (final w in segmentWords) {
          if (w is! Map) continue;
          final startRaw = (w['start'] as num?)?.toDouble() ?? 0.0;
          final endRaw = (w['end'] as num?)?.toDouble() ?? 0.0;
          
          final double startSec = isMs ? startRaw / 1000.0 : startRaw;
          final double endSec = isMs ? endRaw / 1000.0 : endRaw;
          
          words.add(
            WordSchema()
              ..wordId = _uuid.v4()
              ..text = (w['word']?.toString() ?? '').trim()
              ..start = startSec * driftMultiplier
              ..end = endSec * driftMultiplier
              ..type = 'word'
              ..confidence = (w['confidence'] as num?)?.toDouble() ?? 1.0,
          );
        }
      }
    }

    LoggerService.instance.log(LogLevel.info, 'WhisperService', 'Transcription parse successful. Extracted ${words.length} words in language: $detectedLang');

    return TranscriptionResult(
      words: words,
      language: detectedLang,
    );
  }

  String _redactPath(String path) {
    if (kIsWeb) return path;
    try {
      final userProfile = Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
      if (userProfile != null && userProfile.isNotEmpty && path.contains(userProfile)) {
        return path.replaceAll(userProfile, '<USER_PROFILE>');
      }
      return path.replaceAll(RegExp(r'[Cc]:\\Users\\[^\\]+'), r'C:\Users\<USER>');
    } catch (_) {
      return path;
    }
  }
}
