import 'whisper_service.dart';

class WhisperFfiService {
  WhisperFfiService._internal();
  static final WhisperFfiService instance = WhisperFfiService._internal();

  bool get isAvailable => false;

  Future<TranscriptionResult> transcribe({
    required String wavPath,
    required String modelPath,
    String? language,
    bool? translate,
    int? threads,
    bool? useVad,
    double? vadThreshold,
    double? expectedDuration,
  }) {
    throw UnsupportedError('Whisper FFI is not supported on this platform.');
  }
}
