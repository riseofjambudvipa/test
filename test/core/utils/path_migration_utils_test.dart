import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:capstudio/core/utils/path_migration_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PathMigrationUtils Tests', () {
    final mockDocs = p.normalize('/users/test/documents');
    final mockSupport = p.normalize('/users/test/appdata/support');

    setUp(() {
      PathMigrationUtils.setPathsForTesting(
        docPath: mockDocs,
        supportPath: mockSupport,
      );
    });

    tearDown(() {
      PathMigrationUtils.setPathsForTesting(
        docPath: null,
        supportPath: null,
      );
    });

    test('toRelative and toAbsolute return null/empty on null/empty inputs', () {
      expect(PathMigrationUtils.toRelative(null), isNull);
      expect(PathMigrationUtils.toRelative(''), '');
      expect(PathMigrationUtils.toAbsolute(null), isNull);
      expect(PathMigrationUtils.toAbsolute(''), '');
    });

    test('toRelative converts document paths to <DOCS> placeholder', () {
      final absPath = p.normalize('$mockDocs/projects/video.mp4');
      final relPath = PathMigrationUtils.toRelative(absPath);
      expect(relPath, p.normalize('<DOCS>/projects/video.mp4'));
    });

    test('toRelative converts support paths to <SUPPORT> placeholder', () {
      final absPath = p.normalize('$mockSupport/cache/audio.wav');
      final relPath = PathMigrationUtils.toRelative(absPath);
      expect(relPath, p.normalize('<SUPPORT>/cache/audio.wav'));
    });

    test('toRelative leaves other paths normalized but intact', () {
      final absPath = p.normalize('/some/other/path/video.mp4');
      final relPath = PathMigrationUtils.toRelative(absPath);
      expect(relPath, p.normalize('/some/other/path/video.mp4'));
    });

    test('toAbsolute converts <DOCS> placeholder back to absolute path', () {
      final relPath = p.normalize('<DOCS>/projects/video.mp4');
      final absPath = PathMigrationUtils.toAbsolute(relPath);
      expect(absPath, p.normalize('$mockDocs/projects/video.mp4'));
    });

    test('toAbsolute converts <SUPPORT> placeholder back to absolute path', () {
      final relPath = p.normalize('<SUPPORT>/cache/audio.wav');
      final absPath = PathMigrationUtils.toAbsolute(relPath);
      expect(absPath, p.normalize('$mockSupport/cache/audio.wav'));
    });

    test('toAbsolute leaves paths without placeholders intact', () {
      final relPath = p.normalize('/some/other/path/video.mp4');
      final absPath = PathMigrationUtils.toAbsolute(relPath);
      expect(absPath, p.normalize('/some/other/path/video.mp4'));
    });

    test('full path round-trips correctly', () {
      final docsPath = p.normalize('$mockDocs/sub/dir/file.txt');
      final relativeDocs = PathMigrationUtils.toRelative(docsPath);
      expect(PathMigrationUtils.toAbsolute(relativeDocs), docsPath);

      final supportPath = p.normalize('$mockSupport/sub/dir/file.txt');
      final relativeSupport = PathMigrationUtils.toRelative(supportPath);
      expect(PathMigrationUtils.toAbsolute(relativeSupport), supportPath);

      final externalPath = p.normalize('/external/file.txt');
      final relativeExternal = PathMigrationUtils.toRelative(externalPath);
      expect(PathMigrationUtils.toAbsolute(relativeExternal), externalPath);
    });
  });
}
