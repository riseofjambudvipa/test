import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import 'package:capstudio/features/settings/presentation/views/settings/export_settings_section.dart';
import 'package:capstudio/features/settings/presentation/views/settings/general_settings_section.dart';
import 'package:capstudio/features/settings/presentation/views/settings/theme_settings_section.dart';
import 'package:capstudio/features/settings/presentation/views/settings/transcription_settings_section.dart';
import '../../../../helpers/widget_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('capstudio_settings_sections_test_');
    AppDirs.setSupportPathForTesting(tempDir.path);
    await AppDirs.init();

    SharedPreferences.setMockInitialValues({
      'whisper_cli_path': 'C:\\bin\\whisper-cli.exe',
      'ffmpeg_cli_path': 'C:\\bin\\ffmpeg.exe',
      'default_language': 'en',
      'use_vad': true,
      'vad_threshold': 0.6,
      'use_gpu': false,
      'whisper_threads': 4,
      'export_threads': 4,
      'always_ask_export_path': false,
      'default_export_folder': 'C:\\exports',
    });

    await SettingsService.instance.init();
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('ExportSettingsSection renders export path and threads controls', (tester) async {
    await pumpTestWidget(
      tester,
      const SingleChildScrollView(child: ExportSettingsSection()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Default Outputs'), findsOneWidget);
    expect(find.text('Default Export Folder'), findsOneWidget);
    expect(find.textContaining('Always Ask for Export Path'), findsOneWidget);
    expect(find.textContaining('Export CPU Threads'), findsOneWidget);
  });

  testWidgets('ThemeSettingsSection renders light/dark switcher and theme palettes', (tester) async {
    await pumpTestWidget(
      tester,
      const SingleChildScrollView(child: ThemeSettingsSection()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Visual Theme & Appearance'), findsOneWidget);
    expect(find.text('APPEARANCE MODE'), findsOneWidget);
    expect(find.text('Light Studio'), findsOneWidget);
    expect(find.text('Dark Studio'), findsOneWidget);
    expect(find.text('STUDIO COLOR PALETTES'), findsOneWidget);
  });

  testWidgets('TranscriptionSettingsSection renders default language and VAD controls', (tester) async {
    await pumpTestWidget(
      tester,
      const SingleChildScrollView(child: TranscriptionSettingsSection()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Transcription Settings'), findsOneWidget);
    expect(find.text('Default Language'), findsOneWidget);
    expect(find.text('Voice Activity Detection (VAD)'), findsOneWidget);
  });

  testWidgets('GeneralSettingsSection renders performance and path controls', (tester) async {
    await pumpTestWidget(
      tester,
      const SingleChildScrollView(child: GeneralSettingsSection()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hardware Performance Upgrades'), findsOneWidget);
  });
}
