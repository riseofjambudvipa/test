import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/video/b_roll_models.dart';

/// Real-time live video overlay for B-Roll cutaways and Picture-in-Picture (PiP).
/// Renders above the primary video player and below captions.
class BRollOverlay extends StatelessWidget {
  final double currentTime;
  final List<BRollClip> bRollClips;
  final double videoWidth;
  final double videoHeight;

  const BRollOverlay({
    super.key,
    required this.currentTime,
    required this.bRollClips,
    this.videoWidth = 1920,
    this.videoHeight = 1080,
  });

  @override
  Widget build(BuildContext context) {
    if (bRollClips.isEmpty) return const SizedBox.shrink();

    // Find active clip at the current playhead timestamp
    final activeClip = bRollClips.cast<BRollClip?>().firstWhere(
      (clip) =>
          clip != null &&
          currentTime >= clip.startTime &&
          currentTime <= clip.endTime,
      orElse: () => null,
    );

    if (activeClip == null) return const SizedBox.shrink();

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final parentWidth = constraints.maxWidth;
          final parentHeight = constraints.maxHeight;

          return Stack(
            fit: StackFit.expand,
            children: [
              if (activeClip.isPictureInPicture)
                _buildPipOverlay(activeClip, parentWidth, parentHeight)
              else
                _buildFullscreenCutaway(activeClip, parentWidth, parentHeight),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFullscreenCutaway(
      BRollClip clip, double parentWidth, double parentHeight) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildMediaContent(clip, fit: BoxFit.cover),
        // Subtle badge indicating cutaway in editor preview
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppTheme.accentCyan.withValues(alpha: 0.6),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.video_library, size: 12, color: AppTheme.accentCyan),
                const SizedBox(width: 4),
                Text(
                  'B-ROLL CUTAWAY: ${clip.name}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentCyan,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPipOverlay(
      BRollClip clip, double parentWidth, double parentHeight) {
    // 36% width of viewport, 16:9 aspect ratio
    final pipWidth = (parentWidth * 0.36).clamp(100.0, 360.0);
    final pipHeight = pipWidth * (9.0 / 16.0);
    const padding = 16.0;

    double? top;
    double? bottom;
    double? left;
    double? right;

    switch (clip.pipPosition) {
      case 'top_left':
        top = padding;
        left = padding;
        break;
      case 'bottom_right':
        bottom = padding;
        right = padding;
        break;
      case 'bottom_left':
        bottom = padding;
        left = padding;
        break;
      case 'top_right':
      default:
        top = padding;
        right = padding;
        break;
    }

    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      width: pipWidth,
      height: pipHeight,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.accentOrange.withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6.5),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildMediaContent(clip, fit: BoxFit.cover),
              // Mini PiP badge
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.picture_in_picture_alt,
                          size: 10, color: AppTheme.accentOrange),
                      const SizedBox(width: 3),
                      Text(
                        'PiP',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent(BRollClip clip, {required BoxFit fit}) {
    if (!kIsWeb && File(clip.mediaPath).existsSync()) {
      if (!clip.isVideo) {
        return Image.file(
          File(clip.mediaPath),
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallback(clip, error: true),
        );
      } else {
        // Video file preview placeholder / banner
        return Container(
          color: Colors.black87,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.movie_outlined, size: 28, color: AppTheme.accentCyan),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    clip.name,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${(clip.endTime - clip.startTime).toStringAsFixed(1)}s B-Roll',
                  style: TextStyle(fontSize: 8, color: AppTheme.mutedText),
                ),
              ],
            ),
          ),
        );
      }
    }

    return _buildFallback(clip);
  }

  Widget _buildFallback(BRollClip clip, {bool error = false}) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              error ? Icons.broken_image_outlined : Icons.image_outlined,
              size: 24,
              color: error ? AppTheme.accentRed : AppTheme.mutedText,
            ),
            const SizedBox(height: 4),
            Text(
              clip.name,
              style: TextStyle(fontSize: 9, color: AppTheme.secondaryText),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
