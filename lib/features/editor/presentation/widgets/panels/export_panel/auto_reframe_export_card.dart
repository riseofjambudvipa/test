import 'package:flutter/material.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/video/viral_clip_models.dart';
import '../../../../../../l10n/app_localizations.dart';

/// Card allowing creators to choose the aspect conversion / auto-reframing mode
/// for full project video exports (e.g. converting 16:9 landscape to 9:16 vertical
/// or tuning vertical crop framing for TikTok, Instagram Reels, and YouTube Shorts).
class AutoReframeExportCard extends StatelessWidget {
  final AspectConversionMode? selectedMode;
  final ValueChanged<AspectConversionMode?> onModeChanged;
  final bool isLandscapeProject;

  const AutoReframeExportCard({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
    required this.isLandscapeProject,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bool isReframeActive = selectedMode != null;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 10,
      borderOpacity: isReframeActive ? 0.35 : 0.1,
      glowColor: isReframeActive ? AppTheme.accentOrange : null,
      glowOpacity: isReframeActive ? 0.25 : 0.0,
      color: isReframeActive
          ? AppTheme.accentOrange.withValues(alpha: 0.08)
          : AppTheme.cardBg.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: AppTheme.glassDecoration(
                  color: (isReframeActive ? AppTheme.accentOrange : AppTheme.mutedText)
                      .withValues(alpha: 0.15),
                  borderRadius: 8,
                  borderOpacity: 0.2,
                ),
                child: Icon(
                  Icons.crop_portrait_rounded,
                  color: isReframeActive ? AppTheme.accentOrange : AppTheme.mutedText,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          isLandscapeProject
                              ? 'Export 9:16 Vertical Reframe'
                              : 'Vertical Reframe Mode',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isReframeActive
                                ? AppTheme.accentOrange
                                : AppTheme.primaryText,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'AI AUTO-FRAME',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentOrange,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isLandscapeProject
                          ? 'Auto-convert landscape video to 9:16 vertical canvas (1080×1920) for TikTok, Reels & Shorts'
                          : (l10n?.reframeTargetCanvas ??
                              'Target canvas: 1080 × 1920 (TikTok, YouTube Shorts, Instagram Reels)'),
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.secondaryText,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLandscapeProject) ...[
            _buildModeTile(
              isSelected: selectedMode == null,
              onTap: () => onModeChanged(null),
              title: 'Original Canvas (16:9 Landscape)',
              description: 'Preserves the original wide aspect ratio without 9:16 vertical reframing.',
              icon: Icons.tv_rounded,
            ),
            const SizedBox(height: 6),
          ],
          _buildModeTile(
            isSelected: selectedMode == AspectConversionMode.blurPillarbox,
            onTap: () => onModeChanged(AspectConversionMode.blurPillarbox),
            title: l10n?.reframeModeBlurPillarbox ?? 'Blur Pillarbox (Recommended)',
            description: l10n?.reframeModeBlurPillarboxDesc ??
                'Scales & blurs video in the background to fill 9:16, keeping the centered video crisp.',
            icon: Icons.blur_on_rounded,
          ),
          const SizedBox(height: 6),
          _buildModeTile(
            isSelected: selectedMode == AspectConversionMode.centerCrop,
            onTap: () => onModeChanged(AspectConversionMode.centerCrop),
            title: l10n?.reframeModeCenterCrop ?? 'Center Smart Crop',
            description: l10n?.reframeModeCenterCropDesc ??
                'Fills the full 9:16 screen by cropping the left and right edges.',
            icon: Icons.crop_portrait_rounded,
          ),
          const SizedBox(height: 6),
          _buildModeTile(
            isSelected: selectedMode == AspectConversionMode.smartFaceTrack,
            onTap: () => onModeChanged(AspectConversionMode.smartFaceTrack),
            title: 'AI Smart Face Track (OpusClip)',
            description:
                'Intelligent rule-of-thirds upper-body focal framing. Keeps the speaker face and eyes perfectly framed in 9:16.',
            icon: Icons.face_retouching_natural_rounded,
          ),
          const SizedBox(height: 6),
          _buildModeTile(
            isSelected: selectedMode == AspectConversionMode.splitScreen,
            onTap: () => onModeChanged(AspectConversionMode.splitScreen),
            title: l10n?.reframeModeSplitScreen ?? 'Split Screen / Dual Layer',
            description: l10n?.reframeModeSplitScreenDesc ??
                'Stacks two video windows vertically (ideal for reactions and podcast dialogue).',
            icon: Icons.view_agenda_outlined,
          ),
          const SizedBox(height: 6),
          _buildModeTile(
            isSelected: selectedMode == AspectConversionMode.speakerTrack,
            onTap: () => onModeChanged(AspectConversionMode.speakerTrack),
            title: 'AI Multi-Speaker Auto-Switch',
            description:
                'Dynamically cuts the 9:16 vertical camera between speakers in podcasts and interviews based on who is actively talking.',
            icon: Icons.record_voice_over_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildModeTile({
    required bool isSelected,
    required VoidCallback onTap,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentOrange.withValues(alpha: 0.12)
              : AppTheme.cardBgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentOrange
                : AppTheme.borderGlass.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.accentOrange : AppTheme.secondaryText,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected
                          ? AppTheme.accentOrange
                          : AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.secondaryText,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accentOrange
                      : AppTheme.mutedText,
                  width: 1.5,
                ),
                color: isSelected ? AppTheme.accentOrange : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      size: 11,
                      color: AppTheme.onAccentText,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
