import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'style_templates.dart';

/// Represents a curated pack of community/viral creator caption presets.
class CommunityPresetPack {
  final String id;
  final String title;
  final String creator;
  final String description;
  final List<String> tags;
  final String? badge;
  final int downloads;
  final List<StyleTemplate> presets;

  const CommunityPresetPack({
    required this.id,
    required this.title,
    required this.creator,
    required this.description,
    required this.tags,
    this.badge,
    required this.downloads,
    required this.presets,
  });
}

/// Service providing curated, viral community caption presets and packs.
/// Allows creators to discover, preview, and 1-click install style packs into their saved presets.
class CommunityPresetsService {
  CommunityPresetsService._();
  static final CommunityPresetsService instance = CommunityPresetsService._();

  /// Curated community creator packs designed to match viral video platforms.
  final List<CommunityPresetPack> packs = const [
    CommunityPresetPack(
      id: 'viral_titans',
      title: 'Viral Retention Titans',
      creator: 'Hormozi & Beast Styles',
      description: 'High-contrast, high-energy punchy captions optimized for maximum 3-second hook retention.',
      tags: ['Trending', 'YouTube', 'Shorts', 'High Energy'],
      badge: 'TOP VIRAL',
      downloads: 48200,
      presets: [
        StyleTemplate(
          id: 'comm_hormozi_titan',
          name: 'Hormozi 2.0 Bold',
          category: StyleCategory.trending,
          fontFamily: 'Montserrat',
          fontWeight: '900',
          textTransform: 'uppercase',
          color: '#ffffff',
          fontSize: 44.0,
          top: 75.0,
          mainColor: '#facc15', // Vibrant Gold
          secondColor: '#22c55e', // Emerald Green
          thirdColor: '#f97316', // Orange
          stroke: 'thick',
          animation: 'bounce',
          shadow: 'hard',
        ),
        StyleTemplate(
          id: 'comm_mrbeast_beastmode',
          name: 'MrBeast Beastmode',
          category: StyleCategory.trending,
          fontFamily: 'Komika Axis',
          fontWeight: '900',
          textTransform: 'uppercase',
          color: '#ffffff',
          fontSize: 48.0,
          top: 78.0,
          mainColor: '#06b6d4', // Cyan
          secondColor: '#ec4899', // Pink
          thirdColor: '#eab308', // Yellow
          stroke: 'thick',
          animation: 'pop',
          shadow: 'hard',
        ),
        StyleTemplate(
          id: 'comm_graham_stephan',
          name: 'Finance Guru Neon',
          category: StyleCategory.bold,
          fontFamily: 'Impact',
          fontWeight: '900',
          textTransform: 'uppercase',
          color: '#ffffff',
          fontSize: 50.0,
          top: 72.0,
          mainColor: '#10b981', // Money green
          secondColor: '#38bdf8', // Sky blue
          thirdColor: '#f59e0b', // Amber
          stroke: 'thick',
          animation: 'pop',
          shadow: 'hard',
        ),
      ],
    ),
    CommunityPresetPack(
      id: 'podcast_leaders',
      title: 'Thought Leader & Podcast Studio',
      creator: 'Ali Abdaal & Lex Fridman',
      description: 'Sophisticated, elegant typography focused on educational clarity, intellectual podcasts, and longform discourse.',
      tags: ['Podcast', 'Clean', 'Educational', 'Minimal'],
      badge: 'POPULAR',
      downloads: 31400,
      presets: [
        StyleTemplate(
          id: 'comm_ali_abdaal_clarity',
          name: 'Ali Abdaal Clarity',
          category: StyleCategory.elegant,
          fontFamily: 'Inter',
          fontWeight: '600',
          textTransform: 'none',
          color: '#ffffff',
          fontSize: 34.0,
          top: 80.0,
          mainColor: '#facc15',
          secondColor: '#60a5fa',
          thirdColor: '#4ade80',
          stroke: 'none',
          animation: 'wordReveal',
          shadow: 'soft',
          highlightBackground: true,
        ),
        StyleTemplate(
          id: 'comm_lex_fridman_deep',
          name: 'Lex Deep Introspection',
          category: StyleCategory.classic,
          fontFamily: 'Playfair Display',
          fontWeight: '700',
          textTransform: 'none',
          color: '#f8fafc',
          fontSize: 32.0,
          top: 82.0,
          mainColor: '#cbd5e1',
          secondColor: '#e2e8f0',
          thirdColor: '#94a3b8',
          stroke: 'none',
          animation: 'wordReveal',
          shadow: 'soft',
        ),
        StyleTemplate(
          id: 'comm_huberman_science',
          name: 'Huberman Protocol',
          category: StyleCategory.modern,
          fontFamily: 'Roboto',
          fontWeight: '700',
          textTransform: 'none',
          color: '#ffffff',
          fontSize: 36.0,
          top: 76.0,
          mainColor: '#0ea5e9',
          secondColor: '#10b981',
          thirdColor: '#f43f5e',
          stroke: 'thin',
          animation: 'pop',
          shadow: 'soft',
        ),
      ],
    ),
    CommunityPresetPack(
      id: 'tiktok_genz',
      title: 'TikTok & Reels Karaoke Masters',
      creator: 'Viral TikTok Creators',
      description: 'Fast-paced, colorful party karaoke styles that follow speech word-by-word with pulsating highlight glow.',
      tags: ['TikTok', 'Reels', 'Karaoke', 'Gen-Z'],
      badge: 'TRENDING',
      downloads: 56900,
      presets: [
        StyleTemplate(
          id: 'comm_tiktok_neon_karaoke',
          name: 'TikTok Neon Karaoke',
          category: StyleCategory.trending,
          fontFamily: 'Proxima Nova',
          fontWeight: '900',
          textTransform: 'uppercase',
          color: '#ffffff',
          fontSize: 40.0,
          top: 65.0,
          mainColor: '#f43f5e', // Hot pink
          secondColor: '#06b6d4', // Neon cyan
          thirdColor: '#a855f7', // Purple
          stroke: 'thick',
          animation: 'bounce',
          shadow: 'hard',
        ),
        StyleTemplate(
          id: 'comm_spill_the_tea',
          name: 'Spill The Tea Pastel',
          category: StyleCategory.playful,
          fontFamily: 'Poppins',
          fontWeight: '800',
          textTransform: 'none',
          color: '#fdf4ff',
          fontSize: 38.0,
          top: 68.0,
          mainColor: '#ec4899',
          secondColor: '#8b5cf6',
          thirdColor: '#f59e0b',
          stroke: 'thin',
          animation: 'pop',
          shadow: 'soft',
        ),
        StyleTemplate(
          id: 'comm_reels_kinetic',
          name: 'Reels Kinetic Glitch',
          category: StyleCategory.effects,
          fontFamily: 'Montserrat',
          fontWeight: '900',
          textTransform: 'uppercase',
          color: '#ffffff',
          fontSize: 42.0,
          top: 70.0,
          mainColor: '#84cc16', // Lime
          secondColor: '#a855f7', // Violet
          thirdColor: '#06b6d4', // Cyan
          stroke: 'thick',
          animation: 'bounce',
          shadow: 'hard',
        ),
      ],
    ),
    CommunityPresetPack(
      id: 'cinematic_documentary',
      title: 'Cinematic & Documentarian',
      creator: 'Vox & Johnny Harris Style',
      description: 'Editorial grade storytelling subtitles with curated typography, subtle kerning, and classic highlight aesthetics.',
      tags: ['Documentary', 'Cinematic', 'Vox', 'Editorial'],
      badge: 'PRO',
      downloads: 24700,
      presets: [
        StyleTemplate(
          id: 'comm_vox_explainer',
          name: 'Vox Yellow Box Explainer',
          category: StyleCategory.bold,
          fontFamily: 'Helvetica',
          fontWeight: '900',
          textTransform: 'uppercase',
          color: '#000000',
          fontSize: 38.0,
          top: 78.0,
          mainColor: '#facc15', // Yellow Box
          secondColor: '#ffffff',
          thirdColor: '#ef4444',
          stroke: 'none',
          animation: 'wordReveal',
          shadow: 'none',
          highlightBackground: true,
        ),
        StyleTemplate(
          id: 'comm_johnny_harris_journal',
          name: 'Harris Visual Journal',
          category: StyleCategory.elegant,
          fontFamily: 'Georgia',
          fontWeight: '700',
          textTransform: 'none',
          color: '#faf8f5',
          fontSize: 34.0,
          top: 80.0,
          mainColor: '#fbbf24',
          secondColor: '#38bdf8',
          thirdColor: '#34d399',
          stroke: 'none',
          animation: 'wordReveal',
          shadow: 'soft',
          letterSpacing: 1.2,
        ),
        StyleTemplate(
          id: 'comm_magnates_noir',
          name: 'Magnates Media Gold Noir',
          category: StyleCategory.premium,
          fontFamily: 'Cinzel',
          fontWeight: '700',
          textTransform: 'uppercase',
          color: '#f59e0b', // Gold
          fontSize: 36.0,
          top: 76.0,
          mainColor: '#ffffff',
          secondColor: '#d97706',
          thirdColor: '#fbbf24',
          stroke: 'thin',
          animation: 'pop',
          shadow: 'hard',
          letterSpacing: 2.0,
        ),
      ],
    ),
    CommunityPresetPack(
      id: 'gaming_streamer',
      title: 'Gaming & Streamer Hype',
      creator: 'Twitch & Kick Streamers',
      description: 'Maximum adrenaline typography with explosive comic outlines, neon glows, and punchy pop transitions.',
      tags: ['Gaming', 'Twitch', 'Streamer', 'Comic'],
      badge: 'HYPE',
      downloads: 38900,
      presets: [
        StyleTemplate(
          id: 'comm_twitch_chat_hype',
          name: 'Twitch Chat Hype',
          category: StyleCategory.playful,
          fontFamily: 'Bangers',
          fontWeight: '400',
          textTransform: 'uppercase',
          color: '#ffffff',
          fontSize: 52.0,
          top: 65.0,
          mainColor: '#9333ea', // Twitch purple
          secondColor: '#06b6d4', // Cyan
          thirdColor: '#eab308', // Gold
          stroke: 'thick',
          animation: 'bounce',
          shadow: 'hard',
        ),
        StyleTemplate(
          id: 'comm_cyberpunk_neon',
          name: 'Cyberpunk 2077 Night',
          category: StyleCategory.effects,
          fontFamily: 'Impact',
          fontWeight: '900',
          textTransform: 'uppercase',
          color: '#00f0ff', // Cyber cyan
          fontSize: 46.0,
          top: 70.0,
          mainColor: '#ffe600', // Cyber yellow
          secondColor: '#ff003c', // Red
          thirdColor: '#ffffff',
          stroke: 'thick',
          animation: 'pop',
          shadow: 'hard',
        ),
      ],
    ),
  ];

