import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_dirs.dart';
import '../utils/platform_utils.dart' as platform_utils;

/// Single source of truth for where CapStudio assets live on disk.
/// Mobile: OS-managed. Desktop: user-configurable, saved in prefs.
class AssetPathService {
  AssetPathService._();
  static final AssetPathService instance = AssetPathService._();

  static const _prefKey = 'capstudio_assets_folder';
  String? _assetsRoot;
  bool _assetsRootExists = true;

  bool get isDesktop => !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  bool get isMobile  => platform_utils.isMobile;
  bool get isWeb => kIsWeb;

  bool get assetsRootExists => _assetsRootExists;

  String get assetsRoot {
    if (_assetsRoot == null) {
      final isTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
      if (isTesting) {
        return Directory.systemTemp.path;
      }
      throw StateError('AssetPathService.init() not called');
    }
    return _assetsRoot!;
  }

  String get emojisDir => p.join(assetsRoot, 'emojis');
  String get fontsDir  => p.join(assetsRoot, 'fonts');
  String get sfxDir    => p.join(assetsRoot, 'sfx');
  String get tempDir   => p.join(assetsRoot, 'temp');
  String get customStickersDir => p.join(assetsRoot, 'custom_stickers');

  String emojiPackDir(String packFolderName) => p.join(emojisDir, packFolderName);

  // ─── Init ────────────────────────────────────────────────────────────────

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    final isTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (_isInitialized && !isTesting) return;
    _isInitialized = true;
    try {
      if (kIsWeb) {
        await _initWeb();
      } else if (Platform.isAndroid) {
        await _initAndroid();
      } else if (Platform.isIOS) {
        await _initIOS();
      } else {
        await _initDesktop();
      }
      await _ensureDirectories();
      await checkAssetsRootExists();
    } catch (e) {
      _isInitialized = false;
      rethrow;
    }
  }

  Future<void> _initWeb() async {
    _assetsRoot = 'web_assets';
  }

  Future<bool> checkAssetsRootExists() async {
    if (kIsWeb) {
      _assetsRootExists = true;
      return true;
    }
    if (_assetsRoot != null) {
      _assetsRootExists = await Directory(_assetsRoot!).exists();
    }
    return _assetsRootExists;
  }

  Future<void> _initAndroid() async {
    final ext = await getExternalStorageDirectory();
    if (ext != null) {
      _assetsRoot = p.join(ext.path, 'CapStudio', 'assets');
    } else {
      final doc = await getApplicationDocumentsDirectory();
      _assetsRoot = p.join(doc.path, 'CapStudio', 'assets');
    }
  }

  Future<void> _initIOS() async {
    final doc = await getApplicationDocumentsDirectory();
    _assetsRoot = p.join(doc.path, 'CapStudio', 'assets');
  }

  Future<void> _initDesktop() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefKey);
    if (saved != null && saved.isNotEmpty) {
      _assetsRoot = saved;
    } else {
      _assetsRoot = AppDirs.assets;
    }
  }

  /// Desktop only: save user-chosen folder. Call after folder picker confirms.
  Future<void> setDesktopAssetsFolder(String userPickedRoot) async {
    if (!isDesktop) {
      throw UnsupportedError('setDesktopAssetsFolder is only supported on desktop platforms.');
    }
    
    var cleanRoot = userPickedRoot.trim();

    // 1. If the user picked a subdirectory of the assets folder:
    // Case A: Picked the 'emojis', 'fonts', 'sfx', 'custom_stickers', or 'temp' directory itself
    var dirName = p.basename(cleanRoot).toLowerCase();
    if (const {'emojis', 'fonts', 'sfx', 'custom_stickers', 'temp'}.contains(dirName)) {
      cleanRoot = p.dirname(cleanRoot);
      dirName = p.basename(cleanRoot).toLowerCase();
    }

    // Case B: Picked an emoji pack folder (e.g. 'google_noto_emojis_non_animated_pack')
    if (cleanRoot.endsWith('_pack') || p.basename(p.dirname(cleanRoot)).toLowerCase() == 'emojis') {
      final parent = p.dirname(cleanRoot);
      if (p.basename(parent).toLowerCase() == 'emojis') {
        cleanRoot = p.dirname(parent);
        dirName = p.basename(cleanRoot).toLowerCase();
      }
    }

    // 2. Now check if this resolved folder contains emojis or fonts directly
    final hasEmojis = Directory(p.join(cleanRoot, 'emojis')).existsSync();
    final hasFonts = Directory(p.join(cleanRoot, 'fonts')).existsSync();

    if (hasEmojis || hasFonts) {
      _assetsRoot = cleanRoot;
    } else {
      // 3. Prevent double nesting if they selected a CapStudio or assets folder that is currently empty.
      if (dirName == 'assets' && p.basename(p.dirname(cleanRoot)).toLowerCase() == 'capstudio') {
        _assetsRoot = cleanRoot;
      } else if (dirName == 'capstudio') {
        _assetsRoot = p.join(cleanRoot, 'assets');
      } else {
        // Fallback: create CapStudio/assets inside the picked directory
        _assetsRoot = p.join(cleanRoot, 'CapStudio', 'assets');
      }
    }
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _assetsRoot!);
    await _ensureDirectories();
    await checkAssetsRootExists();
  }

  Future<bool> get hasConfiguredAssetsFolder async {
    if (isMobile) return true;
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_prefKey);
  }

  Future<void> _ensureDirectories() async {
    if (kIsWeb) return;
    for (final dir in [assetsRoot, emojisDir, fontsDir, sfxDir, tempDir, customStickersDir]) {
      await Directory(dir).create(recursive: true);
    }
  }

  // Pack folder names — must match your zip exactly
  static String? packFolderName(String packId) => const {
    'googleAnimated':       'google_noto_emojis_animated_pack',
    'googleNonAnimated':    'google_noto_emojis_non_animated_pack',
    'microsoftAnimated':    'microsoft_fluentui_emoji_animated_pack',
    'microsoftNonAnimated': 'microsoft_fluentui_emoji_non_animated_pack',
    'openmoji':             'openmoji_non_animated_pack',
    'fontCjkSc':            'fonts',
    'fontCjkJp':            'fonts',
    'fontCjkKr':            'fonts',
    'fontCjkTc':            'fonts',
  }[packId];

  // Subdirectory within pack folder where image files live
  static String packSubdir(String packId) => const {
    'googleAnimated':       '512x512/',
    'googleNonAnimated':    '512x512/',
    'microsoftAnimated':    '256x256/',
    'microsoftNonAnimated': '256x256/',
    'openmoji':             '618x618/',
  }[packId] ?? '';
}
