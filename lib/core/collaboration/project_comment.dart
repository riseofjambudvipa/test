import 'package:uuid/uuid.dart';

/// User roles for collaboration and project review comments.
enum ProjectCommentRole {
  editor,
  reviewer,
  client,
  director;

  String get displayName {
    switch (this) {
      case ProjectCommentRole.editor:
        return 'Editor';
      case ProjectCommentRole.reviewer:
        return 'Reviewer';
      case ProjectCommentRole.client:
        return 'Client';
      case ProjectCommentRole.director:
        return 'Director';
    }
  }

  static ProjectCommentRole fromString(String? val) {
    if (val == null) return ProjectCommentRole.reviewer;
    return ProjectCommentRole.values.firstWhere(
      (r) => r.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ProjectCommentRole.reviewer,
    );
  }
}

/// Category tags for grouping review comments.
enum ProjectCommentCategory {
  general,
  visual,
  audio,
  copy,
  pacing;

  String get displayName {
    switch (this) {
      case ProjectCommentCategory.general:
        return 'General';
      case ProjectCommentCategory.visual:
        return 'Visual';
      case ProjectCommentCategory.audio:
        return 'Audio';
      case ProjectCommentCategory.copy:
        return 'Copy';
      case ProjectCommentCategory.pacing:
        return 'Pacing';
    }
  }

  static ProjectCommentCategory fromString(String? val) {
    if (val == null) return ProjectCommentCategory.general;
    return ProjectCommentCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ProjectCommentCategory.general,
    );
  }
}

/// A timestamped collaboration/review note or task for team workflows.
class ProjectComment {
  final String id;
  final String projectId;
  final double timestamp;
  final String authorName;
  final ProjectCommentRole role;
  final ProjectCommentCategory category;
  final String content;
  final DateTime createdAt;
  final bool isResolved;
  final DateTime? resolvedAt;

  const ProjectComment({
    required this.id,
    required this.projectId,
    required this.timestamp,
    required this.authorName,
    this.role = ProjectCommentRole.reviewer,
    this.category = ProjectCommentCategory.general,
    required this.content,
    required this.createdAt,
    this.isResolved = false,
    this.resolvedAt,
  });

  /// Factory to create a new comment with generated ID and current timestamp.
  factory ProjectComment.create({
    required String projectId,
    required double timestamp,
    required String authorName,
    required String content,
    ProjectCommentRole role = ProjectCommentRole.reviewer,
    ProjectCommentCategory category = ProjectCommentCategory.general,
  }) {
    return ProjectComment(
      id: const Uuid().v4(),
      projectId: projectId,
      timestamp: timestamp < 0 ? 0.0 : timestamp,
      authorName: authorName.trim().isEmpty ? 'Reviewer' : authorName.trim(),
      role: role,
      category: category,
      content: content.trim(),
      createdAt: DateTime.now(),
      isResolved: false,
    );
  }

  /// Formats the timestamp as MM:SS.S (e.g. 01:23.4)
  String get formattedTimestamp {
    final totalSeconds = timestamp.floor();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final decimal = ((timestamp - totalSeconds) * 10).floor();
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.$decimal';
  }

  ProjectComment copyWith({
    String? id,
    String? projectId,
    double? timestamp,
    String? authorName,
    ProjectCommentRole? role,
    ProjectCommentCategory? category,
    String? content,
    DateTime? createdAt,
    bool? isResolved,
    DateTime? resolvedAt,
  }) {
    return ProjectComment(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      timestamp: timestamp ?? this.timestamp,
      authorName: authorName ?? this.authorName,
      role: role ?? this.role,
      category: category ?? this.category,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'timestamp': timestamp,
      'authorName': authorName,
      'role': role.name,
      'category': category.name,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'isResolved': isResolved,
      'resolvedAt': resolvedAt?.toIso8601String(),
    };
  }

  factory ProjectComment.fromJson(Map<String, dynamic> json) {
    return ProjectComment(
      id: json['id'] as String? ?? const Uuid().v4(),
      projectId: json['projectId'] as String? ?? '',
      timestamp: (json['timestamp'] as num?)?.toDouble() ?? 0.0,
      authorName: json['authorName'] as String? ?? 'Reviewer',
      role: ProjectCommentRole.fromString(json['role'] as String?),
      category: ProjectCommentCategory.fromString(json['category'] as String?),
      content: json['content'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      isResolved: json['isResolved'] as bool? ?? false,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'] as String)
          : null,
    );
  }
}
