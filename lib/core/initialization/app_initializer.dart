import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' hide AssetManifest;
import 'package:media_kit/media_kit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:path/path.dart' as p;

import '../database/isar_service.dart';
import '../logger/logger_service.dart';
import '../settings/settings_service.dart';
import '../fonts/font_service.dart';
import '../assets/asset_path_service.dart';
import '../assets/asset_manifest.dart';
import '../assets/asset_verification_service.dart';
import '../utils/app_dirs.dart';
import '../utils/path_migration_utils.dart';
import '../utils/platform_utils.dart';

class AppInitResult {
  final AssetManifest manifest;
  final AssetVerificationResult verification;

  const AppInitResult({
    required this.manifest,
    required this.verification,
  });
}

class AppInitializer {
  static const String initContext = 'Initialization';

  static Future<AppInitResult> boot() async {
    // Ensure Flutter binding is initialized
    WidgetsFlutterBinding.ensureInitialized();

    // Hide status bar and navigation bar completely (immersive fullscreen mode) on mobile platforms
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }

    // Enforce single-instance lock on Desktop to prevent database corruption
    if (isDesktop) {
      try {
        await RawServerSocket.bind(InternetAddress.loopbackIPv4, 56213);
      } catch (e) {
        stderr.writeln('CapStudio: Another instance is already running. Exiting.');
        exit(0);
      }
    }

    // Initialise path resolution first — everything else depends on this.
    await AppDirs.init();
    await PathMigrationUtils.init();

    // Initialize Logger first (everything else depends on it)
    await LoggerService.instance.init();

    // Hook Flutter framework errors into the advanced logger
    FlutterError.onError = (details) {
      LoggerService.instance.logFlutterError(details);
      // Also print to console in debug mode
      if (kDebugMode) FlutterError.dumpErrorToConsole(details);
    };

    LoggerService.instance.info('System', 'App booting... (crash zone active)');

    // Initialize Settings
    await SettingsService.instance.init();
    LoggerService.instance.log(LogLevel.info, 'Settings', 'SettingsService successfully initialized.');

    // Extract pre-packaged Whisper model from assets if it does not exist in local app support path
    if (!kIsWeb) {
      try {
        final modelDir = Directory(p.join(AppDirs.support, 'models'));
        if (!modelDir.existsSync()) {
          await modelDir.create(recursive: true);
        }
        final localModelPath = p.join(modelDir.path, 'ggml-tiny.bin');
        final localModelFile = File(localModelPath);
        if (!localModelFile.existsSync()) {
          LoggerService.instance.log(LogLevel.info, 'Settings', 'Pre-packaged tiny model not found in support path. Copying from assets...');
          await rootBundle.load('assets/models/ggml-tiny.bin').then((byteData) async {
            final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
            // Write the 75MB file in a background isolate to keep UI perfectly responsive
            await Isolate.run(() async {
              final file = File(localModelPath);
              await file.writeAsBytes(bytes, flush: true);
            });
            LoggerService.instance.log(LogLevel.info, 'Settings', 'Pre-packaged tiny model successfully copied to support path.');
            
            // Auto-set as default model if none is selected
            if ((SettingsService.instance.whisperModelPath ?? '').isEmpty) {
              await SettingsService.instance.setWhisperModelPath(localModelPath);
              await SettingsService.instance.setWhisperModelName('tiny');
              LoggerService.instance.log(LogLevel.info, 'Settings', 'Pre-packaged tiny model auto-configured as active Whisper model.');
            }
          }).catchError((Object err, StackTrace stack) {
            LoggerService.instance.log(LogLevel.error, 'Settings', 'Failed to copy pre-packaged tiny model from assets: $err', stackTrace: stack);
          });
        } else {
          // Model exists on disk. If settings don't point to any model, auto-point to this one!
          if ((SettingsService.instance.whisperModelPath ?? '').isEmpty) {
            await SettingsService.instance.setWhisperModelPath(localModelPath);
            await SettingsService.instance.setWhisperModelName('tiny');
            LoggerService.instance.log(LogLevel.info, 'Settings', 'Pre-packaged tiny model auto-configured as active Whisper model (already on disk).');
          }
        }
      } catch (e, stack) {
        LoggerService.instance.log(LogLevel.error, 'Settings', 'Failed to initialize pre-packaged model setup: $e', stackTrace: stack);
      }
    }

    // Pre-configure binaries for Linux Sandboxes to bypass auto-download
    if (isLinuxSandboxed) {
      if ((SettingsService.instance.whisperCliPath ?? '').isEmpty) {
        await SettingsService.instance.setWhisperCliPath('whisper-cli');
      }
      if ((SettingsService.instance.ffmpegCliPath ?? '').isEmpty) {
        await SettingsService.instance.setFfmpegCliPath('ffmpeg');
      }
      LoggerService.instance.log(LogLevel.info, 'Settings', 'Linux Sandbox detected: pre-configured system binaries to bypass auto-download.');
    }

    // Initialize Fonts
    try {
      await FontService.instance.init();
      LoggerService.instance.log(LogLevel.info, 'Fonts', 'FontService successfully initialized.');
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'Fonts', 'Failed to initialize fonts: $e');
    }

    // Initialize MediaKit for local GPU-accelerated video streaming
    if (!kIsWeb) {
      MediaKit.ensureInitialized();
    }

    // Initialize the local Isar database wrapper
    await IsarService.instance.init();
    LoggerService.instance.log(LogLevel.info, 'Database', 'Isar Database successfully initialized.');

    // Initialize Asset Path Service
    try {
      await AssetPathService.instance.init();
      LoggerService.instance.log(LogLevel.info, 'Assets', 'AssetPathService successfully initialized.');
      
      // Clean up orphaned temporary files in assets temp folder on startup
      try {
        final tempDir = Directory(AssetPathService.instance.tempDir);
        if (tempDir.existsSync()) {
          await for (final entity in tempDir.list(recursive: true)) {
            if (entity is File) {
              await entity.delete();
            }
          }
          LoggerService.instance.log(LogLevel.info, 'Initialization', 'Cleaned up orphaned temporary files in assets temp folder.');
        }
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'Initialization', 'Failed to clean up assets temp directory on boot: $e');
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'Assets', 'Failed to initialize asset path: $e');
    }

    // Load Asset Manifest
    AssetManifest manifest;
    try {
      manifest = await AssetManifest.load();
      LoggerService.instance.log(LogLevel.info, 'Assets', 'AssetManifest successfully loaded.');
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'Assets', 'Failed to load asset manifest: $e');
      manifest = AssetManifest(version: '2.0', packs: [], emojis: []);
    }

    // Run Asset Verification
    AssetVerificationResult verification;
    try {
      verification = await AssetVerificationService.instance.verify(manifest);
      LoggerService.instance.log(LogLevel.info, 'Assets', 'Asset verification completed. Required present: ${verification.allRequiredPresent}');
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'Assets', 'Failed to run asset verification: $e');
      verification = const AssetVerificationResult(
        allRequiredPresent: false,
        missing: [],
        installedPackIds: [],
        hasAnyEmojis: false,
      );
    }

    // Initialize Window Manager close prevention
    if (isDesktop) {
      try {
        await windowManager.ensureInitialized();
        await windowManager.setPreventClose(true);
        LoggerService.instance.log(LogLevel.info, 'WindowManager', 'Window Manager successfully initialized.');
      } catch (e) {
        LoggerService.instance.log(LogLevel.error, 'WindowManager', 'Failed to initialize Window Manager: $e');
      }
    }

    return AppInitResult(
      manifest: manifest,
      verification: verification,
    );
  }
}
