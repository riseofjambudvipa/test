import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;

import '../logger/logger_service.dart';
import '../assets/asset_path_service.dart';
import '../settings/settings_service.dart';
import 'emoji_model.dart';

export 'emoji_model.dart';

class EmojiService {
  EmojiService._internal();
  static final EmojiService instance = EmojiService._internal();

  @visibleForTesting
  void resetForTesting() {
    _emojis = [];
    _assetsBaseDirectory = null;
    _metadataFilePath = null;
    _groupIndex.clear();
    _glyphIndex = {};
    _unicodeIndex.clear();
    _baseEmojis = [];
    _variationsIndex.clear();
    _multilingualSearchIndex.clear();
    _existingPackFiles.clear();
  }

  void setEmojisForTesting(List<EmojiModel> emojis) {
    _emojis = emojis;
    _buildIndexes();
  }

  List<EmojiModel> _emojis = [];
  String? _assetsBaseDirectory;
  String? _metadataFilePath;

  // Search Indexes
  final Map<String, List<EmojiModel>> _groupIndex = {};
  Map<String, EmojiModel> _glyphIndex = {};
  final Map<String, EmojiModel> _unicodeIndex = {};
  
  // Base emojis only (no skin tone or gender variations)
  List<EmojiModel> _baseEmojis = [];
  
  // Map of parent unicode to its list of variations
  final Map<String, List<EmojiModel>> _variationsIndex = {};

  // Multilingual inverted index: locale -> keyword -> list of emoji indices in _emojis
  final Map<String, Map<String, List<int>>> _multilingualSearchIndex = {};

  // FIX (perf): sorted copy of each locale's keyword keys, so prefix search
  // binary-searches the matching range instead of scanning every key of the
  // index (tens of thousands of entries) per keystroke.
  final Map<String, List<String>> _sortedKeywordKeys = {};

  // Cache of existing files for each pack.
  // Key: lowercase basename (e.g. '1f600.png')
  // Value: relative subpath from the pack dir root (e.g. 'Smileys & Emotion/1f600.png')
  final Map<String, Map<String, String>> _existingPackFiles = {};

  bool get isLoaded => _emojis.isNotEmpty;
  List<EmojiModel> get baseEmojis => _baseEmojis;
  List<EmojiModel> get allEmojis => _emojis;

  String get metadataFilePath => _metadataFilePath ?? p.join(AssetPathService.instance.emojisDir, 'emoji_base.json');

  /// Find EmojiModel by its exact emoji character glyph or prefix (e.g. '🎁' or 'microsoftAnimated:🎁')
  /// Uses O(1) hash-map lookup via [_glyphIndex].
  EmojiModel? findByGlyph(String glyph) {
    final parsed = EmojiPackParser.parse(glyph, '');
    return _glyphIndex[parsed.glyph];
  }

  /// Get details for a given emoji model stub. Since we use a compiled registry,
  /// all details are already preloaded. This returns synchronously wrapped in a Future
  /// to maintain 100% backward compatibility with the rest of the application.
  Future<EmojiModel> getFullDetails(EmojiModel stub) async {
    return stub;
  }

  /// Checks if the emoji is a custom sticker path
  bool isCustomSticker(String emoji) {
    return emoji.contains('/') || emoji.contains('\\');
  }

  /// Checks if a pack is installed (downloaded) on the local disk.
  /// Returns true if we have scanned files for this pack on disk.
  bool isPackInstalled(String packId) {
    final filenames = _existingPackFiles[packId];
    return filenames != null && filenames.isNotEmpty;
  }

