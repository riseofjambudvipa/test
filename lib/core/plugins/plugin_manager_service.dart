import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../logger/logger_service.dart';
import 'plugin_models.dart';

/// Central service managing CapStudio extensions and community creator packs (.capplugin).
class PluginManagerService {
  PluginManagerService._();
  static final PluginManagerService instance = PluginManagerService._();

  static const String _prefsKey = 'capstudio_plugins_data_v1';
  static const String _disabledKeys = 'capstudio_disabled_plugins_v1';

  final Map<String, PluginPackage> _cache = {};
  bool _initialized = false;

  /// Default bundled flagship creator packs
  static final List<PluginPackage> _defaultBundledPlugins = [
    PluginPackage(
      manifest: const PluginManifest(
        id: 'com.capstudio.pack.viralmaster',
        name: 'Viral Shorts & TikTok Masterpack',
        version: '1.2.0',
        author: 'CapStudio Creators',
        description: 'High-energy punchy styles, viral retention hook formulas, and emoji triggers.',
        tags: ['shorts', 'tiktok', 'viral', 'reels'],
        icon: 'bolt',
      ),
      isBundled: true,
      isEnabled: true,
      installedAt: DateTime(2026, 1, 1),
      customHooks: const [
        PluginCustomHook(
          pattern: r'\b(pov|point of view)\b',
          weight: 16.0,
          tag: 'pov_hook',
          explanation: 'POV relatable hook pattern increases viewer retention (+16 pts)',
        ),
        PluginCustomHook(
          pattern: r'\b(stop (doing|scrolling|wasting))\b',
          weight: 15.0,
          tag: 'pattern_interrupt',
          explanation: 'Pattern interrupt command immediately pauses user feed scroll (+15 pts)',
        ),
        PluginCustomHook(
          pattern: r'\b(i tried .* for \d+ days)\b',
          weight: 14.0,
          tag: 'challenge_experiment',
          explanation: 'Time-boxed personal experiment hook creates open narrative loop (+14 pts)',
        ),
        PluginCustomHook(
          pattern: r'\b(the biggest mistake|ruining your)\b',
          weight: 15.0,
          tag: 'loss_aversion',
          explanation: 'Loss aversion urgency dramatically improves 3-second completion rate (+15 pts)',
        ),
      ],
      customEmojis: const {
        'secret': '🤫',
        'wealth': '💸',
        'insane': '🤯',
        'danger': '⚠️',
        'hustle': '💼',
        'viral': '🚀',
      },
      customSfx: const {
        'secret': 'suspense',
        'wealth': 'cha_ching',
        'insane': 'glitch',
      },
      styleTemplates: const [
        {
          'id': 'hyper_hype',
          'name': 'HyperHype TikTok',
          'category': 'viral',
          'previewText': 'VIRAL CLIP',
          'fontFamily': 'Outfit',
          'fontSize': 28.0,
          'fontWeight': '900',
          'textTransform': 'uppercase',
          'mainColor': '#EAB308',
          'secondColor': '#06B6D4',
          'thirdColor': '#FFFFFF',
          'animation': 'pop',
          'shadow': 'soft',
          'stroke': 'thick',
        }
      ],
    ),
    PluginPackage(
      manifest: const PluginManifest(
        id: 'com.capstudio.pack.cinemadoc',
        name: 'Cinema & Documentary Storytelling',
        version: '1.0.0',
        author: 'Narrative Studio',
        description: 'Cinematic typography, historical/documentary hook phrases, and narrative pacing.',
        tags: ['cinema', 'documentary', 'storytelling', 'podcast'],
        icon: 'movie',
      ),
      isBundled: true,
      isEnabled: true,
      installedAt: DateTime(2026, 1, 1),
      customHooks: const [
        PluginCustomHook(
          pattern: r'\b(in the summer of|back in \d{4}|decades ago)\b',
          weight: 14.0,
          tag: 'historical_hook',
          explanation: 'Time anchor sets documentary tone and establishes credibility (+14 pts)',
        ),
        PluginCustomHook(
          pattern: r"\b(what they (never|didn't) tell you)\b",
          weight: 16.0,
          tag: 'hidden_truth',
          explanation: 'Forbidden knowledge hook drives deep viewer curiosity (+16 pts)',
        ),
        PluginCustomHook(
          pattern: r'\b(researchers (found|discovered))\b',
          weight: 13.0,
          tag: 'scientific_authority',
          explanation: 'Scientific study reference hooks intellectual audiences (+13 pts)',
        ),
      ],
      customEmojis: const {
        'history': '📜',
        'truth': '🔍',
        'discover': '💡',
        'mystery': '🗝️',
      },
      styleTemplates: const [
        {
          'id': 'doc_cinematic',
          'name': 'DocuStory Gold',
          'category': 'cinematic',
          'previewText': 'UNTOLD STORY',
          'fontFamily': 'Cinzel',
          'fontSize': 26.0,
          'fontWeight': '700',
          'textTransform': 'uppercase',
          'mainColor': '#F59E0B',
          'secondColor': '#FFFFFF',
          'thirdColor': '#D97706',
          'animation': 'glowPulse',
          'shadow': 'hard',
          'stroke': 'thin',
        }
      ],
    ),
    PluginPackage(
      manifest: const PluginManifest(
        id: 'com.capstudio.pack.fitnesspro',
        name: 'Gym & High-Performance Athlete',
        version: '1.1.0',
        author: 'IronFitness Media',
        description: 'Aggressive workout bold fonts, fitness retention patterns, and nutrition triggers.',
        tags: ['fitness', 'workout', 'motivation', 'gym'],
        icon: 'fitness_center',
      ),
      isBundled: true,
      isEnabled: true,
      installedAt: DateTime(2026, 1, 1),
      customHooks: const [
        PluginCustomHook(
          pattern: r"\b(if you're not doing this (every day|in the gym))\b",
          weight: 15.0,
          tag: 'gym_urgency',
          explanation: 'Direct training critique triggers fitness audience engagement (+15 pts)',
        ),
        PluginCustomHook(
          pattern: r'\b(the 1 (exercise|mistake) ruining your)\b',
          weight: 15.0,
          tag: 'training_mistake',
          explanation: 'High-stakes fitness mistake hook commands immediate attention (+15 pts)',
        ),
      ],
      customEmojis: const {
        'gym': '🏋️',
        'protein': '🥩',
        'cardio': '🏃',
        'muscle': '💪',
        'focus': '🎯',
      },
      styleTemplates: const [
        {
          'id': 'iron_pulse',
          'name': 'Iron Pulse Gym',
          'category': 'bold',
          'previewText': 'BEAST MODE',
          'fontFamily': 'Montserrat',
          'fontSize': 30.0,
          'fontWeight': '900',
          'textTransform': 'uppercase',
          'mainColor': '#84CC16',
          'secondColor': '#F97316',
          'thirdColor': '#FFFFFF',
          'animation': 'kineticTilt',
          'shadow': 'hard',
          'stroke': 'thick',
        }
      ],
    ),
    PluginPackage(
      manifest: const PluginManifest(
        id: 'com.capstudio.pack.techinsider',
        name: 'Tech, AI & SaaS Breakdowns',
        version: '1.0.0',
        author: 'Code & Future Media',
        description: 'Futuristic neon typography, AI breakthrough hook patterns, and software emojis.',
        tags: ['tech', 'ai', 'saas', 'coding'],
        icon: 'auto_awesome',
      ),
      isBundled: true,
      isEnabled: true,
      installedAt: DateTime(2026, 1, 1),
      customHooks: const [
        PluginCustomHook(
          pattern: r'\b(this new ai (is|will|changes))\b',
          weight: 16.0,
          tag: 'ai_disruption',
          explanation: 'Emerging AI disruption hook produces viral tech curiosity (+16 pts)',
        ),
        PluginCustomHook(
          pattern: r"\b(don't buy .* until you see this)\b",
          weight: 15.0,
          tag: 'buyer_warning',
          explanation: 'Software purchase caution triggers high tech buyer interest (+15 pts)',
        ),
      ],
      customEmojis: const {
        'code': '💻',
        'future': '🚀',
        'robot': '🤖',
        'speed': '⚡',
        'data': '📊',
      },
      styleTemplates: const [
        {
          'id': 'tech_cyber_glow',
          'name': 'Cyber Neon AI',
          'category': 'neon',
          'previewText': 'NEXT GEN AI',
          'fontFamily': 'Space Grotesk',
          'fontSize': 27.0,
          'fontWeight': '700',
          'textTransform': 'uppercase',
          'mainColor': '#06B6D4',
          'secondColor': '#EC4899',
          'thirdColor': '#FFFFFF',
          'animation': 'glowPulse',
          'shadow': 'soft',
          'stroke': 'thin',
        }
      ],
    ),
  ];

