import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'asset_manifest.dart';
import '../emoji/emoji_service.dart';

/// Displays an emoji image from disk.
/// Fallback chain: activePack → googleNonAnimated → microsoftNonAnimated → openmoji → unicode glyph
/// NEVER throws. NEVER shows red error widget.
class EmojiImage extends ConsumerStatefulWidget {
  final EmojiMeta emoji;
  final String activePack;
  final double size;
  final double? currentTime;
  final double? wordStart;
  final double speed;
  final bool isPlaying;

  const EmojiImage({
    super.key,
    required this.emoji,
    required this.activePack,
    this.size = 32,
    this.currentTime,
    this.wordStart,
    this.speed = 1.0,
    this.isPlaying = true,
  });

  static final Map<String, String?> _resolvedPathCache = {};

  static void clearCache() {
    _resolvedPathCache.clear();
  }

  @override
  ConsumerState<EmojiImage> createState() => _EmojiImageState();
}

class _EmojiImageState extends ConsumerState<EmojiImage> with SingleTickerProviderStateMixin {
  EmojiModel? _loadedDetails;
  AnimatedEmojiFrames? _animatedFrames;
  bool _isLoadingFrames = false;
  String? _loadedFramesPath;
  AnimationController? _previewController;

  @override
  void initState() {
    super.initState();
    _loadDetails();
    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
  }

  @override
  void dispose() {
    _previewController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(EmojiImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.emoji.unicode != widget.emoji.unicode ||
        oldWidget.activePack != widget.activePack ||
        oldWidget.emoji.glyph != widget.emoji.glyph) {
      _loadDetails();
    }

    final speedChanged = oldWidget.speed != widget.speed;
    final emojiChanged = oldWidget.emoji.unicode != widget.emoji.unicode ||
        oldWidget.activePack != widget.activePack ||
        oldWidget.emoji.glyph != widget.emoji.glyph;

    if ((speedChanged || emojiChanged) && !widget.isPlaying) {
      _previewController?.reset();
      _previewController?.forward();
    }

    if (widget.isPlaying && oldWidget.isPlaying != widget.isPlaying) {
      _previewController?.stop();
    }
  }

  void _loadDetails() {
    final service = EmojiService.instance;
    final stub = service.findByGlyph(widget.emoji.glyph);
    if (stub != null && mounted) {
      setState(() {
        _loadedDetails = stub;
      });
    }
  }

