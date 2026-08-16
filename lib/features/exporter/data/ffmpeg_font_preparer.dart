import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import '../../../core/logger/logger_service.dart';
import '../../../core/utils/app_dirs.dart';
import '../../../core/utils/font_metadata_reader.dart';
import '../../../core/assets/asset_path_service.dart';

const List<String> _bundledFontAssets = [
  'Anton-Regular.ttf',
  'Bangers-Regular.ttf',
  'BebasNeue-Regular.ttf',
  'BlackHanSans-Regular.ttf',
  'Caveat-Variable.ttf',
  'ComicNeue-Bold.ttf',
  'DancingScript-Variable.ttf',
  'DMSerifDisplay-Regular.ttf',
  'Exo2-Variable.ttf',
  'Fraunces-Variable.ttf',
  'Gabarito-Variable.ttf',
  'Lobster-Regular.ttf',
  'Montserrat-Variable.ttf',
  'NotoNastaliqUrdu-Variable.ttf',
  'NotoSans-Variable.ttf',
  'NotoSansArabic-Variable.ttf',
  'NotoSansArmenian-Variable.ttf',
  'NotoSansBengali-Variable.ttf',
  'NotoSansDevanagari-Variable.ttf',
  'NotoSansEthiopic-Variable.ttf',
  'NotoSansGeorgian-Variable.ttf',
  'NotoSansGujarati-Variable.ttf',
  'NotoSansGurmukhi-Variable.ttf',
  'NotoSansHebrew-Variable.ttf',
  'NotoSansJP-Bold.ttf',
  'NotoSansKannada-Variable.ttf',
  'NotoSansKhmer-Variable.ttf',
  'NotoSansKR-Bold.ttf',
  'NotoSansLao-Variable.ttf',
  'NotoSansMalayalam-Variable.ttf',
  'NotoSansMyanmar-Variable.ttf',
  'NotoSansOriya-Variable.ttf',
  'NotoSansSC-Bold.ttf',
  'NotoSansSinhala-Variable.ttf',
  'NotoSansTamil-Variable.ttf',
  'NotoSansTC-Bold.ttf',
  'NotoSansTelugu-Variable.ttf',
  'NotoSansThai-Variable.ttf',
  'Nunito-Variable.ttf',
  'Orbitron-Variable.ttf',
  'Oswald-Variable.ttf',
  'Outfit-Variable.ttf',
  'Pacifico-Regular.ttf',
  'PlayfairDisplay-Variable.ttf',
  'Poppins-Bold.ttf',
  'Poppins-ExtraBold.ttf',
  'PressStart2P-Regular.ttf',
  'Raleway-Variable.ttf',
  'Righteous-Regular.ttf',
  'RubikGlitch-Regular.ttf',
  'SpaceGrotesk-Variable.ttf',
  'Urbanist-Variable.ttf',
];

