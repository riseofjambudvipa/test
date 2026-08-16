import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../logger/logger_service.dart';

class ShareService {
  static const _channel = MethodChannel('com.capstudio/share');

  /// Open iOS Share Sheet or Android share intent for a file
  static Future<bool> shareFile(String filePath, {String? mimeType}) async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    final file = File(filePath);
    if (!file.existsSync()) {
      LoggerService.instance.log(
        LogLevel.error,
        'ShareService',
        'Share failed: File does not exist on disk: $filePath',
      );
      return false;
    }

    try {
      await _channel.invokeMethod('shareFile', {
        'path': filePath,
        'mimeType': mimeType ?? 'application/octet-stream',
      });
      return true;
    } catch (e, stackTrace) {
      LoggerService.instance.log(
        LogLevel.error,
        'ShareService',
        'Native share channel invocation failed for $filePath: $e',
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
