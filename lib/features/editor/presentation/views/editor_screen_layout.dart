part of 'editor_screen.dart';

extension _EditorScreenLayout on _EditorScreenState {
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
                              Positioned.fill(
                                child: Consumer(
                                  builder: (context, ref, child) {
                                    final currentTime = ref.watch(editorProvider.select((s) => s.currentTime));
                                    final retentionConfig = ref.watch(editorProvider.select((s) => s.retentionBarConfig));
                                    final safeZone = ref.watch(editorProvider.select((s) => s.safeZoneGuide));
                                    final bRollClips = ref.watch(editorProvider.select((s) => s.bRollClips));
                                    return Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        BRollOverlay(
                                          currentTime: currentTime,
                                          bRollClips: bRollClips,
                                          videoWidth: project.width.toDouble(),
                                          videoHeight: project.height.toDouble(),
                                        ),
                                        SafeZoneOverlay(
                                          platform: safeZone,
                                          videoWidth: project.width.toDouble(),
                                          videoHeight: project.height.toDouble(),
                                        ),
                                        RetentionProgressBarOverlay(
                                          currentTime: currentTime,
                                          duration: project.duration,
                                          config: retentionConfig,
                                          scale: 1.8,
                                        ),
                                        CaptionOverlay(
                                          chunks: chunks,
                                          currentTime: currentTime,
                                          config: project.config,
                                          scale: 1.8,
                                          videoWidth: project.width.toDouble(),
                                          videoHeight: project.height.toDouble(),
                                          isControlsVisible: _controlsVisible,
                                        ),
                                      ],
                                    );
                                  },
                                ),
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
        _updateLayout(() {
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

  void _showExportDialog() {
    showDialog<void>(
      context: context,
      barrierColor: AppTheme.isLight ? Colors.black54 : Colors.black87,
      builder: (context) {
        final screenHeight = MediaQuery.of(context).size.height;
        final maxDialogHeight = (screenHeight * 0.88).clamp(320.0, 720.0);
        return PremiumBlurDialog(
          maxWidth: 520,
          borderOpacity: 0.12,
          useScrollView: false,
          child: SizedBox(
            height: maxDialogHeight,
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
                      icon: Icon(Icons.close, size: 20, color: AppTheme.secondaryText),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                Divider(color: AppTheme.dividerColor, height: 16),
                // Dialog Body containing the Export Panel settings
                const Expanded(
                  child: ExportPanel(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- LANDSCAPE LAYOUT (side-by-side, resizable) ---
  Widget _buildLandscapeLayout(Project project, List<Chunk> chunks, double aspectRatio, AssetVerificationResult verification) {
    final screenHeight = MediaQuery.of(context).size.height;
    final minTimelineH = (screenHeight < 600) ? 120.0 : 150.0;
    final maxTimelineH = (screenHeight * 0.42).clamp(minTimelineH, 380.0);
    final effectiveTimelineHeight = _timelineHeight.clamp(minTimelineH, maxTimelineH);

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
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onVerticalDragUpdate: (details) {
                  _updateLayout(() {
                    _timelineHeight = (_timelineHeight - details.delta.dy).clamp(minTimelineH, maxTimelineH);
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
                          Container(height: 1, color: AppTheme.borderGlass),
                          Container(
                            width: 24,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppTheme.mutedText.withValues(alpha: 0.35),
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
                    final bgmConfig = ref.watch(editorProvider.select((s) => s.backgroundMusicConfig));
                    final bRollClips = ref.watch(editorProvider.select((s) => s.bRollClips));
                    final chapters = ref.watch(editorProvider.select((s) => s.chapters));
                    return TimelineWidget(
                      words: project.words,
                      currentTime: currentTime,
                      duration: project.duration,
                      trimStart: project.trimStart,
                      trimEnd: project.trimEnd,
                      segments: project.segments,
                      backgroundMusic: bgmConfig,
                      bRollClips: bRollClips,
                      chapters: chapters,
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
              final double minSidebarWidth = math.min(400.0, screenWidth * 0.5);
              final double maxSidebarWidth = math.max(minSidebarWidth, screenWidth - 300.0);

              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  _updateLayout(() {
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
                        Container(width: 1, color: AppTheme.borderGlass),
                        Container(
                          width: 3,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppTheme.mutedText.withValues(alpha: 0.35),
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
              final double minSidebarWidth = math.min(400.0, screenWidth * 0.5);
              final double maxSidebarWidth = math.max(minSidebarWidth, screenWidth - 300.0);
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
              Builder(
                builder: (context) {
                  final screenHeight = MediaQuery.of(context).size.height;
                  final minTimelineH = (screenHeight < 600) ? 120.0 : 150.0;
                  final maxTimelineH = (screenHeight * 0.40).clamp(minTimelineH, 360.0);

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onVerticalDragUpdate: (details) {
                          _updateLayout(() {
                            _timelineHeight = (_timelineHeight - details.delta.dy).clamp(minTimelineH, maxTimelineH);
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
                                Container(height: 1, color: AppTheme.borderGlass),
                                Container(
                                  width: 24,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppTheme.mutedText.withValues(alpha: 0.35),
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
                        height: _timelineHeight.clamp(minTimelineH, maxTimelineH),
                        child: Consumer(
                  builder: (context, ref, child) {
                    final currentTime = ref.watch(editorProvider.select((s) => s.currentTime));
                    final bgmConfig = ref.watch(editorProvider.select((s) => s.backgroundMusicConfig));
                    final bRollClips = ref.watch(editorProvider.select((s) => s.bRollClips));
                    final chapters = ref.watch(editorProvider.select((s) => s.chapters));
                    return TimelineWidget(
                      words: project.words,
                      currentTime: currentTime,
                      duration: project.duration,
                      trimStart: project.trimStart,
                      trimEnd: project.trimEnd,
                      segments: project.segments,
                      backgroundMusic: bgmConfig,
                      bRollClips: bRollClips,
                      chapters: chapters,
                    );
                  }
                ),
              ),
                    ],
                  );
                },
              ),
            ],
            // Embedded Sidebar (only if open!)
            if (_mobileSidebarOpen) ...[
              if (!isKeyboardOpen) ...[
                // Horizontal Divider 2 (Timeline <-> Sidebar Panel)
                GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onVerticalDragUpdate: (details) {
                    _updateLayout(() {
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
                          Container(height: 1, color: AppTheme.borderGlass),
                          Container(
                            width: 24,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppTheme.mutedText.withValues(alpha: 0.35),
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
                        color: AppTheme.borderGlass,
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
                              onPressed: () => _updateLayout(() => _mobileSidebarOpen = false),
                            ),
                          ],
                        ),
                      ),
                      Divider(color: AppTheme.dividerColor, height: 1),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool canShowControls = _controlsVisible && constraints.maxHeight >= 70;
        return MouseRegion(
          onHover: (_) => _showControls(),
      child: Container(
        margin: EdgeInsets.all(marginVal),
        decoration: AppTheme.glassDecoration(
          color: AppTheme.surfaceDim, // Solid dark surface to merge seamlessly with video player background
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
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDim,
                                borderRadius: BorderRadius.circular(aspectRatio < 1.0 ? 14 : 8),
                                border: Border.all(
                                  color: AppTheme.borderGlass,
                                  width: 1,
                                ),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Center(
                                    child: Video(controller: _videoController!, controls: null),
                                  ),
                                  Positioned.fill(
                                    child: Consumer(
                                      builder: (context, ref, child) {
                                        final currentTime = ref.watch(editorProvider.select((s) => s.currentTime));
                                      final retentionConfig = ref.watch(editorProvider.select((s) => s.retentionBarConfig));
                                      final config = ref.watch(editorProvider.select((s) => s.project?.config));
                                      final safeZone = ref.watch(editorProvider.select((s) => s.safeZoneGuide));
                                      final bRollClips = ref.watch(editorProvider.select((s) => s.bRollClips));
                                      return Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          BRollOverlay(
                                            currentTime: currentTime,
                                            bRollClips: bRollClips,
                                            videoWidth: project.width.toDouble(),
                                            videoHeight: project.height.toDouble(),
                                          ),
                                          SafeZoneOverlay(
                                            platform: safeZone,
                                            videoWidth: project.width.toDouble(),
                                            videoHeight: project.height.toDouble(),
                                          ),
                                          RetentionProgressBarOverlay(
                                            currentTime: currentTime,
                                            duration: project.duration,
                                            config: retentionConfig,
                                            scale: 1.2,
                                          ),
                                          if (config != null)
                                            CaptionOverlay(
                                              chunks: chunks,
                                              currentTime: currentTime,
                                              config: config,
                                              scale: 1.2,
                                              allowDrag: true,
                                              isControlsVisible: _controlsVisible,
                                              onPositionChanged: (newTop) {
                                                ref.read(editorProvider.notifier).updateCaptionTop(newTop);
                                              },
                                              onHorizontalPositionChanged: (newLeft) {
                                                ref.read(editorProvider.notifier).updateCaptionLeft(newLeft);
                                              },
                                              onDragEnd: () {
                                                ref.read(editorProvider.notifier).commitHistoryAndSave();
                                              },
                                              videoWidth: project.width.toDouble(),
                                              videoHeight: project.height.toDouble(),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
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
                                      Icon(Icons.broken_image_outlined, size: 36, color: AppTheme.accentRed),
                                      const SizedBox(height: 8),
                                      Text(
                                        _playerInitError,
                                        style: TextStyle(color: AppTheme.secondaryText, fontSize: 12, height: 1.3),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.link, size: 14),
                                        label: const Text('RELINK VIDEO FILE', style: TextStyle(fontSize: 12)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppTheme.accentOrange,
                                          foregroundColor: AppTheme.onAccentText,
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
              if (canShowControls)
                _buildVideoControls(project: project),
            ],
          ),
        ),
      ),
    );
      },
    );
  }

  // --- VIDEO CONTROLS (seek bar, play/pause, volume, fullscreen) ---
  Widget _buildVideoControls({required Project project, bool isFullscreen = false}) {
    return Consumer(
      builder: (context, ref, child) {
        final currentTime = ref.watch(editorProvider.select((s) => s.currentTime));
        final isPlaying = ref.watch(editorProvider.select((s) => s.isPlaying));
        final safeZone = ref.watch(editorProvider.select((s) => s.safeZoneGuide));
        final isProxyActive = ref.watch(editorProvider.select((s) => s.isProxyActive));
        final isGeneratingProxy = ref.watch(editorProvider.select((s) => s.isGeneratingProxy));
        final proxyProgress = ref.watch(editorProvider.select((s) => s.proxyProgress));
        return EditorVideoControls(
          project: project,
          currentTime: currentTime,
          isPlaying: isPlaying,
          volume: _volume,
          isMuted: _isMuted,
          playbackRate: _playbackRate,
          isFullscreen: isFullscreen,
          safeZoneGuide: safeZone,
          isProxyActive: isProxyActive,
          isGeneratingProxy: isGeneratingProxy,
          proxyProgress: proxyProgress,
          onToggleProxy: () {
            ref.read(editorProvider.notifier).toggleProxyMode();
          },
          onSafeZoneChanged: (platform) {
            ref.read(editorProvider.notifier).setSafeZoneGuide(platform);
          },
          onTogglePlayback: _togglePlayback,
          onSeek: (val) {
            ref.read(editorProvider.notifier).setCurrentTime(val);
          },
          onSeekEnd: (val) {
            _player?.seek(Duration(milliseconds: (val * 1000).toInt()));
          },
          onToggleMute: _toggleMute,
          onSetVolume: _setVolume,
          onPlaybackRateChanged: (double rate) {
            _updateLayout(() {
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

  Future<void> _switchPlaybackMedia(Project project, bool isProxy, double currentTime) async {
    if (_player == null || kIsWeb || _isSwitchingProxy) return;
    _isSwitchingProxy = true;
    try {
      final proxyPath = VideoProxyService.instance.getProxyPath(
        project.projectId,
        project.videoPath,
      );
      final targetPath = (isProxy && File(proxyPath).existsSync())
          ? proxyPath
          : project.videoPath;
      final wasPlaying = ref.read(editorProvider).isPlaying;
      await _player?.open(Media(targetPath), play: wasPlaying);
      final ms = (currentTime * 1000).toInt();
      await _player?.seek(Duration(milliseconds: ms));
      await _player?.setRate(_playbackRate);
      await _player?.setVolume(_volume * 100);
      LoggerService.instance.info('VideoProxy', 'Switched playback media (proxy: $isProxy, target: $targetPath)');
    } catch (e) {
      LoggerService.instance.error('VideoProxy', 'Failed switching playback media: $e');
    } finally {
      _isSwitchingProxy = false;
    }
  }
}
