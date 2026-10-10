import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import '../../../../mocks/mocks.dart';
import '../../../../helpers/project_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    IsarService.instance = mockIsarService;
    
    controller = EditorController(MockRef());
  });

  group('EditorController Boundary & Edge Cases', () {
    test('Gracefully handles actions when no project is loaded (null safety)', () {
      expect(controller.state.project, isNull);

      // Trigger actions - none of these should crash
      controller.undo();
      controller.redo();
      controller.updateWord('w1', text: 'Hey');
      controller.deleteWords(['w1']);
      controller.duplicateChunk(['w1']);
      controller.splitSegmentAtTime(1.0);
      controller.toggleSegmentDeleted(1.0);
      controller.resetSegments();
      controller.applySegments([]);
      
      expect(controller.state.project, isNull);
    });

    test('History boundary limits (undo/redo bounds)', () {
      final project = makeProject(
        words: [makeWord(wordId: 'w1', text: 'test')],
      );
      controller.setProject(project);

      // Initial state has index 0
      expect(controller.state.hasUnsavedChanges, isFalse);
      
      // Undo when no previous history
      controller.undo();
      expect(controller.state.hasUnsavedChanges, isFalse);

      // Make a change
      controller.updateWord('w1', text: 'changed');
      expect(controller.state.hasUnsavedChanges, isTrue);

      // Redo when at the newest state
      controller.redo();
      expect(controller.state.project!.words[0].text, 'changed');

      // Undo back to original
      controller.undo();
      expect(controller.state.project!.words[0].text, 'test');

      // Undo once more at the bottom of the stack
      controller.undo();
      expect(controller.state.project!.words[0].text, 'test');
    });

    test('Segment splitting boundaries (exact and out-of-bounds times)', () {
      final project = makeProject(
        duration: 10.0,
      );
      // Give it one initial segment: 0.0 to 10.0
      project.segments = [
        VideoSegmentSchema()
          ..start = 0.0
          ..end = 10.0
          ..isDeleted = false,
      ];
      controller.setProject(project);

      // 1. Split out-of-bounds (negative time)
      controller.splitSegmentAtTime(-1.0);
      expect(controller.state.project!.segments!.length, 1);

      // 2. Split out-of-bounds (time > duration)
      controller.splitSegmentAtTime(11.0);
      expect(controller.state.project!.segments!.length, 1);

      // 3. Split exactly at boundary: start (0.0)
      controller.splitSegmentAtTime(0.0);
      expect(controller.state.project!.segments!.length, 1);

      // 4. Split exactly at boundary: end (10.0)
      controller.splitSegmentAtTime(10.0);
      expect(controller.state.project!.segments!.length, 1);

      // 5. Valid split in the middle (5.0)
      controller.splitSegmentAtTime(5.0);
      expect(controller.state.project!.segments!.length, 2);
      expect(controller.state.project!.segments![0].start, 0.0);
      expect(controller.state.project!.segments![0].end, 5.0);
      expect(controller.state.project!.segments![1].start, 5.0);
      expect(controller.state.project!.segments![1].end, 10.0);
    });

    test('Segment deletion toggle boundary (out-of-bounds time)', () {
      final project = makeProject(
        duration: 10.0,
      );
      project.segments = [
        VideoSegmentSchema()
          ..start = 0.0
          ..end = 10.0
          ..isDeleted = false,
      ];
      controller.setProject(project);

      // Toggle at out-of-bounds time (-0.5)
      controller.toggleSegmentDeleted(-0.5);
      expect(controller.state.project!.segments![0].isDeleted, isFalse);

      // Toggle at valid time (2.0)
      controller.toggleSegmentDeleted(2.0);
      expect(controller.state.project!.segments![0].isDeleted, isTrue);
    });

    test('deleteWords with empty list and invalid IDs', () {
      final project = makeProject(
        words: [
          makeWord(wordId: 'w1', text: 'Hello'),
          makeWord(wordId: 'w2', text: 'World'),
        ],
      );
      controller.setProject(project);

      // Delete empty list
      controller.deleteWords([]);
      expect(controller.state.project!.words.length, 2);

      // Delete non-existent IDs
      controller.deleteWords(['invalid_id']);
      expect(controller.state.project!.words.length, 2);

      // Delete valid ID
      controller.deleteWords(['w1']);
      expect(controller.state.project!.words.length, 1);
      expect(controller.state.project!.words[0].wordId, 'w2');
    });

    test('duplicateChunk with empty list and invalid IDs', () {
      final project = makeProject(
        words: [
          makeWord(wordId: 'w1', text: 'Hello', start: 0.0, end: 1.0),
        ],
      );
      controller.setProject(project);

      // Duplicate empty list
      controller.duplicateChunk([]);
      expect(controller.state.project!.words.length, 1);

      // Duplicate invalid IDs
      controller.duplicateChunk(['invalid_id']);
      expect(controller.state.project!.words.length, 1);
    });

    test('Long undo/redo chain consistency', () {
      final project = makeProject(
        words: [makeWord(wordId: 'w1', text: 'initial')],
      );
      controller.setProject(project);

      // Perform 5 updates
      controller.updateWord('w1', text: 'update1');
      controller.updateWord('w1', text: 'update2');
      controller.updateWord('w1', text: 'update3');
      controller.updateWord('w1', text: 'update4');
      controller.updateWord('w1', text: 'update5');
      expect(controller.state.project!.words[0].text, equals('update5'));

      // Undo 3 times -> should go back to update2
      controller.undo();
      controller.undo();
      controller.undo();
      expect(controller.state.project!.words[0].text, equals('update2'));

      // Redo 2 times -> should go to update4
      controller.redo();
      controller.redo();
      expect(controller.state.project!.words[0].text, equals('update4'));

      // Undo 4 times -> should go back to initial
      controller.undo();
      controller.undo();
      controller.undo();
      controller.undo();
      expect(controller.state.project!.words[0].text, equals('initial'));
    });

    test('Trimming bounds limits validation (start >= end returns early)', () {
      final project = makeProject(trimStart: 1.0, trimEnd: 5.0);
      controller.setProject(project);

      // 1. Equal: 2.0 and 2.0
      controller.setTrim(2.0, 2.0);
      expect(controller.state.project!.trimStart, equals(1.0)); // unchanged
      expect(controller.state.project!.trimEnd, equals(5.0));   // unchanged

      // 2. Start > End: 4.0 and 2.0
      controller.setTrim(4.0, 2.0);
      expect(controller.state.project!.trimStart, equals(1.0));
      expect(controller.state.project!.trimEnd, equals(5.0));

      // 3. Valid update: 2.0 and 4.0
      controller.setTrim(2.0, 4.0);
      expect(controller.state.project!.trimStart, equals(2.0));
      expect(controller.state.project!.trimEnd, equals(4.0));
    });

    test('Batch update multiple words concurrently', () {
      final words = List.generate(20, (i) => makeWord(wordId: 'w$i', text: 'word $i'));
      final project = makeProject(words: words);
      controller.setProject(project);

      // Batch update all 20 words
      final ids = List.generate(20, (i) => 'w$i');
      controller.batchUpdateWords(ids, hidden: true, className: 'highlight');

      for (int i = 0; i < 20; i++) {
        expect(controller.state.project!.words[i].hidden, isTrue);
        expect(controller.state.project!.words[i].className, equals('highlight'));
      }
    });

    test('Batch update handles duplicate IDs gracefully', () {
      final project = makeProject(
        words: [
          makeWord(wordId: 'w1', text: 'one'),
          makeWord(wordId: 'w2', text: 'two'),
        ],
      );
      controller.setProject(project);

      // Passing duplicate IDs in list
      controller.batchUpdateWords(['w1', 'w1', 'w2', 'w2'], hidden: true);
      expect(controller.state.project!.words[0].hidden, isTrue);
      expect(controller.state.project!.words[1].hidden, isTrue);
    });

    test('Edge case: delete the very first word in the list', () {
      final project = makeProject(
        words: [
          makeWord(wordId: 'w1', text: 'first'),
          makeWord(wordId: 'w2', text: 'second'),
          makeWord(wordId: 'w3', text: 'third'),
        ],
      );
      controller.setProject(project);

      controller.deleteWords(['w1']);
      expect(controller.state.project!.words.length, equals(2));
      expect(controller.state.project!.words[0].wordId, equals('w2'));
    });

    test('Edge case: delete the very last word in the list', () {
      final project = makeProject(
        words: [
          makeWord(wordId: 'w1', text: 'first'),
          makeWord(wordId: 'w2', text: 'second'),
          makeWord(wordId: 'w3', text: 'third'),
        ],
      );
      controller.setProject(project);

      controller.deleteWords(['w3']);
      expect(controller.state.project!.words.length, equals(2));
      expect(controller.state.project!.words[1].wordId, equals('w2'));
    });

    test('Edge case: delete all words in the list', () {
      final project = makeProject(
        words: [
          makeWord(wordId: 'w1', text: 'first'),
          makeWord(wordId: 'w2', text: 'second'),
        ],
      );
      controller.setProject(project);

      controller.deleteWords(['w1', 'w2']);
      expect(controller.state.project!.words, isEmpty);
    });

    test('splitChunkAtWord on first word in list', () {
      final project = makeProject(
        words: [
          makeWord(wordId: 'w1', text: 'first'),
          makeWord(wordId: 'w2', text: 'second'),
        ],
      );
      controller.setProject(project);

      controller.splitChunkAtWord('w1');
      expect(controller.state.project!.words[0].splitBefore, isTrue);
    });

    test('splitChunkAtWord on last word in list', () {
      final project = makeProject(
        words: [
          makeWord(wordId: 'w1', text: 'first'),
          makeWord(wordId: 'w2', text: 'second'),
        ],
      );
      controller.setProject(project);

      controller.splitChunkAtWord('w2');
      expect(controller.state.project!.words[1].splitBefore, isTrue);
    });

    test('addWordAfter on a word that does not exist does not insert', () {
      final project = makeProject(
        words: [
          makeWord(wordId: 'w1', text: 'first'),
        ],
      );
      controller.setProject(project);

      controller.addWordAfter('non_existent_id');
      expect(controller.state.project!.words.length, equals(1));
      expect(controller.state.project!.words[0].wordId, equals('w1'));
    });

    test('addChunkAfter on a word that does not exist does not insert', () {
      final project = makeProject(
        words: [
          makeWord(wordId: 'w1', text: 'first'),
        ],
      );
      controller.setProject(project);

      controller.addChunkAfter('non_existent_id');
      expect(controller.state.project!.words.length, equals(1));
      expect(controller.state.project!.words[0].wordId, equals('w1'));
    });

    test('applySegments updates project segments, increments revision, and records history', () {
      final project = makeProject(duration: 20.0);
      project.segments = [
        VideoSegmentSchema()
          ..start = 0.0
          ..end = 20.0
          ..isDeleted = false,
      ];
      controller.setProject(project);
      expect(controller.state.project!.segments!.length, 1);

      final newSegments = [
        VideoSegmentSchema()
          ..start = 0.0
          ..end = 5.0
          ..isDeleted = false,
        VideoSegmentSchema()
          ..start = 8.0
          ..end = 15.0
          ..isDeleted = false,
      ];

      final revBefore = controller.state.revision;
      controller.applySegments(newSegments);

      expect(controller.state.project!.segments!.length, 2);
      expect(controller.state.project!.segments![0].start, 0.0);
      expect(controller.state.project!.segments![0].end, 5.0);
      expect(controller.state.project!.segments![1].start, 8.0);
      expect(controller.state.project!.segments![1].end, 15.0);
      expect(controller.state.hasUnsavedChanges, isTrue);
      expect(controller.state.revision, equals(revBefore + 1));

      // Test undo restores previous segments
      controller.undo();
      expect(controller.state.project!.segments!.length, 1);
      expect(controller.state.project!.segments![0].end, 20.0);

      // Test redo applies new segments again
      controller.redo();
      expect(controller.state.project!.segments!.length, 2);
      expect(controller.state.project!.segments![1].end, 15.0);
    });
  });
}