  /// Checks if an emoji's asset for the specified pack actually exists on local disk
  bool hasAssetOnDisk(EmojiModel emoji, String packId) {
    if (emoji.group == 'Custom Stickers') return true;
    final filename = emoji.styles[packId];
    if (filename == null || filename.isEmpty) {
      final isAnimated = packId.contains('Animated');
      final ext = isAnimated ? 'webp' : 'png';
      final unicode = emoji.unicode;
      
      final candidates = [
        '$unicode.$ext',
        'emoji_u$unicode.$ext',
        '$unicode.png',
        '$unicode.gif',
        if (unicode.contains('-fe0f')) '${unicode.replaceAll('-fe0f', '')}.$ext',
        if (unicode.contains('-fe0f')) 'emoji_u${unicode.replaceAll('-fe0f', '')}.$ext',
      ];
      
      final fileMap = _existingPackFiles[packId];
      if (fileMap == null) return false;
      
      for (final cand in candidates) {
        if (fileMap.containsKey(cand.toLowerCase())) {
          return true;
        }
      }
      return false;
    }
    
    final fileMap = _existingPackFiles[packId];
    if (fileMap == null) return false;
    // Strip any directory path prefix (e.g. "618x618/") from the mapping before checking disk cache
    final cleanFilename = p.basename(filename).toLowerCase();
    if (fileMap.containsKey(cleanFilename)) return true;
    final nameWithoutExt = p.basenameWithoutExtension(cleanFilename);
    return fileMap.containsKey('$nameWithoutExt.png') ||
        fileMap.containsKey('$nameWithoutExt.gif') ||
        fileMap.containsKey('$nameWithoutExt.webp');
  }

  static Future<Map<String, Map<String, String>>> _scanExistingFilesIsolate(String assetsBaseDir) async {
    final Map<String, Map<String, String>> existingPackFiles = {};
    if (assetsBaseDir.isEmpty) return existingPackFiles;
    
    final packs = [
      'googleAnimated',
      'googleNonAnimated',
      'microsoftAnimated',
      'microsoftNonAnimated',
      'openmoji'
    ];
    
    for (final packId in packs) {
      final folderName = _mapPackIdToFolderStatic(packId);
      var dirPath = p.join(assetsBaseDir, folderName);
      var dir = Directory(dirPath);
      if (!dir.existsSync()) {
        dirPath = p.join(assetsBaseDir, packId);
        dir = Directory(dirPath);
      }
      
      if (dir.existsSync()) {
        // Map: lowercase basename -> relative subpath from pack dir root
        // e.g. '1f600.png' -> 'Smileys & Emotion/1f600.png'
        final Map<String, String> fileMap = {};
        try {
          final entities = dir.listSync(recursive: true);
          for (final entity in entities) {
            if (entity is File) {
              final baseName = p.basename(entity.path).toLowerCase();
              final relPath = p.relative(entity.path, from: dirPath);
              fileMap[baseName] = relPath;
            }
          }
          existingPackFiles[packId] = fileMap;
        } catch (e) {
          LoggerService.instance.log(LogLevel.warning, 'EmojiService',
              'Failed to scan pack files for $packId: $e');
        }
      }
    }
    return existingPackFiles;
  }

