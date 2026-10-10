---
name: whisper-stt
description: >-
  Deep integration guide for Whisper speech recognition in CapStudio: GGML models,
  quantized inference, native C++ FFI bindings, Web Transformers.js fallback, word timestamps,
  VAD, and language detection.
---

# Whisper Speech-to-Text Integration in CapStudio

CapStudio's core transcription engine is designed to be **100% offline, private, and local-first**. Audio never leaves the user's device.

## Architecture Overview

```
                      ┌─────────────────────────┐
                      │    TranscribeRequest    │
                      └────────────┬────────────┘
                                   │
                     Is Platform Web or Native?
                      /                         \
            [Native Desktop/Mobile]             [Web WASM]
                    │                               │
        ┌───────────▼───────────┐       ┌───────────▼───────────┐
        │   WhisperFfiService   │       │   WhisperWebService   │
        │ (libwhisper.so/dll/dylib)     │  (Transformers.js /   │
        │  via whisper.cpp FFI  │       │   ONNX Web Runtime)   │
        └───────────┬───────────┘       └───────────┬───────────┘
                    │                               │
                    └──────────────┬────────────────┘
                                   ▼
                      ┌─────────────────────────┐
                      │ Word-level Timestamps & │
                      │   Confidence Scoring    │
                      └─────────────────────────┘
```

## Key Components

1. **`WhisperService` (`lib/core/whisper/whisper_service.dart`)**:
   - Facade service managing model download, language detection, process execution, and FFI lifecycle.
2. **`WhisperFfiService` (`lib/core/whisper/whisper_ffi_service.dart`)**:
   - Direct C++ FFI interop with `whisper.cpp` dynamic library.
   - Allocates `whisper_context` and passes raw 16kHz mono audio PCM float arrays.
3. **`WhisperMobileService` (`lib/core/whisper/whisper_mobile_service.dart`)**:
   - Interacts with `whisper.xcframework` on iOS and JNI native libraries on Android.
4. **`WhisperFfiCancellationToken`**:
   - Provides safe mid-stream cancellation of native transcription loops without memory leaks or crashes.

## Supported Whisper Models

Models are stored in `AppDirs.models` (`%APPDATA%\CapStudio\models\` on Windows, `~/Library/Application Support/CapStudio/models/` on macOS, `~/.local/share/CapStudio/models/` on Linux):

| Model Name | Size | RAM Required | Best Use Case |
| :--- | :--- | :--- | :--- |
| `tiny` / `tiny.en` | ~75 MB | ~390 MB | Instant preview, low-spec mobile/embedded devices |
| `base` / `base.en` | ~142 MB | ~500 MB | Fast general transcription (default) |
| `small` / `small.en` | ~466 MB | ~1.0 GB | High accuracy multilingual transcription |
| `medium` / `medium.en` | ~1.5 GB | ~2.6 GB | Professional studio subtitles |
| `large-v3-turbo` | ~1.6 GB | ~2.8 GB | State-of-the-art accuracy with fast turbo decoder |

## Web Transcription Fallback

On Web builds (`kIsWeb`), native FFI is unavailable:
- CapStudio loads `web/whisper_web.js` running in a dedicated Web Worker.
- Uses `@xenova/transformers` ONNX quantized weights (`whisper-tiny.en` or `whisper-base`).
- Audio is sampled using `AudioContext` and processed without blocking the main browser thread.
- Native GGML binaries (`ggml-tiny.bin`) are excluded from web zip distributions to save 75 MB of bandwidth.

## Development Rules
- **Audio Pre-processing**: Whisper strictly requires 16,000 Hz, 16-bit, mono PCM audio. When extracting audio from video via FFmpeg:
  ```bash
  ffmpeg -i input.mp4 -ar 16000 -ac 1 -c:a pcm_s16le output.wav
  ```
- **Cancellation Safety**: Always pass a `WhisperFfiCancellationToken` when initiating transcription. If the user cancels the job, call `token.cancel()` and await clean teardown.
- **Memory Freeing**: Never omit `whisper_free(ctx)` in FFI service dispose routines.
