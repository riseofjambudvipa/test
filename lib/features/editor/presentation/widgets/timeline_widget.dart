import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_provider.dart';
import '../../../../core/database/schemas/word.dart';
import '../../../../core/database/schemas/project.dart';
import '../../../../core/audio/waveform_service.dart';
import '../../../../core/ffmpeg/ffmpeg_locator.dart';
import '../../../../core/settings/settings_service.dart';
import '../../../../core/logger/logger_service.dart';
import '../controllers/editor_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/video/background_music_models.dart';
import '../../../../core/video/b_roll_models.dart';
import '../../../../core/video/chapter_models.dart';
import 'timeline_painter.dart';
import 'timeline_controls.dart';
export 'timeline_controls.dart';

class TimelineWidget extends ConsumerStatefulWidget {
  final List<WordSchema> words;
  final double currentTime;
  final double duration;
  final double trimStart;
  final double trimEnd;
  final List<VideoSegmentSchema>? segments;
  final BackgroundMusicConfig? backgroundMusic;
  final List<BRollClip>? bRollClips;
  final List<VideoChapter>? chapters;

  const TimelineWidget({
    super.key,
    required this.words,
    required this.currentTime,
    required this.duration,
    required this.trimStart,
    required this.trimEnd,
    this.segments,
    this.backgroundMusic,
    this.bRollClips,
    this.chapters,
  });

  @override
  ConsumerState<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends ConsumerState<TimelineWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flingController;
  double _zoomLevel = 3.0;
  double _scrollOffset = 0.0;
  List<double>? _waveformAmplitudes;
  bool _needsAutoScroll = false;
  bool _isUserScrolling = false;
  Timer? _userScrollCooldown;
  double _baseZoomLevel = 3.0;
  Offset? _lastFocalPoint;
  int _waveformLoadCounter = 0;

  double _getPixelsPerSecond(double width) {
    return 100.0 * _zoomLevel;
  }

  /// Returns the zoomLevel that makes the entire video exactly fit the visible width.
  double _getFitZoomLevel(double width) {
    return ((width / widget.duration) / 100.0).clamp(0.5, 5.0);
  }

  void _setZoomLevel(double newZoom, double width) {
    setState(() {
      _zoomLevel = newZoom.clamp(0.5, 5.0);
      final pixelsPerSecond = _getPixelsPerSecond(width);
      final maxScroll = (widget.duration * pixelsPerSecond) - width;
      _scrollOffset = _scrollOffset.clamp(0.0, math.max(0.0, maxScroll));
    });
  }

  String? _draggingHandle; // null, 'start', or 'end'
  String? _draggingWordId; // null or wordId
  String? _draggingWordEdge; // null, 'start', or 'end'
  String? _hoveredWordId; // null or wordId for hover tooltip
  bool _draggingPlayhead = false;
  MouseCursor _cursor = MouseCursor.defer;

  // FIX (perf/correctness): the timeline painter binary-searches the visible
  // word range, which is only valid when words are sorted by start AND end
  // time. SRT-imported or hand-edited projects can be out of order, so the
  // painter must fall back to a linear scan. Compute the flag once per words
  // list (not per frame) and hand it to the painter.
  bool _wordsAreOrdered = true;

  @override
  void initState() {
    super.initState();
    _flingController = AnimationController.unbounded(vsync: this);
    _flingController.addListener(_handleFlingTick);
    _wordsAreOrdered = isWordsChronologicallyOrdered(widget.words);
    _loadWaveform();
  }

  @override
  void dispose() {
    _flingController.dispose();
    _userScrollCooldown?.cancel();
    _userScrollCooldown = null;
    _isUserScrolling = false;
    super.dispose();
  }

  void _handleFlingTick() {
    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final width = renderBox.size.width;
    final pixelsPerSecond = _getPixelsPerSecond(width);
    final maxScroll = (widget.duration * pixelsPerSecond) - width;

    setState(() {
      _scrollOffset =
          _flingController.value.clamp(0.0, math.max(0.0, maxScroll));
    });
  }

