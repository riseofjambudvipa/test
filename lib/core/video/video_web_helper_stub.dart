// lib/core/video/video_web_helper_stub.dart
import 'dart:typed_data';

String resolveWebVideoUrl(String path) => path;

bool checkVideoExistsWeb(String path) {
  return false;
}

Future<double> getVideoDurationWeb(String path) async {
  return 0.0;
}

Future<({double duration, int width, int height})> getVideoMetadataWeb(String path) async {
  return (duration: 0.0, width: 1920, height: 1080);
}

String createBlobUrlWeb(Uint8List bytes) {
  throw UnimplementedError('Web video helper is only supported on Web.');
}

String? getPlatformFilePathWeb(Object? platformFile) {
  return null;
}
