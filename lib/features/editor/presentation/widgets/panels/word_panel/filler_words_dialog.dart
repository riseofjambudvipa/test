import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../domain/auto_enhancement_service.dart';
import '../../../controllers/editor_controller.dart';

/// Dialog offering Descript-style filler word management:
/// 1. "Hide from Captions": removes speech hesitations ("um", "uh", "like") from subtitle display.
/// 2. "Cut from Video & Audio": automatically cuts the corresponding time spans from video segments,
///    jump-cutting hesitations out of both audio and video playback and final export.
/// 3. "Restore Filler Words": unhides previously hidden speech hesitations.
class FillerWordsDialog extends ConsumerWidget {
  final Project project;

  const FillerWordsDialog({
    super.key,
    required this.project,
  });

  static Future<void> show(BuildContext context, Project project) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => FillerWordsDialog(project: project),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(editorProvider.notifier);
    final count = AutoEnhancementService.instance.countFillerWords(project.words);

    return PremiumBlurDialog(
      maxWidth: 440,
      useScrollView: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.content_cut_rounded, size: 20, color: AppTheme.accentOrange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI FILLER WORD REMOVAL',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.primaryText,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Descript-style text editing for speech hesitations',
                      style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 18, color: AppTheme.secondaryText),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(color: AppTheme.dividerColor, height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: AppTheme.glassDecoration(
              color: AppTheme.cardBg.withValues(alpha: 0.5),
              borderRadius: 10,
              borderOpacity: 0.15,
            ),
            child: Row(
              children: [
                Icon(
                  count > 0 ? Icons.check_circle_outline_rounded : Icons.info_outline_rounded,
                  size: 20,
                  color: count > 0 ? AppTheme.accentGreen : AppTheme.secondaryText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    count > 0
                        ? 'Found $count filler word${count == 1 ? '' : 's'} (um, uh, like, basically, etc.)'
                        : 'No active filler words found in transcript.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: count > 0 ? AppTheme.primaryText : AppTheme.secondaryText,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'CHOOSE REMOVAL ACTION',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.mutedText,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 10),

          // Option 1: Cut from Video & Audio
          _buildActionCard(
            context: context,
            title: 'Cut Footage from Video & Audio',
            badge: 'DESCRIPT STYLE',
            badgeColor: AppTheme.accentOrange,
            description:
                'Splits video timeline segments and jump-cuts all hesitations out of the video and audio completely with anti-click crossfading.',
            icon: Icons.movie_filter_outlined,
            iconColor: AppTheme.accentOrange,
            enabled: count > 0,
            onTap: () {
              Navigator.pop(context);
              final cutsCount = notifier.cutFillerWordsFromVideo();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✂️ Cut $cutsCount filler word pause${cutsCount == 1 ? '' : 's'} from video & audio!'),
                  backgroundColor: AppTheme.accentOrange,
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Option 2: Hide from Captions Only
          _buildActionCard(
            context: context,
            title: 'Hide from Captions Only',
            badge: 'SUBTITLES ONLY',
            badgeColor: AppTheme.accentCyan,
            description:
                'Keeps original video footage and audio untouched. Only removes hesitations from subtitle text and animation overlays.',
            icon: Icons.subtitles_off_outlined,
            iconColor: AppTheme.accentCyan,
            enabled: count > 0,
            onTap: () {
              Navigator.pop(context);
              final hiddenCount = notifier.removeFillerWords();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hiding $hiddenCount filler words from captions.'),
                  backgroundColor: AppTheme.accentCyan,
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Option 3: Restore
          _buildActionCard(
            context: context,
            title: 'Restore All Filler Words',
            badge: 'UNDO',
            badgeColor: AppTheme.mutedText,
            description: 'Unhides any previously hidden speech hesitations across the transcript.',
            icon: Icons.restore_rounded,
            iconColor: AppTheme.accentGreen,
            enabled: true,
            onTap: () {
              Navigator.pop(context);
              final restored = notifier.restoreFillerWords();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(restored > 0 ? 'Restored $restored filler words.' : 'No hidden filler words to restore.'),
                  backgroundColor: restored > 0 ? AppTheme.accentGreen : AppTheme.cardBgElevated,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CLOSE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.secondaryText,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String badge,
    required Color badgeColor,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.glassDecoration(
            color: enabled ? AppTheme.cardBg.withValues(alpha: 0.35) : AppTheme.cardBg.withValues(alpha: 0.15),
            borderRadius: 10,
            borderOpacity: enabled ? 0.18 : 0.06,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (enabled ? iconColor : AppTheme.mutedText).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 20, color: enabled ? iconColor : AppTheme.mutedText),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: enabled ? AppTheme.primaryText : AppTheme.mutedText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (enabled ? badgeColor : AppTheme.mutedText).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: enabled ? badgeColor : AppTheme.mutedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: enabled ? AppTheme.secondaryText : AppTheme.mutedText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
