import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as p;
import '../logger/logger_service.dart';
import '../utils/app_dirs.dart';

class FontService {
  FontService._internal();
  static final FontService instance = FontService._internal();

  final Map<String, String> _loadedFonts = {}; // name → path
  String? _fontsDirectory;
  List<String>? _cachedAvailableFonts;

  @visibleForTesting
  void resetForTesting() {
    _loadedFonts.clear();
    _cachedAvailableFonts = null;
  }

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    final isTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (_isInitialized && !isTesting) return;
    _isInitialized = true;
    try {
      if (kIsWeb) {
        LoggerService.instance.log(LogLevel.info, 'FontService', 'Custom Font Service successfully initialized (Web).');
        return;
      }
      // Use AppDirs.fonts → AppData\Roaming\CapStudio\fonts\
      _fontsDirectory = AppDirs.fonts;
      await Directory(_fontsDirectory!).create(recursive: true);
      await _loadExistingFonts();
      LoggerService.instance.log(LogLevel.info, 'FontService', 'Custom Font Service successfully initialized.');
    } catch (e) {
      _isInitialized = false;
      LoggerService.instance.log(LogLevel.error, 'FontService', 'Failed to initialize Custom Font Service: $e');
    }
  }

  String get fontsDirectory => _fontsDirectory ?? '';

  Future<void> _loadExistingFonts() async {
    final customDir = Directory(p.join(_fontsDirectory!, 'Custom'));
    if (!customDir.existsSync()) {
      await customDir.create(recursive: true);
    }

    final dirsToScan = [customDir, Directory(_fontsDirectory!)];
    for (final dir in dirsToScan) {
      if (!dir.existsSync()) continue;
      await for (final entity in dir.list()) {
        if (entity is File) {
          final ext = p.extension(entity.path).toLowerCase();
          if (ext == '.ttf' || ext == '.otf') {
            try {
              await _registerFont(entity.path);
            } catch (e, stackTrace) {
              LoggerService.instance.log(
                LogLevel.warning,
                'FontService',
                'Failed to load custom font file: ${entity.path}. Error: $e',
                stackTrace: stackTrace,
              );
            }
          }
        }
      }
    }
  }

  Future<String?> importFont(String sourcePath) async {
    try {
      final file = File(sourcePath);
      if (!file.existsSync()) return null;

      final extension = p.extension(sourcePath);
      final baseName = p.basenameWithoutExtension(sourcePath);
      var fileName = p.basename(sourcePath);
      
      final customDir = p.join(_fontsDirectory!, 'Custom');
      await Directory(customDir).create(recursive: true);
      var destPath = p.join(customDir, fileName);
      
      int suffix = 1;
      while (File(destPath).existsSync()) {
        fileName = '${baseName}_$suffix$extension';
        destPath = p.join(customDir, fileName);
        suffix++;
      }
      
      await file.copy(destPath);
      
      final fontName = await _registerFont(destPath);
      LoggerService.instance.log(LogLevel.action, 'FontService', 'Successfully imported and registered custom font: "$fontName".');
      return fontName;
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'FontService', 'Failed to import custom font from path: $sourcePath, error: $e');
      return null;
    }
  }

  Future<String?> importFontBytes(Uint8List bytes, String fontName, {String? fileExtension}) async {
    try {
      if (bytes.isEmpty) return null;
      if (bytes.length > 50 * 1024 * 1024) {
        throw Exception('Font file is too large (max 50MB): ${bytes.length} bytes');
      }
      
      final normalizedName = normalizeFontName(fontName);
      
      final fontLoader = FontLoader(normalizedName);
      fontLoader.addFont(Future.value(ByteData.view(bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes)));
      await fontLoader.load();
      
      String fontPath = 'memory';
      if (!kIsWeb && _fontsDirectory != null) {
        final ext = fileExtension ?? 'ttf';
        final fileName = '$normalizedName.$ext';
        final customDir = p.join(_fontsDirectory!, 'Custom');
        await Directory(customDir).create(recursive: true);
        final destPath = p.join(customDir, fileName);
        await File(destPath).writeAsBytes(bytes);
        fontPath = destPath;
      }
      
      _loadedFonts[normalizedName] = fontPath;
      _cachedAvailableFonts = null;
      
      LoggerService.instance.log(LogLevel.action, 'FontService', 'Successfully registered custom font from bytes: "$normalizedName" (Saved to: $fontPath).');
      return normalizedName;
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'FontService', 'Failed to import custom font from bytes, error: $e');
      return null;
    }
  }

  String normalizeFontName(String filename) {
    var name = filename.replaceAll(
      RegExp(r'-(Regular|Bold|Black|Medium|ExtraBold|SemiBold|Light|Thin|Italic|BoldItalic|Condensed)', caseSensitive: false),
      '',
    );
    if (name.startsWith('NotoSans')) {
      name = name.replaceFirst('NotoSans', 'Noto Sans ');
    }
    return name;
  }

  Future<void> registerDownloadedFont(String fontPath) async {
    await _registerFont(fontPath);
  }

  void unregisterFont(String fontName) {
    _loadedFonts.remove(fontName);
    _cachedAvailableFonts = null;
  }

  // FIX (Issue #6, CapStudio 1.0 audit): this list previously existed as two
  // separately hand-maintained copies — one inline in _registerFont's
  // collision check, one inline in availableFonts' getter. If a bundled
  // font were ever added to one and not the other, a custom import with a
  // colliding name could silently misbehave. Single source of truth now.
  static const List<String> _bundledFontNames = [
    // Built-in style templates fonts
    'Montserrat', 'Anton', 'Bebas Neue', 'Poppins', 'Outfit',
    'Raleway', 'Orbitron', 'Urbanist', 'DM Serif Display',
    'Comic Neue', 'Fraunces', 'Gabarito', 'Rubik Glitch',
    'Courier New', 'Bangers', 'Pacifico', 'Oswald', 'Righteous',
    'Caveat', 'Exo 2', 'Nunito', 'Space Grotesk',
    // Bundled Language Fonts (Noto)
    'Noto Sans', 'Noto Sans Devanagari', 'Noto Sans Arabic',
    'Noto Sans Thai', 'Noto Sans Hebrew', 'Noto Sans Tamil',
    'Noto Sans Telugu', 'Noto Sans Bengali', 'Noto Sans Gujarati',
    'Noto Sans Kannada', 'Noto Sans Malayalam', 'Noto Sans Gurmukhi',
    'Noto Sans Oriya', 'Noto Sans Sinhala', 'Noto Sans Myanmar',
    'Noto Sans Khmer', 'Noto Sans Lao', 'Noto Sans Georgian',
    'Noto Sans Armenian', 'Noto Sans Ethiopic', 'Noto Nastaliq Urdu',
    // Bundled CJK translation fonts
    'Noto Sans SC', 'Noto Sans JP', 'Noto Sans KR', 'Noto Sans TC',
  ];

  Future<String> _registerFont(String fontPath) async {
    final rawName = p.basenameWithoutExtension(fontPath);
    var fontName = normalizeFontName(rawName);
    final isBuiltIn = _bundledFontNames.contains(fontName);

    if (isBuiltIn || _loadedFonts.containsKey(fontName)) {
      fontName = rawName; // Fallback to filename with weight
      if (_loadedFonts.containsKey(fontName)) {
        int suffix = 1;
        while (_loadedFonts.containsKey('${fontName}_$suffix')) {
          suffix++;
        }
        fontName = '${fontName}_$suffix';
      }
    }
    
    final file = File(fontPath);
    if (file.existsSync()) {
      final size = await file.length();
      if (size > 50 * 1024 * 1024) {
        throw Exception('Font file is too large (max 50MB): $size bytes');
      }
    }
    
    final fontLoader = FontLoader(fontName);
    final data = await file.readAsBytes();
    fontLoader.addFont(Future.value(ByteData.view(data.buffer, data.offsetInBytes, data.lengthInBytes)));
    await fontLoader.load();
    _loadedFonts[fontName] = fontPath;
    _cachedAvailableFonts = null;
    return fontName;
  }

  List<String> get availableFonts {
    _cachedAvailableFonts ??= [
        ..._bundledFontNames,
        // User-loaded custom fonts & downloaded CJK fonts (legacy dynamic fallback)
        ..._loadedFonts.keys,
      ];
    return _cachedAvailableFonts!;
  }
}
