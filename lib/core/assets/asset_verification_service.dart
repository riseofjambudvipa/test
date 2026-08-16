import 'dart:io';
import 'dart:isolate';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'asset_path_service.dart';
import 'asset_manifest.dart';
import '../fonts/font_service.dart';
import '../logger/logger_service.dart';

enum AssetCategory { emojis, fonts, sfx }

class MissingAsset {
  final String packId;
  final String packName;
  final bool isRequired;
  final String userMessage;
  final String? actionLabel;
  const MissingAsset({
    required this.packId,
    required this.packName,
    required this.isRequired,
    required this.userMessage,
    this.actionLabel,
  });
}

class AssetVerificationResult {
  final bool allRequiredPresent;
  final List<MissingAsset> missing;
  final List<String> installedPackIds;
  final bool hasAnyEmojis;
  final String? assetsRootMissing; // non-null = root folder itself is gone

  const AssetVerificationResult({
    required this.allRequiredPresent,
    required this.missing,
    required this.installedPackIds,
    required this.hasAnyEmojis,
    this.assetsRootMissing,
  });

  List<MissingAsset> get requiredMissing => missing.where((m) => m.isRequired).toList();

  String get warningMessage {
    if (assetsRootMissing != null) {
      return 'Assets folder not found:\n$assetsRootMissing\nEmojis and fonts unavailable.';
    }
    return requiredMissing.map((m) => m.userMessage).join('\n');
  }
}

class AssetVerificationService {
  AssetVerificationService._();
  static final AssetVerificationService instance = AssetVerificationService._();

  /// Run on every startup. Fast — only checks folder existence + file count.
  Future<AssetVerificationResult> verify([AssetManifest? manifest]) async {
    if (kIsWeb) {
      return const AssetVerificationResult(
        allRequiredPresent: true,
        missing: [],
        installedPackIds: [
          'googleNonAnimated',
          'googleAnimated',
          'microsoftAnimated',
          'microsoftNonAnimated',
          'openmoji'
        ],
        hasAnyEmojis: true,
      );
    }

    final paths = AssetPathService.instance;
    final missing = <MissingAsset>[];
    final installed = <String>[];

    // Check root folder exists
    if (!Directory(paths.assetsRoot).existsSync()) {
      return AssetVerificationResult(
        allRequiredPresent: false,
        missing: [],
        installedPackIds: [],
        hasAnyEmojis: false,
        assetsRootMissing: paths.assetsRoot,
      );
    }

    final packs = manifest?.packs ?? AssetManifest.getLocalFallbackPacks();

    final emojiPacksToCheck = <AssetPack>[];

    // Check each pack
    for (final pack in packs) {
      final isFont = pack.id.startsWith('font');
      if (isFont) {
        final fontsDir = FontService.instance.fontsDirectory;
        if (fontsDir.isEmpty) {
          missing.add(MissingAsset(
            packId: pack.id,
            packName: pack.name,
            isRequired: pack.required,
            userMessage: '${pack.name} not installed (service offline)',
            actionLabel: 'Download',
          ));
          continue;
        }
        final fontFile = File(p.join(fontsDir, pack.localFolder));
        if (!fontFile.existsSync()) {
          missing.add(MissingAsset(
            packId: pack.id,
            packName: pack.name,
            isRequired: pack.required,
            userMessage: '${pack.name} not installed',
            actionLabel: 'Download',
          ));
          continue;
        }
        installed.add(pack.id);
        continue;
      }

      final dir = Directory(paths.emojiPackDir(pack.localFolder));
      if (!dir.existsSync()) {
        missing.add(MissingAsset(
          packId: pack.id,
          packName: pack.name,
          isRequired: pack.required,
          userMessage: '${pack.name} ${pack.required ? "is required" : "not installed"}',
          actionLabel: 'Download',
        ));
        continue;
      }

      emojiPacksToCheck.add(pack);
    }

    // Batch verify emoji files in a single Isolate.run() call to optimize boot time
    Map<String, int> fileCounts = {};
    if (emojiPacksToCheck.isNotEmpty) {
      try {
        final Map<String, String> scanTargets = {
          for (final pack in emojiPacksToCheck) pack.id: paths.emojiPackDir(pack.localFolder)
        };
        fileCounts = await Isolate.run(() {
          final results = <String, int>{};
          scanTargets.forEach((packId, path) {
            final d = Directory(path);
            if (!d.existsSync()) {
              results[packId] = 0;
              return;
            }
            int c = 0;
            for (final entity in d.listSync(recursive: true)) {
              if (entity is File) {
                c++;
              }
            }
            results[packId] = c;
          });
          return results;
        });
      } catch (e) {
        LoggerService.instance.log(LogLevel.error, 'Assets', 'Failed batch emoji verification: $e');
      }
    }

    // Process counts for each emoji pack
    for (final pack in emojiPacksToCheck) {
      final count = fileCounts[pack.id];
      if (count == null) {
        missing.add(MissingAsset(
          packId: pack.id,
          packName: pack.name,
          isRequired: pack.required,
          userMessage: 'Failed to access ${pack.name} files',
          actionLabel: 'Re-download',
        ));
        continue;
      }
      if (count < pack.fileCount - 10) {
        missing.add(MissingAsset(
          packId: pack.id,
          packName: pack.name,
          isRequired: pack.required,
          userMessage: '${pack.name} incomplete ($count/${pack.fileCount} files)',
          actionLabel: 'Re-download',
        ));
        continue;
      }
      installed.add(pack.id);
    }

    final requiredMissing = missing.where((m) => m.isRequired).toList();
    LoggerService.instance.log(LogLevel.info, 'Assets', 'Verification completed. Root: ${paths.assetsRoot}, Installed: $installed, Missing: ${missing.map((m) => m.packId).toList()}');
    return AssetVerificationResult(
      allRequiredPresent: requiredMissing.isEmpty,
      missing: missing,
      installedPackIds: installed,
      hasAnyEmojis: installed.any((id) => !id.startsWith('font') && !id.startsWith('fontCjk')),
    );
  }

