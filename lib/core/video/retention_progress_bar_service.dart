import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../logger/logger_service.dart';
import 'retention_progress_bar_models.dart';

/// Service managing persistent preferences and presets for dynamic
/// video retention progress bars (Submagic & OpusClip parity).
class RetentionProgressBarService {
  RetentionProgressBarService._();
  static final RetentionProgressBarService instance = RetentionProgressBarService._();

  static const String _prefPrefix = 'capstudio_retention_bar_';
  final Map<String, RetentionProgressBarConfig> _cache = {};

  /// Synchronously returns the cached config for [projectId], or default if not cached.
  RetentionProgressBarConfig getConfig(String projectId) {
    if (projectId.isEmpty) return const RetentionProgressBarConfig();
    return _cache[projectId] ?? const RetentionProgressBarConfig();
  }

  /// Asynchronously loads the configuration for [projectId] from [SharedPreferences].
  Future<RetentionProgressBarConfig> loadConfig(String projectId) async {
    if (projectId.isEmpty) return const RetentionProgressBarConfig();

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefPrefix$projectId';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final config = RetentionProgressBarConfig.fromJson(decoded);
        _cache[projectId] = config;
        return config;
      }
    } catch (e) {
      LoggerService.instance.log(
        LogLevel.warning,
        'RetentionProgressBarService',
        'Failed to load retention bar config for $projectId: $e',
      );
    }

    const fallback = RetentionProgressBarConfig();
    _cache[projectId] = fallback;
    return fallback;
  }

  /// Persists [config] for [projectId] into [SharedPreferences] and memory cache.
  Future<void> saveConfig(String projectId, RetentionProgressBarConfig config) async {
    if (projectId.isEmpty) return;
    _cache[projectId] = config;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefPrefix$projectId';
      await prefs.setString(key, jsonEncode(config.toJson()));
      LoggerService.instance.debug(
        'RetentionProgressBarService: saved config for $projectId (enabled=${config.enabled}, color=${config.color})',
      );
    } catch (e) {
      LoggerService.instance.log(
        LogLevel.error,
        'RetentionProgressBarService',
        'Failed to save retention bar config for $projectId: $e',
      );
    }
  }

  /// Returns the built-in preset configurations available for fast 1-click styling.
  Map<String, RetentionProgressBarConfig> getPresets() {
    return {
      'Viral Ember': RetentionProgressBarConfig.viralEmber,
      'Electric Cyan': RetentionProgressBarConfig.electricCyan,
      'Hot Magenta': RetentionProgressBarConfig.hotMagenta,
      'Acid Green': RetentionProgressBarConfig.acidGreen,
      'Pure Minimalist': RetentionProgressBarConfig.pureMinimalist,
      'Top Header': RetentionProgressBarConfig.topHeader,
    };
  }

  /// Clears the in-memory cache (useful during testing or logout).
  void clearCache() {
    _cache.clear();
  }
}
