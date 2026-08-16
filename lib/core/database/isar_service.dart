import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:isar_community/isar.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../logger/logger_service.dart';
import '../utils/app_dirs.dart';
import 'package:flutter/foundation.dart';
import '../settings/settings_service.dart';
import '../utils/schema_clones.dart';
import '../utils/path_migration_utils.dart';
import 'schemas/project.dart';
import 'schemas/word.dart';
import 'web_db_helper.dart';

class IsarService {
  IsarService._internal();
  static IsarService _instance = IsarService._internal();
  static IsarService get instance => _instance;

  @visibleForTesting
  static set instance(IsarService newInstance) {
    _instance = newInstance;
  }

  @visibleForTesting
  static void resetForTesting() {
    _instance = IsarService._internal();
  }

  Isar? _isar;
  final Map<String, Project> _webProjects = {};

  bool _initialized = false;

  /// Check if the database has been initialized
  bool get isInitialized => _initialized;

  // Getter to access Isar, ensuring it's initialized
  Isar get db {
    if (kIsWeb) {
      throw StateError('Isar database is running in in-memory mode on Web.');
    }
    if (!_initialized || _isar == null) {
      throw StateError('Isar database has not been initialized. Call init() first.');
    }
    return _isar!;
  }

  Completer<void>? _initCompleter;
  String? lastAutoRecoveredBackupPath;

  void _log(LogLevel level, String tag, String message) {
    if (LoggerService.instance.isInitialized && !LoggerService.instance.isDisposing) {
      LoggerService.instance.log(level, tag, message);
    }
  }

