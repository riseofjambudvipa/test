import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../../../../core/assets/asset_path_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../../../../core/database/schemas/word.dart';
import '../../../../../../core/assets/asset_manifest.dart';
import '../../../../../../core/assets/asset_verification_service.dart';
import '../../../../../../core/logger/logger_service.dart';
import '../../../../../../core/emoji/emoji_service.dart';
import '../../../../domain/caption_engine.dart';
import '../../../controllers/editor_controller.dart';
import 'emoji_tile.dart';
import 'emoji_pack_meta.dart';
import '../../../../../../l10n/app_localizations.dart';

class EmojiPickerDialog extends ConsumerStatefulWidget {
  final Project project;
  final Chunk chunk;
  final String? initialPack;
  final WordSchema? targetWord;
  final void Function(String selectedPack, String selectedGlyph)? onEmojiSelected;

  const EmojiPickerDialog({
    super.key,
    required this.project,
    required this.chunk,
    this.initialPack,
    this.targetWord,
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
    {'id': 'custom',           'icon': '🖼️', 'name': 'Stickers'},
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
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'EmojiPicker', 'Failed to load emoji recents/favorites: $e');
    }
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
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'EmojiPicker', 'Failed to save recent glyphs: $e');
    }
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
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'EmojiPicker', 'Failed to save favorite glyphs: $e');
    }
    if (mounted) setState(_updateFilteredData);
  }

  Future<void> _importCustomStickers() async {
    if (kIsWeb) return;
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp', 'gif'],
      );
      if (result == null || result.files.isEmpty) return;

      final targetDir = AssetPathService.instance.customStickersDir;
      final dir = Directory(targetDir);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      int copied = 0;
      for (final file in result.files) {
        if (file.path != null) {
          final src = File(file.path!);
          final dest = File(p.join(targetDir, file.name));
          src.copySync(dest.path);
          copied++;
        }
      }

      if (copied > 0) {
        await EmojiService.instance.scanCustomStickers(targetDir);
        if (mounted) {
          setState(() {
            _updateFilteredData();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Imported $copied sticker${copied > 1 ? 's' : ''} successfully!'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'EmojiPicker', 'Failed to import stickers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import stickers: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
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
        
      } catch (e) {
        LoggerService.instance.debug('Error checking Segoe UI Emoji support: $e');
      }
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
    if (e.group == 'Custom Stickers') return true;
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

  /// Filters out skin-tone variants, single-byte ASCII characters, regional
  /// indicator symbols (unsupported standalone flags), and legacy keycaps/symbols.
  bool _isExcludedEmoji(String character, [String? unicode]) {
    if (character.contains('/') || character.contains('\\')) return false;
    final manifest = ref.read(assetManifestProvider);
    final u = unicode ??
        manifest.byGlyph[character]?.unicode ??
        (manifest.byUnicode.containsKey(character) ? character : null) ??
        character.runes
            .map((r) => r.toRadixString(16).padLeft(4, '0').toLowerCase())
            .join('-');
    if (u.contains('-1f3fb') ||
        u.contains('-1f3fc') ||
        u.contains('-1f3fd') ||
        u.contains('-1f3fe') ||
        u.contains('-1f3ff') ||
        character.endsWith('🏻') ||
        character.endsWith('🏼') ||
        character.endsWith('🏽') ||
        character.endsWith('🏾') ||
        character.endsWith('🏿')) {
      return true;
    }
    if (character.length == 1 && character.codeUnitAt(0) < 127) {
      return true;
    }
    final codeUnits = character.runes.toList();
    if (codeUnits.length == 1) {
      final rune = codeUnits.first;
      if (rune >= 0x1F1E6 && rune <= 0x1F1FF) {
        return true;
      }
    }
    final isKeycapOrSymbol = u == '0023-20e3' ||
        u == '002a-20e3' ||
        (u.startsWith('003') && u.endsWith('-20e3')) ||
        u == '00a9' ||
        u == '00ae' ||
        u == '2122' ||
        character == '©' ||
        character == '®' ||
        character == '™' ||
        character.contains('\u20e3');
    if (isKeycapOrSymbol) {
      return true;
    }
    return false;
  }

  void _updateFilteredData() {
    final manifest = ref.read(assetManifestProvider);
    final Map<String, int> counts = {};
    final Map<String, List<EmojiMeta>> lists = {};

    for (final cat in _categories) {
      final catId = cat['id']!;

      // Dynamic categories — built from persisted glyph lists
      if (catId == 'recent' || catId == 'favorites') {
        final glyphList = catId == 'recent' ? _recentGlyphs : _favoriteGlyphs.toList();
        final list = <EmojiMeta>[];
        for (final g in glyphList) {
          final meta = manifest.byGlyph[g];
          if (meta != null) {
            if (_isEmojiAvailableForPack(meta, selectedPack)) list.add(meta);
          } else {
            final custom = EmojiService.instance.findByGlyph(g);
            if (custom != null && custom.group == 'Custom Stickers') {
              list.add(EmojiMeta(
                unicode: custom.unicode,
                glyph: custom.glyph,
                name: custom.name,
                group: 'Custom Stickers',
                unicodeVersion: '1.0',
                keywords: custom.keywords,
                shortcodes: custom.shortcodes,
                styles: custom.styles,
              ));
            }
          }
        }
        lists[catId]  = list;
        counts[catId] = list.length;
        continue;
      }

      if (catId == 'custom') {
        final customModels = EmojiService.instance.getByGroup('Custom Stickers');
        final customList = customModels.map((m) {
          return EmojiMeta(
            unicode: m.unicode,
            glyph: m.glyph,
            name: m.name,
            group: 'Custom Stickers',
            unicodeVersion: '1.0',
            keywords: m.keywords,
            shortcodes: m.shortcodes,
            styles: m.styles,
          );
        }).toList();
        lists[catId]  = customList;
        counts[catId] = customList.length;
        continue;
      }

      // Standard Unicode categories — same filter logic as before
      final list = manifest.byGroup[catId] ?? [];
      
      final filtered = list.where((e) {
        if (_isExcludedEmoji(e.glyph, e.unicode)) {
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
                      color: isInstalled ? AppTheme.primaryText : AppTheme.mutedText,
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
    final l10n = AppLocalizations.of(context);
    final double screenHeight = MediaQuery.of(context).size.height;
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double availableHeight = screenHeight - keyboardHeight;
    final double maxBodyHeight = (availableHeight * 0.48).clamp(240.0, 360.0);
    final bool isShortScreen = availableHeight < 500;
    final bool useScrollFallback = availableHeight < 400;

    final isSearching = searchController.text.trim().isNotEmpty;
    final verification = ref.watch(assetVerificationProvider);

    final unfilteredList = isSearching ? searchResults : (_filteredLists[activeCategory] ?? []);
    final displayList = isSearching
        ? unfilteredList.where((e) {
            if (_isExcludedEmoji(e.glyph, e.unicode)) {
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
                    l10n?.stylePackLabel ?? 'STYLE PACK',
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
                    tooltip: l10n?.selectStylePackTooltip ?? 'Select Style Pack',
                    itemBuilder: (context) => _buildPopupMenuItems(verification.installedPackIds),
                    onSelected: (val) {
                      final isSpecial = val == 'systemDefault' || val == 'notoColorEmoji';
                      final isInstalled = isSpecial || verification.installedPackIds.contains(val);
                      
                      if (!isInstalled) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppTheme.accentRed,
                            content: Text(
                              'This pack is not downloaded yet. Please download it from the Settings panel to unlock it.',
                              style: TextStyle(color: AppTheme.onAccentText),
                            ),
                            duration: const Duration(seconds: 3),
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
                        border: Border.all(color: AppTheme.borderGlass),
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
                  hintText: l10n?.searchHint ?? 'Search...',
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
                      final customModels = EmojiService.instance
                          .search(val)
                          .where((m) => m.group == 'Custom Stickers');
                      final customMetas = customModels.map((m) => EmojiMeta(
                            unicode: m.unicode,
                            glyph: m.glyph,
                            name: m.name,
                            group: 'Custom Stickers',
                            unicodeVersion: '1.0',
                            keywords: m.keywords,
                            shortcodes: m.shortcodes,
                            styles: m.styles,
                          ));
                      setState(() {
                        searchResults = [...matches, ...customMetas];
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
              if (catId == 'recent' || catId == 'favorites' || catId == 'custom') return true;
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
                      backgroundColor: AppTheme.cardBgElevated,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: isSelected ? AppTheme.accentOrange : AppTheme.borderGlass),
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
                  if (activeCategory == 'custom' && !kIsWeb) ...[
                    const Spacer(),
                    InkWell(
                      onTap: _importCustomStickers,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_photo_alternate_rounded, size: 12, color: AppTheme.accentOrange),
                            const SizedBox(width: 4),
                            Text(
                              'IMPORT',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentOrange),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          })(),
          SizedBox(height: isShortScreen ? 4 : 8),
        ],
        (() {
          if (displayList.isEmpty) {
            final Widget emptyView;
            if (activeCategory == 'custom') {
              emptyView = Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 32, color: AppTheme.mutedText),
                      const SizedBox(height: 6),
                      Text(
                        'No Custom Stickers Yet',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryText),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Import transparent PNG, JPG, or GIF files to overlay custom stickers and graphics on your captions.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 10.5, color: AppTheme.secondaryText, height: 1.25),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 14),
                        label: const Text('IMPORT STICKERS', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange,
                          foregroundColor: AppTheme.onAccentText,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _importCustomStickers,
                      ),
                    ],
                  ),
                ),
              );
            } else {
              emptyView = Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: useScrollFallback ? 24.0 : 0.0),
                  child: Text(
                    l10n?.noEmojisFound ?? 'No emojis found.',
                    style: TextStyle(color: AppTheme.mutedText, fontSize: 12),
                  ),
                ),
              );
            }
            return useScrollFallback ? emptyView : Expanded(child: emptyView);
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
                      final isSticker = !kIsWeb &&
                          (match.group == 'Custom Stickers' ||
                              selectedGlyph.endsWith('.png') ||
                              selectedGlyph.endsWith('.webp') ||
                              selectedGlyph.endsWith('.jpg') ||
                              selectedGlyph.endsWith('.jpeg') ||
                              selectedGlyph.endsWith('.gif') ||
                              selectedGlyph.startsWith('/') ||
                              RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(selectedGlyph) ||
                              EmojiService.resolveStickerPath(selectedGlyph) != null);
                      final packToUse = isSticker ? 'custom' : selectedPack;
                      if (widget.onEmojiSelected != null) {
                        widget.onEmojiSelected!(packToUse, selectedGlyph);
                        return;
                      }
                      if (widget.chunk.words.isNotEmpty) {
                        final target = widget.targetWord ??
                            widget.chunk.words.firstWhere(
                              (w) => w.emoji == null || w.emoji!.isEmpty || w.emoji == 'none',
                              orElse: () => widget.chunk.words.first,
                            );
                        final targetWordId = target.wordId;
                        if (targetWordId != null) {
                          final finalEmoji = '$packToUse:$selectedGlyph';
                          ref.read(editorProvider.notifier).updateWord(
                            targetWordId,
                            emoji: finalEmoji,
                            emojiX: 0.0,
                            emojiY: 0.0,
                            emojiScale: 1.0,
                          );
                          LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Assigned emoji $finalEmoji to word "$targetWordId"');
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
                            : AppTheme.mutedText.withValues(alpha: 0.35),
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
                  l10n?.selectEmojiTitle ?? 'SELECT EMOJI',
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
                icon: Icon(Icons.close, size: isShortScreen ? 18 : 20, color: AppTheme.secondaryText),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(color: AppTheme.dividerColor, height: isShortScreen ? 8 : 16),
          useScrollFallback
              ? innerContent
              : SizedBox(
                  height: maxBodyHeight,
                  child: innerContent,
                ),
        ],
      ),
    );
  }
}

