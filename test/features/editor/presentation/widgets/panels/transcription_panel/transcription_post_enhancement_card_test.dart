import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/transcription_panel/transcription_post_enhancement_card.dart';

void main() {
  group('TranscriptionPostEnhancementCard Widget Tests', () {
    testWidgets('renders all enhancement options and offline badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TranscriptionPostEnhancementCard(
              autoApplyEmojis: false,
              autoApplySfx: false,
              onAutoApplyEmojisChanged: (_) {},
              onAutoApplySfxChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('AI POST-PROCESSING'), findsOneWidget);
      expect(find.text('FREE & OFFLINE'), findsOneWidget);
      expect(find.text('Auto-Add Magic Emojis'), findsOneWidget);
      expect(find.text('Auto-Add Magic SFX'), findsOneWidget);
    });

    testWidgets('invokes callbacks when switches are toggled', (tester) async {
      bool emojisToggled = false;
      bool sfxToggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TranscriptionPostEnhancementCard(
                  autoApplyEmojis: emojisToggled,
                  autoApplySfx: sfxToggled,
                  onAutoApplyEmojisChanged: (val) {
                    setState(() => emojisToggled = val);
                  },
                  onAutoApplySfxChanged: (val) {
                    setState(() => sfxToggled = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(2));

      // Toggle Emojis switch
      await tester.tap(switches.first);
      await tester.pumpAndSettle();
      expect(emojisToggled, isTrue);

      // Toggle SFX switch
      await tester.tap(switches.last);
      await tester.pumpAndSettle();
      expect(sfxToggled, isTrue);
    });
  });
}
