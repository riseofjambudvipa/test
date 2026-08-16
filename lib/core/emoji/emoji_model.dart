class EmojiAsset {
  final String packId;
  final String filename;
  final String absolutePath;

  const EmojiAsset({
    required this.packId,
    required this.filename,
    required this.absolutePath,
  });
}

class EmojiModel {
  final String unicode;
  final String glyph;
  final String name;
  final List<String> keywords;
  final String group;
  final Map<String, String> styles; // Map packId -> filename
  final List<String> shortcodes;
  final String? parentUnicode;

  const EmojiModel({
    required this.unicode,
    required this.glyph,
    required this.name,
    required this.keywords,
    required this.group,
    required this.styles,
    required this.shortcodes,
    this.parentUnicode,
  });

  factory EmojiModel.fromBaseJson(Map<String, dynamic> json, {required String name, required List<String> keywords}) {
    return EmojiModel(
      unicode: json['u'] as String,
      glyph: json['g'] as String,
      name: name.toLowerCase(),
      keywords: keywords,
      group: json['cat'] as String? ?? 'Other',
      styles: Map<String, String>.from(json['pk'] as Map? ?? {}),
      shortcodes: List<String>.from(json['sc'] as Iterable? ?? []),
      parentUnicode: json['p'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unicode': unicode,
      'glyph': glyph,
      'name': name,
      'keywords': keywords,
      'group': group,
      'styles': styles,
      'shortcodes': shortcodes,
      if (parentUnicode != null) 'parentUnicode': parentUnicode,
    };
  }
}

class EmojiPackParser {
  static EmojiParseResult parse(String emojiStr, String defaultPack) {
    if (emojiStr.contains(':') &&
        !emojiStr.startsWith('http') &&
        !emojiStr.startsWith('/')) {
      // Check if it is a Windows absolute path starting with drive letter (e.g. D:/ or E:\)
      final colonIndex = emojiStr.indexOf(':');
      if (colonIndex == 1) {
        final driveLetter = emojiStr[0].toLowerCase();
        if (driveLetter.codeUnitAt(0) >= 97 && driveLetter.codeUnitAt(0) <= 122) {
          // This is a Windows drive letter path, treat entire string as glyph
          return EmojiParseResult(pack: defaultPack, glyph: emojiStr);
        }
      }

      final parts = emojiStr.split(':');
      if (parts.length == 2) {
        final pack = parts[0];
        final glyph = parts[1];
        if (isValidPack(pack) || pack == 'systemDefault' || pack == 'notoColorEmoji') {
          return EmojiParseResult(pack: pack, glyph: glyph);
        }
      }
    }
    return EmojiParseResult(pack: defaultPack, glyph: emojiStr);
  }

  static bool isValidPack(String pack) {
    return pack == 'googleAnimated' ||
        pack == 'googleNonAnimated' ||
        pack == 'microsoftAnimated' ||
        pack == 'microsoftNonAnimated' ||
        pack == 'openmoji' ||
        pack == 'notoColorEmoji';
  }
}

class EmojiParseResult {
  final String pack;
  final String glyph;
  const EmojiParseResult({required this.pack, required this.glyph});
}
