// lib/core/utils/path_migration_utils.dart
import 'dart:io';
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

  /// FIX (audit): true when [path] is [base] or sits under it. Windows paths
  /// are case-insensitive, and the check is boundary-aware so that
  /// C:\Users\X\DocumentsExtra does not match base C:\Users\X\Documents.
  static bool _isUnder(String path, String base) {
    final cmpPath = Platform.isWindows ? path.toLowerCase() : path;
    final cmpBase = Platform.isWindows ? base.toLowerCase() : base;
    if (!cmpPath.startsWith(cmpBase)) return false;
    if (cmpPath.length == cmpBase.length) return true;
    final next = cmpPath[cmpBase.length];
    return next == '/' || next == '\\';
  }

  static String? toRelative(String? absPath) {
    if (absPath == null || absPath.isEmpty) return absPath;
    if (kIsWeb) return absPath;

    final cleanPath = p.normalize(absPath);
    // Slice by length instead of replaceFirst so case-only differences on
    // Windows still tokenize (replaceFirst is case-sensitive).
    if (_docPath != null && _isUnder(cleanPath, _docPath!)) {
      return '<DOCS>${cleanPath.substring(_docPath!.length)}';
    }
    if (_supportPath != null && _isUnder(cleanPath, _supportPath!)) {
      return '<SUPPORT>${cleanPath.substring(_supportPath!.length)}';
    }
    return cleanPath;
  }

  static String? toAbsolute(String? relPath) {
    if (relPath == null || relPath.isEmpty) return relPath;
    if (kIsWeb) return relPath;

    if (relPath.startsWith('<DOCS>')) {
      // FIX (audit): if init() failed, resolving the token to the literal
      // '<DOCS>' string made file operations target a folder literally named
      // '<DOCS>'. Return null so callers treat the path as unresolvable.
      return _docPath == null ? null : relPath.replaceFirst('<DOCS>', _docPath!);
    }
    if (relPath.startsWith('<SUPPORT>')) {
      return _supportPath == null ? null : relPath.replaceFirst('<SUPPORT>', _supportPath!);
    }
    return relPath;
  }
}
