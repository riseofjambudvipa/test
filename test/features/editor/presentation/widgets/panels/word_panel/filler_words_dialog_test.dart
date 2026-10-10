import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/word_panel/filler_words_dialog.dart';
import '../../../../../../mocks/mocks.dart';
import '../../../../../../helpers/project_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Project testProject;
  late MockIsarService mockIsarService;

  setUpAll(() {
    registerFallbackValue(Project());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();

    mockIsarService = MockIsarService();
    when(() => mockIsarService.isInitialized).thenReturn(true);
    when(() => mockIsarService.saveProject(any())).thenAnswer((_) async {});
    IsarService.instance = mockIsarService;

    final w1 = makeWord(text: 'Hello', start: 0.0, end: 1.0);
    final w2 = makeWord(text: 'um', start: 1.0, end: 1.5);
    final w3 = makeWord(text: 'world', start: 1.5, end: 2.5);

    testProject = makeProject(
      projectId: 'proj_filler_test',
      name: 'Filler Test Project',
      videoPath: 'test.mp4',
      duration: 10.0,
      width: 1080,
      height: 1920,
      words: [w1, w2, w3],
    );
  });

  Widget buildTestWidget() {
    return ProviderScope(
      overrides: [
        editorProvider.overrideWith((ref) {
          final c = EditorController(ref);
          c.setProject(testProject);
          return c;
        }),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () => FillerWordsDialog.show(context, testProject),
                child: const Text('OPEN DIALOG'),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('FillerWordsDialog renders detected filler count and action cards', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    // Open dialog
    await tester.tap(find.text('OPEN DIALOG'));
    await tester.pumpAndSettle();

    expect(find.text('AI FILLER WORD REMOVAL'), findsOneWidget);
    expect(find.textContaining('Found 1 filler word'), findsOneWidget);
    expect(find.text('Cut Footage from Video & Audio'), findsOneWidget);
    expect(find.text('Hide from Captions Only'), findsOneWidget);
    expect(find.text('Restore All Filler Words'), findsOneWidget);
  });

  testWidgets('FillerWordsDialog tapping Cut Footage triggers cut and closes dialog', (tester) async {
    await tester.pumpWidget(buildTestWidget());

    await tester.tap(find.text('OPEN DIALOG'));
    await tester.pumpAndSettle();

    // Tap Cut Footage
    await tester.tap(find.text('Cut Footage from Video & Audio'));
    await tester.pumpAndSettle();

    // Dialog should be dismissed
    expect(find.text('AI FILLER WORD REMOVAL'), findsNothing);
    // SnackBar should be displayed
    expect(find.textContaining('Cut 1 filler word pause'), findsOneWidget);
  });
}
