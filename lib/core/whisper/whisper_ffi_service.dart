import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import '../logger/logger_service.dart';
import '../settings/settings_service.dart';
import 'whisper_ffi_bindings.dart';
import 'whisper_service.dart';

class WhisperFfiService {
  WhisperFfiService._internal();
  static final WhisperFfiService instance = WhisperFfiService._internal();

  @visibleForTesting
  static bool disableFfiForTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

  DynamicLibrary? _dylib;
  bool _isInitialized = false;

  // Bindings cache
  late whisper_print_system_info_df_dart _printSystemInfo;
  late whisper_init_from_file_with_params_df_dart _initFromFileWithParams;
  late whisper_free_df_dart _freeContext;
  late whisper_context_default_params_by_ref_df_dart _contextDefaultParamsByRef;
  late whisper_full_default_params_by_ref_df_dart _fullDefaultParamsByRef;
  late whisper_full_df_dart _full;
  late whisper_full_n_segments_df_dart _fullNSegments;
  late whisper_full_n_tokens_df_dart _fullNTokens;
  late whisper_full_get_token_text_df_dart _fullGetTokenText;
  late whisper_full_get_token_data_df_dart _fullGetTokenData;
  late whisper_token_eot_df_dart _tokenEot;
  late whisper_full_lang_id_df_dart _fullLangId;
  late whisper_lang_str_df_dart _langStr;