  void _startFling(double velocityX) {
    _flingController.stop();

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final width = renderBox.size.width;
    final pixelsPerSecond = _getPixelsPerSecond(width);
    final maxScroll = (widget.duration * pixelsPerSecond) - width;
    if (maxScroll <= 0) return;

    final simulation = ClampingScrollSimulation(
      position: _scrollOffset,
      velocity: -velocityX, // Negative because dragging right scrolls left
      tolerance: Tolerance.defaultTolerance,
    );

    _flingController.animateWith(simulation);
  }

  @override
  void didUpdateWidget(covariant TimelineWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Recompute the sorted-words flag only when the words list is replaced
    // (identity changes on structural edits, not on per-frame rebuilds).
    if (oldWidget.words != widget.words) {
      _wordsAreOrdered = isWordsChronologicallyOrdered(widget.words);
    }

    // Regenerate waveform data when the video duration changes
    if (oldWidget.duration != widget.duration) {
      _loadWaveform();
    }

    // Schedule auto-scroll when currentTime changes during playback
    if (oldWidget.currentTime != widget.currentTime) {
      _scheduleAutoScroll();
    }
  }

  Future<void> _loadWaveform() async {
    final currentLoadId = ++_waveformLoadCounter;
    final project = ref.read(editorProvider).project;
    if (project == null) {
      _generateMockWaveform();
      return;
    }

    final videoPath = project.videoPath;
    final ffmpegPath = FfmpegLocator.instance.resolve(
      configured: SettingsService.instance.ffmpegCliPath,
    );

    try {
      final sampleCount = (widget.duration * 15).round().clamp(800, 3600);
      final amps = await WaveformService.instance.extractWaveform(
        videoPath: videoPath,
        ffmpegPath: ffmpegPath,
        sampleCount: sampleCount,
      );
      if (mounted && currentLoadId == _waveformLoadCounter) {
        setState(() {
          _waveformAmplitudes = amps;
        });
      }
    } catch (e) {
      LoggerService.instance.log(
          LogLevel.error, 'TimelineWidget', 'Failed to load real waveform: $e');
      if (mounted && currentLoadId == _waveformLoadCounter) {
        _generateMockWaveform();
      }
    }
  }

  void _generateMockWaveform() {
    // Generate simple mock soundwave data based on video length
    final random = math.Random(12345);
    final sampleCount = (widget.duration * 10).round().clamp(100, 5000);
    final amps = List.generate(sampleCount, (index) {
      // Create noise with sine wave pulses to simulate speech peaks
      final sineVal = math.sin(index / 15.0).abs();
      return (sineVal * 0.6) + (random.nextDouble() * 0.3);
    });
    if (mounted) {
      setState(() {
        _waveformAmplitudes = amps;
      });
    } else {
      _waveformAmplitudes = amps;
    }
  }

