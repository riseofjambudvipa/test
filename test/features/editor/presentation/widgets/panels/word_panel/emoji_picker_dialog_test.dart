import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/assets/asset_manifest.dart';
import 'package:capstudio/core/assets/asset_verification_service.dart';
import 'package:capstudio/features/editor/domain/caption_engine.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/word_panel/emoji_picker_dialog.dart';
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
  const smileys = [
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
    EmojiMeta(
      unicode: '1f436', glyph: '🐶', name: 'dog face',
      group: 'animals & nature', unicodeVersion: '6.0',
      keywords: ['dog', 'pet'], shortcodes: [':dog:'],
      styles: {'notoColorEmoji': '1f436.png'},
    ),
  ];
  return AssetManifest(
    version: 'test',
    packs: const [],
    emojis: smileys,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpPicker(
    WidgetTester tester, {
    void Function(String pack, String glyph)? onSelected,
    String? initialPack,
  }) async {
    final project = makeProject();
    final chunk = const Chunk(index: 0, startTime: 0, endTime: 1, words: []);

    final selected = <String, String>{};
    await pumpTestWidget(
      tester,
      EmojiPickerDialog(
        project: project,
        chunk: chunk,
        initialPack: initialPack,
        onEmojiSelected: onSelected ??
            (pack, glyph) {
              selected['pack'] = pack;
              selected['glyph'] = glyph;
            },
      ),
      overrides: [
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
  }

  group('EmojiPickerDialog', () {
    testWidgets('renders title, search field and style-pack selector', (tester) async {
      await pumpPicker(tester);

      expect(find.text('SELECT EMOJI'), findsOneWidget);
      expect(find.text('STYLE PACK'), findsOneWidget);
      expect(find.text('Search...'), findsOneWidget);
      // Default pack for legacy 'googleAnimated' projects is notoColorEmoji.
      expect(find.text('Noto Color Emoji (Fallback)'), findsOneWidget);
    });

    testWidgets('shows Recent/Favorites categories with empty state first', (tester) async {
      await pumpPicker(tester);

      // Recent is the default category and starts empty.
      expect(find.text('No emojis found.'), findsOneWidget);
      expect(find.text('RECENT'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('switching to a category shows its emojis', (tester) async {
      await pumpPicker(tester);

      // Tap the Smileys category chip (label is the emoji icon).
      final smileysChip = find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.text('😀'),
      );
      await tester.tap(smileysChip);
      await tester.pumpAndSettle();

      expect(find.text('SMILEYS'), findsOneWidget);
      expect(find.text('😀'), findsWidgets); // chip icon + grid tiles
      expect(find.text('😂'), findsOneWidget);
    });

    testWidgets('tapping an emoji invokes onEmojiSelected with pack and glyph', (tester) async {
      String? selectedPack;
      String? selectedGlyph;
      await pumpPicker(tester, onSelected: (pack, glyph) {
        selectedPack = pack;
        selectedGlyph = glyph;
      });

      final smileysChip = find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.text('😀'),
      );
      await tester.tap(smileysChip);
      await tester.pumpAndSettle();

      // Tap the dog emoji tile in the grid.
      await tester.tap(find.text('😂'));
      await tester.pump();

      expect(selectedPack, 'notoColorEmoji');
      expect(selectedGlyph, '😂');
    });

    testWidgets('search filters emojis by keyword', (tester) async {
      await pumpPicker(tester);

      await tester.enterText(find.byType(TextField).first, 'dog');
      // Debounce is 150ms.
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      expect(find.text('🐶'), findsOneWidget);
      expect(find.text('😂'), findsNothing);
    });

    testWidgets('favoriting an emoji persists to SharedPreferences', (tester) async {
      await pumpPicker(tester);

      final smileysChip = find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.text('😀'),
      );
      await tester.tap(smileysChip);
      await tester.pumpAndSettle();

      // Favorite star starts unfilled; tap it.
      final star = find.byIcon(Icons.star_outline_rounded);
      expect(star, findsWidgets);
      await tester.tap(star.first);
      await tester.pump();

      expect(find.byIcon(Icons.star_rounded), findsWidgets);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('emoji_favorites'), contains('😀'));
    });

    testWidgets('selecting an emoji records it in recents', (tester) async {
      await pumpPicker(tester);

      final smileysChip = find.descendant(
        of: find.byType(ChoiceChip),
        matching: find.text('😀'),
      );
      await tester.tap(smileysChip);
      await tester.pumpAndSettle();

      await tester.tap(find.text('😂'));
      await tester.pump();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getStringList('emoji_recent'), contains('😂'));
    });

    testWidgets('locked packs show a lock suffix in the pack menu', (tester) async {
      await pumpPicker(tester);

      // Open the style-pack dropdown.
      await tester.tap(find.byTooltip('Select Style Pack'));
      await tester.pumpAndSettle();

      // googleAnimated is not installed → disabled with a lock.
      expect(find.textContaining('🔒'), findsWidgets);
      // notoColorEmoji is always available.
      expect(find.text('Noto Color Emoji (Fallback)'), findsWidgets);
    });
  });
}
