import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../logger/logger_service.dart';
import '../settings/settings_service.dart';
import 'whisper_service.dart'; // Reuse TranscriptionResult class

/// Mobile-specific Whisper service using native whisper.cpp via MethodChannel
class WhisperMobileService {
  WhisperMobileService._();
  static WhisperMobileService _instance = WhisperMobileService._();
  static WhisperMobileService get instance => _instance;

  @visibleForTesting
  static set instance(WhisperMobileService newInstance) {
    _instance = newInstance;
  }

  // Android: JNI via MethodChannel
  // iOS: Swift bridge via MethodChannel
  static const _channel = MethodChannel('com.capstudio/whisper');

  String? _loadedModelPath;
  bool _isModelLoaded = false;
  bool _isLoading = false;
  bool _isTranscribing = false;

  bool get isModelLoaded => _isModelLoaded;
  bool get isTranscribing => _isTranscribing;

  /// Load the whisper model into memory.
  /// Call once. Model stays in memory until freeModel() or app exit.
  Future<void> loadModel(String modelPath) async {
    if (kIsWeb) return;
    if (_loadedModelPath == modelPath && _isModelLoaded) {
      LoggerService.instance.log(LogLevel.info, 'WhisperMobile', 'Model already loaded: $modelPath');
      return;
    }

    if (_isLoading) {
      LoggerService.instance.log(LogLevel.warning, 'WhisperMobile', 'Model is currently loading, skipping duplicate request');
      return;
    }

    if (!File(modelPath).existsSync()) {
      throw FileSystemException('Whisper model file not found', modelPath);
    }

    _isLoading = true;
    try {
      LoggerService.instance.log(LogLevel.info, 'WhisperMobile', 'Loading model: $modelPath');

      final result = await _channel.invokeMethod<int>('loadModel', {
        'modelPath': modelPath,
      });

      if (result != 0) {
        throw Exception('Failed to load whisper model. Error code: $result');
      }

      _loadedModelPath = modelPath;
      _isModelLoaded = true;
      LoggerService.instance.log(LogLevel.info, 'WhisperMobile', 'Model loaded successfully');
    } finally {
      _isLoading = false;
    }
  }

  /// Transcribe a WAV file.
  /// Returns TranscriptionResult with word-level timestamps.
  /// WAV must be 16kHz mono PCM (use FfmpegService.extractAudioForWhisper first)
  Future<TranscriptionResult> transcribe({
    required String wavPath,
    String? language,
    bool? useVad,
    double? vadThreshold,
    double? expectedDuration,
    bool? translate,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('Mobile transcription is not supported on Web.');
    }
    _isTranscribing = true;
    try {
      if (!_isModelLoaded) {
        final modelPath = SettingsService.instance.whisperModelPath;
        if (modelPath == null || modelPath.isEmpty) {
          throw StateError('No whisper model loaded. Download a model first.');
        }
        await loadModel(modelPath);
      }

      if (!File(wavPath).existsSync()) {
        throw FileSystemException('WAV file not found', wavPath);
      }

      final lang = (language == null || language == 'auto') ? null : language;
      int threads = SettingsService.instance.whisperThreads;
      if (threads <= 0) {
        // Logic concurrency clamp
        threads = (Platform.numberOfProcessors - 1).clamp(1, 8);
      }

      LoggerService.instance.log(LogLevel.info, 'WhisperMobile',
          'Transcribing: $wavPath (lang=${lang ?? "auto"}, threads=$threads, vad=$useVad, translate=$translate)');

      final resultStr = await _channel.invokeMethod<String>('transcribe', {
        'wavPath': wavPath,
        'language': lang ?? '',
        'threads': threads,
        'useVad': useVad ?? false,
        'vadThreshold': vadThreshold ?? 0.5,
        'translate': translate ?? false,
      });

      if (resultStr == null || resultStr.isEmpty) {
        throw Exception('Transcription returned empty result');
      }

      String jsonString;
      if (resultStr.startsWith('{')) {
        jsonString = resultStr;
      } else {
        final file = File(resultStr);
        if (!file.existsSync()) {
          throw Exception('Transcription JSON file not found: $resultStr');
        }
        final bytes = await file.readAsBytes();
        jsonString = utf8.decode(bytes, allowMalformed: true);
        try {
          file.deleteSync();
        } catch (e) {
          LoggerService.instance.debug('Failed to delete mobile transcription temp file: $e');
        }
      }

      // Reuse desktop JSON parser — JNI outputs same format as whisper-cli -oj
      return WhisperService.instance.parseTranscriptionJson(jsonString, expectedDuration);
    } finally {
      _isTranscribing = false;
      // Auto-free Whisper model after transcription completes to keep RAM completely clean!
      await freeModel();
    }
  }

  Future<void> freeModel() async {
    if (kIsWeb) return;
    if (_isTranscribing) {
      LoggerService.instance.log(LogLevel.warning, 'WhisperMobile', 'Cannot free Whisper model while transcription is in progress');
      return;
    }
    if (!_isModelLoaded) return;
    try {
      await _channel.invokeMethod('freeModel');
    } catch (e, stackTrace) {
      LoggerService.instance.log(LogLevel.error, 'WhisperMobile', 'Failed to free Whisper model: $e. Stack: $stackTrace');
    } finally {
      _isModelLoaded = false;
      _loadedModelPath = null;
    }
    LoggerService.instance.log(LogLevel.info, 'WhisperMobile', 'Model freed from memory');
  }
}
