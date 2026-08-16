import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:shared_preferences/shared_preferences.dart';
import '../whisper/whisper_service.dart';
import '../utils/app_dirs.dart';
import '../logger/logger_service.dart';
import '../utils/path_migration_utils.dart';

class SettingsService {
  SettingsService._internal();
  static final SettingsService instance = SettingsService._internal();

  @visibleForTesting
  void resetForTesting() {
    _isInitialized = false;
    _prefs = null;
  }

  static const _keyWhisperPath = 'whisper_cli_path';
  static const _keyFfmpegPath = 'ffmpeg_cli_path';
  static const _keyDefaultLanguage = 'default_language';
  static const _keyUseVad = 'use_vad';
  static const _keyVadThreshold = 'vad_threshold';
  static const _keyOutputFolder = 'output_folder';
  static const _keyTheme = 'app_theme';
  static const _keyOnboardingComplete = 'onboarding_complete';
  static const _keyForceNoAvx = 'force_no_avx';
  static const _keyWhisperModelPath = 'whisper_model_path';
  static const _keyWhisperModelName = 'whisper_model_name';
  static const _keyDbSchemaVersion = 'db_schema_version';
  static const _keyUseGpu = 'use_gpu_acceleration';
  static const _keyGpuEncoder = 'gpu_encoder';
  static const _keyWhisperThreads = 'whisper_threads';
  static const _keyExportThreads = 'export_threads';
  static const _keyAutoSave = 'auto_save_enabled';
  static const _keyAlwaysAskExportPath = 'always_ask_export_path';
  static const _keyEmojiSearchLanguage = 'emoji_search_language';
  static const _keyLogLevel = 'app_log_level';
  static const _keyUiLanguage = 'app_ui_language';

