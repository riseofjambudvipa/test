import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/features/settings/presentation/views/settings_screen.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import 'package:capstudio/core/utils/premium_blur_dialog.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import '../../../../helpers/widget_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    rootBundle.clear(); // Clear cache to prevent cross-zone Future hang in widget tests
    tempDir = Directory.systemTemp.createTempSync('capstudio_settings_view_test_');
    AppDirs.setSupportPathForTesting(tempDir.path);
    await AppDirs.init();

    SharedPreferences.setMockInitialValues({
      'whisper_cli_path': 'C:\\bin\\whisper-cli.exe',
      'ffmpeg_cli_path': 'C:\\bin\\ffmpeg.exe',
      'default_language': 'en',
      'use_vad': true,
      'vad_threshold': 0.6,
      'use_gpu': false,
      'whisper_threads': 8,
    });

    await SettingsService.instance.init();

    // Mock locales_manifest.json to avoid hanging rootBundle in widget tests.
    // In Flutter widget tests, loading an unmocked asset from rootBundle can hang
    // or block the pumpAndSettle loop due to asynchronous channel handling.
    final binaryMessenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    binaryMessenger.setMockMessageHandler('flutter/assets', (message) async {
      if (message == null) return null;
      // The message payload contains the asset path.
      // We check if it is loading our locales manifest asset.
      final key = utf8.decode(message.buffer.asUint8List(message.offsetInBytes, message.lengthInBytes));
      if (key.contains('locales_manifest.json')) {
        final bytes = utf8.encoder.convert(jsonEncode([
          {'code': 'en', 'name': 'English'},
          {'code': 'es', 'name': 'Spanish'},
        ]));
        return bytes.buffer.asByteData();
      }
      return null; // Fallback to default
    });
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  group('SettingsScreen Widget Tests', () {
    testWidgets('renders all settings groups and inputs correctly from SettingsService', (tester) async {
      await pumpTestWidget(
        tester,
        const SettingsScreen(),
      );

      // Verify header
      expect(find.text('SETTINGS'), findsOneWidget);

      // Expand advanced path configuration
      final advancedBtn = find.text('SHOW ADVANCED PATH CONFIGURATION');
      expect(advancedBtn, findsOneWidget);
      await tester.ensureVisible(advancedBtn);
      await tester.tap(advancedBtn);
      await tester.pumpAndSettle();

      // Verify input values populated from mock SharedPreferences
      final whisperField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Path to whisper-cli executable');
      expect(whisperField, findsOneWidget);
      await tester.ensureVisible(whisperField);
      final whisperText = tester.widget<TextField>(whisperField).controller?.text;
      expect(whisperText, 'C:\\bin\\whisper-cli.exe');

      final ffmpegField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Path to ffmpeg executable');
      expect(ffmpegField, findsOneWidget);
      await tester.ensureVisible(ffmpegField);
      final ffmpegText = tester.widget<TextField>(ffmpegField).controller?.text;
      expect(ffmpegText, 'C:\\bin\\ffmpeg.exe');

      // Expand Hardware Performance Upgrades
      final hardwareHeader = find.text('Hardware Performance Upgrades');
      expect(hardwareHeader, findsOneWidget);
      await tester.ensureVisible(hardwareHeader);
      await tester.tap(hardwareHeader);
      await tester.pumpAndSettle();

      // Verify VAD switch and threshold slider exist
      expect(find.text('Voice Activity Detection (VAD)'), findsOneWidget);
      expect(find.byType(Slider), findsWidgets); // VAD slider + CPU threads slider

      // Verify default language is English
      expect(find.text('English (en)'), findsOneWidget);

      // Verify CPU threads count shows '8'
      expect(find.text('8'), findsOneWidget);
    });

    testWidgets('toggles switches and updates SettingsService', (tester) async {
      await pumpTestWidget(
        tester,
        const SettingsScreen(),
      );

      // Expand Hardware Performance Upgrades
      final hardwareHeader = find.text('Hardware Performance Upgrades');
      expect(hardwareHeader, findsOneWidget);
      await tester.ensureVisible(hardwareHeader);
      await tester.tap(hardwareHeader);
      await tester.pumpAndSettle();

      // Find the VAD switch. In new layout it is the second switch (index 1).
      final vadSwitchFinder = find.byType(Switch).at(1);
      expect(tester.widget<Switch>(vadSwitchFinder).value, isTrue);

      // Tap the VAD switch to turn it off
      await tester.ensureVisible(vadSwitchFinder);
      await tester.tap(vadSwitchFinder);
      await tester.pumpAndSettle();

      // Verify switch is off and setting updated in SettingsService
      expect(tester.widget<Switch>(vadSwitchFinder).value, isFalse);
      expect(SettingsService.instance.useVad, isFalse);

      // Verify GPU switch is off initially. In new layout it is the first switch (index 0).
      final gpuSwitchFinder = find.byType(Switch).first;
      expect(tester.widget<Switch>(gpuSwitchFinder).value, isFalse);

      // Tap GPU switch to turn on
      await tester.ensureVisible(gpuSwitchFinder);
      await tester.tap(gpuSwitchFinder);
      await tester.pumpAndSettle();

      // Verify switch is on and setting updated in SettingsService
      expect(tester.widget<Switch>(gpuSwitchFinder).value, isTrue);
      expect(SettingsService.instance.useGpu, isTrue);

      // Verify Auto-Save switch is on initially. It is the third switch (index 2).
      final autoSaveSwitchFinder = find.byType(Switch).at(2);
      expect(tester.widget<Switch>(autoSaveSwitchFinder).value, isTrue);

      // Tap Auto-Save switch to turn off
      await tester.ensureVisible(autoSaveSwitchFinder);
      await tester.tap(autoSaveSwitchFinder);
      await tester.pumpAndSettle();

      // Verify switch is off and setting updated in SettingsService
      expect(tester.widget<Switch>(autoSaveSwitchFinder).value, isFalse);
      expect(SettingsService.instance.autoSaveEnabled, isFalse);

      // Verify Always Ask switch is off initially. It is now the fourth switch (index 3).
      final alwaysAskSwitchFinder = find.byType(Switch).at(3);
      expect(tester.widget<Switch>(alwaysAskSwitchFinder).value, isFalse);
 
      // Tap Always Ask switch to turn on
      await tester.ensureVisible(alwaysAskSwitchFinder);
      await tester.tap(alwaysAskSwitchFinder);
      await tester.pumpAndSettle();
 
      // Verify switch is on and setting updated in SettingsService
      expect(tester.widget<Switch>(alwaysAskSwitchFinder).value, isTrue);
      expect(SettingsService.instance.alwaysAskExportPath, isTrue);
    });

    testWidgets('VAD threshold slider drag updates SettingsService', (tester) async {
      await pumpTestWidget(
        tester,
        const SettingsScreen(),
      );

      final sliders = find.byType(Slider);
      final vadSliderFinder = sliders.last;
      expect(vadSliderFinder, findsOneWidget);
      await tester.ensureVisible(vadSliderFinder);
      await tester.pumpAndSettle();

      // Drag the VAD slider
      await tester.drag(vadSliderFinder, const Offset(100.0, 0.0));
      await tester.pumpAndSettle();

      // Verify the value in SettingsService has updated
      expect(SettingsService.instance.vadThreshold, isNot(0.5));
    });

    testWidgets('Whisper CPU threads slider drag updates SettingsService', (tester) async {
      await pumpTestWidget(
        tester,
        const SettingsScreen(),
      );

      // Expand Hardware Performance Upgrades
      final hardwareHeader = find.text('Hardware Performance Upgrades');
      expect(hardwareHeader, findsOneWidget);
      await tester.ensureVisible(hardwareHeader);
      await tester.tap(hardwareHeader);
      await tester.pumpAndSettle();

      final sliders = find.byType(Slider);
      final threadsSliderFinder = sliders.first;
      expect(threadsSliderFinder, findsOneWidget);
      await tester.ensureVisible(threadsSliderFinder);
      await tester.pumpAndSettle();

      // Drag the threads slider
      await tester.drag(threadsSliderFinder, const Offset(-100.0, 0.0));
      await tester.pumpAndSettle();

      // Verify value in SettingsService is no longer 8
      expect(SettingsService.instance.whisperThreads, isNot(8));
    });

    testWidgets('typing invalid path and validating Whisper CLI displays error icon', (tester) async {
      await pumpTestWidget(
        tester,
        const SettingsScreen(),
      );

      // Expand advanced path configuration
      final advancedBtn = find.text('SHOW ADVANCED PATH CONFIGURATION');
      expect(advancedBtn, findsOneWidget);
      await tester.ensureVisible(advancedBtn);
      await tester.tap(advancedBtn);
      await tester.pumpAndSettle();

      final whisperField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Path to whisper-cli executable');
      expect(whisperField, findsOneWidget);

      await tester.ensureVisible(whisperField);
      await tester.enterText(whisperField, 'C:\\non_existent\\whisper.exe');
      await tester.pumpAndSettle();

      final validateBtns = find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Validate Path');
      expect(validateBtns, findsNWidgets(2));
      
      await tester.ensureVisible(validateBtns.first);
      await tester.tap(validateBtns.first);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.error_outline), findsWidgets);
    });

    testWidgets('typing invalid path and validating FFmpeg CLI displays error icon', (tester) async {
      await pumpTestWidget(
        tester,
        const SettingsScreen(),
      );

      // Expand advanced path configuration
      final advancedBtn = find.text('SHOW ADVANCED PATH CONFIGURATION');
      expect(advancedBtn, findsOneWidget);
      await tester.ensureVisible(advancedBtn);
      await tester.tap(advancedBtn);
      await tester.pumpAndSettle();

      final ffmpegField = find.byWidgetPredicate((w) => w is TextField && w.decoration?.hintText == 'Path to ffmpeg executable');
      expect(ffmpegField, findsOneWidget);

      await tester.ensureVisible(ffmpegField);
      await tester.enterText(ffmpegField, 'C:\\non_existent\\ffmpeg.exe');
      await tester.pumpAndSettle();

      final validateBtns = find.byWidgetPredicate((w) => w is IconButton && w.tooltip == 'Validate Path');
      await tester.ensureVisible(validateBtns.last);
      await tester.tap(validateBtns.last);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.error_outline), findsWidgets);
    });

    testWidgets('reset settings default dialog cancel does not reset settings', (tester) async {
      await pumpTestWidget(
        tester,
        const SettingsScreen(),
      );

      // Tap Reset Defaults button
      final resetBtnFinder = find.widgetWithText(TextButton, 'Reset Defaults');
      expect(resetBtnFinder, findsOneWidget);
      await tester.ensureVisible(resetBtnFinder);
      await tester.pumpAndSettle();
      await tester.tap(resetBtnFinder);
      await tester.pumpAndSettle();

      // Check dialog shown
      expect(find.text('Are you sure you want to clear all configurations and restore defaults?'), findsOneWidget);

      // Tap Cancel button
      final cancelBtnFinder = find.widgetWithText(TextButton, 'CANCEL');
      expect(cancelBtnFinder, findsOneWidget);
      await tester.tap(cancelBtnFinder);
      await tester.pumpAndSettle();

      // Settings should not be reset, whisper threads still 8
      expect(SettingsService.instance.whisperThreads, equals(8));
    });

    testWidgets('reset settings default dialog confirm resets settings to default values', (tester) async {
      // Modify value first
      await SettingsService.instance.setWhisperThreads(12);
      expect(SettingsService.instance.whisperThreads, equals(12));

      await pumpTestWidget(
        tester,
        const SettingsScreen(),
      );

      // Tap Reset Defaults button
      final resetBtnFinder = find.widgetWithText(TextButton, 'Reset Defaults');
      expect(resetBtnFinder, findsOneWidget);
      await tester.ensureVisible(resetBtnFinder);
      await tester.pumpAndSettle();
      await tester.tap(resetBtnFinder);
      await tester.pumpAndSettle();

      // Tap Reset button in dialog
      final confirmBtnFinder = find.descendant(
        of: find.byType(PremiumBlurDialog),
        matching: find.widgetWithText(TextButton, 'Reset Defaults'),
      );
      expect(confirmBtnFinder, findsOneWidget);
      await tester.tap(confirmBtnFinder);
      await tester.pumpAndSettle();

      // Settings should be reset, whisper threads should be default 0 (auto-detect) again
      expect(SettingsService.instance.whisperThreads, equals(0));
    });
  });
}
