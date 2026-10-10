import 'package:flutter/material.dart';
import '../../../../app/theme.dart';

/// Target social video platforms for UI safe-zone guide overlays.
enum SafeZonePlatform {
  none,
  tikTok,
  instagramReels,
  youTubeShorts,
  broadcastSafe;

  String get label => switch (this) {
    SafeZonePlatform.none => 'Guides: Off',
    SafeZonePlatform.tikTok => 'TikTok Safe Zone (9:16)',
    SafeZonePlatform.instagramReels => 'Reels Safe Zone (9:16)',
    SafeZonePlatform.youTubeShorts => 'YouTube Shorts (9:16)',
    SafeZonePlatform.broadcastSafe => 'Broadcast Safe (SMPTE)',
  };

  String get shortLabel => switch (this) {
    SafeZonePlatform.none => 'Off',
    SafeZonePlatform.tikTok => 'TikTok',
    SafeZonePlatform.instagramReels => 'Reels',
    SafeZonePlatform.youTubeShorts => 'Shorts',
    SafeZonePlatform.broadcastSafe => 'SMPTE',
  };
}

/// An overlay widget rendered on top of the video viewport showing safe zones,
/// platform UI element silhouettes, and danger margins for short-form video.
class SafeZoneOverlay extends StatelessWidget {
  final SafeZonePlatform platform;
  final double videoWidth;
  final double videoHeight;

  const SafeZoneOverlay({
    super.key,
    required this.platform,
    this.videoWidth = 360,
    this.videoHeight = 640,
  });

  @override
  Widget build(BuildContext context) {
    if (platform == SafeZonePlatform.none) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final videoAspect = (videoWidth > 0 && videoHeight > 0)
              ? videoWidth / videoHeight
              : 9 / 16;
          final containerAspect = constraints.maxWidth / constraints.maxHeight;

          double videoW, videoH, videoLeft, videoTop;
          if (videoAspect < containerAspect) {
            videoH = constraints.maxHeight;
            videoW = videoH * videoAspect;
            videoLeft = (constraints.maxWidth - videoW) / 2;
            videoTop = 0;
          } else {
            videoW = constraints.maxWidth;
            videoH = videoW / videoAspect;
            videoLeft = 0;
            videoTop = (constraints.maxHeight - videoH) / 2;
          }

          return Stack(
            children: [
              Positioned(
                left: videoLeft,
                top: videoTop,
                width: videoW,
                height: videoH,
                child: CustomPaint(
                  painter: _SafeZonePainter(
                    platform: platform,
                    isLight: AppTheme.isLight,
                  ),
                ),
              ),
              // Subtle badge at top-left of video frame
              Positioned(
                left: videoLeft + 8,
                top: videoTop + 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppTheme.accentCyan.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.crop_free_rounded, size: 11, color: AppTheme.accentCyan),
                      const SizedBox(width: 4),
                      Text(
                        platform.shortLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SafeZonePainter extends CustomPainter {
  final SafeZonePlatform platform;
  final bool isLight;

  _SafeZonePainter({required this.platform, required this.isLight});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    switch (platform) {
      case SafeZonePlatform.none:
        break;

      case SafeZonePlatform.broadcastSafe:
        _paintBroadcastSafe(canvas, w, h);
        break;

      case SafeZonePlatform.tikTok:
        _paintTikTokSafe(canvas, w, h);
        break;

      case SafeZonePlatform.instagramReels:
        _paintReelsSafe(canvas, w, h);
        break;

      case SafeZonePlatform.youTubeShorts:
        _paintShortsSafe(canvas, w, h);
        break;
    }
  }

  void _paintBroadcastSafe(Canvas canvas, double w, double h) {
    final actionSafePaint = Paint()
      ..color = const Color(0xFF06B6D4).withValues(alpha: 0.7) // cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final titleSafePaint = Paint()
      ..color = const Color(0xFFF97316).withValues(alpha: 0.7) // orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // 90% Action Safe
    final actionRect = Rect.fromLTWH(w * 0.05, h * 0.05, w * 0.90, h * 0.90);
    _drawDashedRect(canvas, actionRect, actionSafePaint);

    // 80% Title Safe
    final titleRect = Rect.fromLTWH(w * 0.10, h * 0.10, w * 0.80, h * 0.80);
    _drawDashedRect(canvas, titleRect, titleSafePaint);

    // Center Crosshair
    final crossPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(w * 0.5 - 12, h * 0.5), Offset(w * 0.5 + 12, h * 0.5), crossPaint);
    canvas.drawLine(Offset(w * 0.5, h * 0.5 - 12), Offset(w * 0.5, h * 0.5 + 12), crossPaint);
  }

  void _paintTikTokSafe(Canvas canvas, double w, double h) {
    final dangerFill = Paint()
      ..color = Colors.red.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final guideBorder = Paint()
      ..color = const Color(0xFF00F2FE).withValues(alpha: 0.4) // TikTok cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final iconOutline = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Top Header Danger Area (~9% height)
    final topRect = Rect.fromLTWH(0, 0, w, h * 0.09);
    canvas.drawRect(topRect, dangerFill);

    // Bottom Metadata & Nav Danger Area (~22% height)
    final bottomRect = Rect.fromLTWH(0, h * 0.78, w, h * 0.22);
    canvas.drawRect(bottomRect, dangerFill);

    // Right Action Rail (~18% width from right, between 35% and 78% height)
    final rightRail = Rect.fromLTWH(w * 0.82, h * 0.35, w * 0.18, h * 0.43);
    canvas.drawRect(rightRail, dangerFill);

    // Safe Content Zone
    final safeRect = Rect.fromLTRB(w * 0.08, h * 0.09, w * 0.82, h * 0.78);
    _drawDashedRect(canvas, safeRect, guideBorder);

    // Right rail button silhouettes (Avatar, Like, Comment, Bookmark, Share, Disc)
    final railCenterX = w * 0.91;
    final buttonRadius = (w * 0.045).clamp(10.0, 18.0);
    final buttonYPositions = [0.40, 0.48, 0.56, 0.64, 0.72, 0.80];
    for (final pct in buttonYPositions) {
      canvas.drawCircle(Offset(railCenterX, h * pct), buttonRadius, iconOutline);
    }
  }

  void _paintReelsSafe(Canvas canvas, double w, double h) {
    final dangerFill = Paint()
      ..color = Colors.purple.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final guideBorder = Paint()
      ..color = const Color(0xFFE1306C).withValues(alpha: 0.45) // Instagram pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final iconOutline = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Top Header (~8%)
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.08), dangerFill);

    // Bottom Metadata (~18%)
    canvas.drawRect(Rect.fromLTWH(0, h * 0.82, w, h * 0.18), dangerFill);

    // Right Rail (~16% width, between 42% and 82%)
    canvas.drawRect(Rect.fromLTWH(w * 0.84, h * 0.42, w * 0.16, h * 0.40), dangerFill);

    // Safe Content Zone
    final safeRect = Rect.fromLTRB(w * 0.06, h * 0.08, w * 0.84, h * 0.82);
    _drawDashedRect(canvas, safeRect, guideBorder);

    // Right rail buttons (Like, Comment, Share, More, Audio)
    final railCenterX = w * 0.92;
    final buttonRadius = (w * 0.042).clamp(9.0, 16.0);
    final buttonYPositions = [0.48, 0.56, 0.64, 0.72, 0.80];
    for (final pct in buttonYPositions) {
      canvas.drawCircle(Offset(railCenterX, h * pct), buttonRadius, iconOutline);
    }
  }

  void _paintShortsSafe(Canvas canvas, double w, double h) {
    final dangerFill = Paint()
      ..color = Colors.red.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    final guideBorder = Paint()
      ..color = const Color(0xFFFF0000).withValues(alpha: 0.4) // YouTube Red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final iconOutline = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Top Header (~9%)
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.09), dangerFill);

