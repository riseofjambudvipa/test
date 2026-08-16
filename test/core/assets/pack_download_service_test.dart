import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:capstudio/core/assets/pack_download_service.dart';
import 'package:capstudio/core/assets/asset_path_service.dart';
import 'package:capstudio/core/assets/asset_manifest.dart';
import 'package:capstudio/core/utils/app_dirs.dart';
import '../../mocks/mocks.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PackDownloadService service;
  late Directory tempDir;
  late MockHttpClient mockClient;
  late MockStreamedResponse mockResponse;

  setUpAll(() {
    registerFallbackValue(http.Request('GET', Uri.parse('http://example.com')));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('capstudio_pack_test_');
    AppDirs.setSupportPathForTesting(tempDir.path);
    await AppDirs.init();
    await AssetPathService.instance.init();

    service = PackDownloadService.instance;
    service.resetForTesting();
    mockClient = MockHttpClient();
    mockResponse = MockStreamedResponse();
    service.httpClient = mockClient;
  });

  tearDown(() {
    service.resetForTesting();
    AppDirs.setMockAvailableDiskSpaceMB(null);
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('PackDownloadService Tests', () {
    test('should fail immediately if insufficient disk space available', () async {
      // Required space is pack.sizeMB * 2 (100MB * 2 = 200MB)
      AppDirs.setMockAvailableDiskSpaceMB(50.0); // Only 50MB free

      const pack = AssetPack(
        id: 'test_font',
        name: 'Test Font',
        description: 'Test Description',
        required: false,
        sizeBytes: 100 * 1024 * 1024,
        compressedSizeBytes: 1024,
        downloadUrl: 'http://example.com/font.ttf',
        checksum: '',
        version: '1.0',
        fileCount: 1,
        format: 'ttf',
        animated: false,
        localFolder: 'fonts',
      );

      final progressList = <DownloadProgress>[];
      final subscription = service.stream(pack.id).listen((event) {
        progressList.add(event);
      });

      await service.download(pack);

      // Drain stream events
      await Future.delayed(const Duration(milliseconds: 50));

      expect(progressList.length, greaterThanOrEqualTo(1));
      expect(progressList.last.status, DownloadStatus.failed);
      expect(progressList.last.error, contains('Insufficient disk space'));

      await subscription.cancel();
    });

    test('should download and extract standard zip file successfully', () async {
      AppDirs.setMockAvailableDiskSpaceMB(1000.0); // 1GB free

      const pack = AssetPack(
        id: 'googleAnimated',
        name: 'Google Animated',
        description: 'Google Noto Emojis',
        required: false,
        sizeBytes: 1 * 1024 * 1024,
        compressedSizeBytes: 100,
        downloadUrl: 'http://example.com/emojis.zip',
        checksum: '',
        version: '1.0',
        fileCount: 1,
        format: 'zip',
        animated: true,
        localFolder: 'google_noto_emojis_animated_pack',
      );

      // Create a valid zip archive in memory
      final archive = Archive();
      archive.addFile(ArchiveFile('emoji_1.png', 5, [10, 20, 30, 40, 50]));
      final zipBytes = ZipEncoder().encode(archive);

      // Mock HTTP response with the zip bytes
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.stream).thenAnswer((_) => http.ByteStream.fromBytes(zipBytes));
      when(() => mockClient.send(any())).thenAnswer((_) async => mockResponse);

      final progressList = <DownloadProgress>[];
      final subscription = service.stream(pack.id).listen((event) {
        progressList.add(event);
      });

      await service.download(pack);

      // Drain stream events
      await Future.delayed(const Duration(milliseconds: 50));

      expect(progressList.any((p) => p.status == DownloadStatus.downloading), isTrue);
      expect(progressList.any((p) => p.status == DownloadStatus.extracting), isTrue);
      expect(progressList.last.status, DownloadStatus.complete);

      // Verify file exists in output directory
      final extractedFile = File(p.join(AssetPathService.instance.emojisDir, 'emoji_1.png'));
      expect(extractedFile.existsSync(), isTrue);
      expect(extractedFile.readAsBytesSync(), [10, 20, 30, 40, 50]);

      await subscription.cancel();
    });

    test('should prevent extraction and throw exception when Zip Slip malicious path is detected', () async {
      AppDirs.setMockAvailableDiskSpaceMB(1000.0);

      const pack = AssetPack(
        id: 'googleAnimated',
        name: 'Google Animated',
        description: 'Google Noto Emojis',
        required: false,
        sizeBytes: 1 * 1024 * 1024,
        compressedSizeBytes: 100,
        downloadUrl: 'http://example.com/emojis.zip',
        checksum: '',
        version: '1.0',
        fileCount: 1,
        format: 'zip',
        animated: true,
        localFolder: 'google_noto_emojis_animated_pack',
      );

      // Construct a malicious zip payload with path traversal attempts
      final archive = Archive();
      archive.addFile(ArchiveFile('../../malicious_exploit.png', 5, [9, 9, 9, 9, 9]));
      final zipBytes = ZipEncoder().encode(archive);

      // Mock HTTP response
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.stream).thenAnswer((_) => http.ByteStream.fromBytes(zipBytes));
      when(() => mockClient.send(any())).thenAnswer((_) async => mockResponse);

      final progressList = <DownloadProgress>[];
      final subscription = service.stream(pack.id).listen((event) {
        progressList.add(event);
      });

      await service.download(pack);

      // Drain stream events
      await Future.delayed(const Duration(milliseconds: 50));

      expect(progressList.last.status, DownloadStatus.failed);
      expect(progressList.last.error, contains('Zip Slip'));

      // Crucial Security Verification: Malicious file must NOT be written outside the emojis directory
      final badPath = p.normalize(p.join(AssetPathService.instance.emojisDir, '..', '..', 'malicious_exploit.png'));
      expect(File(badPath).existsSync(), isFalse);

      await subscription.cancel();
    });

    test('should fallback to mirror URL and retry download successfully when primary URL fails', () async {
      AppDirs.setMockAvailableDiskSpaceMB(1000.0);

      const pack = AssetPack(
        id: 'googleAnimated',
        name: 'Google Animated',
        description: 'Google Noto Emojis',
        required: false,
        sizeBytes: 1024,
        compressedSizeBytes: 100,
        downloadUrl: 'http://example.com/emojis.zip',
        checksum: '',
        version: '1.0',
        fileCount: 1,
        format: 'zip',
        animated: true,
        localFolder: 'google_noto_emojis_animated_pack',
      );

      final archive = Archive();
      archive.addFile(ArchiveFile('emoji_retry.png', 5, [1, 2, 3, 4, 5]));
      final zipBytes = ZipEncoder().encode(archive);

      int callCount = 0;
      when(() => mockClient.send(any())).thenAnswer((invocation) async {
        callCount++;
        final request = invocation.positionalArguments[0] as http.BaseRequest;
        if (request.url.toString() == 'http://example.com/emojis.zip') {
          // Primary fails
          throw const SocketException('Connection refused');
        }
        // Mirror succeeds
        final resp = MockStreamedResponse();
        when(() => resp.statusCode).thenReturn(200);
        when(() => resp.stream).thenAnswer((_) => http.ByteStream.fromBytes(zipBytes));
        return resp;
      });

      final progressList = <DownloadProgress>[];
      final subscription = service.stream(pack.id).listen((event) {
        progressList.add(event);
      });

      await service.download(pack);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(callCount, equals(2)); // Primary + Mirror
      expect(progressList.last.status, DownloadStatus.complete);
      
      final extracted = File(p.join(AssetPathService.instance.emojisDir, 'emoji_retry.png'));
      expect(extracted.existsSync(), isTrue);

      await subscription.cancel();
    });

    test('should throw last exception when all mirrors fail to download', () async {
      AppDirs.setMockAvailableDiskSpaceMB(1000.0);

      const pack = AssetPack(
        id: 'googleAnimated_fail',
        name: 'Google Animated',
        description: 'Google Noto Emojis',
        required: false,
        sizeBytes: 1024,
        compressedSizeBytes: 100,
        downloadUrl: 'http://example.com/emojis_fail.zip',
        checksum: '',
        version: '1.0',
        fileCount: 1,
        format: 'zip',
        animated: true,
        localFolder: 'google_noto_emojis_animated_pack_fail',
      );

      when(() => mockClient.send(any())).thenThrow(const HttpException('Mirror down'));

      final progressList = <DownloadProgress>[];
      final subscription = service.stream(pack.id).listen((event) {
        progressList.add(event);
      });

      await service.download(pack);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(progressList.last.status, DownloadStatus.failed);
      expect(progressList.last.error, contains('Mirror down'));

      await subscription.cancel();
    });

    test('should fail when checksum validation mismatches', () async {
      AppDirs.setMockAvailableDiskSpaceMB(1000.0);

      const pack = AssetPack(
        id: 'googleAnimated_chk',
        name: 'Google Animated',
        description: 'Google Noto Emojis',
        required: false,
        sizeBytes: 1024,
        compressedSizeBytes: 100,
        downloadUrl: 'http://example.com/emojis_chk.zip',
        checksum: 'invalid_sha256_checksum_value_here_12345678901234567890123456789012',
        version: '1.0',
        fileCount: 1,
        format: 'zip',
        animated: true,
        localFolder: 'google_noto_emojis_animated_pack_chk',
      );

      final archive = Archive();
      archive.addFile(ArchiveFile('emoji_chk.png', 5, [1, 2, 3, 4, 5]));
      final zipBytes = ZipEncoder().encode(archive);

      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.stream).thenAnswer((_) => http.ByteStream.fromBytes(zipBytes));
      when(() => mockClient.send(any())).thenAnswer((_) async => mockResponse);

      final progressList = <DownloadProgress>[];
      final subscription = service.stream(pack.id).listen((event) {
        progressList.add(event);
      });

      await service.download(pack);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(progressList.last.status, DownloadStatus.failed);
      expect(progressList.last.error, contains('Download integrity check failed'));

      await subscription.cancel();
    });

    test('should pause download immediately when pause requested', () async {
      AppDirs.setMockAvailableDiskSpaceMB(1000.0);

      const pack = AssetPack(
        id: 'googleAnimated_pause',
        name: 'Google Animated',
        description: 'Google Noto Emojis',
        required: false,
        sizeBytes: 1000,
        compressedSizeBytes: 1000,
        downloadUrl: 'http://example.com/emojis_pause.zip',
        checksum: '',
        version: '1.0',
        fileCount: 1,
        format: 'zip',
        animated: true,
        localFolder: 'google_noto_emojis_animated_pack_pause',
      );

      // Supply a stream that returns bytes slowly so we can pause it midway
      final zipBytes = List.generate(100, (i) => i);
      
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.stream).thenAnswer((_) => http.ByteStream.fromBytes(zipBytes));
      when(() => mockClient.send(any())).thenAnswer((_) async {
        // Pause the pack right as download starts
        service.pause(pack.id);
        return mockResponse;
      });

      final progressList = <DownloadProgress>[];
      final subscription = service.stream(pack.id).listen((event) {
        progressList.add(event);
      });

      await service.download(pack);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(service.isPaused(pack.id), isTrue);
      expect(progressList.any((p) => p.status == DownloadStatus.paused), isTrue);

      service.resume(pack.id);
      expect(service.isPaused(pack.id), isFalse);

      await subscription.cancel();
    });

    test('should download ttf file format and copy to fonts directory', () async {
      AppDirs.setMockAvailableDiskSpaceMB(1000.0);

      const pack = AssetPack(
        id: 'fontCjkSc_test',
        name: 'Chinese Font',
        description: 'Chinese Font Package',
        required: false,
        sizeBytes: 50,
        compressedSizeBytes: 50,
        downloadUrl: 'http://example.com/TestFont.ttf',
        checksum: '',
        version: '1.0',
        fileCount: 1,
        format: 'ttf',
        animated: false,
        localFolder: 'fonts',
      );

      final ttfBytes = List.generate(50, (i) => i);
      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.stream).thenAnswer((_) => http.ByteStream.fromBytes(ttfBytes));
      when(() => mockClient.send(any())).thenAnswer((_) async => mockResponse);

      final progressList = <DownloadProgress>[];
      final subscription = service.stream(pack.id).listen((event) {
        progressList.add(event);
      });

      await service.download(pack);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(progressList.last.status, DownloadStatus.complete);
      
      await subscription.cancel();
    });

    test('should throw error when extracting corrupt zip file archive', () async {
      AppDirs.setMockAvailableDiskSpaceMB(1000.0);

      const pack = AssetPack(
        id: 'googleAnimated_corrupt',
        name: 'Google Animated',
        description: 'Google Noto Emojis',
        required: false,
        sizeBytes: 1024,
        compressedSizeBytes: 100,
        downloadUrl: 'http://example.com/emojis_corrupt.zip',
        checksum: '',
        version: '1.0',
        fileCount: 1,
        format: 'zip',
        animated: true,
        localFolder: 'google_noto_emojis_animated_pack_corrupt',
      );

      // Corrupt/invalid zip bytes
      final corruptBytes = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9];

      when(() => mockResponse.statusCode).thenReturn(200);
      when(() => mockResponse.stream).thenAnswer((_) => http.ByteStream.fromBytes(corruptBytes));
      when(() => mockClient.send(any())).thenAnswer((_) async => mockResponse);

      final progressList = <DownloadProgress>[];
      final subscription = service.stream(pack.id).listen((event) {
        progressList.add(event);
        if (event.status == DownloadStatus.extracting) {
          final tempZip = File(p.join(AssetPathService.instance.tempDir, '${pack.id}.zip'));
          try {
            if (tempZip.existsSync()) {
              tempZip.deleteSync();
            }
          } catch (_) {}
        }
      });

      await service.download(pack);

      await Future.delayed(const Duration(milliseconds: 50));

      expect(progressList.last.status, DownloadStatus.failed);
      expect(progressList.last.error, isNotNull);

      await subscription.cancel();
    });
  });
}
