import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import '../../../../mocks/mocks.dart';
import '../../../../test_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerTestEnvironment(silenceLogs: true);

  late MockIsarService mockIsar;

  setUpAll(() {
    registerFallbackValue(Project());
  });

  setUp(() {
    mockIsar = MockIsarService();
    when(() => mockIsar.isInitialized).thenReturn(true);
    when(() => mockIsar.saveProject(any())).thenAnswer((_) async {});
    IsarService.instance = mockIsar;
  });

  group('EditorRippleDelete Tests', () {
    test('rippleDeleteAllDeletedSegments collapses deleted gaps and shifts surviving words', () {
      final project = Project()
        ..projectId = 'proj_ripple'
        ..name = 'Ripple Test'
        ..duration = 10.0
        ..trimStart = 0.0
        ..trimEnd = 10.0
        ..segments = [
          VideoSegmentSchema()
            ..start = 0.0
            ..end = 3.0
            ..isDeleted = false,
          VideoSegmentSchema()
            ..start = 3.0
            ..end = 6.0
            ..isDeleted = true, // 3.0 second deleted gap
          VideoSegmentSchema()
            ..start = 6.0
            ..end = 10.0
            ..isDeleted = false,
        ]
        ..words = [
          WordSchema()
            ..wordId = 'w1'
            ..text = 'Start'
            ..start = 0.5
            ..end = 1.5,
          WordSchema()
            ..wordId = 'w2'
            ..text = 'InsideGap'
            ..start = 3.5
            ..end = 5.0,
          WordSchema()
            ..wordId = 'w3'
            ..text = 'AfterGap'
            ..start = 7.0
            ..end = 8.5,
        ];

      final controller = EditorController(MockRef());
      controller.setProject(project);

      // Execute ripple delete
      controller.rippleDeleteAllDeletedSegments();

      final updated = controller.state.project!;

      // Duration should now be 10.0 - 3.0 = 7.0
      expect(updated.duration, equals(7.0));
      expect(updated.trimEnd, equals(7.0));

      // Surviving segments should be 2 continuous segments: [0.0, 3.0] and [3.0, 7.0]
      expect(updated.segments!.length, equals(2));
      expect(updated.segments![0].start, equals(0.0));
      expect(updated.segments![0].end, equals(3.0));
      expect(updated.segments![0].isDeleted, isFalse);

      expect(updated.segments![1].start, equals(3.0));
      expect(updated.segments![1].end, equals(7.0));
      expect(updated.segments![1].isDeleted, isFalse);

      // Words check:
      // 'Start' stays at 0.5 - 1.5
      // 'InsideGap' is removed
      // 'AfterGap' was at 7.0 - 8.5, shifted left by 3.0 -> now 4.0 - 5.5
      expect(updated.words.length, equals(2));
      expect(updated.words[0].text, equals('Start'));
      expect(updated.words[0].start, equals(0.5));
      expect(updated.words[0].end, equals(1.5));

      expect(updated.words[1].text, equals('AfterGap'));
      expect(updated.words[1].start, equals(4.0));
      expect(updated.words[1].end, equals(5.5));
    });

    test('rippleDeleteSegmentAtTime marks and removes single segment immediately', () {
      final project = Project()
        ..projectId = 'proj_ripple_at'
        ..name = 'Ripple At Time Test'
        ..duration = 8.0
        ..trimStart = 0.0
        ..trimEnd = 8.0
        ..segments = [
          VideoSegmentSchema()
            ..start = 0.0
            ..end = 4.0
            ..isDeleted = false,
          VideoSegmentSchema()
            ..start = 4.0
            ..end = 8.0
            ..isDeleted = false,
        ]
        ..words = [];

      final controller = EditorController(MockRef());
      controller.setProject(project);

      // Ripple delete second segment (at time 5.0)
      controller.rippleDeleteSegmentAtTime(5.0);

      final updated = controller.state.project!;
      expect(updated.duration, equals(4.0));
      expect(updated.segments!.length, equals(1));
      expect(updated.segments![0].start, equals(0.0));
      expect(updated.segments![0].end, equals(4.0));
      expect(updated.segments![0].isDeleted, isFalse);
    });
  });
}
