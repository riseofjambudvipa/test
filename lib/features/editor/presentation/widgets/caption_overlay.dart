import 'dart:io';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/text_layout_utils.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_provider.dart';
import '../../../../core/database/schemas/project.dart';
import '../../../../core/database/schemas/word.dart';
import '../../../../core/assets/emoji_image.dart';
import '../../../../core/assets/asset_manifest.dart';
import '../../../../core/emoji/emoji_service.dart';
import '../../domain/caption_engine.dart';
import '../controllers/editor_controller.dart';

// ─── Single animated word ──────────────────────────────────────────────────────

class AnimatedCaptionWord extends StatefulWidget {
  final WordSchema word;
  final bool isActive;
  final bool hasEntered;     // true once the chunk containing this word appears
  final StyleConfigSchema style;
  final HighlightStyleSchema highlightStyle;
  final String strokeMode;   // 'thick' | 'none'
  final String shadowMode;   // 'soft' | 'none'
  final String animationMode; // 'pop' | 'bounce' | 'kineticTilt' | 'glowPulse' | 'wordReveal' | 'none'
  final double scale;
  final int wordIndexInChunk;
  final bool isExporting;
  final double exportCurrentTime;
  final double exportChunkStart;

  const AnimatedCaptionWord({
    super.key,
    required this.word,
    required this.isActive,
    required this.hasEntered,
    required this.style,
    required this.highlightStyle,
    required this.strokeMode,
    required this.shadowMode,
    required this.animationMode,
    required this.scale,
    required this.wordIndexInChunk,
    this.isExporting = false,
    this.exportCurrentTime = 0.0,
    this.exportChunkStart = 0.0,
  });

  @override
  State<AnimatedCaptionWord> createState() => _AnimatedCaptionWordState();
}

