import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import '../logger/logger_service.dart';
import '../settings/settings_service.dart';
import 'whisper_ffi_bindings.dart';
import 'whisper_service.dart';

/// Thrown when an FFI transcription is aborted by user cancellation.
class TranscriptionCancelledException implements Exception {
  final String message;
  const TranscriptionCancelledException([this.message = 'Transcription was cancelled by user.']);

  @override
  String toString() => 'TranscriptionCancelledException: $message';
}

/// Thread-safe and isolate-safe cancellation token backed by native heap memory.
///
/// Because native memory allocated with [calloc] is accessible across all
/// Dart isolates in the process, passing [address] into the background isolate
/// allows `abort_callback` to check the cancellation flag without locking.
class WhisperFfiCancellationToken {
  Pointer<Int8>? _flagPtr;

  WhisperFfiCancellationToken() {
    _flagPtr = calloc<Int8>();
    _flagPtr!.value = 0;
  }

  int get address => _flagPtr?.address ?? 0;

  bool get isCancelled => _flagPtr != null && _flagPtr!.value != 0;

  void cancel() {
    if (_flagPtr != null && _flagPtr!.address != 0) {
      _flagPtr!.value = 1;
    }
  }

  void dispose() {
    if (_flagPtr != null && _flagPtr!.address != 0) {
      calloc.free(_flagPtr!);
      _flagPtr = null;
    }
  }
}

typedef WhisperProgressCallbackNative = Void Function(
  Pointer<WhisperContext> ctx,
  Pointer<Void> state,
  Int32 progress,
  Pointer<Void> userData,
);

typedef GgmlAbortCallbackNative = Bool Function(Pointer<Void> data);

class WhisperFfiService {
  WhisperFfiService._internal();
  static final WhisperFfiService instance = WhisperFfiService._internal();

  WhisperFfiCancellationToken? _activeCancellationToken;

  /// Cancels any currently active FFI transcription immediately.
  void cancelActiveTranscription() {
    _activeCancellationToken?.cancel();
  }

  @visibleForTesting
  static bool disableFfiForTesting =
      !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  bool _isInitialized = false;

  // Symbols the background-isolate transcription path needs. isAvailable
  // probes these on the main isolate so a missing/incompatible DLL is
  // reported up front; the bindings themselves are resolved inside the
  // isolate in _transcribeFfiInIsolate.
  static const List<String> _requiredSymbols = [
    'whisper_print_system_info',
    'whisper_init_from_file_with_params',
    'whisper_free',
    'whisper_context_default_params_by_ref',
    'whisper_full_default_params_by_ref',
    'whisper_full',
    'whisper_full_n_segments',
    'whisper_full_n_tokens',
    'whisper_full_get_token_text',
    'whisper_full_get_token_data',
    'whisper_token_eot',
    'whisper_full_lang_id',
    'whisper_lang_str',
  ];

