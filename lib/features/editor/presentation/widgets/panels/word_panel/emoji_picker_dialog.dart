import 'dart:async';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../../../../core/assets/asset_manifest.dart';
import '../../../../../../core/assets/asset_verification_service.dart';
import '../../../../../../core/logger/logger_service.dart';
import '../../../../domain/caption_engine.dart';
import '../../../controllers/editor_controller.dart';
import 'emoji_tile.dart';
import 'emoji_pack_meta.dart';

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

