import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../logger/logger_service.dart';
import 'project_comment.dart';

/// Service managing timestamped review comments and team collaboration
/// for video projects.
class ProjectCollaborationService {
  ProjectCollaborationService._();
  static final ProjectCollaborationService instance = ProjectCollaborationService._();

  static const String _prefsPrefix = 'capstudio_project_comments_';
  static const String _defaultAuthorKey = 'capstudio_last_reviewer_name';

  final Map<String, List<ProjectComment>> _cache = {};

  String _getKey(String projectId) => '$_prefsPrefix$projectId';

  /// Asynchronously loads all comments for a project, caching them in memory.
  Future<List<ProjectComment>> getComments(String projectId) async {
    if (_cache.containsKey(projectId)) {
      return List.unmodifiable(_cache[projectId]!);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_getKey(projectId));
      if (raw == null || raw.trim().isEmpty) {
        _cache[projectId] = [];
        return [];
      }

      final dynamic decoded = jsonDecode(raw);
      if (decoded is List) {
        final comments = decoded
            .whereType<Map<String, dynamic>>()
            .map((map) => ProjectComment.fromJson(map))
            .toList();
        comments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
        _cache[projectId] = comments;
        return List.unmodifiable(comments);
      }
    } catch (e) {
      LoggerService.instance.log(
        LogLevel.error,
        'ProjectCollaborationService',
        'Error reading comments for $projectId: $e',
      );
    }

