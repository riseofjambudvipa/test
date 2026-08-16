import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/assets/asset_path_service.dart';
import '../../../../core/subtitle/srt_importer.dart';
import '../../../../core/video/video_web_helper.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;
import '../../../../core/database/isar_service.dart';
import '../../../../core/database/schemas/project.dart';
import '../../../../core/database/schemas/word.dart';
import '../../../../core/utils/mock_transcription.dart';
import '../../../../core/whisper/whisper_service.dart';
import '../../../../core/utils/app_dirs.dart';
import '../../../../core/utils/permission_service.dart';
import '../../../../core/settings/settings_service.dart';
import '../../../../core/logger/logger_service.dart';
import '../../../../core/ffmpeg/ffmpeg_service.dart';
import '../../../../core/utils/schema_clones.dart';

class DashboardState {
  final List<Project> projects;
  final bool isLoading;
  final String? errorMessage;
  final double importProgress; // 0.0 to 1.0
  final String importStatusText;

  const DashboardState({
    this.projects = const [],
    this.isLoading = false,
    this.errorMessage,
    this.importProgress = 0.0,
    this.importStatusText = '',
  });

  DashboardState copyWith({
    List<Project>? projects,
    bool? isLoading,
    Object? errorMessage = const Object(),
    double? importProgress,
    String? importStatusText,
  }) {
    return DashboardState(
      projects: projects ?? this.projects,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == const Object() ? this.errorMessage : (errorMessage as String?),
      importProgress: importProgress ?? this.importProgress,
      importStatusText: importStatusText ?? this.importStatusText,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final IsarService _dbService = IsarService.instance;
  final _uuid = const Uuid();

  /// Mockable process runner for unit testing offline
  Future<ProcessResult> Function(
    String executable,
    List<String> arguments, {
    Encoding? stdoutEncoding,
    Encoding? stderrEncoding,
  })? processRunner;

  DashboardController() : super(const DashboardState()) {
    Future.microtask(() => loadProjects());
  }

  /// Load recent projects from Isar
  Future<void> loadProjects() async {
    LoggerService.instance.log(LogLevel.info, 'Dashboard', 'loadProjects called');
    state = state.copyWith(isLoading: true);
    try {
      if (_dbService.isInitialized) {
        LoggerService.instance.log(LogLevel.info, 'Dashboard', 'Database is initialized, calling getAllProjects');
        final list = await _dbService.getAllProjects();
        LoggerService.instance.log(LogLevel.info, 'Dashboard', 'getAllProjects returned ${list.length} projects');
        state = state.copyWith(projects: list, isLoading: false);
        LoggerService.instance.log(LogLevel.info, 'Dashboard', 'loadProjects successfully completed, state updated');
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Database not initialized');
        LoggerService.instance.log(LogLevel.error, 'Dashboard', 'Database not initialized during loadProjects');
      }
    } catch (e, stackTrace) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load projects: $e');
      LoggerService.instance.log(LogLevel.error, 'Dashboard', 'Failed to load projects: $e. Stack: $stackTrace');
    }
  }

  Future<void> deleteProject(String projectId) async {
    try {
      if (_dbService.isInitialized) {
        LoggerService.instance.log(LogLevel.action, 'Dashboard', 'Deleting project: $projectId');
        final project = await _dbService.getProject(projectId);
        if (project != null) {
          await _dbService.deleteProject(project.id);
        }
        
        // Cleanup thumbnail
        try {
          final thumbPath = p.join(AppDirs.support, 'thumbnails', '$projectId.jpg');
          final thumbFile = File(thumbPath);
          if (await thumbFile.exists()) {
            await thumbFile.delete();
            LoggerService.instance.log(LogLevel.info, 'Dashboard', 'Deleted thumbnail for project: $projectId');
          }
        } catch (e) {
          LoggerService.instance.log(LogLevel.debug, 'Dashboard', 'Failed to delete thumbnail for project $projectId: $e');
        }

        await loadProjects();
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete project: $e');
      LoggerService.instance.log(LogLevel.error, 'Dashboard', 'Failed to delete project: $e');
    }
  }

  Future<void> renameProject(String projectId, String newName) async {
    try {
      if (_dbService.isInitialized) {
        final project = await _dbService.getProject(projectId);
        if (project != null) {
          LoggerService.instance.log(LogLevel.action, 'Dashboard', 'Renaming project: $projectId to "$newName"');
          // Clone: never mutate an Isar-managed object in-place.
          final updated = Project()
            ..id = project.id
            ..projectId = project.projectId
            ..name = newName
            ..videoPath = project.videoPath
            ..duration = project.duration
            ..width = project.width
            ..height = project.height
            ..createdAt = project.createdAt
            ..trimStart = project.trimStart
            ..trimEnd = project.trimEnd
            ..status = project.status
            ..thumbnailPath = project.thumbnailPath
            ..config = project.config
            ..words = project.words
            ..segments = project.segments;
          await _dbService.saveProject(updated);
          await loadProjects();
        }
      }
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to rename project: $e');
      LoggerService.instance.log(LogLevel.error, 'Dashboard', 'Failed to rename project: $e');
    }
  }


  /// Import a video, transcribing it (or running a premium demo mock fallback)
  Future<Project?> importVideo({
    required String videoPath,
    required String projectName,
    required bool useMockTranscription,
    String? subtitlePath,
    String? language,
    String? modelSize,
    String? whisperCliPath,
    String? whisperModelPath,
    String? ffmpegCliPath,
    bool? useVad,
    double? vadThreshold,
    bool? translate,
  }) async {
    LoggerService.instance.log(LogLevel.action, 'Dashboard', 'Importing new video: $projectName ($videoPath), useMock: $useMockTranscription, VAD: $useVad ($vadThreshold), translate: $translate');
    state = state.copyWith(
      isLoading: true,
      importProgress: 0.0,
      importStatusText: 'Checking storage permissions...',
    );

    // On Android, ensure All Files permission before any file I/O.
    // On Android 11+ this opens the system Settings screen; the method returns
    // false and the user must re-try import after granting. On older Android and
    // all other platforms this returns true immediately.
    if (!kIsWeb && Platform.isAndroid) {
      final granted = await PermissionService.requestStoragePermission();
      if (!granted) {
        state = state.copyWith(
          isLoading: false,
          importStatusText: '',
          errorMessage: 'Storage permission required. Please grant "All files access" in Settings and try again.',
        );
        LoggerService.instance.log(LogLevel.warning, 'Dashboard', 'importVideo aborted: MANAGE_EXTERNAL_STORAGE not yet granted.');
        return null;
      }
    }

    state = state.copyWith(
      importStatusText: 'Analyzing video file...',
    );

    try {
      if (!kIsWeb) {
        final videoFile = File(videoPath);
        if (!await videoFile.exists()) {
          throw FileSystemException('Video file does not exist', videoPath);
        }
      }

      String finalVideoPath = videoPath;
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        state = state.copyWith(
          importStatusText: 'Copying video to app storage...',
        );
        final docDir = await getApplicationDocumentsDirectory();
        final videosDir = Directory(p.join(docDir.path, 'videos'));
        if (!await videosDir.exists()) {
          await videosDir.create(recursive: true);
        }
        
        final ext = p.extension(videoPath);
        final newFileName = 'vid_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}$ext';
        final newPath = p.join(videosDir.path, newFileName);
        
        LoggerService.instance.log(LogLevel.info, 'Dashboard', 'Copying picked video from $videoPath to persistent path: $newPath');
        await File(videoPath).copy(newPath);
        finalVideoPath = newPath;
      }

      final videoMeta = await getVideoMetadata(finalVideoPath);
      final double duration = videoMeta.duration;
      if (duration <= 0.0) {
        throw Exception('Failed to retrieve video duration. The file may be empty or corrupted.');
      }
      final dimensions = (width: videoMeta.width, height: videoMeta.height);
      LoggerService.instance.log(LogLevel.info, 'Dashboard', 'Video analysis complete. Duration: ${duration}s, Dimensions: ${dimensions.width}x${dimensions.height}');
      
      List<WordSchema> words = [];

      if (subtitlePath != null && subtitlePath.isNotEmpty) {
        state = state.copyWith(importProgress: 0.5, importStatusText: 'Importing subtitles from file...');
        try {
          final bytes = await File(subtitlePath).readAsBytes();
          words = SrtImporter.parseSrtBytes(bytes);
          LoggerService.instance.log(LogLevel.info, 'Dashboard', 'Successfully loaded ${words.length} words from subtitle file: $subtitlePath');
        } catch (e) {
          LoggerService.instance.log(LogLevel.error, 'Dashboard', 'Failed to import subtitle file: $e');
          throw Exception('Failed to read subtitle file: $e');
        }
      } else if (useMockTranscription) {
        state = state.copyWith(importProgress: 0.7, importStatusText: 'Loading demo subtitles...');
        if (kIsWeb) {
          try {
            final isLandscape = finalVideoPath.contains('landscape');
            final assetPath = isLandscape
                ? 'assets/demo/landscape/demo_subtitles.srt'
                : 'assets/demo/protrait/demo_subtitles.srt';
            final byteData = await rootBundle.load(assetPath);
            words = SrtImporter.parseSrtBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
          } catch (e) {
            LoggerService.instance.log(LogLevel.warning, 'Dashboard', 'Failed to load web demo subtitles: $e');
            words = generateMockWords(duration);
          }
        } else {
          final baseWithoutExt = p.withoutExtension(videoPath);
          final srtCandidates = [
            '${baseWithoutExt}_subtitles.srt',
            '$baseWithoutExt.srt',
          ];
          String? matchedSrtPath;
          for (final candidate in srtCandidates) {
            if (await File(candidate).exists()) {
              matchedSrtPath = candidate;
              break;
            }
          }
          if (matchedSrtPath != null) {
            try {
              final bytes = await File(matchedSrtPath).readAsBytes();
              words = SrtImporter.parseSrtBytes(bytes);
              LoggerService.instance.log(LogLevel.info, 'Dashboard', 'Loaded ${words.length} real subtitles from $matchedSrtPath for demo.');
            } catch (e) {
              LoggerService.instance.log(LogLevel.warning, 'Dashboard', 'Failed to parse srt file: $e');
              words = generateMockWords(duration);
            }
          } else {
            words = generateMockWords(duration);
          }
        }
        state = state.copyWith(importProgress: 0.8, importStatusText: 'Finalizing database...');
      } else {
        final String wavPath;
        if (kIsWeb) {
          wavPath = finalVideoPath;
        } else {
          state = state.copyWith(importProgress: 0.2, importStatusText: 'Extracting audio track...');
          final tempDir = AssetPathService.instance.tempDir;
          wavPath = await WhisperService.instance.extractAudio(finalVideoPath, tempDir, ffmpegCliPath: ffmpegCliPath);
        }
        
        state = state.copyWith(importProgress: 0.5, importStatusText: 'Running local speech-to-text...');
        
        final result = await WhisperService.instance.transcribe(
          wavPath: wavPath,
          modelPath: whisperModelPath,
          language: language,
          useVad: useVad,
          vadThreshold: vadThreshold,
          expectedDuration: duration,
          whisperCliPath: whisperCliPath,
          translate: translate,
          onWebProgress: (progress, status) {
            final mapped = 0.5 + progress * 0.3;
            state = state.copyWith(importProgress: mapped, importStatusText: status);
          },
        );
        words = result.words;
        
        if (!kIsWeb) {
          try {
            await File(wavPath).delete();
          } catch (_) {}
        }
      }

      // 2. Set default premium video styling parameters (YouTube-style clean subtitles)
      final style = StyleConfigSchema()
        ..fontFamily = 'Montserrat'
        ..fontWeight = '600'
        ..textTransform = 'none'
        ..color = '#ffffff' // White text
        ..fontSize = 28.0
        ..top = 75.0; // Place captions 75% down the screen

      final highlight = HighlightStyleSchema()
        ..mainColor = '#ffffff' // Keep active word white (no highlight color)
        ..secondColor = '#ffffff'
        ..thirdColor = '#ffffff';

      final subs = SubtitleConfigSchema()
        ..chunkSize = 3
        ..chunkLineMaxLength = 15;

      final config = ProjectConfigSchema()
        ..name = projectName
        ..style = style
        ..highlightStyle = highlight
        ..subs = subs
        ..animation = 'none' // No active word animations
        ..shadow = 'none'
        ..stroke = 'none' // No border outline stroke
        ..background = '#000000' // Semi-transparent black background box
        ..emojiPack = 'notoColorEmoji';

      final project = Project()
        ..projectId = 'proj_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}'
        ..name = projectName
        ..videoPath = finalVideoPath
        ..duration = duration
        ..width = dimensions.width
        ..height = dimensions.height
        ..createdAt = DateTime.now()
        ..trimStart = 0.0
        ..trimEnd = duration
        ..status = 'draft'
        ..config = config
        ..words = words;

      // 3. Save to database
      if (_dbService.isInitialized) {
        await _dbService.saveProject(project);
        await _generateThumbnail(project);
      }

      state = state.copyWith(
        isLoading: false,
        importProgress: 1.0,
        importStatusText: 'Complete!',
      );

      await loadProjects();
      return project;

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        importProgress: 0.0,
        importStatusText: '',
        errorMessage: 'Import failed: $e',
      );
      return null;
    }
  }

