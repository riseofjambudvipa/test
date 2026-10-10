import 'dart:ui';
import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Glowing Ambient Background Painter for atmospheric glow behind cards.
class GlowingBackgroundPainter extends CustomPainter {
  final Color primaryGlow;
  final Color secondaryGlow;
  final double devicePixelRatio;

  GlowingBackgroundPainter({
    required this.primaryGlow,
    required this.secondaryGlow,
    required this.devicePixelRatio,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120.0);

    final glowAlpha1 = AppTheme.isLight ? 0.04 : 0.12;
    final glowAlpha2 = AppTheme.isLight ? 0.03 : 0.08;
    final glowAlpha3 = AppTheme.isLight ? 0.015 : 0.03;

    // Glow 1: Top Right
    paint.color = primaryGlow.withValues(alpha: glowAlpha1);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), size.width * 0.25, paint);

    // Glow 2: Bottom Left
    paint.color = secondaryGlow.withValues(alpha: glowAlpha2);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.85), size.width * 0.3, paint);

    // Glow 3: Center Ambient
    paint.color = primaryGlow.withValues(alpha: glowAlpha3);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.2, paint);
  }

  @override
  bool shouldRepaint(covariant GlowingBackgroundPainter oldDelegate) {
    return oldDelegate.primaryGlow != primaryGlow ||
           oldDelegate.secondaryGlow != secondaryGlow ||
           oldDelegate.devicePixelRatio != devicePixelRatio;
  }
}

/// GlassContainer provides modern frosted glass styling with blur and edge highlights.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color? color;
  final double borderOpacity;
  final double borderWidth;
  final Color? glowColor;
  final double glowOpacity;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.blur = 10,
    this.color,
    this.borderOpacity = 0.08,
    this.borderWidth = 1.0,
    this.glowColor,
    this.glowOpacity = 0.0,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.current;
    final activeColor = color ?? theme.cardBg.withValues(alpha: theme.isLight ? 0.85 : 0.55);

    return Container(
      margin: margin,
      width: width,
      height: height,
      alignment: alignment,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: theme.isLight
                ? Colors.black.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            spreadRadius: -4,
            offset: const Offset(0, 10),
          ),
          if (glowColor != null && glowOpacity > 0.0)
            BoxShadow(
              color: glowColor!.withValues(alpha: glowOpacity),
              blurRadius: 16,
              spreadRadius: 1,
              offset: Offset.zero,
            ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: activeColor,
              border: Border.all(
                color: (theme.isLight ? Colors.black : Colors.white).withValues(alpha: borderOpacity),
                width: borderWidth,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  (theme.isLight ? Colors.black : Colors.white).withValues(alpha: 0.04),
                  (theme.isLight ? Colors.black : Colors.white).withValues(alpha: 0.0),
                ],
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
