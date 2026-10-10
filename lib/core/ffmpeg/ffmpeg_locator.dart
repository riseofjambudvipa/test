import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import '../utils/app_dirs.dart';
import '../assets/asset_path_service.dart';

/// Shared FFmpeg/ffprobe executable discovery for desktop platforms.
///
/// Both WhisperService (audio extraction) and FfmpegExporter (video export)
/// need a working FFmpeg, and the editor/dashboard need ffprobe for metadata.
/// In dev runs, `ffmpeg` on PATH (or an explicitly downloaded binary) is
/// enough, but in packaged desktop apps the working directory is NOT the app
/// bundle, so bundle-relative lookups (next to the executable, in
/// `Contents/Resources/bin` on macOS, `bin/` on Linux) are required.
///
/// Semantics:
///  * An explicitly configured path always wins (it is returned directly and
///    never cached, so re-configuration takes effect immediately).
///  * Otherwise, discovery runs once and is cached; [clearCache] resets it
///    (used by service reset hooks in tests and re-configuration paths).
class FfmpegLocator {
  FfmpegLocator._internal();
  static final FfmpegLocator instance = FfmpegLocator._internal();

  String? _cachedFfmpeg;
  String? _cachedFfprobe;

  /// Path to use for FFmpeg subprocess runs. Falls back to `'ffmpeg'` (PATH
  /// lookup) when nothing can be located.
  String resolve({String? configured}) {
    if (kIsWeb) return 'ffmpeg';
    final explicit = configured?.trim() ?? '';
    if (explicit.isNotEmpty) return explicit;
    if (_cachedFfmpeg != null) return _cachedFfmpeg!;

    final exe = Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
    final found = _discover(exe);
    final result = (found == exe) ? 'ffmpeg' : found;
    _cachedFfmpeg = result;
    return result;
  }

  /// Path to use for ffprobe subprocess runs. Looks for ffprobe next to the
  /// resolved FFmpeg binary (bundled distributions ship them together), then
  /// falls back to `'ffprobe'` (PATH lookup).
  String resolveFfprobe({String? configured}) {
    if (kIsWeb) return 'ffprobe';
    final explicit = configured?.trim() ?? '';
    if (explicit.isNotEmpty) {
      final name = p.basename(explicit).toLowerCase();
      if (name.startsWith('ffmpeg')) {
        // If caller passed ffmpeg binary path, resolve its sibling ffprobe
        final sibling = p.join(
          p.dirname(explicit),
          Platform.isWindows ? 'ffprobe.exe' : 'ffprobe',
        );
        if (File(sibling).existsSync()) {
          return sibling;
        }
      } else if (File(explicit).existsSync()) {
        return explicit;
      }
    }
    if (_cachedFfprobe != null) return _cachedFfprobe!;

    final ffmpegPath = resolve(configured: configured);
    if (ffmpegPath != 'ffmpeg') {
      final sibling = p.join(
        p.dirname(ffmpegPath),
        Platform.isWindows ? 'ffprobe.exe' : 'ffprobe',
      );
      if (File(sibling).existsSync()) {
        _cachedFfprobe = sibling;
        return sibling;
      }
    }

    final exe = Platform.isWindows ? 'ffprobe.exe' : 'ffprobe';
    final discovered = _discover(exe);
    if (discovered != exe && File(discovered).existsSync()) {
      _cachedFfprobe = discovered;
      return discovered;
    }

    _cachedFfprobe = 'ffprobe';
    return 'ffprobe';
  }

  /// Forget any cached discovery results. Call after re-configuring a path
  /// or when resetting services for testing.
  void clearCache() {
    _cachedFfmpeg = null;
    _cachedFfprobe = null;
  }

  String _discover(String exe) {
    final executableDir = p.dirname(Platform.resolvedExecutable);
    final isTest = Platform.environment.containsKey('FLUTTER_TEST');
    final paths = <String>[
      // Dev-mode / source-tree locations
      p.join(Directory.current.path, 'assets', 'bin', exe),
      p.join(Directory.current.path, 'bin', exe),
      p.join(Directory.current.path, 'data', 'flutter_assets', 'assets', 'bin', exe),

      if (!isTest) ...[
        // Dedicated app support and custom drive bin directory (downloaded via binary downloader)
        tryPath(() => p.join(AssetPathService.instance.binDir, exe)),
        tryPath(() => p.join(AppDirs.bin, exe)),
        tryPath(() => p.join(AppDirs.support, 'binss', exe)),

        // Packaged macOS app bundle: Contents/MacOS/ffmpeg or Contents/Resources/bin/ffmpeg
        p.join(executableDir, exe),
        p.join(executableDir, '..', 'Resources', 'bin', exe),

        // Packaged Linux bundle: alongside the app binary or in bundle/bin
        p.join(executableDir, 'bin', exe),

        // Windows dynamic program files, root drives, and local app data paths
        if (Platform.isWindows) ...[
          'C:\\ffmpeg\\bin\\$exe',
          'D:\\ffmpeg\\bin\\$exe',
          if (Platform.environment['PROGRAMFILES'] != null)
            p.join(Platform.environment['PROGRAMFILES']!, 'ffmpeg', 'bin', exe),
          if (Platform.environment['ProgramFiles(x86)'] != null)
            p.join(Platform.environment['ProgramFiles(x86)']!, 'ffmpeg', 'bin', exe),
          if (Platform.environment['LOCALAPPDATA'] != null)
            p.join(Platform.environment['LOCALAPPDATA']!, 'Programs', 'ffmpeg', 'bin', exe),
        ],

        // Unix/macOS standard and package-manager locations
        if (!Platform.isWindows) ...[
          '/opt/homebrew/bin/$exe',
          '/usr/local/bin/$exe',
          '/usr/bin/$exe',
          '/snap/bin/$exe',
        ],
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
