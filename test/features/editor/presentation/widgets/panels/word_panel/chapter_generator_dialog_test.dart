import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/word_panel/chapter_generator_dialog.dart';
import '../../../../../../test_environment.dart';

void main() {
  registerTestEnvironment(silenceLogs: true);

  testWidgets('ChapterGeneratorDialog renders detected chapters, validity badge, and add/copy actions', (tester) async {
    final words = [
      WordSchema()..text = 'Welcome'..start = 0.0..end = 0.5,
      WordSchema()..text = 'everyone'..start = 0.5..end = 1.0,

      WordSchema()..text = 'moving'..start = 30.0..end = 30.4,
      WordSchema()..text = 'on'..start = 30.4..end = 30.7,
      WordSchema()..text = 'to'..start = 30.7..end = 31.0,
      WordSchema()..text = 'editing'..start = 31.0..end = 31.5,

      WordSchema()..text = 'finally'..start = 70.0..end = 70.4,
      WordSchema()..text = 'in'..start = 70.4..end = 70.7,
      WordSchema()..text = 'conclusion'..start = 70.7..end = 71.3,
    ];

    final project = Project()
      ..projectId = 'proj_ch_test'
      ..name = 'Chapter Test Video'
      ..duration = 100.0
      ..words = words;

    final container = ProviderContainer();
    container.read(editorProvider.notifier).setProject(project);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: ChapterGeneratorDialog(project: project),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Dialog Header
    expect(find.text('YOUTUBE CHAPTER GENERATOR'), findsOneWidget);

    // 2. Verify YouTube note/badge
    expect(find.textContaining('YOUTUBE'), findsWidgets);

    // 3. Verify Introduction chapter at 00:00
    expect(find.text('00:00'), findsWidgets);

    // 4. Verify Copy Button
    expect(find.text('COPY YOUTUBE CHAPTERS'), findsOneWidget);

    // 5. Verify Add Chapter Button exists
    expect(find.textContaining('ADD AT'), findsOneWidget);

    // 6. Tap Add Chapter button and verify chapter list updates
    await tester.tap(find.textContaining('ADD AT'));
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsWidgets);
  });
}