  /// Schedules a post-frame auto-scroll if the playhead drifts out of view.
  /// Uses [_needsAutoScroll] flag to debounce and prevent infinite rebuild loops.
  void _scheduleAutoScroll() {
    if (_isUserScrolling) return; // user is currently interacting
    if (_needsAutoScroll) return; // already scheduled

    final isPlaying = ref.read(editorProvider).isPlaying;
    if (!isPlaying) return;

    _needsAutoScroll = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _needsAutoScroll = false;
      if (!mounted) return;
      _performAutoScroll();
    });
  }

  void _performAutoScroll() {
    // Use the LayoutBuilder-equivalent logic: read the widget's render size
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final width = renderBox.size.width;
    final pixelsPerSecond = _getPixelsPerSecond(width);
    final playheadX = widget.currentTime * pixelsPerSecond;
    final relativePlayheadX = playheadX - _scrollOffset;

    if (relativePlayheadX > width - 100 || relativePlayheadX < 100) {
      setState(() {
        final targetScroll = playheadX - (width / 2);
        final maxScroll = (widget.duration * pixelsPerSecond) - width;
        _scrollOffset =
            targetScroll.clamp(0.0, math.max(0.0, maxScroll)).toDouble();
      });
    }
  }

  void _handleTap(
      TapUpDetails details, double widgetWidth, double widgetHeight) {
    final localX = details.localPosition.dx;
    final localY = details.localPosition.dy;

    final trackTop = widgetHeight - 32.0;
    final trackBottom = widgetHeight - 8.0;

    final pixelsPerSecond = _getPixelsPerSecond(widgetWidth);
    final timelineX = localX + _scrollOffset;
    final time = timelineX / pixelsPerSecond;

    // 1. Clicked on the Ruler area (top of timeline) -> Seek playhead
    if (localY < trackTop) {
      final double targetTime = time.clamp(0.0, widget.duration).toDouble();
      ref.read(editorProvider.notifier).setCurrentTime(targetTime);
      return;
    }

    // 2. Clicked on the Subtitle Word Track (bottom of timeline) -> Detect Word Hit
    if (localY >= trackTop && localY <= trackBottom) {
      // Use the binary-search helper for O(log n) word lookup instead of O(n) linear scan.
      final word = TimelineHitTester.findWordUnderCursor(
        localX: localX,
        localY: localY,
        widgetWidth: widgetWidth,
        widgetHeight: widgetHeight,
        scrollOffset: _scrollOffset,
        pixelsPerSecond: pixelsPerSecond,
        words: widget.words,
        wordsAreOrdered: _wordsAreOrdered,
      );
      if (word != null) {
        // Cycle Highlight Colors matching: w1 click timer cycle logic
        final cycleClasses = [null, 'mainColor', 'secondColor', 'thirdColor'];
        final currentIdx = cycleClasses.indexOf(word.className);
        final nextIdx = (currentIdx + 1) % cycleClasses.length;

        final wid = word.wordId;
        if (wid != null) {
          ref.read(editorProvider.notifier).updateWord(
                wid,
                className: cycleClasses[nextIdx] ?? 'none',
              );
        }
      }
    }
  }

  void _handleScaleStart(
      ScaleStartDetails details, double widgetWidth, double widgetHeight) {
    _flingController.stop();
    _isUserScrolling = true;
    _userScrollCooldown?.cancel();
    _baseZoomLevel = _zoomLevel;
    _lastFocalPoint = details.localFocalPoint;

    // Use focal point to detect dragging (playhead, word edges, trim handles)
    final localX = details.localFocalPoint.dx;
    final localY = details.localFocalPoint.dy;
    final pixelsPerSecond = _getPixelsPerSecond(widgetWidth);
    final trimStartX = (widget.trimStart * pixelsPerSecond) - _scrollOffset;
    final trimEndX = (widget.trimEnd * pixelsPerSecond) - _scrollOffset;

    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final trimTolerance = isMobile ? 30.0 : 15.0;

    final nearStart = (localX - trimStartX).abs() <= trimTolerance;
    final nearEnd = (localX - trimEndX).abs() <= trimTolerance;

    if (nearStart && nearEnd) {
      if ((localX - trimStartX).abs() < (localX - trimEndX).abs()) {
        _draggingHandle = 'start';
      } else {
        _draggingHandle = 'end';
      }
    } else if (nearStart) {
      _draggingHandle = 'start';
    } else if (nearEnd) {
      _draggingHandle = 'end';
    } else {
      _draggingHandle = null;

      // If not near trim handles, check if resizing a word edge
      final hit = TimelineHitTester.findWordEdgeHit(
        localX: localX,
        localY: localY,
        widgetWidth: widgetWidth,
        widgetHeight: widgetHeight,
        scrollOffset: _scrollOffset,
        pixelsPerSecond: pixelsPerSecond,
        words: widget.words,
        wordsAreOrdered: _wordsAreOrdered,
      );
      if (hit != null) {
        _draggingWordId = hit.word.wordId;
        _draggingWordEdge = hit.edge;
        LoggerService.instance.action('TimelineWidget',
            'Started dragging word edge: $_draggingWordEdge for word ID: $_draggingWordId');
      } else {
        _draggingWordId = null;
        _draggingWordEdge = null;

        // If in ruler area, drag playhead
        final trackTop = widgetHeight - 32.0;
        if (localY < trackTop) {
          _draggingPlayhead = true;
          LoggerService.instance
              .action('TimelineWidget', 'Started dragging playhead');
        }
      }
    }

    // FIX (perf): a trim-handle or word-edge drag mutates state per tick,
    // which used to flood undo history with dozens of entries per gesture.
    // Batch the drag so it collapses into a single undo step on release.
    if (_draggingHandle != null || _draggingWordId != null) {
      ref.read(editorProvider.notifier).beginHistoryBatch();
    }
  }

  void _handleScaleUpdate(
      ScaleUpdateDetails details, double widgetWidth, double widgetHeight) {
    // Multi-touch pinch zoom (only when 2+ fingers/pointers are actively gesturing)
    if (details.pointerCount >= 2 && (details.scale - 1.0).abs() > 0.05) {
      final double newZoom = (_baseZoomLevel * details.scale).clamp(1.0, 5.0);
      setState(() {
        final double oldPps = _getPixelsPerSecond(widgetWidth);
        final double focalTime =
            (details.localFocalPoint.dx + _scrollOffset) / oldPps;

        _zoomLevel = newZoom;

        final double newPps = _getPixelsPerSecond(widgetWidth);
        final double maxScroll = (widget.duration * newPps) - widgetWidth;

        _scrollOffset = (focalTime * newPps - details.localFocalPoint.dx)
            .clamp(0.0, math.max(0.0, maxScroll));
      });
    } else {
      // Single-finger dragging / panning
      final pixelsPerSecond = _getPixelsPerSecond(widgetWidth);
      if (_draggingPlayhead) {
        final localX = details.localFocalPoint.dx;
        final timelineX = localX + _scrollOffset;
        final time = (timelineX / pixelsPerSecond).clamp(0.0, widget.duration);
        ref.read(editorProvider.notifier).setCurrentTime(time);
      } else if (_draggingHandle != null) {
        final localX = details.localFocalPoint.dx;
        final timelineX = localX + _scrollOffset;
        final time = (timelineX / pixelsPerSecond).clamp(0.0, widget.duration);

        if (_draggingHandle == 'start') {
          final maxStart = widget.trimEnd - 0.2;
          final newStart = time.clamp(0.0, math.max(0.0, maxStart)).toDouble();
          ref.read(editorProvider.notifier).setTrim(newStart, widget.trimEnd);
        } else if (_draggingHandle == 'end') {
          final minEnd = widget.trimStart + 0.2;
          final newEnd = time.clamp(minEnd, widget.duration).toDouble();
          ref.read(editorProvider.notifier).setTrim(widget.trimStart, newEnd);
        }
      } else if (_draggingWordId != null && _draggingWordEdge != null) {
        final localX = details.localFocalPoint.dx;
        final timelineX = localX + _scrollOffset;
        final time = (timelineX / pixelsPerSecond).clamp(0.0, widget.duration);

        final wordIdx =
            widget.words.indexWhere((w) => w.wordId == _draggingWordId);
        if (wordIdx != -1) {
          final word = widget.words[wordIdx];
          final start = word.start ?? 0.0;
          final end = word.end ?? 0.0;

          if (_draggingWordEdge == 'start') {
            double minStart = 0.0;
            if (wordIdx > 0) {
              minStart = widget.words[wordIdx - 1].end ?? 0.0;
            }
            final maxStart = end - 0.05;
            final clampedStart =
                time.clamp(minStart, math.max(minStart, maxStart)).toDouble();
            ref.read(editorProvider.notifier).updateWordTimingsQuietly(
                _draggingWordId!,
                start: clampedStart);
          } else if (_draggingWordEdge == 'end') {
            final minEnd = start + 0.05;
            double maxEnd = widget.duration;
            if (wordIdx < widget.words.length - 1) {
              maxEnd = widget.words[wordIdx + 1].start ?? widget.duration;
            }
            final clampedEnd =
                time.clamp(minEnd, math.max(minEnd, maxEnd)).toDouble();
            ref
                .read(editorProvider.notifier)
                .updateWordTimingsQuietly(_draggingWordId!, end: clampedEnd);
          }
        }
      } else {
        // Drag canvas to scroll timeline
        if (_lastFocalPoint != null) {
          final dx = details.localFocalPoint.dx - _lastFocalPoint!.dx;
          setState(() {
            final maxScroll = (widget.duration * pixelsPerSecond) - widgetWidth;
            _scrollOffset = (_scrollOffset - dx)
                .clamp(0.0, math.max(0.0, maxScroll))
                .toDouble();
          });
        }
      }
    }
    _lastFocalPoint = details.localFocalPoint;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_draggingWordId != null || _draggingHandle != null) {
      // FIX (perf): end the batch begun in _handleScaleStart — records a
      // single history entry + auto-save for the whole drag gesture.
      ref.read(editorProvider.notifier).endHistoryBatch();
    }

    if (_draggingWordId == null &&
        _draggingHandle == null &&
        !_draggingPlayhead) {
      final velocityX = details.velocity.pixelsPerSecond.dx;
      if (velocityX.abs() > 50.0) {
        _startFling(velocityX);
      }
    }

    _draggingHandle = null;
    _draggingWordId = null;
    _draggingWordEdge = null;
    _draggingPlayhead = false;
    _lastFocalPoint = null;
    _userScrollCooldown?.cancel();
    _userScrollCooldown = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isUserScrolling = false;
        });
      }
    });
    setState(() {
      _cursor = MouseCursor.defer;
    });
  }

  void _handleHover(
      PointerHoverEvent event, double widgetWidth, double widgetHeight) {
    final localX = event.localPosition.dx;
    final localY = event.localPosition.dy;
    final pixelsPerSecond = _getPixelsPerSecond(widgetWidth);
    final trimStartX = (widget.trimStart * pixelsPerSecond) - _scrollOffset;
    final trimEndX = (widget.trimEnd * pixelsPerSecond) - _scrollOffset;

    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final trimTolerance = isMobile ? 30.0 : 15.0;

    final nearStart = (localX - trimStartX).abs() <= trimTolerance;
    final nearEnd = (localX - trimEndX).abs() <= trimTolerance;

    final wordEdgeHit = TimelineHitTester.findWordEdgeHit(
      localX: localX,
      localY: localY,
      widgetWidth: widgetWidth,
      widgetHeight: widgetHeight,
      scrollOffset: _scrollOffset,
      pixelsPerSecond: pixelsPerSecond,
      words: widget.words,
      wordsAreOrdered: _wordsAreOrdered,
    );
    final wordUnderCursor = TimelineHitTester.findWordUnderCursor(
      localX: localX,
      localY: localY,
      widgetWidth: widgetWidth,
      widgetHeight: widgetHeight,
      scrollOffset: _scrollOffset,
      pixelsPerSecond: pixelsPerSecond,
      words: widget.words,
      wordsAreOrdered: _wordsAreOrdered,
    );
    final newHoveredWordId = wordUnderCursor?.wordId;

    if (newHoveredWordId != _hoveredWordId) {
      setState(() {
        _hoveredWordId = newHoveredWordId;
      });
    }

    if (_draggingHandle != null ||
        _draggingWordId != null ||
        nearStart ||
        nearEnd ||
        wordEdgeHit != null) {
      if (_cursor != SystemMouseCursors.resizeLeftRight) {
        setState(() {
          _cursor = SystemMouseCursors.resizeLeftRight;
        });
      }
    } else {
      if (_cursor != MouseCursor.defer) {
        setState(() {
          _cursor = MouseCursor.defer;
        });
      }
    }
  }

  /// Handles mouse wheel events for horizontal scrolling and zooming (via Ctrl + Mouse Wheel) on the timeline.
  void _handlePointerScroll(PointerScrollEvent event, double widgetWidth) {
    _isUserScrolling = true;
    _userScrollCooldown?.cancel();
    _userScrollCooldown = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isUserScrolling = false;
        });
      }
    });

    final isCtrl = HardwareKeyboard.instance.isControlPressed;

    if (isCtrl) {
      // Zoom logic: Ctrl + mouse wheel scroll
      final delta = event.scrollDelta.dy;
      if (delta != 0.0) {
        setState(() {
          // Calculate the pixels per second and time at the mouse cursor before zoom
          final oldPixelsPerSecond = _getPixelsPerSecond(widgetWidth);
          final localX = event.localPosition.dx;
          final cursorTime = (localX + _scrollOffset) / oldPixelsPerSecond;

          // Adjust zoomLevel: scroll up zooms in, scroll down zooms out
          final zoomDelta = delta < 0 ? 0.5 : -0.5;
          _zoomLevel = (_zoomLevel + zoomDelta).clamp(1.0, 5.0);

          // Get new pixels per second
          final newPixelsPerSecond = _getPixelsPerSecond(widgetWidth);

          // Adjust scroll offset to keep the cursor time at the same local X coordinate
          final maxScroll =
              (widget.duration * newPixelsPerSecond) - widgetWidth;
          _scrollOffset = (cursorTime * newPixelsPerSecond - localX)
              .clamp(0.0, math.max(0.0, maxScroll))
              .toDouble();
        });
      }
    } else {
      // Regular horizontal scroll logic
      setState(() {
        // Use horizontal scroll if available, otherwise fall back to vertical scroll axis
        final delta = event.scrollDelta.dx != 0.0
            ? event.scrollDelta.dx
            : event.scrollDelta.dy;
        final pixelsPerSecond = _getPixelsPerSecond(widgetWidth);
        final maxScroll = (widget.duration * pixelsPerSecond) - widgetWidth;
        _scrollOffset = (_scrollOffset + delta)
            .clamp(0.0, math.max(0.0, maxScroll))
            .toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeProvider);
    double activeDuration = 0.0;
    if (widget.segments != null && widget.segments!.isNotEmpty) {
      for (final seg in widget.segments!) {
        if (!(seg.isDeleted ?? false)) {
          activeDuration += (seg.end ?? 0.0) - (seg.start ?? 0.0);
        }
      }
    } else {
      activeDuration = widget.trimEnd - widget.trimStart;
      if (activeDuration <= 0.0) activeDuration = widget.duration;
    }

    final durationString =
        '${widget.currentTime.toStringAsFixed(3)}s / ${widget.duration.toStringAsFixed(3)}s (Active: ${activeDuration.toStringAsFixed(3)}s)';

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final pixelsPerSecond = _getPixelsPerSecond(width);

        return Container(
          height: height,
          decoration: AppTheme.glassDecoration(
            color: AppTheme.cardBg.withValues(alpha: 0.4),
            borderRadius: 0,
            borderOpacity: 0.0,
          ).copyWith(
            border: Border(
              top: BorderSide(
                color: AppTheme.borderGlass,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              // Zoom Controller & Timing Indicator Bar
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: width >= 600 ? 16.0 : 8.0,
                  vertical: height < 110 ? 2.0 : (width >= 600 ? 8.0 : 4.0),
                ),
                child: height < 110
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              durationString,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                            ),
                          ),
                        ],
                      )
                    : (width >= 1080
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  durationString,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TimelineTrimActionButtons(
                                isCompact: width < 750,
                                onSplit: _splitClip,
                                onToggleExclusion: _toggleExclusion,
                                onRippleDelete: _rippleDeleteGaps,
                                onReset: _resetSplits,
                              ),
                              const SizedBox(width: 8),
                              TimelineZoomControls(
                                zoomLevel: _zoomLevel,
                                timelineWidth: width,
                                onZoomChanged: (newZoom) =>
                                    _setZoomLevel(newZoom, width),
                                onZoomIn: () =>
                                    _setZoomLevel(_zoomLevel + 0.5, width),
                                onZoomOut: () =>
                                    _setZoomLevel(_zoomLevel - 0.5, width),
                                onZoomFit: () {
                                  setState(() {
                                    _zoomLevel = _getFitZoomLevel(width);
                                    _scrollOffset = 0.0;
                                  });
                                },
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      durationString,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            fontFamily: 'monospace',
                                            fontWeight: FontWeight.bold,
                                            fontSize: width >= 600 ? 14 : 11,
                                          ),
                                    ),
                                  ),
                                  if (width >= 600)
                                    TimelineZoomControls(
                                      zoomLevel: _zoomLevel,
                                      timelineWidth: width,
                                      onZoomChanged: (newZoom) =>
                                          _setZoomLevel(newZoom, width),
                                      onZoomIn: () =>
                                          _setZoomLevel(_zoomLevel + 0.5, width),
                                      onZoomOut: () =>
                                          _setZoomLevel(_zoomLevel - 0.5, width),
                                      onZoomFit: () {
                                        setState(() {
                                          _zoomLevel = _getFitZoomLevel(width);
                                          _scrollOffset = 0.0;
                                        });
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              TimelineTrimActionButtons(
                                isCompact: width < 550,
                                onSplit: _splitClip,
                                onToggleExclusion: _toggleExclusion,
                                onRippleDelete: _rippleDeleteGaps,
                                onReset: _resetSplits,
                              ),
                            ],
                          )),
              ),

              // Interactive Canvas area with mouse wheel horizontal scrolling
              Expanded(
                child: LayoutBuilder(
                  builder: (context, canvasConstraints) {
                    final canvasWidth = canvasConstraints.maxWidth;
                    final canvasHeight = canvasConstraints.maxHeight;

                    return MouseRegion(
                      cursor: _cursor,
                      onHover: (event) =>
                          _handleHover(event, canvasWidth, canvasHeight),
                      onExit: (event) {
                        setState(() {
                          _hoveredWordId = null;
                        });
                      },
                      child: Listener(
                        onPointerSignal: (event) {
                          if (event is PointerScrollEvent) {
                            _handlePointerScroll(event, canvasWidth);
                          }
                        },
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) =>
                              _handleTap(details, canvasWidth, canvasHeight),
                          onScaleStart: (details) => _handleScaleStart(
                              details, canvasWidth, canvasHeight),
                          onScaleUpdate: (details) => _handleScaleUpdate(
                              details, canvasWidth, canvasHeight),
                          onScaleEnd: _handleScaleEnd,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              RepaintBoundary(
                                child: CustomPaint(
                                  size: Size(canvasWidth, canvasHeight),
                                  painter: TimelineWaveformPainter(
                                    duration: widget.duration,
                                    pixelsPerSecond: pixelsPerSecond,
                                    scrollOffset: _scrollOffset,
                                    waveformAmplitudes:
                                        _waveformAmplitudes ?? const [],
                                    trimStart: widget.trimStart,
                                    trimEnd: widget.trimEnd,
                                    theme: theme,
                                    segments: widget.segments,
                                    backgroundMusic: widget.backgroundMusic,
                                    bRollClips: widget.bRollClips,
                                    words: widget.words,
                                    chapters: widget.chapters,
                                  ),
                                ),
                              ),
                              CustomPaint(
                                size: Size(canvasWidth, canvasHeight),
                                painter: TimelinePlayheadPainter(
                                  words: widget.words,
                                  currentTime: widget.currentTime,
                                  duration: widget.duration,
                                  pixelsPerSecond: pixelsPerSecond,
                                  scrollOffset: _scrollOffset,
                                  theme: theme,
                                  hoveredWordId: _hoveredWordId,
                                  wordsAreOrdered: _wordsAreOrdered,
                                  segments: widget.segments,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Custom Scrollbar Slider
              TimelineHorizontalScrollbar(
                width: width,
                timelineHeight: height,
                scrollOffset: _scrollOffset,
                maxScroll: (widget.duration * pixelsPerSecond) - width,
                totalContentWidth: widget.duration * pixelsPerSecond,
                onScrollOffsetChanged: (newOffset) {
                  setState(() {
                    _scrollOffset = newOffset;
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _splitClip() {
    final l10n = AppLocalizations.of(context);
    final curr = widget.currentTime;
    if (curr > widget.trimStart && curr < widget.trimEnd) {
      ref.read(editorProvider.notifier).splitSegmentAtTime(curr);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.splitTimelineAt(curr.toStringAsFixed(2)) ??
                'Split timeline at ${curr.toStringAsFixed(2)}s.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.splitTimelineError ??
                'Playhead must be inside the active region to split.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _toggleExclusion() {
    final l10n = AppLocalizations.of(context);
    ref
        .read(editorProvider.notifier)
        .toggleSegmentDeleted(widget.currentTime);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.exclusionToggled ??
              'Toggled segment exclusion under playhead.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _resetSplits() {
    final l10n = AppLocalizations.of(context);
    ref.read(editorProvider.notifier).resetSegments();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          l10n?.splitsReset ??
              'Reset all timeline splits and exclusions.',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _rippleDeleteGaps() {
    final hasDeleted = widget.segments?.any((s) => s.isDeleted == true) ?? false;
    if (!hasDeleted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No deleted segments to ripple. Exclude or cut a clip first.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    ref.read(editorProvider.notifier).rippleDeleteAllDeletedSegments();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ripple delete applied: closed dead air gaps and aligned timeline.'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
