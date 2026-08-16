// lib/core/video/video_web_helper_stub.dart
import 'dart:typed_data';

bool checkVideoExistsWeb(String path) {
  return false;
}

Future<double> getVideoDurationWeb(String path) async {
  return 0.0;
}

String createBlobUrlWeb(Uint8List bytes) {
  throw UnimplementedError('Web video helper is only supported on Web.');
}

String? getPlatformFilePathWeb(dynamic platformFile) {
  return null;
}
