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
    if (emojiStr.isEmpty) {
      return EmojiParseResult(pack: defaultPack, glyph: '');
    }

    // 1. Direct absolute file path check (Unix / Android or Windows C:\...)
    if (emojiStr.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(emojiStr) ||
        emojiStr.endsWith('.png') ||
        emojiStr.endsWith('.webp') ||
        emojiStr.endsWith('.jpg') ||
        emojiStr.endsWith('.jpeg') ||
        emojiStr.endsWith('.gif')) {
      return EmojiParseResult(pack: 'custom', glyph: emojiStr);
    }

    // 2. Check for pack:glyph prefix (e.g. custom:C:\... or notoColorEmoji:😀)
    final firstColon = emojiStr.indexOf(':');
    // If the colon is at index 1, it is a Windows drive letter (e.g. C:\)
    if (firstColon > 1) {
      final packCandidate = emojiStr.substring(0, firstColon);
      final remaining = emojiStr.substring(firstColon + 1);

      if (remaining.startsWith('/') ||
          RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(remaining) ||
          remaining.endsWith('.png') ||
          remaining.endsWith('.webp') ||
          remaining.endsWith('.jpg') ||
          remaining.endsWith('.jpeg') ||
          remaining.endsWith('.gif')) {
        return EmojiParseResult(pack: 'custom', glyph: remaining);
      }

      if (isValidPack(packCandidate) ||
          packCandidate == 'systemDefault' ||
          packCandidate == 'notoColorEmoji' ||
          packCandidate == 'custom') {
        return EmojiParseResult(pack: packCandidate, glyph: remaining);
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
        pack == 'notoColorEmoji' ||
        pack == 'custom';
  }
}

class EmojiParseResult {
  final String pack;
  final String glyph;
  const EmojiParseResult({required this.pack, required this.glyph});
}