  /// Filters packs by search query and optional tag.
  List<CommunityPresetPack> searchPacks({String? query, String? tag}) {
    return packs.where((pack) {
      if (tag != null && tag.isNotEmpty && tag != 'All') {
        if (!pack.tags.any((t) => t.toLowerCase() == tag.toLowerCase())) {
          return false;
        }
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim().toLowerCase();
        final matchTitle = pack.title.toLowerCase().contains(q);
        final matchCreator = pack.creator.toLowerCase().contains(q);
        final matchDesc = pack.description.toLowerCase().contains(q);
        final matchTag = pack.tags.any((t) => t.toLowerCase().contains(q));
        final matchPreset = pack.presets.any((p) => p.name.toLowerCase().contains(q));
        return matchTitle || matchCreator || matchDesc || matchTag || matchPreset;
      }
      return true;
    }).toList();
  }

  /// Checks if all presets in this pack are already saved in the user's custom presets.
  Future<bool> isPackInstalled(String packId) async {
    final pack = packs.firstWhere((p) => p.id == packId, orElse: () => packs.first);
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('custom_presets') ?? [];

    final installedIds = <String>{};
    for (final item in list) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        final id = decoded['id'] as String?;
        if (id != null) installedIds.add(id);
      } catch (_) {}
    }

    return pack.presets.every((preset) => installedIds.contains(preset.id));
  }

  /// Installs all presets from this pack into the user's custom presets with deduplication.
  /// Returns the number of newly added presets.
  Future<int> installPack(CommunityPresetPack pack) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList('custom_presets') ?? [];

    final existingIds = <String>{};
    for (final item in list) {
      try {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        final id = decoded['id'] as String?;
        if (id != null) existingIds.add(id);
      } catch (_) {}
    }

    final toAdd = <String>[];
    for (final preset in pack.presets) {
      if (!existingIds.contains(preset.id)) {
        toAdd.add(jsonEncode(preset.toJson()));
      }
    }

    if (toAdd.isNotEmpty) {
      await prefs.setStringList('custom_presets', [...list, ...toAdd]);
    }

    return toAdd.length;
  }
}
