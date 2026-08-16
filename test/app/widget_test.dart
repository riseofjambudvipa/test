import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/main.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import 'package:capstudio/core/assets/asset_path_service.dart';
import 'package:capstudio/core/assets/asset_manifest.dart';
import 'package:capstudio/core/assets/asset_verification_service.dart';
import 'package:capstudio/core/settings/settings_service.dart';

void main() {
  testWidgets('App should boot and render title placeholder', (WidgetTester tester) async {
    // Initialize mock SharedPreferences values to prevent platform channel hang
    SharedPreferences.setMockInitialValues({});
    
    // Create a temporary directory for tests to prevent locking production database
    final tempDir = Directory.systemTemp.createTempSync('capstudio_test_');
    AppDirs.setSupportPathForTesting(tempDir.path);
    addTearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    // Run real OS asynchronous service initializations inside tester.runAsync
    // to prevent FakeAsync event loop deadlocks in headless tests.
    AppDirs.setHasAvx(true);
    await tester.runAsync(() async {
      await AppDirs.init();
      await AssetPathService.instance.init();
      await SettingsService.instance.init();
    });

    final mockManifest = AssetManifest(version: '2.0', packs: [], emojis: []);
    const mockVerification = AssetVerificationResult(
      allRequiredPresent: true,
      missing: [],
      installedPackIds: [],
      hasAnyEmojis: true,
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assetManifestProvider.overrideWithValue(mockManifest),
          assetVerificationProvider.overrideWith((ref) => AssetVerificationNotifier(mockVerification)),
        ],
        child: const CapStudioApp(),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    // Verify that the onboarding screen welcome headers exist in the widget tree
    expect(find.text('Welcome to CapStudio'), findsOneWidget);
    expect(find.text('100% Offline Local AI Caption Editor'), findsOneWidget);
  });
}