  SharedPreferences? _prefs;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    final isTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (_isInitialized && !isTesting) return;
    _isInitialized = true;
    try {
      _prefs = await SharedPreferences.getInstance();
      _applyStoredSettings();
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  void _applyStoredSettings() {
    final whisperPath = _prefs?.getString(_keyWhisperPath);
    final ffmpegPath = _prefs?.getString(_keyFfmpegPath);
    final modelPathRaw = _prefs?.getString(_keyWhisperModelPath);
    final modelPath = PathMigrationUtils.toAbsolute(modelPathRaw);
    if (whisperPath != null && whisperPath.isNotEmpty) {
      WhisperService.instance.configureCli(whisperPath);
    }
    if (ffmpegPath != null && ffmpegPath.isNotEmpty) {
      WhisperService.instance.configureFfmpeg(ffmpegPath);
    }
    if (modelPath != null && modelPath.isNotEmpty) {
      WhisperService.instance.configureModel(modelPath);
    }
    if (_prefs?.getBool(_keyForceNoAvx) == true) {
      AppDirs.setHasAvx(false);
    }
    final logLevelName = _prefs?.getString(_keyLogLevel);
    if (logLevelName != null) {
      try {
        final level = LogLevel.values.firstWhere((l) => l.name == logLevelName);
        LoggerService.instance.setMinimumLevel(level);
      } catch (_) {}
    }
  }

  SharedPreferences get _requirePrefs {
    if (_prefs == null) {
      throw StateError('SettingsService has not been initialized. Ensure SettingsService.instance.init() is called first.');
    }
    return _prefs!;
  }

  // Getters
  String? get whisperCliPath => _requirePrefs.getString(_keyWhisperPath);
  String? get ffmpegCliPath => _requirePrefs.getString(_keyFfmpegPath);
  String get defaultLanguage => _requirePrefs.getString(_keyDefaultLanguage) ?? 'auto';
  bool get useVad => _requirePrefs.getBool(_keyUseVad) ?? false;
  double get vadThreshold => _requirePrefs.getDouble(_keyVadThreshold) ?? 0.5;
  String? get outputFolder => _requirePrefs.getString(_keyOutputFolder);
  String get appTheme => _requirePrefs.getString(_keyTheme) ?? 'obsidianAmber';
  bool get onboardingComplete => kIsWeb || (_requirePrefs.getBool(_keyOnboardingComplete) ?? false);
  bool get forceNoAvx => _requirePrefs.getBool(_keyForceNoAvx) ?? false;
  String? get whisperModelPath {
    final raw = _requirePrefs.getString(_keyWhisperModelPath);
    return PathMigrationUtils.toAbsolute(raw);
  }
  String? get whisperModelName => _requirePrefs.getString(_keyWhisperModelName);
  int get dbSchemaVersion => _requirePrefs.getInt(_keyDbSchemaVersion) ?? 1;
  bool get useGpu => _requirePrefs.getBool(_keyUseGpu) ?? false;
  String get gpuEncoder => _requirePrefs.getString(_keyGpuEncoder) ?? 'none';
  int get whisperThreads => _requirePrefs.getInt(_keyWhisperThreads) ?? 0;
  int get exportThreads => _requirePrefs.getInt(_keyExportThreads) ?? 0;
  bool get autoSaveEnabled => _requirePrefs.getBool(_keyAutoSave) ?? true;
  bool get alwaysAskExportPath => _requirePrefs.getBool(_keyAlwaysAskExportPath) ?? false;
  String get emojiSearchLanguage => _requirePrefs.getString(_keyEmojiSearchLanguage) ?? 'auto';
  String get logMinimumLevel => _requirePrefs.getString(_keyLogLevel) ?? 'info';
  String get uiLanguage => _requirePrefs.getString(_keyUiLanguage) ?? 'system';

  // Helper Setters with success checks
  Future<void> _setBool(String key, bool value) async {
    final ok = await _requirePrefs.setBool(key, value);
    if (!ok) {
      LoggerService.instance.log(LogLevel.warning, 'SettingsService', 'Failed to persist setting: $key = $value');
    }
  }
  Future<void> _setString(String key, String value) async {
    final ok = await _requirePrefs.setString(key, value);
    if (!ok) {
      LoggerService.instance.log(LogLevel.warning, 'SettingsService', 'Failed to persist setting: $key = $value');
    }
  }
  Future<void> _setInt(String key, int value) async {
    final ok = await _requirePrefs.setInt(key, value);
    if (!ok) {
      LoggerService.instance.log(LogLevel.warning, 'SettingsService', 'Failed to persist setting: $key = $value');
    }
  }
  Future<void> _setDouble(String key, double value) async {
    final ok = await _requirePrefs.setDouble(key, value);
    if (!ok) {
      LoggerService.instance.log(LogLevel.warning, 'SettingsService', 'Failed to persist setting: $key = $value');
    }
  }

  // Setters (all async write + apply immediately)
  Future<void> setDbSchemaVersion(int version) async {
    final cleanVersion = version < 1 ? 1 : version;
    await _setInt(_keyDbSchemaVersion, cleanVersion);
  }
  String _sanitizePath(String path) {
    var cleaned = path.trim();
    if (cleaned.isEmpty) return '';
    if (cleaned.startsWith(r'\\') || cleaned.startsWith('//')) {
      return ''; // Refuse network UNC paths
    }
    cleaned = cleaned.replaceAll(RegExp(r'[\x00-\x1F\x7F;|&$`><\r\n]'), '');
    return cleaned;
  }

  Future<void> setWhisperCliPath(String path) async {
    final sanitized = _sanitizePath(path);
    await _setString(_keyWhisperPath, sanitized);
    WhisperService.instance.configureCli(sanitized);
  }
  Future<void> setFfmpegCliPath(String path) async {
    final sanitized = _sanitizePath(path);
    await _setString(_keyFfmpegPath, sanitized);
    WhisperService.instance.configureFfmpeg(sanitized);
  }
  Future<void> setDefaultLanguage(String lang) async => await _setString(_keyDefaultLanguage, lang);
  Future<void> setUseVad(bool v) async => await _setBool(_keyUseVad, v);
  Future<void> setVadThreshold(double v) async => await _setDouble(_keyVadThreshold, v.clamp(0.0, 1.0));
  Future<void> setOutputFolder(String path) async {
    final sanitized = _sanitizePath(path);
    await _setString(_keyOutputFolder, sanitized);
  }
  Future<void> setAppTheme(String theme) async => await _setString(_keyTheme, theme);
  Future<void> setOnboardingComplete() async => await _setBool(_keyOnboardingComplete, true);
  Future<void> setForceNoAvx(bool value) async {
    await _setBool(_keyForceNoAvx, value);
    if (value) {
      AppDirs.setHasAvx(false);
    } else {
      AppDirs.setHasAvx(null);
    }
  }
  Future<void> setWhisperModelPath(String path) async {
    final sanitized = _sanitizePath(path);
    final tokenized = PathMigrationUtils.toRelative(sanitized) ?? '';
    await _setString(_keyWhisperModelPath, tokenized);
    WhisperService.instance.configureModel(sanitized);
  }
  Future<void> setWhisperModelName(String name) async => await _setString(_keyWhisperModelName, name);
  Future<void> setUseGpu(bool v) async => await _setBool(_keyUseGpu, v);
  Future<void> setGpuEncoder(String enc) async => await _setString(_keyGpuEncoder, enc);
  Future<void> setWhisperThreads(int count) async => await _setInt(_keyWhisperThreads, count.clamp(0, 64));
  Future<void> setExportThreads(int count) async => await _setInt(_keyExportThreads, count.clamp(0, 64));
  Future<void> setAutoSave(bool v) async => await _setBool(_keyAutoSave, v);
  Future<void> setAlwaysAskExportPath(bool v) async => await _setBool(_keyAlwaysAskExportPath, v);
  Future<void> setEmojiSearchLanguage(String lang) async => await _setString(_keyEmojiSearchLanguage, lang);
  Future<void> setLogMinimumLevel(String level) async => await _setString(_keyLogLevel, level);
  Future<void> setUiLanguage(String lang) async => await _setString(_keyUiLanguage, lang);
}
