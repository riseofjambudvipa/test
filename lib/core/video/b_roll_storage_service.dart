import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../logger/logger_service.dart';
import 'b_roll_models.dart';

/// Service managing persistent preferences and caching for attached B-roll
/// video and image overlay clips per project.
class BRollStorageService {
  BRollStorageService._();
  static final BRollStorageService instance = BRollStorageService._();

  static const String _prefPrefix = 'capstudio_broll_';
  final Map<String, List<BRollClip>> _cache = {};

  /// Synchronously returns cached B-roll clips for [projectId].
  List<BRollClip> getClips(String projectId) {
    if (projectId.isEmpty) return const [];
    return _cache[projectId] ?? const [];
  }

  /// Asynchronously loads B-roll clips for [projectId] from [SharedPreferences].
  Future<List<BRollClip>> loadClips(String projectId) async {
    if (projectId.isEmpty) return const [];

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefPrefix$projectId';
      final raw = prefs.getString(key);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        final clips = decoded
            .map((item) => BRollClip.fromJson(item as Map<String, dynamic>))
            .toList();
        _cache[projectId] = clips;
        return clips;
      }
    } catch (e) {
      LoggerService.instance.log(
        LogLevel.warning,
        'BRollStorageService',
        'Failed to load B-roll clips for $projectId: $e',
      );
    }

    _cache[projectId] = const [];
    return const [];
  }

  /// Persists [clips] for [projectId] into [SharedPreferences] and memory cache.
  Future<void> saveClips(String projectId, List<BRollClip> clips) async {
    if (projectId.isEmpty) return;
    _cache[projectId] = List.unmodifiable(clips);

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_prefPrefix$projectId';
      final encoded = jsonEncode(clips.map((c) => c.toJson()).toList());
      await prefs.setString(key, encoded);
      LoggerService.instance.debug(
        'BRollStorageService: saved ${clips.length} B-roll clips for $projectId',
      );
    } catch (e) {
      LoggerService.instance.log(
        LogLevel.error,
        'BRollStorageService',
        'Failed to save B-roll clips for $projectId: $e',
      );
    }
  }

  /// Clears in-memory cache (for testing/cleanup).
  void clearCache() {
    _cache.clear();
  }
}
