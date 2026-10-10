import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../../core/video/chapter_models.dart';
import '../../../../../../core/video/chapter_generator_service.dart';
import '../../../controllers/editor_controller.dart';

/// Modal dialog for generating, editing, and copying YouTube video chapters.
class ChapterGeneratorDialog extends ConsumerStatefulWidget {
  final Project project;

  const ChapterGeneratorDialog({
    super.key,
    required this.project,
  });

  static Future<void> show(BuildContext context, Project project) {
    return showDialog<void>(
      context: context,
      barrierColor: AppTheme.isLight ? Colors.black54 : Colors.black87,
      builder: (context) => ChapterGeneratorDialog(project: project),
    );
  }

  @override
  ConsumerState<ChapterGeneratorDialog> createState() =>
      _ChapterGeneratorDialogState();
}

class _ChapterGeneratorDialogState extends ConsumerState<ChapterGeneratorDialog> {
  final _uuid = const Uuid();
  late List<VideoChapter> _chapters;
  bool _useDashes = false;
  final TextEditingController _newChapterTitleController =
      TextEditingController(text: 'New Chapter');

  @override
  void initState() {
    super.initState();
    final existing = ref.read(editorProvider).chapters;
    if (existing.isNotEmpty) {
      _chapters = List<VideoChapter>.from(existing);
    } else {
      _chapters = ChapterGeneratorService.instance.generateChapters(
        words: widget.project.words.toList(),
        totalDuration: widget.project.duration,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(editorProvider.notifier).setChapters(_chapters);
        }
      });
    }
  }

  @override
  void dispose() {
    _newChapterTitleController.dispose();
    super.dispose();
  }

  void _syncChapters() {
    ref.read(editorProvider.notifier).setChapters(_chapters);
  }

  void _regenerate() {
    setState(() {
      _chapters = ChapterGeneratorService.instance.generateChapters(
        words: widget.project.words.toList(),
        totalDuration: widget.project.duration,
      );
    });
    _syncChapters();
  }

  void _addChapterAtCurrentTime() {
    final currentTime = ref.read(editorProvider).currentTime;
    final title = _newChapterTitleController.text.trim().isEmpty
        ? 'Chapter'
        : _newChapterTitleController.text.trim();

    setState(() {
      _chapters.add(
        VideoChapter(
          id: _uuid.v4(),
          startTime: currentTime,
          title: title,
        ),
      );
      _chapters.sort((a, b) => a.startTime.compareTo(b.startTime));
    });
    _syncChapters();
  }

  void _removeChapter(String id) {
    setState(() {
      _chapters.removeWhere((c) => c.id == id);
    });
    _syncChapters();
  }

  void _editChapterTitle(String id, String newTitle) {
    setState(() {
      final idx = _chapters.indexWhere((c) => c.id == id);
      if (idx != -1) {
        _chapters[idx] = _chapters[idx].copyWith(title: newTitle);
      }
    });
    _syncChapters();
  }

  void _copyToClipboard() {
    final text = ChapterListUtils.formatForYouTube(_chapters, useDash: _useDashes);
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied ${_chapters.length} YouTube chapters to clipboard!'),
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isValid = ChapterListUtils.isValidForYouTube(_chapters);
    final formattedText = ChapterListUtils.formatForYouTube(
      _chapters,
      useDash: _useDashes,
    );

    return PremiumBlurDialog(
      maxWidth: 580,
      borderOpacity: 0.15,
      useScrollView: false,
      child: SizedBox(
        height: 600,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Row(
              children: [
                Icon(Icons.bookmarks_outlined,
                    size: 20, color: AppTheme.accentOrange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'YOUTUBE CHAPTER GENERATOR',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.refresh_rounded,
                      size: 18, color: AppTheme.secondaryText),
                  tooltip: 'Re-detect chapters from transcript',
                  onPressed: _regenerate,
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: AppTheme.secondaryText),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(color: AppTheme.dividerColor, height: 16),

            // ── YouTube Eligibility Badge ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isValid
                    ? AppTheme.accentGreen.withValues(alpha: 0.12)
                    : AppTheme.accentOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isValid
                      ? AppTheme.accentGreen.withValues(alpha: 0.4)
                      : AppTheme.accentOrange.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle_outline : Icons.info_outline,
                    size: 16,
                    color: isValid ? AppTheme.accentGreen : AppTheme.accentOrange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isValid
                          ? 'READY FOR YOUTUBE: Meets YouTube chapter requirements (>= 3 chapters, starts at 00:00, >= 10s gap).'
                          : 'YOUTUBE NOTE: YouTube requires at least 3 chapters, starting at 00:00 with >= 10s between chapters.',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isValid
                            ? AppTheme.accentGreen
                            : AppTheme.accentOrange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Chapters List ─────────────────────────────────────────────────
            Expanded(
              child: _chapters.isEmpty
                  ? Center(
                      child: Text(
                        'No chapters detected. Add one below or click refresh.',
                        style: TextStyle(color: AppTheme.mutedText, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _chapters.length,
                      itemBuilder: (context, index) {
                        final chapter = _chapters[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.borderGlass),
                          ),
                          child: Row(
                            children: [
                              // Jump to time button
                              InkWell(
                                onTap: () {
                                  ref
                                      .read(editorProvider.notifier)
                                      .setCurrentTime(chapter.startTime);
                                  ref
                                      .read(editorProvider.notifier)
                                      .setIsPlaying(true);
                                },
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentCyan
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.play_arrow_rounded,
                                          size: 12, color: AppTheme.accentCyan),
                                      const SizedBox(width: 2),
                                      Text(
                                        chapter.formattedTimestamp,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.accentCyan,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Editable Title
                              Expanded(
                                child: TextFormField(
                                  initialValue: chapter.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 4),
                                    border: InputBorder.none,
                                  ),
                                  onChanged: (val) =>
                                      _editChapterTitle(chapter.id, val),
                                ),
                              ),

                              // Delete Button
                              IconButton(
                                icon: Icon(Icons.delete_outline_rounded,
                                    size: 16, color: AppTheme.accentRed),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                tooltip: 'Remove Chapter',
                                onPressed: () => _removeChapter(chapter.id),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),

            // ── Add Chapter at Current Playhead ───────────────────────────────
            Consumer(
              builder: (context, ref, child) {
                final currentTime =
                    ref.watch(editorProvider.select((s) => s.currentTime));
                final formattedPlayhead =
                    VideoChapter(id: '', startTime: currentTime, title: '')
                        .formattedTimestamp;

                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBgElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderGlass),
                        ),
                        child: TextField(
                          controller: _newChapterTitleController,
                          style: TextStyle(
                              fontSize: 11, color: AppTheme.primaryText),
                          decoration: InputDecoration(
                            hintText: 'New chapter title...',
                            hintStyle: TextStyle(
                                fontSize: 11, color: AppTheme.mutedText),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add_rounded, size: 14),
                      label: Text(
                        'ADD AT $formattedPlayhead',
                        style: const TextStyle(
                            fontSize: 10.5, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.cardBgElevated,
                        foregroundColor: AppTheme.accentOrange,
                        side: BorderSide(
                            color: AppTheme.accentOrange.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: _addChapterAtCurrentTime,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),

            // ── Preview Box & Copy Action ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.borderGlass),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'YOUTUBE DESCRIPTION PREVIEW',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.mutedText,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Row(
                        children: [
                          Text('Include dash:',
                              style: TextStyle(
                                  fontSize: 9, color: AppTheme.mutedText)),
                          const SizedBox(width: 4),
                          SizedBox(
                            height: 18,
                            width: 32,
                            child: Switch(
                              value: _useDashes,
                              activeTrackColor: AppTheme.accentOrange,
                              onChanged: (val) =>
                                  setState(() => _useDashes = val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedText.isEmpty
                        ? '00:00 Introduction'
                        : formattedText,
                    style: TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                      color: AppTheme.secondaryText,
                      height: 1.3,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ── Action Buttons ────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text(
                      'COPY YOUTUBE CHAPTERS',
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: AppTheme.onAccentText,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: _chapters.isEmpty ? null : _copyToClipboard,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
