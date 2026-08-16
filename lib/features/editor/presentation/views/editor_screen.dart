import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../../../../core/utils/platform_utils.dart' as platform_utils;

import '../../../../app/theme.dart';
import '../../../../app/theme_provider.dart';
import '../../../../core/audio/audio_service.dart';
import '../../../../core/utils/premium_blur_dialog.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/video/video_relink_service.dart';
import '../../../../core/database/schemas/project.dart';
import '../../../../core/emoji/emoji_service.dart';
import '../../../../core/logger/logger_service.dart';
import '../../../../core/assets/asset_path_service.dart';
import '../../../../core/assets/asset_verification_service.dart';
import '../../domain/caption_engine.dart';
import '../controllers/editor_controller.dart';
import '../controllers/editor_state.dart';
import '../widgets/caption_overlay.dart';
import '../widgets/editor_sidebar.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/shortcuts_panel.dart';
import '../widgets/panels/export_panel.dart';
import '../widgets/editor_video_controls.dart';
import '../widgets/editor_header_bar.dart';
import '../widgets/editor_keyboard_hint_bar.dart';
import '../widgets/retranscribe_overlay_widget.dart';
import '../widgets/editor_keyboard_shortcuts.dart';
import '../widgets/editor_mobile_bottom_dock.dart';

class EditorScreen extends ConsumerStatefulWidget {
  final String projectId;
  const EditorScreen({super.key, required this.projectId});

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  // Media Kit Player variables
  Player? _player;
  VideoController? _videoController;
  
  // Flag to handle media kit init errors gracefully
  bool _playerInitFailed = false;
  String _playerInitError = '';

  // Timing tracking for SFX triggers
  double _lastSfxCheckTime = 0.0;
  final Set<String> _playedSfxWordIds = {};

  // Subscription to sync state changes back to video player
  ProviderSubscription<EditorState>? _editorStateSubscription;
  
  // Stream subscriptions for proper cleanup
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<int?>? _widthSubscription;
  StreamSubscription<int?>? _heightSubscription;



  // Re-transcribe progress status
  bool _isRetranscribing = false;
  double _retranscribeProgressVal = 0.0;
  String _retranscribeStatusText = '';

  // Custom fullscreen state
  bool _isFullscreen = false;
  bool _isCleaningUp = false;

  // Video controls auto-hide
  bool _controlsVisible = true;
  Timer? _controlsHideTimer;

  // Volume state
  double _volume = 1.0;
  bool _isMuted = false;
  double _playbackRate = 1.0;

  // Memoized chunks cache
  // FIX (Issue #4, CapStudio 1.0 audit): previously cached against a
  // hand-enumerated field hash (_computeProjectHash/_getWordHash), which
  // would silently return stale chunks if a future WordSchema/style field
  // affecting rendering was added but forgotten in the hash. EditorState's
  // `revision` counter is already verified (see audit) to be bumped on every
  // project mutation, so it's a strictly safer cache key — nothing to
  // remember to update when new fields are added.
  List<Chunk>? _cachedChunks;
  int _lastChunkRevision = -1;

  // Keyboard focus
  final FocusNode _keyboardFocusNode = FocusNode();


  // Desktop sidebar panel open state
  bool _desktopSidebarOpen = true;

  // Mobile sidebar bottom sheet state
  bool _mobileSidebarOpen = false;

