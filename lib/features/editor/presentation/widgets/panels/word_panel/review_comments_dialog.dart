import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/collaboration/project_comment.dart';
import '../../../../../../core/collaboration/project_collaboration_service.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../controllers/editor_controller.dart';

/// Modal dialog providing Descript & Frame.io parity for team collaboration,
/// timestamped review comments, revision requests, and client feedback.
class ReviewCommentsDialog extends ConsumerStatefulWidget {
  const ReviewCommentsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const ReviewCommentsDialog(),
    );
  }

  @override
  ConsumerState<ReviewCommentsDialog> createState() => _ReviewCommentsDialogState();
}

class _ReviewCommentsDialogState extends ConsumerState<ReviewCommentsDialog> {
  String _searchQuery = '';
  bool? _resolvedFilter; // null = all, false = pending, true = resolved
  ProjectCommentCategory? _categoryFilter;
  bool _isAdding = false;

  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  ProjectCommentRole _selectedRole = ProjectCommentRole.reviewer;
  ProjectCommentCategory _selectedCategory = ProjectCommentCategory.general;

  @override
  void initState() {
    super.initState();
    _initDefaultAuthor();
  }

  Future<void> _initDefaultAuthor() async {
    final author = await ProjectCollaborationService.instance.getDefaultAuthor();
    if (mounted) {
      _authorController.text = author;
    }
  }

  @override
  void dispose() {
    _authorController.dispose();
    _contentController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  void _openAddForm(double currentTime) {
    setState(() {
      _isAdding = true;
      _timeController.text = currentTime.toStringAsFixed(2);
      _contentController.clear();
    });
  }

  void _cancelAddForm() {
    setState(() {
      _isAdding = false;
      _contentController.clear();
    });
  }

  Future<void> _submitNewComment() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) return;

    final parsedTime = double.tryParse(_timeController.text.trim()) ??
        ref.read(editorProvider).currentTime;

    await ref.read(editorProvider.notifier).addReviewComment(
          content: content,
          authorName: _authorController.text.trim(),
          role: _selectedRole,
          category: _selectedCategory,
          timestamp: parsedTime,
        );

