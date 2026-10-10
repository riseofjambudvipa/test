import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../../core/video/b_roll_models.dart';
import '../../../../domain/b_roll_service.dart';
import '../../../../domain/chapter_marker_service.dart';

class BRollSuggestionsDialog extends StatefulWidget {
  final Project project;
  final void Function(double time)? onSeekToTime;
  final List<BRollClip> activeClips;
  final void Function(BRollClip clip)? onAttachClip;
  final void Function(String clipId)? onRemoveClip;
  final void Function(BRollClip clip)? onUpdateClip;

  const BRollSuggestionsDialog({
    super.key,
    required this.project,
    this.onSeekToTime,
    this.activeClips = const [],
    this.onAttachClip,
    this.onRemoveClip,
    this.onUpdateClip,
  });

  static Future<void> show(
    BuildContext context,
    Project project, {
    void Function(double time)? onSeekToTime,
    List<BRollClip> activeClips = const [],
    void Function(BRollClip clip)? onAttachClip,
    void Function(String clipId)? onRemoveClip,
    void Function(BRollClip clip)? onUpdateClip,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: AppTheme.isLight
          ? AppTheme.cardBg.withValues(alpha: 0.6)
          : AppTheme.background.withValues(alpha: 0.85),
      builder: (context) => BRollSuggestionsDialog(
        project: project,
        onSeekToTime: onSeekToTime,
        activeClips: activeClips,
        onAttachClip: onAttachClip,
        onRemoveClip: onRemoveClip,
        onUpdateClip: onUpdateClip,
      ),
    );
  }

  @override
  State<BRollSuggestionsDialog> createState() => _BRollSuggestionsDialogState();
}

class _BRollSuggestionsDialogState extends State<BRollSuggestionsDialog> {
  late List<BRollCue> _cues;
  late List<BRollClip> _clips;
  int _selectedTabIndex = 0; // 0 = AI Cues, 1 = Attached Overlays

  @override
  void initState() {
    super.initState();
    _cues = BRollSuggestionService.instance.suggestBRoll(widget.project.words);
    _clips = List<BRollClip>.from(widget.activeClips);
  }

