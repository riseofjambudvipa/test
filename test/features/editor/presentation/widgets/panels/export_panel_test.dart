import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/whisper/whisper_service.dart';
import 'package:capstudio/features/editor/presentation/controllers/editor_controller.dart';
import 'package:capstudio/features/editor/presentation/widgets/panels/export_panel.dart';
import '../../../../../helpers/project_fixture.dart';
import '../../../../../helpers/widget_helpers.dart';

/// In-memory [FilePickerPlatform] fake. file_picker 12.x is federated and its
/// platform instance is swappable, which is far more robust than mocking the
/// legacy method channel (the previous version of this test mocked
/// `miguelruivo.flutter.plugins.filepicker`, which the beta restructure no
/// longer routes through).
class _FakeFilePickerPlatform extends FilePickerPlatform {
  String? saveTo;
  String? pickFolder;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    required String fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    required Uint8List bytes,
    Function(FilePickerStatus)? onFileLoading,
    bool lockParentWindow = false,
  }) async {
    final path = saveTo;
    if (path != null) {
      await File(path).writeAsBytes(bytes);
    }
    return path;
  }

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
    AndroidSAFOptions? androidSafOptions,
  }) async {
    return pickFolder;
  }
}

/// Polls until [path] exists with non-empty content on disk, up to 10
/// seconds. Must be called inside [WidgetTester.runAsync] so real async file
/// I/O can complete. Waiting for non-empty content (not just existence) is
/// required because the export handler writes the file asynchronously — a
/// file can exist but still be empty mid-write.
Future<void> _waitForFile(String path) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (DateTime.now().isBefore(deadline)) {
    if (File(path).existsSync()) {
      final content = File(path).readAsStringSync();
      if (content.trim().isNotEmpty) return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeFilePickerPlatform fakePicker;
  FilePickerPlatform? previousPlatform;
  String? clipboardText;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'auto_save_enabled': false});
    await SettingsService.instance.init();
    fakePicker = _FakeFilePickerPlatform();
    previousPlatform = FilePickerPlatform.instance;
    FilePickerPlatform.instance = fakePicker;
    // Clipboard goes over the `flutter/platform` channel; without a mock the
    // test binary messenger never answers and the test hangs on await. Keep a
    // tiny in-memory clipboard so getData() round-trips what setData() wrote.
    clipboardText = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        final args = call.arguments as Map<Object?, Object?>?;
        clipboardText = args?['text'] as String?;
        return null;
      }
      if (call.method == 'Clipboard.getData') {
        return <String, Object?>{'text': clipboardText};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  tearDown(() {
    if (previousPlatform != null) {
      FilePickerPlatform.instance = previousPlatform!;
    }
  });

  Future<ProviderContainer> pumpPanel(WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorProvider.notifier).setProject(
          makeProject(
            words: [makeWord(text: 'hello world', start: 0.0, end: 1.0)],
          ),
        );
    await pumpTestWidget(tester, const ExportPanel(), container: container);
    // initState's _checkFastModeSupport resolves asynchronously.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    return container;
  }

  group('ExportPanel', () {
    testWidgets('renders burn-in section and all four subtitle cards',
        (tester) async {
      await pumpPanel(tester);

      expect(find.text('BURN-IN VIDEO EXPORT'), findsOneWidget);
      expect(find.text('TIMECODE SUBTITLE FORMATS'), findsOneWidget);
      expect(find.text('SubRip Subtitles (.srt)'), findsOneWidget);
      expect(find.text('WebVTT Subtitles (.vtt)'), findsOneWidget);
      expect(find.text('Advanced SubStation Alpha (.ass)'), findsOneWidget);
      expect(find.text('Plain Text Transcript (.txt)'), findsOneWidget);
    });

    testWidgets('tapping the SRT card writes the subtitle file and confirms',
        (tester) async {
      final tmp = Directory.systemTemp.createTempSync('capstudio_srt_test');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      final outPath = '${tmp.path}${Platform.pathSeparator}out.srt';
      fakePicker.saveTo = outPath;

      await pumpPanel(tester);
      await tester.ensureVisible(find.text('SubRip Subtitles (.srt)'));
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.text('SubRip Subtitles (.srt)'));
        // Give the async export (file write) time to complete; poll instead
        // of a fixed delay so slow CI machines don't flake.
        await _waitForFile(outPath);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(File(outPath).existsSync(), isTrue);
      final content = File(outPath).readAsStringSync();
      // The default fixture style is uppercase, so compare case-insensitively.
      expect(content.toLowerCase(), contains('hello world'));
      expect(content, contains('00:00:00,000'));
      expect(find.text('SRT exported successfully!'), findsOneWidget);
    });

    testWidgets('tapping the VTT card writes a WEBVTT file', (tester) async {
      final tmp = Directory.systemTemp.createTempSync('capstudio_vtt_test');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      final outPath = '${tmp.path}${Platform.pathSeparator}out.vtt';
      fakePicker.saveTo = outPath;

      await pumpPanel(tester);
      await tester.ensureVisible(find.text('WebVTT Subtitles (.vtt)'));
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.text('WebVTT Subtitles (.vtt)'));
        await _waitForFile(outPath);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final content = File(outPath).readAsStringSync();
      expect(content, contains('WEBVTT'));
      expect(content.toLowerCase(), contains('hello world'));
    });

    testWidgets('tapping the ASS card writes an ASS script', (tester) async {
      final tmp = Directory.systemTemp.createTempSync('capstudio_ass_test');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      final outPath = '${tmp.path}${Platform.pathSeparator}out.ass';
      fakePicker.saveTo = outPath;

      await pumpPanel(tester);
      await tester.ensureVisible(find.text('Advanced SubStation Alpha (.ass)'));
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.text('Advanced SubStation Alpha (.ass)'));
        await _waitForFile(outPath);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final content = File(outPath).readAsStringSync();
      expect(content, contains('Dialogue:'));
      expect(content.toLowerCase(), contains('hello world'));
    });

    testWidgets('tapping the TXT card writes a transcript file',
        (tester) async {
      final tmp = Directory.systemTemp.createTempSync('capstudio_txt_test');
      addTearDown(() {
        try {
          tmp.deleteSync(recursive: true);
        } catch (_) {}
      });
      final outPath = '${tmp.path}${Platform.pathSeparator}out.txt';
      fakePicker.saveTo = outPath;

      await pumpPanel(tester);
      await tester.ensureVisible(find.text('Plain Text Transcript (.txt)'));
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.text('Plain Text Transcript (.txt)'));
        await _waitForFile(outPath);
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(File(outPath).readAsStringSync().toLowerCase(),
          contains('hello world'));
    });

    testWidgets('copy button puts the SRT on the clipboard', (tester) async {
      await pumpPanel(tester);

      await tester.ensureVisible(find.byIcon(Icons.copy_rounded));
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.copy_rounded));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final data = await Clipboard.getData('text/plain');
      expect(data?.text?.toLowerCase(), contains('hello world'));
      expect(find.text('SRT copied to clipboard!'), findsOneWidget);
    });

    testWidgets('fast mode is supported on desktop (no unsupported warning)',
        (tester) async {
      await pumpPanel(tester);

      expect(find.text('Fast (Native FFmpeg)'), findsOneWidget);
      expect(find.textContaining('Fast Mode is not supported'), findsNothing);
      // Slow-mode-only UI is hidden initially.
      expect(find.text('Target FPS'), findsNothing);
    });

    testWidgets('selecting slow mode reveals the target FPS selector',
        (tester) async {
      await pumpPanel(tester);

      await tester.tap(find.text('Fast (Native FFmpeg)'));
      await tester.pump();
      await tester.ensureVisible(find.text('Slow (1:1 Preview Render)').last);
      await tester.pump();
      await tester.tap(find.text('Slow (1:1 Preview Render)').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Target FPS'), findsOneWidget);
      expect(find.text('30 FPS (Standard)'), findsOneWidget);
    });

    testWidgets('choosing an output folder updates the destination text',
        (tester) async {
      final folder =
          Directory.systemTemp.createTempSync('capstudio_folder_test');
      addTearDown(() {
        try {
          folder.deleteSync(recursive: true);
        } catch (_) {}
      });
      fakePicker.pickFolder = folder.path;

      await pumpPanel(tester);
      await tester.ensureVisible(find.byIcon(Icons.folder_open_outlined));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.byIcon(Icons.folder_open_outlined));
        await Future<void>.delayed(const Duration(milliseconds: 250));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(folder.path), findsOneWidget);
    });

    testWidgets('start export with a missing FFmpeg shows the warning dialog',
        (tester) async {
      // Configure a definitely-missing absolute path so the panel takes the
      // warning branch instead of launching a real export.
      WhisperService.instance
          .configureFfmpeg(r'C:\definitely_missing\ffmpeg.exe');

      await pumpPanel(tester);
      await tester.ensureVisible(find.text('START MP4 EXPORT'));
      await tester.pump();
      await tester.tap(find.text('START MP4 EXPORT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('FFmpeg Required'), findsOneWidget);
      expect(find.textContaining('A local installation of FFmpeg is required'),
          findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('FFmpeg Required'), findsNothing);
    });

    testWidgets('renders audio enhancement cards and toggles work',
        (tester) async {
      await pumpPanel(tester);

      await tester.ensureVisible(find.text('AI Studio Sound'));
      await tester.pump();

      expect(find.text('AI Studio Sound'), findsOneWidget);
      expect(find.text('PRO AUDIO'), findsOneWidget);
      expect(find.text('Smooth Cut Transitions'), findsOneWidget);
      expect(find.text('ANTI-CLICK'), findsOneWidget);

      final switches = find.byType(Switch);
      expect(switches, findsAtLeastNWidgets(2));

      // Studio sound is initially off
      final studioSoundSwitch = tester.widget<Switch>(switches.at(switches.evaluate().length - 2));
      expect(studioSoundSwitch.value, isFalse);

      // Smooth cuts crossfade is initially on
      final crossfadeSwitch = tester.widget<Switch>(switches.at(switches.evaluate().length - 1));
      expect(crossfadeSwitch.value, isTrue);

      // Tap to toggle studio sound
      await tester.tap(switches.at(switches.evaluate().length - 2));
      await tester.pumpAndSettle();

      final updatedStudioSound = tester.widget<Switch>(switches.at(switches.evaluate().length - 2));
      expect(updatedStudioSound.value, isTrue);
    });

    testWidgets('renders auto-reframe export card and allows mode selection',
        (tester) async {
      await pumpPanel(tester);

      await tester.ensureVisible(find.text('Export 9:16 Vertical Reframe'));
      await tester.pump();

      expect(find.text('Export 9:16 Vertical Reframe'), findsOneWidget);
      expect(find.text('AI AUTO-FRAME'), findsOneWidget);
      expect(find.text('Original Canvas (16:9 Landscape)'), findsOneWidget);
      expect(find.text('Blur Pillarbox (Recommended)'), findsOneWidget);
      expect(find.text('Center Smart Crop'), findsOneWidget);
      expect(find.text('AI Smart Face Track (OpusClip)'), findsOneWidget);
      expect(find.text('Split Screen / Dual Layer'), findsOneWidget);

      // Select Blur Pillarbox
      await tester.tap(find.text('Blur Pillarbox (Recommended)'));
      await tester.pumpAndSettle();

      // Mode can be toggled to Center Smart Crop
      await tester.tap(find.text('Center Smart Crop'));
      await tester.pumpAndSettle();
    });
  });
}
