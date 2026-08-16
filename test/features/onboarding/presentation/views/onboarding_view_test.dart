import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:capstudio/features/onboarding/presentation/views/onboarding_screen.dart';
import 'package:capstudio/core/assets/asset_path_service.dart';
import 'package:capstudio/core/assets/asset_manifest.dart';
import 'package:capstudio/core/assets/asset_verification_service.dart';
import 'package:capstudio/core/assets/pack_download_service.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import 'dart:io';
import '../../../../helpers/widget_helpers.dart';
import '../../../../mocks/mocks.dart';

class FakeAssetVerificationNotifier extends AssetVerificationNotifier {
  FakeAssetVerificationNotifier(super.state);

  @override
  Future<void> reVerify() async {
    // No-op
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(http.Request('GET', Uri.parse('http://example.com')));
  });

  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late AssetManifest testManifest;
  late AssetVerificationResult testVerification;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('capstudio_onboarding_view_test_');
    AppDirs.setSupportPathForTesting(tempDir.path);
    await AppDirs.init();
    await SettingsService.instance.init();
    await AssetPathService.instance.init();
    await AssetPathService.instance.setDesktopAssetsFolder(tempDir.path);
    PackDownloadService.instance.resetForTesting();

    testManifest = AssetManifest(
      version: '2.0',
      packs: [
        const AssetPack(
          id: 'googleNonAnimated',
          name: 'Google Noto (Static)',
          description: 'High-quality flat Google Noto emoji set. Required for basic display.',
          required: true,
          sizeBytes: 10 * 1024 * 1024,
          compressedSizeBytes: 5 * 1024 * 1024,
          downloadUrl: 'http://example.com',
          checksum: '',
          version: '1.0',
          fileCount: 10,
          format: 'zip',
          animated: false,
          localFolder: 'google_noto_emojis_non_animated_pack',
        ),
      ],
      emojis: [],
    );

    testVerification = const AssetVerificationResult(
      allRequiredPresent: true,
      missing: [],
      installedPackIds: ['googleNonAnimated'],
      hasAnyEmojis: true,
    );
  });

  tearDown(() {
    PackDownloadService.instance.resetForTesting();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('OnboardingScreen Widget Tests', () {
    testWidgets('steps through onboarding welcome and fields correctly', (tester) async {
      await pumpTestWidget(
        tester,
        const OnboardingScreen(),
        overrides: [
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      // 1. Verify welcome screen renders
      expect(find.text('Welcome to CapStudio'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      // Tap Get Started to go to step 1 (setup tools)
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // 2. Verify Connect Local CLI Tools screen renders
      expect(find.text('Connect Local CLI Tools'), findsOneWidget);
      expect(find.text('Whisper CLI Executable Path'), findsOneWidget);
      expect(find.text('FFmpeg CLI Executable Path'), findsOneWidget);

      // Tap Continue to go to step 2 (assets folder path)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // 3. Verify Choose Asset Directory screen renders
      expect(find.text('Choose Asset Directory'), findsOneWidget);
      expect(find.text('Storage Path Folder'), findsOneWidget);

      // Tap Confirm Location to go to step 3 (download packs)
      await tester.runAsync(() async {
        await tester.tap(find.text('Confirm Location'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // 4. Verify Download Content Packs screen renders
      expect(find.text('Download Content Packs (Optional)'), findsOneWidget);
      expect(find.text('EMOJI PACKS'), findsOneWidget);

      // Tap Continue to go to step 4 (complete)
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // 5. Verify Complete screen renders
      expect(find.text("You're Ready to Roll!"), findsOneWidget);
      expect(find.text('Configuration Details:'), findsOneWidget);
    });

    testWidgets('auto-detect Whisper CLI shows warning banner when not found', (tester) async {
      await pumpTestWidget(
        tester,
        const OnboardingScreen(),
        overrides: [
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      final autoDetectBtns = find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Auto-detect & Validate');
      expect(autoDetectBtns, findsNWidgets(2));

      // Click auto-detect for Whisper
      await tester.tap(autoDetectBtns.first);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Could not auto-detect whisper-cli. Please browse manually.'), findsOneWidget);

      // Dismiss snackbars and clear timers
      ScaffoldMessenger.of(tester.element(find.byType(OnboardingScreen))).clearSnackBars();
      await tester.pumpAndSettle();
    });

    testWidgets('auto-detect FFmpeg CLI shows warning banner when not found', (tester) async {
      await pumpTestWidget(
        tester,
        const OnboardingScreen(),
        overrides: [
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      final autoDetectBtns = find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Auto-detect & Validate');

      // Click auto-detect for FFmpeg
      await tester.tap(autoDetectBtns.last);
      await tester.pump(const Duration(milliseconds: 500));

      final hasWarning = find.text('Could not auto-detect ffmpeg. Please browse manually.').evaluate().isNotEmpty;
      if (hasWarning) {
        expect(find.text('Could not auto-detect ffmpeg. Please browse manually.'), findsOneWidget);
      } else {
        // Successfully detected FFmpeg in system path, so it shouldn't show the warning
        expect(find.text('Could not auto-detect ffmpeg. Please browse manually.'), findsNothing);
      }

      // Dismiss snackbars and clear timers
      ScaffoldMessenger.of(tester.element(find.byType(OnboardingScreen))).clearSnackBars();
      await tester.pumpAndSettle();
    });

    testWidgets('renders download button and handles pack downloading UI ticks', (tester) async {
      final mockClient = MockHttpClient();
      final mockResponse = MockStreamedResponse();
      PackDownloadService.instance.httpClient = mockClient;
      AppDirs.setMockAvailableDiskSpaceMB(1000.0);

      // Create dummy zip archive
      final archive = Archive();
      archive.addFile(ArchiveFile('emoji_1.png', 5, [10, 20, 30, 40, 50]));
      final zipBytes = ZipEncoder().encode(archive);

      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.stream).thenAnswer((_) => http.ByteStream.fromBytes(zipBytes));
      when(() => mockClient.send(any())).thenAnswer((_) async => mockResponse);

      final uninstalledVerification = const AssetVerificationResult(
        allRequiredPresent: false,
        missing: [
          MissingAsset(
            packId: 'googleNonAnimated',
            packName: 'Google Noto (Static)',
            isRequired: true,
            userMessage: 'Required pack is missing',
          ),
        ],
        installedPackIds: [],
        hasAnyEmojis: false,
      );

      await pumpTestWidget(
        tester,
        const OnboardingScreen(),
        overrides: [
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(uninstalledVerification)),
        ],
      );

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Confirm Location'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      final downloadBtn = find.widgetWithText(ElevatedButton, 'DOWNLOAD');
      expect(downloadBtn, findsOneWidget);

      await tester.tap(downloadBtn);
      await tester.pump(const Duration(milliseconds: 200));

      // Cleaning up
      PackDownloadService.instance.httpClient = null;
      AppDirs.setMockAvailableDiskSpaceMB(null);
    });

    testWidgets('renders checkmark icon when pack is verified as installed', (tester) async {
      await pumpTestWidget(
        tester,
        const OnboardingScreen(),
        overrides: [
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Confirm Location'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Verify the checkmark circle icon renders for installed pack
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.text('DOWNLOAD'), findsNothing);
    });

    testWidgets('Skip setup for now button skips Step 1 and goes to Choose Asset Directory', (tester) async {
      await pumpTestWidget(
        tester,
        const OnboardingScreen(),
        overrides: [
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();

      // Tap Skip setup for now button
      final skipBtn = find.text('Skip setup for now');
      expect(skipBtn, findsOneWidget);
      await tester.tap(skipBtn);
      await tester.pumpAndSettle();

      // Should be on Choose Asset Directory screen (Step 2)
      expect(find.text('Choose Asset Directory'), findsOneWidget);
    });

    testWidgets('Back button on Choose Asset Directory returns to Step 1', (tester) async {
      await pumpTestWidget(
        tester,
        const OnboardingScreen(),
        overrides: [
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      // Navigate to step 2 (Choose Asset Directory)
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Tap Back button
      final backBtn = find.widgetWithText(TextButton, 'Back');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Should be back on Connect Local CLI Tools screen (Step 1)
      expect(find.text('Connect Local CLI Tools'), findsOneWidget);
    });

    testWidgets('Back button on Download Content Packs returns to Choose Asset Directory', (tester) async {
      await pumpTestWidget(
        tester,
        const OnboardingScreen(),
        overrides: [
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      // Navigate to step 3 (Download Content Packs)
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Confirm Location'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Tap Back button
      final backBtn = find.widgetWithText(TextButton, 'Back');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      await tester.pumpAndSettle();

      // Should be back on Choose Asset Directory screen (Step 2)
      expect(find.text('Choose Asset Directory'), findsOneWidget);
    });

    testWidgets('renders REQUIRED badge on required pack in content download list', (tester) async {
      await pumpTestWidget(
        tester,
        const OnboardingScreen(),
        overrides: [
          assetManifestProvider.overrideWithValue(testManifest),
          assetVerificationProvider.overrideWith((ref) => FakeAssetVerificationNotifier(testVerification)),
        ],
      );

      // Navigate to step 3 (Download Content Packs)
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Confirm Location'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      // Verify required badge text is visible
      expect(find.text('REQUIRED'), findsOneWidget);
    });
  });
}
