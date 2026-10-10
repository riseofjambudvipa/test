// lib/core/video/video_web_helper_web.dart
// ignore_for_file: uri_does_not_exist, avoid_web_libraries_in_flutter, deprecated_member_use, unawaited_futures
import 'dart:async';
import 'package:web/web.dart' as web;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';

String resolveWebVideoUrl(String path) {
  if (path.startsWith('blob:') || path.startsWith('http:') || path.startsWith('https:') || path.startsWith('data:')) {
    return path;
  }
  final baseOrigin = web.window.location.origin;
  if (path.startsWith('assets/')) {
    final assetPath = path.startsWith('assets/assets/') ? path : 'assets/$path';
    return '$baseOrigin/$assetPath';
  }
  final cleanPath = path.startsWith('/') ? path.substring(1) : path;
  return '$baseOrigin/$cleanPath';
}

bool checkVideoExistsWeb(String path) {
  return path.startsWith('blob:') || path.startsWith('http:') || path.startsWith('https:') || path.startsWith('assets/');
}

Future<({double duration, int width, int height})> getVideoMetadataWeb(String path) async {
  final lower = path.toLowerCase();
  final isDemoLandscape = lower.contains('demo') && lower.contains('landscape');
  final isDemoPortrait = lower.contains('demo') && (lower.contains('portrait') || lower.contains('protrait'));
  final double fallbackDuration = isDemoLandscape ? 19.87 : (isDemoPortrait ? 18.08 : 0.0);
  final int fallbackWidth = isDemoPortrait ? 1080 : 1920;
  final int fallbackHeight = isDemoPortrait ? 1920 : 1080;

  final resolved = resolveWebVideoUrl(path);
  final completer = Completer<({double duration, int width, int height})>();
  final video = web.document.createElement('video') as web.HTMLVideoElement;
  video.src = resolved;
  video.preload = 'metadata';

  // Set safety timeout of 5 seconds
  final timeout = Timer(const Duration(seconds: 5), () {
    if (!completer.isCompleted) {
      completer.complete((duration: fallbackDuration, width: fallbackWidth, height: fallbackHeight));
    }
  });

  void onMetadataReady() {
    timeout.cancel();
    if (!completer.isCompleted) {
      final w = video.videoWidth > 0 ? video.videoWidth : fallbackWidth;
      final h = video.videoHeight > 0 ? video.videoHeight : fallbackHeight;
      final d = (video.duration.isFinite && video.duration > 0) ? video.duration : fallbackDuration;
      completer.complete((duration: d, width: w, height: h));
    }
  }

  video.onloadedmetadata = ((web.Event event) => onMetadataReady()).toJS;
  video.onloadeddata = ((web.Event event) => onMetadataReady()).toJS;
  video.oncanplay = ((web.Event event) => onMetadataReady()).toJS;

  video.onerror = ((web.Event event) {
    timeout.cancel();
    if (!completer.isCompleted) {
      completer.complete((duration: fallbackDuration, width: fallbackWidth, height: fallbackHeight));
    }
  }).toJS;

  try {
    video.load();
    return await completer.future;
  } finally {
    video.src = '';
    try {
      video.load();
    } catch (e) {
      debugPrint('video.load() cleanup error on web: $e');
    }
  }
}

Future<double> getVideoDurationWeb(String path) async {
  final meta = await getVideoMetadataWeb(path);
  return meta.duration;
}

String createBlobUrlWeb(Uint8List bytes) {
  final blob = web.Blob([bytes.toJS].toJS);
  return web.URL.createObjectURL(blob);
}

String? getPlatformFilePathWeb(Object? platformFile) {
  try {
    if (platformFile == null) return null;

    // ignore: invalid_runtime_check_with_js_interop_types
    if (platformFile is JSObject) {
      final obj = platformFile;
      // 1. Try rawFile first to avoid loading bytes into memory (causes OOM for large files)
      final rawFile = obj.getProperty('rawFile'.toJS);
      if (rawFile.isDefinedAndNotNull) {
        return web.URL.createObjectURL(rawFile as web.Blob);
      }

      // 2. Try to get path from cross_file XFile object if available
      final xFile = obj.getProperty('xFile'.toJS);
      if (xFile.isDefinedAndNotNull && xFile.isA<JSObject>()) {
        final xPath = (xFile as JSObject).getProperty('path'.toJS);
        if (xPath.isDefinedAndNotNull) {
          final s = (xPath as JSString).toDart;
          if (s.isNotEmpty) return s;
        }
      }

      // 3. Fallback to path field
      final path = obj.getProperty('path'.toJS);
      if (path.isDefinedAndNotNull) {
        final s = (path as JSString).toDart;
        if (s.isNotEmpty) return s;
      }
    }

    // 4. Fallback to bytes only if absolutely necessary (can cause OOM on large files)
    try {
      final dynamic d = platformFile;
      final bytes = d.bytes as Uint8List?;
      if (bytes != null) {
        return createBlobUrlWeb(bytes);
      }
    } catch (_) {}
  } catch (e) {
    // ignore
  }
  return null;
}
