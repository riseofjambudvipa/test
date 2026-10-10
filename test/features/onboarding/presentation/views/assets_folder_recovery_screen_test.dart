import 'package:capstudio/features/onboarding/presentation/views/assets_folder_recovery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_helpers.dart';

void main() {
  testWidgets('AssetsFolderRecoveryScreen renders warning icon, text, and action buttons', (tester) async {
    await pumpTestWidget(
      tester,
      const AssetsFolderRecoveryScreen(),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.text('Assets Folder Not Found'), findsOneWidget);
    expect(find.textContaining('CapStudio could not locate the assets folder'), findsOneWidget);
    expect(find.text('EXPECTED PATH:'), findsOneWidget);
    expect(find.text('Browse New Location'), findsOneWidget);
    expect(find.text('Reset to Default Path'), findsOneWidget);
    expect(find.text('Retry Verification'), findsOneWidget);
  });
}
