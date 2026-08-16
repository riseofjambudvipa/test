import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../../../../core/database/schemas/word.dart';
import '../../../../../../core/assets/asset_manifest.dart';
import '../../../../../../core/assets/asset_verification_service.dart';
import '../../../../../../core/assets/emoji_image.dart';
import '../../../../../../core/logger/logger_service.dart';
import '../../../../../../core/emoji/emoji_service.dart';
import '../../../../domain/caption_engine.dart';
import '../../../controllers/editor_controller.dart';

// FIX (Issue #6, CapStudio 1.0 audit): this was previously defined twice,
// identically, as private `static const _packMeta` inside two separate
// State classes in this same file (_EmojiPickerDialogState and
// _EmojiSettingsDialogState). Both now reference this single copy.
const List<Map<String, String>> kEmojiPackMeta = [
  {'id': 'systemDefault', 'name': 'System Default'},
  {'id': 'googleAnimated', 'name': 'Google Noto 3D (Animated)'},
  {'id': 'googleNonAnimated', 'name': 'Google Noto Flat (Static)'},
  {'id': 'microsoftAnimated', 'name': 'Microsoft Fluent 3D (Animated)'},
  {'id': 'microsoftNonAnimated', 'name': 'Microsoft Fluent Flat (Static)'},
  {'id': 'openmoji', 'name': 'OpenMoji Color (Static)'},
  {'id': 'notoColorEmoji', 'name': 'Noto Color Emoji (Fallback)'},
];

class EmojiTile extends ConsumerStatefulWidget {
  final EmojiMeta emoji;
  final String packId;
  final ValueChanged<String> onSelect;

  const EmojiTile({
    super.key,
    required this.emoji,
    required this.packId,
    required this.onSelect,
  });

  @override
  ConsumerState<EmojiTile> createState() => _EmojiTileState();
}

class _EmojiTileState extends ConsumerState<EmojiTile> {
  bool _isHovered = false;
  EmojiModel? _emojiModel;
  List<EmojiModel> _variations = [];
  bool _hasVariations = false;

  @override
  void initState() {
    super.initState();
    _loadVariations();
  }

