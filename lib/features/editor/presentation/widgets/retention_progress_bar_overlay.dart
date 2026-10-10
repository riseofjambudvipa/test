import 'package:flutter/material.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../core/video/retention_progress_bar_models.dart';

/// Overlay widget that renders the dynamic animated video retention progress bar
/// directly onto the video canvas (both in the editor player and in offstage export rendering).
///
/// In short-form video creation, this visual progress stripe keeps viewers glued
/// until the end of the video, significantly increasing audience retention rate.
class RetentionProgressBarOverlay extends StatelessWidget {
  final double currentTime;
  final double duration;
  final RetentionProgressBarConfig config;
  final double scale;

  const RetentionProgressBarOverlay({
    super.key,
    required this.currentTime,
    required this.duration,
    required this.config,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!config.enabled || duration <= 0.0) {
      return const SizedBox.shrink();
    }

    final double progress = (currentTime / duration).clamp(0.0, 1.0);
    final double barHeight = (config.height * scale).clamp(2.0, 40.0);
    final double edgeOffset = (config.padding * scale).clamp(0.0, 100.0);
    final Color barColor = ColorUtils.fromHex(config.color);
    final Color? trackColor = config.backgroundColor != null && config.backgroundColor!.isNotEmpty
        ? ColorUtils.fromHex(config.backgroundColor!)
        : null;

    final isTop = config.position == 'top';
    final radius = config.roundedCorners ? BorderRadius.circular(barHeight / 2) : BorderRadius.zero;

    return Positioned(
      top: isTop ? edgeOffset : null,
      bottom: !isTop ? edgeOffset : null,
      left: 0,
      right: 0,
      height: barHeight,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: Container(
            color: trackColor,
            width: double.infinity,
            height: barHeight,
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: radius,
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.35),
                      blurRadius: 4.0 * scale,
                      spreadRadius: 1.0 * scale,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
