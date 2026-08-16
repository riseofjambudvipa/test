import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_state.dart';
import '../../../../mocks/mocks.dart';
import '../../../../helpers/project_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Project testProject;
  late EditorController controller;
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
    
    // Inject mock singleton
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
          start: 0.0,
          end: 0.5,
          type: 'word',
          confidence: 1.0,
        ),
        makeWord(
          wordId: 'w2',
          text: 'world',
          start: 0.6,
          end: 1.0,
          type: 'word',
          confidence: 1.0,
        ),
      ],
    );

    controller = EditorController(MockRef());
    controller.setProject(testProject);
  });

  group('EditorController Core Tests', () {
    test('should initialize project state correctly', () {
      expect(controller.state.project, isNotNull);
      expect(controller.state.project!.projectId, 'proj_test_123');
      expect(controller.state.project!.words.length, 2);
      expect(controller.state.hasUnsavedChanges, isFalse);
    });

    test('should update single word text and timing and trigger auto-save', () {
      controller.updateWord('w1', text: 'Hey', start: 0.1, end: 0.4);

      final updatedProject = controller.state.project!;
      expect(updatedProject.words[0].text, 'Hey');
      expect(updatedProject.words[0].start, 0.1);
      expect(updatedProject.words[0].end, 0.4);
      expect(controller.state.hasUnsavedChanges, isTrue);
    });

    test('should track state in history and perform undo/redo', () {
      expect(controller.state.project!.words[0].text, 'Hello');

      controller.updateWord('w1', text: 'Hey');
      expect(controller.state.project!.words[0].text, 'Hey');

      controller.undo();
      expect(controller.state.project!.words[0].text, 'Hello');

      controller.redo();
      expect(controller.state.project!.words[0].text, 'Hey');
    });

    test('should split chunk at specific word', () {
      controller.splitChunkAtWord('w2');

      final updatedProject = controller.state.project!;
      expect(updatedProject.words[1].splitBefore, isTrue);
    });

    test('should delete word from words list', () {
      controller.deleteWords(['w1']);

      final updatedProject = controller.state.project!;
      expect(updatedProject.words.length, 1);
      expect(updatedProject.words[0].wordId, 'w2');
    });

    test('should update style property', () {
      controller.updateStyleProp('fontSize', 32.0);

      final updatedProject = controller.state.project!;
      expect(updatedProject.config.style.fontSize, 32.0);
    });
  });

  group('EditorController Advanced & Edge Case Tests', () {
    test('should update timings quietly and save on commit', () async {
      controller.updateWordTimingsQuietly('w1', start: 0.15, end: 0.45);
      
      expect(controller.state.project!.words[0].start, 0.15);
      expect(controller.state.project!.words[0].end, 0.45);
      // Quiet operations shouldn't trigger instant DB writes
      verifyNever(() => mockIsarService.saveProject(any()));

      await controller.saveProject();
      verify(() => mockIsarService.saveProject(any())).called(1);
    });

    test('should perform batch updates on multiple words', () {
      controller.batchUpdateWords(['w1', 'w2'], hidden: true, className: 'bounce');

      final words = controller.state.project!.words;
      expect(words[0].hidden, isTrue);
      expect(words[0].className, 'bounce');
      expect(words[1].hidden, isTrue);
      expect(words[1].className, 'bounce');
    });

    test('should perform find and replace on matching words in a single transaction', () {
      final project = controller.state.project!;
      project.words = [
        ...project.words,
        makeWord(
          wordId: 'w3',
          text: 'HelloWorld',
          start: 1.1,
          end: 1.5,
          type: 'word',
          confidence: 1.0,
        ),
      ];
      controller.setProject(project);

      final count = controller.findAndReplaceText('hello', 'Hi');
      
      expect(count, 2); // 'Hello' and 'HelloWorld'
      final words = controller.state.project!.words;
      expect(words[0].text, 'Hi');
      expect(words[1].text, 'world');
      expect(words[2].text, 'HiWorld');
      expect(controller.state.hasUnsavedChanges, isTrue);

      controller.undo();
      final revertedWords = controller.state.project!.words;
      expect(revertedWords[0].text, 'Hello');
      expect(revertedWords[2].text, 'HelloWorld');
    });

    test('should duplicate a chunk with proper timing shifts', () {
      controller.duplicateChunk(['w1', 'w2']);

      final words = controller.state.project!.words;
      expect(words.length, 4);
      expect(words[2].text, 'Hello');
      expect(words[3].text, 'world');
      
      // Original w2 ended at 1.0. Shift offset = 1.0 - 0.0 + 0.1 = 1.1s.
      // Copy 1 (from w1: 0.0-0.5) starts at 1.1s, ends at 1.6s.
      expect(words[2].start, 1.1);
      expect(words[2].end, 1.6);
      expect(words[2].wordId, isNot('w1'));
    });

    test('should insert a blank word after a specified word', () {
      controller.addWordAfter('w1');

      final words = controller.state.project!.words;
      expect(words.length, 3);
      expect(words[1].text, '');
      expect(words[1].start, 0.5);
      expect(words[1].end, 1.0);
    });

    test('should add split chunk after a specified word', () {
      controller.addChunkAfter('w1');

      final words = controller.state.project!.words;
      expect(words.length, 3);
      expect(words[1].text, '');
      expect(words[1].splitBefore, isTrue);
    });

    test('should correctly configure trim boundaries', () {
      controller.setTrim(1.5, 8.5);

      final project = controller.state.project!;
      expect(project.trimStart, 1.5);
      expect(project.trimEnd, 8.5);
    });

    test('should replace full config at once', () {
      final newConfig = ProjectConfigSchema()
        ..name = 'new_template'
        ..stroke = 'thick'
        ..style = (StyleConfigSchema()
          ..fontFamily = 'Outfit'
          ..fontWeight = '900'
          ..textTransform = 'uppercase'
          ..color = '#ffffff'
          ..fontSize = 24.0
          ..top = 70.0)
        ..highlightStyle = (HighlightStyleSchema()
          ..mainColor = '#f97316'
          ..secondColor = '#06b6d4'
          ..thirdColor = '#22c55e')
        ..subs = (SubtitleConfigSchema()
          ..chunkSize = 2
          ..chunkLineMaxLength = 20)
        ..animation = 'pop'
        ..shadow = 'soft';

      controller.setFullConfig(newConfig);
      expect(controller.state.project!.config.name, 'new_template');
      expect(controller.state.project!.config.stroke, 'thick');
    });

    test('should enforce maximum history size of 50', () {
      for (int i = 0; i < 60; i++) {
        controller.updateWord('w1', text: 'Hey $i');
      }
      
      // Since history size limit is 50, the first 10 edits are discarded.
      // The oldest retained text should be 'Hey 10'. We should be able to call undo exactly 49 times
      // until index 0 is reached, and then further undos do nothing.
      int undoCount = 0;
      String? lastText = controller.state.project!.words[0].text;
      
      for (int i = 0; i < 100; i++) {
        controller.undo();
        final currentText = controller.state.project!.words[0].text;
        if (currentText != lastText) {
          undoCount++;
          lastText = currentText;
        }
      }

      expect(undoCount, 49);
      expect(lastText, 'Hey 10');
    });

    test('should invalidate redo history when a new change is made after undos', () {
      controller.updateWord('w1', text: 'Change 1');
      controller.updateWord('w1', text: 'Change 2');

      controller.undo(); // back to 'Change 1'
      expect(controller.state.project!.words[0].text, 'Change 1');

      // Make a fresh change
      controller.updateWord('w1', text: 'Change 3');
      expect(controller.state.project!.words[0].text, 'Change 3');

      // Redo should do nothing now since the redo stack got cleared
      controller.redo();
      expect(controller.state.project!.words[0].text, 'Change 3');
    });

    test('should update playback states correctly', () {
      controller.setIsPlaying(true);
      expect(controller.state.isPlaying, isTrue);

      controller.setActiveTab(EditorTab.style);
      expect(controller.state.activeTab, EditorTab.style);
    });

    test('should update highlight style and mark project completed', () async {
      controller.updateHighlightStyle(
        mainColor: '#123456',
        secondColor: '#654321',
        thirdColor: '#abcdef',
      );

      final config = controller.state.project!.config;
      expect(config.highlightStyle.mainColor, '#123456');
      expect(config.highlightStyle.secondColor, '#654321');
      expect(config.highlightStyle.thirdColor, '#abcdef');

      // Mark completed
      controller.markCompleted();
      expect(controller.state.project!.status, 'completed');
      await controller.saveProject();
      verify(() => mockIsarService.saveProject(any())).called(greaterThanOrEqualTo(1));
    });

    test('should support quiet timeline updates and commitHistoryAndSave', () async {
      controller.updateWordTimingsQuietly('w1', start: 0.1, end: 0.4);
      expect(controller.state.project!.words[0].start, 0.1);
      
      // Since it is quiet, history is not yet committed (so undo stack won't have it)
      // Call commitHistoryAndSave to write to history & DB
      controller.commitHistoryAndSave();
      await controller.saveProject();
      verify(() => mockIsarService.saveProject(any())).called(greaterThanOrEqualTo(1));

      // Now we can undo back to original start time (0.0)
      controller.undo();
      expect(controller.state.project!.words[0].start, 0.0);
    });

    test('should update emoji configuration positioning', () {
      // 1. Add emoji to w1
      controller.updateWord('w1', emoji: '🔥');
      
      var word = controller.state.project!.words[0];
      expect(word.emoji, '🔥');
      expect(word.emojiConfig, isNotNull);
      expect(word.emojiConfig!.x, 0.0);
      expect(word.emojiConfig!.y, 0.0);
      expect(word.emojiConfig!.scale, 1.0);

      // 2. Update positioning coordinates
      controller.updateWord('w1', emojiX: 10.5, emojiY: -20.0, emojiScale: 2.5);
      
      word = controller.state.project!.words[0];
      expect(word.emojiConfig!.x, 10.5);
      expect(word.emojiConfig!.y, -20.0);
      expect(word.emojiConfig!.scale, 2.5);

      // 3. Remove emoji
      controller.updateWord('w1', emoji: 'none');
      word = controller.state.project!.words[0];
      expect(word.emoji, isNull);
      expect(word.emojiConfig, isNull);
    });

    test('should not auto-save when auto-save setting is disabled', () async {
      await SettingsService.instance.setAutoSave(false);
      clearInteractions(mockIsarService);

      controller.updateWord('w1', text: 'Hey-AutoSaveDisabled');
      
      // Wait for debounce timer (3 seconds) to ensure it would have run
      await Future.delayed(const Duration(seconds: 3, milliseconds: 500));
      
      // Verify saveProject was never called
      verifyNever(() => mockIsarService.saveProject(any()));
      expect(controller.state.hasUnsavedChanges, isTrue);

      // Re-enable auto-save for other tests
      await SettingsService.instance.setAutoSave(true);
    });

    test('should auto-save when auto-save setting is enabled', () async {
      await SettingsService.instance.setAutoSave(true);
      clearInteractions(mockIsarService);

      controller.updateWord('w1', text: 'Hey-AutoSaveEnabled');
      
      // Wait for debounce timer (3 seconds)
      await Future.delayed(const Duration(seconds: 3, milliseconds: 500));
      
      // Verify saveProject was called
      verify(() => mockIsarService.saveProject(any())).called(1);
      expect(controller.state.hasUnsavedChanges, isFalse);
    });
  });

  group('EditorController Multi-Segment Tests', () {
    test('should initialize segments list when loading project', () {
      expect(controller.state.project!.segments, isNotNull);
      expect(controller.state.project!.segments!.length, 1);
      expect(controller.state.project!.segments![0].start, 0.0);
      expect(controller.state.project!.segments![0].end, 10.0);
      expect(controller.state.project!.segments![0].isDeleted, isFalse);
    });

    test('should split segment at specific time', () {
      controller.splitSegmentAtTime(4.0);

      final segments = controller.state.project!.segments!;
      expect(segments.length, 2);
      expect(segments[0].start, 0.0);
      expect(segments[0].end, 4.0);
      expect(segments[0].isDeleted, isFalse);

      expect(segments[1].start, 4.0);
      expect(segments[1].end, 10.0);
      expect(segments[1].isDeleted, isFalse);
    });

    test('should toggle segment deletion status', () {
      controller.splitSegmentAtTime(4.0);
      controller.toggleSegmentDeleted(2.0); // Toggles first segment

      final segments = controller.state.project!.segments!;
      expect(segments[0].isDeleted, isTrue);
      expect(segments[1].isDeleted, isFalse);

      controller.toggleSegmentDeleted(2.0); // Toggles back
      expect(controller.state.project!.segments![0].isDeleted, isFalse);
    });

    test('should reset all segments to full duration', () {
      controller.splitSegmentAtTime(4.0);
      controller.toggleSegmentDeleted(2.0);
      expect(controller.state.project!.segments!.length, 2);

      controller.resetSegments();
      expect(controller.state.project!.segments!.length, 1);
      expect(controller.state.project!.segments![0].start, 0.0);
      expect(controller.state.project!.segments![0].end, 10.0);
      expect(controller.state.project!.segments![0].isDeleted, isFalse);
    });
  });

  group('EditorController Find & Replace Trigger Tests', () {
    test('should start with findReplaceCounter at 0', () {
      expect(controller.state.findReplaceCounter, 0);
    });

    test('should increment findReplaceCounter on triggerFindReplace', () {
      controller.triggerFindReplace();
      expect(controller.state.findReplaceCounter, 1);

      controller.triggerFindReplace();
      expect(controller.state.findReplaceCounter, 2);
    });

    test('triggerFindReplace should not affect revision or hasUnsavedChanges', () {
      final revisionBefore = controller.state.revision;
      controller.triggerFindReplace();
      expect(controller.state.revision, revisionBefore);
      expect(controller.state.hasUnsavedChanges, isFalse);
    });

    test('findReplaceCounter should be preserved across unrelated state updates', () {
      controller.triggerFindReplace();
      controller.triggerFindReplace();
      expect(controller.state.findReplaceCounter, 2);

      // An unrelated state mutation should not reset the counter
      controller.updateStyleProp('fontSize', 36.0);
      expect(controller.state.findReplaceCounter, 2);
    });
  });

  group('EditorController Zero Duration & Empty Word Edge Cases', () {
    test('handles zero duration project initialization gracefully', () {
      final zeroProj = makeProject(
        projectId: 'proj_zero_duration',
        name: 'Zero Duration Project',
        videoPath: 'zero.mp4',
        duration: 0.0,
        trimStart: 0.0,
        trimEnd: 0.0,
        words: [],
      );

      final zeroController = EditorController(MockRef());
      zeroController.setProject(zeroProj);

      expect(zeroController.state.project, isNotNull);
      expect(zeroController.state.project!.duration, 0.0);
      expect(zeroController.state.project!.words, isEmpty);
    });

    test('handles empty words list in batch operations without crash', () {
      final emptyWordsProj = makeProject(
        projectId: 'proj_empty_words',
        name: 'Empty Words Project',
        videoPath: 'empty.mp4',
        duration: 5.0,
        trimStart: 0.0,
        trimEnd: 5.0,
        words: [],
      );

      final c = EditorController(MockRef());
      c.setProject(emptyWordsProj);

      // Verify batch updates or operations do not crash when words are empty
      expect(() => c.updateStyleProp('fontFamily', 'Roboto'), returnsNormally);
      expect(() => c.updateWordTimingsQuietly('w1', start: 1.0, end: 2.0), returnsNormally); // Non-existent wordId should not crash
      expect(() => c.deleteWords(['w1']), returnsNormally); // Non-existent wordId should not crash
    });
  });
}
