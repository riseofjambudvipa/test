import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/downloader/binary_verifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BinaryVerifier Tests', () {
    test('returns true when verifyChecksumsEnabled is false (test mode)', () async {
      final result = await BinaryVerifier.verifyExecutableFormatAndSignature(
        'non_existent_file.exe',
        verifyChecksumsEnabled: false,
      );
      expect(result, isTrue);
    });

    test('returns false when file does not exist and verification enabled', () async {
      final result = await BinaryVerifier.verifyExecutableFormatAndSignature(
        'A:/non_existent_path/fake_binary.exe',
        verifyChecksumsEnabled: true,
      );
      expect(result, isFalse);
    });

    test('returns false when file is too short to have valid magic bytes', () async {
      final tempDir = Directory.systemTemp.createTempSync('capstudio_verifier_test');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final shortFile = File('${tempDir.path}/short.bin')..writeAsBytesSync([0x01, 0x02]);
      final result = await BinaryVerifier.verifyExecutableFormatAndSignature(
        shortFile.path,
        verifyChecksumsEnabled: true,
      );
      expect(result, isFalse);
    });
  });
}
