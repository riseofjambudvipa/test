import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import '../logger/logger_service.dart';
import 'asset_path_service.dart';
import 'asset_manifest.dart';
import '../fonts/font_service.dart';
import '../utils/app_dirs.dart';
import '../emoji/emoji_service.dart';
import 'emoji_image.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

enum DownloadStatus { idle, downloading, extracting, verifying, complete, failed, paused }

class DownloadProgress {
  final String packId;
  final DownloadStatus status;
  final double downloadProgress; // 0.0–1.0
  final double extractProgress;  // 0.0–1.0
  final int bytesReceived;
  final int totalBytes;
  final double speedBytesPerSec;
  final Duration? eta;
  final String? error;

  const DownloadProgress({
    required this.packId,
    required this.status,
    this.downloadProgress = 0,
    this.extractProgress = 0,
    this.bytesReceived = 0,
    this.totalBytes = 0,
    this.speedBytesPerSec = 0,
    this.eta,
    this.error,
  });

  double get overall => (downloadProgress * 0.7) + (extractProgress * 0.3);

  String get label => switch (status) {
    DownloadStatus.idle        => 'Ready',
    DownloadStatus.downloading => 'Downloading ${_fmt(bytesReceived)} / ${_fmt(totalBytes)}',
    DownloadStatus.extracting  => 'Extracting files...',
    DownloadStatus.verifying   => 'Verifying...',
    DownloadStatus.complete    => 'Installed',
    DownloadStatus.failed      => 'Failed: ${error ?? "Unknown"}',
    DownloadStatus.paused      => 'Paused — tap to resume',
  };

  String _fmt(int b) {
    if (b < 1 << 20) return '${(b / 1024).toStringAsFixed(1)} KB';
    if (b < 1 << 30) return '${(b / (1 << 20)).toStringAsFixed(1)} MB';
    return '${(b / (1 << 30)).toStringAsFixed(2)} GB';
  }
}

class PackDownloadService {
  PackDownloadService._();
  static final PackDownloadService instance = PackDownloadService._();

  /// Mockable HTTP client for offline unit testing
  @visibleForTesting
  http.Client? httpClient;

  final Map<String, StreamController<DownloadProgress>> _streams = {};
  final Map<String, http.Client> _clients = {};
  final Set<String> _pausedPacks = {};
  final Map<String, DownloadProgress> _activeProgress = {};

  // Sequential download FIFO queue to prevent CPU saturation and OOM crashes from parallel extraction isolates
  final List<AssetPack> _queue = [];
  bool _isProcessingQueue = false;
  final Map<String, Completer<void>> _completers = {};

  Stream<DownloadProgress> stream(String packId) {
    _streams[packId] ??= StreamController<DownloadProgress>.broadcast();
    return _streams[packId]!.stream;
  }

  DownloadProgress? getActiveProgress(String packId) => _activeProgress[packId];

  void _closeStream(String packId) {
    _activeProgress.remove(packId);
    final ctrl = _streams.remove(packId);
    if (ctrl != null && !ctrl.isClosed) {
      ctrl.close();
    }
  }

