import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/database/schemas/word.dart';
import '../../../../l10n/app_localizations.dart';

/// WordEdgeHit coordinate lookup model for timeline edge dragging
class WordEdgeHit {
  final WordSchema word;
  final String edge; // 'start' or 'end'
  const WordEdgeHit(this.word, this.edge);
}

/// Timeline coordinate hit tester for word track interactions and edge dragging.
class TimelineHitTester {
  const TimelineHitTester._();

  static bool isLocalYInWordTrack(double localY, double widgetHeight) {
    final trackTop = widgetHeight - 32.0;
    final trackBottom = widgetHeight - 8.0;
    return localY >= trackTop && localY <= trackBottom;
  }

  static WordSchema? findWordUnderCursor({
    required double localX,
    required double localY,
    required double widgetWidth,
    required double widgetHeight,
    required double scrollOffset,
    required double pixelsPerSecond,
    required List<WordSchema> words,
    required bool wordsAreOrdered,
  }) {
    if (!isLocalYInWordTrack(localY, widgetHeight)) return null;

    final timelineX = localX + scrollOffset;
    final time = timelineX / pixelsPerSecond;

    if (!wordsAreOrdered) {
      // Linear scan when words may be out of sorted order.
      for (final word in words) {
        final start = word.start ?? 0.0;
        final end = word.end ?? 0.0;
        if (time >= start && time <= end) return word;
      }
      return null;
    }

    // Binary search for the word containing time (requires sorted order).
    int low = 0;
    int high = words.length - 1;
    while (low <= high) {
      final mid = (low + high) >> 1;
      final word = words[mid];
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

  static WordEdgeHit? findWordEdgeHit({
    required double localX,
    required double localY,
    required double widgetWidth,
    required double widgetHeight,
    required double scrollOffset,
    required double pixelsPerSecond,
    required List<WordSchema> words,
    required bool wordsAreOrdered,
  }) {
    if (!isLocalYInWordTrack(localY, widgetHeight)) return null;

    final time = (localX + scrollOffset) / pixelsPerSecond;
    final isMobile = defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
    final edgeTolerance = isMobile ? 24.0 : 8.0;
    final toleranceTime = edgeTolerance / pixelsPerSecond;

    if (!wordsAreOrdered) {
      for (final word in words) {
        final start = word.start ?? 0.0;
        final end = word.end ?? 0.0;
        final startX = (start * pixelsPerSecond) - scrollOffset;
        final endX = (end * pixelsPerSecond) - scrollOffset;

        if ((localX - startX).abs() <= edgeTolerance) {
          return WordEdgeHit(word, 'start');
        }
        if ((localX - endX).abs() <= edgeTolerance) {
          return WordEdgeHit(word, 'end');
        }
      }
      return null;
    }

    // Find the first index where word.start >= time - toleranceTime using binary search
    int low = 0;
    int high = words.length - 1;
    int targetIdx = words.length;
    final minTime = time - toleranceTime;

    while (low <= high) {
      final mid = (low + high) >> 1;
      final start = words[mid].start ?? 0.0;
      if (start >= minTime) {
        targetIdx = mid;
        high = mid - 1;
      } else {
        low = mid + 1;
      }
    }

    final startScan = math.max(0, targetIdx - 1);
    final maxTime = time + toleranceTime;

    for (int i = startScan; i < words.length; i++) {
      final word = words[i];
      final start = word.start ?? 0.0;
      if (start > maxTime && (word.end ?? 0.0) > maxTime) {
        break;
      }
      final end = word.end ?? 0.0;
      final startX = (start * pixelsPerSecond) - scrollOffset;
      final endX = (end * pixelsPerSecond) - scrollOffset;

      if ((localX - startX).abs() <= edgeTolerance) {
        return WordEdgeHit(word, 'start');
      }
      if ((localX - endX).abs() <= edgeTolerance) {
        return WordEdgeHit(word, 'end');
      }
    }
    return null;
  }
}

/// Zoom control buttons and slider for timeline magnification
class TimelineZoomControls extends StatelessWidget {
  final double zoomLevel;
  final ValueChanged<double> onZoomChanged;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onZoomFit;
  final double timelineWidth;

  const TimelineZoomControls({
    super.key,
    required this.zoomLevel,
    required this.onZoomChanged,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onZoomFit,
    required this.timelineWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppTheme.cardBgElevated,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.borderGlass, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: AppTheme.isLight ? 0.04 : 0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildIconButton(
            icon: Icons.remove_rounded,
            tooltip: 'Zoom Out',
            onPressed: onZoomOut,
          ),
          SizedBox(
            width: 60,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                activeTrackColor: AppTheme.accentOrange,
                inactiveTrackColor: AppTheme.borderGlass,
                thumbColor: AppTheme.accentOrange,
                overlayColor: AppTheme.accentOrange.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: zoomLevel.clamp(0.5, 5.0),
                min: 0.5,
                max: 5.0,
                onChanged: (value) => onZoomChanged(value.clamp(0.5, 5.0)),
              ),
            ),
          ),
          _buildIconButton(
            icon: Icons.add_rounded,
            tooltip: 'Zoom In',
            onPressed: onZoomIn,
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => onZoomChanged(1.0),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.surfaceDim,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${zoomLevel.toStringAsFixed(1)}x',
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Container(
            height: 12,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: AppTheme.borderGlass,
          ),
          _buildIconButton(
            icon: Icons.fit_screen_rounded,
            tooltip: 'Zoom to Fit',
            onPressed: onZoomFit,
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      hoverColor: AppTheme.hoverBg,
      child: Padding(
        padding: const EdgeInsets.all(3.0),
        child: Tooltip(
          message: tooltip,
          child: Icon(icon, size: 15, color: AppTheme.secondaryText),
        ),
      ),
    );
  }
}

/// Horizontal scrollbar slider for the timeline canvas
class TimelineHorizontalScrollbar extends StatefulWidget {
  final double width;
  final double timelineHeight;
  final double scrollOffset;
  final double maxScroll;
  final double totalContentWidth;
  final ValueChanged<double> onScrollOffsetChanged;

  const TimelineHorizontalScrollbar({
    super.key,
    required this.width,
    required this.timelineHeight,
    required this.scrollOffset,
    required this.maxScroll,
    required this.totalContentWidth,
    required this.onScrollOffsetChanged,
  });

  @override
  State<TimelineHorizontalScrollbar> createState() =>
      _TimelineHorizontalScrollbarState();
}

class _TimelineHorizontalScrollbarState
    extends State<TimelineHorizontalScrollbar> {
  bool _isDraggingScrollbar = false;
  bool _isHoveringScrollbar = false;

  @override
  Widget build(BuildContext context) {
    if (widget.timelineHeight < 100) return const SizedBox.shrink();
    final trackWidth = widget.width - 32.0;
    final showThumb = widget.maxScroll > 0;

    final thumbWidth = showThumb
        ? ((widget.width / widget.totalContentWidth) * trackWidth)
            .clamp(40.0, trackWidth)
        : trackWidth;

    final scrollableTrackWidth = trackWidth - thumbWidth;
    final thumbLeft = (showThumb && widget.maxScroll > 0)
        ? (widget.scrollOffset / widget.maxScroll) * scrollableTrackWidth
        : 0.0;

    final Color trackColor = AppTheme.borderGlass.withValues(alpha: 0.22);
    final Color thumbColor = _isDraggingScrollbar
        ? AppTheme.accentOrange
        : (_isHoveringScrollbar
            ? AppTheme.accentOrange.withValues(alpha: 0.9)
            : AppTheme.secondaryText.withValues(alpha: 0.75));

    final double thumbHeight =
        _isHoveringScrollbar || _isDraggingScrollbar ? 13.0 : 10.0;

    return Container(
      height: 24,
      margin: const EdgeInsets.only(bottom: 4, left: 16, right: 16),
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
          widget.onScrollOffsetChanged(
              (fraction * widget.maxScroll).toDouble());
        },
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.borderGlass.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
            ),
            if (showThumb)
              Positioned(
                left: thumbLeft,
                child: MouseRegion(
                  onEnter: (_) =>
                      setState(() => _isHoveringScrollbar = true),
                  onExit: (_) =>
                      setState(() => _isHoveringScrollbar = false),
                  cursor: SystemMouseCursors.grab,
                  child: GestureDetector(
                    onHorizontalDragStart: (_) =>
                        setState(() => _isDraggingScrollbar = true),
                    onHorizontalDragUpdate: (details) {
                      if (scrollableTrackWidth <= 0) return;
                      final dx = details.delta.dx;
                      final scrollDelta =
                          (dx / scrollableTrackWidth) * widget.maxScroll;
                      widget.onScrollOffsetChanged(
                        (widget.scrollOffset + scrollDelta)
                            .clamp(0.0, widget.maxScroll)
                            .toDouble(),
                      );
                    },
                    onHorizontalDragEnd: (_) =>
                        setState(() => _isDraggingScrollbar = false),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: thumbHeight,
                      width: thumbWidth,
                      decoration: BoxDecoration(
                        color: thumbColor,
                        borderRadius: BorderRadius.circular(5),
                        boxShadow:
                            (_isDraggingScrollbar || _isHoveringScrollbar)
                                ? [
                                    BoxShadow(
                                      color:
                                          AppTheme.accentOrange.withValues(alpha: 0.35),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                      ),
                      alignment: Alignment.center,
                      child: thumbWidth >= 40
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 2,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Container(
                                  width: 2,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Action buttons to split clips, toggle exclusions, and reset splits
class TimelineTrimActionButtons extends StatelessWidget {
  final VoidCallback onSplit;
  final VoidCallback onToggleExclusion;
  final VoidCallback onReset;
  final VoidCallback? onRippleDelete;
  final bool isCompact;

  const TimelineTrimActionButtons({
    super.key,
    required this.onSplit,
    required this.onToggleExclusion,
    required this.onReset,
    this.onRippleDelete,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final buttons = [
      _buildActionPill(
        icon: Icons.content_cut,
        label: isCompact ? 'Split' : (l10n?.splitClip ?? 'Split clip'),
        tooltip: l10n?.splitClip ?? 'Split clip at playhead',
        onTap: onSplit,
        isCompact: isCompact,
      ),
      _buildActionPill(
        icon: Icons.delete_outline,
        label: isCompact ? 'Remove' : (l10n?.removeClip ?? 'Remove clip'),
        tooltip: l10n?.removeClip ?? 'Exclude clip under playhead',
        onTap: onToggleExclusion,
        isCompact: isCompact,
      ),
      if (onRippleDelete != null)
        _buildActionPill(
          icon: Icons.compress_rounded,
          label: isCompact ? 'Ripple' : 'Ripple delete gaps',
          tooltip: 'Ripple delete gaps and close dead air',
          onTap: onRippleDelete!,
          isCompact: isCompact,
        ),
      _buildActionPill(
        icon: Icons.restore,
        label: isCompact ? 'Reset' : (l10n?.resetToOriginal ?? 'Reset to original'),
        tooltip: l10n?.resetToOriginal ?? 'Reset all splits to original',
        onTap: onReset,
        isCompact: isCompact,
      ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons
            .map((btn) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: btn,
                ))
            .toList(),
      ),
    );
  }

  Widget _buildActionPill({
    required IconData icon,
    required String label,
    required String tooltip,
    required VoidCallback onTap,
    required bool isCompact,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: isCompact ? 4 : 6),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.cardBgElevated,
            borderRadius: 20,
            borderOpacity: 0.08,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: isCompact ? 11 : 12, color: AppTheme.iconMuted),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: isCompact ? 10 : 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSubtle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Verifies whether the provided word list is sorted strictly monotonically
/// by both start and end timestamps.
bool isWordsChronologicallyOrdered(List<WordSchema> words) {
  for (int i = 0; i + 1 < words.length; i++) {
    final a = words[i];
    final b = words[i + 1];
    if ((a.start ?? 0.0) > (b.start ?? 0.0) ||
        (a.end ?? 0.0) > (b.end ?? 0.0)) {
      return false;
    }
  }
  return true;
}
