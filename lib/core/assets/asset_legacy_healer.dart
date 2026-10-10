import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import '../logger/logger_service.dart';
import 'asset_path_service.dart';

/// Automatically detects and heals legacy or mislocated asset pack extractions.
///
/// Handles scenarios where:
/// 1. Archives were extracted directly into `assets/emojis/` creating loose resolution
///    directories (`618x618`, `512x512`, `256x256`) and root files (`LICENSE.md`).
/// 2. Packs were stored using legacy pack IDs (`openmoji`, `googleNonAnimated`, etc.)
///    instead of manifest `localFolder` names.
/// 3. Archives were extracted with redundant double nesting
///    (`openmoji_non_animated_pack/openmoji_non_animated_pack/`).
class AssetLegacyHealer {
  const AssetLegacyHealer._();

  static const Map<String, String> legacyFolderMap = {
    'openmoji': 'openmoji_non_animated_pack',
    'googleNonAnimated': 'google_noto_emojis_non_animated_pack',
    'googleAnimated': 'google_noto_emojis_animated_pack',
    'microsoftNonAnimated': 'microsoft_fluentui_emoji_non_animated_pack',
    'microsoftAnimated': 'microsoft_fluentui_emoji_animated_pack',
  };

  /// Heals any legacy extractions in [emojisDirectory] (defaults to [AssetPathService.instance.emojisDir]).
  /// Returns the list of pack IDs that were healed / migrated.
  static Future<List<String>> heal([String? emojisDirectory]) async {
    if (kIsWeb) return const [];
    final healedPackIds = <String>{};

    try {
      final emojisDir = emojisDirectory ?? AssetPathService.instance.emojisDir;
      final rootDir = Directory(emojisDir);
      if (!rootDir.existsSync()) return const [];

      // 1. Heal OpenMoji loose 618x618 folder
      final healedOpenMoji = await _healLooseResolutionFolder(
        emojisDir: emojisDir,
        resolutionFolderName: '618x618',
        targetPackFolder: 'openmoji_non_animated_pack',
        associatedFiles: const ['LICENSE.md'],
      );
      if (healedOpenMoji) {
        healedPackIds.add('openmoji');
      }

      // 2. Heal Google Noto loose 512x512 folder
      final healedGoogle = await _healAmbiguousResolutionFolder(
        emojisDir: emojisDir,
        resolutionFolderName: '512x512',
        animatedPackFolder: 'google_noto_emojis_animated_pack',
        nonAnimatedPackFolder: 'google_noto_emojis_non_animated_pack',
      );
      if (healedGoogle != null) {
        healedPackIds.add(healedGoogle == 'google_noto_emojis_animated_pack'
            ? 'googleAnimated'
            : 'googleNonAnimated');
      }

      // 3. Heal Microsoft FluentUI loose 256x256 folder
      final healedMicrosoft = await _healAmbiguousResolutionFolder(
        emojisDir: emojisDir,
        resolutionFolderName: '256x256',
        animatedPackFolder: 'microsoft_fluentui_emoji_animated_pack',
        nonAnimatedPackFolder: 'microsoft_fluentui_emoji_non_animated_pack',
      );
      if (healedMicrosoft != null) {
        healedPackIds.add(healedMicrosoft == 'microsoft_fluentui_emoji_animated_pack'
            ? 'microsoftAnimated'
            : 'microsoftNonAnimated');
      }

      // 4. Heal legacy pack ID folder names
      for (final entry in legacyFolderMap.entries) {
        final oldDir = Directory(p.join(emojisDir, entry.key));
        final newDir = Directory(p.join(emojisDir, entry.value));
        if (oldDir.existsSync()) {
          if (!newDir.existsSync()) {
            _safeMoveDirectory(oldDir, newDir);
            healedPackIds.add(entry.key);
            LoggerService.instance.log(LogLevel.info, 'AssetLegacyHealer',
                'Migrated legacy pack directory "${entry.key}" to "${entry.value}"');
          } else {
            _mergeDirectory(oldDir, newDir);
            try {
              oldDir.deleteSync(recursive: true);
            } catch (_) {}
            healedPackIds.add(entry.key);
          }
        }
      }

      // 5. Heal double-nested folders
      for (final packFolder in legacyFolderMap.values) {
        final nestedDir = Directory(p.join(emojisDir, packFolder, packFolder));
        final parentDir = Directory(p.join(emojisDir, packFolder));
        if (nestedDir.existsSync()) {
          _mergeDirectory(nestedDir, parentDir);
          try {
            nestedDir.deleteSync(recursive: true);
          } catch (_) {}
          LoggerService.instance.log(LogLevel.info, 'AssetLegacyHealer',
              'Un-nested double folder for "$packFolder"');
          // Find packId for this folder
          for (final entry in legacyFolderMap.entries) {
            if (entry.value == packFolder) healedPackIds.add(entry.key);
          }
        }
      }
    } catch (e, stackTrace) {
      LoggerService.instance.log(LogLevel.warning, 'AssetLegacyHealer',
          'Legacy asset healing encountered an error (continuing safely): $e',
          stackTrace: stackTrace);
    }

    return healedPackIds.toList();
  }

