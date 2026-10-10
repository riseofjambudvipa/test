// lib/core/video/video_web_helper.dart
export 'video_web_helper_stub.dart'
    if (dart.library.js_interop) 'video_web_helper_web.dart'
    if (dart.library.html) 'video_web_helper_web.dart';

