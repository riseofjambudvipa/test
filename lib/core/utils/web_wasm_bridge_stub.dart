// lib/core/utils/web_wasm_bridge_stub.dart
import 'dart:async';

class WebWasmBridge {
  static Future<String> transcribe({
    required String videoUrl,
    required String modelName,
    required String language,
    required bool translate,
    required void Function(double progress, String status) onProgress,
  }) {
    throw UnsupportedError('transcribe is only supported on Web');
  }

  static Future<String> exportVideo({
    required String videoUrl,
    required String assContent,
    required String optionsJson,
    required void Function(double progress, String status) onProgress,
  }) {
    throw UnsupportedError('exportVideo is only supported on Web');
  }
}