class _AnimatedCaptionWordState extends State<AnimatedCaptionWord>
    with TickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _slideAnim;

  late AnimationController _activeCtrl;
  late Animation<double> _activeSpringAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _buildAnimations();

    _activeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _activeSpringAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _activeCtrl, curve: Curves.easeOutBack),
    );
    if (widget.isActive) {
      _activeCtrl.value = 1.0;
    }

    // Staggered entry: each word in the chunk enters 30ms after the previous
    if (widget.hasEntered && !widget.isExporting) {
      if (widget.animationMode == 'none') {
        _ctrl.value = 1.0;
      } else {
        Future.delayed(
          Duration(milliseconds: widget.wordIndexInChunk * 30),
          () { if (mounted) _ctrl.forward(); },
        );
      }
    }
  }

  void _buildAnimations() {
    switch (widget.animationMode) {
      case 'pop':
      case 'glowPulse':
        _scaleAnim = Tween<double>(begin: 0.4, end: 1.0).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
        _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.6)));
        _slideAnim = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
            .animate(_ctrl);
        break;

      case 'wordReveal':
        _scaleAnim = Tween<double>(begin: 0.7, end: 1.0).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
        _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5)));
        _slideAnim = Tween<Offset>(
                begin: const Offset(0, 0.3), end: Offset.zero)
            .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
        break;

      case 'bounce':
        _scaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut));
        _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.4)));
        _slideAnim = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
            .animate(_ctrl);
        break;

      case 'kineticTilt':
        _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
            CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
        _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5)));
        _slideAnim = Tween<Offset>(
                begin: const Offset(-0.2, 0), end: Offset.zero)
            .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutExpo));
        break;

      default: // 'none'
        _scaleAnim = const AlwaysStoppedAnimation(1.0);
        _opacityAnim = const AlwaysStoppedAnimation(1.0);
        _slideAnim = const AlwaysStoppedAnimation(Offset.zero);
        _ctrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedCaptionWord old) {
    super.didUpdateWidget(old);
    final modeChanged = old.animationMode != widget.animationMode;
    // New chunk appeared — restart entry animation
    if (!old.hasEntered && widget.hasEntered && !widget.isExporting) {
      _ctrl.reset();
      _buildAnimations();
      Future.delayed(
        Duration(milliseconds: widget.wordIndexInChunk * 30),
        () { if (mounted) _ctrl.forward(); },
      );
    } else if (modeChanged && !widget.isExporting) {
      // Rebuild and restart with the new mode
      _ctrl.reset();
      _buildAnimations();
      _ctrl.forward();
    }

    // Active word kinetic spring transition: pop/bounce when spoken
    if (!old.isActive && widget.isActive && !widget.isExporting) {
      _activeCtrl.forward(from: 0.0);
    } else if (old.isActive && !widget.isActive && !widget.isExporting) {
      _activeCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _activeCtrl.dispose();
    super.dispose();
  }

  Color _fillColor() {
    final style = widget.style;
    final hs = widget.highlightStyle;
    final Color base = _parseHex(style.color, Colors.white);

    if (widget.isActive || widget.word.className != null) {
      final cls = widget.word.className ?? (widget.isActive ? 'mainColor' : null);
      if (cls == 'mainColor')   return _parseHex(hs.mainColor, Colors.orange);
      if (cls == 'secondColor') return _parseHex(hs.secondColor, Colors.cyan);
      if (cls == 'thirdColor')  return _parseHex(hs.thirdColor, Colors.green);
    }
    return base;
  }

  Color _parseHex(String? hex, Color fallback) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
    } catch (_) { return fallback; }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isExporting) {
      final delay = widget.wordIndexInChunk * 0.030;
      final animStart = widget.exportChunkStart + delay;
      final elapsed = widget.exportCurrentTime - animStart;
      _ctrl.value = elapsed < 0.0 ? 0.0 : (elapsed / 0.180).clamp(0.0, 1.0);

      final wordStart = widget.word.start ?? 0.0;
      final activeElapsed = (widget.exportCurrentTime - wordStart).clamp(0.0, 0.14);
      _activeCtrl.value = widget.isActive ? (activeElapsed / 0.14).clamp(0.0, 1.0) : 0.0;
    }

    if (widget.word.hidden == true) return const SizedBox.shrink();

    final style   = widget.style;
    final fillColor = _fillColor();
    final fs = style.fontSize * widget.scale;
    final fw = _parseFontWeight(style.fontWeight);
    final text = _transformText(widget.word.text ?? '', style.textTransform);

    final strokeWidth = widget.strokeMode == 'thick'
        ? 6.0 * widget.scale
        : (widget.strokeMode == 'thin' ? 2.5 * widget.scale : 0.0);
    final strokeColor = Colors.black;

    // Active spring value with elastic overshoot (0.0 to 1.0+)
    final springVal = widget.animationMode != 'none'
        ? _activeSpringAnim.value
        : (widget.isActive ? 1.0 : 0.0);

    // Active word scale boost with dynamic kinetic spring (up to 1.18x)
    final activeBoost = 1.0 + (springVal * 0.18);

    // Tilt for kineticTilt active word (dynamic spring tilt)
    final tiltAngle = (widget.animationMode == 'kineticTilt')
        ? ((widget.wordIndexInChunk % 2 == 0 ? -0.078 : 0.078) * springVal)
        : 0.0;

    // Bounce jump translation (dynamic spring vertical bounce)
    final bounceOffset = (widget.animationMode == 'bounce')
        ? Offset(0, -springVal * 7.0 * widget.scale)
        : Offset.zero;

    // Background highlight box (the CapCut-style pill)
    final showBgBox = widget.isActive && style.highlightBackground == true;

    // Dynamic glowing shadow system
    final List<Shadow> shadowStack = [];
    if (widget.animationMode == 'glowPulse' && springVal > 0.01) {
      shadowStack.addAll([
        Shadow(
          color: fillColor.withValues(alpha: (0.85 * springVal).clamp(0.0, 1.0)),
          blurRadius: (16.0 * widget.scale * springVal).clamp(0.0, 32.0),
          offset: Offset.zero,
        ),
        Shadow(
          color: fillColor.withValues(alpha: (0.5 * springVal).clamp(0.0, 1.0)),
          blurRadius: (8.0 * widget.scale * springVal).clamp(0.0, 16.0),
          offset: Offset.zero,
        ),
      ]);
    } else if (widget.shadowMode == '3d' || widget.shadowMode == 'extruded') {
      for (double step = 1.0; step <= 5.0; step += 1.0) {
        shadowStack.add(
          Shadow(
            color: Colors.black.withValues(alpha: (0.95 - (step * 0.12)).clamp(0.2, 1.0)),
            blurRadius: 0,
            offset: Offset(step * 1.5 * widget.scale, step * 1.5 * widget.scale),
          ),
        );
      }
    } else if (widget.shadowMode == 'hard') {
      shadowStack.add(
        Shadow(
          color: Colors.black.withValues(alpha: 0.8),
          blurRadius: 0,
          offset: Offset(3.5 * widget.scale, 3.5 * widget.scale),
        ),
      );
    } else if (widget.shadowMode == 'soft') {
      shadowStack.add(
        Shadow(
          color: Colors.black.withValues(alpha: 0.5),
          blurRadius: 2.0 * widget.scale,
          offset: Offset(2.0 * widget.scale, 2.0 * widget.scale),
        ),
      );
    }

    Widget wordWidget = Stack(
      clipBehavior: Clip.none,
      children: [
        if (strokeWidth > 0)
          Text(text,
            softWrap: false,
            style: TextStyle(
              fontFamily: style.fontFamily,
              fontFamilyFallback: AppThemeData.fontFallbacks,
              fontSize: fs,
              fontWeight: fw,
              letterSpacing: (style.letterSpacing ?? 0) * widget.scale,
              foreground: Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = strokeWidth
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..color = strokeColor,
            ),
          ),
        Text(text,
          softWrap: false,
          style: TextStyle(
            fontFamily: style.fontFamily,
            fontFamilyFallback: AppThemeData.fontFallbacks,
            fontSize: fs,
            fontWeight: fw,
            letterSpacing: (style.letterSpacing ?? 0) * widget.scale,
            color: fillColor,
            shadows: shadowStack,
          ),
        ),
      ],
    );

    if (showBgBox) {
      final bgBoxColor = fillColor.withValues(alpha: 0.9);
      final textOnBg = ColorUtils.contrastColor(bgBoxColor);
      wordWidget = Container(
        padding: EdgeInsets.symmetric(
            horizontal: 8 * widget.scale, vertical: 4 * widget.scale),
        decoration: BoxDecoration(
          color: bgBoxColor,
          borderRadius: BorderRadius.circular(6 * widget.scale),
        ),
        child: Text(text,
          softWrap: false,
          style: TextStyle(
            fontFamily: style.fontFamily,
            fontFamilyFallback: AppThemeData.fontFallbacks,
            fontSize: fs,
            fontWeight: fw,
            letterSpacing: (style.letterSpacing ?? 0) * widget.scale,
            color: textOnBg,
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: Listenable.merge([_ctrl, _activeCtrl]),
      builder: (context, child) => FractionalTranslation(
        translation: _slideAnim.value,
        child: Opacity(
          opacity: _opacityAnim.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: bounceOffset,
            child: Transform.rotate(
              angle: tiltAngle,
              child: Transform.scale(
                scale: _scaleAnim.value * activeBoost,
                child: child,
              ),
            ),
          ),
        ),
      ),
      child: wordWidget,
    );
  }

  String _transformText(String s, String mode) => switch (mode) {
    'uppercase'  => s.toUpperCase(),
    'capitalize' => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1),
    _            => s,
  };

  FontWeight _parseFontWeight(String w) => switch (w) {
    '900'  => FontWeight.w900,
    '800'  => FontWeight.w800,
    '700' || 'bold' => FontWeight.bold,
    '600'  => FontWeight.w600,
    '500'  => FontWeight.w500,
    '300'  => FontWeight.w300,
    _      => FontWeight.normal,
  };
}

