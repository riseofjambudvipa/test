import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/viral_clipping_panel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ViralClippingPanel renders sections and toggles canvas aspect ratio', (tester) async {
    final project = Project()
      ..projectId = 'test_proj'
      ..name = 'Test Video'
      ..width = 1920
      ..height = 1080
      ..duration = 60.0
      ..words = [
        WordSchema()
          ..wordId = 'w1'
          ..text = 'The'
          ..start = 0.0
          ..end = 0.5,
        WordSchema()
          ..wordId = 'w2'
          ..text = 'secret'
          ..start = 0.5
          ..end = 1.0,
      ];

    final container = ProviderContainer();
    container.read(editorProvider.notifier).setProject(project);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: ViralClippingPanel(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('VIRAL SHORTS STUDIO'), findsOneWidget);
    expect(find.text('1. VERTICAL 9:16 REFRAME'), findsOneWidget);
    expect(find.text('2. SILENCE REMOVAL (JUMP-CUTS)'), findsOneWidget);
    expect(find.text('3. AI VIRAL HOOK DETECTOR'), findsOneWidget);

    // Initial state is 16:9 Landscape
    expect(find.text('16:9 LANDSCAPE'), findsOneWidget);

    // Tap to change to 9:16
    final reframeBtn = find.text('SET PROJECT CANVAS TO 9:16');
    expect(reframeBtn, findsOneWidget);
    await tester.tap(reframeBtn);
    await tester.pumpAndSettle();

    // Now state should update to 9:16 VERTICAL
    expect(container.read(editorProvider).project!.width, equals(1080));
    expect(container.read(editorProvider).project!.height, equals(1920));
    expect(find.text('9:16 VERTICAL'), findsOneWidget);
  });
}
