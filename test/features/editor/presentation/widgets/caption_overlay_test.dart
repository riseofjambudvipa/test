import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:capstudio/core/database/schemas/project.dart';
import 'package:capstudio/features/editor/domain/caption_engine.dart';
import 'package:capstudio/features/editor/presentation/widgets/caption_overlay.dart';
import 'package:capstudio/core/assets/asset_manifest.dart';
import '../../../../helpers/project_fixture.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/settings/settings_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService.instance.init();
  });

  final ProjectConfigSchema defaultConfig = makeConfig(
    name: 'default',
    animation: 'pop',
    shadow: 'soft',
    stroke: 'none',
    fontFamily: 'Outfit',
    fontWeight: '900',
    textTransform: 'uppercase',
    fontSize: 24.0,
    top: 70.0,
    color: '#ffffff',
    mainColor: '#f97316',
    secondColor: '#06b6d4',
    thirdColor: '#22c55e',
    chunkSize: 2,
    chunkLineMaxLength: 20,
  );

  final mockManifest = AssetManifest(version: '2.0', packs: [], emojis: []);

  testWidgets('CaptionOverlay should detect RTL text and apply RTL direction', (WidgetTester tester) async {
    final List<Chunk> chunks = [
      Chunk(
        index: 0,
        words: [
          makeWord(
            wordId: 'w1',
            text: 'مرحبا',
            start: 0.0,
            end: 1.0,
            type: 'word',
          ),
        ],
        startTime: 0.0,
        endTime: 1.0,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CaptionOverlay(
                  chunks: chunks,
                  currentTime: 0.5,
                  config: defaultConfig,
                  scale: 1.0,
                  videoWidth: 1080,
                  videoHeight: 1920,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    final wrapFinder = find.byType(Wrap);
    expect(wrapFinder, findsOneWidget);
    final Wrap wrapWidget = tester.widget(wrapFinder);
    expect(wrapWidget.textDirection, TextDirection.rtl);
  });

  testWidgets('CaptionOverlay should detect English LTR text and apply LTR direction', (WidgetTester tester) async {
    final List<Chunk> chunks = [
      Chunk(
        index: 0,
        words: [
          makeWord(
            wordId: 'w1',
            text: 'Hello',
            start: 0.0,
            end: 1.0,
            type: 'word',
          ),
        ],
        startTime: 0.0,
        endTime: 1.0,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CaptionOverlay(
                  chunks: chunks,
                  currentTime: 0.5,
                  config: defaultConfig,
                  scale: 1.0,
                  videoWidth: 1080,
                  videoHeight: 1920,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    final wrapFinder = find.byType(Wrap);
    expect(wrapFinder, findsOneWidget);
    final Wrap wrapWidget = tester.widget(wrapFinder);
    expect(wrapWidget.textDirection, TextDirection.ltr);
  });

  testWidgets('CaptionOverlay should render text with active word highlighting matching style config colors', (WidgetTester tester) async {
    final List<Chunk> chunks = [
      Chunk(
        index: 0,
        words: [
          makeWord(
            wordId: 'w1',
            text: 'ActiveWord',
            start: 0.0,
            end: 1.0,
            type: 'word',
          ),
          makeWord(
            wordId: 'w2',
            text: 'InactiveWord',
            start: 1.1,
            end: 2.0,
            type: 'word',
          ),
        ],
        startTime: 0.0,
        endTime: 2.0,
      ),
    ];

    // Current player time is 0.5s -> ActiveWord is active, InactiveWord is inactive
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                CaptionOverlay(
                  chunks: chunks,
                  currentTime: 0.5,
                  config: defaultConfig,
                  scale: 1.0,
                  videoWidth: 1080,
                  videoHeight: 1920,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify ActiveWord text is rendered
    final activeFinder = find.text('ACTIVEWORD');
    expect(activeFinder, findsOneWidget);

    // Verify InactiveWord text is rendered
    final inactiveFinder = find.text('INACTIVEWORD');
    expect(inactiveFinder, findsOneWidget);

    final Text activeText = tester.widget(activeFinder);
    final Text inactiveText = tester.widget(inactiveFinder);

    // Active text should have custom highlight color (#f97316 matches Color(0xfff97316))
    expect(activeText.style!.color, const Color(0xfff97316));

    // Inactive text should have the standard text color (#ffffff matches Color(0xffffffff))
    expect(inactiveText.style!.color, const Color(0xffffffff));
  });
}

