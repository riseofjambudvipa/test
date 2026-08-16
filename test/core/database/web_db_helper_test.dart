import 'package:flutter_test/flutter_test.dart';
import 'package:capstudio/core/database/web_db_helper.dart';

void main() {
  group('WebDbHelper Native Stub Tests', () {
    test('stub saveProjectWeb should complete without errors', () async {
      expect(WebDbHelper.saveProjectWeb('proj_test', '{}'), completes);
    });

    test('stub getProjectWeb should return null', () async {
      final res = await WebDbHelper.getProjectWeb('proj_test');
      expect(res, isNull);
    });

    test('stub getAllProjectsWeb should return empty list', () async {
      final res = await WebDbHelper.getAllProjectsWeb();
      expect(res, isEmpty);
    });

    test('stub deleteProjectWeb should complete without errors', () async {
      expect(WebDbHelper.deleteProjectWeb('proj_test'), completes);
    });
  });
}
