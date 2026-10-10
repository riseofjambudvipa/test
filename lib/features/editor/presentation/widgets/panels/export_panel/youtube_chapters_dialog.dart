import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../domain/chapter_marker_service.dart';

class YouTubeChaptersDialog extends StatefulWidget {
  final Project project;

  const YouTubeChaptersDialog({
    super.key,
    required this.project,
  });

  static Future<void> show(BuildContext context, Project project) {
    return showDialog<void>(
      context: context,
      barrierColor: AppTheme.isLight ? Colors.black54 : Colors.black87,
      builder: (context) => YouTubeChaptersDialog(project: project),
    );
  }

  @override
  State<YouTubeChaptersDialog> createState() => _YouTubeChaptersDialogState();
}

class _YouTubeChaptersDialogState extends State<YouTubeChaptersDialog> {
  late List<ChapterMarker> _chapters;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    _chapters = ChapterMarkerService.instance.generateChapters(
      widget.project.words,
      widget.project.duration,
    );
  }

  void _copyToClipboard() async {
    final text = ChapterMarker.formatForYouTube(_chapters);
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      setState(() => _copied = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('YouTube chapters copied to clipboard! Paste directly into your video description.'),
          backgroundColor: AppTheme.accentGreen,
          duration: const Duration(seconds: 3),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBlurDialog(
      maxWidth: 500,
      borderOpacity: 0.15,
      useScrollView: false,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: AppTheme.glassDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.15),
                    borderRadius: 8,
                    borderOpacity: 0.2,
                  ),
                  child: Icon(Icons.smart_display_outlined, color: AppTheme.accentCyan, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUTUBE VIDEO CHAPTERS',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'AI-detected topic shifts & timestamps',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: AppTheme.secondaryText),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(color: AppTheme.dividerColor, height: 24),

            // Content
            if (_chapters.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Column(
                  children: [
                    Icon(Icons.notes_rounded, size: 40, color: AppTheme.mutedText),
                    const SizedBox(height: 12),
                    Text(
                      'No captions available to detect chapters',
                      style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Transcribe your video first in the STT tab to generate automatic chapters.',
                      style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else ...[
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _chapters.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final ch = _chapters[index];
                    final durationSec = (ch.endTime - ch.startTime).round();
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: AppTheme.glassDecoration(
                        color: AppTheme.cardBgElevated,
                        borderRadius: 8,
                        borderOpacity: 0.08,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.accentOrange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              ch.timestamp,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentOrange,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              ch.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${durationSec}s',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Copy Button
              ElevatedButton.icon(
                icon: Icon(_copied ? Icons.check : Icons.copy_rounded, size: 16),
                label: Text(
                  _copied ? 'COPIED TO CLIPBOARD!' : 'COPY YOUTUBE CHAPTERS',
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _copied ? AppTheme.accentGreen : AppTheme.accentCyan,
                  foregroundColor: AppTheme.onAccentText,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _copyToClipboard,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