  Future<void> _openStockSearch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Search URL copied to clipboard!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    }
  }

  Future<void> _pickAndAttachMedia({double? startTime, String? category}) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'mp4',
          'mov',
          'webm',
          'mkv',
          'avi',
          'png',
          'jpg',
          'jpeg',
          'webp'
        ],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      final path = file.path;
      if (path == null || path.isEmpty) return;

      final double start = startTime ?? 0.0;
      final double defaultDuration = 3.0;
      final double maxDuration = widget.project.duration > 0
          ? widget.project.duration
          : start + defaultDuration;
      final double end = (start + defaultDuration).clamp(0.0, maxDuration);

      final clip = BRollClip(
        id: 'broll_${DateTime.now().millisecondsSinceEpoch}',
        mediaPath: path,
        name: file.name.isNotEmpty ? file.name : p.basename(path),
        startTime: start,
        endTime: end,
        category: category ?? 'General',
        isPictureInPicture: false,
        pipPosition: 'top_right',
      );

      widget.onAttachClip?.call(clip);
      setState(() {
        _clips.add(clip);
        _selectedTabIndex = 1;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Attached B-roll overlay "${clip.name}"!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to attach media: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  void _removeClip(String clipId) {
    widget.onRemoveClip?.call(clipId);
    setState(() {
      _clips.removeWhere((c) => c.id == clipId);
    });
  }

  void _updateClip(BRollClip updated) {
    widget.onUpdateClip?.call(updated);
    setState(() {
      final idx = _clips.indexWhere((c) => c.id == updated.id);
      if (idx != -1) {
        _clips[idx] = updated;
      }
    });
  }

  bool _isCueAttached(BRollCue cue) {
    return _clips.any((c) =>
        (c.startTime - cue.startTime).abs() < 1.0 ||
        (c.category.toLowerCase() == cue.category.toLowerCase() &&
            (c.startTime - cue.startTime).abs() < 2.5));
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBlurDialog(
      maxWidth: 560,
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
                  child: Icon(Icons.video_library_outlined,
                      color: AppTheme.accentCyan, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI B-ROLL STUDIO',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Smart cutaways & Picture-in-Picture to boost viewer retention',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close,
                      size: 20, color: AppTheme.secondaryText),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab bar switcher
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 0),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 0
                            ? AppTheme.accentCyan.withValues(alpha: 0.15)
                            : AppTheme.cardBgElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedTabIndex == 0
                              ? AppTheme.accentCyan
                              : AppTheme.borderGlass,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'AI CUES (${_cues.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _selectedTabIndex == 0
                              ? AppTheme.accentCyan
                              : AppTheme.secondaryText,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedTabIndex = 1),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedTabIndex == 1
                            ? AppTheme.accentOrange.withValues(alpha: 0.15)
                            : AppTheme.cardBgElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _selectedTabIndex == 1
                              ? AppTheme.accentOrange
                              : AppTheme.borderGlass,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'ATTACHED OVERLAYS (${_clips.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _selectedTabIndex == 1
                              ? AppTheme.accentOrange
                              : AppTheme.secondaryText,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Divider(color: AppTheme.dividerColor, height: 20),

            // Tab Content
            if (_selectedTabIndex == 0)
              _buildAiCuesView()
            else
              _buildAttachedOverlaysView(),
          ],
        ),
      ),
    );
  }

  Widget _buildAiCuesView() {
    if (_cues.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          children: [
            Icon(Icons.video_library_outlined,
                size: 40, color: AppTheme.mutedText),
            const SizedBox(height: 12),
            Text(
              'No B-Roll cues detected',
              style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Spoken visual keywords (e.g. money, code, rocket, travel) will appear here automatically.',
              style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _cues.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final cue = _cues[index];
              final timeStr = ChapterMarker.formatTime(cue.startTime);
              final isAttached = _isCueAttached(cue);

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.glassDecoration(
                  color: AppTheme.cardBgElevated,
                  borderRadius: 8,
                  borderOpacity: 0.08,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            timeStr,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppTheme.borderGlass),
                          ),
                          child: Text(
                            cue.category.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.mutedText,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        if (isAttached) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGreen
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ATTACHED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.accentGreen,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                        const Spacer(),
                        if (widget.onSeekToTime != null) ...[
                          IconButton(
                            icon: Icon(Icons.my_location_rounded,
                                size: 14, color: AppTheme.accentOrange),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            tooltip: 'Seek to timestamp',
                            onPressed: () {
                              widget.onSeekToTime!(cue.startTime);
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 4),
                        ],
                        IconButton(
                          icon: Icon(Icons.open_in_new_rounded,
                              size: 14, color: AppTheme.accentCyan),
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: 'Search free stock footage on Pexels',
                          onPressed: () => _openStockSearch(cue.pexelsUrl),
                        ),
                        const SizedBox(width: 6),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isAttached
                                ? AppTheme.accentGreen.withValues(alpha: 0.2)
                                : AppTheme.accentOrange,
                            foregroundColor: isAttached
                                ? AppTheme.accentGreen
                                : AppTheme.onAccentText,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          icon: const Icon(Icons.add_photo_alternate_rounded,
                              size: 12),
                          label: Text(
                            isAttached ? 'Replace' : 'Attach',
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          onPressed: () => _pickAndAttachMedia(
                            startTime: cue.startTime,
                            category: cue.category,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${cue.contextSentence}"',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.secondaryText,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 14),
                label: const Text('COPY CUES LIST'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryText,
                  side: BorderSide(color: AppTheme.borderGlass),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final text = _cues
                      .map((c) =>
                          '${ChapterMarker.formatTime(c.startTime)} [${c.category}] Keyword: ${c.keyword} -> Search: ${c.searchTopic}')
                      .join('\n');
                  await Clipboard.setData(ClipboardData(text: text));
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content:
                          const Text('B-Roll cues copied to clipboard!'),
                      backgroundColor: AppTheme.accentGreen,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('ATTACH CUSTOM MEDIA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: AppTheme.onAccentText,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _pickAndAttachMedia(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAttachedOverlaysView() {
    if (_clips.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Icon(Icons.layers_outlined, size: 40, color: AppTheme.mutedText),
            const SizedBox(height: 12),
            Text(
              'No B-Roll overlays attached yet',
              style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Click "Attach" on any AI cue or attach custom media files below.',
              style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
              label: const Text('ATTACH MEDIA FILE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: AppTheme.onAccentText,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _pickAndAttachMedia(),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _clips.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final clip = _clips[index];

              return Container(
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.glassDecoration(
                  color: AppTheme.cardBgElevated,
                  borderRadius: 8,
                  borderOpacity: 0.08,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          clip.isVideo
                              ? Icons.movie_outlined
                              : Icons.image_outlined,
                          size: 16,
                          color: AppTheme.accentCyan,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            clip.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.accentOrange
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${clip.startTime.toStringAsFixed(1)}s - ${clip.endTime.toStringAsFixed(1)}s',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 16, color: AppTheme.accentRed),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Remove B-roll overlay',
                          onPressed: () => _removeClip(clip.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Display Mode (Fullscreen vs PiP)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Text(
                          'Display Mode: ',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.secondaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        InkWell(
                          onTap: () => _updateClip(
                              clip.copyWith(isPictureInPicture: false)),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: !clip.isPictureInPicture
                                  ? AppTheme.accentCyan
                                      .withValues(alpha: 0.2)
                                  : AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: !clip.isPictureInPicture
                                    ? AppTheme.accentCyan
                                    : AppTheme.borderGlass,
                              ),
                            ),
                            child: Text(
                              'Fullscreen Cutaway',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: !clip.isPictureInPicture
                                    ? AppTheme.accentCyan
                                    : AppTheme.mutedText,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => _updateClip(
                              clip.copyWith(isPictureInPicture: true)),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: clip.isPictureInPicture
                                  ? AppTheme.accentOrange
                                      .withValues(alpha: 0.2)
                                  : AppTheme.cardBg,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: clip.isPictureInPicture
                                    ? AppTheme.accentOrange
                                    : AppTheme.borderGlass,
                              ),
                            ),
                            child: Text(
                              'Picture-in-Picture (PiP)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: clip.isPictureInPicture
                                    ? AppTheme.accentOrange
                                    : AppTheme.mutedText,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // PiP Position options
                    if (clip.isPictureInPicture) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        runSpacing: 4,
                        children: [
                          Text(
                            'Corner: ',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.mutedText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          for (final pos in [
                            ('top_right', 'Top-R'),
                            ('top_left', 'Top-L'),
                            ('bottom_right', 'Bottom-R'),
                            ('bottom_left', 'Bottom-L'),
                          ])
                            InkWell(
                              onTap: () => _updateClip(
                                  clip.copyWith(pipPosition: pos.$1)),
                              borderRadius: BorderRadius.circular(4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: clip.pipPosition == pos.$1
                                      ? AppTheme.accentOrange
                                      : AppTheme.cardBg,
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: clip.pipPosition == pos.$1
                                        ? AppTheme.accentOrange
                                        : AppTheme.borderGlass,
                                  ),
                                ),
                                child: Text(
                                  pos.$2,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: clip.pipPosition == pos.$1
                                        ? AppTheme.onAccentText
                                        : AppTheme.mutedText,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
          label: const Text('ATTACH ANOTHER MEDIA FILE'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.accentOrange,
            foregroundColor: AppTheme.onAccentText,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _pickAndAttachMedia(),
        ),
      ],
    );
  }
}