const Map<String, String> _fontFileToFamily = {
  'Anton-Regular.ttf': 'Anton',
  'Bangers-Regular.ttf': 'Bangers',
  'BebasNeue-Regular.ttf': 'Bebas Neue',
  'BlackHanSans-Regular.ttf': 'Black Han Sans',
  'Caveat-Variable.ttf': 'Caveat',
  'ComicNeue-Bold.ttf': 'Comic Neue',
  'DancingScript-Variable.ttf': 'Dancing Script',
  'DMSerifDisplay-Regular.ttf': 'DM Serif Display',
  'Exo2-Variable.ttf': 'Exo 2',
  'Fraunces-Variable.ttf': 'Fraunces',
  'Gabarito-Variable.ttf': 'Gabarito',
  'Lobster-Regular.ttf': 'Lobster',
  'Montserrat-Variable.ttf': 'Montserrat',
  'NotoNastaliqUrdu-Variable.ttf': 'Noto Nastaliq Urdu',
  'NotoSans-Variable.ttf': 'Noto Sans',
  'NotoSansArabic-Variable.ttf': 'Noto Sans Arabic',
  'NotoSansArmenian-Variable.ttf': 'Noto Sans Armenian',
  'NotoSansBengali-Variable.ttf': 'Noto Sans Bengali',
  'NotoSansDevanagari-Variable.ttf': 'Noto Sans Devanagari',
  'NotoSansEthiopic-Variable.ttf': 'Noto Sans Ethiopic',
  'NotoSansGeorgian-Variable.ttf': 'Noto Sans Georgian',
  'NotoSansGujarati-Variable.ttf': 'Noto Sans Gujarati',
  'NotoSansGurmukhi-Variable.ttf': 'Noto Sans Gurmukhi',
  'NotoSansHebrew-Variable.ttf': 'Noto Sans Hebrew',
  'NotoSansJP-Bold.ttf': 'Noto Sans JP',
  'NotoSansKannada-Variable.ttf': 'Noto Sans Kannada',
  'NotoSansKhmer-Variable.ttf': 'Noto Sans Khmer',
  'NotoSansKR-Bold.ttf': 'Noto Sans KR',
  'NotoSansLao-Variable.ttf': 'Noto Sans Lao',
  'NotoSansMalayalam-Variable.ttf': 'Noto Sans Malayalam',
  'NotoSansMyanmar-Variable.ttf': 'Noto Sans Myanmar',
  'NotoSansOriya-Variable.ttf': 'Noto Sans Oriya',
  'NotoSansSC-Bold.ttf': 'Noto Sans SC',
  'NotoSansSinhala-Variable.ttf': 'Noto Sans Sinhala',
  'NotoSansTamil-Variable.ttf': 'Noto Sans Tamil',
  'NotoSansTC-Bold.ttf': 'Noto Sans TC',
  'NotoSansTelugu-Variable.ttf': 'Noto Sans Telugu',
  'NotoSansThai-Variable.ttf': 'Noto Sans Thai',
  'Nunito-Variable.ttf': 'Nunito',
  'Orbitron-Variable.ttf': 'Orbitron',
  'Oswald-Variable.ttf': 'Oswald',
  'Outfit-Variable.ttf': 'Outfit',
  'Pacifico-Regular.ttf': 'Pacifico',
  'PlayfairDisplay-Variable.ttf': 'Playfair Display',
  'Poppins-Bold.ttf': 'Poppins',
  'Poppins-ExtraBold.ttf': 'Poppins',
  'PressStart2P-Regular.ttf': 'Press Start 2P',
  'Raleway-Variable.ttf': 'Raleway',
  'Righteous-Regular.ttf': 'Righteous',
  'RubikGlitch-Regular.ttf': 'Rubik Glitch',
  'SpaceGrotesk-Variable.ttf': 'Space Grotesk',
  'Urbanist-Variable.ttf': 'Urbanist',
};