  Future<bool> isPackInstalled(String packId, [AssetManifest? manifest]) async {
    if (kIsWeb) return true;
    final packs = manifest?.packs ?? AssetManifest.getLocalFallbackPacks();
    final pack = packs.firstWhere(
      (p) => p.id == packId,
      orElse: () => const AssetPack(
        id: '',
        name: '',
        description: '',
        required: false,
        sizeBytes: 0,
        compressedSizeBytes: 0,
        downloadUrl: '',
        checksum: '',
        version: '',
        fileCount: 0,
        format: '',
        animated: false,
        localFolder: '',
      ),
    );
    if (pack.id.isEmpty) return false;
    final isFont = pack.id.startsWith('font');
    if (isFont) {
      final fontsDir = FontService.instance.fontsDirectory;
      if (fontsDir.isEmpty) return false;
      return File(p.join(fontsDir, pack.localFolder)).existsSync();
    }
    final dir = Directory(AssetPathService.instance.emojiPackDir(pack.localFolder));
    if (!await dir.exists()) return false;
    try {
      int count = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          count++;
          if (count >= pack.fileCount - 10) {
            return true;
          }
        }
      }
      return count >= pack.fileCount - 10;
    } catch (_) {
      return false;
    }
  }
}

class AssetVerificationNotifier extends StateNotifier<AssetVerificationResult> {
  final Ref? _ref;
  AssetVerificationNotifier(super.state, [this._ref]);

  Future<void> reVerify() async {
    final manifest = _ref?.read(assetManifestProvider);
    final result = await AssetVerificationService.instance.verify(manifest);
    state = result;
  }
}

final assetVerificationProvider = StateNotifierProvider<AssetVerificationNotifier, AssetVerificationResult>((ref) {
  final notifier = AssetVerificationNotifier(
    const AssetVerificationResult(
      allRequiredPresent: true,
      missing: [],
      installedPackIds: [],
      hasAnyEmojis: false,
    ),
    ref,
  );
  notifier.reVerify();
  return notifier;
});