  // Draggable/Resizable panel dimensions
  double _sidebarWidth = 440.0;
  double _timelineHeight = 130.0;
  double _portraitSidebarHeight = 220.0;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
    _loadProjectAndInitPlayer();
    _startControlsHideTimer();
  }

  void _startControlsHideTimer() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && ref.read(editorProvider).isPlaying) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  void _showControls() {
    setState(() {
      _controlsVisible = true;
    });
    _startControlsHideTimer();
  }

  Future<void> _loadProjectAndInitPlayer() async {
    try {
      // 1. Fetch project from Isar database (with retries for busy database handles)
      Project? project;
      int retries = 5;
      dynamic lastError;
      while (retries > 0) {
        try {
          if (!IsarService.instance.isInitialized) {
            await IsarService.instance.init();
          }
          project = await IsarService.instance.getProject(widget.projectId);
          break; // Success!
        } catch (e) {
          lastError = e;
          retries--;
          if (retries == 0) break;
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      }

      if (project == null) {
        setState(() {
          _playerInitFailed = true;
          _playerInitError = lastError != null 
              ? 'Database error: $lastError' 
              : 'Project not found in database.';
        });
        return;
      }

      final resolvedProject = project;

      // 2. Set project in Editor state manager
      ref.read(editorProvider.notifier).setProject(resolvedProject);

      // Ensure default SFX are generated and registered
      if (!kIsWeb) {
        try {
          final sfxDir = AssetPathService.instance.sfxDir;
          final sfxDirObj = Directory(sfxDir);
          if (!sfxDirObj.existsSync()) {
            sfxDirObj.createSync(recursive: true);
          }
          await AudioService.instance.ensureDefaultSfx(sfxDir);
        } catch (e) {
          LoggerService.instance.error('SFX generation failed', e.toString());
        }
      }
      if (!mounted) return;

      if (!EmojiService.instance.isLoaded) {
        final emojisDir = AssetPathService.instance.emojisDir;
        final metadataPath = p.join(emojisDir, 'metadata.json');
        await EmojiService.instance.loadMetadata(metadataPath, emojisDir);
      }
      if (!mounted) return;

      // 3. Validate video file exists
      if (!kIsWeb) {
        final videoFile = File(resolvedProject.videoPath);
        if (!await videoFile.exists()) {
          if (!mounted) return;
          setState(() {
            _playerInitFailed = true;
            _playerInitError = 'Video file not found:\n${resolvedProject.videoPath}\n\nThe file may have been moved or deleted.';
          });
          return;
        }
      }
      if (!mounted) return;

      // 4. Initialize media_kit Player
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
        // In tests, we do not initialize the real native media_kit Player to avoid native loading crashes.
      } else {
        final player = Player();
        final controller = VideoController(player);

        await player.open(Media(resolvedProject.videoPath), play: false);
        if (!mounted) return;
        await player.setVolume(_volume * 100);
        if (!mounted) return;

        // Listen to position stream to drive playback timelines
        _positionSubscription = player.stream.position.listen((pos) {
          final currentTime = pos.inMilliseconds / 1000.0;
          if (!mounted) return;

          final proj = ref.read(editorProvider).project;
          if (proj != null && proj.segments != null && proj.segments!.isNotEmpty) {
            double? nextActiveStart;
            bool currentIsDeleted = false;

            for (int i = 0; i < proj.segments!.length; i++) {
              final seg = proj.segments![i];
              final segStart = seg.start ?? 0.0;
              final segEnd = seg.end ?? 0.0;
              final isDel = seg.isDeleted ?? false;

              if (currentTime >= segStart && currentTime < segEnd) {
                if (isDel) {
                  currentIsDeleted = true;
                  for (int j = i + 1; j < proj.segments!.length; j++) {
                    final nextSeg = proj.segments![j];
                    if (!(nextSeg.isDeleted ?? false)) {
                      nextActiveStart = nextSeg.start;
                      break;
                    }
                  }
                  break;
                }
              }
            }

            if (currentIsDeleted) {
              if (nextActiveStart != null) {
                player.seek(Duration(milliseconds: (nextActiveStart * 1000).toInt()));
                ref.read(editorProvider.notifier).setCurrentTime(nextActiveStart);
              } else {
                player.seek(Duration.zero); // Reset to beginning if everything else is deleted
                ref.read(editorProvider.notifier).setCurrentTime(0.0);
              }
              return;
            }
          }

          ref.read(editorProvider.notifier).setCurrentTime(currentTime);
          _checkAndPlayWordSfx(currentTime);
        });

        // Listen to player playing stream
        _playingSubscription = player.stream.playing.listen((playing) {
          if (mounted) {
            ref.read(editorProvider.notifier).setIsPlaying(playing);
            if (playing) {
              _startControlsHideTimer();
            } else {
              _controlsHideTimer?.cancel();
              setState(() {
                _controlsVisible = true;
              });
            }
          }
        });

        _widthSubscription = player.stream.width.listen((w) {
          if (mounted) {
            _updateProjectDimensionsIfNecessary();
            setState(() {});
          }
        });
        _heightSubscription = player.stream.height.listen((h) {
          if (mounted) {
            _updateProjectDimensionsIfNecessary();
            setState(() {});
          }
        });

        if (!mounted) return;
        setState(() {
          _player = player;
          _videoController = controller;
        });
        await player.setRate(_playbackRate);
      }

      // 5. Setup state synchronization (seeks timeline -> seeks video)
      _editorStateSubscription = ref.listenManual<EditorState>(
        editorProvider,
        (previous, next) {
          if (next.project == null || _player == null) return;
          
          // Only seek player if currentTime actually changed (manual seek/scrub/jump)
          if (previous != null && 
              (next.currentTime - previous.currentTime).abs() > 0.02 &&
              !next.isPlaying) {
            final ms = (next.currentTime * 1000).toInt();
            _player?.seek(Duration(milliseconds: ms));
          }
        },
      );

    } catch (e) {
      LoggerService.instance.error('MediaKit', 'MediaKit initialization failed: $e');
      final errStr = e.toString().toLowerCase();
      String friendlyError;
      if (errStr.contains('libmpv') || errStr.contains('mpv')) {
        friendlyError = 'Video decoder (libmpv) not found.\nOn Windows: Download VC++ Runtime.\nOn Linux: Run "sudo apt install libmpv-dev"';
      } else if (errStr.contains('format') || errStr.contains('codec')) {
        friendlyError = 'Video format not supported.\nTry converting to MP4 H.264 first.';
      } else if (errStr.contains('permission')) {
        friendlyError = 'Permission denied reading video file.\nCheck file permissions.';
      } else {
        friendlyError = 'Video player failed: $e\n\nYou can still edit captions without preview.';
      }
      if (mounted) {
        setState(() {
          _playerInitFailed = true;
          _playerInitError = friendlyError;
        });
      }
    }
  }

  Future<void> _handleRelinkVideo(Project project) async {
    final selectedPath = await VideoRelinkService.instance.pickVideoFile();
    if (selectedPath == null || !mounted) return;

    setState(() {
      _playerInitError = 'Validating and relinking video file...';
    });

    final result = await VideoRelinkService.instance.validateAndRelink(
      project: project,
      newPath: selectedPath,
      onSave: () async {
        await IsarService.instance.saveProject(project);
      },
      onReload: (updatedProject) {
        ref.read(editorProvider.notifier).setProject(updatedProject);
      },
    );

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.warningMessage ?? 'Video relinked successfully!'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
      setState(() {
        _playerInitFailed = false;
        _playerInitError = '';
        _player = null;
        _videoController = null;
      });
      await _loadProjectAndInitPlayer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Failed to relink video.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() {
        _playerInitFailed = true;
        _playerInitError = result.errorMessage ?? 'Relink validation failed.';
      });
    }
  }

  /// Polyphonic Sound Effect Cross-check and Trigger
  void _checkAndPlayWordSfx(double currentTime) {
    final editorState = ref.read(editorProvider);
    final project = editorState.project;
    if (project == null || !editorState.isPlaying) return;

    // Reset check boundaries if user seeks backwards or jumps significantly
    if (currentTime < _lastSfxCheckTime || (currentTime - _lastSfxCheckTime).abs() > 0.5) {
      _lastSfxCheckTime = currentTime;
      _playedSfxWordIds.clear();
      return;
    }

    // Binary search for the first word starting at or after _lastSfxCheckTime
    int low = 0;
    int high = project.words.length - 1;
    int startIndex = project.words.length;

    while (low <= high) {
      final mid = (low + high) >> 1;
      final wordStart = project.words[mid].start ?? 0.0;
      if (wordStart >= _lastSfxCheckTime) {
        startIndex = mid;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    for (int i = startIndex; i < project.words.length; i++) {
      final word = project.words[i];
      final start = word.start ?? 0.0;
      if (start > currentTime) break; // Words are sorted by time; stop early
      final sfx = word.soundEffect;
      if (sfx != null && sfx.isNotEmpty && word.wordId != null) {
        if (!_playedSfxWordIds.contains(word.wordId)) {
          _playedSfxWordIds.add(word.wordId!);
          final sfxData = SfxData.parse(sfx, fallbackVolume: word.soundVolume ?? 100);
          if (sfxData.chunk != null) {
            AudioService.instance.playSfx(sfxData.chunk!.name, sfxData.chunk!.volume / 100.0);
          }
          if (sfxData.word != null) {
            AudioService.instance.playSfx(sfxData.word!.name, sfxData.word!.volume / 100.0);
          }
        }
      }
    }
    _lastSfxCheckTime = currentTime;
  }

  /// Memoized chunk building — only recompute when the project actually
  /// changed. Uses EditorState.revision (bumped on every project mutation —
  /// see editor_controller.dart) rather than a hand-enumerated field hash,
  /// so this can't silently go stale when new fields are added later.
  List<Chunk> _buildChunksMemoized(Project project, int revision) {
    if (revision == _lastChunkRevision && _cachedChunks != null) {
      return _cachedChunks!;
    }

    _cachedChunks = CaptionEngine.buildChunks(
      project.words,
      project.segments,
      project.trimStart,
      project.trimEnd,
      project.config.subs.chunkSize,
      project.config.subs.chunkLineMaxLength,
    );
    _lastChunkRevision = revision;
    return _cachedChunks!;
  }

  void _updateSystemUiMode() {
    if (kIsWeb) return;
    if (Platform.isAndroid || Platform.isIOS) {
      Future.microtask(() {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      });
    }
  }

  /// Stops and disposes the media player, handling the Windows mutex-crash
  /// workaround in one place.
  ///
  /// FIX (Issue #5, CapStudio 1.0 audit): this logic — including the
  /// Windows-specific workaround comment — was previously duplicated between
  /// [dispose] and [_cleanupAndExit]. [dispose] cannot be async (it's a
  /// synchronous Flutter framework override), so it calls this without
  /// awaiting (fire-and-forget, matching its pre-fix behavior);
  /// [_cleanupAndExit] awaits it so navigation only happens after cleanup
  /// finishes.
  Future<void> _disposePlayer(Player player, {bool withPause = false}) async {
    if (withPause) {
      try {
        await player.pause();
      } catch (_) {}
    }
    try {
      await player.stop();
    } catch (_) {}

    // On Windows, calling player.dispose() triggers a native std::mutex crash ("unlock of unowned mutex")
    // inside the precompiled media_kit DLL's VideoOutput destructor. Since player.stop() already
    // releases decoders, threads, and file handles, we bypass player.dispose() on Windows.
    if (kIsWeb || !Platform.isWindows) {
      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  Future<void> _cleanupAndExit() async {
    if (_isCleaningUp) return;
    if (mounted) {
      setState(() {
        _isCleaningUp = true;
      });
    }

    _controlsHideTimer?.cancel();
    _editorStateSubscription?.close();
    await _positionSubscription?.cancel();
    await _playingSubscription?.cancel();
    await _widthSubscription?.cancel();
    await _heightSubscription?.cancel();

    final playerToDispose = _player;
    if (playerToDispose != null) {
      await _disposePlayer(playerToDispose);
      _player = null;
      _videoController = null;
    }

    if (mounted) {
      context.go('/');
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    } else if (_isFullscreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    _editorStateSubscription?.close();
    _positionSubscription?.cancel();
    _playingSubscription?.cancel();
    _widthSubscription?.cancel();
    _heightSubscription?.cancel();
    _controlsHideTimer?.cancel();
    _keyboardFocusNode.dispose();
    // Halt player immediately to stop native texture/rendering threads
    // before unmounting the widget tree and releasing textures. dispose()
    // must stay synchronous, so this is intentionally not awaited.
    final playerToDispose = _player;
    if (playerToDispose != null) {
      unawaited(_disposePlayer(playerToDispose, withPause: true));
    }
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_player == null) return;
    if (ref.read(editorProvider).isPlaying) {
      await _player?.pause();
    } else {
      await _player?.play();
    }
  }

  void _seekRelative(double seconds) {
    final state = ref.read(editorProvider);
    final project = state.project;
    if (project == null) return;
    final newTime = (state.currentTime + seconds).clamp(0.0, project.duration);
    ref.read(editorProvider.notifier).setCurrentTime(newTime);
    _player?.seek(Duration(milliseconds: (newTime * 1000).toInt()));
  }

  void _setVolume(double vol) {
    setState(() {
      _volume = vol.clamp(0.0, 1.0);
      _isMuted = _volume == 0;
    });
    _player?.setVolume(_volume * 100);
  }

  void _toggleMute() {
    if (_isMuted) {
      _setVolume(_volume > 0 ? _volume : 1.0);
    } else {
      setState(() {
        _isMuted = true;
      });
      _player?.setVolume(0);
    }
  }

  void _toggleFullscreenMode(double aspectRatio) {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          if (aspectRatio > 1.0) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
          } else {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]);
          }
        }
      } else {
        SystemChrome.setEnabledSystemUIMode(!kIsWeb && (Platform.isAndroid || Platform.isIOS)
            ? SystemUiMode.immersiveSticky
            : SystemUiMode.edgeToEdge);
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
      }
    });
  }



  Future<void> _handleSave() async {
    await ref.read(editorProvider.notifier).saveProject();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project saved successfully.'), duration: Duration(seconds: 1)),
      );
    }
  }

  void _showExportDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) {
        return PremiumBlurDialog(
          maxWidth: 520,
          borderOpacity: 0.12,
          useScrollView: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Dialog Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.rocket_launch, size: 20, color: AppTheme.accentOrange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'EXPORT PROJECT',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: AppTheme.primaryText,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 16),
              // Dialog Body containing the Export Panel settings
              const Flexible(
                child: ExportPanel(),
              ),
            ],
          ),
        );
      },
    );
  }



  double _getAspectRatio(Project project) {
    if (_videoController != null) {
      final w = _videoController!.player.state.width;
      final h = _videoController!.player.state.height;
      if (w != null && h != null && w > 0 && h > 0) {
        return w / h;
      }
    }
    if (project.width > 0 && project.height > 0) {
      return project.width / project.height;
    }
    return 16 / 9; // Fallback
  }

  Future<void> _updateProjectDimensionsIfNecessary() async {
    final player = _player;
    if (player == null) return;
    final w = player.state.width;
    final h = player.state.height;
    if (w == null || h == null || w <= 0 || h <= 0) return;

    final proj = ref.read(editorProvider).project;
    if (proj == null) return;

    if (proj.width != w || proj.height != h) {
      LoggerService.instance.log(
        LogLevel.info,
        'EditorScreen',
        'Correcting project dimensions in database to match media player: $w x $h',
      );
      proj.width = w;
      proj.height = h;
      await IsarService.instance.saveProject(proj);
      ref.read(editorProvider.notifier).setProject(proj);
    }
  }

  @override
  Widget build(BuildContext context) {
    _updateSystemUiMode();
    // Watch the project's revision counter to force rebuild when captions,
    // styles, trim boundaries, or highlight settings change. Otherwise, since
    // the Project reference is mutated in-place, the outer build() would
    // never rebuild, leading to a stale chunks list in the video viewport.
    final revision = ref.watch(editorProvider.select((s) => s.revision));



    final project = ref.watch(editorProvider.select((s) => s.project));
    final activeTab = ref.watch(editorProvider.select((s) => s.activeTab));
    final verification = ref.watch(assetVerificationProvider);
    final theme = ref.watch(themeProvider);

    if (project == null) {
      if (_playerInitFailed) {
        return Scaffold(
          backgroundColor: AppTheme.cardBg,
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassDecoration(
                color: Colors.black12,
                borderRadius: 16,
                borderOpacity: 0.08,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to initialize media player',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _playerInitError,
                    style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      context.go('/');
                    },
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: const Text('Back to Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return Scaffold(
        body: Center(child: CircularProgressIndicator(color: theme.accentOrange)),
      );
    }

    final chunks = _buildChunksMemoized(project, revision);
    final aspectRatio = _getAspectRatio(project);
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactWidth = screenWidth < 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    if (_isFullscreen) {
      return _buildFullscreenMode(project, chunks, aspectRatio);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _cleanupAndExit();
      },
      child: EditorKeyboardShortcuts(
      focusNode: _keyboardFocusNode,
      player: _player,
      togglePlayback: _togglePlayback,
      handleSave: _handleSave,
      seekRelative: _seekRelative,
      isFullscreen: _isFullscreen,
      onFullscreenChanged: (val) {
        _toggleFullscreenMode(aspectRatio);
      },
      mobileSidebarOpen: _mobileSidebarOpen,
      onMobileSidebarOpenChanged: (val) => setState(() => _mobileSidebarOpen = val),
      desktopSidebarOpen: _desktopSidebarOpen,
      onDesktopSidebarOpenChanged: (val) => setState(() => _desktopSidebarOpen = val),
      child: GestureDetector(
        onTap: () => _keyboardFocusNode.requestFocus(),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              // Glowing Ambient background gradients
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: GlowingBackgroundPainter(
                      primaryGlow: theme.accentOrange,
                      secondaryGlow: theme.accentCyan,
                      devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
                    ),
                  ),
                ),
              ),
              // Main layout
              Column(
                children: [
                  // Top Header Bar
                  _buildHeaderBar(project, isCompactWidth),

                  // Middle Viewport / Timeline / Sidebar layout
                  Expanded(
                    child: isLandscape
                        ? _buildLandscapeLayout(project, chunks, aspectRatio, verification)
                        : _buildPortraitLayout(project, chunks, aspectRatio, verification),
                  ),

                  // Keyboard hint bar — desktop only
                  if (platform_utils.isDesktop) _buildKeyboardHintBar(),
                ],
              ),



              // Re-transcribe overlay
              if (_isRetranscribing) _buildRetranscribeOverlay(),

              // Shortcuts overlay
              if (activeTab == EditorTab.shortcuts) const ShortcutsPanel(),

              // Closing session overlay
              if (_isCleaningUp)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.65),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: theme.accentOrange),
                          const SizedBox(height: 16),
                          const Text(
                            'Closing editor session...',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),

          // Mobile bottom navigation dock
          bottomNavigationBar: !isLandscape
              ? EditorMobileBottomDock(
                  mobileSidebarOpen: _mobileSidebarOpen,
                  onMobileSidebarOpenChanged: (val) => setState(() => _mobileSidebarOpen = val),
                )
              : null,
        ),
      ),
    ),
  );
  }

  // --- FULLSCREEN MODE ---
  Widget _buildFullscreenMode(Project project, List<Chunk> chunks, double aspectRatio) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: MouseRegion(
        onHover: (_) => _showControls(),
        child: GestureDetector(
          onTap: _togglePlayback,
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: _videoController != null
                      ? AspectRatio(
                          aspectRatio: aspectRatio,
                          child: Stack(
                            children: [
                              Video(controller: _videoController!, controls: null),
                              Consumer(
                                builder: (context, ref, child) {
                                  final currentTime = ref.watch(editorProvider.select((s) => s.currentTime));
                                    return CaptionOverlay(
                                      chunks: chunks,
                                      currentTime: currentTime,
                                      config: project.config,
                                      scale: 1.8,
                                      videoWidth: project.width.toDouble(),
                                      videoHeight: project.height.toDouble(),
                                      isControlsVisible: _controlsVisible,
                                    );
                                }
                              ),
                            ],
                          ),
                        )
                      : CircularProgressIndicator(color: AppTheme.accentOrange),
                ),
              ),
              if (_controlsVisible)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: _buildVideoControls(project: project, isFullscreen: true),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HEADER BAR ---
  Widget _buildHeaderBar(Project project, bool isCompactWidth) {
    final headerBar = EditorHeaderBar(
      project: project,
      isCompactWidth: isCompactWidth,
      desktopSidebarOpen: _desktopSidebarOpen,
      onToggleSidebar: () {
        setState(() {
          _desktopSidebarOpen = !_desktopSidebarOpen;
        });
      },
      onSave: _handleSave,
      onExport: _showExportDialog,
      onBack: _cleanupAndExit,
    );

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      return SafeArea(
        bottom: false,
        child: headerBar,
      );
    }
    return headerBar;
  }

  // --- LANDSCAPE LAYOUT (side-by-side, resizable) ---
  Widget _buildLandscapeLayout(Project project, List<Chunk> chunks, double aspectRatio, AssetVerificationResult verification) {
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isMobileDevice = platform_utils.isMobile || shortestSide < 600;
    final effectiveTimelineHeight = isMobileDevice ? 85.0 : _timelineHeight;

    return Row(
      children: [
        // Left area: Video Player + Timeline
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: _buildVideoViewport(project, chunks, aspectRatio, verification),
              ),
              // Horizontal Resizable Divider (Video <-> Timeline)
              if (!isMobileDevice)
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _timelineHeight = (_timelineHeight - details.delta.dy).clamp(80.0, 250.0);
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpDown,
                    child: Container(
                      height: 12,
                      color: Colors.transparent,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                          Container(
                            width: 24,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              SizedBox(
                height: effectiveTimelineHeight,
                child: Consumer(
                  builder: (context, ref, child) {
                    final currentTime = ref.watch(editorProvider.select((s) => s.currentTime));
                    return TimelineWidget(
                      words: project.words,
                      currentTime: currentTime,
                      duration: project.duration,
                      trimStart: project.trimStart,
                      trimEnd: project.trimEnd,
                      segments: project.segments,
                    );
                  }
                ),
              ),
            ],
          ),
        ),
        // Right area: Sidebar panel (resizable)
        if (_desktopSidebarOpen) ...[
          // Vertical Resizable Divider (Timeline/Video <-> Sidebar)
          Builder(
            builder: (context) {
              final double screenWidth = MediaQuery.of(context).size.width;
              final shortestSide = MediaQuery.of(context).size.shortestSide;
              final isMobileDevice = platform_utils.isMobile || shortestSide < 600;
              final maxRatio = isMobileDevice ? 0.45 : 0.7;
              final double minSidebarWidth = isMobileDevice ? 320.0 : 420.0;
              final double maxSidebarWidth = (screenWidth - (isMobileDevice ? 320.0 : 240.0)).clamp(minSidebarWidth, screenWidth * maxRatio);

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _sidebarWidth = (_sidebarWidth - details.delta.dx).clamp(minSidebarWidth, maxSidebarWidth);
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: Container(
                    width: 12,
                    color: Colors.transparent,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(width: 1, color: Colors.white.withValues(alpha: 0.08)),
                        Container(
                          width: 3,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.24),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
          ),
          Builder(
            builder: (context) {
              final double screenWidth = MediaQuery.of(context).size.width;
              final shortestSide = MediaQuery.of(context).size.shortestSide;
              final isMobileDevice = platform_utils.isMobile || shortestSide < 600;
              final maxRatio = isMobileDevice ? 0.45 : 0.7;
              final double minSidebarWidth = isMobileDevice ? 320.0 : 420.0;
              final double maxSidebarWidth = (screenWidth - (isMobileDevice ? 320.0 : 240.0)).clamp(minSidebarWidth, screenWidth * maxRatio);
              final double effectiveSidebarWidth = _sidebarWidth.clamp(minSidebarWidth, maxSidebarWidth);

              return SizedBox(
                width: effectiveSidebarWidth,
                child: EditorSidebar(
                  onRetranscribe: executeRetranscribe,
                ),
              );
            }
          ),
        ],
      ],
    );
  }

  // --- PORTRAIT LAYOUT (embedded, resizable, no overlays) ---
  Widget _buildPortraitLayout(Project project, List<Chunk> chunks, double aspectRatio, AssetVerificationResult verification) {
    return Consumer(
      builder: (context, ref, child) {
        final activeTab = ref.watch(editorProvider.select((s) => s.activeTab));
        final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

        return Column(
          children: [
            // Video viewport (takes remaining space)
            Expanded(
              child: _buildVideoViewport(project, chunks, aspectRatio, verification),
            ),
            if (!isKeyboardOpen) ...[
              // Horizontal Divider 1 (Video <-> Timeline)
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (details) {
                  setState(() {
                    _timelineHeight = (_timelineHeight - details.delta.dy).clamp(80.0, 220.0);
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeUpDown,
                  child: Container(
                    height: 12,
                    color: Colors.transparent,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                        Container(
                          width: 24,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.24),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Timeline
              SizedBox(
                height: _timelineHeight,
                child: Consumer(
                  builder: (context, ref, child) {
                    final currentTime = ref.watch(editorProvider.select((s) => s.currentTime));
                    return TimelineWidget(
                      words: project.words,
                      currentTime: currentTime,
                      duration: project.duration,
                      trimStart: project.trimStart,
                      trimEnd: project.trimEnd,
                      segments: project.segments,
                    );
                  }
                ),
              ),
            ],
            // Embedded Sidebar (only if open!)
            if (_mobileSidebarOpen) ...[
              if (!isKeyboardOpen) ...[
                // Horizontal Divider 2 (Timeline <-> Sidebar Panel)
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _portraitSidebarHeight = (_portraitSidebarHeight - details.delta.dy).clamp(120.0, 360.0);
                    });
                  },
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpDown,
                    child: Container(
                      height: 12,
                      color: Colors.transparent,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
                          Container(
                            width: 24,
                            height: 3,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.24),
                              borderRadius: BorderRadius.circular(1.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              SizedBox(
                height: isKeyboardOpen ? _portraitSidebarHeight.clamp(120.0, 200.0) : _portraitSidebarHeight,
                child: Container(
                  decoration: AppTheme.glassDecoration(
                    color: AppTheme.cardBg.withValues(alpha: 0.55),
                    borderRadius: 0,
                    borderOpacity: 0.0,
                  ).copyWith(
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Panel title + close button
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                {
                                  EditorTab.caption: 'CAPTION EDITOR',
                                  EditorTab.style: 'THEME & STYLE',
                                  EditorTab.transcription: 'TRANSCRIPTION & STT',
                                  EditorTab.debug: 'SYSTEM LOGS',
                                  EditorTab.export: 'EXPORT SETTINGS',
                                }[activeTab] ?? 'EDITOR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.mutedText,
                                  letterSpacing: 2,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () => setState(() => _mobileSidebarOpen = false),
                            ),
                          ],
                        ),
                      ),
                      const Divider(color: Colors.white10, height: 1),
                      // Sidebar Tab Content
                      Expanded(
                        child: EditorSidebar(
                          onRetranscribe: executeRetranscribe,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      }
    );
  }

  Widget _buildVideoViewport(Project project, List<Chunk> chunks, double aspectRatio, AssetVerificationResult verification) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final shortestSide = MediaQuery.of(context).size.shortestSide;
    final isMobileDevice = platform_utils.isMobile || shortestSide < 600;
    final marginVal = isMobileDevice ? (isLandscape ? 4.0 : 8.0) : 12.0;

    return MouseRegion(
      onHover: (_) => _showControls(),
      child: Container(
        margin: EdgeInsets.all(marginVal),
        decoration: AppTheme.glassDecoration(
          color: Colors.black, // Solid black to merge seamlessly with video player background
          borderRadius: 12,
          borderOpacity: 0.08,
          showGradient: false, // Prevent gradient transparency from showing glow through card
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Video Surface
              Expanded(
                child: Center(
                  child: _videoController != null
                      ? GestureDetector(
                          onTap: _togglePlayback,
                          child: AspectRatio(
                            aspectRatio: aspectRatio,
                            child: Stack(
                              children: [
                                Video(controller: _videoController!, controls: null),
                                Consumer(
                                  builder: (context, ref, child) {
                                    // Watch BOTH currentTime AND config so any style change
                                    // (font, color, animation, stroke, position) immediately
                                    // rebuilds the CaptionOverlay without waiting for a position tick.
                                    final currentTime = ref.watch(editorProvider.select((s) => s.currentTime));
                                    final config = ref.watch(editorProvider.select((s) => s.project?.config));
                                    if (config == null) return const SizedBox.shrink();
                                    return CaptionOverlay(
                                      chunks: chunks,
                                      currentTime: currentTime,
                                      config: config,
                                      scale: 1.2,
                                      allowDrag: true,
                                      isControlsVisible: _controlsVisible,
                                      onPositionChanged: (newTop) {
                                        ref.read(editorProvider.notifier).updateCaptionTop(newTop);
                                      },
                                      onDragEnd: () {
                                        ref.read(editorProvider.notifier).commitHistoryAndSave();
                                      },
                                      videoWidth: project.width.toDouble(),
                                      videoHeight: project.height.toDouble(),
                                    );
                                  }
                                ),
                              ],
                            ),
                          ),
                        )
                      : _playerInitFailed
                          ? Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Center(
                                child: SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.broken_image_outlined, size: 36, color: Colors.redAccent),
                                      const SizedBox(height: 8),
                                      Text(
                                        _playerInitError,
                                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.link, size: 14),
                                        label: const Text('RELINK VIDEO FILE', style: TextStyle(fontSize: 12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.accentOrange,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: () async {
                                          await _handleRelinkVideo(project);
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : CircularProgressIndicator(color: AppTheme.accentOrange),
                ),
              ),
              
              // Video Controls bar
              if (_controlsVisible)
                _buildVideoControls(project: project),
            ],
          ),
        ),
      ),
    );
  }

  // --- VIDEO CONTROLS (seek bar, play/pause, volume, fullscreen) ---
  Widget _buildVideoControls({required Project project, bool isFullscreen = false}) {
    return Consumer(
      builder: (context, ref, child) {
        final currentTime = ref.watch(editorProvider.select((s) => s.currentTime));
        final isPlaying = ref.watch(editorProvider.select((s) => s.isPlaying));
        return EditorVideoControls(
          project: project,
          currentTime: currentTime,
          isPlaying: isPlaying,
          volume: _volume,
          isMuted: _isMuted,
          playbackRate: _playbackRate,
          isFullscreen: isFullscreen,
          onTogglePlayback: _togglePlayback,
          onSeek: (val) {
            ref.read(editorProvider.notifier).setCurrentTime(val);
          },
          onSeekEnd: (val) {
            _player?.seek(Duration(milliseconds: (val * 1000).toInt()));
          },
          onToggleMute: _toggleMute,
          onSetVolume: _setVolume,
          onPlaybackRateChanged: (rate) {
            setState(() {
              _playbackRate = rate;
            });
            _player?.setRate(rate);
          },
          onToggleFullscreen: () {
            _toggleFullscreenMode(_getAspectRatio(project));
          },
        );
      }
    );
  }



  // --- KEYBOARD HINT BAR ---
  Widget _buildKeyboardHintBar() {
    return const EditorKeyboardHintBar();
  }



  Widget _buildRetranscribeOverlay() {
    return RetranscribeOverlayWidget(
      statusText: _retranscribeStatusText,
      progressValue: _retranscribeProgressVal,
    );
  }

  Future<void> executeRetranscribe({
    required bool useMock,
    String? language,
    String? whisperCliPath,
    String? whisperModelPath,
    String? ffmpegCliPath,
    bool? useVad,
    double? vadThreshold,
    bool? translate,
  }) async {
    setState(() {
      _isRetranscribing = true;
      _retranscribeProgressVal = 0.0;
      _retranscribeStatusText = 'Preparing transcription...';
    });

    final success = await ref.read(editorProvider.notifier).retranscribe(
      useMock: useMock,
      language: language,
      whisperCliPath: whisperCliPath,
      whisperModelPath: whisperModelPath,
      ffmpegCliPath: ffmpegCliPath,
      useVad: useVad,
      vadThreshold: vadThreshold,
      translate: translate,
      onProgress: (progress, status) {
        if (mounted) {
          setState(() {
            _retranscribeProgressVal = progress;
            _retranscribeStatusText = status;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _isRetranscribing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Re-transcription successful!' : 'Re-transcription failed.'),
          backgroundColor: success ? AppTheme.accentGreen : Colors.redAccent,
        ),
      );
      
      if (success && _player != null) {
        unawaited(_player!.seek(Duration.zero));
      }
    }
  }


}

