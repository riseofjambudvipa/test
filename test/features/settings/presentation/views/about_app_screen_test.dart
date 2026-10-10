import 'package:capstudio/features/settings/presentation/views/settings/about_app_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_helpers.dart';

void main() {
  testWidgets('AboutAppScreen renders branding, credit cards, and license launcher', (tester) async {
    await pumpTestWidget(
      tester,
      const AboutAppScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.text('ABOUT CAPSTUDIO'), findsOneWidget);
    expect(find.text('CapStudio'), findsOneWidget);
    expect(find.textContaining('100% Offline, Privacy-First AI Captioning'), findsOneWidget);

    // Verify open-source credits
    expect(find.text('whisper.cpp & OpenAI Whisper'), findsOneWidget);
    expect(find.text('FFmpeg Multimedia Framework'), findsOneWidget);
    expect(find.text('Flutter & Dart SDK'), findsOneWidget);
    expect(find.text('Isar Embedded Database'), findsOneWidget);

    // Verify license button
    final viewLicensesButton = find.widgetWithText(ElevatedButton, 'VIEW ALL PACKAGES LICENSES');
    expect(viewLicensesButton, findsOneWidget);

    await tester.ensureVisible(viewLicensesButton);
    await tester.tap(viewLicensesButton);
    await tester.pumpAndSettle();

    // Verify LicensePage opened with GPL-3.0 legalese
    expect(find.byType(LicensePage), findsOneWidget);
    expect(find.textContaining('Licensed under GPL-3.0'), findsOneWidget);
  });
}
