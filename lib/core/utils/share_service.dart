import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:path/path.dart' as p;
import '../logger/logger_service.dart';

class ShareService {
  static const _channel = MethodChannel('com.capstudio/share');
  static const _nativeChannel = MethodChannel('com.capstudio/native');

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

  /// Save an exported video directly to the iOS Camera Roll or Android Gallery (Movies/CapStudio)
  static Future<bool> saveVideoToGallery(String filePath, {String? name, String? mimeType}) async {
    if (kIsWeb) return false;
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    final file = File(filePath);
    if (!file.existsSync()) {
      LoggerService.instance.log(
        LogLevel.error,
        'ShareService',
        'Save to gallery failed: File does not exist: $filePath',
      );
      return false;
    }

    try {
      final fileName = name ?? p.basename(filePath);
      final videoMimeType = mimeType ?? 'video/mp4';

      final res = await _nativeChannel.invokeMethod<bool>('saveVideoToGallery', {
        'path': filePath,
        'name': fileName,
        'mimeType': videoMimeType,
      });
      return res ?? false;
    } catch (e, stackTrace) {
      LoggerService.instance.log(
        LogLevel.error,
        'ShareService',
        'Failed to save video to gallery for $filePath: $e',
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
