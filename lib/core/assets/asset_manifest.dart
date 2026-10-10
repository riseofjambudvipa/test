import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../emoji/emoji_service.dart';
import 'asset_path_service.dart';

class AssetPack {
  final String id, name, description, downloadUrl, checksum, version, localFolder, format;
  final bool required, animated;
  final int sizeBytes, compressedSizeBytes, fileCount;

  const AssetPack({
    required this.id, required this.name, required this.description,
    required this.required, required this.sizeBytes, required this.compressedSizeBytes,
    required this.downloadUrl, required this.checksum, required this.version,
    required this.fileCount, required this.format, required this.animated,
    required this.localFolder,
  });

  double get sizeMB => sizeBytes / (1024 * 1024);
  double get compressedSizeMB => compressedSizeBytes / (1024 * 1024);

  factory AssetPack.fromJson(Map<String, dynamic> json) => AssetPack(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    required: json['required'] as bool,
    sizeBytes: json['sizeBytes'] as int,
    compressedSizeBytes: json['compressedSizeBytes'] as int,
    downloadUrl: json['downloadUrl'] as String,
    checksum: json['checksum'] as String,
    version: json['version'] as String,
    fileCount: json['fileCount'] as int,
    format: json['format'] as String,
    animated: json['animated'] as bool,
    localFolder: json['localFolder'] as String,
  );
}

class EmojiMeta {
  final String unicode, glyph, name, group, unicodeVersion;
  final List<String> keywords, shortcodes;
  final Map<String, String> styles; // packId → filename

  const EmojiMeta({
    required this.unicode, required this.glyph, required this.name,
    required this.group, required this.unicodeVersion,
    required this.keywords, required this.shortcodes, required this.styles,
  });

  bool supportsPack(String packId) => styles.containsKey(packId);

  factory EmojiMeta.fromJson(Map<String, dynamic> j) => EmojiMeta(
    unicode: j['unicode'] as String, glyph: (j['glyph'] ?? '') as String,
    name: (j['name'] as String).toLowerCase(), group: (j['group'] ?? 'Other') as String,
    unicodeVersion: (j['unicodeVersion'] ?? '8.0') as String,
    keywords: List<String>.from(j['keywords'] as Iterable? ?? []).map((k) => k.toLowerCase()).toList(),
    shortcodes: List<String>.from(j['shortcodes'] as Iterable? ?? []).map((s) => s.toLowerCase()).toList(),
    styles: Map<String, String>.from(j['styles'] as Map? ?? {}),
  );
}

class AssetManifest {
  final String version;
  final List<AssetPack> packs;
  final List<EmojiMeta> emojis;
  late final Map<String, EmojiMeta> byUnicode;
  late final Map<String, EmojiMeta> byGlyph;
  late final Map<String, List<EmojiMeta>> byGroup;

  AssetManifest({required this.version, required this.packs, required this.emojis}) {
    byUnicode = {for (final e in emojis) e.unicode: e};
    byGlyph = {for (final e in emojis) e.glyph: e};
    byGroup = {};
    for (final e in emojis) {
      final model = EmojiService.instance.findByGlyph(e.glyph);
      if (model != null && model.parentUnicode != null) {
        continue; // Skip skin-tone and gender variations in category browsing
      }
      byGroup.putIfAbsent(e.group.toLowerCase(), () => []).add(e);
    }
  }