// ─── Main CaptionOverlay ──────────────────────────────────────────────────────

class CaptionOverlay extends ConsumerStatefulWidget {
  final List<Chunk> chunks;
  final double currentTime;
  final ProjectConfigSchema config;
  final double scale;
  final bool allowDrag;   // true in editor preview, false in export preview
  final void Function(double top)? onPositionChanged;
  final void Function(double left)? onHorizontalPositionChanged;
  final void Function()? onDragEnd;  // Called on drag-end to commit history
  final double videoWidth;  // dynamic sizing helpers
  final double videoHeight;
  final bool isControlsVisible;
  final bool isExporting;

  const CaptionOverlay({
    super.key,
    required this.chunks,
    required this.currentTime,
    required this.config,
    required this.scale,
    this.allowDrag = false,
    this.onPositionChanged,
    this.onHorizontalPositionChanged,
    this.onDragEnd,
    this.videoWidth = 360,
    this.videoHeight = 640,
    this.isControlsVisible = false,
    this.isExporting = false,
  });

  @override
  ConsumerState<CaptionOverlay> createState() => _CaptionOverlayState();
}

class _CaptionOverlayState extends ConsumerState<CaptionOverlay> {
  bool _isDragging = false;
  bool _snappedX = false;
  bool _snappedY = false;
  double _snappedTargetY = 50.0;

