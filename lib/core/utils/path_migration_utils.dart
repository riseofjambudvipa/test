// lib/core/utils/path_migration_utils.dart
import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PathMigrationUtils {
  static String? _docPath;
  static String? _supportPath;

  @visibleForTesting
  static void setPathsForTesting({String? docPath, String? supportPath}) {
    _docPath = docPath;
    _supportPath = supportPath;
  }

  static Future<void> init() async {
    if (kIsWeb) return;
    try {
      _docPath = (await getApplicationDocumentsDirectory()).path;
      _supportPath = (await getApplicationSupportDirectory()).path;
    } catch (_) {
      // safe fallback
    }
  }

  static String? toRelative(String? absPath) {
    if (absPath == null || absPath.isEmpty) return absPath;
    if (kIsWeb) return absPath;
    
    final cleanPath = p.normalize(absPath);
    if (_docPath != null && cleanPath.startsWith(_docPath!)) {
      return cleanPath.replaceFirst(_docPath!, '<DOCS>');
    }
    if (_supportPath != null && cleanPath.startsWith(_supportPath!)) {
      return cleanPath.replaceFirst(_supportPath!, '<SUPPORT>');
    }
    return cleanPath;
  }

  static String? toAbsolute(String? relPath) {
    if (relPath == null || relPath.isEmpty) return relPath;
    if (kIsWeb) return relPath;

    if (relPath.startsWith('<DOCS>')) {
      return _docPath == null ? relPath : relPath.replaceFirst('<DOCS>', _docPath!);
    }
    if (relPath.startsWith('<SUPPORT>')) {
      return _supportPath == null ? relPath : relPath.replaceFirst('<SUPPORT>', _supportPath!);
    }
    return relPath;
  }
}
