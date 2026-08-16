import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/database/isar_service.dart';
import 'package:capstudio/core/logger/logger_service.dart';
import 'package:capstudio/core/audio/audio_service.dart';
import 'package:capstudio/core/emoji/emoji_service.dart';
import 'package:capstudio/core/whisper/whisper_service.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';

class TestEnvironment {
  Directory? _tempDir;

  Directory get tempDir {
    if (_tempDir == null) {
      throw StateError('TestEnvironment not initialized. Call initialize() first.');
    }
    return _tempDir!;
  }

  /// Sets up a clean, isolated test environment:
  /// - Sets up mock SharedPreferences values.
  /// - Creates a temporary directory inside 'test/.temp/' to centralize test files.
  /// - Initializes AppDirs, SettingsService, and LoggerService.
  /// - Suppresses console log output by default.
  Future<void> initialize({
    Map<String, Object> initialPreferences = const {},
    bool silenceLogs = false,
  }) async {
    // 1. SharedPreferences Mock
    SharedPreferences.setMockInitialValues({
      'db_schema_version': 1,
      ...initialPreferences,
    });

    // 2. Centralized Temp Directory inside test/.temp/
    final projectRoot = Directory.current.path;
    final testTempRoot = Directory(p.join(projectRoot, 'test', '.temp'));
    if (!testTempRoot.existsSync()) {
      testTempRoot.createSync(recursive: true);
    }
    _tempDir = testTempRoot.createTempSync('capstudio_test_');

    // 3. Initialize AppDirs with the temp path
    AppDirs.setSupportPathForTesting(_tempDir!.path);
    await AppDirs.init();

    // 4. Initialize LoggerService with reset and optional silence
    LoggerService.resetForTesting();
    if (silenceLogs) {
      LoggerService.instance.enableConsoleOutput = false;
    }
    await LoggerService.instance.init();

    // 5. Initialize SettingsService
    await SettingsService.instance.init();
  }

  /// Tears down the test environment, resets all singletons, and cleans up the temporary directory.
  Future<void> cleanUp() async {
    // 1. Close Isar if it was initialized
    try {
      if (IsarService.instance.isInitialized) {
        await IsarService.instance.close();
      }
    } catch (_) {}

    // 2. Dispose of LoggerService
    try {
      if (LoggerService.instance.isInitialized) {
        await LoggerService.instance.dispose();
      }
    } catch (_) {}

    // 3. Reset all service singletons to prevent state leakage
    IsarService.resetForTesting();
    LoggerService.resetForTesting();
    AudioService.instance.resetForTesting();
    EmojiService.instance.resetForTesting();
    WhisperService.resetForTesting();
    SettingsService.instance.resetForTesting();

    // 4. Delete the temporary directory
    if (_tempDir != null && _tempDir!.existsSync()) {
      try {
        _tempDir!.deleteSync(recursive: true);
      } catch (_) {
        // Ignore or swallow momentary file lock errors on Windows
      }
      _tempDir = null;
    }
  }
}

/// Helper function to register the standard test environment in a test file's main()
void registerTestEnvironment({
  Map<String, Object> initialPreferences = const {},
  bool silenceLogs = false,
}) {
  final env = TestEnvironment();

  setUp(() async {
    await env.initialize(
      initialPreferences: initialPreferences,
      silenceLogs: silenceLogs,
    );
  });

  tearDown(() async {
    await env.cleanUp();
  });
}