  static List<AssetPack> getLocalFallbackPacks() {
    return [
      const AssetPack(
        id: 'googleNonAnimated',
        name: 'Google Noto (Static)',
        description: 'High-quality flat Google Noto emoji set. Clean and lightweight.',
        required: false,
        sizeBytes: 93240659,
        compressedSizeBytes: 93240659,
        downloadUrl: 'https://github.com/riseofjambudvipa/test/releases/download/test/google_noto_emojis_non_animated_pack.zip',
        checksum: '',
        version: '1.0',
        fileCount: 3733,
        format: 'zip',
        animated: false,
        localFolder: 'google_noto_emojis_non_animated_pack',
      ),
      const AssetPack(
        id: 'googleAnimated',
        name: 'Google Noto (Animated)',
        description: 'Gorgeous 3D animated emojis. Plays on hover.',
        required: false,
        sizeBytes: 1792659858,
        compressedSizeBytes: 1792659858,
        downloadUrl: 'https://github.com/riseofjambudvipa/test/releases/download/test/google_noto_emojis_animated_pack.zip',
        checksum: '',
        version: '1.0',
        fileCount: 611,
        format: 'zip',
        animated: true,
        localFolder: 'google_noto_emojis_animated_pack',
      ),
      const AssetPack(
        id: 'microsoftNonAnimated',
        name: 'Microsoft FluentUI (Static)',
        description: 'Clean flat FluentUI static emojis.',
        required: false,
        sizeBytes: 54231090,
        compressedSizeBytes: 54231090,
        downloadUrl: 'https://github.com/riseofjambudvipa/test/releases/download/test/microsoft_fluentui_emoji_non_animated_pack.zip',
        checksum: '',
        version: '1.0',
        fileCount: 1597,
        format: 'zip',
        animated: false,
        localFolder: 'microsoft_fluentui_emoji_non_animated_pack',
      ),
      const AssetPack(
        id: 'microsoftAnimated',
        name: 'Microsoft FluentUI (Animated)',
        description: 'Modern 3D animated fluent emojis. Plays on hover.',
        required: false,
        sizeBytes: 1688573602,
        compressedSizeBytes: 1688573602,
        downloadUrl: 'https://github.com/riseofjambudvipa/test/releases/download/test/microsoft_fluentui_emoji_animated_pack.zip',
        checksum: '',
        version: '1.0',
        fileCount: 746,
        format: 'zip',
        animated: true,
        localFolder: 'microsoft_fluentui_emoji_animated_pack',
      ),
      const AssetPack(
        id: 'openmoji',
        name: 'OpenMoji',
        description: 'Clean open-source outline design style emojis.',
        required: false,
        sizeBytes: 47095578,
        compressedSizeBytes: 47095578,
        downloadUrl: 'https://github.com/riseofjambudvipa/test/releases/download/test/openmoji_non_animated_pack.zip',
        checksum: '',
        version: '1.0',
        fileCount: 4497,
        format: 'zip',
        animated: false,
        localFolder: 'openmoji_non_animated_pack',
      ),
    ];
  }

  /// Loads emoji database from JSON and returns the manifest.
  static Future<AssetManifest> load() async {
    final emojisDir = AssetPathService.instance.emojisDir;
    final metadataPath = p.join(emojisDir, 'metadata.json');
    // Boot up EmojiService to load the metadata JSON
    await EmojiService.instance.loadMetadata(metadataPath, emojisDir);
    
    // Construct EmojiMeta list from EmojiService database
    final emojisList = EmojiService.instance.allEmojis.map((e) => EmojiMeta(
      unicode: e.unicode,
      glyph: e.glyph,
      name: e.name,
      group: e.group,
      unicodeVersion: '15.0',
      keywords: e.keywords,
      shortcodes: e.shortcodes,
      styles: e.styles,
    )).toList();

    return AssetManifest(
      version: '2.0',
      packs: getLocalFallbackPacks(),
      emojis: emojisList,
    );
  }

  factory AssetManifest.fromJson(Map<String, dynamic> j, [List<AssetPack>? customPacks]) {
    final packsList = customPacks ?? getLocalFallbackPacks();

    return AssetManifest(
      version: (j['version'] ?? '2.0') as String,
      packs: packsList,
      emojis: (j['emojis'] as List<dynamic>).map((e) => EmojiMeta.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  /// Search by name, keyword, shortcode, or unicode glyph.
  List<EmojiMeta> search(String query, {String? packId, int limit = 50}) {
    final q = query.toLowerCase().trim();
    
    // If EmojiService is loaded, leverage its lazy inverted search index
    if (EmojiService.instance.isLoaded) {
      final models = EmojiService.instance.search(q, limit: limit);
      final results = <EmojiMeta>[];
      for (final m in models) {
        final fullModel = EmojiService.instance.findByGlyph(m.glyph) ?? m;
        if (packId != null) {
          if (fullModel.styles.isNotEmpty && !fullModel.styles.containsKey(packId)) {
            continue;
          }
        }
        results.add(EmojiMeta(
          unicode: fullModel.unicode,
          glyph: fullModel.glyph,
          name: fullModel.name,
          group: fullModel.group,
          unicodeVersion: '8.0',
          keywords: fullModel.keywords,
          shortcodes: fullModel.shortcodes,
          styles: fullModel.styles,
        ));
      }
      return results;
    }

    if (q.isEmpty) return emojis.take(limit).toList();
    return emojis.where((e) {
      if (packId != null && !e.supportsPack(packId)) return false;
      return e.name.contains(q) || e.glyph == q ||
          e.keywords.any((k) => k.contains(q)) ||
          e.shortcodes.any((s) => s.contains(q));
    }).take(limit).toList();
  }
}

final assetManifestProvider = Provider<AssetManifest>((ref) {
  throw UnimplementedError('assetManifestProvider must be overridden in ProviderScope');
});
