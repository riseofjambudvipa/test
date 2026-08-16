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
import '../../../../core/settings/settings_service.dart';
import '../../../../core/logger/logger_service.dart';
import '../controllers/editor_controller.dart';
import 'timeline_painter.dart';

class TimelineWidget extends ConsumerStatefulWidget {
  final List<WordSchema> words;
  final double currentTime;
  final double duration;
  final double trimStart;
  final double trimEnd;
  final List<VideoSegmentSchema>? segments;

  const TimelineWidget({
    super.key,
    required this.words,
    required this.currentTime,
    required this.duration,
    required this.trimStart,
    required this.trimEnd,
    this.segments,
  });

  @override
  ConsumerState<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends ConsumerState<TimelineWidget> with SingleTickerProviderStateMixin {
  late AnimationController _flingController;
  double _zoomLevel = 3.0;
  double _scrollOffset = 0.0;
  List<double>? _waveformAmplitudes;
  bool _needsAutoScroll = false;
  bool _isUserScrolling = false;
  Timer? _userScrollCooldown;
  bool _isHoveringScrollbar = false;
  bool _isDraggingScrollbar = false;
  double _baseZoomLevel = 3.0;
  Offset? _lastFocalPoint;
  int _waveformLoadCounter = 0;

  double _getPixelsPerSecond(double width) {
    return 100.0 * _zoomLevel;
  }

  /// Returns the zoomLevel that makes the entire video exactly fit the visible width.
  double _getFitZoomLevel(double width) {
    return ((width / widget.duration) / 100.0).clamp(0.5, 10.0);
  }

  String? _draggingHandle; // null, 'start', or 'end'
  String? _draggingWordId; // null or wordId
  String? _draggingWordEdge; // null, 'start', or 'end'
  String? _hoveredWordId; // null or wordId for hover tooltip
  bool _draggingPlayhead = false;
  MouseCursor _cursor = MouseCursor.defer;

  @override
  void initState() {
    super.initState();
    _flingController = AnimationController.unbounded(vsync: this);
    _flingController.addListener(_handleFlingTick);
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
      _scrollOffset = _flingController.value.clamp(0.0, math.max(0.0, maxScroll));
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
    final ffmpegPath = SettingsService.instance.ffmpegCliPath ?? 'ffmpeg';

    try {
      final amps = await WaveformService.instance.extractWaveform(
        videoPath: videoPath,
        ffmpegPath: ffmpegPath,
        sampleCount: 800,
      );
      if (mounted && currentLoadId == _waveformLoadCounter) {
        setState(() {
          _waveformAmplitudes = amps;
        });
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'TimelineWidget', 'Failed to load real waveform: $e');
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
        _scrollOffset = targetScroll.clamp(0.0, math.max(0.0, maxScroll)).toDouble();
      });
    }
  }

  void _handleTap(TapUpDetails details, double widgetWidth, double widgetHeight) {
    final localX = details.localPosition.dx;
    final localY = details.localPosition.dy;
    
    final trackTop = widgetHeight - 32.0;
    final trackBottom = widgetHeight - 8.0;

    final pixelsPerSecond = _getPixelsPerSecond(widgetWidth);
    final timelineX = localX + _scrollOffset;
    final time = timelineX / pixelsPerSecond;

    // 1. Clicked on the Ruler area (top of timeline) -> Seek playhead
    if (localY < trackTop) {
      final targetTime = time.clamp(0.0, widget.duration).toDouble();
      ref.read(editorProvider.notifier).setCurrentTime(targetTime);
      return;
    }

    // 2. Clicked on the Subtitle Word Track (bottom of timeline) -> Detect Word Hit
    if (localY >= trackTop && localY <= trackBottom) {
      // Use the binary-search helper for O(log n) word lookup instead of O(n) linear scan.
      final word = _findWordUnderCursor(localX, localY, widgetWidth, widgetHeight);
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

  bool _isLocalYInWordTrack(double localY, double widgetHeight) {
    final trackTop = widgetHeight - 32.0;
    final trackBottom = widgetHeight - 8.0;
    return localY >= trackTop && localY <= trackBottom;
  }

  WordSchema? _findWordUnderCursor(double localX, double localY, double widgetWidth, double widgetHeight) {
    if (!_isLocalYInWordTrack(localY, widgetHeight)) return null;

    final pixelsPerSecond = _getPixelsPerSecond(widgetWidth);
    final timelineX = localX + _scrollOffset;
    final time = timelineX / pixelsPerSecond;

    // Binary search for the word containing time
    int low = 0;
    int high = widget.words.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final word = widget.words[mid];
      final start = word.start ?? 0.0;
      final end = word.end ?? 0.0;
      if (time >= start && time <= end) {
        return word;
      } else if (time < start) {
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }
    return null;
  }

  WordEdgeHit? _findWordEdgeHit(double localX, double localY, double widgetWidth, double widgetHeight) {
    if (!_isLocalYInWordTrack(localY, widgetHeight)) return null;

    final pixelsPerSecond = _getPixelsPerSecond(widgetWidth);
    final time = (localX + _scrollOffset) / pixelsPerSecond;
    final isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    final edgeTolerance = isMobile ? 24.0 : 8.0;
    final toleranceTime = edgeTolerance / pixelsPerSecond;

    // Find the first index where word.start >= time - toleranceTime using binary search
    int low = 0;
    int high = widget.words.length - 1;
    int targetIdx = widget.words.length;
    final minTime = time - toleranceTime;

    while (low <= high) {
      final mid = (low + high) >> 1;
      final start = widget.words[mid].start ?? 0.0;
      if (start >= minTime) {
        targetIdx = mid;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    final startScan = math.max(0, targetIdx - 1);
    final maxTime = time + toleranceTime;

    for (int i = startScan; i < widget.words.length; i++) {
      final word = widget.words[i];
      final start = word.start ?? 0.0;
      if (start > maxTime && (word.end ?? 0.0) > maxTime) {
        break;
      }
      final end = word.end ?? 0.0;
      final startX = (start * pixelsPerSecond) - _scrollOffset;
      final endX = (end * pixelsPerSecond) - _scrollOffset;

      if ((localX - startX).abs() <= edgeTolerance) {
        return WordEdgeHit(word, 'start');
      }
      if ((localX - endX).abs() <= edgeTolerance) {
        return WordEdgeHit(word, 'end');
      }
    }
    return null;
  }

  void _handleScaleStart(ScaleStartDetails details, double widgetWidth, double widgetHeight) {
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

    final isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
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
      final hit = _findWordEdgeHit(localX, localY, widgetWidth, widgetHeight);
      if (hit != null) {
        _draggingWordId = hit.word.wordId;
        _draggingWordEdge = hit.edge;
        LoggerService.instance.action('TimelineWidget', 'Started dragging word edge: $_draggingWordEdge for word ID: $_draggingWordId');
      } else {
        _draggingWordId = null;
        _draggingWordEdge = null;

        // If in ruler area, drag playhead
        final trackTop = widgetHeight - 32.0;
        if (localY < trackTop) {
          _draggingPlayhead = true;
          LoggerService.instance.action('TimelineWidget', 'Started dragging playhead');
        }
      }
    }
  }

  void _handleScaleUpdate(ScaleUpdateDetails details, double widgetWidth, double widgetHeight) {
    // If the user is pinching (multi-touch zoom)
    if (details.scale != 1.0) {
      final double newZoom = (_baseZoomLevel * details.scale).clamp(0.5, 10.0);
      setState(() {
        final double oldPps = _getPixelsPerSecond(widgetWidth);
        final double focalTime = (details.localFocalPoint.dx + _scrollOffset) / oldPps;

        _zoomLevel = newZoom;

        final double newPps = _getPixelsPerSecond(widgetWidth);
        final double maxScroll = (widget.duration * newPps) - widgetWidth;
        
        _scrollOffset = (focalTime * newPps - details.localFocalPoint.dx).clamp(0.0, math.max(0.0, maxScroll));
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

        final wordIdx = widget.words.indexWhere((w) => w.wordId == _draggingWordId);
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
            final clampedStart = time.clamp(minStart, math.max(minStart, maxStart)).toDouble();
            ref.read(editorProvider.notifier).updateWordTimingsQuietly(_draggingWordId!, start: clampedStart);
          } else if (_draggingWordEdge == 'end') {
            final minEnd = start + 0.05;
            double maxEnd = widget.duration;
            if (wordIdx < widget.words.length - 1) {
              maxEnd = widget.words[wordIdx + 1].start ?? widget.duration;
            }
            final clampedEnd = time.clamp(minEnd, math.max(minEnd, maxEnd)).toDouble();
            ref.read(editorProvider.notifier).updateWordTimingsQuietly(_draggingWordId!, end: clampedEnd);
          }
        }
      } else {
        // Drag canvas to scroll timeline
        if (_lastFocalPoint != null) {
          final dx = details.localFocalPoint.dx - _lastFocalPoint!.dx;
          setState(() {
            final maxScroll = (widget.duration * pixelsPerSecond) - widgetWidth;
            _scrollOffset = (_scrollOffset - dx).clamp(0.0, math.max(0.0, maxScroll)).toDouble();
          });
        }
      }
    }
    _lastFocalPoint = details.localFocalPoint;
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (_draggingWordId != null || _draggingHandle != null) {
      ref.read(editorProvider.notifier).commitHistoryAndSave();
    }

    if (_draggingWordId == null && _draggingHandle == null && !_draggingPlayhead) {
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

  void _handleHover(PointerHoverEvent event, double widgetWidth, double widgetHeight) {
    final localX = event.localPosition.dx;
    final localY = event.localPosition.dy;
    final pixelsPerSecond = _getPixelsPerSecond(widgetWidth);
    final trimStartX = (widget.trimStart * pixelsPerSecond) - _scrollOffset;
    final trimEndX = (widget.trimEnd * pixelsPerSecond) - _scrollOffset;

    final isMobile = defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
    final trimTolerance = isMobile ? 30.0 : 15.0;

    final nearStart = (localX - trimStartX).abs() <= trimTolerance;
    final nearEnd = (localX - trimEndX).abs() <= trimTolerance;

    final wordEdgeHit = _findWordEdgeHit(localX, localY, widgetWidth, widgetHeight);
    final wordUnderCursor = _findWordUnderCursor(localX, localY, widgetWidth, widgetHeight);
    final newHoveredWordId = wordUnderCursor?.wordId;

    if (newHoveredWordId != _hoveredWordId) {
      setState(() {
        _hoveredWordId = newHoveredWordId;
      });
    }

    if (_draggingHandle != null || _draggingWordId != null || nearStart || nearEnd || wordEdgeHit != null) {
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
          _zoomLevel = (_zoomLevel + zoomDelta).clamp(0.5, 10.0);

          // Get new pixels per second
          final newPixelsPerSecond = _getPixelsPerSecond(widgetWidth);

          // Adjust scroll offset to keep the cursor time at the same local X coordinate
          final maxScroll = (widget.duration * newPixelsPerSecond) - widgetWidth;
          _scrollOffset = (cursorTime * newPixelsPerSecond - localX).clamp(0.0, math.max(0.0, maxScroll)).toDouble();
        });
      }
    } else {
      // Regular horizontal scroll logic
      setState(() {
        // Use horizontal scroll if available, otherwise fall back to vertical scroll axis
        final delta = event.scrollDelta.dx != 0.0 ? event.scrollDelta.dx : event.scrollDelta.dy;
        final pixelsPerSecond = _getPixelsPerSecond(widgetWidth);
        final maxScroll = (widget.duration * pixelsPerSecond) - widgetWidth;
        _scrollOffset = (_scrollOffset + delta).clamp(0.0, math.max(0.0, maxScroll)).toDouble();
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

    final durationString = '${widget.currentTime.toStringAsFixed(3)}s / ${widget.duration.toStringAsFixed(3)}s (Active: ${activeDuration.toStringAsFixed(3)}s)';

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
                color: Colors.white.withValues(alpha: 0.08),
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
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      )
                    : (width >= 950
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  durationString,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildTrimActionButtons(),
                              const SizedBox(width: 8),
                              _buildZoomControls(width),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      durationString,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.bold,
                                        fontSize: width >= 600 ? 14 : 11,
                                      ),
                                    ),
                                  ),
                                  if (width >= 600) _buildZoomControls(width),
                                ],
                              ),
                              const SizedBox(height: 6),
                              _buildTrimActionButtons(),
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
                      onHover: (event) => _handleHover(event, canvasWidth, canvasHeight),
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
                          onTapUp: (details) => _handleTap(details, canvasWidth, canvasHeight),
                          onScaleStart: (details) => _handleScaleStart(details, canvasWidth, canvasHeight),
                          onScaleUpdate: (details) => _handleScaleUpdate(details, canvasWidth, canvasHeight),
                          onScaleEnd: _handleScaleEnd,
                          child: RepaintBoundary(
                            child: CustomPaint(
                              size: Size(canvasWidth, canvasHeight),
                              painter: TimelinePainter(
                                words: widget.words,
                                currentTime: widget.currentTime,
                                duration: widget.duration,
                                pixelsPerSecond: pixelsPerSecond,
                                scrollOffset: _scrollOffset,
                                waveformAmplitudes: _waveformAmplitudes ?? const [],
                                trimStart: widget.trimStart,
                                trimEnd: widget.trimEnd,
                                theme: theme,
                                segments: widget.segments,
                                hoveredWordId: _hoveredWordId,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Custom Scrollbar Slider
              _buildHorizontalScrollbar(width, height),
            ],
          ),
        );
      },
    );
  }

  Widget _buildZoomControls(double timelineWidth) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.zoom_out, size: 16),
          tooltip: 'Zoom Out',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () {
            setState(() {
              _zoomLevel = (_zoomLevel - 0.5).clamp(0.5, 10.0);
              final pixelsPerSecond = _getPixelsPerSecond(timelineWidth);
              final maxScroll = (widget.duration * pixelsPerSecond) - timelineWidth;
              _scrollOffset = _scrollOffset.clamp(0.0, math.max(0.0, maxScroll));
            });
          },
        ),
        SizedBox(
          width: 80,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: const Color(0xFF06B6D4),
              inactiveTrackColor: Colors.white24,
              thumbColor: const Color(0xFF06B6D4),
              overlayColor: const Color(0xFF06B6D4).withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _zoomLevel.clamp(0.5, 10.0),
              min: 0.5,
              max: 10.0,
              onChanged: (value) {
                setState(() {
                  _zoomLevel = value.clamp(0.5, 10.0);
                  final pixelsPerSecond = _getPixelsPerSecond(timelineWidth);
                  final maxScroll = (widget.duration * pixelsPerSecond) - timelineWidth;
                  _scrollOffset = _scrollOffset.clamp(0.0, math.max(0.0, maxScroll));
                });
              },
            ),
          ),
        ),
        Text(
          'Zoom: ${_zoomLevel.toStringAsFixed(1)}x',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.zoom_in, size: 16),
          tooltip: 'Zoom In',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () {
            setState(() {
              _zoomLevel = (_zoomLevel + 0.5).clamp(0.5, 10.0);
              final pixelsPerSecond = _getPixelsPerSecond(timelineWidth);
              final maxScroll = (widget.duration * pixelsPerSecond) - timelineWidth;
              _scrollOffset = _scrollOffset.clamp(0.0, math.max(0.0, maxScroll));
            });
          },
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.fit_screen, size: 16),
          tooltip: 'Zoom to Fit',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () {
            setState(() {
              _zoomLevel = _getFitZoomLevel(timelineWidth);
              _scrollOffset = 0.0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHorizontalScrollbar(double width, double timelineHeight) {
    if (timelineHeight < 100) return const SizedBox.shrink();
    final trackWidth = width - 32.0;
    final pixelsPerSecond = _getPixelsPerSecond(width);
    final totalContentWidth = widget.duration * pixelsPerSecond;
    final maxScroll = totalContentWidth - width;
    final showThumb = maxScroll > 0;

    final thumbWidth = showThumb
        ? ((width / totalContentWidth) * trackWidth).clamp(40.0, trackWidth)
        : trackWidth;

    final scrollableTrackWidth = trackWidth - thumbWidth;
    final thumbLeft = (showThumb && maxScroll > 0)
        ? (_scrollOffset / maxScroll) * scrollableTrackWidth
        : 0.0;

    final Color trackColor = Colors.white.withValues(alpha: 0.05);
    final Color thumbColor = _isDraggingScrollbar
        ? AppTheme.accentSecondary // Accent color
        : (_isHoveringScrollbar ? Colors.white.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.25));

    final double thumbHeight = _isHoveringScrollbar || _isDraggingScrollbar ? 8.0 : 6.0;

    return Container(
      height: 18,
      margin: const EdgeInsets.only(bottom: 6, left: 16, right: 16),
      alignment: Alignment.center,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) {
          if (!showThumb) return;
          final localX = details.localPosition.dx;
          final targetLeft = localX - (thumbWidth / 2);
          final fraction = (scrollableTrackWidth > 0)
              ? (targetLeft / scrollableTrackWidth).clamp(0.0, 1.0)
              : 0.0;
          setState(() {
            _scrollOffset = (fraction * maxScroll).toDouble();
          });
        },
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Track Line
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Thumb
            if (showThumb)
              Positioned(
                left: thumbLeft,
                child: MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      _isHoveringScrollbar = true;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _isHoveringScrollbar = false;
                    });
                  },
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onHorizontalDragStart: (_) {
                      setState(() {
                        _isDraggingScrollbar = true;
                      });
                    },
                    onHorizontalDragUpdate: (details) {
                      if (scrollableTrackWidth <= 0) return;
                      final dx = details.delta.dx;
                      final scrollDelta = (dx / scrollableTrackWidth) * maxScroll;
                      setState(() {
                        _scrollOffset = (_scrollOffset + scrollDelta)
                            .clamp(0.0, maxScroll)
                            .toDouble();
                      });
                    },
                    onHorizontalDragEnd: (_) {
                      setState(() {
                        _isDraggingScrollbar = false;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: thumbHeight,
                      width: thumbWidth,
                      decoration: BoxDecoration(
                        color: thumbColor,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: (_isDraggingScrollbar || _isHoveringScrollbar)
                            ? [
                                BoxShadow(
                                  color: thumbColor.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrimActionButtons() {
    final buttons = [
      _buildActionPill(
        icon: Icons.content_cut,
        label: 'Split clip',
        onTap: () {
          final curr = widget.currentTime;
          if (curr > widget.trimStart && curr < widget.trimEnd) {
            ref.read(editorProvider.notifier).splitSegmentAtTime(curr);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Split timeline at ${curr.toStringAsFixed(2)}s.'),
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Playhead must be inside the active region to split.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
      _buildActionPill(
        icon: Icons.delete_outline,
        label: 'Remove clip',
        onTap: () {
          ref.read(editorProvider.notifier).toggleSegmentDeleted(widget.currentTime);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Toggled segment exclusion under playhead.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
      _buildActionPill(
        icon: Icons.restore,
        label: 'Reset to original',
        onTap: () {
          ref.read(editorProvider.notifier).resetSegments();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Reset all timeline splits and exclusions.'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons.map((btn) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: btn,
        )).toList(),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: AppTheme.glassDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: 20,
          borderOpacity: 0.08,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: AppTheme.iconMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSubtle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// WordEdgeHit coordinate lookup model
class WordEdgeHit {
  final WordSchema word;
  final String edge; // 'start' or 'end'
  const WordEdgeHit(this.word, this.edge);
}
