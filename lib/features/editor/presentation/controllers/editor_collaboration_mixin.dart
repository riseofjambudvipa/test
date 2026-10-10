part of 'editor_controller.dart';

/// Collaboration, team review notes, and revision comments operations
/// for [EditorController].
mixin EditorCollaborationOpsMixin on StateNotifier<EditorState> {
  /// Adds a new timestamped review comment at [timestamp] (or current playhead).
  Future<ProjectComment?> addReviewComment({
    required String content,
    String? authorName,
    ProjectCommentRole role = ProjectCommentRole.reviewer,
    ProjectCommentCategory category = ProjectCommentCategory.general,
    double? timestamp,
  }) async {
    final project = state.project;
    if (project == null || content.trim().isEmpty) return null;

    final effectiveTime = timestamp ?? state.currentTime;
    final effectiveAuthor = authorName?.trim().isNotEmpty == true
        ? authorName!.trim()
        : await ProjectCollaborationService.instance.getDefaultAuthor();

    final newComment = await ProjectCollaborationService.instance.addComment(
      projectId: project.projectId,
      timestamp: effectiveTime,
      authorName: effectiveAuthor,
      content: content.trim(),
      role: role,
      category: category,
    );

    final updatedList = List<ProjectComment>.from(state.comments)..add(newComment);
    updatedList.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    state = state.copyWith(comments: updatedList);

    return newComment;
  }

  /// Toggles the resolved state of a comment.
  Future<void> toggleCommentResolved(String commentId) async {
    final project = state.project;
    if (project == null) return;

    final updated = await ProjectCollaborationService.instance.toggleResolved(
      project.projectId,
      commentId,
    );

    if (updated != null) {
      final list = state.comments.map((c) => c.id == commentId ? updated : c).toList();
      state = state.copyWith(comments: list);
    }
  }

  /// Edits the text content of a comment.
  Future<void> updateReviewComment(String commentId, String newContent) async {
    final project = state.project;
    if (project == null || newContent.trim().isEmpty) return;

    final updated = await ProjectCollaborationService.instance.updateComment(
      project.projectId,
      commentId,
      newContent,
    );

    if (updated != null) {
      final list = state.comments.map((c) => c.id == commentId ? updated : c).toList();
      state = state.copyWith(comments: list);
    }
  }

  /// Deletes a comment.
  Future<void> deleteReviewComment(String commentId) async {
    final project = state.project;
    if (project == null) return;

    final success = await ProjectCollaborationService.instance.deleteComment(
      project.projectId,
      commentId,
    );

    if (success) {
      final list = state.comments.where((c) => c.id != commentId).toList();
      state = state.copyWith(comments: list);
    }
  }

  /// Generates a Markdown report of all comments for the current project.
  String generateReviewMarkdownReport() {
    final project = state.project;
    return ProjectCollaborationService.instance.exportMarkdownReport(
      project?.name ?? 'CapStudio Project',
      state.comments,
    );
  }

  /// Jumps the video playhead directly to a comment's timestamp.
  void seekToComment(ProjectComment comment) {
    (this as EditorCoreMixin).setCurrentTime(comment.timestamp);
  }
}