  bool get isAvailable {
    if (disableFfiForTesting) return false;
    if (_isInitialized) return true;
    try {
      _initDylib();
      return _isInitialized;
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'WhisperFfiService',
          'FFI library not available: $e');
      return false;
    }
  }

  void _initDylib() {
    if (_isInitialized) return;

    final path = _ffiLibraryPath();
    LoggerService.instance.log(LogLevel.info, 'WhisperFfiService',
        'Loading shared library from: $path');

    final dylib = DynamicLibrary.open(path);
    for (final symbol in _requiredSymbols) {
      dylib.lookup(symbol); // Throws ArgumentError if the symbol is missing.
    }

    _isInitialized = true;
    final printSystemInfo = dylib
        .lookup<NativeFunction<whisper_print_system_info_df>>(
            'whisper_print_system_info')
        .asFunction<whisper_print_system_info_df_dart>();
    final sysInfo = printSystemInfo().toDartString();
    LoggerService.instance.log(LogLevel.info, 'WhisperFfiService',
        'FFI library loaded successfully. System info: $sysInfo');
  }

  /// Run local FFI transcription on the WAV file.
  ///
  /// The heavy work — reading the (potentially 100+ MB) WAV file and the
  /// synchronous `whisper_full` call, which can take minutes for long audio —
  /// runs inside a background isolate via [Isolate.run] so the UI isolate is
  /// never blocked. Only the resulting JSON string crosses back to the caller.
  ///
  /// Note: the isolate has a fresh heap, so the settings singleton there is
  /// uninitialized. All settings (thread count, VAD, language) are therefore
  /// resolved here, on the caller isolate, and passed in as plain values.
  Future<TranscriptionResult> transcribe({
    required String wavPath,
    required String modelPath,
    String? language,
    bool? translate,
    int? threads,
    bool? useVad,
    double? vadThreshold,
    double? expectedDuration,
    void Function(int progress)? onProgress,
    WhisperFfiCancellationToken? cancellationToken,
  }) async {
    int activeThreads = threads ?? SettingsService.instance.whisperThreads;
    if (activeThreads <= 0) {
      activeThreads = (Platform.numberOfProcessors - 1).clamp(1, 16);
    }

    LoggerService.instance.log(LogLevel.action, 'WhisperFfiService',
        'Starting FFI transcription in background isolate ($activeThreads threads).');

    final token = cancellationToken ?? WhisperFfiCancellationToken();
    final bool ownsToken = cancellationToken == null;
    _activeCancellationToken = token;

    final receivePort = ReceivePort();
    StreamSubscription<dynamic>? sub;
    if (onProgress != null) {
      sub = receivePort.listen((message) {
        if (message is int) {
          onProgress(message);
        }
      });
    }

    try {
      if (token.isCancelled) {
        throw const TranscriptionCancelledException();
      }

      final sendPort = receivePort.sendPort;
      final int cancelAddress = token.address;

      final String jsonContent =
          await Isolate.run(() => _transcribeFfiInIsolate(
                wavPath: wavPath,
                modelPath: modelPath,
                language: language,
                translate: translate ?? false,
                threads: activeThreads,
                useVad: useVad ?? false,
                vadThreshold: vadThreshold ?? 0.5,
                progressSendPort: sendPort,
                cancelAddress: cancelAddress,
              ));

      LoggerService.instance.log(LogLevel.trace, 'WhisperFfiService',
          'FFI transcription completed successfully');

      // Parse JSON through the shared parser on the caller isolate.
      return WhisperService.instance
          .parseTranscriptionJson(jsonContent, expectedDuration);
    } finally {
      await sub?.cancel();
      receivePort.close();
      if (identical(_activeCancellationToken, token)) {
        _activeCancellationToken = null;
      }
      if (ownsToken) {
        token.dispose();
      }
    }
  }
}

/// Resolves the whisper native library path (dev-tree and packaged-app
/// locations). Shared between the main-isolate availability probe and the
/// background-isolate transcription entry point.
String _ffiLibraryPath() {
  final exeDir = p.dirname(Platform.resolvedExecutable);
  if (Platform.isWindows) {
    final appDll = p.join(exeDir, 'whisper.dll');
    if (File(appDll).existsSync()) return appDll;
    final localDll =
        p.join(Directory.current.path, 'windows', 'runner', 'whisper.dll');
    if (File(localDll).existsSync()) return localDll;
    return 'whisper.dll';
  } else if (Platform.isMacOS) {
    final appDylib = p.join(exeDir, 'libwhisper.dylib');
    if (File(appDylib).existsSync()) return appDylib;
    final localDylib =
        p.join(Directory.current.path, 'macos', 'libwhisper.dylib');
    if (File(localDylib).existsSync()) return localDylib;
    return 'libwhisper.dylib';
  } else {
    final appSo = p.join(exeDir, 'libwhisper.so');
    if (File(appSo).existsSync()) return appSo;
    final localSo = p.join(Directory.current.path, 'linux', 'libwhisper.so');
    if (File(localSo).existsSync()) return localSo;
    return 'libwhisper.so';
  }
}

/// Parses raw 16kHz mono 16-bit PCM WAV file to a Float32 buffer for Whisper.
/// Runs inside the background isolate, so the synchronous file read never
/// blocks the UI.
Float32List _readWavPcm(String wavPath) {
  final bytes = File(wavPath).readAsBytesSync();
  if (bytes.length < 44) {
    throw FormatException(
        'WAV file too short to contain a valid header: $wavPath');
  }

  final byteData = ByteData.sublistView(bytes);

  // Verify RIFF & WAVE signatures
  final chunkId = String.fromCharCodes(bytes.sublist(0, 4));
  final format = String.fromCharCodes(bytes.sublist(8, 12));
  if (chunkId != 'RIFF' || format != 'WAVE') {
    throw const FormatException('Invalid RIFF/WAVE header signature');
  }

  // Traverse subchunks to locate 'data' chunk
  int offset = 12;
  int dataOffset = -1;
  int dataSize = -1;

  while (offset + 8 <= bytes.length) {
    final subChunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final subChunkSize = byteData.getUint32(offset + 4, Endian.little);

    if (subChunkId == 'data') {
      dataOffset = offset + 8;
      dataSize = subChunkSize;
      break;
    }

    offset += 8 + subChunkSize + (subChunkSize % 2);
  }

  if (dataOffset == -1 || dataSize == -1) {
    // Fallback: if subchunk parsing fails but it's a standard simple WAV, data usually starts at 44
    dataOffset = 44;
    dataSize = bytes.length - 44;
  }

  final int sampleCount = dataSize ~/ 2; // 16-bit samples = 2 bytes each
  final Float32List pcmf32 = Float32List(sampleCount);

  for (int i = 0; i < sampleCount; i++) {
    final int byteIdx = dataOffset + (i * 2);
    if (byteIdx + 2 > bytes.length) break;
    // Read 16-bit signed integer
    final int sample = byteData.getInt16(byteIdx, Endian.little);
    // Normalize to float -1.0 to 1.0
    pcmf32[i] = sample / 32768.0;
  }

  return pcmf32;
}