    if (mounted) {
      setState(() {
        _isAdding = false;
        _contentController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Review note posted at ${_formatTimestamp(parsedTime)}',
            style: TextStyle(color: AppTheme.primaryText),
          ),
          backgroundColor: AppTheme.cardBgElevated,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  String _formatTimestamp(double timestamp) {
    final totalSeconds = timestamp.floor();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final decimal = ((timestamp - totalSeconds) * 10).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.$decimal';
  }

  Color _getRoleColor(ProjectCommentRole role) {
    switch (role) {
      case ProjectCommentRole.editor:
        return AppTheme.accentOrange;
      case ProjectCommentRole.client:
        return AppTheme.accentCyan;
      case ProjectCommentRole.reviewer:
        return AppTheme.accentPink;
      case ProjectCommentRole.director:
        return AppTheme.accentGreen;
    }
  }

  void _copyMarkdownReport(List<ProjectComment> comments, String projectName) {
    final report = ProjectCollaborationService.instance.exportMarkdownReport(
      projectName,
      comments,
    );
    Clipboard.setData(ClipboardData(text: report));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Review summary copied to clipboard in Markdown format!',
          style: TextStyle(color: AppTheme.primaryText),
        ),
        backgroundColor: AppTheme.cardBgElevated,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorProvider);
    final comments = state.comments;
    final projectName = state.project?.name ?? 'Project';
    final currentTime = state.currentTime;

    final filtered = ProjectCollaborationService.instance.filterComments(
      comments,
      isResolved: _resolvedFilter,
      category: _categoryFilter,
      searchQuery: _searchQuery,
    );

    final pendingCount = comments.where((c) => !c.isResolved).length;
    final resolvedCount = comments.where((c) => c.isResolved).length;

    return PremiumBlurDialog(
      maxWidth: 680,
      glowColor: AppTheme.accentCyan,
      glowOpacity: 0.12,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.accentCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.rate_review_rounded,
                    color: AppTheme.accentCyan,
                    size: 22,
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
                            'Team Review & Notes',
                            style: TextStyle(
                              color: AppTheme.primaryText,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: pendingCount > 0
                                  ? AppTheme.accentOrange.withValues(alpha: 0.2)
                                  : AppTheme.accentGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: pendingCount > 0
                                    ? AppTheme.accentOrange.withValues(alpha: 0.4)
                                    : AppTheme.accentGreen.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              pendingCount > 0
                                  ? '$pendingCount PENDING'
                                  : 'ALL RESOLVED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: pendingCount > 0
                                    ? AppTheme.accentOrange
                                    : AppTheme.accentGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Descript & Frame.io style timestamped revisions & approvals',
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Export Review Notes (Markdown)',
                  icon: Icon(
                    Icons.file_download_outlined,
                    color: AppTheme.secondaryText,
                    size: 20,
                  ),
                  onPressed: comments.isEmpty
                      ? null
                      : () => _copyMarkdownReport(comments, projectName),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppTheme.secondaryText,
                    size: 20,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Add Note / Playhead Quick Action Bar
            if (!_isAdding)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.cardBgElevated.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderGlass),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timer_outlined, color: AppTheme.accentCyan, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Playhead: ${_formatTimestamp(currentTime)}',
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () => _openAddForm(currentTime),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text(
                        'ADD NOTE AT PLAYHEAD',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: AppTheme.onAccentText,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              _buildAddForm(currentTime),

            const SizedBox(height: 12),

            // Filter & Search Controls
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderGlass),
                    ),
                    child: TextField(
                      style: TextStyle(color: AppTheme.primaryText, fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Search notes or authors...',
                        hintStyle: TextStyle(color: AppTheme.mutedText, fontSize: 12),
                        prefixIcon: Icon(Icons.search, size: 16, color: AppTheme.mutedText),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusChip('All (${comments.length})', null),
                const SizedBox(width: 4),
                _buildStatusChip('Pending ($pendingCount)', false),
                const SizedBox(width: 4),
                _buildStatusChip('Resolved ($resolvedCount)', true),
              ],
            ),
            const SizedBox(height: 12),

            // Comments List View
            Flexible(
              child: filtered.isEmpty
                  ? _buildEmptyState(comments.isEmpty)
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final comment = filtered[index];
                        return _buildCommentCard(comment);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, bool? resolvedState) {
    final isSelected = _resolvedFilter == resolvedState;
    return InkWell(
      onTap: () => setState(() => _resolvedFilter = resolvedState),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentCyan.withValues(alpha: 0.2)
              : AppTheme.cardBgElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? AppTheme.accentCyan
                : AppTheme.borderGlass,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.accentCyan : AppTheme.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildAddForm(double currentTime) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardBgElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _authorController,
                  style: TextStyle(color: AppTheme.primaryText, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Author Name',
                    labelStyle: TextStyle(color: AppTheme.secondaryText, fontSize: 11),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppTheme.borderGlass),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<ProjectCommentRole>(
                  initialValue: _selectedRole,
                  dropdownColor: AppTheme.cardBgElevated,
                  style: TextStyle(color: AppTheme.primaryText, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Role',
                    labelStyle: TextStyle(color: AppTheme.secondaryText, fontSize: 11),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppTheme.borderGlass),
                    ),
                  ),
                  items: ProjectCommentRole.values.map((r) {
                    return DropdownMenuItem(
                      value: r,
                      child: Text(r.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedRole = val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<ProjectCommentCategory>(
                  initialValue: _selectedCategory,
                  dropdownColor: AppTheme.cardBgElevated,
                  style: TextStyle(color: AppTheme.primaryText, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: TextStyle(color: AppTheme.secondaryText, fontSize: 11),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppTheme.borderGlass),
                    ),
                  ),
                  items: ProjectCommentCategory.values.map((c) {
                    return DropdownMenuItem(
                      value: c,
                      child: Text(c.displayName),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedCategory = val);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _timeController,
                  style: TextStyle(color: AppTheme.primaryText, fontSize: 12),
                  decoration: InputDecoration(
                    labelText: 'Sec',
                    labelStyle: TextStyle(color: AppTheme.secondaryText, fontSize: 11),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(color: AppTheme.borderGlass),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _contentController,
            maxLines: 2,
            style: TextStyle(color: AppTheme.primaryText, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Enter revision feedback, copy changes, or approval note...',
              hintStyle: TextStyle(color: AppTheme.mutedText, fontSize: 12),
              isDense: true,
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: AppTheme.borderGlass),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _cancelAddForm,
                child: Text('CANCEL', style: TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _submitNewComment,
                icon: const Icon(Icons.send_rounded, size: 14),
                label: const Text('POST NOTE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentCyan,
                  foregroundColor: AppTheme.onAccentText,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(ProjectComment comment) {
    final roleColor = _getRoleColor(comment.role);
    final isResolved = comment.isResolved;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isResolved
            ? AppTheme.cardBg.withValues(alpha: 0.5)
            : AppTheme.cardBgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isResolved
              ? AppTheme.borderGlass.withValues(alpha: 0.3)
              : AppTheme.borderGlass,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Timestamp jump button
              InkWell(
                onTap: () {
                  ref.read(editorProvider.notifier).seekToComment(comment);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Jumped playhead to ${comment.formattedTimestamp}',
                        style: TextStyle(color: AppTheme.primaryText),
                      ),
                      backgroundColor: AppTheme.cardBgElevated,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.accentCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_arrow_rounded, size: 14, color: AppTheme.accentCyan),
                      const SizedBox(width: 3),
                      Text(
                        comment.formattedTimestamp,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.accentCyan,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Author + Role Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: roleColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '${comment.authorName} (${comment.role.displayName})',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: roleColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Category Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.borderGlass),
                ),
                child: Text(
                  comment.category.displayName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    color: AppTheme.secondaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),

              // Resolved Checkbox
              IconButton(
                tooltip: isResolved ? 'Mark Pending' : 'Mark Resolved',
                icon: Icon(
                  isResolved ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 18,
                  color: isResolved ? AppTheme.accentGreen : AppTheme.mutedText,
                ),
                onPressed: () {
                  ref.read(editorProvider.notifier).toggleCommentResolved(comment.id);
                },
              ),

              // Delete button
              IconButton(
                tooltip: 'Delete Note',
                icon: Icon(Icons.delete_outline, size: 16, color: AppTheme.mutedText),
                onPressed: () {
                  ref.read(editorProvider.notifier).deleteReviewComment(comment.id);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 2, right: 8),
            child: Text(
              comment.content,
              style: TextStyle(
                fontSize: 13,
                color: isResolved ? AppTheme.mutedText : AppTheme.primaryText,
                decoration: isResolved ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool noCommentsAtAll) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            noCommentsAtAll ? Icons.forum_outlined : Icons.filter_alt_off_outlined,
            size: 40,
            color: AppTheme.mutedText.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            noCommentsAtAll ? 'No Review Notes Yet' : 'No Matching Notes',
            style: TextStyle(
              color: AppTheme.primaryText,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            noCommentsAtAll
                ? 'Pause anywhere on the video timeline and add timestamped revision notes for your team or clients.'
                : 'Try adjusting your search query or status filter.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
