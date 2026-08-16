part of 'editor_controller.dart';

/// Maximum undo/redo history entries kept per editor session.
const int _kMaxHistory = 50;

/// Shared state, deep-clone helpers, persistence, and session-level actions
/// for [EditorController]. Mixed in first so the other controller mixins can
/// rely on its members.
mixin EditorCoreMixin on StateNotifier<EditorState> {
  /// Riverpod reference — carried by [EditorController] for future needs.
  Ref get ref;

  final IsarService _dbService = IsarService.instance;
  final _uuid = const Uuid();

  // Undo/Redo Stacks
  final List<HistoryEntry> _history = [];
  int _historyIndex = -1;

  // Debounce timer for auto-save to prevent 60 writes/sec during slider drags
  Timer? _autoSaveTimer;

  bool _isDisposed = false;

  /// Initialize the controller with a loaded project and reset the history stack
  void setProject(Project project) {
    LoggerService.instance.info('EditorController', 'Project "${project.name}" loaded into editor session. ID: ${project.projectId}. Words: ${project.words.length}');
    _history.clear();

    final clonedProject = _cloneProject(project);

    // Asynchronously verify video dimensions to repair legacy/incorrect dimensions (e.g. hardcoded 1920x1080 vertical videos)
    _verifyAndUpdateDimensions(clonedProject);

    // Initialize segments if missing (for legacy projects or newly created projects)
    if (clonedProject.segments == null || clonedProject.segments!.isEmpty) {
      final start = clonedProject.trimStart;
      final end = (clonedProject.trimEnd <= 0.0) ? clonedProject.duration : clonedProject.trimEnd;
      clonedProject.segments = [
        VideoSegmentSchema()
          ..start = start
          ..end = end > 0.2 ? end : 1.0
          ..isDeleted = false,
      ];
    }

    // Capture current references dynamically inside structural sharing memento
    final initialEntry = HistoryEntry(
      words: List<WordSchema>.from(clonedProject.words), // Structural sharing (shallow copy)
      config: _cloneConfig(clonedProject.config),
      trimStart: clonedProject.trimStart,
      trimEnd: clonedProject.trimEnd,
      segments: _cloneSegments(clonedProject.segments),
    );
    _history.add(initialEntry);
    _historyIndex = 0;

    state = EditorState(
      project: clonedProject,
      currentTime: 0.0,
      isPlaying: false,
      activeTab: EditorTab.caption,
      hasUnsavedChanges: false,
      revision: 1,
    );
  }

  // --- Playback Settings ---

  void setCurrentTime(double time) {
    state = state.copyWith(currentTime: time);
  }

  void setIsPlaying(bool playing) {
    state = state.copyWith(isPlaying: playing);
  }

  void setActiveTab(EditorTab tab) {
    if (tab == EditorTab.shortcuts) {
      if (state.activeTab != EditorTab.shortcuts) {
        state = state.copyWith(previousTab: state.activeTab, activeTab: tab);
      }
    } else {
      state = state.copyWith(activeTab: tab);
    }
  }

  void closeShortcuts() {
    if (state.activeTab == EditorTab.shortcuts) {
      state = state.copyWith(activeTab: state.previousTab);
    }
  }

  // --- Project Management ---

  /// Mark project status completed
  void markCompleted() {
    final project = state.project;
    if (project == null) return;

    final updated = _cloneProject(project);
    updated.status = 'completed';
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
    _autoSave();
  }

  /// Persist local changes to Isar database
  Future<void> saveProject() async {
    final project = state.project;
    if (project != null && _dbService.isInitialized) {
      LoggerService.instance.info('EditorController', 'Saving project "${project.name}" dynamically to database.');
      await _dbService.saveProject(project);
      if (_isDisposed) return;
      if (state.project?.projectId == project.projectId) {
        state = state.copyWith(hasUnsavedChanges: false);
      }
      LoggerService.instance.info('EditorController', 'Project "${project.name}" saved successfully.');
    }
  }

  void _autoSave() {
    _autoSaveTimer?.cancel();
    if (!SettingsService.instance.autoSaveEnabled) return;
    _autoSaveTimer = Timer(const Duration(seconds: 3), () async {
      final project = state.project;
      if (project != null && _dbService.isInitialized) {
        if (state.project?.projectId != project.projectId) return;
        LoggerService.instance.info('EditorController', 'Debounced auto-saving project "${project.name}"...');
        await _dbService.saveProject(project);
        if (_isDisposed) return;
        if (state.project?.projectId == project.projectId) {
          state = state.copyWith(hasUnsavedChanges: false);
        }
      }
    });
  }

  void resetCjkPrompt() {
    if (_isDisposed) return;
    state = state.copyWith(showCjkFontPrompt: false);
  }

  /// Increments the findReplaceCounter so WordPanel knows to open the Find & Replace dialog.
  /// Called by the Ctrl+F keyboard shortcut in EditorScreen.
  void triggerFindReplace() {
    if (_isDisposed) return;
    state = state.copyWith(findReplaceCounter: state.findReplaceCounter + 1);
    LoggerService.instance.action('EditorController', 'Find & Replace triggered via keyboard shortcut (counter: ${state.findReplaceCounter}).');
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoSaveTimer?.cancel();
    final project = state.project;
    // Fire-and-forget final save: only attempt if Isar is still open.
    // The IsarService.close() call in _cleanTeardownAndExit() runs concurrently
    // with Flutter's disposal, so we must check isInitialized to avoid
    // writing to an already-closed database instance.
    if (state.hasUnsavedChanges && project != null && _dbService.isInitialized) {
      LoggerService.instance.info('EditorController', 'Final save on dispose for project "${project.name}"...');
      unawaited(_dbService.saveProject(project));
    }
    WhisperService.instance.cancelActiveTranscription();
    super.dispose();
  }

  // --- Deep Cloning Helpers ---

  // FIX (Issue #1, CapStudio 1.0 audit): these 4 methods previously each
  // hand-duplicated the same field-by-field object cloning that also
  // existed independently in isar_service.dart and caption_engine.dart.
  // Bodies now delegate to core/utils/schema_clones.dart's single shared
  // implementation. Signatures are UNCHANGED on purpose — this method is
  // called from 30+ places in this file, so keeping the same name/shape
  // means none of those call sites need to change.
  //
  // _cloneProject's shallow-copy-of-words ("structural sharing") is
  // intentionally NOT delegated to SchemaClones.cloneProjectDeep (which
  // deep-clones every word) — this shallow behavior was specifically
  // verified safe during the audit (every word-mutating method in this
  // class clones-then-replaces rather than mutating a shared WordSchema in
  // place), and deep-cloning every word on every history entry would be
  // needlessly slow on a hot path (every edit).
  Project _cloneProject(Project p) {
    final clone = Project()
      ..id = p.id
      ..projectId = p.projectId
      ..name = p.name
      ..videoPath = p.videoPath
      ..duration = p.duration
      ..width = p.width
      ..height = p.height
      ..createdAt = p.createdAt
      ..trimStart = p.trimStart
      ..trimEnd = p.trimEnd
      ..status = p.status
      ..thumbnailPath = p.thumbnailPath
      ..config = _cloneConfig(p.config)
      ..words = List<WordSchema>.from(p.words) // Shallow copy for structural sharing — see class doc comment above
      ..segments = _cloneSegments(p.segments);
    return clone;
  }

  WordSchema _cloneWord(WordSchema w) => SchemaClones.cloneWord(w);

  ProjectConfigSchema _cloneConfig(ProjectConfigSchema c) => SchemaClones.cloneConfig(c);

  List<VideoSegmentSchema> _cloneSegments(List<VideoSegmentSchema>? source) {
    if (source == null) return [];
    return source.map(SchemaClones.cloneSegment).toList();
  }

  Future<void> _verifyAndUpdateDimensions(Project project) async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.environment.containsKey('FLUTTER_TEST')) {
      return; // Skip ffprobe verification on mobile, web, and tests — dimensions from DB are sufficient
    }

    try {
      final localFfprobe = p.join(
        p.dirname(SettingsService.instance.ffmpegCliPath ?? ''),
        Platform.isWindows ? 'ffprobe.exe' : 'ffprobe',
      );
      final ffprobePath = File(localFfprobe).existsSync() ? localFfprobe : 'ffprobe';

      final process = await Process.run(
        ffprobePath,
        [
          '-v', 'error',
          '-select_streams', 'v:0',
          '-show_entries', 'stream=width,height:stream_side_data=rotation:stream_tags=rotate',
          '-of', 'json',
          project.videoPath
        ],
      );
      if (_isDisposed) return;
      if (process.exitCode == 0) {
        final Map<String, dynamic> data = jsonDecode(process.stdout.toString()) as Map<String, dynamic>;
        final streams = data['streams'] as List<dynamic>?;

        int w = 1920;
        int h = 1080;
        int rotation = 0;

        if (streams != null && streams.isNotEmpty) {
          final stream = streams.first;
          w = stream['width'] as int? ?? 1920;
          h = stream['height'] as int? ?? 1080;

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
          final temp = w;
          w = h;
          h = temp;
        }

        if (project.width != w || project.height != h) {
          LoggerService.instance.log(LogLevel.warning, 'EditorController',
            'Project dimensions mismatch detected for ${project.name}. DB: ${project.width}x${project.height}, Real: ${w}x$h. Repairing database record...');

          final currentProject = state.project;
          if (currentProject != null && currentProject.projectId == project.projectId) {
            final updated = _cloneProject(currentProject);
            updated.width = w;
            updated.height = h;
            if (_dbService.isInitialized) {
              await _dbService.saveProject(updated);
              if (_isDisposed) return;
            }
            if (state.project?.projectId == project.projectId) {
              state = state.copyWith(project: updated, revision: state.revision + 1);
            }
          }
        }
      }
    } catch (e) {
      if (e is ProcessException) {
        LoggerService.instance.log(LogLevel.warning, 'EditorController',
            'ffprobe executable was not found in standard PATH or configured directories. '
            'Please install FFmpeg or configure its path in Settings to enable automatic video dimension verification. Detail: $e');
      } else {
        LoggerService.instance.log(LogLevel.error, 'EditorController', 'Failed to verify project dimensions: $e');
      }
    }
  }
}