  Future<bool> _verifySha256(String filePath, String expectedHex) async {
    if (expectedHex.isEmpty) {
      LoggerService.instance.log(LogLevel.warning, 'PackDownloadService',
          'No checksum configured for $filePath. Skipping integrity check.');
      return true;
    }
    try {
      final stream = File(filePath).openRead();
      final hash = await sha256.bind(stream).first;
      final actual = hash.toString();
      if (actual != expectedHex.toLowerCase()) {
        LoggerService.instance.log(LogLevel.error, 'PackDownloadService',
            'Checksum mismatch for $filePath! Expected $expectedHex, got $actual');
        return false;
      }
      return true;
    } catch (e, stackTrace) {
      LoggerService.instance.log(LogLevel.error, 'PackDownloadService',
          'Failed to calculate sha256 checksum for $filePath: $e', stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> download(AssetPack pack) async {
    if (kIsWeb) {
      throw UnsupportedError('Pack downloading is not supported on Web.');
    }

    // If already downloading or queued, return the existing future to prevent duplicate triggers
    if (_completers.containsKey(pack.id)) {
      return _completers[pack.id]!.future;
    }

    final completer = Completer<void>();
    _completers[pack.id] = completer;

    // Add to queue
    _queue.add(pack);

    // Emit initial idle/queued state
    final ctrl = _streams[pack.id] ??= StreamController<DownloadProgress>.broadcast();
    final progress = DownloadProgress(
      packId: pack.id,
      status: DownloadStatus.idle,
      downloadProgress: 0.0,
      extractProgress: 0.0,
      bytesReceived: 0,
      totalBytes: 0,
      speedBytesPerSec: 0,
    );
    _activeProgress[pack.id] = progress;
    if (!ctrl.isClosed) ctrl.add(progress);

    LoggerService.instance.log(LogLevel.info, 'PackDownloadService', 'Queued download for pack: ${pack.id}');

    unawaited(_processQueue());

    return completer.future;
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _queue.isEmpty) return;
    _isProcessingQueue = true;
    final pack = _queue.removeAt(0);
    final completer = _completers[pack.id];
    try {
      await _downloadTask(pack);
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
    } catch (e, stackTrace) {
      LoggerService.instance.log(LogLevel.error, 'PackDownloadService', 'Error running queued download for ${pack.id}: $e', stackTrace: stackTrace);
      if (completer != null && !completer.isCompleted) {
        completer.completeError(e, stackTrace);
      }
    } finally {
      _completers.remove(pack.id);
      _isProcessingQueue = false;
      // Process next item in the queue asynchronously to yield the thread
      scheduleMicrotask(_processQueue);
    }
  }

  Future<void> _downloadTask(AssetPack pack) async {
    final ctrl = _streams[pack.id] ??= StreamController<DownloadProgress>.broadcast();
    void emit(DownloadProgress p) {
      _activeProgress[pack.id] = p;
      if (!ctrl.isClosed) ctrl.add(p);
    }

    final tempTtf = pack.format == 'ttf' ? p.join(AssetPathService.instance.tempDir, p.basename(pack.downloadUrl)) : null;
    final tempZip = pack.format != 'ttf' ? p.join(AssetPathService.instance.tempDir, '${pack.id}.zip') : null;

    try {
      final requiredMB = (pack.sizeMB > 0 ? pack.sizeMB : 100.0) * 2.0;
      final targetPath = AssetPathService.instance.assetsRoot;
      final hasSpace = await AppDirs.hasAvailableSpace(targetPath, requiredMB);
      if (!hasSpace) {
        emit(DownloadProgress(
          packId: pack.id,
          status: DownloadStatus.failed,
          downloadProgress: 0.0,
          extractProgress: 0.0,
          bytesReceived: 0,
          totalBytes: 0,
          speedBytesPerSec: 0,
          error: 'Insufficient disk space. At least ${requiredMB.toStringAsFixed(1)} MB free space is required.',
        ));
        _closeStream(pack.id);
        return;
      }

      if (pack.format == 'ttf') {
        final filename = p.basename(pack.downloadUrl);

        // Step 1: Download (supports resume)
        final completed = await _downloadFile(
          url: pack.downloadUrl,
          savePath: tempTtf!,
          packId: pack.id,
          totalBytes: pack.compressedSizeBytes,
          emit: emit,
        );

        if (!completed) return;

        // Step 1.5: Verify Checksum
        emit(DownloadProgress(packId: pack.id, status: DownloadStatus.verifying, downloadProgress: 1.0));
        final checksumOk = await _verifySha256(tempTtf, pack.checksum);
        if (!checksumOk) {
          emit(DownloadProgress(
            packId: pack.id,
            status: DownloadStatus.failed,
            downloadProgress: 1.0,
            error: 'Download integrity check failed. File may be corrupted or tampered with.',
          ));
          try { File(tempTtf).deleteSync(); } catch (_) {}
          _closeStream(pack.id);
          return;
        }

        emit(DownloadProgress(packId: pack.id, status: DownloadStatus.extracting, downloadProgress: 1.0));

        // Step 2: Copy to fonts directory and register
        final fontsDir = FontService.instance.fontsDirectory;
        if (fontsDir.isNotEmpty) {
          final destPath = p.join(fontsDir, filename);
          final tempFile = File(tempTtf);
          if (tempFile.existsSync()) {
            await tempFile.copy(destPath);
            await tempFile.delete();
            await FontService.instance.registerDownloadedFont(destPath);
          }
        }

        emit(DownloadProgress(packId: pack.id, status: DownloadStatus.complete, downloadProgress: 1.0, extractProgress: 1.0));
        _closeStream(pack.id);
        return;
      }

      // Step 1: Download (supports resume)
      final completed = await _downloadFile(
        url: pack.downloadUrl,
        savePath: tempZip!,
        packId: pack.id,
        totalBytes: pack.compressedSizeBytes,
        emit: emit,
      );

      if (!completed) {
        return; // Don't proceed to extract if paused or cancelled
      }

      // Step 1.5: Verify Checksum
      emit(DownloadProgress(packId: pack.id, status: DownloadStatus.verifying, downloadProgress: 1.0));
      final checksumOk = await _verifySha256(tempZip, pack.checksum);
      if (!checksumOk) {
        emit(DownloadProgress(
          packId: pack.id,
          status: DownloadStatus.failed,
          downloadProgress: 1.0,
          error: 'Download integrity check failed. File may be corrupted or tampered with.',
        ));
        try { File(tempZip).deleteSync(); } catch (_) {}
        _closeStream(pack.id);
        return;
      }

      // Step 2: Extract in isolate (keeps UI responsive)
      emit(DownloadProgress(packId: pack.id, status: DownloadStatus.extracting, downloadProgress: 1.0));
      await _extractInIsolate(zipPath: tempZip, destDir: AssetPathService.instance.emojisDir, packId: pack.id, emit: emit);

      try {
        final f = File(tempZip);
        if (f.existsSync()) {
          // Retry deleting the file a few times with backoff, since Windows might hold a lock briefly
          for (int retry = 0; retry < 5; retry++) {
            try {
              await Future<void>.delayed(Duration(milliseconds: 150 * (retry + 1)));
              if (f.existsSync()) {
                await f.delete();
              }
              break;
            } on PathAccessException {
              if (retry == 4) rethrow;
            }
          }
        }
      } catch (e, stackTrace) {
        LoggerService.instance.log(LogLevel.warning, 'PackDownloadService', 'Failed to delete temporary zip file: $e', stackTrace: stackTrace);
      }

      await EmojiService.instance.invalidatePackCache(pack.id);
      emit(DownloadProgress(packId: pack.id, status: DownloadStatus.complete, downloadProgress: 1.0, extractProgress: 1.0));
      _closeStream(pack.id);
    } catch (e) {
      if (tempTtf != null) {
        try {
          final f = File(tempTtf);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }
      if (tempZip != null) {
        try {
          final f = File(tempZip);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }
      LoggerService.instance.log(LogLevel.error, 'PackDownloadService', 'Failed to download ${pack.id}: $e');
      emit(DownloadProgress(packId: pack.id, status: DownloadStatus.failed, error: e.toString()));
      _closeStream(pack.id);
    }
  }

  Future<bool> _downloadFile({
    required String url,
    required String savePath,
    required String packId,
    required int totalBytes,
    required void Function(DownloadProgress) emit,
  }) async {
    final filename = p.basename(url);
    final urls = [
      url,
      'https://github.com/chyrenselin/Local-AI-Caption-Studio/releases/download/v0.0.1/$filename',
    ];

    Exception? lastException;
    for (int i = 0; i < urls.length; i++) {
      final currentUrl = urls[i];
      try {
        if (i > 0) {
          // If falling back to a mirror, clear any partially downloaded file to avoid corrupt ranges
          final f = File(savePath);
          if (f.existsSync()) {
            try {
              f.deleteSync();
            } catch (e, stackTrace) {
              LoggerService.instance.log(LogLevel.warning, 'PackDownloadService', 'Failed to delete partially downloaded file: $e', stackTrace: stackTrace);
            }
          }
        }
        
        LoggerService.instance.log(LogLevel.info, 'PackDownloadService', 
            'Attempting pack download: $packId from mirror: $currentUrl');
            
        final success = await _downloadFileAttempt(
          url: currentUrl,
          savePath: savePath,
          packId: packId,
          totalBytes: totalBytes,
          emit: emit,
        );
        return success;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        LoggerService.instance.log(LogLevel.warning, 'PackDownloadService', 
            'Download attempt failed for $currentUrl: $e');
      }
    }
    throw lastException ?? Exception('All download mirrors failed for pack $packId');
  }

  Future<bool> _downloadFileAttempt({
    required String url,
    required String savePath,
    required String packId,
    required int totalBytes,
    required void Function(DownloadProgress) emit,
  }) async {
    final file = File(savePath);
    int startByte = file.existsSync() ? file.lengthSync() : 0;

    // Check if startByte is somehow larger than totalBytes (corruption check)
    if (totalBytes > 0 && startByte >= totalBytes) {
      try {
        file.deleteSync();
        startByte = 0;
      } catch (e, stackTrace) {
        LoggerService.instance.log(LogLevel.warning, 'PackDownloadService', 'Failed to delete corrupted file: $e', stackTrace: stackTrace);
      }
    }

    final isLocalClient = httpClient == null;
    final client = httpClient ?? http.Client();
    _clients[packId] = client;

    try {
      final req = http.Request('GET', Uri.parse(url));
      if (startByte > 0) req.headers['Range'] = 'bytes=$startByte-';

      final resp = await client.send(req);
      if (resp.statusCode != 200 && resp.statusCode != 206) {
        throw Exception('HTTP ${resp.statusCode}');
      }

      final isRangeAccepted = resp.statusCode == 206;
      final sink = file.openWrite(mode: isRangeAccepted ? FileMode.append : FileMode.write);
      int received = isRangeAccepted ? startByte : 0;
      final actualStartByte = isRangeAccepted ? startByte : 0;
      final start = DateTime.now();

      await for (final chunk in resp.stream) {
        if (isPaused(packId)) {
          await sink.flush(); await sink.close();
          emit(DownloadProgress(
            packId: packId, status: DownloadStatus.paused,
            bytesReceived: received, totalBytes: totalBytes,
            downloadProgress: totalBytes > 0 ? received / totalBytes : 0.0,
          ));
          return false;
        }
        sink.add(chunk);
        received += chunk.length;
        final ms = DateTime.now().difference(start).inMilliseconds;
        final speed = ms > 0 ? (received - actualStartByte) / (ms / 1000.0) : 0.0;
        final eta = speed > 0 && totalBytes > 0 ? Duration(seconds: ((totalBytes - received) / speed).round()) : null;
        emit(DownloadProgress(
          packId: packId, status: DownloadStatus.downloading,
          downloadProgress: totalBytes > 0 ? (received / totalBytes).clamp(0.0, 1.0) : 0.0,
          bytesReceived: received, totalBytes: totalBytes,
          speedBytesPerSec: speed, eta: eta,
        ));
      }
      await sink.flush(); await sink.close();
      return true;
    } finally {
      if (isLocalClient) {
        client.close();
      }
      _clients.remove(packId);
    }
  }

  Future<void> _extractInIsolate({
    required String zipPath,
    required String destDir,
    required String packId,
    required void Function(DownloadProgress) emit,
  }) async {
    final port = ReceivePort();
    await Isolate.spawn(_extractEntry, [zipPath, destDir, port.sendPort]);
    await for (final msg in port) {
      if (msg is double) {
        emit(DownloadProgress(packId: packId, status: DownloadStatus.extracting,
            downloadProgress: 1.0, extractProgress: msg));
      } else if (msg == 'done') { port.close(); break; }
      else if (msg is String && msg.startsWith('err:')) {
        port.close(); throw Exception(msg.substring(4));
      }
    }
  }

  static Future<void> _extractEntry(List<dynamic> args) async {
    final zip = args[0] as String;
    final dest = args[1] as String;
    final port = args[2] as SendPort;
    try {
      await _extractZipMemoryEfficiently(zip, dest, port);
      port.send('done');
    } catch (e) {
      port.send('err:$e');
    }
  }

  static Future<void> _extractZipMemoryEfficiently(
    String zipPath,
    String destDir,
    SendPort port,
  ) async {
    final file = File(zipPath);
    if (!file.existsSync()) {
      throw FileSystemException('Zip file not found', zipPath);
    }
    final raf = await file.open(mode: FileMode.read);
    try {
      final length = await raf.length();
      if (length < 22) {
        throw const FormatException('File is too short to be a valid zip archive');
      }

      final searchEnd = (length - 65535 - 22).clamp(0, length);
      final searchSize = length - searchEnd;
      await raf.setPosition(searchEnd);
      final buffer = await raf.read(searchSize);

      int eocdOffsetInBuf = -1;
      for (int i = buffer.length - 22; i >= 0; i--) {
        if (buffer[i] == 0x50 &&
            buffer[i + 1] == 0x4b &&
            buffer[i + 2] == 0x05 &&
            buffer[i + 3] == 0x06) {
          eocdOffsetInBuf = i;
          break;
        }
      }

      if (eocdOffsetInBuf == -1) {
        throw const FormatException('EOCD signature not found. The ZIP file may be corrupt.');
      }

      final eocdBytes = buffer.sublist(eocdOffsetInBuf, eocdOffsetInBuf + 22);
      final byteData = ByteData.view(eocdBytes.buffer, eocdBytes.offsetInBytes, eocdBytes.lengthInBytes);
      final totalEntries = byteData.getUint16(10, Endian.little);
      final cdOffset = byteData.getUint32(16, Endian.little);

      await raf.setPosition(cdOffset);

      final entries = <_ZipEntryMetadata>[];
      for (int i = 0; i < totalEntries; i++) {
        final headerBytes = await raf.read(46);
        if (headerBytes.length < 46) {
          break;
        }
        final bd = ByteData.view(headerBytes.buffer, headerBytes.offsetInBytes, headerBytes.lengthInBytes);
        final sig = bd.getUint32(0, Endian.little);
        if (sig != 0x02014b50) {
          break;
        }
        final compressionMethod = bd.getUint16(10, Endian.little);
        final compressedSize = bd.getUint32(20, Endian.little);
        final uncompressedSize = bd.getUint32(24, Endian.little);
        final filenameLen = bd.getUint16(28, Endian.little);
        final extraLen = bd.getUint16(30, Endian.little);
        final commentLen = bd.getUint16(32, Endian.little);
        final localHeaderOffset = bd.getUint32(42, Endian.little);

        final filenameBytes = await raf.read(filenameLen);
        final filename = utf8.decode(filenameBytes, allowMalformed: true);

        // Skip extra field and comment
        await raf.setPosition(await raf.position() + extraLen + commentLen);

        entries.add(_ZipEntryMetadata(
          filename: filename,
          compressionMethod: compressionMethod,
          compressedSize: compressedSize,
          uncompressedSize: uncompressedSize,
          localHeaderOffset: localHeaderOffset,
        ));
      }

      final String canonicalDest = p.canonicalize(destDir);
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final outPath = p.join(destDir, entry.filename);
        final String canonicalOut = p.canonicalize(outPath);
        if (!p.isWithin(canonicalDest, canonicalOut) && canonicalOut != canonicalDest) {
          throw Exception('Malicious zip entry path detected (Zip Slip): ${entry.filename}');
        }

        final isDir = entry.filename.endsWith('/') || entry.filename.endsWith('\\');
        if (isDir) {
          await Directory(outPath).create(recursive: true);
        } else {
          await Directory(p.dirname(outPath)).create(recursive: true);

          await raf.setPosition(entry.localHeaderOffset);
          final localHeaderBytes = await raf.read(30);
          if (localHeaderBytes.length < 30) {
            throw Exception('Invalid local file header for ${entry.filename}');
          }
          final bd = ByteData.view(localHeaderBytes.buffer, localHeaderBytes.offsetInBytes, localHeaderBytes.lengthInBytes);
          final sig = bd.getUint32(0, Endian.little);
          if (sig != 0x04034b50) {
            throw Exception('Invalid local file header signature for ${entry.filename}');
          }
          final localFilenameLen = bd.getUint16(26, Endian.little);
          final localExtraLen = bd.getUint16(28, Endian.little);

          final dataOffset = entry.localHeaderOffset + 30 + localFilenameLen + localExtraLen;
          await raf.setPosition(dataOffset);

          final outFile = File(outPath);
          final outSink = await outFile.open(mode: FileMode.write);

          try {
            if (entry.compressionMethod == 0) {
              // STORE
              int remaining = entry.compressedSize;
              const chunkSize = 64 * 1024;
              while (remaining > 0) {
                final toRead = remaining < chunkSize ? remaining : chunkSize;
                final bytes = await raf.read(toRead);
                if (bytes.isEmpty) break;
                await outSink.writeFrom(bytes);
                remaining -= bytes.length;
              }
            } else if (entry.compressionMethod == 8) {
              // DEFLATE
              final stream = _readChunkStream(raf, dataOffset, entry.compressedSize);
              final decodedStream = stream.transform<List<int>>(ZLibCodec(raw: true).decoder);
              await for (final List<int> chunk in decodedStream) {
                await outSink.writeFrom(chunk);
              }
            } else {
              throw Exception('Unsupported compression method ${entry.compressionMethod} for ${entry.filename}');
            }
          } finally {
            await outSink.close();
          }
        }

        if (i % 20 == 0 || i == entries.length - 1) {
          port.send((i + 1) / entries.length);
        }
      }
    } finally {
      await raf.close();
    }
  }

  static Stream<List<int>> _readChunkStream(RandomAccessFile raf, int startOffset, int length) async* {
    await raf.setPosition(startOffset);
    int remaining = length;
    const chunkSize = 64 * 1024;
    while (remaining > 0) {
      final toRead = remaining < chunkSize ? remaining : chunkSize;
      final bytes = await raf.read(toRead);
      if (bytes.isEmpty) break;
      yield bytes;
      remaining -= bytes.length;
    }
  }

  void pause(String packId) {
    _pausedPacks.add(packId);
    _queue.removeWhere((p) => p.id == packId);
  }
  void resume(String packId) {
    _pausedPacks.remove(packId);
    final packs = AssetManifest.getLocalFallbackPacks();
    AssetPack? foundPack;
    for (final p in packs) {
      if (p.id == packId) {
        foundPack = p;
        break;
      }
    }
    if (foundPack != null) {
      download(foundPack);
    }
  }
  bool isPaused(String packId) => _pausedPacks.contains(packId);
  void cancel(String packId) {
    _queue.removeWhere((p) => p.id == packId);
    _activeProgress.remove(packId);
    _clients[packId]?.close();
    _clients.remove(packId);
    _closeStream(packId);
  }

  Future<void> _safeDeleteDirectory(Directory dir) async {
    if (!dir.existsSync()) return;
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {}

    for (int i = 0; i < 5; i++) {
      try {
        await dir.delete(recursive: true);
        return;
      } catch (e) {
        if (i == 4) rethrow;
        await Future<void>.delayed(Duration(milliseconds: 150 * (i + 1)));
      }
    }
  }

  Future<void> removePack(AssetPack pack) async {
    if (kIsWeb) return;
    try {
      if (pack.format == 'ttf') {
        final filename = p.basename(pack.downloadUrl);
        final file = File(p.join(FontService.instance.fontsDirectory, filename));
        if (file.existsSync()) {
          await file.delete();
          final fontName = FontService.instance.normalizeFontName(p.basenameWithoutExtension(file.path));
          FontService.instance.unregisterFont(fontName);
        }
        return;
      }
      final dir = Directory(AssetPathService.instance.emojiPackDir(pack.localFolder));
      await _safeDeleteDirectory(dir);
      await EmojiService.instance.invalidatePackCache(pack.id);
      EmojiImage.clearCache();
    } catch (e, stackTrace) {
      LoggerService.instance.log(LogLevel.error, 'PackDownloadService', 'Failed to remove pack ${pack.id}: $e', stackTrace: stackTrace);
    }
  }

  @visibleForTesting
  void resetForTesting() {
    _queue.clear();
    _isProcessingQueue = false;
    for (final completer in _completers.values) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _completers.clear();
    _streams.clear();
    _clients.clear();
    _pausedPacks.clear();
    _activeProgress.clear();
    httpClient = null;
  }
}

class _ZipEntryMetadata {
  final String filename;
  final int compressionMethod;
  final int compressedSize;
  final int uncompressedSize;
  final int localHeaderOffset;

  _ZipEntryMetadata({
    required this.filename,
    required this.compressionMethod,
    required this.compressedSize,
    required this.uncompressedSize,
    required this.localHeaderOffset,
  });
}
