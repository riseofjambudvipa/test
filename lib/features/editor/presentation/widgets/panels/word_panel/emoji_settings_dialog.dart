import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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
import '../../../../../../l10n/app_localizations.dart';

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
  // FIX (audit, cancel-revert race): revision markers used to decide whether
  // the dispose-revert is still safe to apply. _openRevision is captured when
  // the dialog opens; _lastPushRevision tracks the revision after this dialog's
  // own last live-preview push.
  late int _openRevision;
  int _lastPushRevision = -1;

  @override
  void initState() {
    super.initState();
    _editorController = ref.read(editorProvider.notifier);
    _openRevision = _editorController.revision;
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
      final wordId = widget.word.wordId!;
      Future.microtask(() {
        // FIX (audit, cancel-revert race): only apply the revert when nothing
        // else has edited the project since this dialog's last change. A
        // find/replace, another dialog, or a retranscribe bumps the revision
        // past our last push — reverting then would clobber the newer state
        // with stale originals (or write stale emoji into a retranscribed
        // project that reused the same wordId).
        final currentRevision = _editorController.revision;
        final lastKnown =
            _lastPushRevision >= 0 ? _lastPushRevision : _openRevision;
        if (currentRevision != lastKnown) return;
        _editorController.updateWordEmojiQuietly(
          wordId,
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
      final isSticker = !kIsWeb &&
          (currentEmoji != null &&
              (currentEmoji!.endsWith('.png') ||
                  currentEmoji!.endsWith('.webp') ||
                  currentEmoji!.endsWith('.jpg') ||
                  currentEmoji!.endsWith('.jpeg') ||
                  currentEmoji!.endsWith('.gif') ||
                  currentEmoji!.startsWith('/') ||
                  RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(currentEmoji!) ||
                  EmojiService.resolveStickerPath(currentEmoji!) != null));
      final pack = isSticker ? 'custom' : (selectedPackOverride ?? 'notoColorEmoji');
      final String finalEmoji = (currentEmoji == null || currentEmoji == 'none' || currentEmoji!.isEmpty)
          ? 'none'
          : '$pack:$currentEmoji';

      ref.read(editorProvider.notifier).updateWordEmojiQuietly(
        wordId,
        emoji: finalEmoji,
        emojiX: emojiX,
        emojiY: emojiY,
        emojiScale: emojiScale,
        emojiSpeed: emojiSpeed,
      );
      // Remember the revision right after this dialog's own push, so the
      // dispose-revert can detect external edits that landed afterwards.
      _lastPushRevision = _editorController.revision;
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
                color: isInstalled ? AppTheme.primaryText : AppTheme.mutedText,
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
    final l10n = AppLocalizations.of(context);
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
                  l10n?.emojiSettingsTitle ?? 'EMOJI SETTINGS',
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
                icon: Icon(Icons.close, size: 20, color: AppTheme.secondaryText),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(color: AppTheme.dividerColor, height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (currentEmoji != null && currentEmoji != 'none')
                        Tooltip(
                          message: l10n?.changeEmojiTooltip ?? 'Change Emoji',
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
                                      final isSticker = !kIsWeb &&
                                          (selectedGlyph.endsWith('.png') ||
                                              selectedGlyph.endsWith('.webp') ||
                                              selectedGlyph.endsWith('.jpg') ||
                                              selectedGlyph.endsWith('.jpeg') ||
                                              selectedGlyph.endsWith('.gif') ||
                                              selectedGlyph.startsWith('/') ||
                                              RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(selectedGlyph) ||
                                              EmojiService.resolveStickerPath(selectedGlyph) != null);
                                      setState(() {
                                        currentEmoji = selectedGlyph;
                                        selectedPackOverride = isSticker ? 'custom' : selectedPack;
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
                              child: Builder(
                                builder: (context) {
                                  final isSticker = !kIsWeb &&
                                      (File(currentEmoji!).existsSync() ||
                                          currentEmoji!.startsWith('/') ||
                                          RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(currentEmoji!));
                                  if (isSticker) {
                                    return Image.file(
                                      File(currentEmoji!),
                                      width: 24,
                                      height: 24,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.image_outlined,
                                        size: 24,
                                      ),
                                    );
                                  }
                                  return Text(
                                    currentEmoji!,
                                    style: const TextStyle(fontSize: 24, fontFamily: 'Noto Color Emoji'),
                                  );
                                },
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
                            labelText: l10n?.searchEmojisHint ?? 'Search Emojis...',
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
                          icon: Icon(Icons.clear, color: AppTheme.accentRed),
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
                        color: AppTheme.surfaceDim,
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
                                color: AppTheme.cardBgElevated,
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
                    Text(l10n?.emojiPosX(emojiX.toStringAsFixed(0)) ?? 'Emoji Position (X Offset: ${emojiX.toStringAsFixed(0)}px)', style: Theme.of(context).textTheme.bodyMedium),
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
                    Text(l10n?.emojiPosY(emojiY.toStringAsFixed(0)) ?? 'Emoji Position (Y Offset: ${emojiY.toStringAsFixed(0)}px)', style: Theme.of(context).textTheme.bodyMedium),
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
                    Text(l10n?.emojiScale(emojiScale.toStringAsFixed(2)) ?? 'Emoji Scale (${emojiScale.toStringAsFixed(2)}x)', style: Theme.of(context).textTheme.bodyMedium),
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
                      Text(l10n?.emojiAnimSpeed(emojiSpeed.toStringAsFixed(1)) ?? 'Animation Speed (${emojiSpeed.toStringAsFixed(1)}x)', style: Theme.of(context).textTheme.bodyMedium),
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
                      Text(l10n?.emojiStylePack ?? 'Emoji Style / Pack', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      PopupMenuButton<String>(
                        offset: const Offset(0, 38),
                        color: AppTheme.cardBg,
                        tooltip: l10n?.selectStylePackTooltip ?? 'Select Style Pack',
                        itemBuilder: (context) => _buildPopupMenuItems(),
                        onSelected: (val) {
                          final isSpecial = val == 'systemDefault' || val == 'notoColorEmoji';
                          final isInstalled = isSpecial || EmojiService.instance.isPackInstalled(val);
                          
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
                            selectedPackOverride = val;
                          });
                          _updateLivePreview();
                        },
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
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
                child: Text(l10n?.btnCancel ?? 'CANCEL', style: TextStyle(color: AppTheme.secondaryText, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: AppTheme.onAccentText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                onPressed: () {
                  final wordId = widget.word.wordId;
                  if (wordId != null) {
                    final isSticker = !kIsWeb &&
                        (currentEmoji != null &&
                            (File(currentEmoji!).existsSync() ||
                                currentEmoji!.startsWith('/') ||
                                RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(currentEmoji!)));
                    final pack = isSticker ? 'custom' : (selectedPackOverride ?? 'notoColorEmoji');
                    final String finalEmoji = (currentEmoji == null || currentEmoji == 'none' || currentEmoji!.isEmpty)
                        ? 'none'
                        : '$pack:$currentEmoji';

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
                child: Text(l10n?.btnSave ?? 'SAVE', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
