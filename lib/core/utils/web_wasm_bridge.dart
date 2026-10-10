// lib/core/utils/web_wasm_bridge.dart
export 'web_wasm_bridge_stub.dart'
    if (dart.library.js_interop) 'web_wasm_bridge_real.dart'
    if (dart.library.html) 'web_wasm_bridge_real.dart';

