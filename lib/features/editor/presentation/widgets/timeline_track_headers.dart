import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/premium_blur_dialog.dart';
import '../../../../core/video/background_music_models.dart';

/// Pinned left track header column (V1/A1 Video & Audio, A2 Added Music, T1 Captions)
/// Prevents scrolling timeline items from overlapping track labels and provides real
/// interactive controls (Mute/Unmute A1, Add/Manage A2 Audio, Show/Hide & Add T1 Captions).
class TimelineTrackHeaderColumn extends StatelessWidget {
  final double width;
  final double canvasHeight;
  final bool isAudioMuted;
  final bool isCaptionsVisible;
  final BackgroundMusicConfig? backgroundMusic;
  final VoidCallback onToggleAudioMute;
  final VoidCallback onToggleCaptionsVisible;
  final VoidCallback onAddCaptionAtPlayhead;
  final VoidCallback onOpenAudioManager;

  const TimelineTrackHeaderColumn({
    super.key,
    required this.width,
    required this.canvasHeight,
    required this.isAudioMuted,
    required this.isCaptionsVisible,
    required this.backgroundMusic,
    required this.onToggleAudioMute,
    required this.onToggleCaptionsVisible,
    required this.onAddCaptionAtPlayhead,
    required this.onOpenAudioManager,
  });

