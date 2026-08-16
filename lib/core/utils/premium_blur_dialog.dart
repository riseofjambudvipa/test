import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app/theme.dart';

/// A premium, highly polished Liquid Glass dialog wrapper.
/// Features a deep BackdropFilter blur, semi-transparent borders, and
/// built-in responsive sizing with vertical scroll-adaptation to guarantee
/// that RenderFlex layout overflows never happen.
class PremiumBlurDialog extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final Color? glassColor;
  final double borderOpacity;
  final bool animate;

  final bool useScrollView;

  final Color? glowColor;
  final double glowOpacity;
  final Alignment alignment;

  const PremiumBlurDialog({
    super.key,
    required this.child,
    this.maxWidth = 580,
    this.glassColor,
    this.borderOpacity = 0.08,
    this.animate = true,
    this.useScrollView = true,
    this.glowColor,
    this.glowOpacity = 0.0,
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape = size.height < 500;
    
    final EdgeInsets padding = isLandscape
        ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0)
        : EdgeInsets.all(size.width < 600 ? 16.0 : 24.0);

    final double heightMultiplier = isLandscape ? 0.92 : 0.85;

    Widget dialogBody = Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: size.width < 600 ? 12.0 : 40.0,
        vertical: size.height < 600 ? 12.0 : 40.0,
      ),
      child: Align(
        alignment: alignment,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: (size.width * 0.92).clamp(280.0, maxWidth),
              constraints: BoxConstraints(
                maxHeight: (size.height - MediaQuery.of(context).viewInsets.bottom) * heightMultiplier,
              ),
              decoration: AppTheme.glassDecoration(
                color: glassColor ?? AppTheme.cardBg.withValues(alpha: 0.85),
                borderRadius: 16,
                borderOpacity: borderOpacity,
                glowColor: glowColor,
                glowOpacity: glowOpacity,
              ),
              padding: padding,
              child: ClipRect(
                child: useScrollView
                    ? SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: child,
                      )
                    : child,
              ),
            ),
          ),
        ),
      ),
    );

    final bool shouldAnimate = animate && (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST'));
    if (shouldAnimate) {
      dialogBody = dialogBody
          .animate()
          .fade(duration: 250.ms, curve: Curves.easeOut)
          .scale(
            begin: const Offset(0.95, 0.95),
            end: const Offset(1.0, 1.0),
            duration: 300.ms,
            curve: Curves.easeOutBack,
          );
    }

    return dialogBody;
  }
}
