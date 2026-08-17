import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:archive/archive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/core/downloader/binary_downloader_service.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';

class MockIOHttpClient extends Mock implements HttpClient {}
class MockHttpClientRequest extends Mock implements HttpClientRequest {}
class MockHttpClientResponse extends Mock implements HttpClientResponse {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late BinaryDownloaderService service;
  late Directory tempDir;
  late MockIOHttpClient mockClient;
  late MockHttpClientRequest mockRequest;
  late MockHttpClientResponse mockResponse;

  setUpAll(() {
    registerFallbackValue(Uri.parse('http://example.com'));
    registerFallbackValue((List<int> _) {});
    registerFallbackValue((Object o, StackTrace s) {});
    registerFallbackValue(() {});
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('capstudio_binary_test_');
    AppDirs.setSupportPathForTesting(tempDir.path);
    await AppDirs.init();
    await SettingsService.instance.init();

    service = BinaryDownloaderService.instance;
    service.verifyChecksumsEnabled = false;
    mockClient = MockIOHttpClient();
    mockRequest = MockHttpClientRequest();
    mockResponse = MockHttpClientResponse();
    service.httpClient = mockClient;

    // Standard stubbing for HttpClient
    when(() => mockClient.getUrl(any())).thenAnswer((_) async => mockRequest);
    when(() => mockRequest.close()).thenAnswer((_) async => mockResponse);
    when(() => mockResponse.statusCode).thenReturn(200);
    when(() => mockResponse.persistentConnection).thenReturn(true);
  });