  Future<void> _scanExistingFiles(String assetsBaseDir) async {
    _existingPackFiles.clear();
    if (assetsBaseDir.isEmpty) return;
    
    try {
      final result = await compute(_scanExistingFilesIsolate, assetsBaseDir);
      _existingPackFiles.addAll(result);
      LoggerService.instance.log(LogLevel.info, 'EmojiService', 'Scanned emoji packs in background isolate. Total files matched: ${result.values.fold<int>(0, (sum, set) => sum + set.length)}');
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'EmojiService', 'Failed to scan emoji packs in isolate: $e');
    }
  }

  /// Invalidates and re-scans the cache of existing files for a specific pack
  Future<void> invalidatePackCache(String packId) async {
    final baseDir = _assetsBaseDirectory;
    if (baseDir == null || baseDir.isEmpty) return;

    final folderName = _mapPackIdToFolder(packId);
    var dirPath = p.join(baseDir, folderName);
    var dir = Directory(dirPath);
    if (!await dir.exists()) {
      dirPath = p.join(baseDir, packId);
      dir = Directory(dirPath);
    }

    if (await dir.exists()) {
      final Map<String, String> fileMap = {};
      try {
        await for (final entity in dir.list(recursive: true)) {
          if (entity is File) {
            final baseName = p.basename(entity.path).toLowerCase();
            final relPath = p.relative(entity.path, from: dirPath);
            fileMap[baseName] = relPath;
          }
        }
        _existingPackFiles[packId] = fileMap;
        LoggerService.instance.log(LogLevel.info, 'EmojiService', 'Cache invalidated and re-scanned for pack $packId: ${fileMap.length} files.');
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'EmojiService', 'Failed to re-scan for pack $packId: $e');
      }
    } else {
      _existingPackFiles.remove(packId);
    }
  }

  static List<EmojiModel> _parseEmojisIsolate(Map<String, String> params) {
    final baseList = json.decode(params['base']!) as List<dynamic>;
    final langMap = json.decode(params['lang']!) as Map<String, dynamic>;
    
    final List<EmojiModel> list = [];
    for (final item in baseList) {
      final mapItem = item as Map<String, dynamic>;
      final unicode = mapItem['u'] as String;
      
      final langEntry = langMap[unicode] as Map<String, dynamic>?;
      final name = langEntry?['nm'] as String? ?? unicode.replaceAll('-', ' ');
      final keywordsList = langEntry?['kw'] as List<dynamic>?;
      final keywords = keywordsList != null 
          ? List<String>.from(keywordsList) 
          : [name];
          
      list.add(EmojiModel.fromBaseJson(mapItem, name: name, keywords: keywords));
    }
    return list;
  }

  /// Load comprehensive JSON database and setup multilingual indexes
  Future<void> loadMetadata(String metadataFilePath, String assetsBaseDir) async {
    if (isLoaded) {
      return;
    }
    _assetsBaseDirectory = AssetPathService.instance.isInitialized
        ? AssetPathService.instance.emojisDir
        : assetsBaseDir;
    _metadataFilePath = metadataFilePath;
    
    final stopwatch = Stopwatch()..start();
    
    // 1. Scan existing files on disk first (not on web)
    if (!kIsWeb) {
      await _scanExistingFiles(assetsBaseDir);
    }
    
    // 2. Load and parse the base structural JSON and localized names/keywords
    try {
      final baseJsonStr = await rootBundle.loadString('assets/emojis/emoji_base.json');
      
      final activeLocale = activeSearchLocale;
      String langJsonStr;
      try {
        langJsonStr = await rootBundle.loadString('assets/emojis/langs/$activeLocale.json');
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'EmojiService',
            'Failed to load active locale $activeLocale: $e');
        try {
          langJsonStr = await rootBundle.loadString('assets/emojis/langs/en.json');
        } catch (e) {
          LoggerService.instance.log(LogLevel.error, 'EmojiService', 'Failed to load fallback English lang file: $e');
          langJsonStr = '{}';
        }
      }
      
      final parseParams = {
        'base': baseJsonStr,
        'lang': langJsonStr,
      };
      
      _emojis = await compute(_parseEmojisIsolate, parseParams);
      LoggerService.instance.log(LogLevel.info, 'EmojiService', 'Loaded ${_emojis.length} emojis from split-database in ${stopwatch.elapsedMilliseconds}ms.');
    } catch (e, stack) {
      LoggerService.instance.log(LogLevel.error, 'EmojiService', 'Failed to load split-database: $e', stackTrace: stack);
      _emojis = [];
    }
    
    // 3. Auto scan user custom stickers directory
    if (!kIsWeb) {
      String customDir;
      if (AssetPathService.instance.isInitialized) {
        customDir = AssetPathService.instance.customStickersDir;
      } else {
        customDir = p.join(p.dirname(assetsBaseDir), 'custom_stickers');
      }
      final bundledCustomDir = p.join(Directory.current.path, 'assets', 'custom_stickers');
      await scanCustomStickers(customDir, secondaryDirectory: bundledCustomDir);
    } else {
      _buildIndexes();
    }
    
    LoggerService.instance.log(LogLevel.info, 'EmojiService', 'Emoji indexing completed. Total loaded: ${_emojis.length}');
  }

  /// Load and parse a specific language file dynamically, update all emojis in place,
  /// and rebuild search indexes. This runs in under 5ms.
  Future<void> setLanguage(String locale) async {
    // Try the full locale code first (e.g. 'zh-Hant', 'pt-PT'), then fall back
    // to the base language code (e.g. 'zh', 'pt'), then fall back to English.
    // Build without duplicates: normalise underscores to hyphens, then strip to
    // base code only if it differs from the already-normalised full code.
    final normalised = locale.toLowerCase().replaceAll('_', '-');
    final base = normalised.split('-')[0];
    final candidates = [
      normalised,
      if (base != normalised) base,
    ];

    LoggerService.instance.log(LogLevel.info, 'EmojiService',
        'Changing emoji language. Trying candidates: $candidates');

    String? langJson;
    for (final candidate in candidates) {
      try {
        langJson = await rootBundle.loadString('assets/emojis/langs/$candidate.json');
        LoggerService.instance.log(LogLevel.info, 'EmojiService',
            'Loaded emoji lang file: $candidate.json');
        break;
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'EmojiService',
            'Failed to load locale candidate $candidate: $e');
        // continue to next candidate
      }
    }

    if (langJson == null) {
      try {
        langJson = await rootBundle.loadString('assets/emojis/langs/en.json');
        LoggerService.instance.log(LogLevel.warning, 'EmojiService',
            'All locale candidates failed. Fell back to en.json');
      } catch (e) {
        LoggerService.instance.log(LogLevel.error, 'EmojiService',
            'Failed to load fallback English language file: $e');
        return;
      }
    }

    try {
      final Map<String, dynamic> langMap = json.decode(langJson) as Map<String, dynamic>;

      for (var i = 0; i < _emojis.length; i++) {
        final oldModel = _emojis[i];
        final unicode = oldModel.unicode;
        if (oldModel.group == 'Custom Stickers') {
          continue; // Keep custom stickers untouched
        }

        final langEntry = langMap[unicode] as Map<String, dynamic>?;
        final newName = langEntry?['nm'] as String? ?? unicode.replaceAll('-', ' ');
        final keywordsList = langEntry?['kw'] as List<dynamic>?;
        final newKeywords = keywordsList != null
            ? List<String>.from(keywordsList)
            : [newName];

        _emojis[i] = EmojiModel(
          unicode: oldModel.unicode,
          glyph: oldModel.glyph,
          name: newName.toLowerCase(),
          keywords: newKeywords,
          group: oldModel.group,
          styles: oldModel.styles,
          shortcodes: oldModel.shortcodes,
          parentUnicode: oldModel.parentUnicode,
        );
      }

      _buildIndexes();
      LoggerService.instance.log(LogLevel.info, 'EmojiService',
          'Emoji search language updated and indexes rebuilt.');
    } catch (e, stack) {
      LoggerService.instance.log(LogLevel.error, 'EmojiService',
          'Failed to update emoji language: $e', stackTrace: stack);
    }
  }

  /// Loads the generated locales manifest from assets/emojis/locales_manifest.json.
  ///
  /// Returns an ordered list of locale records, each with:
  ///   - 'code': the CLDR locale code (e.g. 'zh-Hant', 'pt-PT')
  ///   - 'name': the locale's native display name (e.g. '中文 (繁體)')
  ///
  /// This is the authoritative source for which locales are available and their
  /// display names. The settings screen reads this list to build its dropdown.
  /// No locale list is hardcoded anywhere in Dart.
  static Future<List<Map<String, String>>> loadLocalesManifest() async {
    try {
      final raw = await rootBundle.loadString('assets/emojis/locales_manifest.json');
      final decoded = json.decode(raw) as List<dynamic>;
      return decoded
          .cast<Map<String, dynamic>>()
          .map((e) => {
                'code': e['code'] as String,
                'name': e['name'] as String,
              })
          .toList();
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'EmojiService',
          'Failed to load locales manifest: $e');
      // Hard fallback: return English only so the dropdown is never empty
      return [
        {'code': 'auto', 'name': 'Auto (System Language)'},
        {'code': 'en', 'name': 'English'},
      ];
    }
  }



  /// Builds O(1) lookup tables, base emoji list, variations map, and inverted search index
  void _buildIndexes() {
    _groupIndex.clear();
    _glyphIndex = {};
    _unicodeIndex.clear();
    _baseEmojis = [];
    _variationsIndex.clear();
    _multilingualSearchIndex.clear();
    _sortedKeywordKeys.clear();

    final activeLocale = activeSearchLocale;
    final localeMap = _multilingualSearchIndex.putIfAbsent(
      activeLocale,
      () => {},
    );

    for (int i = 0; i < _emojis.length; i++) {
      final emoji = _emojis[i];
      _glyphIndex[emoji.glyph] = emoji;
      _unicodeIndex[emoji.unicode] = emoji;

      // Group / Category Index
      final groupKey = emoji.group.toLowerCase();
      _groupIndex.putIfAbsent(groupKey, () => []).add(emoji);

      // Base Emojis vs. Variations
      if (emoji.parentUnicode == null) {
        _baseEmojis.add(emoji);
      } else {
        _variationsIndex.putIfAbsent(emoji.parentUnicode!, () => []).add(emoji);
      }

      if (emoji.group == 'Custom Stickers') {
        // Index custom stickers under activeLocale
        for (final kw in emoji.keywords) {
          final cleanKw = kw.toLowerCase().trim();
          if (cleanKw.isNotEmpty) {
            localeMap.putIfAbsent(cleanKw, () => []).add(i);
          }
        }
        continue;
      }

      // Build Inverted Search Index for active locale
      // 1. Index all keywords
      for (final kw in emoji.keywords) {
        final cleanKw = kw.toLowerCase().trim();
        if (cleanKw.isNotEmpty) {
          localeMap.putIfAbsent(cleanKw, () => []).add(i);
        }
      }

      // 2. Index words from localized name as keywords
      final cleanName = emoji.name.toLowerCase().trim();
      if (cleanName.isNotEmpty) {
        // Index the full name
        localeMap.putIfAbsent(cleanName, () => []).add(i);
        
        // Index individual words in the name
        final words = cleanName.split(RegExp(r'[\s:,\-_]'));
        for (final w in words) {
          final cleanW = w.trim();
          if (cleanW.length > 1) {
            localeMap.putIfAbsent(cleanW, () => []).add(i);
          }
        }
      }
    }

    // FIX (perf): keep a sorted copy of the keyword keys per locale so prefix
    // search can binary-search the matching range instead of scanning every key.
    _sortedKeywordKeys[activeLocale] = localeMap.keys.toList()..sort();
  }

  /// Get the active search language locale.
  /// Reads manual override from settings, falling back to system locale or English.
  String get activeSearchLocale {
    try {
      final override = SettingsService.instance.emojiSearchLanguage;
      if (override != 'auto' && override.isNotEmpty) {
        return override.toLowerCase();
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'EmojiService',
          'Failed to read emojiSearchLanguage setting: $e');
    }
    
    if (kIsWeb) return 'en';
    try {
      return Platform.localeName.split('_')[0].split('-')[0].toLowerCase();
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'EmojiService',
          'Failed to read system locale: $e');
      return 'en';
    }
  }

  /// Search emojis by keyword query using the comprehensive multilingual inverted search index.
  /// Supports exact, prefix, substring, and synonym matching in the active locale.
  List<EmojiModel> search(String query, {String? locale, int limit = 50}) {
    if (_emojis.isEmpty) return const [];
    final cleanQuery = query.toLowerCase().trim();
    if (cleanQuery.isEmpty) return const [];

    final Set<EmojiModel> results = {};

    // 1. Check direct glyph match (e.g. they paste 👍)
    final directMatch = findByGlyph(cleanQuery);
    if (directMatch != null) {
      results.add(directMatch);
    }

    // Determine target locale, falling back to English if not found
    final targetLocale = (locale ?? activeSearchLocale).toLowerCase().split('_')[0].split('-')[0];
    var localeIndex = _multilingualSearchIndex[targetLocale];
    var effectiveLocale = targetLocale;
    if (localeIndex == null && _multilingualSearchIndex.isNotEmpty) {
      // Fallback to whatever active language is loaded
      final firstEntry = _multilingualSearchIndex.entries.first;
      effectiveLocale = firstEntry.key;
      localeIndex = firstEntry.value;
    }
    
    if (localeIndex != null) {
      // 2a. Exact match on keyword index
      final exactMatches = localeIndex[cleanQuery];
      if (exactMatches != null) {
        for (final idx in exactMatches) {
          results.add(_emojis[idx]);
        }
      }
      
      // 2b. Prefix matches on keyword index keys. Binary-search the sorted
      // key list for the prefix range — the old loop scanned EVERY key of
      // the locale index (tens of thousands) per keystroke.
      if (results.length < limit) {
        final sortedKeys = _sortedKeywordKeys[effectiveLocale] ?? const <String>[];
        if (sortedKeys.isNotEmpty) {
          int low = 0;
          int high = sortedKeys.length - 1;
          int first = -1;
          while (low <= high) {
            final mid = low + ((high - low) >> 1);
            if (sortedKeys[mid].compareTo(cleanQuery) >= 0) {
              first = mid;
              high = mid - 1;
            } else {
              low = mid + 1;
            }
          }
          if (first >= 0) {
            for (int k = first; k < sortedKeys.length; k++) {
              final keyword = sortedKeys[k];
              if (!keyword.startsWith(cleanQuery)) break;
              if (keyword == cleanQuery) continue;
              final matches = localeIndex[keyword];
              if (matches != null) {
                for (final idx in matches) {
                  results.add(_emojis[idx]);
                }
              }
              if (results.length >= limit) break;
            }
          }
        }
      }
    }

    // 3. Substring check on names (fallback for unmatched keywords)
    if (results.length < limit) {
      for (final emoji in _emojis) {
        final nameInLang = emoji.name;
        if (nameInLang.contains(cleanQuery)) {
          results.add(emoji);
        }
        if (results.length >= limit) break;
      }
    }

    return results.toList();
  }

  /// Get all emojis in a group (e.g. 'activities', 'smileys & emotion')
  List<EmojiModel> getByGroup(String group) {
    final groupKey = group.toLowerCase().trim();
    return _groupIndex[groupKey] ?? const [];
  }

  /// Get variations for a given base emoji
  List<EmojiModel> getVariations(EmojiModel emoji) {
    return _variationsIndex[emoji.unicode] ?? const [];
  }

  static String _mapPackIdToFolderStatic(String packId) {
    switch (packId) {
      case 'googleAnimated':
        return p.join('google_noto_emojis_animated_pack', '512x512');
      case 'googleNonAnimated':
        return p.join('google_noto_emojis_non_animated_pack', '512x512');
      case 'microsoftAnimated':
        return p.join('microsoft_fluentui_emoji_animated_pack', '256x256');
      case 'microsoftNonAnimated':
        return p.join('microsoft_fluentui_emoji_non_animated_pack', '256x256');
      case 'openmoji':
        return p.join('openmoji_non_animated_pack', '618x618');
      default:
        return packId;
    }
  }

  String _mapPackIdToFolder(String packId) {
    return _mapPackIdToFolderStatic(packId);
  }

  /// Resolves the absolute disk path of the emoji based on pack selection
  EmojiAsset? getAssetPath(EmojiModel emoji, String packId) {
    if (emoji.group == 'Custom Stickers') {
      return EmojiAsset(
        packId: 'custom',
        filename: emoji.styles['custom'] ?? '',
        absolutePath: emoji.glyph,
      );
    }
    if (_assetsBaseDirectory == null) return null;

    var filename = emoji.styles[packId];
    if (filename == null || filename.isEmpty) {
      final isAnimated = packId.contains('Animated');
      final ext = isAnimated ? 'webp' : 'png';
      final unicode = emoji.unicode;
      
      final candidates = [
        '$unicode.$ext',
        'emoji_u$unicode.$ext',
        '$unicode.png',
        '$unicode.gif',
        if (unicode.contains('-fe0f')) '${unicode.replaceAll('-fe0f', '')}.$ext',
        if (unicode.contains('-fe0f')) 'emoji_u${unicode.replaceAll('-fe0f', '')}.$ext',
      ];
      
      final fileMap = _existingPackFiles[packId];
      if (fileMap != null) {
        for (final cand in candidates) {
          if (fileMap.containsKey(cand.toLowerCase())) {
            filename = cand;
            break;
          }
        }
      }
      filename ??= '$unicode.$ext'; // default fallback
    }

    final folderName = _mapPackIdToFolder(packId);
    final cleanFilename = p.basename(filename);

    // Look up the relative subpath (e.g. 'Smileys & Emotion/1f600.png') from the scan cache.
    // This handles the category-subfolder layout introduced after the emoji reorganization.
    final fileMap = _existingPackFiles[packId];
    var relSubPath = fileMap?[cleanFilename.toLowerCase()];
    if (relSubPath == null && fileMap != null) {
      final nameWithoutExt = p.basenameWithoutExtension(cleanFilename).toLowerCase();
      relSubPath = fileMap['$nameWithoutExt.png'] ??
          fileMap['$nameWithoutExt.gif'] ??
          fileMap['$nameWithoutExt.webp'];
    }

    String targetPath;
    if (relSubPath != null) {
      // Found in scan: use the exact relative subpath (includes category folder)
      targetPath = p.join(_assetsBaseDirectory!, folderName, relSubPath);
    } else {
      // Not in scan cache: fall back to flat path (handles test environments and
      // packs that are not yet organised into category subfolders)
      targetPath = p.join(_assetsBaseDirectory!, folderName, cleanFilename);
      // Secondary fallback: raw packId folder (for test environments)
      final mappedDir = Directory(p.join(_assetsBaseDirectory!, folderName));
      if (!mappedDir.existsSync()) {
        targetPath = p.join(_assetsBaseDirectory!, packId, cleanFilename);
      }
    }

    return EmojiAsset(
      packId: packId,
      filename: cleanFilename,
      absolutePath: targetPath,
    );
  }

  static Future<List<EmojiModel>> _scanCustomStickersIsolate(String directoryPath) async {
    final List<EmojiModel> customEmojis = [];
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      try {
        dir.createSync(recursive: true);
      } catch (e) {
        LoggerService.instance.log(LogLevel.warning, 'EmojiService',
            'Failed to create stickers directory: $e');
      }
      return customEmojis;
    }
    
    try {
      final entities = dir.listSync(recursive: true);
      for (final entity in entities) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.png' || ext == '.jpg' || ext == '.jpeg' || ext == '.webp' || ext == '.gif') {
            final filename = p.basename(entity.path);
            final nameWithoutExt = p.basenameWithoutExtension(entity.path);
            
            customEmojis.add(EmojiModel(
              unicode: '',
              glyph: entity.path,
              name: nameWithoutExt.toLowerCase(),
              keywords: [nameWithoutExt.toLowerCase(), 'custom', 'sticker'],
              group: 'Custom Stickers',
              styles: {
                'googleAnimated': filename,
                'googleNonAnimated': filename,
                'microsoftAnimated': filename,
                'microsoftNonAnimated': filename,
                'openmoji': filename,
                'custom': filename
              },
              shortcodes: [nameWithoutExt.toLowerCase()],
              parentUnicode: null,
            ));
          }
        }
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'EmojiService',
          'Failed to scan custom stickers: $e');
    }
    return customEmojis;
  }

  /// Scans the local user stickers folder and registers png/jpg/gif assets as searchable EmojiModels.
  /// Also checks optional secondary directories (e.g. bundled assets/custom_stickers) and copies
  /// missing starter stickers over if primary directory is accessible.
  Future<void> scanCustomStickers(String directoryPath, {String? secondaryDirectory}) async {
    LoggerService.instance.log(LogLevel.info, 'EmojiService', 'Scanning custom stickers in background: $directoryPath');
    try {
      final dirsToScan = <String>[directoryPath];
      if (secondaryDirectory != null && secondaryDirectory.isNotEmpty && secondaryDirectory != directoryPath) {
        final secDir = Directory(secondaryDirectory);
        if (secDir.existsSync()) {
          dirsToScan.add(secondaryDirectory);
          // If primary exists, copy over any bundled starter stickers not yet in primary
          final primDir = Directory(directoryPath);
          if (primDir.existsSync()) {
            try {
              for (final entity in secDir.listSync()) {
                if (entity is File && !p.basename(entity.path).startsWith('.')) {
                  final dest = File(p.join(directoryPath, p.basename(entity.path)));
                  if (!dest.existsSync()) {
                    entity.copySync(dest.path);
                  }
                }
              }
            } catch (e) {
              LoggerService.instance.log(LogLevel.warning, 'EmojiService', 'Could not copy starter stickers: $e');
            }
          }
        }
      }

      final combined = <EmojiModel>[];
      for (final dir in dirsToScan) {
        final result = await compute(_scanCustomStickersIsolate, dir);
        combined.addAll(result);
      }
      
      _emojis.removeWhere((e) => e.group == 'Custom Stickers');
      final existingGlyphs = _emojis.map((e) => e.glyph).toSet();
      
      for (final model in combined) {
        if (!existingGlyphs.contains(model.glyph)) {
          _emojis.add(model);
          existingGlyphs.add(model.glyph);
        }
      }

      _buildIndexes();
      LoggerService.instance.log(LogLevel.info, 'EmojiService', 'Registered custom stickers. Total emojis registered: ${_emojis.length}');
    } catch (e, stackTrace) {
      LoggerService.instance.log(LogLevel.error, 'EmojiService', 'Failed to scan custom stickers: $e', stackTrace: stackTrace);
    }
  }

  /// Resolves a sticker glyph or path string to a valid, existing absolute file path.
  /// Checks direct path, normalized path, and lookup in customStickersDir / bundled assets.
  /// Returns null if the file cannot be located on disk or on web.
  static String? resolveStickerPath(String? glyph) {
    if (kIsWeb || glyph == null || glyph.isEmpty) return null;

    // Check direct path
    try {
      final direct = File(glyph);
      if (direct.existsSync()) return direct.path;
    } catch (_) {}

    // Check normalized path
    try {
      final norm = File(p.normalize(glyph));
      if (norm.existsSync()) return norm.path;
    } catch (_) {}

    // Check by basename in customStickersDir
    final baseName = p.basename(glyph);
    if (AssetPathService.instance.isInitialized) {
      final customDir = AssetPathService.instance.customStickersDir;
      final inCustom = File(p.join(customDir, baseName));
      if (inCustom.existsSync()) return inCustom.path;

      final inAssetsRoot = File(p.join(AssetPathService.instance.assetsRoot, 'custom_stickers', baseName));
      if (inAssetsRoot.existsSync()) return inAssetsRoot.path;
    }

    // Check in bundled assets/custom_stickers
    final bundled = File(p.join(Directory.current.path, 'assets', 'custom_stickers', baseName));
    if (bundled.existsSync()) return bundled.path;

    return null;
  }
}
