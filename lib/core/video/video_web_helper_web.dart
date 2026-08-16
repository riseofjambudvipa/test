// lib/core/video/video_web_helper_web.dart
// ignore_for_file: uri_does_not_exist, avoid_web_libraries_in_flutter, deprecated_member_use, unawaited_futures
import 'dart:async';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:js_util' as js_util;

bool checkVideoExistsWeb(String path) {
  return path.startsWith('blob:') || path.startsWith('http:') || path.startsWith('https:') || path.startsWith('assets/');
}

Future<double> getVideoDurationWeb(String path) async {
  final completer = Completer<double>();
  final video = web.document.createElement('video') as web.HTMLVideoElement;
  video.src = path;
  video.preload = 'metadata';
  
  // Set safety timeout of 5 seconds
  final timeout = Timer(const Duration(seconds: 5), () {
    if (!completer.isCompleted) {
      completer.complete(0.0);
    }
  });

  video.onloadedmetadata = ((web.Event event) {
    timeout.cancel();
    if (!completer.isCompleted) {
      completer.complete(video.duration);
    }
  }).toJS;

  video.onerror = ((web.Event event) {
    timeout.cancel();
    if (!completer.isCompleted) {
      completer.complete(0.0);
    }
  }).toJS;

  try {
    final duration = await completer.future;
    return duration;
  } finally {
    video.src = '';
    try {
      video.load();
    } catch (_) {}
  }
}

String createBlobUrlWeb(Uint8List bytes) {
  final blob = web.Blob([bytes.toJS].toJS);
  return web.URL.createObjectURL(blob);
}

String? getPlatformFilePathWeb(dynamic platformFile) {
  try {
    if (platformFile == null) return null;

    // 1. Try rawFile first to avoid loading bytes into memory (causes OOM for large files)
    final rawFile = js_util.getProperty(platformFile, 'rawFile');
    if (rawFile != null) {
      return web.URL.createObjectURL(rawFile as web.Blob);
    }

    // 2. Try to get path from cross_file XFile object if available
    final xFile = js_util.getProperty(platformFile, 'xFile');
    if (xFile != null) {
      final xPath = js_util.getProperty(xFile, 'path');
      if (xPath != null && xPath.toString().isNotEmpty) {
        return xPath.toString();
      }
    }

    // 3. Fallback to path field
    final path = js_util.getProperty(platformFile, 'path');
    if (path != null && path.toString().isNotEmpty) {
      return path.toString();
    }

    // 4. Fallback to bytes only if absolutely necessary (can cause OOM on large files)
    final bytes = js_util.getProperty(platformFile, 'bytes') as Uint8List?;
    if (bytes != null) {
      return createBlobUrlWeb(bytes);
    }
  } catch (e) {
    // ignore
  }
  return null;
}