  // FIX (perf): memoize the wrapped-line layout. During playback the overlay
  // rebuilds on every currentTime tick, and splitWordsIntoLines allocates
  // fresh TextPainters per word per trial — heavy per-frame GC pressure.
  // The cache keyed on identity + dimensions recomputes only when the active
  // chunk, style, or viewport size actually changes.
  List<List<WordSchema>>? _cachedLines;
  List<WordSchema>? _cacheWords;
  StyleConfigSchema? _cacheStyle;
  double _cacheScale = -1;
  double _cacheWidth = -1;

  List<List<WordSchema>> _computeLines(
    List<WordSchema> words,
    StyleConfigSchema style,
    double effectiveScale,
    double maxPixelWidth,
  ) {
    if (_cachedLines == null ||
        !identical(_cacheWords, words) ||
        !identical(_cacheStyle, style) ||
        _cacheScale != effectiveScale ||
        _cacheWidth != maxPixelWidth) {
      _cacheWords = words;
      _cacheStyle = style;
      _cacheScale = effectiveScale;
      _cacheWidth = maxPixelWidth;
      _cachedLines = splitWordsIntoLines(words, style, effectiveScale, maxPixelWidth);
    }
    return _cachedLines!;
  }

  List<List<WordSchema>> splitWordsIntoLines(
    List<WordSchema> words,
    StyleConfigSchema style,
    double effectiveScale,
    double maxPixelWidth,
  ) {
    return TextLayoutUtils.splitWordsIntoLines(
      words: words,
      fontFamily: style.fontFamily,
      fontSize: style.fontSize * effectiveScale,
      fontWeight: style.fontWeight,
      letterSpacing: (style.letterSpacing ?? 0.0) * effectiveScale,
      maxPixelWidth: maxPixelWidth,
    );
  }