  static Future<bool> _healLooseResolutionFolder({
    required String emojisDir,
    required String resolutionFolderName,
    required String targetPackFolder,
    List<String> associatedFiles = const [],
  }) async {
    final looseResDir = Directory(p.join(emojisDir, resolutionFolderName));
    final targetPackDir = Directory(p.join(emojisDir, targetPackFolder));
    final targetResDir = Directory(p.join(targetPackDir.path, resolutionFolderName));

    bool healed = false;
    if (looseResDir.existsSync()) {
      if (!targetResDir.existsSync()) {
        targetPackDir.createSync(recursive: true);
        _safeMoveDirectory(looseResDir, targetResDir);
        healed = true;
        LoggerService.instance.log(LogLevel.info, 'AssetLegacyHealer',
            'Migrated loose $resolutionFolderName folder to $targetPackFolder/$resolutionFolderName');
      } else {
        _mergeDirectory(looseResDir, targetResDir);
        try {
          looseResDir.deleteSync(recursive: true);
        } catch (_) {}
        healed = true;
      }
    }

    for (final filename in associatedFiles) {
      final looseFile = File(p.join(emojisDir, filename));
      if (looseFile.existsSync()) {
        final targetFile = File(p.join(targetPackDir.path, filename));
        if (!targetFile.existsSync()) {
          targetPackDir.createSync(recursive: true);
          try {
            looseFile.copySync(targetFile.path);
          } catch (_) {}
        }
        try {
          looseFile.deleteSync();
        } catch (_) {}
      }
    }

    return healed;
  }

  static Future<String?> _healAmbiguousResolutionFolder({
    required String emojisDir,
    required String resolutionFolderName,
    required String animatedPackFolder,
    required String nonAnimatedPackFolder,
  }) async {
    final looseResDir = Directory(p.join(emojisDir, resolutionFolderName));
    if (!looseResDir.existsSync()) return null;

    bool isAnimated = false;
    try {
      for (final entity in looseResDir.listSync(recursive: true)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.gif' || ext == '.webp') {
            isAnimated = true;
            break;
          }
        }
      }
    } catch (_) {}

    final chosenPack = isAnimated ? animatedPackFolder : nonAnimatedPackFolder;
    final targetPackDir = Directory(p.join(emojisDir, chosenPack));
    final targetResDir = Directory(p.join(targetPackDir.path, resolutionFolderName));

    if (!targetResDir.existsSync()) {
      targetPackDir.createSync(recursive: true);
      _safeMoveDirectory(looseResDir, targetResDir);
      LoggerService.instance.log(LogLevel.info, 'AssetLegacyHealer',
          'Migrated loose $resolutionFolderName folder to $chosenPack/$resolutionFolderName');
    } else {
      _mergeDirectory(looseResDir, targetResDir);
      try {
        looseResDir.deleteSync(recursive: true);
      } catch (_) {}
    }

    return chosenPack;
  }

  static void _safeMoveDirectory(Directory source, Directory destination) {
    try {
      source.renameSync(destination.path);
    } catch (_) {
      _mergeDirectory(source, destination);
      try {
        source.deleteSync(recursive: true);
      } catch (_) {}
    }
  }

  static void _mergeDirectory(Directory source, Directory destination) {
    if (!source.existsSync()) return;
    if (!destination.existsSync()) {
      destination.createSync(recursive: true);
    }
    for (final entity in source.listSync(recursive: true)) {
      final relPath = p.relative(entity.path, from: source.path);
      final destPath = p.join(destination.path, relPath);
      if (entity is Directory) {
        Directory(destPath).createSync(recursive: true);
      } else if (entity is File) {
        final df = File(destPath);
        if (!df.existsSync()) {
          Directory(p.dirname(destPath)).createSync(recursive: true);
          try {
            entity.copySync(destPath);
          } catch (_) {}
        }
      }
    }
  }
}
