import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../../../../core/database/schemas/word.dart';
import '../../../../../../core/assets/asset_manifest.dart';
import '../../../../../../core/assets/emoji_image.dart';
import '../../../../../../core/logger/logger_service.dart';
import '../../../../../../core/emoji/emoji_service.dart';
import '../../../../domain/caption_engine.dart';
import '../../../controllers/editor_controller.dart';
import 'emoji_picker_dialog.dart';
import 'emoji_pack_meta.dart';

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
