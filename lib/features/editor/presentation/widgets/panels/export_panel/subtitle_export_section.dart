import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../../../exporter/data/subtitle_exporter.dart';
import '../word_panel/chapter_generator_dialog.dart';

class SubtitleExportSection extends StatelessWidget {
  final Project project;
  final ValueChanged<String> onExportSubtitles;

  const SubtitleExportSection({
    super.key,
    required this.project,
    required this.onExportSubtitles,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSubtitleCard(
          title: l10n?.exportSrtTitle ?? 'SRT Subtitles',
          desc: l10n?.exportSrtDesc ?? 'Standard SubRip subtitle file for YouTube, Premiere, Final Cut, DaVinci',
          icon: Icons.subtitles_outlined,
          color: AppTheme.accentCyan,
          onTap: () => onExportSubtitles('srt'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.copy_rounded, color: AppTheme.mutedText, size: 18),
                tooltip: l10n?.exportCopySrtTooltip ?? 'Copy SRT to clipboard',
                splashRadius: 18,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  try {
                    final content = SubtitleExporter.toSrt(project);
                    await Clipboard.setData(ClipboardData(text: content));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n?.exportCopiedSrt ?? 'SRT copied to clipboard!'),
                          backgroundColor: AppTheme.accentGreen,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n?.exportCopyFailedSrt('$e') ?? 'Failed to copy SRT: $e'),
                          backgroundColor: AppTheme.accentRed,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: 12),
              Icon(Icons.download_rounded, color: AppTheme.mutedText, size: 18),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildSubtitleCard(
          title: l10n?.exportVttTitle ?? 'WebVTT Subtitles',
          desc: l10n?.exportVttDesc ?? 'Modern web subtitle format compatible with HTML5 video players',
          icon: Icons.html_outlined,
          color: AppTheme.accentPink,
          onTap: () => onExportSubtitles('vtt'),
        ),
        const SizedBox(height: 12),
        _buildSubtitleCard(
          title: l10n?.exportAssTitle ?? 'Advanced SubStation Alpha (ASS)',
          desc: l10n?.exportAssDesc ?? 'Preserves all custom colors, fonts, strokes, and animations in VLC/Aegisub',
          icon: Icons.style_outlined,
          color: AppTheme.accentOrange,
          onTap: () => onExportSubtitles('ass'),
        ),
        const SizedBox(height: 12),
        _buildSubtitleCard(
          title: l10n?.exportTxtTitle ?? 'Plain Transcript (TXT)',
          desc: l10n?.exportTxtDesc ?? 'Clean text transcript without timestamps, ideal for blog posts or notes',
          icon: Icons.notes_outlined,
          color: AppTheme.accentGreen,
          onTap: () => onExportSubtitles('txt'),
        ),
        const SizedBox(height: 12),
        _buildSubtitleCard(
          title: 'YouTube Video Chapters',
          desc: 'Auto-detect semantic topics, edit markers & export timestamped YouTube chapters',
          icon: Icons.smart_display_outlined,
          color: AppTheme.accentCyan,
          onTap: () {
            ChapterGeneratorDialog.show(context, project);
          },
          trailing: Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.mutedText, size: 14),
        ),
      ],
    );
  }

  Widget _buildSubtitleCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GlassContainer(
      borderRadius: 10,
      borderOpacity: 0.08,
      color: AppTheme.cardBg.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: AppTheme.glassDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: 8,
                  borderOpacity: 0.2,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.secondaryText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? Icon(Icons.download_rounded, color: AppTheme.mutedText, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
