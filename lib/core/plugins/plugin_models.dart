/// Manifest metadata describing a CapStudio Community Plugin or Creator Pack.
class PluginManifest {
  final String id;
  final String name;
  final String version;
  final String author;
  final String description;
  final List<String> tags;
  final String icon;
  final String minAppVersion;
  final String? website;

  const PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.author,
    required this.description,
    this.tags = const [],
    this.icon = 'extension',
    this.minAppVersion = '1.0.0',
    this.website,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'version': version,
      'author': author,
      'description': description,
      'tags': tags,
      'icon': icon,
      'minAppVersion': minAppVersion,
      'website': website,
    };
  }

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    return PluginManifest(
      id: json['id'] as String? ?? 'unknown.plugin',
      name: json['name'] as String? ?? 'Unnamed Plugin',
      version: json['version'] as String? ?? '1.0.0',
      author: json['author'] as String? ?? 'Community',
      description: json['description'] as String? ?? '',
      tags: (json['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? const [],
      icon: json['icon'] as String? ?? 'extension',
      minAppVersion: json['minAppVersion'] as String? ?? '1.0.0',
      website: json['website'] as String?,
    );
  }
}

/// Custom viral hook pattern supplied by an extension package to enhance
/// AI Virality scoring for specialized niches (e.g. gym, crypto, tech).
class PluginCustomHook {
  final String pattern;
  final double weight;
  final String tag;
  final String explanation;

  const PluginCustomHook({
    required this.pattern,
    this.weight = 12.0,
    this.tag = 'niche_hook',
    required this.explanation,
  });

  Map<String, dynamic> toJson() {
    return {
      'pattern': pattern,
      'weight': weight,
      'tag': tag,
      'explanation': explanation,
    };
  }

  factory PluginCustomHook.fromJson(Map<String, dynamic> json) {
    return PluginCustomHook(
      pattern: json['pattern'] as String? ?? '',
      weight: (json['weight'] as num?)?.toDouble() ?? 12.0,
      tag: json['tag'] as String? ?? 'niche_hook',
      explanation: json['explanation'] as String? ?? 'High-retention niche hook pattern',
    );
  }
}

/// Complete installable plugin or extension package (.capplugin).
class PluginPackage {
  final PluginManifest manifest;
  final bool isEnabled;
  final bool isBundled;
  final DateTime installedAt;
  final List<Map<String, dynamic>> styleTemplates;
  final List<PluginCustomHook> customHooks;
  final Map<String, String> customEmojis;
  final Map<String, String> customSfx;
  final List<Map<String, dynamic>> brandKits;

  const PluginPackage({
    required this.manifest,
    this.isEnabled = true,
    this.isBundled = false,
    required this.installedAt,
    this.styleTemplates = const [],
    this.customHooks = const [],
    this.customEmojis = const {},
    this.customSfx = const {},
    this.brandKits = const [],
  });

  PluginPackage copyWith({
    PluginManifest? manifest,
    bool? isEnabled,
    bool? isBundled,
    DateTime? installedAt,
    List<Map<String, dynamic>>? styleTemplates,
    List<PluginCustomHook>? customHooks,
    Map<String, String>? customEmojis,
    Map<String, String>? customSfx,
    List<Map<String, dynamic>>? brandKits,
  }) {
    return PluginPackage(
      manifest: manifest ?? this.manifest,
      isEnabled: isEnabled ?? this.isEnabled,
      isBundled: isBundled ?? this.isBundled,
      installedAt: installedAt ?? this.installedAt,
      styleTemplates: styleTemplates ?? this.styleTemplates,
      customHooks: customHooks ?? this.customHooks,
      customEmojis: customEmojis ?? this.customEmojis,
      customSfx: customSfx ?? this.customSfx,
      brandKits: brandKits ?? this.brandKits,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'format': 'CapStudioPlugin',
      'manifest': manifest.toJson(),
      'isEnabled': isEnabled,
      'isBundled': isBundled,
      'installedAt': installedAt.toIso8601String(),
      'styleTemplates': styleTemplates,
      'customHooks': customHooks.map((h) => h.toJson()).toList(),
      'customEmojis': customEmojis,
      'customSfx': customSfx,
      'brandKits': brandKits,
    };
  }

  factory PluginPackage.fromJson(Map<String, dynamic> json) {
    final manifestMap = json['manifest'] as Map<String, dynamic>? ?? {};
    final hooksRaw = json['customHooks'] as List<dynamic>? ?? const [];
    final emojisRaw = json['customEmojis'] as Map<String, dynamic>? ?? const {};
    final sfxRaw = json['customSfx'] as Map<String, dynamic>? ?? const {};
    final templatesRaw = json['styleTemplates'] as List<dynamic>? ?? const [];
    final brandKitsRaw = json['brandKits'] as List<dynamic>? ?? const [];

    return PluginPackage(
      manifest: PluginManifest.fromJson(manifestMap),
      isEnabled: json['isEnabled'] as bool? ?? true,
      isBundled: json['isBundled'] as bool? ?? false,
      installedAt: json['installedAt'] != null
          ? DateTime.tryParse(json['installedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      styleTemplates: templatesRaw.whereType<Map<String, dynamic>>().toList(),
      customHooks: hooksRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => PluginCustomHook.fromJson(m))
          .toList(),
      customEmojis: emojisRaw.map((k, v) => MapEntry(k, v.toString())),
      customSfx: sfxRaw.map((k, v) => MapEntry(k, v.toString())),
      brandKits: brandKitsRaw.whereType<Map<String, dynamic>>().toList(),
    );
  }
}
