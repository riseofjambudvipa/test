// lib/core/utils/web_download_helper_web.dart
import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

void downloadFileWeb(String content, String fileName) {
  final bytes = utf8.encode(content);
  final blob = web.Blob([bytes.toJS].toJS);
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = fileName;
  anchor.click();
  // FIX (audit): revoking synchronously right after click() can abort the
  // download before the browser starts fetching it (Safari historically).
  // Defer the revoke instead.
  Timer(const Duration(seconds: 30), () {
    web.URL.revokeObjectURL(url);
  });
}

