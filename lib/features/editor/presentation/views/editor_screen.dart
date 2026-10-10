import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
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
import '../../../../core/video/video_web_helper.dart';
import '../../../../core/video/video_proxy_service.dart';
import '../../../../core/database/schemas/project.dart';
import '../../../../core/emoji/emoji_service.dart';
import '../../../../core/logger/logger_service.dart';
import '../../../../core/assets/asset_path_service.dart';
import '../../../../core/assets/asset_verification_service.dart';
import '../../domain/caption_engine.dart';
import '../controllers/editor_controller.dart';
import '../controllers/editor_state.dart';
import '../widgets/caption_overlay.dart';
import '../widgets/b_roll_overlay.dart';
import '../widgets/retention_progress_bar_overlay.dart';
import '../widgets/safe_zone_overlay.dart';
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
import '../../../../l10n/app_localizations.dart';

part 'editor_screen_layout.dart';

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
  StreamSubscription<Duration>? _durationSubscription;

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

  // Volume and proxy state
  double _volume = 1.0;
  bool _isMuted = false;
  double _playbackRate = 1.0;
  bool _isSwitchingProxy = false;

  // Memoized chunks cache
  List<Chunk>? _cachedChunks;
  int _lastChunkRevision = -1;

  // Keyboard focus
  final FocusNode _keyboardFocusNode = FocusNode();

  // Desktop sidebar panel open state
  bool _desktopSidebarOpen = true;

  // Mobile sidebar bottom sheet state
  bool _mobileSidebarOpen = false;

  // Draggable/Resizable panel dimensions
  double _sidebarWidth = 528.0;
  double _timelineHeight = 184.0;
  double _portraitSidebarHeight = 240.0;

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
      _updateSystemUiMode();
    }
    _loadProjectAndInitPlayer();
    _startControlsHideTimer();
  }

  void _startControlsHideTimer() {
    _controlsHideTimer?.cancel();
    _controlsHideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _controlsVisible && (_player?.state.playing ?? false)) {
        setState(() {
          _controlsVisible = false;
        });
      }
    });
  }

  void _updateLayout(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
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
      Object? lastError;
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

        final initialProxy = ref.read(editorProvider).isProxyActive;
        final proxyPath = VideoProxyService.instance.getProxyPath(
          resolvedProject.projectId,
          resolvedProject.videoPath,
        );
        final shouldUseProxy = initialProxy && !kIsWeb && File(proxyPath).existsSync();
        final mediaPath = kIsWeb
            ? resolveWebVideoUrl(resolvedProject.videoPath)
            : (shouldUseProxy ? proxyPath : resolvedProject.videoPath);
        await player.open(Media(mediaPath), play: false);
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
                // If there are no subsequent active segments, pause player at end of last active segment
                player.pause();
                double lastActiveEnd = 0.0;
                for (final seg in (proj.segments ?? <VideoSegmentSchema>[])) {
                  if (seg.isDeleted != true && seg.end != null) {
                    lastActiveEnd = math.max(lastActiveEnd, seg.end!);
                  }
                }
                player.seek(Duration(milliseconds: (lastActiveEnd * 1000).toInt()));
                ref.read(editorProvider.notifier).setCurrentTime(lastActiveEnd);
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
        _durationSubscription = player.stream.duration.listen((dur) {
          if (dur > Duration.zero && mounted) {
            _updateProjectDurationIfNecessary();
          }
        });

        if (!mounted) return;
        setState(() {
          _player = player;
          _videoController = controller;
        });
        await player.setRate(_playbackRate);
      }

      // 5. Setup state synchronization (seeks timeline -> seeks video, proxy switches)
      _editorStateSubscription = ref.listenManual<EditorState>(
        editorProvider,
        (previous, next) {
          if (next.project == null || _player == null) return;
          
          if (previous != null && previous.isProxyActive != next.isProxyActive) {
            _switchPlaybackMedia(next.project!, next.isProxyActive, next.currentTime);
          }

          // Only seek player if currentTime actually changed (manual seek/scrub/jump)
          if (previous != null && 
              (next.currentTime - previous.currentTime).abs() > 0.02 &&
              !next.isPlaying) {
            final ms = (next.currentTime * 1000).toInt();
            _player?.seek(Duration(milliseconds: ms));
          }

          // Sync programmatic play/pause requests from state
          if (previous != null && previous.isPlaying != next.isPlaying) {
            if (next.isPlaying && !(_player?.state.playing ?? false)) {
              _player?.play();
            } else if (!next.isPlaying && (_player?.state.playing ?? false)) {
              _player?.pause();
            }
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
    final l10n = AppLocalizations.of(context);

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.warningMessage ?? (l10n?.videoRelinkedSuccess ?? 'Video relinked successfully!')),
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
          content: Text(result.errorMessage ?? (l10n?.errorRelinkVideoFailed ?? 'Failed to relink video.')),
          backgroundColor: AppTheme.accentRed,
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

    // Verify words are sorted by start time
    bool isSorted = true;
    for (int i = 0; i < project.words.length - 1; i++) {
      if ((project.words[i].start ?? 0.0) > (project.words[i + 1].start ?? 0.0)) {
        isSorted = false;
        break;
      }
    }

    if (!isSorted) {
      for (final word in project.words) {
        final start = word.start ?? 0.0;
        if (start >= _lastSfxCheckTime && start <= currentTime) {
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
      }
      _lastSfxCheckTime = currentTime;
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

  /// Stops and disposes the media player, handling Windows mutex bypass.
  Future<void> _disposePlayer(Player player, {bool withPause = false}) async {
    if (withPause) {
      try { await player.pause(); } catch (e) { LoggerService.instance.debug('Player pause error: $e'); }
    }
    try { await player.stop(); } catch (e) { LoggerService.instance.debug('Player stop error: $e'); }

    // Bypass player.dispose() on Windows to prevent native precompiled DLL mutex crash.
    if (kIsWeb || !Platform.isWindows) {
      try { await player.dispose(); } catch (e) { LoggerService.instance.debug('Player dispose error: $e'); }
    }
  }

  Future<void> _cleanupAndExit() async {
    if (_isCleaningUp) return;
    if (mounted) setState(() => _isCleaningUp = true);

    _controlsHideTimer?.cancel();
    _editorStateSubscription?.close();
    await _positionSubscription?.cancel();
    await _playingSubscription?.cancel();
    await _widthSubscription?.cancel();
    await _heightSubscription?.cancel();
    await _durationSubscription?.cancel();

    final playerToDispose = _player;
    if (playerToDispose != null) {
      await _disposePlayer(playerToDispose);
      _player = null;
      _videoController = null;
    }
    if (mounted) context.go('/');
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
    _durationSubscription?.cancel();
    _controlsHideTimer?.cancel();
    _keyboardFocusNode.dispose();
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
    final l10n = AppLocalizations.of(context);
    await ref.read(editorProvider.notifier).saveProject();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.projectSavedSuccess ?? 'Project saved successfully.'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  double _getAspectRatio(Project project) {
    if (project.width > 0 && project.height > 0) {
      return project.width / project.height;
    }
    if (_videoController != null) {
      final w = _videoController!.player.state.width;
      final h = _videoController!.player.state.height;
      if (w != null && h != null && w > 0 && h > 0) return w / h;
    }
    final nameOrPath = '${project.name} ${project.videoPath}'.toLowerCase();
    if (nameOrPath.contains('portrait') || nameOrPath.contains('protrait')) {
      return 9 / 16;
    }
    return 16 / 9;
  }

  Future<void> _updateProjectDimensionsIfNecessary() async {
    final player = _player;
    if (player == null) return;
    final w = player.state.width;
    final h = player.state.height;
    if (w == null || h == null || w <= 0 || h <= 0) return;

    final proj = ref.read(editorProvider).project;
    if (proj == null) return;
    // Preserve 9:16 vertical canvas dimensions for forked shorts & vertical projects
    if (proj.width > 0 && proj.height > 0 && proj.width < proj.height) return;

    if (proj.width != w || proj.height != h) {
      LoggerService.instance.log(LogLevel.info, 'EditorScreen',
          'Correcting project dimensions to media player: $w x $h');
      ref.read(editorProvider.notifier).updateDimensions(w, h);
    }
  }

  Future<void> _updateProjectDurationIfNecessary() async {
    final player = _player;
    if (player == null) return;
    final dur = player.state.duration;
    if (dur <= Duration.zero) return;
    final durSeconds = dur.inMilliseconds / 1000.0;
    if (durSeconds <= 0.1) return;

    final proj = ref.read(editorProvider).project;
    if (proj == null) return;
    if ((proj.duration - durSeconds).abs() > 0.1) {
      LoggerService.instance.log(LogLevel.info, 'EditorScreen',
          'Correcting project duration to media player: ${durSeconds.toStringAsFixed(2)}s (was ${proj.duration.toStringAsFixed(2)}s)');
      ref.read(editorProvider.notifier).updateDuration(durSeconds);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the project's revision counter to force rebuild when captions,
    // styles, trim boundaries, or highlight settings change. Otherwise, since
    // the Project reference is mutated in-place, the outer build() would
    // never rebuild, leading to a stale chunks list in the video viewport.
    final revision = ref.watch(editorProvider.select((s) => s.revision));
    final project = ref.watch(editorProvider.select((s) => s.project));
    final activeTab = ref.watch(editorProvider.select((s) => s.activeTab));
    final verification = ref.watch(assetVerificationProvider);
    final theme = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);

    if (project == null) {
      if (_playerInitFailed) {
        return Scaffold(
          backgroundColor: AppTheme.cardBg,
          body: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(24),
              decoration: AppTheme.glassDecoration(
                color: AppTheme.cardBgElevated,
                borderRadius: 16,
                borderOpacity: 0.08,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline_rounded, color: AppTheme.accentRed, size: 48),
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
                      foregroundColor: AppTheme.onAccentText,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      context.go('/');
                    },
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: Text(l10n?.btnBack ?? 'Back to Dashboard', style: const TextStyle(fontWeight: FontWeight.bold)),
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
      onExport: _showExportDialog,
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
                    color: AppTheme.surfaceDim.withValues(alpha: 0.75),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: theme.accentOrange),
                          const SizedBox(height: 16),
                          Text(
                            'Closing editor session...',
                            style: TextStyle(color: AppTheme.primaryText, fontSize: 13, fontWeight: FontWeight.bold),
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
    final l10n = AppLocalizations.of(context);
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
          content: Text(success
              ? (l10n?.retranscriptionSuccess ?? 'Re-transcription successful!')
              : (l10n?.retranscriptionFailed ?? 'Re-transcription failed.')),
          backgroundColor: success ? AppTheme.accentGreen : AppTheme.accentRed,
        ),
      );
      
      if (success && _player != null) {
        unawaited(_player!.seek(Duration.zero));
      }
    }
  }


}

