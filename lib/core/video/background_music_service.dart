import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../logger/logger_service.dart';
import 'background_music_models.dart';

/// Service managing persistent preferences and caching for background music
/// tracks and sidechain speech ducking per project.
class BackgroundMusicService {
  BackgroundMusicService._();
  static final BackgroundMusicService instance = BackgroundMusicService._();

  static const String _prefPrefix = 'capstudio_bgm_';
  final Map<String, BackgroundMusicConfig> _cache = {};

  /// Synchronously returns the cached config for [projectId], or default if not cached.
  BackgroundMusicConfig getConfig(String projectId) {
    if (projectId.isEmpty) return const BackgroundMusicConfig();
    return _cache[projectId] ?? const BackgroundMusicConfig();
  }

  /// Asynchronously loads the configuration for [projectId] from [SharedPreferences].
  Future<BackgroundMusicConfig> loadConfig(String projectId) async {
    if (projectId.isEmpty) return const BackgroundMusicConfig();

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefPrefix$projectId';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final config = BackgroundMusicConfig.fromJson(decoded);
        _cache[projectId] = config;
        return config;
      }
    } catch (e) {
      LoggerService.instance.log(
        LogLevel.warning,
        'BackgroundMusicService',
        'Failed to load background music config for $projectId: $e',
      );
    }

    const fallback = BackgroundMusicConfig();
    _cache[projectId] = fallback;
    return fallback;
  }

  /// Persists [config] for [projectId] into [SharedPreferences] and memory cache.
  Future<void> saveConfig(String projectId, BackgroundMusicConfig config) async {
    if (projectId.isEmpty) return;
    _cache[projectId] = config;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefPrefix$projectId';
      await prefs.setString(key, jsonEncode(config.toJson()));
      LoggerService.instance.debug(
        'BackgroundMusicService: saved config for $projectId (path=${config.musicPath}, vol=${config.volume})',
      );
    } catch (e) {
      LoggerService.instance.log(
        LogLevel.error,
        'BackgroundMusicService',
        'Failed to save background music config for $projectId: $e',
      );
    }
  }

  /// Clears the in-memory cache (useful during testing or logout).
  void clearCache() {
    _cache.clear();
  }
}