  Future<void> _capBackupFiles(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      final list = await dir.list().where((e) {
        final name = p.basename(e.path);
        return name.startsWith('capstudio_db_backup_') && name.endsWith('.isar');
      }).toList();
      
      if (list.length >= 5) {
        list.sort((a, b) => a.path.compareTo(b.path)); // Oldest first
        final toDeleteCount = list.length - 4;
        for (int i = 0; i < toDeleteCount; i++) {
          try {
            await list[i].delete();
          } catch (_) {}
        }
      }
    } catch (e) {
      _log(LogLevel.warning, 'IsarService', 'Failed to cap backup files: $e');
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    if (_initCompleter != null) return _initCompleter!.future;
    
    _initCompleter = Completer<void>();

    try {
      if (kIsWeb) {
        _log(LogLevel.info, 'IsarService', 'Initializing database for Web via IndexedDB.');
        try {
          // 1. Load from IndexedDB
          final idbJsonStrings = await WebDbHelper.getAllProjectsWeb();
          for (final jsonStr in idbJsonStrings) {
            final map = jsonDecode(jsonStr) as Map<String, dynamic>;
            final project = _projectFromMap(map);
            _webProjects[project.projectId] = project;
          }

          // 2. Migration: load legacy SharedPreferences projects if any
          final prefs = await SharedPreferences.getInstance();
          final keys = prefs.getKeys().where((k) => k.startsWith('capstudio_proj_'));
          int migratedCount = 0;
          for (final key in keys) {
            final projectId = key.substring('capstudio_proj_'.length);
            if (!_webProjects.containsKey(projectId)) {
              final jsonStr = prefs.getString(key);
              if (jsonStr != null) {
                final map = jsonDecode(jsonStr) as Map<String, dynamic>;
                final project = _projectFromMap(map);
                _webProjects[project.projectId] = project;
                await WebDbHelper.saveProjectWeb(project.projectId, jsonStr);
                migratedCount++;
              }
            }
            await prefs.remove(key);
          }

          _log(LogLevel.info, 'IsarService', 'Loaded ${_webProjects.length} projects on Web (Migrated $migratedCount legacy projects).');
        } catch (e) {
          _log(LogLevel.error, 'IsarService', 'Failed to load projects on Web: $e');
        }
        _initialized = true;
        _initCompleter!.complete();
        return;
      }

      final String? dirPath = kIsWeb ? null : AppDirs.support;

      if (!kIsWeb) {
        // One-time migration: if the DB exists at the old double-nested path
        // (AppData\Roaming\CapStudio\CapStudio\) but not the new one, copy it.
        await _migrateDbIfNeeded(dirPath!);

        // Verify and run stored database schema version migration
        const currentSchemaVersion = 1;
        final storedVersion = SettingsService.instance.dbSchemaVersion;
        if (storedVersion < currentSchemaVersion) {
          _log(
            LogLevel.warning,
            'IsarService',
            'Database schema version mismatch detected: $storedVersion -> $currentSchemaVersion. Note: Schema migrations are currently not implemented.',
          );
          // Custom field migrations/default-setting logic is not yet implemented
          await SettingsService.instance.setDbSchemaVersion(currentSchemaVersion);
        }
      }

      _log(LogLevel.info, 'IsarService', kIsWeb ? 'Opening Isar database for Web' : 'Opening Isar database at: $dirPath');
      try {
        _isar = await Isar.open(
          [
            ProjectSchema,
          ],
          directory: dirPath ?? '',
          name: 'capstudio_db',
          inspector: false,
        );
      } on IsarError catch (e) {
        _log(
          LogLevel.error,
          'IsarService',
          'Isar open failed due to schema mismatch or corruption: $e. Attempting database auto-recovery...',
        );
        if (!kIsWeb) {
          try {
            final dbFile = File(p.join(dirPath!, 'capstudio_db.isar'));
            if (dbFile.existsSync()) {
              await _capBackupFiles(dirPath);
              final backupFile = File(p.join(dirPath, 'capstudio_db_backup_${DateTime.now().millisecondsSinceEpoch}.isar'));
              await dbFile.copy(backupFile.path);
              await dbFile.delete();
              lastAutoRecoveredBackupPath = backupFile.path;
              _log(LogLevel.warning, 'IsarService', 'Successfully backed up and removed corrupted database: ${backupFile.path}');
            }
          } catch (backupErr) {
            _log(LogLevel.error, 'IsarService', 'Failed to backup and remove corrupted database: $backupErr');
          }
        }
        // Try opening a fresh database
        _isar = await Isar.open(
          [
            ProjectSchema,
          ],
          directory: dirPath ?? '',
          name: 'capstudio_db',
          inspector: false,
        );
      }
      _log(LogLevel.info, 'IsarService', 'Isar database successfully opened.');
      _initialized = true;
      _initCompleter!.complete();
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null; // allow retry
      rethrow;
    } finally {
      if (_initCompleter != null && !_initCompleter!.isCompleted) {
        _initCompleter!.completeError(Exception('Init aborted prematurely'));
      }
    }
  }

  /// Copy DB files from old double-nested path to new single path, if needed.
  Future<void> _migrateDbIfNeeded(String newDirPath) async {
    try {
      // Old path: AppData\Roaming\CapStudio\CapStudio
      final oldDir = Directory(p.join(newDirPath, 'CapStudio'));
      if (!oldDir.existsSync()) return;

      const dbName = 'capstudio_db.isar';
      final oldFile = File(p.join(oldDir.path, dbName));
      final newFile = File(p.join(newDirPath, dbName));

      if (oldFile.existsSync() && !newFile.existsSync()) {
        await oldFile.copy(newFile.path);
        _log(LogLevel.info, 'IsarService',
            'Migrated database from old path: ${oldFile.path} → ${newFile.path}');
        try {
          await oldFile.delete();
          if (oldDir.listSync().isEmpty) {
            await oldDir.delete();
          }
          _log(LogLevel.info, 'IsarService', 'Cleaned up legacy database files.');
        } catch (cleanupErr) {
          _log(LogLevel.warning, 'IsarService', 'Failed to clean up legacy database files: $cleanupErr');
        }
      }
    } catch (e) {
      _log(LogLevel.warning, 'IsarService', 'DB migration check failed (non-fatal): $e');
    }
  }