  /// Initializes the service and loads plugins from persistence.
  Future<List<PluginPackage>> getInstalledPlugins() async {
    if (_initialized) {
      return List.unmodifiable(_cache.values);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final disabledIds = (prefs.getStringList(_disabledKeys) ?? []).toSet();

      // Seed with bundled default plugins
      for (final bp in _defaultBundledPlugins) {
        _cache[bp.manifest.id] = bp.copyWith(
          isEnabled: !disabledIds.contains(bp.manifest.id),
        );
      }

      // Load user-installed plugins
      final rawCustom = prefs.getString(_prefsKey);
      if (rawCustom != null && rawCustom.trim().isNotEmpty) {
        final dynamic decoded = jsonDecode(rawCustom);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map<String, dynamic>) {
              final pkg = PluginPackage.fromJson(item);
              final isEnabled = !disabledIds.contains(pkg.manifest.id);
              _cache[pkg.manifest.id] = pkg.copyWith(isEnabled: isEnabled);
            }
          }
        }
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'PluginManagerService', 'Error initializing plugins: $e');
    }

    _initialized = true;
    return List.unmodifiable(_cache.values);
  }

  /// Synchronous retrieval of currently loaded plugins.
  List<PluginPackage> getInstalledPluginsSync() {
    if (!_initialized) {
      return List.unmodifiable(_defaultBundledPlugins);
    }
    return List.unmodifiable(_cache.values);
  }

  /// Installs a new plugin package from JSON (.capplugin).
  Future<PluginPackage> installPluginFromJson(String jsonStr) async {
    await getInstalledPlugins();

    final dynamic decoded = jsonDecode(jsonStr);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Invalid plugin format: expected JSON object');
    }

    final pkg = PluginPackage.fromJson(decoded);
    if (pkg.manifest.id.trim().isEmpty) {
      throw const FormatException('Plugin manifest ID cannot be empty');
    }

    _cache[pkg.manifest.id] = pkg.copyWith(
      isEnabled: true,
      isBundled: false,
      installedAt: DateTime.now(),
    );

    await _persist();
    LoggerService.instance.log(
      LogLevel.action,
      'PluginManagerService',
      'Installed plugin: ${pkg.manifest.name} (v${pkg.manifest.version})',
    );

    return _cache[pkg.manifest.id]!;
  }

  /// Toggles an installed plugin on or off.
  Future<void> togglePlugin(String pluginId, bool isEnabled) async {
    await getInstalledPlugins();
    final current = _cache[pluginId];
    if (current == null) return;

    _cache[pluginId] = current.copyWith(isEnabled: isEnabled);

    final prefs = await SharedPreferences.getInstance();
    final disabledIds = (prefs.getStringList(_disabledKeys) ?? []).toSet();
    if (isEnabled) {
      disabledIds.remove(pluginId);
    } else {
      disabledIds.add(pluginId);
    }
    await prefs.setStringList(_disabledKeys, disabledIds.toList());

    LoggerService.instance.log(
      LogLevel.action,
      'PluginManagerService',
      'Plugin ${current.manifest.name} is now ${isEnabled ? "ENABLED" : "DISABLED"}',
    );
  }

  /// Uninstalls a user-installed plugin. Bundled plugins cannot be deleted, only disabled.
  Future<bool> uninstallPlugin(String pluginId) async {
    await getInstalledPlugins();
    final current = _cache[pluginId];
    if (current == null || current.isBundled) {
      return false;
    }

    _cache.remove(pluginId);
    await _persist();

    LoggerService.instance.log(
      LogLevel.action,
      'PluginManagerService',
      'Uninstalled plugin: ${current.manifest.name}',
    );

    return true;
  }

  /// Exports a plugin package as a JSON string (.capplugin).
  String exportPluginPackage(PluginPackage plugin) {
    return const JsonEncoder.withIndent('  ').convert(plugin.toJson());
  }

  /// Aggregates all custom hooks from all currently enabled plugins.
  List<PluginCustomHook> getActiveCustomHooks() {
    final active = _cache.isEmpty ? _defaultBundledPlugins : _cache.values;
    final hooks = <PluginCustomHook>[];
    for (final p in active) {
      if (p.isEnabled) {
        hooks.addAll(p.customHooks);
      }
    }
    return hooks;
  }

  /// Aggregates all custom emoji mappings from all enabled plugins.
  Map<String, String> getActiveCustomEmojis() {
    final active = _cache.isEmpty ? _defaultBundledPlugins : _cache.values;
    final emojis = <String, String>{};
    for (final p in active) {
      if (p.isEnabled) {
        emojis.addAll(p.customEmojis);
      }
    }
    return emojis;
  }

  /// Aggregates all custom sfx mappings from all enabled plugins.
  Map<String, String> getActiveCustomSfx() {
    final active = _cache.isEmpty ? _defaultBundledPlugins : _cache.values;
    final sfx = <String, String>{};
    for (final p in active) {
      if (p.isEnabled) {
        sfx.addAll(p.customSfx);
      }
    }
    return sfx;
  }

  /// Aggregates custom style templates from all enabled plugins.
  List<Map<String, dynamic>> getActiveStyleTemplates() {
    final active = _cache.isEmpty ? _defaultBundledPlugins : _cache.values;
    final templates = <Map<String, dynamic>>[];
    for (final p in active) {
      if (p.isEnabled) {
        templates.addAll(p.styleTemplates);
      }
    }
    return templates;
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userInstalled = _cache.values.where((p) => !p.isBundled).map((p) => p.toJson()).toList();
      await prefs.setString(_prefsKey, jsonEncode(userInstalled));
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'PluginManagerService', 'Failed to persist plugins: $e');
    }
  }
}
