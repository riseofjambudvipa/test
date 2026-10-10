import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/collaboration/project_comment.dart';
import 'package:capstudio/core/collaboration/project_collaboration_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/word_panel/review_comments_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget(WidgetRef? capturedRef) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          return MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (innerContext) {
                  return ElevatedButton(
                    onPressed: () => ReviewCommentsDialog.show(innerContext),
                    child: const Text('OPEN DIALOG'),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  testWidgets('ReviewCommentsDialog renders header and empty state', (tester) async {
    await tester.pumpWidget(buildTestWidget(null));
    await tester.pump();

    // Tap to open dialog
    await tester.tap(find.text('OPEN DIALOG'));
    await tester.pumpAndSettle();

    expect(find.text('Team Review & Notes'), findsOneWidget);
    expect(find.text('ADD NOTE AT PLAYHEAD'), findsOneWidget);
    expect(find.text('No Review Notes Yet'), findsOneWidget);
  });

  testWidgets('ReviewCommentsDialog displays comments and filters', (tester) async {
    final service = ProjectCollaborationService.instance;
    await service.clearComments('test_proj_widget');
    await service.addComment(
      projectId: 'test_proj_widget',
      timestamp: 12.0,
      authorName: 'Client Reviewer',
      content: 'Make hook title bigger and yellow',
      role: ProjectCommentRole.client,
      category: ProjectCommentCategory.visual,
    );

    final project = Project()
      ..projectId = 'test_proj_widget'
      ..name = 'Client Review Video'
      ..words = [];

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            // Set project
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(editorProvider.notifier).setProject(project);
            });

            return MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (innerContext) {
                    return ElevatedButton(
                      onPressed: () => ReviewCommentsDialog.show(innerContext),
                      child: const Text('OPEN DIALOG'),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open dialog
    await tester.tap(find.text('OPEN DIALOG'));
    await tester.pumpAndSettle();

    expect(find.text('Team Review & Notes'), findsOneWidget);
    expect(find.text('Make hook title bigger and yellow'), findsOneWidget);
    expect(find.text('Client Reviewer (Client)'), findsOneWidget);
    expect(find.text('00:12.0'), findsOneWidget);
  });
}