    _cache[projectId] = [];
    return [];
  }

  /// Synchronous retrieval from in-memory cache.
  List<ProjectComment> getCommentsSync(String projectId) {
    final list = _cache[projectId];
    if (list == null) return const [];
    return List.unmodifiable(list);
  }

  /// Adds a new timestamped comment.
  Future<ProjectComment> addComment({
    required String projectId,
    required double timestamp,
    required String authorName,
    required String content,
    ProjectCommentRole role = ProjectCommentRole.reviewer,
    ProjectCommentCategory category = ProjectCommentCategory.general,
  }) async {
    final comment = ProjectComment.create(
      projectId: projectId,
      timestamp: timestamp,
      authorName: authorName,
      content: content,
      role: role,
      category: category,
    );

    // Save default reviewer name for convenience
    if (authorName.trim().isNotEmpty) {
      await _saveDefaultAuthor(authorName.trim());
    }

    final current = List<ProjectComment>.from(_cache[projectId] ?? await getComments(projectId));
    current.add(comment);
    current.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _cache[projectId] = current;

    await _persist(projectId, current);
    LoggerService.instance.log(
      LogLevel.action,
      'ProjectCollaborationService',
      'Added review comment at ${comment.formattedTimestamp} by ${comment.authorName}',
    );

    return comment;
  }

  /// Toggles the resolved status of a comment.
  Future<ProjectComment?> toggleResolved(String projectId, String commentId) async {
    final current = List<ProjectComment>.from(_cache[projectId] ?? await getComments(projectId));
    final index = current.indexWhere((c) => c.id == commentId);
    if (index == -1) return null;

    final target = current[index];
    final updated = target.copyWith(
      isResolved: !target.isResolved,
      resolvedAt: !target.isResolved ? DateTime.now() : null,
    );

    current[index] = updated;
    _cache[projectId] = current;
    await _persist(projectId, current);

    LoggerService.instance.log(
      LogLevel.action,
      'ProjectCollaborationService',
      'Toggled resolved state for comment $commentId (${updated.isResolved ? "Resolved" : "Pending"})',
    );

    return updated;
  }

  /// Updates the text content of an existing comment.
  Future<ProjectComment?> updateComment(String projectId, String commentId, String newContent) async {
    final current = List<ProjectComment>.from(_cache[projectId] ?? await getComments(projectId));
    final index = current.indexWhere((c) => c.id == commentId);
    if (index == -1) return null;

    final target = current[index];
    final updated = target.copyWith(content: newContent.trim());
    current[index] = updated;
    _cache[projectId] = current;
    await _persist(projectId, current);

    return updated;
  }

  /// Deletes a comment.
  Future<bool> deleteComment(String projectId, String commentId) async {
    final current = List<ProjectComment>.from(_cache[projectId] ?? await getComments(projectId));
    final initialCount = current.length;
    current.removeWhere((c) => c.id == commentId);

    if (current.length != initialCount) {
      _cache[projectId] = current;
      await _persist(projectId, current);
      return true;
    }
    return false;
  }

  /// Persists a list of comments directly into cache and SharedPreferences.
  Future<void> saveComments(String projectId, List<ProjectComment> comments) async {
    final sorted = List<ProjectComment>.from(comments);
    sorted.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    _cache[projectId] = sorted;
    await _persist(projectId, sorted);
  }

  /// Clears all comments for a project.
  Future<void> clearComments(String projectId) async {
    _cache[projectId] = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_getKey(projectId));
  }

  /// Retrieves the last used reviewer name.
  Future<String> getDefaultAuthor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_defaultAuthorKey) ?? 'Reviewer';
    } catch (_) {
      return 'Reviewer';
    }
  }

  Future<void> _saveDefaultAuthor(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_defaultAuthorKey, name);
    } catch (_) {}
  }

  Future<void> _persist(String projectId, List<ProjectComment> comments) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = comments.map((c) => c.toJson()).toList();
      await prefs.setString(_getKey(projectId), jsonEncode(jsonList));
    } catch (e) {
      LoggerService.instance.log(
        LogLevel.error,
        'ProjectCollaborationService',
        'Failed to persist comments for $projectId: $e',
      );
    }
  }

  /// Exports comments as a clean Markdown Review Summary report.
  String exportMarkdownReport(String projectName, List<ProjectComment> comments) {
    final buffer = StringBuffer();
    buffer.writeln('# Video Review Report: $projectName');
    buffer.writeln('Generated: ${DateTime.now().toLocal().toString().split('.').first}');
    buffer.writeln('Total Comments: ${comments.length}');
    final pending = comments.where((c) => !c.isResolved).toList();
    final resolved = comments.where((c) => c.isResolved).toList();
    buffer.writeln('Pending: ${pending.length} | Resolved: ${resolved.length}');
    buffer.writeln();

    if (pending.isNotEmpty) {
      buffer.writeln('## ⏳ Pending Action Items');
      for (final c in pending) {
        buffer.writeln('- **[${c.formattedTimestamp}]** [${c.category.displayName.toUpperCase()}] **${c.authorName}** (${c.role.displayName}):');
        buffer.writeln('  ${c.content}');
      }
      buffer.writeln();
    }

    if (resolved.isNotEmpty) {
      buffer.writeln('## ✅ Resolved Items');
      for (final c in resolved) {
        buffer.writeln('- **[${c.formattedTimestamp}]** ~~${c.content}~~ *(Resolved by ${c.authorName})*');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  /// Exports comments as JSON string.
  String exportJson(List<ProjectComment> comments) {
    return const JsonEncoder.withIndent('  ').convert(comments.map((c) => c.toJson()).toList());
  }

  /// Imports comments from a JSON string.
  Future<int> importComments(String projectId, String jsonStr, {bool replace = false}) async {
    try {
      final dynamic decoded = jsonDecode(jsonStr);
      final List<dynamic> list = decoded is List ? decoded : (decoded is Map && decoded['comments'] is List ? decoded['comments'] as List : []);
      final imported = list
          .whereType<Map<String, dynamic>>()
          .map((map) => ProjectComment.fromJson(map))
          .toList();

      final existing = replace ? <ProjectComment>[] : List<ProjectComment>.from(_cache[projectId] ?? await getComments(projectId));
      final Map<String, ProjectComment> map = {
        for (final c in existing) c.id: c,
        for (final c in imported) c.id: c,
      };

      final merged = map.values.toList();
      await saveComments(projectId, merged);
      return imported.length;
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'ProjectCollaborationService', 'Failed to import comments: $e');
      return 0;
    }
  }

  /// Filter comments helper.
  List<ProjectComment> filterComments(
    List<ProjectComment> comments, {
    bool? isResolved,
    ProjectCommentCategory? category,
    String? searchQuery,
  }) {
    return comments.where((c) {
      if (isResolved != null && c.isResolved != isResolved) return false;
      if (category != null && c.category != category) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchesContent = c.content.toLowerCase().contains(query);
        final matchesAuthor = c.authorName.toLowerCase().contains(query);
        if (!matchesContent && !matchesAuthor) return false;
      }
      return true;
    }).toList();
  }
}
