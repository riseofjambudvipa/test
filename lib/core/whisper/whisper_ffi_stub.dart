import 'whisper_service.dart';

class TranscriptionCancelledException implements Exception {
  final String message;
  const TranscriptionCancelledException([this.message = 'Transcription was cancelled by user.']);

  @override
  String toString() => 'TranscriptionCancelledException: $message';
}

class WhisperFfiCancellationToken {
  WhisperFfiCancellationToken();
  int get address => 0;
  bool get isCancelled => false;
  void cancel() {}
  void dispose() {}
}

class WhisperFfiService {
  WhisperFfiService._internal();
  static final WhisperFfiService instance = WhisperFfiService._internal();

  bool get isAvailable => false;

  void cancelActiveTranscription() {}

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
  }) {
    throw UnsupportedError('Whisper FFI is not supported on this platform.');
  }
}
