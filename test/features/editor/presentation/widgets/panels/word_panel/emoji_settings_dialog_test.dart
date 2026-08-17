import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/assets/asset_manifest.dart';
import 'package:capstudio/core/assets/asset_verification_service.dart';
import 'package:capstudio/features/editor/domain/caption_engine.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/word_panel/emoji_settings_dialog.dart';
import '../../../../../../helpers/project_fixture.dart';
import '../../../../../../helpers/widget_helpers.dart';

class FakeAssetVerificationNotifier extends AssetVerificationNotifier {
  FakeAssetVerificationNotifier(super.state);

  @override
  Future<void> reVerify() async {
    // No-op — the fake state is authoritative.
  }
}

AssetManifest buildManifest() {
  const emojis = [
    EmojiMeta(
      unicode: '1f600', glyph: '😀', name: 'grinning face',
      group: 'smileys & emotion', unicodeVersion: '6.1',
      keywords: ['smile', 'happy'], shortcodes: [':grinning:'],
      styles: {'notoColorEmoji': '1f600.png'},
    ),
    EmojiMeta(
      unicode: '1f602', glyph: '😂', name: 'face with tears of joy',
      group: 'smileys & emotion', unicodeVersion: '6.0',
      keywords: ['joy', 'laugh'], shortcodes: [':joy:'],
      styles: {'notoColorEmoji': '1f602.png'},
    ),
    EmojiMeta(
      unicode: '1f44d', glyph: '👍', name: 'thumbs up',
      group: 'people & body', unicodeVersion: '6.0',
      keywords: ['thumb', 'up', 'approve'], shortcodes: [':+1:'],
      styles: {'notoColorEmoji': '1f44d.png'},
    ),
  ];
  return AssetManifest(
    version: 'test',
    packs: const [],
    emojis: emojis,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Opens the settings dialog through a real showDialog route so its
  // dispose-lifecycle (dispose schedules a restore microtask on the editor
  // controller) matches production instead of fighting test teardown.
  Future<void> openSettings(WidgetTester tester) async {
    final project = makeProject();
    final chunk = const Chunk(index: 0, startTime: 0, endTime: 1, words: []);
    final word = makeWord(wordId: 'word_1', emoji: 'notoColorEmoji:😀');

    await pumpTestWidget(
      tester,
      Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            onPressed: () {
              showDialog<void>(
                context: context,
                builder: (_) => EmojiSettingsDialog(
                  word: word,
                  project: project,
                  chunk: chunk,
                ),
              );
            },
            child: const Text('open settings'),
          ),
        ),
      ),
      overrides: [
        editorProvider.overrideWith((ref) => EditorController(ref)),
        assetManifestProvider.overrideWithValue(buildManifest()),
        assetVerificationProvider.overrideWith(
          (ref) => FakeAssetVerificationNotifier(
            const AssetVerificationResult(
              allRequiredPresent: true,
              missing: [],
              installedPackIds: ['notoColorEmoji'],
              hasAnyEmojis: true,
            ),
          ),
        ),
      ],
    );

    await tester.tap(find.text('open settings'));
    await tester.pumpAndSettle();
  }

  // Closes the dialog so its dispose-restore microtask runs while the editor
  // controller is still alive (matching production lifecycle), not during
  // test teardown after the scope disposed the controller.
  Future<void> closeDialog(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
  }

  group('EmojiSettingsDialog', () {
    testWidgets('renders title and the current emoji', (tester) async {
      await openSettings(tester);

      expect(find.text('EMOJI SETTINGS'), findsOneWidget);
      // Current emoji glyph from the word's emoji value.
      expect(find.text('😀'), findsOneWidget);
      expect(find.text('Search Emojis...'), findsOneWidget);

      await closeDialog(tester);
    });

    testWidgets('shows position and scale sliders', (tester) async {
      await openSettings(tester);

      expect(find.textContaining('X Offset'), findsOneWidget);
      expect(find.textContaining('Y Offset'), findsOneWidget);
      expect(find.byType(Slider), findsWidgets);

      await closeDialog(tester);
    });

    testWidgets('search field filters emojis from the manifest', (tester) async {
      await openSettings(tester);

      await tester.enterText(find.byType(TextField).first, 'thumbs');
      // Debounce is 150ms.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('👍'), findsOneWidget);
      expect(find.text('😂'), findsNothing);

      await closeDialog(tester);
    });

    testWidgets('close button pops the dialog', (tester) async {
      await openSettings(tester);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text('EMOJI SETTINGS'), findsNothing);
    });

    testWidgets('remove-emoji button clears the emoji via the editor controller', (tester) async {
      await openSettings(tester);

      // Red clear button is present because a current emoji is set.
      final clearButton = find.byIcon(Icons.clear);
      expect(clearButton, findsOneWidget);

      await tester.tap(clearButton);
      await tester.pumpAndSettle();

      // Dialog closes after removal.
      expect(find.text('EMOJI SETTINGS'), findsNothing);
    });
  });
}
