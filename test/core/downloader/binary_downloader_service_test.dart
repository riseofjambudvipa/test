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
    test('should resolve correct download URL for whisper based on platform', () async {
      final url = await service.getDownloadUrl('whisper');
      if (Platform.isWindows) {
        expect(url, anyOf(contains('whisper-cli-win-x64-avx.zip'), contains('whisper-cli-win-x64-noavx.zip')));
      } else if (Platform.isMacOS) {
        expect(url, anyOf(contains('whisper-cli-mac-universal.zip'), contains('whisper-macos.zip')));
      } else {
        expect(url, anyOf(contains('whisper-cli-linux-x64.zip'), contains('whisper-linux.zip')));
      }
    });

    test('should resolve fast CDN mirror and fallback mirrors for ffmpeg', () async {
      final mirrors = await service.getDownloadUrls('ffmpeg');
      expect(mirrors, isNotEmpty);
      if (Platform.isWindows) {
        expect(mirrors.length, 3);
        expect(mirrors.any((m) => m.contains('ffmpeg-windows.zip')), isTrue);
        expect(mirrors.any((m) => m.contains('codexffmpeg')), isTrue);
        expect(mirrors.any((m) => m.contains('gyan.dev')), isTrue);
      } else if (Platform.isMacOS) {
        expect(mirrors.any((m) => m.contains('evermeet.cx')), isTrue);
      } else {
        expect(mirrors.any((m) => m.contains('johnvansickle.com')), isTrue);
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

    test('should preserve both whisper and ffmpeg licenses side-by-side without collision', () async {
      AppDirs.setHasAvx(true);
      final binDir = Directory(AppDirs.bin);
      if (!binDir.existsSync()) binDir.createSync(recursive: true);

      // 1. First download Whisper which contains LICENSE.txt
      final whisperTarget = Platform.isWindows ? 'whisper-cli.exe' : 'whisper-cli';
      final whisperArchive = Archive();
      final mockData = List<int>.generate(2 * 1024 * 1024, (i) => (i * 11) & 0xFF);
      whisperArchive.addFile(ArchiveFile(whisperTarget, mockData.length, mockData));
      final whisperLicenseBytes = 'MIT License - Whisper.cpp copyright (c) 2023 Georgi Gerganov'.codeUnits;
      whisperArchive.addFile(ArchiveFile('LICENSE.txt', whisperLicenseBytes.length, whisperLicenseBytes));
      final whisperZipBytes = ZipEncoder().encode(whisperArchive);

      when(() => mockResponse.contentLength).thenReturn(whisperZipBytes.length);
      when(() => mockResponse.listen(
        any(),
        onError: any(named: 'onError'),
        onDone: any(named: 'onDone'),
        cancelOnError: any(named: 'cancelOnError'),
      )).thenAnswer((invocation) {
        return Stream<List<int>>.fromIterable([whisperZipBytes]).listen(
          invocation.positionalArguments[0] as void Function(List<int>)?,
          onError: invocation.namedArguments[#onError] as Function?,
          onDone: invocation.namedArguments[#onDone] as void Function()?,
          cancelOnError: invocation.namedArguments[#cancelOnError] as bool?,
        );
      });

      await service.download('whisper');
      final whisperLicense = File(p.join(AppDirs.bin, 'whisper_LICENSE.txt'));
      expect(whisperLicense.existsSync(), isTrue);
      expect(whisperLicense.readAsStringSync(), contains('Whisper.cpp'));

      // 2. Now download FFmpeg which ALSO contains LICENSE.txt
      final ffmpegTarget = Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
      final ffmpegArchive = Archive();
      ffmpegArchive.addFile(ArchiveFile(ffmpegTarget, mockData.length, mockData));
      final ffmpegLicenseBytes = 'GNU General Public License v3 - FFmpeg project'.codeUnits;
      ffmpegArchive.addFile(ArchiveFile('LICENSE.txt', ffmpegLicenseBytes.length, ffmpegLicenseBytes));
      final ffmpegZipBytes = ZipEncoder().encode(ffmpegArchive);

      when(() => mockResponse.contentLength).thenReturn(ffmpegZipBytes.length);
      when(() => mockResponse.listen(
        any(),
        onError: any(named: 'onError'),
        onDone: any(named: 'onDone'),
        cancelOnError: any(named: 'cancelOnError'),
      )).thenAnswer((invocation) {
        return Stream<List<int>>.fromIterable([ffmpegZipBytes]).listen(
          invocation.positionalArguments[0] as void Function(List<int>)?,
          onError: invocation.namedArguments[#onError] as Function?,
          onDone: invocation.namedArguments[#onDone] as void Function()?,
          cancelOnError: invocation.namedArguments[#cancelOnError] as bool?,
        );
      });

      await service.download('ffmpeg');
      final ffmpegLicense = File(p.join(AppDirs.bin, 'ffmpeg_LICENSE.txt'));
      expect(ffmpegLicense.existsSync(), isTrue);
      expect(ffmpegLicense.readAsStringSync(), contains('FFmpeg project'));

      // 3. Confirm whisper license was NOT overwritten or deleted!
      expect(whisperLicense.existsSync(), isTrue);
      expect(whisperLicense.readAsStringSync(), contains('Whisper.cpp'));
    });
  }); // BinaryDownloaderService Tests
}