  bool _isRtlText(String text) {
    for (final rune in text.runes) {
      if ((rune >= 0x0590 && rune <= 0x05FF) || // Hebrew
          (rune >= 0x0600 && rune <= 0x06FF) || // Arabic
          (rune >= 0x0700 && rune <= 0x074F) || // Syriac
          (rune >= 0x0750 && rune <= 0x077F) || // Arabic Supplement
          (rune >= 0x0780 && rune <= 0x07BF) || // Thaana
          (rune >= 0x0870 && rune <= 0x089F) || // Arabic Extended-B
          (rune >= 0x08A0 && rune <= 0x08FF) || // Arabic Extended-A
          (rune >= 0xFB50 && rune <= 0xFDFF) || // Arabic Presentation Forms-A
          (rune >= 0xFE70 && rune <= 0xFEFF)) { // Arabic Presentation Forms-B
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final isPlaying = ref.watch(editorProvider.select((s) => s.isPlaying));
    final Chunk? activeChunk = CaptionEngine.getActiveChunk(
        widget.chunks, widget.currentTime);

    if (activeChunk == null) return const SizedBox.shrink();
    final Chunk currentChunk = activeChunk;

    final style = widget.config.style;
    final manifest = ref.read(assetManifestProvider);

    // Collect all emojis in the active chunk to lay them out inline side-by-side
    final chunkEmojiWords = <(WordSchema, EmojiMeta?)>[];
    for (final w in currentChunk.words) {
      if (w.emoji != null && w.emoji!.isNotEmpty && w.emoji != 'none') {
        final parsed = EmojiPackParser.parse(w.emoji!, '');
        final emojiMeta = manifest.byGlyph[parsed.glyph];
        chunkEmojiWords.add((w, emojiMeta));
      }
    }

    // Auto-detect RTL languages
    final isChunkRtl = currentChunk.words.any((w) => w.text != null && _isRtlText(w.text!));

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final containerAspect = constraints.maxWidth / constraints.maxHeight;
          // Calculate actual video render rect inside the container
          final defaultFallback = containerAspect < 1.0 ? (9 / 16) : (16 / 9);
          final videoAspect = (widget.videoWidth > 0 && widget.videoHeight > 0)
              ? widget.videoWidth / widget.videoHeight
              : defaultFallback;

          double videoW, videoH, videoLeft, videoTop;
          if ((videoAspect - containerAspect).abs() / containerAspect < 0.02) {
            videoW = constraints.maxWidth;
            videoH = constraints.maxHeight;
            videoLeft = 0;
            videoTop = 0;
          } else if (videoAspect < containerAspect) {
            videoH = constraints.maxHeight;
            videoW = videoH * videoAspect;
            videoLeft = (constraints.maxWidth - videoW) / 2;
            videoTop = 0;
          } else {
            videoW = constraints.maxWidth;
            videoH = videoW / videoAspect;
            videoLeft = 0;
            videoTop = (constraints.maxHeight - videoH) / 2;
          }

          // Dynamic scale: make captions responsive to the actual rendered
          // video size. Font sizes (28-44) in templates look correct at
          // ~640px rendered height. Scale proportionally for smaller/larger
          // previews so captions never overflow on narrow 9:16 previews.
          final effectiveScale = (videoH / 640.0).clamp(0.45, 4.0);

          // Safe horizontal padding (10% of video width on each side to keep captions in premium 80% safe area)
          final hPad = videoW * 0.10;
          final captionMaxW = videoW - (hPad * 2);

          // Dynamic multi-line wrapping algorithm (memoized — see _computeLines)
          final lines = _computeLines(
            currentChunk.words,
            style,
            effectiveScale,
            captionMaxW,
          );

          // The style.top is a percentage (0-100) of where the caption's
          // CENTER should be vertically within the video frame.
          final topFraction = (style.top / 100).clamp(0.05, 0.95);
          // The style.left is a percentage (0-100) for horizontal positioning.
          // 50 = centered, 0 = far left, 100 = far right.
          final leftFraction = (style.left / 100).clamp(0.05, 0.95);

          // Build only the text lines content
          final textLinesContent = Column(
            mainAxisSize: MainAxisSize.min,
            children: lines.map((lineWords) {
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 2.0 * effectiveScale),
                child: Wrap(
                  textDirection: isChunkRtl ? TextDirection.rtl : TextDirection.ltr,
                  spacing: ((style.fontSize * 0.20) + (widget.config.stroke == 'thick' ? 3.0 : 0.0)) * effectiveScale,
                  runSpacing: (style.lineHeight ?? 1.2) * style.fontSize * effectiveScale * 0.25,
                  alignment: WrapAlignment.center,
                  children: (() {
                    final wordToIndex = {
                      for (int i = 0; i < currentChunk.words.length; i++)
                        currentChunk.words[i].wordId: i
                    };
                    return lineWords.map((word) {
                      final idx = wordToIndex[word.wordId] ?? -1;
                      final wordStart = word.start ?? 0.0;
                      final wordEnd = word.end ?? 0.0;
                      final isActive = widget.currentTime >= wordStart &&
                          widget.currentTime <= wordEnd;
                      final double chunkStart = currentChunk.words.isNotEmpty
                          ? (currentChunk.words.first.start ?? 0.0)
                          : 0.0;

                      return AnimatedCaptionWord(
                        key: ValueKey('${currentChunk.index}_${word.wordId}'),
                        word: word,
                        isActive: isActive,
                        hasEntered: true,
                        style: style,
                        highlightStyle: widget.config.highlightStyle,
                        strokeMode: widget.config.stroke,
                        shadowMode: widget.config.shadow,
                        animationMode: widget.config.animation,
                        scale: effectiveScale,
                        wordIndexInChunk: idx,
                        isExporting: widget.isExporting,
                        exportCurrentTime: widget.currentTime,
                        exportChunkStart: chunkStart,
                      );
                    });
                  })().toList(),
                ),
              );
            }).toList(),
          );

          // Wrap only the text lines content in the background box if configured
          Widget textWidget = textLinesContent;
          if (widget.config.background != null && widget.config.background!.isNotEmpty) {
            final bgColor = ColorUtils.fromHex(widget.config.background, fallback: Colors.black);
            textWidget = Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * effectiveScale,
                vertical: 10 * effectiveScale,
              ),
              decoration: AppTheme.glassDecoration(
                color: bgColor.withValues(alpha: 0.7),
                borderRadius: 8 * effectiveScale,
                borderOpacity: 0.12,
              ),
              child: textLinesContent,
            );
          }

          // Build final content stacking emojis outside (above) the text container
          final contentWidget = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (chunkEmojiWords.isNotEmpty) ...[
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12.0 * effectiveScale,
                  runSpacing: 6.0 * effectiveScale,
                  children: [
                    for (final item in chunkEmojiWords)
                      _buildEmojiWithScale(item.$1, item.$2, effectiveScale, isPlaying),
                  ],
                ),
                SizedBox(height: 12 * effectiveScale),
              ],
              textWidget,
            ],
          );

          // Wrap in FittedBox to auto-shrink if content is still too wide.
          // By letting the Column lay out unconstrained, the words stay on the lines.
          // We add horizontal padding as a safety margin for active word zoom animations (activeBoost scale 1.12),
          // guaranteeing they never clip the video boundaries.
          final wrappedCaption = SizedBox(
            width: captionMaxW,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14 * effectiveScale),
                child: contentWidget,
              ),
            ),
          );

          // Build the clipped video-frame overlay with the caption
          Widget buildCaptionStack() {
            return Stack(
              children: [
                // Clip everything to the video rect
                Positioned(
                  left: videoLeft,
                  top: videoTop,
                  width: videoW,
                  height: videoH,
                  child: ClipRect(
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned(
                          left: hPad,
                          right: hPad,
                          top: 0,
                          bottom: 0,
                          child: Align(
                            alignment: Alignment((leftFraction - 0.5) * 2, (topFraction - 0.5) * 2),
                            child: wrappedCaption,
                          ),
                        ),
                        // Magnetic Horizontal Guideline (appears when snapped to key vertical positions)
                        if (_isDragging && _snappedY)
                          Positioned(
                            left: 0,
                            right: 0,
                            top: (videoH * (_snappedTargetY / 100)).clamp(0.0, videoH - 1.5),
                            child: Container(
                              height: 1.5,
                              color: AppTheme.accentCyan.withValues(alpha: 0.85),
                            ),
                          ),
                        // Magnetic Vertical Center Guideline (appears when snapped to X=50%)
                        if (_isDragging && _snappedX)
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: (videoW * 0.5) - 0.75,
                            child: Container(
                              width: 1.5,
                              color: AppTheme.accentCyan.withValues(alpha: 0.85),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          if (widget.allowDrag) {
            return RepaintBoundary(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanStart: (_) {
                  setState(() {
                    _isDragging = true;
                  });
                },
                onPanUpdate: (d) {
                  double newTopPct =
                      (style.top + (d.delta.dy / videoH * 100))
                          .clamp(10.0, 90.0);
                  double newLeftPct =
                      (style.left + (d.delta.dx / videoW * 100))
                          .clamp(10.0, 90.0);

                  // Magnetic horizontal center snap (50%)
                  bool snapX = false;
                  if ((newLeftPct - 50.0).abs() < 2.0) {
                    newLeftPct = 50.0;
                    snapX = true;
                  }

                  // Magnetic vertical snaps (25% top third, 50% center, 75% lower third, 80% baseline)
                  bool snapY = false;
                  double targetY = 50.0;
                  const snapTargetsY = [25.0, 50.0, 75.0, 80.0];
                  for (final t in snapTargetsY) {
                    if ((newTopPct - t).abs() < 1.8) {
                      newTopPct = t;
                      snapY = true;
                      targetY = t;
                      break;
                    }
                  }

                  if (_snappedX != snapX || _snappedY != snapY || _snappedTargetY != targetY) {
                    setState(() {
                      _snappedX = snapX;
                      _snappedY = snapY;
                      _snappedTargetY = targetY;
                    });
                  }

                  widget.onPositionChanged?.call(newTopPct);
                  widget.onHorizontalPositionChanged?.call(newLeftPct);
                },
                onPanEnd: (_) {
                  setState(() {
                    _isDragging = false;
                    _snappedX = false;
                    _snappedY = false;
                  });
                  widget.onDragEnd?.call();
                },
                child: buildCaptionStack(),
              ),
            );
          }

          // FIX (perf): isolate the animated caption stack behind a
          // RepaintBoundary so per-frame animation repaints re-rasterize only
          // this layer instead of the surrounding editor tree.
          return RepaintBoundary(child: buildCaptionStack());
        },
      ),
    );
  }

  Widget _buildEmojiWithScale(WordSchema emojiWord, EmojiMeta? emojiMeta, double scale, bool isPlaying) {
    final cfg = emojiWord.emojiConfig;
    final parsed = EmojiPackParser.parse(emojiWord.emoji ?? '', widget.config.emojiPack ?? 'notoColorEmoji');
    final activePack = (parsed.pack.isEmpty || parsed.pack == 'default')
        ? (widget.config.emojiPack ?? 'notoColorEmoji')
        : parsed.pack;

    final isFilePath = parsed.glyph.startsWith('/') ||
        RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(parsed.glyph) ||
        parsed.pack == 'custom' ||
        parsed.glyph.endsWith('.png') ||
        parsed.glyph.endsWith('.webp') ||
        parsed.glyph.endsWith('.jpg') ||
        parsed.glyph.endsWith('.jpeg') ||
        parsed.glyph.endsWith('.gif') ||
        parsed.glyph.contains('/') ||
        parsed.glyph.contains('\\') ||
        (emojiWord.emoji != null &&
            (emojiWord.emoji!.startsWith('/') ||
                RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(emojiWord.emoji!) ||
                emojiWord.emoji!.startsWith('custom:')));

    final resolvedSticker = (!kIsWeb)
        ? (EmojiService.resolveStickerPath(parsed.glyph) ??
            (emojiWord.emoji != null ? EmojiService.resolveStickerPath(emojiWord.emoji) : null))
        : null;

    final isCustomSticker = !kIsWeb && (resolvedSticker != null || isFilePath);

    Widget emojiContent;
    if (resolvedSticker != null && !kIsWeb) {
      emojiContent = SizedBox(
        width: 80 * scale,
        height: 80 * scale,
        child: Image.file(
          File(resolvedSticker),
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      );
    } else if (isCustomSticker) {
      // Custom sticker whose file is not on disk — never render raw path string as text!
      emojiContent = const SizedBox.shrink();
    } else if (emojiMeta != null &&
        activePack != 'systemDefault' &&
        activePack != 'notoColorEmoji') {
      emojiContent = EmojiImage(
        emoji: emojiMeta,
        activePack: activePack,
        size: 80 * scale,
        currentTime: widget.currentTime,
        wordStart: emojiWord.start,
        speed: cfg?.speed ?? 1.0,
        isPlaying: isPlaying,
      );
    } else {
      if (isFilePath) {
        emojiContent = const SizedBox.shrink();
      } else {
        emojiContent = Text(
          parsed.glyph,
          style: TextStyle(
            fontSize: 64 * scale,
            fontFamily: activePack == 'notoColorEmoji'
                ? 'Noto Color Emoji'
                : switch (defaultTargetPlatform) {
                    TargetPlatform.android => null, // Let mobile devices use their native default system emoji font
                    TargetPlatform.macOS   => 'Apple Color Emoji',
                    TargetPlatform.windows => 'Segoe UI Emoji',
                    TargetPlatform.linux   => null,
                    _                      => null, // web / fuchsia: rely on browser native
                  },
          ),
        );
      }
    }

    return Transform.translate(
      offset: Offset((cfg?.x ?? 0) * scale, (cfg?.y ?? 0) * scale),
      child: Transform.scale(
        scale: cfg?.scale ?? 1.0,
        child: emojiContent,
      ),
    );
  }

}