/// Opens the whisper shared library in THIS isolate, transcribes [wavPath],
/// and returns the JSON string in whisper-cli -ojf compatible format.
///
/// This is the [Isolate.run] entry point: it must be a top-level function and
/// must not touch any per-isolate singleton state (LoggerService,
/// SettingsService, WhisperService). All inputs are plain values; the only
/// cross-isolate output is the JSON string.
String _transcribeFfiInIsolate({
  required String wavPath,
  required String modelPath,
  String? language,
  required bool translate,
  required int threads,
  required bool useVad,
  required double vadThreshold,
  SendPort? progressSendPort,
  int cancelAddress = 0,
}) {
  final dylib = DynamicLibrary.open(_ffiLibraryPath());

  final initFromFileWithParams = dylib
      .lookup<NativeFunction<whisper_init_from_file_with_params_df>>(
          'whisper_init_from_file_with_params')
      .asFunction<whisper_init_from_file_with_params_df_dart>();
  final freeContext = dylib
      .lookup<NativeFunction<whisper_free_df>>('whisper_free')
      .asFunction<whisper_free_df_dart>();
  final contextDefaultParamsByRef = dylib
      .lookup<NativeFunction<whisper_context_default_params_by_ref_df>>(
          'whisper_context_default_params_by_ref')
      .asFunction<whisper_context_default_params_by_ref_df_dart>();
  final fullDefaultParamsByRef = dylib
      .lookup<NativeFunction<whisper_full_default_params_by_ref_df>>(
          'whisper_full_default_params_by_ref')
      .asFunction<whisper_full_default_params_by_ref_df_dart>();
  final full = dylib
      .lookup<NativeFunction<whisper_full_df>>('whisper_full')
      .asFunction<whisper_full_df_dart>();
  final fullNSegments = dylib
      .lookup<NativeFunction<whisper_full_n_segments_df>>(
          'whisper_full_n_segments')
      .asFunction<whisper_full_n_segments_df_dart>();
  final fullNTokens = dylib
      .lookup<NativeFunction<whisper_full_n_tokens_df>>('whisper_full_n_tokens')
      .asFunction<whisper_full_n_tokens_df_dart>();
  final fullGetTokenText = dylib
      .lookup<NativeFunction<whisper_full_get_token_text_df>>(
          'whisper_full_get_token_text')
      .asFunction<whisper_full_get_token_text_df_dart>();
  final fullGetTokenData = dylib
      .lookup<NativeFunction<whisper_full_get_token_data_df>>(
          'whisper_full_get_token_data')
      .asFunction<whisper_full_get_token_data_df_dart>();
  final tokenEot = dylib
      .lookup<NativeFunction<whisper_token_eot_df>>('whisper_token_eot')
      .asFunction<whisper_token_eot_df_dart>();
  final fullLangId = dylib
      .lookup<NativeFunction<whisper_full_lang_id_df>>('whisper_full_lang_id')
      .asFunction<whisper_full_lang_id_df_dart>();
  final langStr = dylib
      .lookup<NativeFunction<whisper_lang_str_df>>('whisper_lang_str')
      .asFunction<whisper_lang_str_df_dart>();

  final pcmSamples = _readWavPcm(wavPath);

  // 1. Initialize Whisper Context with default params
  final modelPathPtr = modelPath.toNativeUtf8();
  final ctxParamsPtr = contextDefaultParamsByRef();

  // Explicitly enforce CPU execution on desktop FFI for maximum model compatibility
  ctxParamsPtr.ref.use_gpu = false;

  final ctx = initFromFileWithParams(modelPathPtr, ctxParamsPtr.ref);

  calloc.free(modelPathPtr);

  if (ctx.address == 0) {
    throw StateError(
        'Failed to initialize whisper_context from model: $modelPath');
  }

  Pointer<Float>? samplesPtr;
  Pointer<WhisperFullParams>? paramsPtr;
  NativeCallable<WhisperProgressCallbackNative>? progressCallable;
  NativeCallable<GgmlAbortCallbackNative>? abortCallable;

  try {
    // 2. Allocate PCM samples in native memory
    samplesPtr = calloc<Float>(pcmSamples.length);
    final Float32List pointerFloats = samplesPtr.asTypedList(pcmSamples.length);
    for (int i = 0; i < pcmSamples.length; i++) {
      pointerFloats[i] = pcmSamples[i];
    }

    // 3. Configure full parameters
    paramsPtr = fullDefaultParamsByRef(0); // 0 = WHISPER_SAMPLING_GREEDY

    paramsPtr.ref.print_realtime = false;
    paramsPtr.ref.print_progress = false;
    paramsPtr.ref.print_timestamps = false;
    paramsPtr.ref.print_special = false;
    paramsPtr.ref.translate = translate;
    paramsPtr.ref.token_timestamps = true; // Word-level timings
    paramsPtr.ref.thold_pt = 0.01;
    paramsPtr.ref.max_len = 0;

    // Handle language
    final lang = (language != null && language.isNotEmpty) ? language : 'auto';
    paramsPtr.ref.language = lang.toNativeUtf8();

    paramsPtr.ref.n_threads = threads;

    if (useVad) {
      paramsPtr.ref.vad = true;
      paramsPtr.ref.vad_params.threshold = vadThreshold;
    }

    // Configure progress callback
    if (progressSendPort != null) {
      progressCallable =
          NativeCallable<WhisperProgressCallbackNative>.isolateLocal(
        (Pointer<WhisperContext> ctx, Pointer<Void> state, int progress,
            Pointer<Void> userData) {
          progressSendPort.send(progress);
        },
      );
      paramsPtr.ref.progress_callback =
          progressCallable.nativeFunction.cast<Void>();
    }

    // Configure abort callback
    if (cancelAddress != 0) {
      abortCallable = NativeCallable<GgmlAbortCallbackNative>.isolateLocal(
        (Pointer<Void> data) {
          if (data.address != 0) {
            final flag = data.cast<Int8>();
            return flag.value != 0;
          }
          return false;
        },
        exceptionalReturn: false,
      );
      paramsPtr.ref.abort_callback = abortCallable.nativeFunction.cast<Void>();
      paramsPtr.ref.abort_callback_user_data =
          Pointer<Void>.fromAddress(cancelAddress);
    }

    // Check cancellation before starting inference
    if (cancelAddress != 0 &&
        Pointer<Int8>.fromAddress(cancelAddress).value != 0) {
      throw const TranscriptionCancelledException();
    }

    final int res = full(ctx, paramsPtr, samplesPtr, pcmSamples.length);

    // Check cancellation after whisper_full returns
    if (cancelAddress != 0 &&
        Pointer<Int8>.fromAddress(cancelAddress).value != 0) {
      throw const TranscriptionCancelledException();
    }

    if (res != 0) {
      throw ProcessException('whisper.dll', [],
          'FFI transcription whisper_full call failed.', res);
    }

    // 4. Retrieve results and construct JSON string matching CLI output
    final List<Map<String, dynamic>> wordsJson = [];
    final int nSegments = fullNSegments(ctx);
    final int eotToken = tokenEot(ctx);

    for (int i = 0; i < nSegments; i++) {
      final int nTokens = fullNTokens(ctx, i);
      for (int j = 0; j < nTokens; j++) {
        final tokenData = fullGetTokenData(ctx, i, j);
        final textPtr = fullGetTokenText(ctx, i, j);

        if (tokenData.id >= eotToken) continue;

        final text = textPtr.toDartString();
        if (text.isEmpty || text == ' ') continue;

        // Timestamps in milliseconds (t0/t1 from Whisper are centiseconds)
        final int t0 = tokenData.t0 * 10;
        final int t1 = tokenData.t1 * 10;
        final double p = tokenData.p;

        wordsJson.add({
          'text': text,
          'timestamps': {'from': t0, 'to': t1},
          'p': p,
        });
      }
    }

    final langId = fullLangId(ctx);
    final langStrPtr = langStr(langId);
    final detectedLang =
        langStrPtr.address != 0 ? langStrPtr.toDartString() : 'en';

    final Map<String, dynamic> outputMap = {
      'transcription': wordsJson,
      'language': detectedLang,
    };

    // 5. Clean up language pointer
    if (paramsPtr.ref.language.address != 0) {
      calloc.free(paramsPtr.ref.language);
    }

    return jsonEncode(outputMap);
  } finally {
    // 6. Free all allocated native memory and callbacks
    progressCallable?.close();
    abortCallable?.close();
    if (samplesPtr != null) calloc.free(samplesPtr);
    freeContext(ctx);
  }
}
