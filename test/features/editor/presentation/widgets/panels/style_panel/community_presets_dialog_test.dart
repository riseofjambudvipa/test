import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/app/theme.dart';
import 'package:capstudio/features/editor/domain/style_templates.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/style_panel/community_presets_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget({
    required ValueChanged<StyleTemplate> onApplyPreset,
    required VoidCallback onPacksUpdated,
  }) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (ctx) => CommunityPresetsDialog(
                    onApplyPreset: onApplyPreset,
                    onPacksUpdated: onPacksUpdated,
                  ),
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('CommunityPresetsDialog renders search, tags, and packs', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestWidget(
        onApplyPreset: (_) {},
        onPacksUpdated: () {},
      ),
    );

    // Open dialog
    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Verify dialog header
    expect(find.text('COMMUNITY PRESET PACKS'), findsOneWidget);

    // Verify search bar and tag chips
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Podcast'), findsOneWidget);

    // Verify pack cards appear
    expect(find.text('Viral Retention Titans'), findsOneWidget);
  });

  testWidgets('CommunityPresetsDialog filters by tag chip', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestWidget(
        onApplyPreset: (_) {},
        onPacksUpdated: () {},
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Tap Podcast tag
    await tester.tap(find.text('Podcast'));
    await tester.pumpAndSettle();

    // Podcast pack should be visible
    expect(find.text('Thought Leader & Podcast Studio'), findsOneWidget);
    // Gaming pack should be filtered out
    expect(find.text('Gaming & Streamer Hype'), findsNothing);
  });

  testWidgets('CommunityPresetsDialog applies individual preset on tap', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1000, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    StyleTemplate? applied;

    await tester.pumpWidget(
      buildTestWidget(
        onApplyPreset: (template) {
          applied = template;
        },
        onPacksUpdated: () {},
      ),
    );

    await tester.tap(find.text('Open Dialog'));
    await tester.pumpAndSettle();

    // Find and tap a preset chip
    final hormoziPresetFinder = find.text('Hormozi 2.0 Bold');
    expect(hormoziPresetFinder, findsOneWidget);

    await tester.tap(hormoziPresetFinder);
    await tester.pumpAndSettle();

    // Verify preset was applied and dialog dismissed
    expect(applied, isNotNull);
    expect(applied!.name, 'Hormozi 2.0 Bold');
    expect(find.text('COMMUNITY PRESET PACKS'), findsNothing);
  });
}
