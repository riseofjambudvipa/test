import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/collaboration/project_comment.dart';
import 'package:capstudio/core/collaboration/project_collaboration_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('ProjectComment Model Tests', () {
    test('create generates valid ID, formatted timestamp, and defaults', () {
      final comment = ProjectComment.create(
        projectId: 'proj_123',
        timestamp: 83.4,
        authorName: 'Alex Reviewer',
        content: 'Trim this pause before the drop',
        role: ProjectCommentRole.reviewer,
        category: ProjectCommentCategory.pacing,
      );

      expect(comment.id, isNotEmpty);
      expect(comment.projectId, 'proj_123');
      expect(comment.timestamp, 83.4);
      expect(comment.authorName, 'Alex Reviewer');
      expect(comment.content, 'Trim this pause before the drop');
      expect(comment.role, ProjectCommentRole.reviewer);
      expect(comment.category, ProjectCommentCategory.pacing);
      expect(comment.isResolved, isFalse);
      expect(comment.resolvedAt, isNull);
      expect(comment.formattedTimestamp, '01:23.4');
    });

    test('toJson and fromJson preserves all fields', () {
      final now = DateTime.now();
      final comment = ProjectComment(
        id: 'c_test_999',
        projectId: 'proj_abc',
        timestamp: 12.5,
        authorName: 'Client Boss',
        role: ProjectCommentRole.client,
        category: ProjectCommentCategory.copy,
        content: 'Fix spelling of subtitle',
        createdAt: now,
        isResolved: true,
        resolvedAt: now.add(const Duration(minutes: 5)),
      );

      final json = comment.toJson();
      final restored = ProjectComment.fromJson(json);

      expect(restored.id, 'c_test_999');
      expect(restored.projectId, 'proj_abc');
      expect(restored.timestamp, 12.5);
      expect(restored.authorName, 'Client Boss');
      expect(restored.role, ProjectCommentRole.client);
      expect(restored.category, ProjectCommentCategory.copy);
      expect(restored.content, 'Fix spelling of subtitle');
      expect(restored.isResolved, isTrue);
      expect(restored.resolvedAt, isNotNull);
    });

    test('role and category fallback to default when invalid', () {
      expect(ProjectCommentRole.fromString('non_existent'), ProjectCommentRole.reviewer);
      expect(ProjectCommentCategory.fromString('unknown_cat'), ProjectCommentCategory.general);
    });
  });

  group('ProjectCollaborationService Tests', () {
    test('addComment persists comment and updates cache', () async {
      final service = ProjectCollaborationService.instance;
      await service.clearComments('test_proj_1');

      final added = await service.addComment(
        projectId: 'test_proj_1',
        timestamp: 10.0,
        authorName: 'Lead Editor',
        content: 'Change subtitle font color to yellow',
        role: ProjectCommentRole.editor,
        category: ProjectCommentCategory.visual,
      );

      final comments = await service.getComments('test_proj_1');
      expect(comments.length, 1);
      expect(comments.first.id, added.id);
      expect(comments.first.content, 'Change subtitle font color to yellow');
      expect(service.getCommentsSync('test_proj_1').length, 1);
    });

    test('toggleResolved updates comment state', () async {
      final service = ProjectCollaborationService.instance;
      await service.clearComments('test_proj_2');

      final added = await service.addComment(
        projectId: 'test_proj_2',
        timestamp: 5.0,
        authorName: 'Reviewer',
        content: 'Check audio volume here',
        category: ProjectCommentCategory.audio,
      );

      expect(added.isResolved, isFalse);

      final resolved = await service.toggleResolved('test_proj_2', added.id);
      expect(resolved, isNotNull);
      expect(resolved!.isResolved, isTrue);
      expect(resolved.resolvedAt, isNotNull);

      final reopened = await service.toggleResolved('test_proj_2', added.id);
      expect(reopened!.isResolved, isFalse);
    });

    test('updateComment and deleteComment function properly', () async {
      final service = ProjectCollaborationService.instance;
      await service.clearComments('test_proj_3');

      final added = await service.addComment(
        projectId: 'test_proj_3',
        timestamp: 14.0,
        authorName: 'Director',
        content: 'Original note',
      );

      final updated = await service.updateComment('test_proj_3', added.id, 'Updated note content');
      expect(updated!.content, 'Updated note content');

      final deleted = await service.deleteComment('test_proj_3', added.id);
      expect(deleted, isTrue);

      final remaining = await service.getComments('test_proj_3');
      expect(remaining.isEmpty, isTrue);
    });

    test('exportMarkdownReport formats clean markdown with pending & resolved sections', () async {
      final service = ProjectCollaborationService.instance;
      final comments = [
        ProjectComment.create(
          projectId: 'p',
          timestamp: 4.5,
          authorName: 'Sarah',
          content: 'Increase word spacing',
          role: ProjectCommentRole.reviewer,
          category: ProjectCommentCategory.visual,
        ),
        ProjectComment.create(
          projectId: 'p',
          timestamp: 18.0,
          authorName: 'Alex',
          content: 'Fix grammar on line 2',
          role: ProjectCommentRole.editor,
          category: ProjectCommentCategory.copy,
        ).copyWith(isResolved: true),
      ];

      final report = service.exportMarkdownReport('Viral TikTok Clip', comments);
      expect(report, contains('# Video Review Report: Viral TikTok Clip'));
      expect(report, contains('Pending: 1 | Resolved: 1'));
      expect(report, contains('⏳ Pending Action Items'));
      expect(report, contains('Increase word spacing'));
      expect(report, contains('✅ Resolved Items'));
      expect(report, contains('Fix grammar on line 2'));
    });

    test('filterComments handles resolved status, category, and search query', () {
      final service = ProjectCollaborationService.instance;
      final c1 = ProjectComment.create(
        projectId: 'p',
        timestamp: 2.0,
        authorName: 'Alice',
        content: 'Visual hook needs pop animation',
        category: ProjectCommentCategory.visual,
      );
      final c2 = ProjectComment.create(
        projectId: 'p',
        timestamp: 10.0,
        authorName: 'Bob',
        content: 'Audio whoosh sound is too quiet',
        category: ProjectCommentCategory.audio,
      ).copyWith(isResolved: true);

      final list = [c1, c2];

      final pendingOnly = service.filterComments(list, isResolved: false);
      expect(pendingOnly.length, 1);
      expect(pendingOnly.first.content, c1.content);

      final audioOnly = service.filterComments(list, category: ProjectCommentCategory.audio);
      expect(audioOnly.length, 1);
      expect(audioOnly.first.content, c2.content);

      final searchBob = service.filterComments(list, searchQuery: 'bob');
      expect(searchBob.length, 1);
      expect(searchBob.first.authorName, 'Bob');
    });
  });
}
