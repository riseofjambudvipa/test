import 'dart:io';
import 'dart:isolate';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'binary_download_models.dart';

/// Helper to safely unpack tar.xz and zip archives inside background isolates.
class ArchiveExtractor {
  const ArchiveExtractor._();

  /// Extracts an archive ([zipPath]) into [destDir] in a spawned background isolate,
  /// streaming extraction progress through [emit].
  static Future<void> extractInIsolate({
    required String zipPath,
    required String destDir,
    required String toolId,
    required void Function(BinaryDownloadProgress) emit,
    void Function(Isolate isolate)? onIsolateSpawned,
    void Function()? onIsolateCompleted,
  }) async {
    final port = ReceivePort();
    final isolate = await Isolate.spawn(_extractEntry, (zipPath, destDir, port.sendPort));
    onIsolateSpawned?.call(isolate);

    try {
      await for (final msg in port) {
        if (msg is double) {
          emit(BinaryDownloadProgress(
            toolId: toolId,
            status: BinaryDownloadStatus.extracting,
            downloadProgress: 1.0,
            extractProgress: msg,
          ));
        } else if (msg == 'done') {
          port.close();
          break;
        } else if (msg is String && msg.startsWith('err:')) {
          port.close();
          throw Exception(msg.substring(4));
        }
      }
    } finally {
      onIsolateCompleted?.call();
      port.close();
    }
  }

  static void _extractEntry((String, String, SendPort) args) {
    final (zip, dest, port) = args;
    try {
      // Check if it's a tar.xz archive (Linux static builds)
      if (zip.endsWith('.tar.xz')) {
        // Step 1: List entries and reject any with path traversal
        final listResult = Process.runSync('tar', ['-tf', zip]);
        if (listResult.exitCode != 0) {
          throw Exception('Failed to list tar.xz entries: ${listResult.stderr}');
        }
        final canonicalDest = p.canonicalize(dest);
        for (final entry in listResult.stdout.toString().split('\n')) {
          final trimmed = entry.trim();
          if (trimmed.isEmpty) continue;
          final resolved = p.canonicalize(p.join(dest, trimmed));
          if (!p.isWithin(canonicalDest, resolved) && resolved != canonicalDest) {
            throw Exception('Malicious tar entry detected (path traversal): $trimmed');
          }
        }
        // Step 2: Safe extraction
        final processResult = Process.runSync('tar', ['--no-overwrite-dir', '-xf', zip, '-C', dest]);
        if (processResult.exitCode != 0) {
          throw Exception('Failed to extract tar.xz archive: ${processResult.stderr}');
        }
        port.send(1.0);
      } else {
        final inputStream = InputFileStream(zip);
        final archive = ZipDecoder().decodeStream(inputStream);
        final total = archive.files.length;
        final String canonicalDest = p.canonicalize(dest);
        for (int i = 0; i < total; i++) {
          final f = archive.files[i];
          if (f.isFile) {
            final out = p.join(dest, f.name);
            final String canonicalOut = p.canonicalize(out);
            if (!p.isWithin(canonicalDest, canonicalOut) && canonicalOut != canonicalDest) {
              inputStream.close();
              throw Exception('Malicious zip entry path detected (Zip Slip): ${f.name}');
            }
            Directory(p.dirname(out)).createSync(recursive: true);
            final outStream = OutputFileStream(out);
            f.writeContent(outStream);
            outStream.close();
          }
          if (i % 20 == 0 || i == total - 1) {
            port.send((i + 1) / total);
          }
        }
        inputStream.close();
      }
      port.send('done');
    } catch (e) {
      port.send('err:$e');
    }
  }
}