  tearDown(() {
    service.httpClient = null;
    service.verifyChecksumsEnabled = true;
    AppDirs.setHasAvx(true);
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('BinaryDownloaderService Tests', () {
    test('should resolve correct download URL for whisper based on AVX presence', () async {
      // 1. With AVX support
      AppDirs.setHasAvx(true);
      final urlAvx = await service.getDownloadUrl('whisper');
      if (Platform.isWindows) {
        expect(urlAvx, contains('whisper-bin-x64.zip'));
      } else if (Platform.isMacOS) {
        expect(urlAvx, contains('whisper-cli-mac-universal.zip'));
      } else {
        expect(urlAvx, contains('whisper-cli-linux-x64.zip'));
      }

      // 2. Without AVX support
      AppDirs.setHasAvx(false);
      final urlNoAvx = await service.getDownloadUrl('whisper');
      if (Platform.isWindows) {
        expect(urlNoAvx, contains('whisper-cli-win-x64-noavx.zip'));
      } else if (Platform.isMacOS) {
        expect(urlNoAvx, contains('whisper-cli-mac-universal.zip'));
      } else {
        expect(urlNoAvx, contains('whisper-cli-linux-x64.zip'));
      }
    });

    test('should download, extract, and configure whisper binary successfully', () async {
      AppDirs.setHasAvx(true);

      final targetName = Platform.isWindows ? 'whisper-cli.exe' : 'whisper-cli';

      // Create a valid zip archive in memory containing the platform-specific executable
      final archive = Archive();
      final mockData = List<int>.generate(4 * 1024 * 1024, (i) => (i * 17 + 3) & 0xFF);
      archive.addFile(ArchiveFile(targetName, mockData.length, mockData));
      final zipBytes = ZipEncoder().encode(archive);

      // Mock Stream of bytes for HttpClientResponse
      final byteStream = Stream<List<int>>.fromIterable([zipBytes]);
      when(() => mockResponse.contentLength).thenReturn(zipBytes.length);
      when(() => mockResponse.listen(
        any(),
        onError: any(named: 'onError'),
        onDone: any(named: 'onDone'),
        cancelOnError: any(named: 'cancelOnError'),
      )).thenAnswer((invocation) {
        return byteStream.listen(
          invocation.positionalArguments[0] as void Function(List<int>)?,
          onError: invocation.namedArguments[#onError] as Function?,
          onDone: invocation.namedArguments[#onDone] as void Function()?,
          cancelOnError: invocation.namedArguments[#cancelOnError] as bool?,
        );
      });

      final progressList = <BinaryDownloadProgress>[];
      final subscription = service.stream('whisper').listen((event) {
        progressList.add(event);
      });

      await service.download('whisper');

      // Drain stream events
      await Future.delayed(const Duration(milliseconds: 50));

      expect(progressList.any((p) => p.status == BinaryDownloadStatus.downloading), isTrue);
      expect(progressList.any((p) => p.status == BinaryDownloadStatus.extracting), isTrue);
      expect(progressList.last.status, BinaryDownloadStatus.complete);

      // Verify the final binary was moved to AppDirs.bin
      final finalBinary = File(p.join(AppDirs.bin, targetName));
      expect(finalBinary.existsSync(), isTrue);

      // Verify settings were configured with the new executable path
      expect(SettingsService.instance.whisperCliPath, finalBinary.path);

      await subscription.cancel();
    });

    test('should fail closed and refuse install when no checksum can be fetched', () async {
      // Regression guard for the supply-chain hardening: when no checksum is
      // configured (e.g. the remote .sha256 fetch fails), the download must
      // REFUSE to install — the old behavior logged a warning and passed,
      // silently installing an unverified binary.
      service.verifyChecksumsEnabled = true;

      // Make the checksum fetch for ffmpeg's .sha256 companion fail, so
      // expectedChecksum stays empty and fail-closed verification kicks in.
      when(() => mockClient.getUrl(any(
            that: predicate((Uri u) => u.toString().endsWith('.sha256')),
          )))
          .thenThrow(Exception('checksum server unreachable'));

      // Valid zip payload for the download itself (mocked stream).
      final archive = Archive();
      final mockData = List<int>.generate(4 * 1024 * 1024, (i) => (i * 17 + 3) & 0xFF);
      archive.addFile(ArchiveFile('ffmpeg.exe', mockData.length, mockData));
      final zipBytes = ZipEncoder().encode(archive);

      final byteStream = Stream<List<int>>.fromIterable([zipBytes]);
      when(() => mockResponse.contentLength).thenReturn(zipBytes.length);
      when(() => mockResponse.listen(
        any(),
        onError: any(named: 'onError'),
        onDone: any(named: 'onDone'),
        cancelOnError: any(named: 'cancelOnError'),
      )).thenAnswer((invocation) {
        return byteStream.listen(
          invocation.positionalArguments[0] as void Function(List<int>)?,
          onError: invocation.namedArguments[#onError] as Function?,
          onDone: invocation.namedArguments[#onDone] as void Function()?,
          cancelOnError: invocation.namedArguments[#cancelOnError] as bool?,
        );
      });

      final progressList = <BinaryDownloadProgress>[];
      final subscription = service.stream('ffmpeg').listen((event) {
        progressList.add(event);
      });

      await service.download('ffmpeg');
      await Future.delayed(const Duration(milliseconds: 50));

      // Must end in failure with the integrity message, NOT complete.
      expect(progressList.last.status, BinaryDownloadStatus.failed);
      expect(progressList.last.error, contains('integrity check failed'));
      expect(progressList.any((p) => p.status == BinaryDownloadStatus.complete), isFalse);

      // No unverified binary may be installed.
      expect(File(p.join(AppDirs.bin, 'ffmpeg.exe')).existsSync(), isFalse);
      expect(File(p.join(AppDirs.bin, 'ffmpeg')).existsSync(), isFalse);

      await subscription.cancel();
    });

    test('should prevent extraction and abort when Zip Slip traversal is found in binary archive', () async {
      AppDirs.setHasAvx(true);

      // Construct a malicious zip payload trying to write outside binDir
      final archive = Archive();
      final mockData = List<int>.generate(4 * 1024 * 1024, (i) => (i * 17 + 3) & 0xFF);
      archive.addFile(ArchiveFile('../../malicious_exploit.exe', mockData.length, mockData));
      final zipBytes = ZipEncoder().encode(archive);

      final byteStream = Stream<List<int>>.fromIterable([zipBytes]);
      when(() => mockResponse.contentLength).thenReturn(zipBytes.length);
      when(() => mockResponse.listen(
        any(),
        onError: any(named: 'onError'),
        onDone: any(named: 'onDone'),
        cancelOnError: any(named: 'cancelOnError'),
      )).thenAnswer((invocation) {
        return byteStream.listen(
          invocation.positionalArguments[0] as void Function(List<int>)?,
          onError: invocation.namedArguments[#onError] as Function?,
          onDone: invocation.namedArguments[#onDone] as void Function()?,
          cancelOnError: invocation.namedArguments[#cancelOnError] as bool?,
        );
      });

      final progressList = <BinaryDownloadProgress>[];
      final subscription = service.stream('whisper').listen((event) {
        progressList.add(event);
      });

      // Download should throw an exception due to Zip Slip abort
      await expectLater(service.download('whisper'), throwsException);

      // Drain stream events
      await Future.delayed(const Duration(milliseconds: 100));

      // Check final status was failed
      expect(progressList.last.status, BinaryDownloadStatus.failed);
      expect(progressList.last.error, contains('Zip Slip'));

      // Malicious file must NOT be written outside
      final badPath = p.normalize(p.join(AppDirs.bin, '..', '..', 'malicious_exploit.exe'));
      expect(File(badPath).existsSync(), isFalse);

      await subscription.cancel();
    });
  }); // BinaryDownloaderService Tests
}