  @override
  Widget build(BuildContext context) {
    final hasMusic = backgroundMusic != null && backgroundMusic!.hasMusic;
    final captionTrackHeight = (canvasHeight - math.max(38.0, canvasHeight - 32.0)).clamp(20.0, 32.0);
    final isCompact = width < 72;

    return Container(
      width: width,
      height: canvasHeight,
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.72),
        border: Border(
          right: BorderSide(color: AppTheme.borderGlass, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Ruler corner (24px): "+ Audio" button
          Container(
            height: 24,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceDim.withValues(alpha: 0.6),
              border: Border(
                bottom: BorderSide(color: AppTheme.borderGlass, width: 1.0),
              ),
            ),
            child: Tooltip(
              message: hasMusic
                  ? 'Manage Added Audio Track (A2) & Ducking'
                  : 'Add Audio / Background Music Track (+ Audio)',
              child: InkWell(
                onTap: onOpenAudioManager,
                borderRadius: BorderRadius.circular(4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      hasMusic ? Icons.library_music_rounded : Icons.add_rounded,
                      size: 11,
                      color: hasMusic ? AppTheme.accentCyan : AppTheme.accentOrange,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        hasMusic ? 'Audio' : '+Audio',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: hasMusic ? AppTheme.accentCyan : AppTheme.primaryText,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Main Video / Audio Track (V1 • A1)
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 3 : 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Tooltip(
                      message: 'Main Video & Original Audio Track (V1 • A1) — Click for Audio Settings',
                      child: InkWell(
                        onTap: onOpenAudioManager,
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: isAudioMuted
                                ? AppTheme.accentRed.withValues(alpha: 0.14)
                                : AppTheme.accentOrange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isAudioMuted
                                  ? AppTheme.accentRed.withValues(alpha: 0.4)
                                  : AppTheme.accentOrange.withValues(alpha: 0.35),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            isCompact ? 'A1' : 'V1•A1',
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: isAudioMuted ? AppTheme.accentRed : AppTheme.accentOrange,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Tooltip(
                    message: isAudioMuted
                        ? 'Unmute Original Video Audio (A1)'
                        : 'Mute Original Video Audio (A1)',
                    child: InkWell(
                      onTap: onToggleAudioMute,
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Icon(
                          isAudioMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          size: 13,
                          color: isAudioMuted ? AppTheme.accentRed : AppTheme.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Added Background Music Track (A2) when active
          if (hasMusic && canvasHeight >= 76)
            Container(
              height: 20,
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 3 : 6),
              decoration: BoxDecoration(
                color: AppTheme.accentCyan.withValues(alpha: 0.08),
                border: Border(
                  top: BorderSide(color: AppTheme.borderGlass, width: 1.0),
                ),
              ),
              child: Tooltip(
                message: 'Added Audio Track (A2) — Click to adjust volume, auto-ducking, or remove',
                child: InkWell(
                  onTap: onOpenAudioManager,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'A2',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                      Icon(
                        Icons.music_note_rounded,
                        size: 11,
                        color: AppTheme.accentCyan,
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 4. Captions Track (T1)
          Container(
            height: captionTrackHeight,
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 3 : 6),
            decoration: BoxDecoration(
              color: AppTheme.cardBgElevated.withValues(alpha: 0.65),
              border: Border(
                top: BorderSide(color: AppTheme.borderGlass, width: 1.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Tooltip(
                  message: 'Captions Track (T1) — Click + to add caption at playhead',
                  child: InkWell(
                    onTap: onAddCaptionAtPlayhead,
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: isCaptionsVisible
                            ? AppTheme.accentCyan.withValues(alpha: 0.14)
                            : AppTheme.surfaceDim,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isCaptionsVisible
                              ? AppTheme.accentCyan.withValues(alpha: 0.4)
                              : AppTheme.borderGlass,
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'T1',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: isCaptionsVisible
                                  ? AppTheme.accentCyan
                                  : AppTheme.mutedText,
                            ),
                          ),
                          if (!isCompact) ...[
                            const SizedBox(width: 2),
                            Icon(
                              Icons.add_rounded,
                              size: 10,
                              color: isCaptionsVisible
                                  ? AppTheme.accentCyan
                                  : AppTheme.mutedText,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                Tooltip(
                  message: isCaptionsVisible
                      ? 'Hide Captions Track (T1) on Video Preview'
                      : 'Show Captions Track (T1) on Video Preview',
                  child: InkWell(
                    onTap: onToggleCaptionsVisible,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        isCaptionsVisible
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                        size: 13,
                        color: isCaptionsVisible
                            ? AppTheme.secondaryText
                            : AppTheme.mutedText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for managing Timeline Audio Tracks:
/// - V1 • A1 (Original Video Audio mute/unmute)
/// - A2 (+ Audio / Background Music file picker, volume slider, speech auto-ducking, remove)
void showTimelineAudioManagerDialog({
  required BuildContext context,
  required bool isAudioMuted,
  required VoidCallback onToggleAudioMute,
  required BackgroundMusicConfig currentConfig,
  required ValueChanged<BackgroundMusicConfig> onUpdateMusicConfig,
}) {
  BackgroundMusicConfig workingConfig = currentConfig;
  bool localMuted = isAudioMuted;

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final hasMusic = workingConfig.hasMusic;
          final musicFileName = (workingConfig.musicPath ?? '')
              .split(RegExp(r'[/\\]'))
              .where((s) => s.isNotEmpty)
              .lastOrNull ??
              'No audio track selected';

          return PremiumBlurDialog(
            maxWidth: 440,
            glowColor: AppTheme.accentCyan,
            glowOpacity: 0.1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.equalizer_rounded, color: AppTheme.accentOrange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'TIMELINE AUDIO & TRACKS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: AppTheme.primaryText,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close, size: 18, color: AppTheme.secondaryText),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                Divider(color: AppTheme.dividerColor, height: 16),

                // Track A1: Original Video Audio
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.glassDecoration(
                    color: AppTheme.cardBgElevated,
                    borderRadius: 10,
                    borderOpacity: 0.1,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: localMuted
                              ? AppTheme.accentRed.withValues(alpha: 0.15)
                              : AppTheme.accentOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          'V1 • A1',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: localMuted ? AppTheme.accentRed : AppTheme.accentOrange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Original Video Audio',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryText,
                              ),
                            ),
                            Text(
                              localMuted ? 'Muted on playback' : 'Active on timeline',
                              style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: Icon(
                          localMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                          size: 15,
                          color: localMuted ? AppTheme.accentRed : AppTheme.primaryText,
                        ),
                        label: Text(
                          localMuted ? 'UNMUTE' : 'MUTE A1',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: localMuted ? AppTheme.accentRed : AppTheme.primaryText,
                          ),
                        ),
                        onPressed: () {
                          onToggleAudioMute();
                          setModalState(() {
                            localMuted = !localMuted;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Track A2: Added Background Audio / Music
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: AppTheme.glassDecoration(
                    color: AppTheme.cardBgElevated,
                    borderRadius: 10,
                    borderOpacity: 0.1,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.accentCyan.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'A2 • AUDIO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: AppTheme.accentCyan,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              hasMusic ? musicFileName : 'Add Background Music / Audio Track',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryText,
                              ),
                            ),
                          ),
                          if (hasMusic)
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Remove A2 Audio Track',
                              icon: Icon(Icons.delete_outline, size: 18, color: AppTheme.accentRed),
                              onPressed: () {
                                workingConfig = workingConfig.copyWith(musicPath: '');
                                onUpdateMusicConfig(workingConfig);
                                setModalState(() {});
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.audio_file_rounded, size: 16),
                          label: Text(
                            hasMusic ? 'CHANGE AUDIO FILE (A2)' : '+ ADD AUDIO / MUSIC TRACK (A2)',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                            foregroundColor: AppTheme.onAccentText,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final result = await FilePicker.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac'],
                            );
                            final pickedPath = result?.files.single.path;
                            if (pickedPath != null && pickedPath.isNotEmpty) {
                              workingConfig = workingConfig.copyWith(musicPath: pickedPath);
                              onUpdateMusicConfig(workingConfig);
                              setModalState(() {});
                            }
                          },
                        ),
                      ),
                      if (hasMusic) ...[
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'A2 Track Volume',
                              style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                            ),
                            Text(
                              '${(workingConfig.volume * 100).round()}%',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentCyan,
                              ),
                            ),
                          ],
                        ),
                        SliderTheme(
                          data: AppTheme.premiumSliderTheme(context),
                          child: Slider(
                            value: workingConfig.volume.clamp(0.0, 1.0),
                            min: 0.0,
                            max: 1.0,
                            onChanged: (val) {
                              workingConfig = workingConfig.copyWith(volume: val);
                              onUpdateMusicConfig(workingConfig);
                              setModalState(() {});
                            },
                          ),
                        ),
                        SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: AppTheme.accentCyan,
                          title: Text(
                            'Auto-Ducking During Speech (-12dB)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          subtitle: Text(
                            'Automatically lowers A2 music volume when T1 captions are spoken',
                            style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                          ),
                          value: workingConfig.enableDucking,
                          onChanged: (val) {
                            workingConfig = workingConfig.copyWith(enableDucking: val);
                            onUpdateMusicConfig(workingConfig);
                            setModalState(() {});
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