  @override
  void didUpdateWidget(EmojiTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emoji.glyph != widget.emoji.glyph || oldWidget.packId != widget.packId) {
      _loadVariations();
    }
  }

  void _loadVariations() {
    _emojiModel = EmojiService.instance.findByGlyph(widget.emoji.glyph);
    final allVars = _emojiModel != null ? EmojiService.instance.getVariations(_emojiModel!) : <EmojiModel>[];
    
    final resolvedPackId = widget.packId == 'default' ? 'notoColorEmoji' : widget.packId;
    final List<EmojiModel> packFiltered = allVars.where((v) {
      if (resolvedPackId != 'systemDefault' && resolvedPackId != 'notoColorEmoji') {
        if (!v.styles.containsKey(resolvedPackId)) return false;
      }
      
      final u = v.unicode.toLowerCase();
      final g = v.glyph;
      final isVariant = u.contains('1f3fb') || u.contains('1f3fc') ||
          u.contains('1f3fd') || u.contains('1f3fe') ||
          u.contains('1f3ff') || u.contains('2640') ||
          u.contains('2642') || u.contains('1f9b0') ||
          u.contains('1f9b1') || u.contains('1f9b2') ||
          u.contains('1f9b3') || g.contains('🏻') ||
          g.contains('🏼') || g.contains('🏽') ||
          g.contains('🏾') || g.contains('🏿') ||
          g.contains('♀') || g.contains('♂');
      return isVariant;
    }).toList();
    
    _variations = packFiltered;
    _hasVariations = _variations.isNotEmpty;
  }

  void _showSkinTonePopup(BuildContext context, List<EmojiModel> variations) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;
    final offset = renderBox.localToGlobal(Offset.zero);
    final manifest = ref.read(assetManifestProvider);

    final selectedGlyph = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy - 64,
        offset.dx + renderBox.size.width,
        offset.dy,
      ),
      color: AppTheme.cardBg.withValues(alpha: 0.95),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPopupItem(widget.emoji.glyph, manifest),
                const SizedBox(width: 4),
                ...variations.map((v) => _buildPopupItem(v.glyph, manifest)),
              ],
            ),
          ),
        ),
      ],
    );

    if (selectedGlyph != null && mounted) {
      widget.onSelect(selectedGlyph);
    }
  }

  Widget _buildPopupItem(String glyph, AssetManifest manifest) {
    bool isItemHovered = false;
    final emojiMeta = manifest.byGlyph[glyph];
    
    return StatefulBuilder(
      builder: (context, setStateItem) {
        Widget imageWidget;
        if (emojiMeta != null && widget.packId != 'systemDefault' && widget.packId != 'notoColorEmoji') {
          imageWidget = EmojiImage(
            emoji: emojiMeta,
            activePack: widget.packId,
            size: 24,
          );
        } else {
          imageWidget = Text(
            glyph,
            style: TextStyle(
              fontSize: 22,
              fontFamily: widget.packId == 'notoColorEmoji'
                  ? 'Noto Color Emoji'
                  : switch (defaultTargetPlatform) {
                      TargetPlatform.android => null, // Let mobile devices use their native default system emoji font
                      TargetPlatform.macOS   => 'Apple Color Emoji',
                      TargetPlatform.windows => 'Segoe UI Emoji',
                      TargetPlatform.linux   => null,
                      _                      => null,
                    },
            ),
          );
        }

        return InkWell(
          onTap: () => Navigator.pop(context, glyph),
          onHover: (hovered) {
            if (context.mounted) {
              setStateItem(() {
                isItemHovered = hovered;
              });
            }
          },
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isItemHovered 
                  ? AppTheme.accentOrange.withValues(alpha: 0.15) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: imageWidget,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final verification = ref.watch(assetVerificationProvider);
    
    final isSystemDefault = widget.packId == 'systemDefault' || widget.packId == 'notoColorEmoji';
    final resolvedPackId = widget.packId == 'default' ? 'notoColorEmoji' : widget.packId;
    final isInstalled = isSystemDefault || verification.installedPackIds.contains(resolvedPackId);
    
    bool isMissing = false;
    if (!isSystemDefault && isInstalled && _emojiModel != null) {
      if (!EmojiService.instance.hasAssetOnDisk(_emojiModel!, resolvedPackId)) {
        isMissing = true;
      }
    }
    
    final isLocked = !isInstalled || isMissing;
    
    Widget content;
    if (!isLocked && !isSystemDefault) {
      final isAnimated = resolvedPackId == 'googleAnimated' || resolvedPackId == 'microsoftAnimated';
      
      String targetPackId = resolvedPackId;
      if (isAnimated && !_isHovered) {
         final nonAnimatedPackId = resolvedPackId == 'googleAnimated' 
            ? 'googleNonAnimated' 
            : 'microsoftNonAnimated';
        if (verification.installedPackIds.contains(nonAnimatedPackId)) {
          targetPackId = nonAnimatedPackId;
        }
      }
      
      final resolvedAsset = _emojiModel != null
          ? EmojiService.instance.getAssetPath(_emojiModel!, targetPackId)
          : null;

      if (!kIsWeb && resolvedAsset != null && verification.installedPackIds.contains(targetPackId)) {
        content = Image.file(
          File(resolvedAsset.absolutePath),
          key: ValueKey('${widget.emoji.unicode}_${targetPackId}_$_isHovered'),
          width: 32,
          height: 32,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => Text(
            widget.emoji.glyph,
            style: const TextStyle(fontSize: 24, fontFamily: 'Noto Color Emoji'),
          ),
        );
      } else {
        content = Text(
          widget.emoji.glyph,
          style: const TextStyle(fontSize: 24, fontFamily: 'Noto Color Emoji'),
        );
      }
    } else {
      if (isLocked) {
        content = Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.25,
              child: Text(
                widget.emoji.glyph,
                style: const TextStyle(fontSize: 24, fontFamily: 'Noto Color Emoji'),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                Icons.lock,
                size: 10,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            if (isMissing)
              Positioned(
                bottom: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: AppTheme.glassDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.8),
                    borderRadius: 3,
                    borderOpacity: 0.2,
                  ),
                  child: const Text(
                    'MISSING',
                    style: TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        );
      } else {
        content = Text(
          widget.emoji.glyph,
          style: TextStyle(
            fontSize: 24,
            fontFamily: widget.packId == 'notoColorEmoji'
                ? 'Noto Color Emoji'
                : switch (defaultTargetPlatform) {
                    TargetPlatform.android => null, // Let mobile devices use their native default system emoji font
                    TargetPlatform.macOS   => 'Apple Color Emoji',
                    TargetPlatform.windows => 'Segoe UI Emoji',
                    TargetPlatform.linux   => null,
                    _                      => null,
                  },
          ),
        );
      }
    }

    return RepaintBoundary(
      child: GestureDetector(
        onLongPress: (isLocked || !_hasVariations) ? null : () => _showSkinTonePopup(context, _variations),
        child: InkWell(
          onTap: isLocked ? null : () => widget.onSelect(widget.emoji.glyph),
          onHover: isLocked ? null : (hovered) {
            if (mounted) {
              setState(() {
                _isHovered = hovered;
              });
            }
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: AppTheme.glassDecoration(
              color: isLocked
                  ? Colors.black.withValues(alpha: 0.2)
                  : (_isHovered 
                      ? AppTheme.accentOrange.withValues(alpha: 0.1) 
                      : Colors.white.withValues(alpha: 0.02)),
              borderRadius: 8,
              borderOpacity: isLocked
                  ? 0.04
                  : (_isHovered ? 0.3 : 0.04),
              glowColor: (!isLocked && _isHovered) ? AppTheme.accentOrange : null,
              glowOpacity: (!isLocked && _isHovered) ? 0.06 : 0.0,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Center(
                  child: content,
                ),
                if (_hasVariations && !isLocked)
                  Positioned(
                    bottom: 3,
                    right: 3,
                    child: CustomPaint(
                      size: const Size(4, 4),
                      painter: _TrianglePainter(color: Colors.white30),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EmojiPickerDialog extends ConsumerStatefulWidget {
  final Project project;
  final Chunk chunk;
  final String? initialPack;
  final void Function(String selectedPack, String selectedGlyph)? onEmojiSelected;

  const EmojiPickerDialog({
    super.key,
    required this.project,
    required this.chunk,
    this.initialPack,
    this.onEmojiSelected,
  });

  @override
  ConsumerState<EmojiPickerDialog> createState() => _EmojiPickerDialogState();
}

class _EmojiPickerDialogState extends ConsumerState<EmojiPickerDialog> {
  late TextEditingController searchController;
  String activeCategory = 'recent';
  List<EmojiMeta> searchResults = [];
  late String selectedPack;
  Timer? _debounceTimer;
  final ScrollController _gridScrollController = ScrollController();

  Map<String, int> _categoryCounts = {};
  Map<String, List<EmojiMeta>> _filteredLists = {};

  // Recent + Favorites — dynamic, persisted in SharedPreferences
  List<String> _recentGlyphs = [];   // ordered newest-first, max 30
  Set<String> _favoriteGlyphs = {};

  static const String _prefKeyRecent    = 'emoji_recent';
  static const String _prefKeyFavorites = 'emoji_favorites';

  static const List<Map<String, String>> _categories = [
    {'id': 'recent',           'icon': '🕐', 'name': 'Recent'},
    {'id': 'favorites',        'icon': '⭐', 'name': 'Favorites'},
    {'id': 'smileys & emotion','icon': '😀', 'name': 'Smileys'},
    {'id': 'people & body',    'icon': '👋', 'name': 'People'},
    {'id': 'animals & nature', 'icon': '🐶', 'name': 'Animals'},
    {'id': 'food & drink',     'icon': '🍔', 'name': 'Food'},
    {'id': 'activities',       'icon': '⚽', 'name': 'Activities'},
    {'id': 'travel & places',  'icon': '🚗', 'name': 'Travel'},
    {'id': 'objects',          'icon': '💡', 'name': 'Objects'},
    {'id': 'symbols',          'icon': '✨', 'name': 'Symbols'},
    {'id': 'flags',            'icon': '🏳️', 'name': 'Flags'},
  ];

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
    
    final projectPack = widget.project.config.emojiPack;
    // 'googleAnimated' was the old hard-coded default — treat it the same as
    // null/empty so new-default notoColorEmoji kicks in for legacy projects.
    selectedPack = widget.initialPack ??
        ((projectPack == null ||
                projectPack == 'default' ||
                projectPack.isEmpty ||
                projectPack == 'googleAnimated')
            ? 'notoColorEmoji'
            : projectPack);

    _updateFilteredData();
    _loadPersistedData(); // async — loads recent/favorites then rebuilds
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounceTimer?.cancel();
    _gridScrollController.dispose();
    super.dispose();
  }

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recent    = prefs.getStringList(_prefKeyRecent)    ?? [];
      final favorites = prefs.getStringList(_prefKeyFavorites) ?? [];
      if (!mounted) return;
      setState(() {
        _recentGlyphs   = recent;
        _favoriteGlyphs = favorites.toSet();
        _updateFilteredData();
      });
    } catch (_) {}
  }

  Future<void> _addToRecent(String glyph) async {
    _recentGlyphs.remove(glyph);
    _recentGlyphs.insert(0, glyph);
    if (_recentGlyphs.length > 30) {
      _recentGlyphs = _recentGlyphs.sublist(0, 30);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKeyRecent, _recentGlyphs);
    } catch (_) {}
    if (mounted) setState(_updateFilteredData);
  }

  Future<void> _toggleFavorite(String glyph) async {
    if (_favoriteGlyphs.contains(glyph)) {
      _favoriteGlyphs.remove(glyph);
    } else {
      _favoriteGlyphs.add(glyph);
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefKeyFavorites, _favoriteGlyphs.toList());
    } catch (_) {}
    if (mounted) setState(_updateFilteredData);
  }

  bool _isSupportedOnWindowsSystemDefault(String unicode) {
    // Zero-Width Joiner (ZWJ) sequences (e.g., professions, families, horizontal/vertical head shakes,
    // face-in-clouds, black cat) often render as split/separated component glyphs on Windows
    // (e.g. man + medical staff, or face + cloud/arrow/gender sign).
    // Filtering out all ZWJ sequences on Windows under System Default guarantees a clean, native experience.
    if (unicode.toLowerCase().contains('200d')) {
      return false;
    }

    final parts = unicode.split('-');
    for (final part in parts) {
      try {
        final value = int.parse(part, radix: 16);
        
        // Filter out newer Unicode versions (Unicode 13.0, 14.0, 15.0, 15.1)
        // that Segoe UI Emoji on Windows lacks, causing tofu boxes (□).
        if (value >= 0x1F90C && value <= 0x1F90F) return false; // pinching hand, etc.
        if (value == 0x1F93F) return false;
        if (value == 0x1F972) return false; // smiling face with tear (Unicode 13.0)
        if (value >= 0x1F977 && value <= 0x1F979) return false; // ninja, disguised face, holding back tears (Unicode 13.0/14.0)
        if (value >= 0x1F9A3 && value <= 0x1F9AD) return false; // beaver, dodo, bison, etc.
        if (value >= 0x1F9C0 && value <= 0x1F9CF) return false;
        if (value >= 0x1F9D0 && value <= 0x1F9FF) return false; // newer people/objects
        if (value >= 0x1FA70 && value <= 0x1FAFF) return false; // yo-yo, kite, accordion, etc.
        if (value >= 0x1FAB0 && value <= 0x1FABF) return false; // feather, fly, etc.
        if (value >= 0x1FAC0 && value <= 0x1FACF) return false; // people hugging, etc.
        if (value >= 0x1FAD0 && value <= 0x1FADF) return false; // teapot, etc.
        if (value >= 0x1FAE0 && value <= 0x1FAEF) return false; // melting face, etc.
        if (value >= 0x1FAF0 && value <= 0x1FAFF) return false; // index pointing, etc.
        
        // Windows Segoe UI Emoji lacks U+1F6FB (pickup truck) and U+1F6FC (roller skate)
        if (value >= 0x1F6FB && value <= 0x1F6FF) return false; 
        if (value >= 0x1F6D0 && value <= 0x1F6DF) return false; // playground slide, elevator, etc.
        
      } catch (_) {}
    }
    return true;
  }

  /// Whether [e] should be shown when [selectedPack] is the active asset
  /// pack.
  ///
  /// FIX (Issue #6, CapStudio 1.0 audit): this exact predicate previously
  /// existed as 4 separate inline copies within this class (recent list,
  /// favorites list, standard category browsing, and search results) — no
  /// legitimate reason for the duplication, just copy-paste. Single
  /// implementation now; all 4 call it.
  bool _isEmojiAvailableForPack(EmojiMeta e, String selectedPack) {
    if (selectedPack == 'notoColorEmoji') return true;
    if (selectedPack == 'systemDefault') {
      if (defaultTargetPlatform == TargetPlatform.windows) {
        if (!_isSupportedOnWindowsSystemDefault(e.unicode)) return false;
        return e.styles.containsKey('microsoftNonAnimated');
      }
      return e.styles.isNotEmpty;
    }
    return e.styles.containsKey(selectedPack);
  }

  void _updateFilteredData() {
    final manifest = ref.read(assetManifestProvider);
    final Map<String, int> counts = {};
    final Map<String, List<EmojiMeta>> lists = {};

    for (final cat in _categories) {
      final catId = cat['id']!;

      // Dynamic categories — built from persisted glyph lists
      if (catId == 'recent') {
        final recentList = _recentGlyphs
            .map((g) => manifest.byGlyph[g])
            .whereType<EmojiMeta>()
            .where((e) => _isEmojiAvailableForPack(e, selectedPack))
            .toList();
        lists[catId]  = recentList;
        counts[catId] = recentList.length;
        continue;
      }
      if (catId == 'favorites') {
        final favList = _favoriteGlyphs
            .map((g) => manifest.byGlyph[g])
            .whereType<EmojiMeta>()
            .where((e) => _isEmojiAvailableForPack(e, selectedPack))
            .toList();
        lists[catId]  = favList;
        counts[catId] = favList.length;
        continue;
      }

      // Standard Unicode categories — same filter logic as before
      final list = manifest.byGroup[catId] ?? [];
      
      final filtered = list.where((e) {
        if (e.unicode.contains('-1f3fb') || e.unicode.contains('-1f3fc') ||
            e.unicode.contains('-1f3fd') || e.unicode.contains('-1f3fe') ||
            e.unicode.contains('-1f3ff') ||
            e.glyph.endsWith('🏻') || e.glyph.endsWith('🏼') ||
            e.glyph.endsWith('🏽') || e.glyph.endsWith('🏾') || e.glyph.endsWith('🏿')) {
          return false;
        }
        if (e.glyph.length == 1 && e.glyph.codeUnitAt(0) < 127) {
          return false;
        }
        final codeUnits = e.glyph.runes.toList();
        if (codeUnits.length == 1) {
          final rune = codeUnits.first;
          if (rune >= 0x1F1E6 && rune <= 0x1F1FF) {
            return false;
          }
        }
        final u = e.unicode;
        if (u == '0023-20e3' || u == '002a-20e3' || (u.startsWith('003') && u.endsWith('-20e3')) ||
            u == '00a9' || u == '00ae' || u == '2122') {
          return false;
        }

        // For a specific asset pack: only show emojis that pack supports.
        // For systemDefault: only show emojis at least one of our packs knows about
        //   — this hides obscure territory flags (AC, AD, AQ…) and newer Unicode
        //   characters that none of the 6 asset packs cover, which would render
        //   as boxes or letter pairs on Windows.
        // For notoColorEmoji: show everything — the bundled font covers all.
        return _isEmojiAvailableForPack(e, selectedPack);
      }).toList();

      lists[catId]  = filtered;
      counts[catId] = filtered.length;
    }

    _filteredLists  = lists;
    _categoryCounts = counts;
  }

  List<PopupMenuEntry<String>> _buildPopupMenuItems(List<String> installedPackIds) {
    return kEmojiPackMeta.map((pack) {
      final id    = pack['id']!;
      final name  = pack['name']!;
      final isInstalled = id == 'systemDefault' || id == 'notoColorEmoji' || installedPackIds.contains(id);

      return PopupMenuItem<String>(
        value: id,
        enabled: isInstalled,
        height: 36,
        child: SizedBox(
          height: 32,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    isInstalled ? name : '$name  🔒',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: isInstalled ? Colors.white : Colors.white38,
                      fontWeight: isInstalled ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  String _packDisplayName(String packId) {
    return kEmojiPackMeta.firstWhere(
      (p) => p['id'] == packId,
      orElse: () => {'name': packId},
    )['name']!;
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double availableHeight = screenHeight - keyboardHeight;
    final double maxBodyHeight = (availableHeight * 0.48).clamp(160.0, 320.0);
    final bool isShortScreen = availableHeight < 500;
    final bool useScrollFallback = availableHeight < 400;

    final isSearching = searchController.text.trim().isNotEmpty;
    final verification = ref.watch(assetVerificationProvider);

    final unfilteredList = isSearching ? searchResults : (_filteredLists[activeCategory] ?? []);
    final displayList = isSearching
        ? unfilteredList.where((e) {
            if (e.unicode.contains('-1f3fb') || e.unicode.contains('-1f3fc') ||
                e.unicode.contains('-1f3fd') || e.unicode.contains('-1f3fe') ||
                e.unicode.contains('-1f3ff') ||
                e.glyph.endsWith('🏻') || e.glyph.endsWith('🏼') ||
                e.glyph.endsWith('🏽') || e.glyph.endsWith('🏾') || e.glyph.endsWith('🏿')) {
              return false;
            }
            if (e.glyph.length == 1 && e.glyph.codeUnitAt(0) < 127) {
              return false;
            }
            final codeUnits = e.glyph.runes.toList();
            if (codeUnits.length == 1) {
              final rune = codeUnits.first;
              if (rune >= 0x1F1E6 && rune <= 0x1F1FF) {
                return false;
              }
            }
            final u = e.unicode;
            if (u == '0023-20e3' || u == '002a-20e3' || (u.startsWith('003') && u.endsWith('-20e3')) ||
                u == '00a9' || u == '00ae' || u == '2122') {
              return false;
            }
            return _isEmojiAvailableForPack(e, selectedPack);
          }).toList()
        : unfilteredList;

    final Widget innerContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'STYLE PACK',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.secondaryText,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  PopupMenuButton<String>(
                    offset: const Offset(0, 36),
                    color: AppTheme.cardBg,
                    tooltip: 'Select Style Pack',
                    itemBuilder: (context) => _buildPopupMenuItems(verification.installedPackIds),
                    onSelected: (val) {
                      final isSpecial = val == 'systemDefault' || val == 'notoColorEmoji';
                      final isInstalled = isSpecial || verification.installedPackIds.contains(val);
                      
                      if (!isInstalled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.redAccent,
                            content: Text(
                              'This pack is not downloaded yet. Please download it from the Settings panel to unlock it.',
                              style: TextStyle(color: Colors.white),
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        setState(() {});
                        return;
                      }
                      
                      setState(() {
                        selectedPack = val;
                        _updateFilteredData();
                        if (activeCategory != 'recent' && activeCategory != 'favorites') {
                          final activeCount = _categoryCounts[activeCategory] ?? 0;
                          if (activeCount == 0) {
                            activeCategory = 'recent';
                          }
                        }
                      });
                      LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Emoji pack changed in picker to: $val');
                    },
                    child: Container(
                      height: isShortScreen ? 30 : 34,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _packDisplayName(selectedPack),
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.primaryText,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: AppTheme.primaryText.withValues(alpha: 0.6), size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: TextField(
                controller: searchController,
                style: TextStyle(fontSize: 12, color: AppTheme.primaryText),
                decoration: InputDecoration(
                  hintText: 'Search...',
                  prefixIcon: const Icon(Icons.search, size: 16),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: isShortScreen ? 4 : 8,
                    horizontal: 8,
                  ),
                  border: AppTheme.defaultBorder(radius: 10),
                  focusedBorder: AppTheme.focusedBorder(radius: 10),
                  filled: true,
                  fillColor: AppTheme.cardBg,
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: () {
                            searchController.clear();
                            setState(() {
                              searchResults = [];
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (val) {
                  _debounceTimer?.cancel();
                  _debounceTimer = Timer(const Duration(milliseconds: 150), () {
                    if (mounted) {
                      final manifest = ref.read(assetManifestProvider);
                      final matches = manifest.search(val);
                      setState(() {
                        searchResults = matches;
                      });
                    }
                  });
                },
              ),
            ),
          ],
        ),
        SizedBox(height: isShortScreen ? 6 : 12),
        if (!isSearching) ...[
          // Category Icons Bar (Compact, fits all 11 categories on a single row)
          (() {
            final visibleCategories = _categories.where((cat) {
              final catId = cat['id']!;
              if (catId == 'recent' || catId == 'favorites') return true;
              return (_categoryCounts[catId] ?? 0) > 0;
            }).toList();

            return SizedBox(
              height: isShortScreen ? 32 : 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: visibleCategories.length,
                itemBuilder: (context, index) {
                  final cat = visibleCategories[index];
                  final catId = cat['id']!;
                  final isSelected = catId == activeCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4.0),
                    child: ChoiceChip(
                      visualDensity: isShortScreen ? VisualDensity.compact : null,
                      padding: const EdgeInsets.all(4),
                      labelPadding: EdgeInsets.zero,
                      label: Text(
                        cat['icon']!,
                        style: TextStyle(
                          fontSize: isShortScreen ? 14 : 16,
                          fontFamily: 'Noto Color Emoji',
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            activeCategory = catId;
                          });
                          if (_gridScrollController.hasClients) {
                            _gridScrollController.jumpTo(0.0);
                          }
                        }
                      },
                      selectedColor: AppTheme.accentOrange,
                      backgroundColor: Colors.white.withValues(alpha: 0.04),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: isSelected ? AppTheme.accentOrange : Colors.white10),
                    ),
                  );
                },
              ),
            );
          })(),
          SizedBox(height: isShortScreen ? 6 : 10),
          // Active Category Header Title
          (() {
            final activeCatMeta = _categories.firstWhere((c) => c['id'] == activeCategory);
            final activeCatName = activeCatMeta['name']!;
            final activeCatIcon = activeCatMeta['icon']!;
            final activeCount = _categoryCounts[activeCategory] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
              child: Row(
                children: [
                  Text(
                    activeCatIcon,
                    style: const TextStyle(fontSize: 14, fontFamily: 'Noto Color Emoji'),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    activeCatName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($activeCount)',
                    style: TextStyle(
                      fontSize: 9,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
            );
          })(),
          SizedBox(height: isShortScreen ? 4 : 8),
        ],
        (() {
          if (displayList.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: useScrollFallback ? 24.0 : 0.0),
                child: Text(
                  'No emojis found.',
                  style: TextStyle(color: AppTheme.mutedText, fontSize: 12),
                ),
              ),
            );
          }

          final grid = GridView.builder(
            controller: useScrollFallback ? null : _gridScrollController,
            shrinkWrap: useScrollFallback,
            physics: useScrollFallback ? const NeverScrollableScrollPhysics() : null,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isShortScreen ? 8 : 6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: displayList.length,
            itemBuilder: (context, idx) {
              final match = displayList[idx];
              final isFavorited = _favoriteGlyphs.contains(match.glyph);
              return Stack(
                children: [
                  EmojiTile(
                    emoji: match,
                    packId: selectedPack,
                    onSelect: (selectedGlyph) {
                      _addToRecent(selectedGlyph);
                      if (widget.onEmojiSelected != null) {
                        widget.onEmojiSelected!(selectedPack, selectedGlyph);
                        return;
                      }
                      if (widget.chunk.words.isNotEmpty) {
                        final firstWord = widget.chunk.words.first;
                        final firstWordId = firstWord.wordId;
                        if (firstWordId != null) {
                          ref.read(editorProvider.notifier).updateWord(
                            firstWordId,
                            emoji: '$selectedPack:$selectedGlyph',
                            emojiX: 0.0,
                            emojiY: 0.0,
                            emojiScale: 1.0,
                          );
                          LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Assigned emoji $selectedPack:$selectedGlyph to chunk');
                        }
                      }
                      Navigator.pop(context);
                    },
                  ),
                  // ── Favorite toggle — tap the star to add/remove ──────────
                  Positioned(
                    top: 2,
                    left: 2,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(match.glyph),
                      child: Icon(
                        isFavorited ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 9,
                        color: isFavorited
                            ? AppTheme.accentOrange
                            : Colors.white24,
                      ),
                    ),
                  ),
                ],
              );
            },
          );

          if (useScrollFallback) {
            return grid;
          } else {
            return Expanded(child: grid);
          }
        })(),
      ],
    );

    return PremiumBlurDialog(
      maxWidth: isShortScreen ? 500 : 460,
      useScrollView: useScrollFallback,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'SELECT EMOJI',
                  style: TextStyle(
                    fontSize: isShortScreen ? 11 : 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryText,
                    letterSpacing: 1.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.close, size: isShortScreen ? 18 : 20, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(color: Colors.white10, height: isShortScreen ? 8 : 16),
          useScrollFallback
              ? innerContent
              : ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: maxBodyHeight,
                  ),
                  child: innerContent,
                ),
        ],
      ),
    );
  }
}

class EmojiSettingsDialog extends ConsumerStatefulWidget {
  final WordSchema word;
  final Project project;
  final Chunk chunk;

  const EmojiSettingsDialog({
    super.key,
    required this.word,
    required this.project,
    required this.chunk,
  });

  @override
  ConsumerState<EmojiSettingsDialog> createState() => _EmojiSettingsDialogState();
}

class _EmojiSettingsDialogState extends ConsumerState<EmojiSettingsDialog> {
  String? currentEmoji;
  double emojiX = 0.0;
  double emojiY = 0.0;
  double emojiScale = 1.0;
  double emojiSpeed = 1.0;
  late TextEditingController searchController;
  List<EmojiMeta> searchResults = [];
  String? selectedPackOverride;
  Timer? _settingsDebounceTimer;

  String? _originalEmoji;
  double _originalX = 0.0;
  double _originalY = 0.0;
  double _originalScale = 1.0;
  double _originalSpeed = 1.0;
  bool _isSaved = false;
  late final EditorController _editorController;

  @override
  void initState() {
    super.initState();
    _editorController = ref.read(editorProvider.notifier);
    _originalEmoji = widget.word.emoji;
    _originalX = widget.word.emojiConfig?.x ?? 0.0;
    _originalY = widget.word.emojiConfig?.y ?? 0.0;
    _originalScale = widget.word.emojiConfig?.scale ?? 1.0;
    _originalSpeed = widget.word.emojiConfig?.speed ?? 1.0;

    final parseResult = EmojiPackParser.parse(widget.word.emoji ?? '', 'notoColorEmoji');
    currentEmoji = parseResult.glyph;
    selectedPackOverride = (parseResult.pack.isEmpty ||
            parseResult.pack == 'default')
        ? 'notoColorEmoji'
        : parseResult.pack;
    
    emojiX = _originalX;
    emojiY = _originalY;
    emojiScale = _originalScale;
    emojiSpeed = _originalSpeed;
    searchController = TextEditingController();
  }

  @override
  void dispose() {
    searchController.dispose();
    _settingsDebounceTimer?.cancel();
    
    if (!_isSaved && widget.word.wordId != null) {
      Future.microtask(() {
        _editorController.updateWordEmojiQuietly(
          widget.word.wordId!,
          emoji: _originalEmoji,
          emojiX: _originalX,
          emojiY: _originalY,
          emojiScale: _originalScale,
          emojiSpeed: _originalSpeed,
        );
      });
    }
    
    super.dispose();
  }

  void _updateLivePreview() {
    final wordId = widget.word.wordId;
    if (wordId != null) {
      final String finalEmoji = (currentEmoji == null || currentEmoji == 'none' || currentEmoji!.isEmpty)
          ? 'none'
          : '$selectedPackOverride:$currentEmoji';

      ref.read(editorProvider.notifier).updateWordEmojiQuietly(
        wordId,
        emoji: finalEmoji,
        emojiX: emojiX,
        emojiY: emojiY,
        emojiScale: emojiScale,
        emojiSpeed: emojiSpeed,
      );
    }
  }

  String _packDisplayName(String packId) {
    return kEmojiPackMeta.firstWhere(
      (p) => p['id'] == packId,
      orElse: () => {'name': packId},
    )['name']!;
  }

  List<PopupMenuEntry<String>> _buildPopupMenuItems() {
    final service = EmojiService.instance;
    return kEmojiPackMeta.map((pack) {
      final id   = pack['id']!;
      final name = pack['name']!;
      final isInstalled = id == 'systemDefault' || id == 'notoColorEmoji' || service.isPackInstalled(id);

      return PopupMenuItem<String>(
        value: id,
        enabled: isInstalled,
        height: 36,
        child: SizedBox(
          height: 32,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              isInstalled ? name : '$name  🔒',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: isInstalled ? Colors.white : Colors.white38,
                fontWeight: isInstalled ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final bool isLandscape = screenWidth > screenHeight;

    return PremiumBlurDialog(
      maxWidth: 460,
      borderOpacity: 0.12,
      useScrollView: false,
      alignment: isLandscape ? Alignment.centerRight : Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'EMOJI SETTINGS',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.primaryText,
                    letterSpacing: 1.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (currentEmoji != null && currentEmoji != 'none')
                        Tooltip(
                          message: 'Change Emoji',
                          child: InkWell(
                            onTap: () {
                              showDialog<void>(
                                context: context,
                                builder: (dialogContext) {
                                  return EmojiPickerDialog(
                                    project: widget.project,
                                    chunk: widget.chunk,
                                    initialPack: selectedPackOverride,
                                    onEmojiSelected: (selectedPack, selectedGlyph) {
                                      setState(() {
                                        currentEmoji = selectedGlyph;
                                        selectedPackOverride = selectedPack;
                                      });
                                      _updateLivePreview();
                                      Navigator.pop(dialogContext);
                                    },
                                  );
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: AppTheme.glassDecoration(
                                color: AppTheme.accentOrange.withValues(alpha: 0.15),
                                borderRadius: 6,
                                borderOpacity: 0.25,
                              ),
                              child: Text(
                                currentEmoji!,
                                style: const TextStyle(fontSize: 24, fontFamily: 'Noto Color Emoji'),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          style: TextStyle(fontSize: 12, color: AppTheme.primaryText),
                          decoration: InputDecoration(
                            labelText: 'Search Emojis...',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: AppTheme.defaultBorder(radius: 8),
                            focusedBorder: AppTheme.focusedBorder(radius: 8),
                            filled: true,
                            fillColor: AppTheme.cardBg,
                            suffixIcon: searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 16),
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() {
                                        searchResults = [];
                                      });
                                    },
                                  )
                                : const Icon(Icons.search, size: 16),
                          ),
                          onChanged: (val) {
                            _settingsDebounceTimer?.cancel();
                            _settingsDebounceTimer = Timer(const Duration(milliseconds: 150), () {
                              if (mounted) {
                                final matches = ref.read(assetManifestProvider).search(val);
                                setState(() {
                                  searchResults = matches;
                                });
                              }
                            });
                          },
                          onSubmitted: (val) {
                            final matches = ref.read(assetManifestProvider).search(val);
                            setState(() {
                              searchResults = matches;
                            });
                          },
                        ),
                      ),
                      if (currentEmoji != null && currentEmoji != 'none') ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.clear, color: Colors.redAccent),
                          onPressed: () {
                            final wordId = widget.word.wordId;
                            if (wordId != null) {
                              setState(() {
                                _isSaved = true;
                              });
                              ref.read(editorProvider.notifier).updateWord(
                                wordId,
                                emoji: 'none',
                                emojiX: 0.0,
                                emojiY: 0.0,
                                emojiScale: 1.0,
                              );
                              LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Removed emoji via Settings Dialog X button');
                            }
                            Navigator.pop(context);
                          },
                        ),
                      ]
                    ],
                  ),
                  if (searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 180,
                      decoration: AppTheme.glassDecoration(
                        color: Colors.black12,
                        borderRadius: 6,
                        borderOpacity: 0.08,
                      ),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: searchResults.length,
                        itemBuilder: (context, idx) {
                          final match = searchResults[idx];
                          final activePack = selectedPackOverride ?? 'notoColorEmoji';
                          return InkWell(
                            onTap: () {
                              setState(() {
                                currentEmoji = match.glyph;
                                searchResults = [];
                                searchController.clear();
                              });
                              _updateLivePreview();
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: AppTheme.glassDecoration(
                                color: Colors.white.withValues(alpha: 0.02),
                                borderRadius: 6,
                                borderOpacity: 0.04,
                              ),
                              child: Center(
                                child: EmojiImage(
                                  emoji: match,
                                  activePack: activePack,
                                  size: 28,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  if (currentEmoji != null && currentEmoji != 'none') ...[
                    const SizedBox(height: 16),
                    Text('Emoji Position (X Offset: ${emojiX.toStringAsFixed(0)}px)', style: Theme.of(context).textTheme.bodyMedium),
                    SliderTheme(
                      data: AppTheme.premiumSliderTheme(context),
                      child: Slider(
                        value: emojiX,
                        min: -150,
                        max: 150,
                        divisions: 60,
                        onChanged: (val) {
                          setState(() {
                            emojiX = val;
                          });
                          _updateLivePreview();
                        },
                      ),
                    ),
                    Text('Emoji Position (Y Offset: ${emojiY.toStringAsFixed(0)}px)', style: Theme.of(context).textTheme.bodyMedium),
                    SliderTheme(
                      data: AppTheme.premiumSliderTheme(context),
                      child: Slider(
                        value: emojiY,
                        min: -150,
                        max: 150,
                        divisions: 60,
                        onChanged: (val) {
                          setState(() {
                            emojiY = val;
                          });
                          _updateLivePreview();
                        },
                      ),
                    ),
                    Text('Emoji Scale (${emojiScale.toStringAsFixed(2)}x)', style: Theme.of(context).textTheme.bodyMedium),
                    SliderTheme(
                      data: AppTheme.premiumSliderTheme(context),
                      child: Slider(
                        value: emojiScale,
                        min: 0.5,
                        max: 2.0,
                        divisions: 30,
                        onChanged: (val) {
                          setState(() {
                            emojiScale = val;
                          });
                          _updateLivePreview();
                        },
                      ),
                    ),
                    if (selectedPackOverride == 'googleAnimated' || selectedPackOverride == 'microsoftAnimated') ...[
                      Text('Animation Speed (${emojiSpeed.toStringAsFixed(1)}x)', style: Theme.of(context).textTheme.bodyMedium),
                      SliderTheme(
                        data: AppTheme.premiumSliderTheme(context),
                        child: Slider(
                          value: emojiSpeed,
                          min: 0.2,
                          max: 4.0,
                          divisions: 38,
                          onChanged: (val) {
                            setState(() {
                              emojiSpeed = val;
                            });
                            _updateLivePreview();
                          },
                        ),
                      ),
                    ],
                    if (!EmojiService.instance.isCustomSticker(currentEmoji ?? '')) ...[
                      const SizedBox(height: 16),
                      Text('Emoji Style / Pack', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      PopupMenuButton<String>(
                        offset: const Offset(0, 38),
                        color: AppTheme.cardBg,
                        tooltip: 'Select Style Pack',
                        itemBuilder: (context) => _buildPopupMenuItems(),
                        onSelected: (val) {
                          final isSpecial = val == 'systemDefault' || val == 'notoColorEmoji';
                          final isInstalled = isSpecial || EmojiService.instance.isPackInstalled(val);
                          
                          if (!isInstalled) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.redAccent,
                                content: Text(
                                  'This pack is not downloaded yet. Please download it from the Settings panel to unlock it.',
                                  style: TextStyle(color: Colors.white),
                                ),
                                duration: Duration(seconds: 3),
                              ),
                            );
                            setState(() {});
                            return;
                          }
                          
                          setState(() {
                            selectedPackOverride = val;
                          });
                          _updateLivePreview();
                        },
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _packDisplayName(selectedPackOverride ?? 'notoColorEmoji'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryText,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.arrow_drop_down, color: AppTheme.primaryText.withValues(alpha: 0.6), size: 18),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                  final wordId = widget.word.wordId;
                  if (wordId != null) {
                    final String? finalEmoji = (currentEmoji == null || currentEmoji == 'none' || currentEmoji!.isEmpty)
                        ? null
                        : '$selectedPackOverride:$currentEmoji';

                    setState(() {
                      _isSaved = true;
                    });

                    ref.read(editorProvider.notifier).updateWord(
                      wordId,
                      emoji: finalEmoji,
                      emojiX: emojiX,
                      emojiY: emojiY,
                      emojiScale: emojiScale,
                      emojiSpeed: emojiSpeed,
                    );
                    LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Saved emoji settings for word');
                  }
                  Navigator.pop(context);
                },
                child: const Text('SAVE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
