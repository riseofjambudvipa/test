import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/downloader/archive_extractor.dart';
import 'package:capstudio/core/downloader/binary_download_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('archive_extractor_test_');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('ArchiveExtractor extracts valid zip archives and emits progress', () async {
    final zipFile = File(p.join(tempDir.path, 'valid.zip'));
    final archive = Archive();
    final fileContent = 'Hello CapStudio Archive Test'.codeUnits;
    archive.addFile(ArchiveFile('test_file.txt', fileContent.length, fileContent));
    archive.addFile(ArchiveFile('subfolder/nested.bin', fileContent.length, fileContent));
    final encoded = ZipEncoder().encode(archive);
    zipFile.writeAsBytesSync(encoded);

    final destDir = Directory(p.join(tempDir.path, 'output'))..createSync();
    final progressList = <BinaryDownloadProgress>[];

    await ArchiveExtractor.extractInIsolate(
      zipPath: zipFile.path,
      destDir: destDir.path,
      toolId: 'test_tool',
      emit: (p) => progressList.add(p),
    );

    expect(File(p.join(destDir.path, 'test_file.txt')).existsSync(), isTrue);
    expect(File(p.join(destDir.path, 'test_file.txt')).readAsStringSync(), 'Hello CapStudio Archive Test');
    expect(File(p.join(destDir.path, 'subfolder', 'nested.bin')).existsSync(), isTrue);
    expect(progressList.isNotEmpty, isTrue);
    expect(progressList.any((p) => p.status == BinaryDownloadStatus.extracting), isTrue);
  });

  test('ArchiveExtractor detects and blocks Zip Slip directory traversal', () async {
    final zipFile = File(p.join(tempDir.path, 'malicious.zip'));
    final archive = Archive();
    final fileContent = 'malicious payload'.codeUnits;
    archive.addFile(ArchiveFile('../../outside.txt', fileContent.length, fileContent));
    final encoded = ZipEncoder().encode(archive);
    zipFile.writeAsBytesSync(encoded);

    final destDir = Directory(p.join(tempDir.path, 'output'))..createSync();

    expect(
      () => ArchiveExtractor.extractInIsolate(
        zipPath: zipFile.path,
        destDir: destDir.path,
        toolId: 'malicious_tool',
        emit: (_) {},
      ),
      throwsA(isA<Exception>().having(
        (e) => e.toString(),
        'description',
        contains('Zip Slip'),
      )),
    );
  });
}
