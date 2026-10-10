import 'dart:async';
import 'dart:io';
import '../logger/logger_service.dart';
import 'binary_download_models.dart';

/// Handles chunked HTTP/HTTPS binary streaming with range-resumption,
/// download progress tracking, and exponential-backoff retries.
class HttpFileDownloader {
  HttpFileDownloader._();

  /// Downloads a file from [url] to [savePath] with up to 3 retry attempts.
  static Future<void> downloadFile({
    required String url,
    required String savePath,
    required String toolId,
    required void Function(BinaryDownloadProgress) emit,
    HttpClient? customHttpClient,
    Map<String, HttpClient>? activeClients,
  }) async {
    const maxRetries = 3;
    Exception? lastError;

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _downloadAttempt(
          url: url,
          savePath: savePath,
          toolId: toolId,
          emit: emit,
          customHttpClient: customHttpClient,
          activeClients: activeClients,
        );
        return; // Success!
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        LoggerService.instance.log(LogLevel.warning, 'HttpFileDownloader',
            'Download attempt $attempt/$maxRetries failed for $toolId: $e');

        if (attempt < maxRetries) {
          await Future<void>.delayed(Duration(seconds: attempt));
          emit(BinaryDownloadProgress(
            toolId: toolId,
            status: BinaryDownloadStatus.downloading,
            downloadProgress: 0.0,
            error: 'Retrying... (attempt ${attempt + 1}/$maxRetries)',
          ));
        }
      }
    }
    throw lastError ?? Exception('Download failed after $maxRetries attempts');
  }

  static Future<void> _downloadAttempt({
    required String url,
    required String savePath,
    required String toolId,
    required void Function(BinaryDownloadProgress) emit,
    HttpClient? customHttpClient,
    Map<String, HttpClient>? activeClients,
  }) async {
    final partFile = File('$savePath.part');
    final finalFile = File(savePath);
    if (finalFile.existsSync()) finalFile.deleteSync();

    final int existingBytes = partFile.existsSync() ? partFile.lengthSync() : 0;
    final client = customHttpClient ?? HttpClient();
    client.connectionTimeout = const Duration(seconds: 15);
    client.autoUncompress = false;
    if (activeClients != null) {
      activeClients[toolId] = client;
    }

    try {
      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = true;
      request.maxRedirects = 10;
      if (existingBytes > 0) {
        try {
          request.headers.set(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
        } catch (_) {}
      }

      final response = await request.close();
      int startOffset = 0;
      int totalBytes = -1;
      FileMode writeMode = FileMode.write;

      if (response.statusCode == 206) {
        startOffset = existingBytes;
        writeMode = FileMode.append;
        totalBytes = response.contentLength > 0 ? existingBytes + response.contentLength : -1;
        LoggerService.instance.log(LogLevel.info, 'HttpFileDownloader',
            'Resuming download of $toolId from byte $startOffset');
      } else if (response.statusCode == 200) {
        startOffset = 0;
        writeMode = FileMode.write;
        totalBytes = response.contentLength;
      } else if (response.statusCode == 416) {
        if (partFile.existsSync()) partFile.deleteSync();
        throw Exception('HTTP 416 Range Not Satisfiable, resetting partial download.');
      } else {
        throw Exception('Server returned HTTP status ${response.statusCode}');
      }

      int received = startOffset;
      final start = DateTime.now();
      DateTime lastEmitTime = DateTime.now();

      final sink = partFile.openWrite(mode: writeMode);
      try {
        await for (final chunk in response) {
          sink.add(chunk);
          received += chunk.length;

          final now = DateTime.now();
          if (now.difference(lastEmitTime).inMilliseconds >= 80 || (totalBytes > 0 && received >= totalBytes)) {
            lastEmitTime = now;
            final elapsedMs = now.difference(start).inMilliseconds;
            final newlyDownloaded = received - startOffset;
            final speed = elapsedMs > 0 ? newlyDownloaded / (elapsedMs / 1000.0) : 0.0;
            final eta = speed > 0 && totalBytes > 0
                ? Duration(seconds: ((totalBytes - received) / speed).round())
                : null;

            emit(BinaryDownloadProgress(
              toolId: toolId,
              status: BinaryDownloadStatus.downloading,
              downloadProgress: totalBytes > 0 ? (received / totalBytes).clamp(0.0, 1.0) : 0.5,
              bytesReceived: received,
              totalBytes: totalBytes,
              speedBytesPerSec: speed,
              eta: eta,
            ));
          }
        }
        await sink.flush();
      } finally {
        await sink.close();
      }

      final downloadedSize = partFile.lengthSync();
      if (downloadedSize < 50 * 1024) {
        if (partFile.existsSync()) partFile.deleteSync();
        throw Exception('Downloaded file is only ${(downloadedSize / 1024).toStringAsFixed(1)} KB — likely an error page.');
      }

      if (finalFile.existsSync()) finalFile.deleteSync();
      partFile.renameSync(savePath);

      LoggerService.instance.log(LogLevel.info, 'HttpFileDownloader',
          'Download complete for $toolId: ${(downloadedSize / (1024 * 1024)).toStringAsFixed(1)} MB');
    } finally {
      if (customHttpClient == null) client.close();
      if (activeClients != null) {
        activeClients.remove(toolId);
      }
    }
  }
}