/// Font preparation for FFmpeg: bundles the app fonts into a directory FFmpeg
/// can use for the subtitles filter, on every platform.
mixin FfmpegFontPreparation {
  bool _fontsPrepared = false;

  String? getSafeFontsDir() {
    try {
      return AssetPathService.instance.fontsDir;
    } catch (_) {
      return null;
    }
  }

  String? getSafeAppDirsFonts() {
    try {
      return AppDirs.fonts;
    } catch (_) {
      return null;
    }
  }

  Future<void> prepareFonts() async {
    if (_fontsPrepared) {
      return;
    }
    final customPath = getSafeAppDirsFonts();
    final destPath = getSafeFontsDir();
    if (customPath == null || destPath == null) {
      LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'AppDirs or AssetPathService not initialized. Skipping font preparation.');
      return;
    }
    try {
      final destFontsDir = Directory(destPath);
      if (!destFontsDir.existsSync()) {
        await destFontsDir.create(recursive: true);
      }

      // Copy LICENSE.txt
      if (Platform.isAndroid || Platform.isIOS) {
        try {
          final byteData = await rootBundle.load('assets/fonts/LICENSE.txt');
          final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
          final licenseFile = File(p.join(destFontsDir.path, 'LICENSE.txt'));
          await licenseFile.writeAsBytes(bytes);
          LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Copied LICENSE.txt to FFmpeg fonts directory.');
        } catch (e) {
          LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter', 'Failed to copy LICENSE.txt: $e');
        }

        // Copy bundled fonts to their structured subdirectories on mobile
        final allAssets = [
          ..._bundledFontAssets,
          'NotoColorEmoji.ttf',
        ];
        for (final fontName in allAssets) {
          String assetSubpath;
          if (fontName == 'NotoColorEmoji.ttf') {
            assetSubpath = 'emoji';
          } else if (fontName.startsWith('Noto')) {
            assetSubpath = 'languages';
          } else {
            assetSubpath = 'design';
          }

          final targetFolder = Directory(p.join(destFontsDir.path, assetSubpath));
          if (!targetFolder.existsSync()) {
            await targetFolder.create(recursive: true);
          }

          final destFile = File(p.join(targetFolder.path, fontName));
          if (!destFile.existsSync()) {
            try {
              final byteData = await rootBundle.load('assets/fonts/$assetSubpath/$fontName');
              final bytes = byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes);
              await destFile.writeAsBytes(bytes);
              LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Copied bundled asset font $fontName to assets/fonts/$assetSubpath.');
            } catch (e) {
              LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter', 'Failed to copy bundled asset font $fontName: $e');
            }
          }
        }
      } else {
        // Desktop fallback: copy organized directories directly from app package/bundle
        final bundledPaths = [
          p.join(Directory.current.path, 'assets', 'fonts'),
          p.join(Directory.current.path, 'Capstudio Flutter', 'assets', 'fonts'),
          p.join(Directory.current.path, 'data', 'flutter_assets', 'assets', 'fonts'),
        ];

        for (final path in bundledPaths) {
          final dir = Directory(path);
          if (dir.existsSync()) {
            LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Found bundled fonts directory: $path');

            // Copy LICENSE.txt
            final licenseSource = File(p.join(dir.path, 'LICENSE.txt'));
            if (licenseSource.existsSync()) {
              final licenseDest = File(p.join(destFontsDir.path, 'LICENSE.txt'));
              await licenseSource.copy(licenseDest.path);
            }

            final subdirs = ['design', 'languages', 'emoji'];
            for (final subdir in subdirs) {
              final subFolder = Directory(p.join(dir.path, subdir));
              if (subFolder.existsSync()) {
                final targetSubfolder = Directory(p.join(destFontsDir.path, subdir));
                if (!targetSubfolder.existsSync()) {
                  await targetSubfolder.create(recursive: true);
                }

                await for (final entity in subFolder.list()) {
                  if (entity is File) {
                    final ext = p.extension(entity.path).toLowerCase();
                    if (ext == '.ttf' || ext == '.otf') {
                      final destFile = File(p.join(targetSubfolder.path, p.basename(entity.path)));
                      if (!destFile.existsSync()) {
                        await entity.copy(destFile.path);
                        LoggerService.instance.log(LogLevel.info, 'FfmpegExporter', 'Copied bundled font ${p.basename(entity.path)} to assets/fonts/$subdir.');
                      }
                    }
                  }
                }
              }
            }
            break; // Stop after finding the first valid folder
          }
        }
      }
      _fontsPrepared = true;
    } catch (e, stack) {
      LoggerService.instance.log(LogLevel.warning, 'FfmpegExporter', 'Failed to copy fonts to assets/fonts: $e', stackTrace: stack);
    }
  }

  // Dynamic flat font creation and aliasing for FFmpeg
  Future<String> prepareTempFontsDir(String tempDir) async {
    final tempFontsDir = Directory(p.join(tempDir, 'ffmpeg_fonts'));
    if (tempFontsDir.existsSync()) {
      try {
        tempFontsDir.deleteSync(recursive: true);
      } catch (_) {}
    }
    await tempFontsDir.create(recursive: true);

    final destPath = getSafeFontsDir();
    final customPath = getSafeAppDirsFonts();

    Future<void> createAlias(File file, String baseName) async {
      final meta = await FontMetadataReader.readMetadata(file);
      final familyName = meta?.familyName ?? _fontFileToFamily[baseName];
      if (familyName != null) {
        final ext = p.extension(baseName);
        final aliasFile = File(p.join(tempFontsDir.path, '$familyName$ext'));
        if (!aliasFile.existsSync()) {
          await file.copy(aliasFile.path);
        }
        final postScript = meta?.postScriptName;
        if (postScript != null && postScript != familyName) {
          final psFile = File(p.join(tempFontsDir.path, '$postScript$ext'));
          if (!psFile.existsSync()) {
            await file.copy(psFile.path);
          }
        }
      }
    }

    Future<void> copyFontsFromDir(Directory dir) async {
      if (!dir.existsSync()) return;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.ttf' || ext == '.otf') {
            final filename = p.basename(entity.path);
            if (filename == 'NotoColorEmoji.ttf') {
              continue; // Skip large color emoji font to prevent metadata warnings and save memory
            }
            final destFile = File(p.join(tempFontsDir.path, filename));
            if (!destFile.existsSync()) {
              await entity.copy(destFile.path);
            }
            await createAlias(destFile, filename);
          }
        }
      }
    }

    if (destPath != null) {
      await copyFontsFromDir(Directory(destPath));
    }
    if (customPath != null) {
      final customSubdir = Directory(p.join(customPath, 'Custom'));
      await copyFontsFromDir(customSubdir);
    }

    return tempFontsDir.path;
  }
}
