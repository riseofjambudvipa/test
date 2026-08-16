import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide AssetManifest;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/assets/asset_manifest.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/word_panel.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import '../../../../helpers/project_fixture.dart';

class MockIsarService extends Mock implements IsarService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Project testProject;
  late MockIsarService mockIsarService;
  final mockManifest = AssetManifest(version: '2.0', packs: [], emojis: []);

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

    testProject = makeProject(
      projectId: 'proj_test_123',
      name: 'Test Project',
      videoPath: 'test.mp4',
      duration: 10.0,
      width: 1080,
      height: 1920,
      trimStart: 0.0,
      trimEnd: 10.0,
      status: 'draft',
      config: makeConfig(
        name: 'default',
        fontFamily: 'Montserrat',
        fontWeight: '900',
        textTransform: 'uppercase',
        color: '#ffffff',
        fontSize: 24.0,
        top: 70.0,
        mainColor: '#f97316',
        secondColor: '#06b6d4',
        thirdColor: '#22c55e',
        chunkSize: 2,
        chunkLineMaxLength: 20,
        animation: 'pop',
        shadow: 'soft',
        stroke: 'none',
      ),
      words: [
        makeWord(
          wordId: 'w1',
          text: 'Hello',
          start: 1.0,
          end: 1.5,
          type: 'word',
          confidence: 0.9,
        ),
        makeWord(
          wordId: 'w2',
          text: 'world',
          start: 1.6,
          end: 2.0,
          type: 'word',
          confidence: 0.3, // Uncertain (<40% - Red)
        ),
        makeWord(
          wordId: 'w3',
          text: 'Flutter',
          start: 3.0,
          end: 3.5,
          type: 'word',
          confidence: 0.8,
        ),
      ],
    );
  });

  testWidgets('WordPanel should render caption list, find & replace button, and confidence legend', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    await tester.pumpAndSettle();

    expect(find.text('CAPTION LIST'), findsOneWidget);
    expect(find.text('Uncertain (<40%)'), findsOneWidget);
    expect(find.text('Medium (40-60%)'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    expect(find.text('world'), findsOneWidget);

    final findReplaceBtn = find.byIcon(Icons.find_replace_rounded);
    expect(findReplaceBtn, findsOneWidget);
  });

  testWidgets('WordPanel should jump timeline position to the next uncertain word when tapping jump warning icon', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    // Position timeline before the first uncertain word (time = 0.0s)
    container.read(editorProvider.notifier).setCurrentTime(0.0);
    await tester.pumpAndSettle();

    final jumpBtn = find.byIcon(Icons.error_outline);
    expect(jumpBtn, findsOneWidget);

    // Tap jump to uncertain word warning icon
    await tester.tap(jumpBtn);
    await tester.pumpAndSettle();

    // Verify current time was correctly updated to w2's start time (1.6s)
    expect(container.read(editorProvider).currentTime, closeTo(1.6, 0.001));
  });

  testWidgets('WordPanel should toggle visibility batch state for all words inside a chunk when visibility icon clicked', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    await tester.pumpAndSettle();

    // Check first chunk hide button (should be visibility_outlined icon initially)
    final hideBtn = find.byIcon(Icons.visibility_outlined).first;
    expect(hideBtn, findsOneWidget);

    // Tap hide chunk button
    await tester.tap(hideBtn);
    await tester.pumpAndSettle();

    // Verify both words in chunk 1 (w1, w2) have their hidden state updated to true
    final words = container.read(editorProvider).project!.words;
    expect(words[0].hidden, isTrue);
    expect(words[1].hidden, isTrue);
    expect(words[2].hidden == true, isFalse); // Chunk 2 (w3) remains visible
  });

  testWidgets('WordPanel should open find & replace dialog, type terms, and replace occurrences globally', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    await tester.pumpAndSettle();

    final findReplaceBtn = find.byIcon(Icons.find_replace_rounded);
    await tester.tap(findReplaceBtn);
    await tester.pumpAndSettle();

    // Verify Find & Replace dialog popped up
    expect(find.text('FIND & REPLACE'), findsOneWidget);

    // Find the text fields in dialog
    final findField = find.widgetWithText(TextField, 'Find text');
    final replaceField = find.widgetWithText(TextField, 'Replace with');
    expect(findField, findsOneWidget);
    expect(replaceField, findsOneWidget);

    // Type query terms
    await tester.enterText(findField, 'Hello');
    await tester.enterText(replaceField, 'Hey');
    await tester.pump();

    // Tap REPLACE ALL button
    final replaceAllBtn = find.text('REPLACE ALL');
    expect(replaceAllBtn, findsOneWidget);
    await tester.tap(replaceAllBtn);
    await tester.pumpAndSettle();

    // Check count success notification text is displayed inside the dialog
    expect(find.text('Replaced 1 occurrences!'), findsOneWidget);

    // Verify the word text in editor state was replaced correctly
    final words = container.read(editorProvider).project!.words;
    expect(words[0].text, 'Hey');
    expect(words[1].text, 'world');
  });

  testWidgets('WordPanel should open word settings dialog on double tap, enter new text, and save on submit', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    await tester.pumpAndSettle();

    // Verify word "Hello" is present
    expect(find.text('Hello'), findsOneWidget);

    // Double tap the word "Hello" to open settings dialog
    await tester.tap(find.text('Hello'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    // Verify Word Settings dialog appears
    expect(find.text('WORD SETTINGS'), findsOneWidget);
    final wordTextField = find.widgetWithText(TextField, 'Word Text');
    expect(wordTextField, findsOneWidget);

    // Type the new word "Hi" and save
    await tester.enterText(wordTextField, 'Hi');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    // Verify it saved and the text in state is updated
    final words = container.read(editorProvider).project!.words;
    expect(words[0].text, 'Hi');
    expect(find.text('Hi'), findsOneWidget);
  });

  testWidgets('WordPanel word settings dialog validation: entering empty text does not modify original word', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    await tester.pumpAndSettle();

    // Double tap the word "Hello" to open settings dialog
    await tester.tap(find.text('Hello'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.text('Hello'));
    await tester.pumpAndSettle();

    // Verify Word Settings dialog appears
    expect(find.text('WORD SETTINGS'), findsOneWidget);
    final wordTextField = find.widgetWithText(TextField, 'Word Text');
    expect(wordTextField, findsOneWidget);

    // Enter empty/whitespace text and save
    await tester.enterText(wordTextField, '   ');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    // Verify it was NOT saved and the text remains "Hello"
    final words = container.read(editorProvider).project!.words;
    expect(words[0].text, 'Hello');
    expect(find.text('Hello'), findsOneWidget);
  });

  testWidgets('WordPanel keyboard shortcut: pressing Delete deletes focused word', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    await tester.pumpAndSettle();

    // Focus the word chip "Hello"
    final helloElement = tester.element(find.text('Hello'));
    Focus.of(helloElement).requestFocus();
    await tester.pump();

    // Press Delete keyboard key
    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pumpAndSettle();

    // Verify "Hello" (w1) is removed from the project words
    final words = container.read(editorProvider).project!.words;
    expect(words.any((w) => w.wordId == 'w1'), isFalse);
    expect(find.text('Hello'), findsNothing);
  });

  testWidgets('WordPanel keyboard shortcut: pressing Backspace deletes focused word', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    await tester.pumpAndSettle();

    // Focus the word chip "Hello"
    final helloElement = tester.element(find.text('Hello'));
    Focus.of(helloElement).requestFocus();
    await tester.pump();

    // Press Backspace keyboard key
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    // Verify "Hello" (w1) is removed from the project words
    final words = container.read(editorProvider).project!.words;
    expect(words.any((w) => w.wordId == 'w1'), isFalse);
    expect(find.text('Hello'), findsNothing);
  });

  testWidgets('WordPanel chunk controls: split chunk at word splits correctly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    await tester.pumpAndSettle();

    // Verify initial layout has 1 chunk containing w1 and w2 (size 2 is current max)
    // Find split chunk button
    final splitBtn = find.byIcon(Icons.content_cut_rounded).first;
    expect(splitBtn, findsOneWidget);

    await tester.tap(splitBtn);
    await tester.pumpAndSettle();

    // Verify that a split event happened
    // The controller should split the chunk at the mid word or largest gap
    // In our testProject, w1 starts at 1.0, ends 1.5. w2 starts at 1.6, ends 2.0.
    // Tapping split chunk on chunk 1 splits at w2, setting splitBefore to true on w2
    final words = container.read(editorProvider).project!.words;
    expect(words[1].splitBefore, isTrue);
  });

  testWidgets('WordPanel chunk controls: insert line after chunk appends a new chunk', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    await tester.pumpAndSettle();

    // Find and tap add chunk button
    final addBtn = find.byIcon(Icons.add_circle_outline_rounded).first;
    expect(addBtn, findsOneWidget);

    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // Verify a new empty word is added to editor state
    final words = container.read(editorProvider).project!.words;
    expect(words.any((w) => w.text == '' || w.text == null), isTrue);
    expect(find.text('[New Word]'), findsOneWidget);
  });

  testWidgets('WordPanel chunk controls: duplicate chunk creates duplicate words', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    await tester.pumpAndSettle();

    final duplicateBtn = find.byIcon(Icons.copy_outlined).first;
    expect(duplicateBtn, findsOneWidget);

    await tester.tap(duplicateBtn);
    await tester.pumpAndSettle();

    // Verify words list size increases by duplicated chunk's word count (2)
    final words = container.read(editorProvider).project!.words;
    expect(words.length, 5); // 3 original + 2 duplicated = 5
  });

  testWidgets('WordPanel chunk controls: delete chunk removes all words in chunk', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    await tester.pumpAndSettle();

    final deleteBtn = find.byIcon(Icons.delete_outline_rounded).first;
    expect(deleteBtn, findsOneWidget);

    await tester.tap(deleteBtn);
    await tester.pumpAndSettle();

    // Verify first chunk words (w1, w2) are deleted
    final words = container.read(editorProvider).project!.words;
    expect(words.length, 1); // Only w3 remains
    expect(words[0].wordId, 'w3');
  });

  testWidgets('WordPanel find & replace validation: searching empty string returns early without replacements', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    await tester.pumpAndSettle();

    final findReplaceBtn = find.byIcon(Icons.find_replace_rounded);
    await tester.tap(findReplaceBtn);
    await tester.pumpAndSettle();

    // Keep Find field empty, fill Replace with field
    final replaceField = find.widgetWithText(TextField, 'Replace with');
    await tester.enterText(replaceField, 'Hey');
    await tester.pump();

    // Tap REPLACE ALL button
    await tester.tap(find.text('REPLACE ALL'));
    await tester.pumpAndSettle();

    // Verify that "Replaced 0 occurrences!" is NOT rendered (since it returned early on empty search query)
    expect(find.textContaining('Replaced'), findsNothing);

    // Verify project state words are unmodified
    final words = container.read(editorProvider).project!.words;
    expect(words[0].text, 'Hello');
  });

  testWidgets('WordPanel word settings dialog: long press opens dialog and saves modifications', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    await tester.pumpAndSettle();

    // Long press on "Hello" word chip
    await tester.longPress(find.text('Hello'));
    await tester.pumpAndSettle();

    // Verify Word Settings dialog is visible
    expect(find.text('WORD SETTINGS'), findsOneWidget);

    // Update text
    final wordTextField = find.widgetWithText(TextField, 'Word Text');
    expect(wordTextField, findsOneWidget);
    await tester.enterText(wordTextField, 'Welcome');

    // Tap SAVE
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    // Verify updated word is present in editor state and layout
    final words = container.read(editorProvider).project!.words;
    expect(words[0].text, 'Welcome');
    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('WordPanel timing edit dialog: opens edit timing dialog and saves proportional updates', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 600,
              child: WordPanel(),
            ),
          ),
        ),
      ),
    );

    final element = tester.element(find.byType(WordPanel));
    final container = ProviderScope.containerOf(element);
    container.read(editorProvider.notifier).setProject(testProject);
    await tester.pumpAndSettle();

    // Tap timing indicator chip "1.00s → 2.00s"
    final timingBtn = find.text('1.00s → 2.00s');
    expect(timingBtn, findsOneWidget);
    await tester.tap(timingBtn);
    await tester.pumpAndSettle();

    // Verify Edit Timing dialog is visible
    expect(find.text('EDIT TIMING'), findsOneWidget);

    // Find start time textfield, enter new start time "1.200"
    final startField = find.byType(TextField).first; // Start Time text field is first
    await tester.enterText(startField, '1.200');
    // Submit text to trigger validation and update
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    // Tap SAVE
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    // Verify the first word timing was updated proportionally
    final words = container.read(editorProvider).project!.words;
    // Since start went from 1.0 to 1.2, new start should be exactly 1.2
    expect(words[0].start, closeTo(1.2, 0.001));
  });
}
