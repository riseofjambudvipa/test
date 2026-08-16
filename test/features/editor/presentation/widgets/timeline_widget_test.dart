import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:capstudio/features/editor/presentation/widgets/timeline_widget.dart';
import 'package:capstudio/features/editor/presentation/widgets/timeline_painter.dart';
import 'package:capstudio/core/database/schemas/word.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_state.dart';
import '../../../../mocks/mocks.dart';
import '../../../../helpers/project_fixture.dart';
import '../../../../test_environment.dart';

void main() {
  registerTestEnvironment(silenceLogs: true);

  testWidgets('TimelineWidget should render layout and zoom buttons', (WidgetTester tester) async {
    final List<WordSchema> mockWords = [
      WordSchema()
        ..wordId = 'w1'
        ..text = 'Hello'
        ..start = 0.0
        ..end = 1.0
        ..type = 'word',
    ];

    // Build the TimelineWidget wrapped in MaterialApp and ProviderScope
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: TimelineWidget(
                words: mockWords,
                currentTime: 0.5,
                duration: 10.0,
                trimStart: 0.0,
                trimEnd: 10.0,
              ),
            ),
          ),
        ),
      ),
    );

    // Verify time indicators and zoom texts are rendered
    expect(find.text('0.500s / 10.000s (Active: 10.000s)'), findsOneWidget);
    expect(find.text('Zoom: 3.0x'), findsOneWidget);

    // Find fit screen button
    expect(find.byIcon(Icons.fit_screen), findsOneWidget);
  });

  testWidgets('TimelineWidget tap on word with null wordId should not crash', (WidgetTester tester) async {
    final List<WordSchema> mockWords = [
      WordSchema()
        ..wordId = null
        ..text = 'Hello'
        ..start = 0.0
        ..end = 1.0
        ..type = 'word',
    ];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: TimelineWidget(
                words: mockWords,
                currentTime: 0.5,
                duration: 10.0,
                trimStart: 0.0,
                trimEnd: 10.0,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(TimelineWidget), findsOneWidget);

    final customPaintFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is TimelinePainter,
    );
    expect(customPaintFinder, findsOneWidget);

    await tester.tap(customPaintFinder);
    await tester.pump();
  });

  testWidgets('TimelineWidget Zoom to Fit changes scale', (WidgetTester tester) async {
    final List<WordSchema> mockWords = [];

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: TimelineWidget(
                words: mockWords,
                currentTime: 0.5,
                duration: 10.0,
                trimStart: 0.0,
                trimEnd: 10.0,
              ),
            ),
          ),
        ),
      ),
    );

    // Initial Zoom is 3.0x (300 px/s)
    expect(find.text('Zoom: 3.0x'), findsOneWidget);

    // Click fit screen button
    await tester.tap(find.byIcon(Icons.fit_screen));
    await tester.pumpAndSettle();

    // Verify Zoom has changed (1280 width / 10s duration = 128 px/s -> Zoom: 1.3x or similar)
    expect(find.text('Zoom: 3.0x'), findsNothing);
  });

  testWidgets('TimelineWidget action buttons trigger correct EditorController calls', (WidgetTester tester) async {
    final mockEditorController = MockEditorController();
    final project = makeProject(
      projectId: 'p_test',
      duration: 10.0,
    );
    
    when(() => mockEditorController.addListener(any(), fireImmediately: any(named: 'fireImmediately')))
        .thenAnswer((invocation) {
          final listener = invocation.positionalArguments[0] as void Function(EditorState);
          listener(EditorState(project: project));
          return () {};
        });
    when(() => mockEditorController.state).thenReturn(EditorState(project: project));
    when(() => mockEditorController.splitSegmentAtTime(any())).thenReturn(null);
    when(() => mockEditorController.toggleSegmentDeleted(any())).thenReturn(null);
    when(() => mockEditorController.resetSegments()).thenReturn(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorProvider.overrideWith((ref) => mockEditorController),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: TimelineWidget(
                words: [],
                currentTime: 5.0,
                duration: 10.0,
                trimStart: 1.0,
                trimEnd: 9.0,
              ),
            ),
          ),
        ),
      ),
    );

    // 1. Test Split Clip button
    await tester.tap(find.text('Split clip'));
    await tester.pump();
    verify(() => mockEditorController.splitSegmentAtTime(5.0)).called(1);

    // 2. Test Remove Clip button
    await tester.tap(find.text('Remove clip'));
    await tester.pump();
    verify(() => mockEditorController.toggleSegmentDeleted(5.0)).called(1);

    // 3. Test Reset to original button
    await tester.tap(find.text('Reset to original'));
    await tester.pump();
    verify(() => mockEditorController.resetSegments()).called(1);
  });

  testWidgets('TimelineWidget Zoom In button increases zoom scale', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: TimelineWidget(
                words: [],
                currentTime: 0.5,
                duration: 10.0,
                trimStart: 0.0,
                trimEnd: 10.0,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Zoom: 3.0x'), findsOneWidget);

    final zoomInBtn = find.byTooltip('Zoom In');
    expect(zoomInBtn, findsOneWidget);
    await tester.tap(zoomInBtn);
    await tester.pump();

    expect(find.text('Zoom: 3.5x'), findsOneWidget);
  });

  testWidgets('TimelineWidget Zoom Out button decreases zoom scale', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: TimelineWidget(
                words: [],
                currentTime: 0.5,
                duration: 10.0,
                trimStart: 0.0,
                trimEnd: 10.0,
              ),
            ),
          ),
        ),
      ),
    );

    final zoomOutBtn = find.byTooltip('Zoom Out');
    expect(zoomOutBtn, findsOneWidget);
    await tester.tap(zoomOutBtn);
    await tester.pump();

    expect(find.text('Zoom: 2.5x'), findsOneWidget);
  });

  testWidgets('TimelineWidget Zoom In clamps at 10.0x maximum zoom', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: TimelineWidget(
                words: [],
                currentTime: 0.5,
                duration: 10.0,
                trimStart: 0.0,
                trimEnd: 10.0,
              ),
            ),
          ),
        ),
      ),
    );

    final zoomInBtn = find.byTooltip('Zoom In');
    for (int i = 0; i < 20; i++) {
      await tester.tap(zoomInBtn);
    }
    await tester.pump();

    expect(find.text('Zoom: 10.0x'), findsOneWidget);
  });

  testWidgets('TimelineWidget Zoom Out clamps at 0.5x minimum zoom', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: TimelineWidget(
                words: [],
                currentTime: 0.5,
                duration: 10.0,
                trimStart: 0.0,
                trimEnd: 10.0,
              ),
            ),
          ),
        ),
      ),
    );

    final zoomOutBtn = find.byTooltip('Zoom Out');
    for (int i = 0; i < 10; i++) {
      await tester.tap(zoomOutBtn);
    }
    await tester.pump();

    expect(find.text('Zoom: 0.5x'), findsOneWidget);
  });

  testWidgets('TimelineWidget single tap on ruler seeks playback time', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockEditorController = MockEditorController();
    final project = makeProject(
      projectId: 'p_test',
      duration: 10.0,
    );

    when(() => mockEditorController.addListener(any(), fireImmediately: any(named: 'fireImmediately')))
        .thenAnswer((invocation) {
          final listener = invocation.positionalArguments[0] as void Function(EditorState);
          listener(EditorState(project: project));
          return () {};
        });
    when(() => mockEditorController.state).thenReturn(EditorState(project: project));
    when(() => mockEditorController.setCurrentTime(any())).thenReturn(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorProvider.overrideWith((ref) => mockEditorController),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              width: 1000,
              child: TimelineWidget(
                words: [],
                currentTime: 0.5,
                duration: 10.0,
                trimStart: 0.0,
                trimEnd: 10.0,
              ),
            ),
          ),
        ),
      ),
    );

    final paintFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is TimelinePainter,
    );
    expect(paintFinder, findsOneWidget);

    final paintTopLeft = tester.getTopLeft(paintFinder);
    await tester.tapAt(paintTopLeft.translate(500.0, 40.0));
    await tester.pump();

    verify(() => mockEditorController.setCurrentTime(any())).called(1);
  });

  testWidgets('TimelineWidget drag on playhead seeks playback time', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockEditorController = MockEditorController();
    final project = makeProject(
      projectId: 'p_test',
      duration: 10.0,
    );

    when(() => mockEditorController.addListener(any(), fireImmediately: any(named: 'fireImmediately')))
        .thenAnswer((invocation) {
          final listener = invocation.positionalArguments[0] as void Function(EditorState);
          listener(EditorState(project: project));
          return () {};
        });
    when(() => mockEditorController.state).thenReturn(EditorState(project: project));
    when(() => mockEditorController.setCurrentTime(any())).thenReturn(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorProvider.overrideWith((ref) => mockEditorController),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              width: 1000,
              child: TimelineWidget(
                words: [],
                currentTime: 0.5,
                duration: 10.0,
                trimStart: 0.0,
                trimEnd: 10.0,
              ),
            ),
          ),
        ),
      ),
    );

    final paintFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is TimelinePainter,
    );
    final paintTopLeft = tester.getTopLeft(paintFinder);
    final rulerCenter = paintTopLeft.translate(500.0, 40.0);

    await tester.dragFrom(rulerCenter, const Offset(100.0, 0.0));
    await tester.pump();

    verify(() => mockEditorController.setCurrentTime(any())).called(greaterThanOrEqualTo(1));
  });

  testWidgets('TimelineWidget drag on start trim handle updates trim start time', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockEditorController = MockEditorController();
    final project = makeProject(
      projectId: 'p_test',
      duration: 3.0,
    );

    when(() => mockEditorController.addListener(any(), fireImmediately: any(named: 'fireImmediately')))
        .thenAnswer((invocation) {
          final listener = invocation.positionalArguments[0] as void Function(EditorState);
          listener(EditorState(project: project));
          return () {};
        });
    when(() => mockEditorController.state).thenReturn(EditorState(project: project));
    when(() => mockEditorController.setTrim(any(), any())).thenReturn(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorProvider.overrideWith((ref) => mockEditorController),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              width: 1000,
              child: TimelineWidget(
                words: [],
                currentTime: 0.5,
                duration: 3.0,
                trimStart: 0.5,
                trimEnd: 2.5,
              ),
            ),
          ),
        ),
      ),
    );

    final paintFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is TimelinePainter,
    );
    final paintTopLeft = tester.getTopLeft(paintFinder);
    
    // Account for Flutter's 20-pixel drag touch slope: start 20px before handle so it triggers exactly at 150.
    await tester.dragFrom(paintTopLeft.translate(130, 40), const Offset(70.0, 0.0));
    await tester.pump();

    verify(() => mockEditorController.setTrim(any(), any())).called(greaterThanOrEqualTo(1));
  });

  testWidgets('TimelineWidget drag on end trim handle updates trim end time', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockEditorController = MockEditorController();
    final project = makeProject(
      projectId: 'p_test',
      duration: 3.0,
    );

    when(() => mockEditorController.addListener(any(), fireImmediately: any(named: 'fireImmediately')))
        .thenAnswer((invocation) {
          final listener = invocation.positionalArguments[0] as void Function(EditorState);
          listener(EditorState(project: project));
          return () {};
        });
    when(() => mockEditorController.state).thenReturn(EditorState(project: project));
    when(() => mockEditorController.setTrim(any(), any())).thenReturn(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          editorProvider.overrideWith((ref) => mockEditorController),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              width: 1000,
              child: TimelineWidget(
                words: [],
                currentTime: 0.5,
                duration: 3.0,
                trimStart: 0.5,
                trimEnd: 2.5,
              ),
            ),
          ),
        ),
      ),
    );

    final paintFinder = find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is TimelinePainter,
    );
    final paintTopLeft = tester.getTopLeft(paintFinder);
    
    // Account for Flutter's 20-pixel drag touch slope: start 20px after handle so it triggers exactly at 750.
    await tester.dragFrom(paintTopLeft.translate(770, 40), const Offset(-70.0, 0.0));
    await tester.pump();

    verify(() => mockEditorController.setTrim(any(), any())).called(greaterThanOrEqualTo(1));
  });
}