  Future<void> _loadAnimatedFrames(String path) async {
    if (_isLoadingFrames) return;
    _isLoadingFrames = true;
    _loadedFramesPath = path;
    
    try {
      final frames = await EmojiFrameCache.instance.getFrames(path);
      if (mounted && _loadedFramesPath == path) {
        setState(() {
          _animatedFrames = frames;
          _isLoadingFrames = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingFrames = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentEmojiModel = _loadedDetails;
    final path = _resolve(currentEmojiModel);
    
    final parseResult = EmojiPackParser.parse(widget.emoji.glyph, widget.activePack);
    final displayGlyph = parseResult.glyph;

    final fallbackStyle = TextStyle(
      fontSize: widget.size * 0.75,
      fontFamily: widget.activePack == 'notoColorEmoji'
          ? 'Noto Color Emoji'
          : switch (defaultTargetPlatform) {
              TargetPlatform.android => null, // Let mobile devices use their native default system emoji font
              TargetPlatform.macOS   => 'Apple Color Emoji',
              TargetPlatform.windows => 'Segoe UI Emoji',
              TargetPlatform.linux   => null,
              _                      => null,
            },
    );

    if (path != null) {
      final lowercasePath = path.toLowerCase();
      final isAnimFormat = lowercasePath.endsWith('.webp') || lowercasePath.endsWith('.gif') || lowercasePath.endsWith('.png');
      if (widget.currentTime != null && widget.wordStart != null && isAnimFormat) {
        final cached = EmojiFrameCache.instance.getCachedFrames(path);
        if (cached != null) {
          _animatedFrames = cached;
        } else if (_loadedFramesPath != path) {
          _loadAnimatedFrames(path);
        }

        final frames = _animatedFrames;
        if (frames != null && frames.images.isNotEmpty) {
          Widget buildRawImage() {
            final isLocalPreview = _previewController != null && _previewController!.isAnimating;
            final double elapsedSeconds = isLocalPreview
                ? (_previewController!.value * 12.0) * widget.speed
                : (widget.currentTime! - widget.wordStart!) * widget.speed;

            final elapsedMs = (elapsedSeconds * 1000).toInt().clamp(0, 999999);
            final loopMs = frames.totalDuration.inMilliseconds;
            
            ui.Image targetImage = frames.images.first;
            if (loopMs > 0) {
              final targetMs = elapsedMs % loopMs;
              int accumMs = 0;
              for (int i = 0; i < frames.images.length; i++) {
                accumMs += frames.durations[i].inMilliseconds;
                if (targetMs < accumMs) {
                  targetImage = frames.images[i];
                  break;
                }
              }
            }

            return SizedBox(
              width: widget.size,
              height: widget.size,
              child: RawImage(
                image: targetImage,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
            );
          }

          return AnimatedBuilder(
            animation: _previewController!,
            builder: (context, child) => buildRawImage(),
          );
        }
      }
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: path == null
          ? Center(child: Text(displayGlyph, style: fallbackStyle))
          : Image.file(
              File(path),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              errorBuilder: (context, error, stackTrace) =>
                  Text(displayGlyph, style: fallbackStyle),
            ),
    );
  }

  String? _resolve(EmojiModel? details) {
    final parseResult = EmojiPackParser.parse(widget.emoji.glyph, widget.activePack);
    final activePack = parseResult.pack;
    
    final unicode = details?.unicode ?? widget.emoji.unicode;
    final key = '${unicode}_$activePack';
    if (EmojiImage._resolvedPathCache.containsKey(key)) {
      return EmojiImage._resolvedPathCache[key];
    }
    final path = _resolveImpl(details, activePack);
    EmojiImage._resolvedPathCache[key] = path;
    return path;
  }

  String? _resolveImpl(EmojiModel? details, String activePack) {
    if (kIsWeb) return null;
    if (activePack == 'systemDefault' || activePack == 'notoColorEmoji') {
      return null;
    }

    final service = EmojiService.instance;
    final emojiModel = details ?? service.findByGlyph(widget.emoji.glyph);
    if (emojiModel == null) return null;

    // 1. Try the selected activePack (if it's installed/downloaded)
    if (service.isPackInstalled(activePack) && service.hasAssetOnDisk(emojiModel, activePack)) {
      final asset = service.getAssetPath(emojiModel, activePack);
      if (asset != null) return asset.absolutePath;
    }

    // 2. FALLBACK 1: If activePack is animated (googleAnimated / microsoftAnimated), check their static equivalents
    if (activePack == 'googleAnimated') {
      const staticPack = 'googleNonAnimated';
      if (service.isPackInstalled(staticPack) && service.hasAssetOnDisk(emojiModel, staticPack)) {
        final asset = service.getAssetPath(emojiModel, staticPack);
        if (asset != null) return asset.absolutePath;
      }
    } else if (activePack == 'microsoftAnimated') {
      const staticPack = 'microsoftNonAnimated';
      if (service.isPackInstalled(staticPack) && service.hasAssetOnDisk(emojiModel, staticPack)) {
        final asset = service.getAssetPath(emojiModel, staticPack);
        if (asset != null) return asset.absolutePath;
      }
    }

    // 3. FALLBACK 2: Check other installed image packs that contain this exact emoji
    final otherPacks = const ['googleNonAnimated', 'openmoji', 'microsoftNonAnimated', 'googleAnimated', 'microsoftAnimated'];
    for (final pack in otherPacks) {
      if (pack != activePack) {
        if (service.isPackInstalled(pack) && service.hasAssetOnDisk(emojiModel, pack)) {
          final asset = service.getAssetPath(emojiModel, pack);
          if (asset != null) return asset.absolutePath;
        }
      }
    }

    // 4. FALLBACK 3: Return null to fall back to native system font (preserves the skin tone)
    return null;
  }
}

class AnimatedEmojiFrames {
  final List<ui.Image> images;
  final List<Duration> durations;
  final Duration totalDuration;

  AnimatedEmojiFrames({
    required this.images,
    required this.durations,
    required this.totalDuration,
  });
}

class EmojiFrameCache {
  EmojiFrameCache._();
  static final EmojiFrameCache instance = EmojiFrameCache._();

  final Map<String, AnimatedEmojiFrames> _cache = {};

  Future<AnimatedEmojiFrames?> getFrames(String path) async {
    if (_cache.containsKey(path)) {
      return _cache[path];
    }

    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      final bytes = await file.readAsBytes();
      
      final codec = await ui.instantiateImageCodec(bytes);
      if (codec.frameCount <= 1) {
        codec.dispose();
        return null;
      }

      final List<ui.Image> images = [];
      final List<Duration> durations = [];
      int totalMs = 0;

      for (int i = 0; i < codec.frameCount; i++) {
        final frameInfo = await codec.getNextFrame();
        images.add(frameInfo.image);
        durations.add(frameInfo.duration);
        totalMs += frameInfo.duration.inMilliseconds;
      }
      codec.dispose();

      final frames = AnimatedEmojiFrames(
        images: images,
        durations: durations,
        totalDuration: Duration(milliseconds: totalMs),
      );
      _cache[path] = frames;
      return frames;
    } catch (e) {
      debugPrint('Failed to decode animated emoji: $e');
      return null;
    }
  }

  AnimatedEmojiFrames? getCachedFrames(String path) {
    return _cache[path];
  }

  void clear() {
    for (final frames in _cache.values) {
      for (final img in frames.images) {
        img.dispose();
      }
    }
    _cache.clear();
  }
}
