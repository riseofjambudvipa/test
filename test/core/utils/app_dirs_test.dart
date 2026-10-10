import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/utils/app_dirs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('capstudio_dirs_test_');
    AppDirs.setSupportPathForTesting(tempDir.path);
    Directory(AppDirs.logs).createSync(recursive: true);
  });

  tearDown(() {
    AppDirs.setHasAvx(null);
    AppDirs.setMockAvailableDiskSpaceMB(null);
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('AppDirs Tests', () {
    test('should resolve canonical subdirectories correctly', () {
      expect(AppDirs.support, tempDir.path);
      expect(AppDirs.logs, p.join(tempDir.path, 'logs'));
      expect(AppDirs.bin, p.join(tempDir.path, 'bin'));
      expect(AppDirs.assets, p.join(tempDir.path, 'assets'));
      expect(AppDirs.fonts, p.join(tempDir.path, 'fonts'));

      expect(Directory(AppDirs.support).existsSync(), isTrue);
      expect(Directory(AppDirs.logs).existsSync(), isTrue);
    });



    test('isWindowsVcRuntimeInstalled should return boolean without throwing exceptions', () {
      expect(() => AppDirs.isWindowsVcRuntimeInstalled(), returnsNormally);
    });

    test('isAppleSilicon and getCpuArchitecture should return valid results without throwing', () {
      expect(() => AppDirs.isAppleSilicon(), returnsNormally);
      expect(AppDirs.isAppleSilicon(), isA<bool>());
      expect(AppDirs.getCpuArchitecture(), isNotEmpty);
    });

    test('cpuSupportsAvx should cache and return boolean flag safely', () async {
      AppDirs.setHasAvx(true);
      expect(await AppDirs.cpuSupportsAvx(), isTrue);

      AppDirs.setHasAvx(false);
      expect(await AppDirs.cpuSupportsAvx(), isFalse);
    });

    test('getAvailableDiskSpaceMB should return mock values when configured', () async {
      AppDirs.setMockAvailableDiskSpaceMB(1234.5);
      final space = await AppDirs.getAvailableDiskSpaceMB('dummy_path');
      expect(space, 1234.5);

      final hasSpace = await AppDirs.hasAvailableSpace('dummy_path', 1000.0);
      expect(hasSpace, isTrue);

      final hasSpaceFailed = await AppDirs.hasAvailableSpace('dummy_path', 2000.0);
      expect(hasSpaceFailed, isFalse);
    });
  });
}
