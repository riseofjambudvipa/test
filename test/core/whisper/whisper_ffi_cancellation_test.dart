import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/whisper/whisper_service.dart';
import '../../test_environment.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  registerTestEnvironment(silenceLogs: true);

  group('WhisperFfiCancellationToken & Cancellation Exception Tests', () {
    test('TranscriptionCancelledException should construct with default and custom messages', () {
      const defaultException = TranscriptionCancelledException();
      expect(defaultException.message, 'Transcription was cancelled by user.');
      expect(defaultException.toString(), contains('Transcription was cancelled by user.'));

      const customException = TranscriptionCancelledException('Aborted during VAD phase');
      expect(customException.message, 'Aborted during VAD phase');
      expect(customException.toString(), 'TranscriptionCancelledException: Aborted during VAD phase');
    });

    test('WhisperFfiCancellationToken lifecycle: create, cancel, and dispose', () {
      final token = WhisperFfiCancellationToken();
      try {
        expect(token.isCancelled, isFalse);
        expect(token.address, isNonZero);

        // Cancel the token
        token.cancel();
        expect(token.isCancelled, isTrue);

        // Multiple cancel calls are idempotent
        token.cancel();
        expect(token.isCancelled, isTrue);
      } finally {
        token.dispose();
      }

      // After dispose, pointer is freed
      expect(token.address, 0);
      expect(token.isCancelled, isFalse);

      // Multiple dispose calls are safe
      expect(() => token.dispose(), returnsNormally);
    });

    test('WhisperService.cancelActiveTranscription invokes WhisperFfiService.cancelActiveTranscription cleanly', () {
      final whisperService = WhisperService.instance;
      expect(() => whisperService.cancelActiveTranscription(), returnsNormally);
      expect(() => WhisperFfiService.instance.cancelActiveTranscription(), returnsNormally);
    });
  });
}
