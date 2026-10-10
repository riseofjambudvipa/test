import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/style_panel/plugins_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestWidget() {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (innerContext) {
              return ElevatedButton(
                onPressed: () => PluginsDialog.show(innerContext),
                child: const Text('OPEN PLUGINS'),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('PluginsDialog renders bundled packages and tag chips', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    // Tap to open dialog
    await tester.tap(find.text('OPEN PLUGINS'));
    await tester.pumpAndSettle();

    expect(find.text('Community Plugins & Creator Packs'), findsOneWidget);
    expect(find.text('IMPORT PLUGIN'), findsOneWidget);

    // Verify bundled creator packs are present
    expect(find.text('Viral Shorts & TikTok Masterpack'), findsOneWidget);
    expect(find.text('Cinema & Documentary Storytelling'), findsOneWidget);
    expect(find.text('Gym & High-Performance Athlete'), findsOneWidget);
    expect(find.text('Tech, AI & SaaS Breakdowns'), findsOneWidget);

    // Verify tag chips
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Shorts'), findsOneWidget);
    expect(find.text('Cinema'), findsOneWidget);
    expect(find.text('Fitness'), findsOneWidget);
    expect(find.text('Tech'), findsOneWidget);
  });

  testWidgets('PluginsDialog filters by tag chip', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pump();

    await tester.tap(find.text('OPEN PLUGINS'));
    await tester.pumpAndSettle();

    // Tap 'Cinema' tag chip
    await tester.tap(find.text('Cinema'));
    await tester.pumpAndSettle();

    expect(find.text('Cinema & Documentary Storytelling'), findsOneWidget);
    expect(find.text('Gym & High-Performance Athlete'), findsNothing);
  });
}