  bool get isAvailable {
    if (disableFfiForTesting) return false;
    if (_isInitialized) return true;
    try {
      _initDylib();
      return _isInitialized;
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'WhisperFfiService', 'FFI library not available: $e');
      return false;
    }
  }

  void _initDylib() {
    if (_isInitialized) return;

    final path = _getLibraryPath();
    LoggerService.instance.log(LogLevel.info, 'WhisperFfiService', 'Loading shared library from: $path');
    
    _dylib = DynamicLibrary.open(path);

    // Lookups
    _printSystemInfo = _dylib!
        .lookup<NativeFunction<whisper_print_system_info_df>>('whisper_print_system_info')
        .asFunction();
    _initFromFileWithParams = _dylib!
        .lookup<NativeFunction<whisper_init_from_file_with_params_df>>('whisper_init_from_file_with_params')
        .asFunction();
    _freeContext = _dylib!
        .lookup<NativeFunction<whisper_free_df>>('whisper_free')
        .asFunction();
    _contextDefaultParamsByRef = _dylib!
        .lookup<NativeFunction<whisper_context_default_params_by_ref_df>>('whisper_context_default_params_by_ref')
        .asFunction();
    _fullDefaultParamsByRef = _dylib!
        .lookup<NativeFunction<whisper_full_default_params_by_ref_df>>('whisper_full_default_params_by_ref')
        .asFunction();
    _full = _dylib!
        .lookup<NativeFunction<whisper_full_df>>('whisper_full')
        .asFunction();
    _fullNSegments = _dylib!
        .lookup<NativeFunction<whisper_full_n_segments_df>>('whisper_full_n_segments')
        .asFunction();
    _fullNTokens = _dylib!
        .lookup<NativeFunction<whisper_full_n_tokens_df>>('whisper_full_n_tokens')
        .asFunction();
    _fullGetTokenText = _dylib!
        .lookup<NativeFunction<whisper_full_get_token_text_df>>('whisper_full_get_token_text')
        .asFunction();
    _fullGetTokenData = _dylib!
        .lookup<NativeFunction<whisper_full_get_token_data_df>>('whisper_full_get_token_data')
        .asFunction();
    _tokenEot = _dylib!
        .lookup<NativeFunction<whisper_token_eot_df>>('whisper_token_eot')
        .asFunction();
    _fullLangId = _dylib!
        .lookup<NativeFunction<whisper_full_lang_id_df>>('whisper_full_lang_id')
        .asFunction();
    _langStr = _dylib!
        .lookup<NativeFunction<whisper_lang_str_df>>('whisper_lang_str')
        .asFunction();

    _isInitialized = true;
    final sysInfo = _printSystemInfo().toDartString();
    LoggerService.instance.log(LogLevel.info, 'WhisperFfiService', 'FFI library loaded successfully. System info: $sysInfo');
  }

  String _getLibraryPath() {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    if (Platform.isWindows) {
      final appDll = p.join(exeDir, 'whisper.dll');
      if (File(appDll).existsSync()) return appDll;
      final localDll = p.join(Directory.current.path, 'windows', 'runner', 'whisper.dll');
      if (File(localDll).existsSync()) return localDll;
      return 'whisper.dll';
    } else if (Platform.isMacOS) {
      final appDylib = p.join(exeDir, 'libwhisper.dylib');
      if (File(appDylib).existsSync()) return appDylib;
      final localDylib = p.join(Directory.current.path, 'macos', 'libwhisper.dylib');
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

  /// Parses raw 16kHz mono 16-bit PCM WAV file to a Float32 buffer for Whisper
  Float32List _readWavPCM(String wavPath) {
    final bytes = File(wavPath).readAsBytesSync();
    if (bytes.length < 44) {
      throw FormatException('WAV file too short to contain a valid header: $wavPath');
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
      
      offset += 8 + subChunkSize;
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

  /// Run local FFI transcription on the WAV file
  Future<TranscriptionResult> transcribe({
    required String wavPath,
    required String modelPath,
    String? language,
    bool? translate,
    int? threads,
    bool? useVad,
    double? vadThreshold,
    double? expectedDuration,
  }) async {
    _initDylib();

    LoggerService.instance.log(LogLevel.info, 'WhisperFfiService', 'Parsing WAV PCM audio samples: $wavPath');
    final pcmSamples = _readWavPCM(wavPath);
    LoggerService.instance.log(LogLevel.info, 'WhisperFfiService', 'Loaded ${pcmSamples.length} audio samples');

    // 1. Initialize Whisper Context with default params
    final modelPathPtr = modelPath.toNativeUtf8();
    final ctxParamsPtr = _contextDefaultParamsByRef();
    
    // Explicitly enforce CPU execution on desktop FFI for maximum model compatibility
    ctxParamsPtr.ref.use_gpu = false;

    LoggerService.instance.log(LogLevel.info, 'WhisperFfiService', 'Initializing whisper_context from model: $modelPath');
    final ctx = _initFromFileWithParams(modelPathPtr, ctxParamsPtr.ref);
    
    calloc.free(modelPathPtr);

    if (ctx.address == 0) {
      throw StateError('Failed to initialize whisper_context from model: $modelPath');
    }

    Pointer<Float>? samplesPtr;
    Pointer<WhisperFullParams>? paramsPtr;

    try {
      // 2. Allocate PCM samples in native memory
      samplesPtr = calloc<Float>(pcmSamples.length);
      final Float32List pointerFloats = samplesPtr.asTypedList(pcmSamples.length);
      for (int i = 0; i < pcmSamples.length; i++) {
        pointerFloats[i] = pcmSamples[i];
      }

      // 3. Configure full parameters
      paramsPtr = _fullDefaultParamsByRef(0); // 0 = WHISPER_SAMPLING_GREEDY
      
      paramsPtr.ref.print_realtime = false;
      paramsPtr.ref.print_progress = false;
      paramsPtr.ref.print_timestamps = false;
      paramsPtr.ref.print_special = false;
      paramsPtr.ref.translate = translate ?? false;
      paramsPtr.ref.token_timestamps = true; // Word-level timings
      paramsPtr.ref.thold_pt = 0.01;
      paramsPtr.ref.max_len = 0;

      // Handle language
      final lang = (language != null && language.isNotEmpty) ? language : 'auto';
      paramsPtr.ref.language = lang.toNativeUtf8();

      // Threads
      int activeThreads = threads ?? SettingsService.instance.whisperThreads;
      if (activeThreads <= 0) {
        activeThreads = (Platform.numberOfProcessors - 1).clamp(1, 16);
      }
      paramsPtr.ref.n_threads = activeThreads;

      if (useVad == true) {
        paramsPtr.ref.vad = true;
        paramsPtr.ref.vad_params.threshold = vadThreshold ?? 0.5;
      }

      LoggerService.instance.log(LogLevel.action, 'WhisperFfiService', 'Running whisper_full with $activeThreads threads (Language: $lang)');
      
      final int res = _full(ctx, paramsPtr, samplesPtr, pcmSamples.length);
      if (res != 0) {
        throw ProcessException('whisper.dll', [], 'FFI transcription whisper_full call failed.', res);
      }

      // 4. Retrieve results and construct JSON string matching CLI output
      final List<Map<String, dynamic>> wordsJson = [];
      final int nSegments = _fullNSegments(ctx);
      final int eotToken = _tokenEot(ctx);

      for (int i = 0; i < nSegments; i++) {
        final int nTokens = _fullNTokens(ctx, i);
        for (int j = 0; j < nTokens; j++) {
          final tokenData = _fullGetTokenData(ctx, i, j);
          final textPtr = _fullGetTokenText(ctx, i, j);
          
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

      final langId = _fullLangId(ctx);
      final langStrPtr = _langStr(langId);
      final detectedLang = langStrPtr.address != 0 ? langStrPtr.toDartString() : 'en';

      final Map<String, dynamic> outputMap = {
        'transcription': wordsJson,
        'language': detectedLang,
      };

      final jsonContent = jsonEncode(outputMap);
      LoggerService.instance.log(LogLevel.trace, 'WhisperFfiService', 'FFI transcription completed successfully');

      // 5. Clean up language pointer
      if (paramsPtr.ref.language.address != 0) {
        calloc.free(paramsPtr.ref.language);
      }

      // Parse JSON through standard parser
      return WhisperService.instance.parseTranscriptionJson(jsonContent, expectedDuration);
    } finally {
      // 6. Free all allocated native memory
      if (samplesPtr != null) calloc.free(samplesPtr);
      _freeContext(ctx);
    }
  }
}