    // Bottom Channel & Title (~16%)
    canvas.drawRect(Rect.fromLTWH(0, h * 0.84, w, h * 0.16), dangerFill);

    // Right Rail (~18% width, between 38% and 84%)
    canvas.drawRect(Rect.fromLTWH(w * 0.82, h * 0.38, w * 0.18, h * 0.46), dangerFill);

    // Safe Content Zone
    final safeRect = Rect.fromLTRB(w * 0.06, h * 0.09, w * 0.82, h * 0.84);
    _drawDashedRect(canvas, safeRect, guideBorder);

    // Right rail buttons (Like, Dislike, Comments, Share, Remix, Sound)
    final railCenterX = w * 0.91;
    final buttonRadius = (w * 0.044).clamp(10.0, 17.0);
    final buttonYPositions = [0.42, 0.50, 0.58, 0.66, 0.74, 0.82];
    for (final pct in buttonYPositions) {
      canvas.drawCircle(Offset(railCenterX, h * pct), buttonRadius, iconOutline);
    }
  }

  void _drawDashedRect(Canvas canvas, Rect rect, Paint paint, {double dash = 6, double gap = 4}) {
    // Top line
    _drawDashedLine(canvas, rect.topLeft, rect.topRight, paint, dash, gap);
    // Right line
    _drawDashedLine(canvas, rect.topRight, rect.bottomRight, paint, dash, gap);
    // Bottom line
    _drawDashedLine(canvas, rect.bottomRight, rect.bottomLeft, paint, dash, gap);
    // Left line
    _drawDashedLine(canvas, rect.bottomLeft, rect.topLeft, paint, dash, gap);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint, double dash, double gap) {
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = (dx * dx + dy * dy);
    if (distance <= 0) return;
    final totalLength = (dx != 0 ? dx.abs() : dy.abs());
    final ux = dx / totalLength;
    final uy = dy / totalLength;

    double current = 0;
    while (current < totalLength) {
      final len = (current + dash <= totalLength) ? dash : totalLength - current;
      canvas.drawLine(
        Offset(p1.dx + ux * current, p1.dy + uy * current),
        Offset(p1.dx + ux * (current + len), p1.dy + uy * (current + len)),
        paint,
      );
      current += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _SafeZonePainter oldDelegate) {
    return oldDelegate.platform != platform || oldDelegate.isLight != isLight;
  }
}
