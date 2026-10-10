import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/time_format_utils.dart';
import '../../../../core/database/schemas/project.dart';
import '../../../../core/utils/platform_utils.dart';
import 'safe_zone_overlay.dart';

class EditorVideoControls extends StatelessWidget {
  final Project project;
  final double currentTime;
  final bool isPlaying;
  final double volume;
  final bool isMuted;
  final double playbackRate;
  final bool isFullscreen;
  final SafeZonePlatform safeZoneGuide;
  final VoidCallback onTogglePlayback;
  final ValueChanged<double> onSeek;
  final ValueChanged<double> onSeekEnd;
  final VoidCallback onToggleMute;
  final ValueChanged<double> onSetVolume;
  final ValueChanged<double> onPlaybackRateChanged;
  final VoidCallback onToggleFullscreen;
  final ValueChanged<SafeZonePlatform>? onSafeZoneChanged;
  final bool isProxyActive;
  final bool isGeneratingProxy;
  final double proxyProgress;
  final VoidCallback? onToggleProxy;

  const EditorVideoControls({
    super.key,
    required this.project,
    required this.currentTime,
    required this.isPlaying,
    required this.volume,
    required this.isMuted,
    required this.playbackRate,
    required this.isFullscreen,
    this.safeZoneGuide = SafeZonePlatform.none,
    this.isProxyActive = false,
    this.isGeneratingProxy = false,
    this.proxyProgress = 0.0,
    this.onToggleProxy,
    required this.onTogglePlayback,
    required this.onSeek,
    required this.onSeekEnd,
    required this.onToggleMute,
    required this.onSetVolume,
    required this.onPlaybackRateChanged,
    required this.onToggleFullscreen,
    this.onSafeZoneChanged,
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
          // Seek bar only in fullscreen mode (in editor mode, the main timeline below is the scrubber)
          if (isFullscreen)
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
              final showVolumeSlider = !isMobile && constraints.maxWidth >= 520;
              final showRateButton = constraints.maxWidth >= 450;
              final showTimeIndicator = constraints.maxWidth >= 360;

              return Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(4),
                    icon: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      size: 26,
                      color: AppTheme.primaryText,
                    ),
                    onPressed: onTogglePlayback,
                  ),
                  const SizedBox(width: 4),
                  if (showTimeIndicator)
                    Text(
                      '${TimeFormatUtils.formatSmartTime(currentTime)} / ${TimeFormatUtils.formatSmartTime(project.duration)}',
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
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(4),
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
                  if (onSafeZoneChanged != null)
                    PopupMenuButton<SafeZonePlatform>(
                      tooltip: 'Safe Zone Guides (TikTok, Reels, Shorts)',
                      icon: Icon(
                        Icons.crop_free_rounded,
                        size: 20,
                        color: safeZoneGuide != SafeZonePlatform.none
                            ? AppTheme.accentCyan
                            : AppTheme.secondaryText,
                      ),
                      color: AppTheme.cardBgElevated,
                      onSelected: onSafeZoneChanged,
                      itemBuilder: (context) => SafeZonePlatform.values.map((p) => PopupMenuItem(
                        value: p,
                        child: Row(
                          children: [
                            Icon(
                              safeZoneGuide == p ? Icons.radio_button_checked : Icons.radio_button_off,
                              size: 14,
                              color: safeZoneGuide == p ? AppTheme.accentCyan : AppTheme.secondaryText,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                p.label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: safeZoneGuide == p ? AppTheme.accentCyan : AppTheme.primaryText,
                                  fontWeight: safeZoneGuide == p ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                    ),
                  if (onToggleProxy != null && !kIsWeb)
                    isGeneratingProxy
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                value: proxyProgress > 0 ? proxyProgress : null,
                                strokeWidth: 2,
                                color: AppTheme.accentLime,
                              ),
                            ),
                          )
                        : IconButton(
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                            padding: const EdgeInsets.all(4),
                            icon: Icon(
                              isProxyActive ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                              size: 20,
                              color: isProxyActive ? AppTheme.accentLime : AppTheme.secondaryText,
                            ),
                            tooltip: isProxyActive
                                ? 'Proxy Active (Fluid 60fps) — Tap for Original Media'
                                : 'Original Media — Tap to Generate/Switch to 720p Proxy',
                            onPressed: onToggleProxy,
                          ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    padding: const EdgeInsets.all(4),
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
      child: mainContent,
    );
  }
}