  /// Save or update a project immediately in a database transaction
  Future<void> saveProject(Project project) async {
    _log(LogLevel.info, 'IsarService', 'Saving project to database: ${project.projectId} (${project.name})');
    
    if (kIsWeb) {
      _webProjects[project.projectId] = project;
      try {
        final jsonStr = jsonEncode(_projectToMap(project));
        await WebDbHelper.saveProjectWeb(project.projectId, jsonStr);
      } catch (e) {
        _log(LogLevel.error, 'IsarService', 'Failed to save project to IndexedDB on Web: $e');
      }
      return;
    }

    // Clone the project to prevent mutating the caller's reference in-place
    final clone = _deepCloneProject(project);
    clone.videoPath = PathMigrationUtils.toRelative(clone.videoPath) ?? '';
    clone.thumbnailPath = PathMigrationUtils.toRelative(clone.thumbnailPath);
    
    try {
      await db.writeTxn(() async {
        await db.projects.put(clone);
      });
      // Synchronize the assigned auto-increment ID back to the source project
      project.id = clone.id;
    } catch (e, stackTrace) {
      _log(LogLevel.error, 'IsarService', 'Failed to save project: $e. Stack: $stackTrace');
      rethrow;
    }
  }

  /// Fetch a project by its unique UUID projectId string
  Future<Project?> getProject(String projectId) async {
    _log(LogLevel.debug, 'IsarService', 'Fetching project: $projectId');
    if (kIsWeb) {
      return _webProjects[projectId];
    }
    final project = await db.projects.where().projectIdEqualTo(projectId).findFirst();
    if (project != null) {
      project.videoPath = PathMigrationUtils.toAbsolute(project.videoPath) ?? '';
      project.thumbnailPath = PathMigrationUtils.toAbsolute(project.thumbnailPath);
    }
    return project;
  }

  /// Delete a project by its auto-increment ID
  Future<void> deleteProject(Id id) async {
    _log(LogLevel.action, 'IsarService', 'Deleting project from database. ID: $id');
    if (kIsWeb) {
      String? keyToDelete;
      _webProjects.forEach((k, v) {
        if (v.id == id) keyToDelete = k;
      });
      if (keyToDelete != null) {
        _webProjects.remove(keyToDelete);
        await WebDbHelper.deleteProjectWeb(keyToDelete!);
      }
      return;
    }
    try {
      await db.writeTxn(() async {
        await db.projects.delete(id);
      });
    } catch (e) {
      _log(LogLevel.error, 'IsarService', 'Failed to delete project: $e');
      rethrow;
    }
  }

  /// Fetch all projects stored in the local database
  Future<List<Project>> getAllProjects() async {
    _log(LogLevel.debug, 'IsarService', 'Fetching all projects');
    if (kIsWeb) {
      return _webProjects.values.toList();
    }
    _log(LogLevel.debug, 'IsarService', 'Executing Isar query for all projects');
    final list = await db.projects.where().sortByCreatedAtDesc().findAll();
    _log(LogLevel.debug, 'IsarService', 'Isar query completed, found ${list.length} projects. Mapping paths...');
    for (final project in list) {
      project.videoPath = PathMigrationUtils.toAbsolute(project.videoPath) ?? '';
      project.thumbnailPath = PathMigrationUtils.toAbsolute(project.thumbnailPath);
    }
    _log(LogLevel.debug, 'IsarService', 'All projects fetched and paths mapped successfully');
    return list;
  }

  /// Close the database instance
  Future<void> close() async {
    if (kIsWeb) {
      _webProjects.clear();
      _initialized = false;
      return;
    }
    if (_isar != null) {
      await _isar!.close();
      _isar = null;
      _log(LogLevel.info, 'IsarService', 'Isar database closed.');
    }
    _initialized = false;
    _initCompleter = null;
  }

  // --- Web JSON Mapping Helpers ---

