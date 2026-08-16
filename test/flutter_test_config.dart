import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;

base class TestIOOverrides extends IOOverrides {
  @override
  Directory getSystemTempDirectory() {
    final projectRoot = Directory.current.path;
    final testTempRoot = Directory(p.join(projectRoot, 'test', '.temp'));
    if (!testTempRoot.existsSync()) {
      testTempRoot.createSync(recursive: true);
    }
    return testTempRoot;
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await IOOverrides.runWithIOOverrides(
    () async {
      await testMain();
    },
    TestIOOverrides(),
  );
}
