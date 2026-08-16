import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/assets/asset_manifest.dart';
import '../../../../../../core/assets/asset_verification_service.dart';
import '../../../../../../core/assets/emoji_image.dart';
import '../../../../../../core/emoji/emoji_service.dart';

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