  /// Extracts video duration and dimensions (adjusted for rotation) in a single ffprobe run.
  Future<({double duration, int width, int height})> getVideoMetadata(String path) async {
    if (kIsWeb) {
      final duration = await getVideoDurationWeb(path);
      return (duration: duration > 0 ? duration : 60.0, width: 1920, height: 1080);
    }
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final info = await FfmpegService.instance.probeVideo(path);
        int w = (info['width'] as int?) ?? 0;
        int h = (info['height'] as int?) ?? 0;
        if (w <= 0) w = 1920;
        if (h <= 0) h = 1080;
        
        return (
          duration: (info['duration'] as double?) ?? 60.0,
          width: w,
          height: h,
        );
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'Dashboard', 'probeVideo failed: $e');
        return (duration: 60.0, width: 1920, height: 1080);
      }
    }

    try {
      final localFfprobe = p.join(
        p.dirname(SettingsService.instance.ffmpegCliPath ?? ''),
        Platform.isWindows ? 'ffprobe.exe' : 'ffprobe',
      );
      final ffprobePath = File(localFfprobe).existsSync() ? localFfprobe : 'ffprobe';

      final process = processRunner != null
          ? await processRunner!(
              ffprobePath,
              [
                '-v', 'error',
                '-select_streams', 'v:0',
                '-show_entries', 'stream=width,height:stream_side_data=rotation:stream_tags=rotate:format=duration',
                '-of', 'json',
                path
              ],
            )
          : await Process.run(
              ffprobePath,
              [
                '-v', 'error',
                '-select_streams', 'v:0',
                '-show_entries', 'stream=width,height:stream_side_data=rotation:stream_tags=rotate:format=duration',
                '-of', 'json',
                path
              ],
            );

      if (process.exitCode == 0) {
        final Map<String, dynamic> data = jsonDecode(process.stdout.toString()) as Map<String, dynamic>;
        final streams = data['streams'] as List<dynamic>?;
        final format = data['format'] as Map<String, dynamic>?;

        double duration = 60.0;
        if (format != null && format['duration'] != null) {
          duration = double.tryParse(format['duration'].toString()) ?? 60.0;
        }

        int width = 1920;
        int height = 1080;
        int rotation = 0;

        if (streams != null && streams.isNotEmpty) {
          final stream = streams.first;
          width = stream['width'] as int? ?? 1920;
          height = stream['height'] as int? ?? 1080;

          final sideDataList = stream['side_data_list'] as List<dynamic>?;
          if (sideDataList != null) {
            for (final sideData in sideDataList) {
              if (sideData['side_data_type'] == 'Display Matrix' && sideData['rotation'] != null) {
                rotation = (sideData['rotation'] as num).toInt();
                break;
              }
            }
          }

          final tags = stream['tags'] as Map<String, dynamic>?;
          if (tags != null && tags['rotate'] != null) {
            rotation = int.tryParse(tags['rotate'].toString()) ?? rotation;
          }
        }

        if (rotation == 90 || rotation == -90 || rotation == 270 || rotation == -270) {
          final temp = width;
          width = height;
          height = temp;
        }

        return (duration: duration, width: width, height: height);
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'Dashboard', 'Single-run ffprobe metadata extraction failed: $e');
    }
    return (duration: 60.0, width: 1920, height: 1080); // Fallback
  }

  Future<void> _generateThumbnail(Project project) async {
    if (kIsWeb) return;
    try {
      final thumbDir = Directory(p.join(AppDirs.support, 'thumbnails'));
      if (!await thumbDir.exists()) {
        await thumbDir.create(recursive: true);
      }
      final thumbPath = p.join(thumbDir.path, '${project.projectId}.jpg');
      
      if (Platform.isAndroid || Platform.isIOS) {
        await FfmpegService.instance.generateThumbnail(project.videoPath, thumbPath);
      } else {
        final ffmpegPath = (SettingsService.instance.ffmpegCliPath?.isNotEmpty == true) 
            ? SettingsService.instance.ffmpegCliPath! 
            : 'ffmpeg';
        final result = processRunner != null
            ? await processRunner!(ffmpegPath, [
                '-y',
                '-i', project.videoPath,
                '-ss', '00:00:01',
                '-vframes', '1',
                '-vf', 'scale=320:-1',
                '-q:v', '5',
                thumbPath,
              ])
            : await Process.run(ffmpegPath, [
                '-y',
                '-i', project.videoPath,
                '-ss', '00:00:01',
                '-vframes', '1',
                '-vf', 'scale=320:-1',
                '-q:v', '5',
                thumbPath,
              ]);
        if (result.exitCode != 0) {
          throw ProcessException(ffmpegPath, [], 'Thumbnail generation failed', result.exitCode);
        }
      }
      
      if (await File(thumbPath).exists()) {
        // Never mutate the caller-provided project object directly.
        // Build a proper clone with only the thumbnailPath updated,
        // then persist it and reload the project list.
        final updated = _cloneProjectForThumbnail(project, thumbPath);
        if (_dbService.isInitialized) {
          await _dbService.saveProject(updated);
        }
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'Dashboard', 'Failed to generate thumbnail: $e');
    }
  }

  Future<void> duplicateProject(String projectId) async {
    try {
      if (!_dbService.isInitialized) return;
      final original = await _dbService.getProject(projectId);
      if (original == null) return;

      state = state.copyWith(isLoading: true);

      // FIX (Issue #1 extended, found in second-pass review): this used to
      // hand-duplicate the same config/word/segment cloning logic that
      // SchemaClones now centralizes — and that hand-duplicated copy had a
      // real bug: its emojiConfig clone was missing the `speed` field, so
      // duplicating a project would silently reset any custom emoji
      // animation speed back to default. Delegating to SchemaClones fixes
      // that bug as a direct consequence of removing the duplication.
      final config = SchemaClones.cloneConfig(original.config)..name = '${original.config.name} Copy';

      // Words still get fresh IDs on duplication (a duplicated project's
      // words must not share IDs with the original's) — clone first via
      // SchemaClones (correct, complete field copy), then assign new IDs.
      final words = original.words.map((w) {
        final cloned = SchemaClones.cloneWord(w);
        cloned.wordId = _uuid.v4();
        return cloned;
      }).toList();

      final newProjectId = 'proj_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4().substring(0, 8)}';
      
      String? copyThumbPath;
      if (original.thumbnailPath != null && original.thumbnailPath!.isNotEmpty) {
        try {
          final origThumbFile = File(original.thumbnailPath!);
          if (await origThumbFile.exists()) {
            final thumbDir = Directory(p.join(AppDirs.support, 'thumbnails'));
            if (!await thumbDir.exists()) {
              await thumbDir.create(recursive: true);
            }
            final destPath = p.join(thumbDir.path, '$newProjectId.jpg');
            await origThumbFile.copy(destPath);
            copyThumbPath = destPath;
            LoggerService.instance.log(LogLevel.info, 'Dashboard', 'Cloned thumbnail for duplicated project: $newProjectId');
          }
        } catch (e) {
          LoggerService.instance.log(LogLevel.warning, 'Dashboard', 'Failed to clone thumbnail during duplication: $e');
        }
      }

      final copy = Project()
        ..projectId = newProjectId
        ..name = '${original.name} (Copy)'
        ..videoPath = original.videoPath
        ..duration = original.duration
        ..width = original.width
        ..height = original.height
        ..createdAt = DateTime.now()
        ..trimStart = original.trimStart
        ..trimEnd = original.trimEnd
        ..status = original.status
        ..config = config
        ..words = words
        ..thumbnailPath = copyThumbPath
        ..segments = original.segments?.map(SchemaClones.cloneSegment).toList();

      await _dbService.saveProject(copy);
      await loadProjects();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to duplicate project: $e');
      LoggerService.instance.log(LogLevel.error, 'Dashboard', 'Failed to duplicate project: $e');
    }
  }

  /// Creates a shallow clone of [project] with [newThumbPath] applied.
  /// Used exclusively by [_generateThumbnail] to avoid mutating Isar-managed objects.
  ///
  /// NOTE (found in second-pass review): intentionally shallow (config/words/
  /// segments copied by reference, not deep-cloned) since this only needs to
  /// change one field and isn't racing with concurrent mutation the way
  /// undo/redo or pre-save cloning are — SchemaClones.cloneProjectDeep would
  /// be needlessly expensive here. Not wired to SchemaClones for that reason,
  /// but it still hand-lists Project's fields, so if a field is added to
  /// Project, this is one more place (alongside SchemaClones itself) that
  /// needs updating — low risk since it's a simple wrapper, but worth
  /// checking during future schema changes.
  Project _cloneProjectForThumbnail(Project project, String newThumbPath) {
    return Project()
      ..id = project.id
      ..projectId = project.projectId
      ..name = project.name
      ..videoPath = project.videoPath
      ..duration = project.duration
      ..width = project.width
      ..height = project.height
      ..createdAt = project.createdAt
      ..trimStart = project.trimStart
      ..trimEnd = project.trimEnd
      ..status = project.status
      ..thumbnailPath = newThumbPath
      ..config = project.config
      ..words = project.words
      ..segments = project.segments;
  }
}

final dashboardProvider = StateNotifierProvider<DashboardController, DashboardState>((ref) {
  return DashboardController();
});
