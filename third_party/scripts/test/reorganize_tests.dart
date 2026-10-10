// ignore_for_file: avoid_print
import 'dart:io';
import 'package:path/path.dart' as p;

// Mapping of flat test filenames to their structured subdirectories under `test/`
const Map<String, String> testDestinations = {
  'app_dirs_test.dart': 'core/utils',
  'asset_manifest_test.dart': 'core/assets',
  'asset_path_service_test.dart': 'core/assets',
  'audio_service_test.dart': 'core/audio',
  'binary_downloader_service_test.dart': 'core/downloader',
  'caption_engine_boundary_test.dart': 'core/whisper',
  'caption_engine_test.dart': 'core/whisper',
  'caption_overlay_test.dart': 'core/subtitle',
  'dashboard_controller_test.dart': 'features/dashboard/presentation/controllers',
  'dashboard_view_test.dart': 'features/dashboard/presentation/views',
  'editor_controller_boundary_test.dart': 'features/editor/presentation/controllers',
  'editor_controller_test.dart': 'features/editor/presentation/controllers',
  'emoji_service_test.dart': 'core/emoji',
  'ffmpeg_exporter_test.dart': 'core/ffmpeg',
  'font_service_test.dart': 'core/fonts',
  'isar_service_test.dart': 'core/database',
  'logger_service_test.dart': 'core/logger',
  'onboarding_view_test.dart': 'features/onboarding/presentation/views',
  'pack_download_service_test.dart': 'core/assets',
  'permission_service_test.dart': 'core/utils',
  'settings_service_test.dart': 'core/settings',
  'settings_view_test.dart': 'features/settings/presentation/views',
  'srt_importer_test.dart': 'core/subtitle',
  'style_templates_test.dart': 'core/subtitle',
  'subtitle_exporter_test.dart': 'core/subtitle',
  'suggest_font_language_test.dart': 'core/fonts',
  'timeline_widget_test.dart': 'features/editor/presentation/widgets',
  'video_relink_service_test.dart': 'core/video',
  'waveform_service_test.dart': 'core/audio',
  'whisper_json_parsing_test.dart': 'core/whisper',
  'whisper_model_test.dart': 'core/whisper',
  'whisper_service_test.dart': 'core/whisper',
  'widget_test.dart': 'app',
  'word_panel_test.dart': 'features/editor/presentation/widgets',
};

void main() async {
  final testDir = Directory(p.join(Directory.current.path, 'test'));
  if (!testDir.existsSync()) {
    print('Error: test/ directory not found in the current working directory.');
    exit(1);
  }

  print('Starting test directory reorganization...');

  int movedCount = 0;

  for (final entry in testDestinations.entries) {
    final filename = entry.key;
    final subfolder = entry.value;

    final sourceFile = File(p.join(testDir.path, filename));
    if (!sourceFile.existsSync()) {
      print('Warning: Source file not found, skipping: $filename');
      continue;
    }

    final destDir = Directory(p.join(testDir.path, subfolder));
    if (!destDir.existsSync()) {
      destDir.createSync(recursive: true);
    }

    final destFile = File(p.join(destDir.path, filename));
    
    // Read old content
    final String content = sourceFile.readAsStringSync();

    // Calculate depth relative to test/
    // e.g. core/utils has 2 parts, so N = 2. Relative prefix to test/ is '../../'
    final parts = p.split(subfolder);
    final N = parts.length;
    final relativePrefix = '../' * N;

    // Adjust relative imports
    final updatedContent = content
        .replaceAll("import 'mocks/mocks.dart';", "import '${relativePrefix}mocks/mocks.dart';")
        .replaceAll("import 'helpers/project_fixture.dart';", "import '${relativePrefix}helpers/project_fixture.dart';")
        .replaceAll("import 'helpers/widget_helpers.dart';", "import '${relativePrefix}helpers/widget_helpers.dart';");

    // Write to destination
    destFile.writeAsStringSync(updatedContent);

    // Delete source
    sourceFile.deleteSync();

    print(' Relocated: $filename -> test/$subfolder/$filename (Depth: $N, Prefix: $relativePrefix)');
    movedCount++;
  }

  print('\nReorganization completed successfully! Relocated $movedCount files.');
}
