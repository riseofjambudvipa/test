import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/database/schemas/project.dart';
import '../../../../core/utils/platform_utils.dart';

class EditorVideoControls extends StatelessWidget {
  final Project project;
  final double currentTime;
  final bool isPlaying;
  final double volume;
  final bool isMuted;
  final double playbackRate;
  final bool isFullscreen;
  final VoidCallback onTogglePlayback;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onSeekEnd;
  final VoidCallback onToggleMute;
  final ValueChanged<double> onSetVolume;
  final ValueChanged<double> onPlaybackRateChanged;
  final VoidCallback onToggleFullscreen;

  const EditorVideoControls({
    super.key,
    required this.project,
    required this.currentTime,
    required this.isPlaying,
    required this.volume,
    required this.isMuted,
    required this.playbackRate,
    required this.isFullscreen,
    required this.onTogglePlayback,
    required this.onSeek,
    required this.onSeekEnd,
    required this.onToggleMute,
    required this.onSetVolume,
    required this.onPlaybackRateChanged,
    required this.onToggleFullscreen,
  });

  @override
  Widget build(BuildContext context) {
    final isTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

    final mainContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: AppTheme.glassDecoration(
        color: isTesting ? AppTheme.cardBg : AppTheme.cardBg.withValues(alpha: 0.55),
        borderRadius: 12,
        borderOpacity: 0.08,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Seek bar
          SliderTheme(
            data: AppTheme.premiumSliderTheme(context),
            child: Slider(
              value: currentTime.clamp(0.0, project.duration),
              min: 0,
              max: project.duration > 0 ? project.duration : 1,
              onChanged: onSeek,
              onChangeEnd: onSeekEnd,
            ),
          ),
          // Controls row
          LayoutBuilder(
            builder: (context, constraints) {
              final showVolumeSlider = !isMobile && constraints.maxWidth >= 400;
              final showTimeIndicator = constraints.maxWidth >= 310;
              final showRateButton = constraints.maxWidth >= 400;

              return Row(
                children: [
                  IconButton(
                    icon: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 28,
                      color: AppTheme.primaryText,
                    ),
                    onPressed: onTogglePlayback,
                  ),
                  const SizedBox(width: 4),
                  if (showTimeIndicator)
                    Text(
                      '${_formatTime(currentTime)} / ${_formatTime(project.duration)}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  const Spacer(),
                  // Volume control
                  IconButton(
                    icon: Icon(
                      isMuted ? Icons.volume_off : (volume > 0.5 ? Icons.volume_up : Icons.volume_down),
                      size: 20,
                      color: AppTheme.secondaryText,
                    ),
                    onPressed: onToggleMute,
                  ),
                  if (showVolumeSlider)
                    SizedBox(
                      width: 80,
                      child: SliderTheme(
                        data: AppTheme.premiumSliderTheme(context).copyWith(
                          activeTrackColor: AppTheme.secondaryText,
                          thumbColor: AppTheme.primaryText,
                        ),
                        child: Slider(
                          value: isMuted ? 0.0 : volume,
                          onChanged: onSetVolume,
                        ),
                      ),
                    ),
                  if (showRateButton) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<double>(
                      icon: Text(
                        '${playbackRate}x',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryText),
                      ),
                      tooltip: 'Playback Speed',
                      color: AppTheme.cardBg,
                      itemBuilder: (context) => [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 2.0]
                          .map((rate) => PopupMenuItem(
                                value: rate,
                                child: Text('${rate}x', style: TextStyle(fontSize: 12, color: AppTheme.primaryText)),
                              ))
                          .toList(),
                      onSelected: onPlaybackRateChanged,
                    ),
                  ],
                  IconButton(
                    icon: Icon(
                      isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                      size: 22,
                      color: AppTheme.secondaryText,
                    ),
                    tooltip: isFullscreen ? 'Exit Fullscreen' : 'Fullscreen Mode',
                    onPressed: onToggleFullscreen,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    if (isTesting) {
      return mainContent;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: mainContent,
      ),
    );
  }

  String _formatTime(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    final ms = ((seconds % 1) * 1000).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}.${ms.toString().padLeft(3, '0')}';
  }
}
