import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import '../utils/app_dirs.dart';
import '../assets/asset_path_service.dart';

/// Centralized discovery for local Whisper CLI executable across all desktop platforms.
///
/// Follows the same robust, bundle-relative and dynamic environment search hierarchy
/// as FfmpegLocator, ensuring Whisper CLI is discovered without hardcoded paths.
class WhisperLocator {
  WhisperLocator._internal();
  static final WhisperLocator instance = WhisperLocator._internal();

  String? _cachedWhisper;

  /// Resolves the executable path to whisper-cli.
  /// Explicitly configured path always takes precedence.
  String resolve({String? configured}) {
    if (kIsWeb) return 'whisper-cli';
    final explicit = configured?.trim() ?? '';
    if (explicit.isNotEmpty) return explicit;
    if (_cachedWhisper != null) return _cachedWhisper!;

    final exe = Platform.isWindows ? 'whisper-cli.exe' : 'whisper-cli';
    final found = _discover(exe);
    _cachedWhisper = found;
    return found;
  }

  /// Reset cached resolution (used in tests or when re-configuring paths).
  void clearCache() {
    _cachedWhisper = null;
  }

  String _discover(String exe) {
    final executableDir = p.dirname(Platform.resolvedExecutable);
    final paths = <String>[
      // Dev-mode / source-tree locations
      p.join(Directory.current.path, 'assets', 'bin', exe),
      p.join(Directory.current.path, 'bin', exe),
      p.join(Directory.current.path, 'data', 'flutter_assets', 'assets', 'bin', exe),

      // App support data folder & custom drive bin (downloaded or installed by CapStudio)
      tryPath(() => p.join(AssetPathService.instance.binDir, exe)),
      tryPath(() => p.join(AppDirs.bin, exe)),

      // Packaged macOS app bundle
      p.join(executableDir, exe),
      p.join(executableDir, '..', 'Resources', 'bin', exe),

      // Packaged Linux bundle
      p.join(executableDir, 'bin', exe),

      // Windows dynamic Program Files and Local App Data paths
      if (Platform.isWindows) ...[
        if (Platform.environment['PROGRAMFILES'] != null)
          p.join(Platform.environment['PROGRAMFILES']!, 'whisper.cpp', exe),
        if (Platform.environment['ProgramFiles(x86)'] != null)
          p.join(Platform.environment['ProgramFiles(x86)']!, 'whisper.cpp', exe),
        if (Platform.environment['LOCALAPPDATA'] != null) ...[
          p.join(Platform.environment['LOCALAPPDATA']!, 'Programs', 'whisper.cpp', exe),
          p.join(Platform.environment['LOCALAPPDATA']!, 'Programs', 'whisper', exe),
        ],
      ],

      // Unix and macOS standard and package manager locations
      if (!Platform.isWindows) ...[
        '/opt/homebrew/bin/$exe',
        '/usr/local/bin/$exe',
        '/usr/bin/$exe',
        '/snap/bin/$exe',
      ],
    ];

    for (final path in paths) {
      if (path.isNotEmpty && File(path).existsSync()) return path;
    }

    return exe;
  }

  /// Safely resolves a path that might depend on AppDirs before AppDirs.init()
  static String tryPath(String Function() resolver) {
    try {
      return resolver();
    } catch (_) {
      return '';
    }
  }
}