  Map<String, dynamic> _projectToMap(Project project) {
    return {
      'id': project.id,
      'projectId': project.projectId,
      'name': project.name,
      'videoPath': project.videoPath,
      'duration': project.duration,
      'width': project.width,
      'height': project.height,
      'createdAt': project.createdAt.toIso8601String(),
      'trimStart': project.trimStart,
      'trimEnd': project.trimEnd,
      'status': project.status,
      'thumbnailPath': project.thumbnailPath,
      'config': _configToMap(project.config),
      'words': project.words.map(_wordToMap).toList(),
      'segments': project.segments?.map(_segmentToMap).toList(),
    };
  }

  Project _projectFromMap(Map<String, dynamic> map) {
    final p = Project()
      ..id = (map['id'] as int?) ?? Isar.autoIncrement
      ..projectId = (map['projectId'] as String?) ?? ''
      ..name = (map['name'] as String?) ?? ''
      ..videoPath = (map['videoPath'] as String?) ?? ''
      ..duration = (map['duration'] as num?)?.toDouble() ?? 0.0
      ..width = (map['width'] as int?) ?? 0
      ..height = (map['height'] as int?) ?? 0
      ..createdAt = map['createdAt'] != null ? DateTime.parse(map['createdAt'] as String) : DateTime.now()
      ..trimStart = (map['trimStart'] as num?)?.toDouble() ?? 0.0
      ..trimEnd = (map['trimEnd'] as num?)?.toDouble() ?? 0.0
      ..status = (map['status'] as String?) ?? 'draft'
      ..thumbnailPath = map['thumbnailPath'] as String?
      ..config = _configFromMap(map['config'] as Map<String, dynamic>?);
    
    if (map['words'] != null) {
      p.words = (map['words'] as List).map((w) => _wordFromMap(w as Map<String, dynamic>)).toList();
    }
    
    if (map['segments'] != null) {
      p.segments = (map['segments'] as List).map((s) => _segmentFromMap(s as Map<String, dynamic>)).toList();
    }
    
    return p;
  }

  Map<String, dynamic> _configToMap(ProjectConfigSchema config) {
    return {
      'name': config.name,
      'style': {
        'fontFamily': config.style.fontFamily,
        'fontWeight': config.style.fontWeight,
        'textTransform': config.style.textTransform,
        'color': config.style.color,
        'fontSize': config.style.fontSize,
        'top': config.style.top,
        'highlightBackground': config.style.highlightBackground,
        'letterSpacing': config.style.letterSpacing,
        'lineHeight': config.style.lineHeight,
      },
      'highlightStyle': {
        'mainColor': config.highlightStyle.mainColor,
        'secondColor': config.highlightStyle.secondColor,
        'thirdColor': config.highlightStyle.thirdColor,
      },
      'subs': {
        'chunkSize': config.subs.chunkSize,
        'chunkLineMaxLength': config.subs.chunkLineMaxLength,
      },
      'animation': config.animation,
      'shadow': config.shadow,
      'stroke': config.stroke,
      'background': config.background,
      'emojiPack': config.emojiPack,
    };
  }

  ProjectConfigSchema _configFromMap(Map<String, dynamic>? map) {
    final config = ProjectConfigSchema();
    if (map == null) return config;

    config.name = (map['name'] as String?) ?? '';
    config.animation = (map['animation'] as String?) ?? 'none';
    config.shadow = (map['shadow'] as String?) ?? 'none';
    config.stroke = (map['stroke'] as String?) ?? 'none';
    config.background = map['background'] as String?;
    config.emojiPack = map['emojiPack'] as String?;

    if (map['style'] != null) {
      final styleMap = map['style'] as Map<String, dynamic>;
      config.style = StyleConfigSchema()
        ..fontFamily = (styleMap['fontFamily'] as String?) ?? 'Arial'
        ..fontWeight = (styleMap['fontWeight'] as String?) ?? '500'
        ..textTransform = (styleMap['textTransform'] as String?) ?? 'none'
        ..color = (styleMap['color'] as String?) ?? '#ffffff'
        ..fontSize = (styleMap['fontSize'] as num?)?.toDouble() ?? 24.0
        ..top = (styleMap['top'] as num?)?.toDouble() ?? 50.0
        ..highlightBackground = styleMap['highlightBackground'] as bool?
        ..letterSpacing = (styleMap['letterSpacing'] as num?)?.toDouble()
        ..lineHeight = (styleMap['lineHeight'] as num?)?.toDouble();
    }

    if (map['highlightStyle'] != null) {
      final hlMap = map['highlightStyle'] as Map<String, dynamic>;
      config.highlightStyle = HighlightStyleSchema()
        ..mainColor = (hlMap['mainColor'] as String?) ?? '#f97316'
        ..secondColor = (hlMap['secondColor'] as String?) ?? '#ffffff'
        ..thirdColor = (hlMap['thirdColor'] as String?) ?? '#ffffff';
    }

    if (map['subs'] != null) {
      final subsMap = map['subs'] as Map<String, dynamic>;
      config.subs = SubtitleConfigSchema()
        ..chunkSize = (subsMap['chunkSize'] as int?) ?? 3
        ..chunkLineMaxLength = (subsMap['chunkLineMaxLength'] as int?) ?? 20;
    }

    return config;
  }

