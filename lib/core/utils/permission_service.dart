import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:meta/meta.dart';

import '../logger/logger_service.dart';

class PermissionService {
  static const _channel = MethodChannel('com.capstudio.ai/permissions');

  /// Override for tests: set to `true` to simulate an Android device,
  /// `false` to simulate non-Android, or `null` to use the real platform value.
  @visibleForTesting
  static bool? mockIsAndroid;

  /// Whether the current runtime is Android (respects [mockIsAndroid] in tests).
  static bool get _isAndroid => mockIsAndroid ?? (!kIsWeb && Platform.isAndroid);

  /// Requests storage permissions if required by the system.
  /// On Android 11+, the app uses scoped app-specific storage paths which do not require
  /// special permissions, so this channel call checks/requests standard media access permissions.
  /// On all other platforms, returns true immediately.
  static Future<bool> requestStoragePermission() async {
    if (!_isAndroid) return true;

    try {
      final granted = await _channel.invokeMethod<bool>('requestStoragePermission');
      return granted ?? false;
    } catch (e) {
      // Fail-open: channel errors (e.g. in unit tests) don't block the import flow.
      LoggerService.instance.log(
        LogLevel.warning,
        'PermissionService',
        'requestStoragePermission channel call failed: $e. Assuming granted.',
      );
      return true;
    }
  }
}
