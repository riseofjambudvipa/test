import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../logger/logger_service.dart';
import 'native_helper.dart' as native_helper;

/// Central source of truth for all CapStudio data directories.
///
/// On Windows, [getApplicationSupportDirectory] returns
/// `AppData\Roaming\<CompanyName>\<ProductName>`. When both are set to
/// "CapStudio" (Runner.rc default) the result is the ugly double-nested
/// `AppData\Roaming\CapStudio\CapStudio`. This helper normalises it to the
/// clean single-level `AppData\Roaming\CapStudio\`.
///
/// All services should call [AppDirs.support] instead of calling
/// [getApplicationSupportDirectory] directly.
class AppDirs {
  AppDirs._();

  static String? _supportPath;
  static String? _logsPath;
  static double? _mockAvailableDiskSpaceMB;

  /// Whether [AppDirs.init] or [setSupportPathForTesting] has completed.
  static bool get isInitialized => _supportPath != null;

  /// Override the support path for testing to prevent locking production AppData files.
  static void setSupportPathForTesting(String path) {
    _supportPath = path;
    _logsPath = p.join(path, 'logs');
  }

  /// Override the available disk space for testing.
  static void setMockAvailableDiskSpaceMB(double? mb) {
    _mockAvailableDiskSpaceMB = mb;
  }

  /// Initialise once at startup (called from main.dart before runApp).
  static Future<void> init() async {
    if (_supportPath != null) return;

    if (!kIsWeb && Platform.isWindows) {
      // Build `%APPDATA%\CapStudio` directly — single, clean folder.
      final appData = Platform.environment['APPDATA'];
      if (appData != null && appData.isNotEmpty && Directory(appData).existsSync()) {
        _supportPath = p.join(appData, 'CapStudio');
      }
    }

    // Fallback for non-Windows or if APPDATA is missing: use path_provider.
    if (_supportPath == null) {
      if (kIsWeb) {
        _supportPath = 'web_support';
      } else {
        final dir = await getApplicationSupportDirectory();
        _supportPath = dir.path;
      }
    }

    if (!kIsWeb) {
      // Ensure the root support dir exists.
      await Directory(_supportPath!).create(recursive: true);

      // Logs sub-directory.
      _logsPath = p.join(_supportPath!, 'logs');
      await Directory(_logsPath!).create(recursive: true);
    } else {
      _logsPath = p.join(_supportPath!, 'logs');
    }
  }

  /// `AppData\Roaming\CapStudio\` on Windows, platform equivalent elsewhere.
  static String get support {
    if (_supportPath == null) {
      throw StateError('AppDirs.init() has not been called or failed. '
          'Ensure AppDirs.init() completes successfully before accessing AppDirs.support.');
    }
    return _supportPath!;
  }

  /// `AppData\Roaming\CapStudio\logs\`
  static String get logs {
    if (_logsPath == null) {
      throw StateError('AppDirs.init() has not been called or failed. '
          'Ensure AppDirs.init() completes successfully before accessing AppDirs.logs.');
    }
    return _logsPath!;
  }

  /// `AppData\Roaming\CapStudio\bin\`
  static String get bin => p.join(support, 'bin');

  /// `AppData\Roaming\CapStudio\models\`
  static String get models => p.join(support, 'models');

  /// `AppData\Roaming\CapStudio\assets\`
  static String get assets => p.join(support, 'assets');

  /// `AppData\Roaming\CapStudio\fonts\`
  static String get fonts => p.join(support, 'fonts');

  /// Probe if the Microsoft Visual C++ Redistributable is installed on Windows.
  /// Checks for the presence of `vcruntime140.dll` in System32 or SysWOW64.
  static bool isWindowsVcRuntimeInstalled() {
    return native_helper.isWindowsVcRuntimeInstalled();
  }

  // ─── CPU Feature Detection ───────────────────────────────────────────────

  static bool? _hasAvx;

  /// Override the CPU AVX capability runtime cache.
  /// Clear the cache by passing null.
  static void setHasAvx(bool? value) {
    _hasAvx = value;
  }

  /// Returns true if the CPU supports AVX/AVX2 (Advanced Vector Extensions).
  static Future<bool> cpuSupportsAvx() async {
    if (kIsWeb) return false;
    if (_hasAvx != null) return _hasAvx!;
    _hasAvx = await native_helper.cpuSupportsAvx();
    return _hasAvx!;
  }

  /// Returns whether the host machine is running on Apple Silicon (macOS ARM64 / Rosetta).
  static bool isAppleSilicon() {
    if (kIsWeb) return false;
    return native_helper.isAppleSilicon();
  }

  /// Returns the host CPU architecture string (e.g. 'macos_arm64', 'windows_x64').
  static String getCpuArchitecture() {
    if (kIsWeb) return 'web';
    return native_helper.getCpuArchitecture();
  }

  // ─── Disk Space Caching ──────────────────────────────────────────────────

  /// Returns the available space on the disk partition of the given [path] in megabytes (MB).
  static Future<double> getAvailableDiskSpaceMB(String path) async {
    if (kIsWeb) return -1.0;
    if (_mockAvailableDiskSpaceMB != null) return _mockAvailableDiskSpaceMB!;
    return native_helper.getAvailableDiskSpaceMB(path);
  }

  /// Checks if there is at least [requiredMB] available disk space.
  static Future<bool> hasAvailableSpace(String path, double requiredMB) async {
    final available = await getAvailableDiskSpaceMB(path);
    if (available < 0.0) {
      // Fail-open: on web the probe is unsupported (-1). On native, a failed
      // probe means we cannot verify space; log it loudly so a silently full
      // disk doesn't turn into a confusing mid-download failure.
      if (!kIsWeb) {
        LoggerService.instance.log(LogLevel.warning, 'AppDirs',
            'Disk space probe failed for $path; assuming enough space.');
      }
      return true;
    }
    return available >= requiredMB;
  }
}