  Map<String, dynamic> _wordToMap(WordSchema word) {
    return {
      'wordId': word.wordId,
      'text': word.text,
      'start': word.start,
      'end': word.end,
      'type': word.type,
      'emoji': word.emoji,
      'className': word.className,
      'confidence': word.confidence,
      'splitBefore': word.splitBefore,
      'hidden': word.hidden,
      'emojiConfig': word.emojiConfig != null ? {
        'x': word.emojiConfig!.x,
        'y': word.emojiConfig!.y,
        'scale': word.emojiConfig!.scale,
        'speed': word.emojiConfig!.speed,
      } : null,
      'soundEffect': word.soundEffect,
      'soundVolume': word.soundVolume,
    };
  }

  WordSchema _wordFromMap(Map<String, dynamic> map) {
    final w = WordSchema()
      ..wordId = map['wordId'] as String?
      ..text = map['text'] as String?
      ..start = (map['start'] as num?)?.toDouble()
      ..end = (map['end'] as num?)?.toDouble()
      ..type = map['type'] as String?
      ..emoji = map['emoji'] as String?
      ..className = map['className'] as String?
      ..confidence = (map['confidence'] as num?)?.toDouble()
      ..splitBefore = map['splitBefore'] as bool?
      ..hidden = map['hidden'] as bool?
      ..soundEffect = map['soundEffect'] as String?
      ..soundVolume = map['soundVolume'] as int?;

    if (map['emojiConfig'] != null) {
      final ecMap = map['emojiConfig'] as Map<String, dynamic>;
      w.emojiConfig = EmojiConfigSchema()
        ..x = (ecMap['x'] as num?)?.toDouble()
        ..y = (ecMap['y'] as num?)?.toDouble()
        ..scale = (ecMap['scale'] as num?)?.toDouble()
        ..speed = (ecMap['speed'] as num?)?.toDouble();
    }

    return w;
  }

  Map<String, dynamic> _segmentToMap(VideoSegmentSchema segment) {
    return {
      'start': segment.start,
      'end': segment.end,
      'isDeleted': segment.isDeleted,
    };
  }

  VideoSegmentSchema _segmentFromMap(Map<String, dynamic> map) {
    return VideoSegmentSchema()
      ..start = (map['start'] as num?)?.toDouble()
      ..end = (map['end'] as num?)?.toDouble()
      ..isDeleted = map['isDeleted'] as bool?;
  }

  // --- Fast Deep Cloning Methods ---

  // FIX (Issue #1, CapStudio 1.0 audit): this used to be 6 private methods
  // (_deepCloneProject, _cloneConfig, _cloneStyle, _cloneHighlightStyle,
  // _cloneSubs, _cloneSegment, _cloneWord) hand-duplicating the exact same
  // object-graph traversal that also existed independently in
  // editor_controller.dart and caption_engine.dart. Now delegates to the
  // single shared implementation in core/utils/schema_clones.dart.
  Project _deepCloneProject(Project p) => SchemaClones.cloneProjectDeep(p);
}
