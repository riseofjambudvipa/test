// lib/core/utils/web_wasm_bridge_real.dart
import 'dart:async';
import 'dart:js_interop';

@JS('transcribeWeb')
external JSPromise _transcribeWebJs(
  JSString videoUrl,
  JSString modelName,
  JSString language,
  JSBoolean translate,
  JSFunction onProgressCallback,
);

@JS('exportVideoWeb')
external JSPromise _exportVideoWebJs(
  JSString videoUrl,
  JSString assContent,
  JSString optionsJson,
  JSFunction onProgressCallback,
);

class WebWasmBridge {
  static Future<String> transcribe({
    required String videoUrl,
    required String modelName,
    required String language,
    required bool translate,
    required void Function(double progress, String status) onProgress,
  }) async {
    final jsProgressCallback = ((JSNumber progress, JSString status) {
      onProgress(progress.toDartDouble, status.toDart);
    }).toJS;

    final promise = _transcribeWebJs(
      videoUrl.toJS,
      modelName.toJS,
      language.toJS,
      translate.toJS,
      jsProgressCallback,
    );

    final jsResult = await promise.toDart;
    return (jsResult as JSString).toDart;
  }

  static Future<String> exportVideo({
    required String videoUrl,
    required String assContent,
    required String optionsJson,
    required void Function(double progress, String status) onProgress,
  }) async {
    final jsProgressCallback = ((JSNumber progress, JSString status) {
      onProgress(progress.toDartDouble, status.toDart);
    }).toJS;

    final promise = _exportVideoWebJs(
      videoUrl.toJS,
      assContent.toJS,
      optionsJson.toJS,
      jsProgressCallback,
    );

    final jsResult = await promise.toDart;
    return (jsResult as JSString).toDart;
  }
}
