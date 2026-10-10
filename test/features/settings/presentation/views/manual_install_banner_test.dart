import 'package:capstudio/core/downloader/binary_download_models.dart';
import 'package:capstudio/features/settings/presentation/views/manual_install_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/widget_helpers.dart';

void main() {
  testWidgets('ManualInstallBanner renders steps, platform, and copy action', (tester) async {
    final exception = ManualInstallRequiredException(
      platform: 'Linux x64',
      toolId: 'whisper',
      steps: const [
        ManualInstallStep(
          title: 'Install package using APT',
          command: 'sudo apt update && sudo apt install whisper-cli',
        ),
        ManualInstallStep(
          title: 'Verify whisper installation',
          command: 'whisper-cli --version',
        ),
      ],
    );

    await pumpTestWidget(
      tester,
      ManualInstallBanner(exception: exception),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manual Action Required'), findsOneWidget);
    expect(find.textContaining('Linux x64'), findsOneWidget);
    expect(find.text('Install package using APT'), findsOneWidget);
    expect(find.text('sudo apt update && sudo apt install whisper-cli'), findsOneWidget);
    expect(find.text('Verify whisper installation'), findsOneWidget);
    expect(find.text('whisper-cli --version'), findsOneWidget);

    // Tap copy button on the first step command
    final copyIcons = find.byIcon(Icons.copy_rounded);
    expect(copyIcons, findsNWidgets(2));
    await tester.tap(copyIcons.first);
    await tester.pump();
  });
}
