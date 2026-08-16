import 'dart:ui';
import 'package:flutter/material.dart';

enum ThemeType {
  obsidianAmber,   // Deep Zinc-950 base with glowing Amber/Orange (Classic Premium)
  neonCyberpunk,   // Midnight purple base with Hot Pink & Cyber Cyan
  obsidianEmerald, // Slate black base with Mint Emerald Green
  royalAmethyst,   // Deep Royal Indigo base with glowing Purple/Lavender
  sunsetSunrise,   // Rich Charcoal base with glowing Coral Sunset Orange
}

class AppThemeData {
  final ThemeType activeThemeType;
  final Color background;
  final Color cardBg;
  final Color borderGlass;
  final Color hoverBg;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color accentPrimary;
  final Color accentSecondary;
  final Color accentTertiary;
  final Color accentQuaternary;

  const AppThemeData({
    required this.activeThemeType,
    required this.background,
    required this.cardBg,
    required this.borderGlass,
    required this.hoverBg,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.accentTertiary,
    required this.accentQuaternary,
  });

  Color get accentOrange => accentPrimary;
  Color get accentCyan => accentSecondary;
  Color get accentPink => accentTertiary;
  Color get accentGreen => accentQuaternary;
  Color get iconMuted => mutedText;
  Color get textSubtle => secondaryText;

  static AppThemeData getTheme(ThemeType type) {
    switch (type) {
      case ThemeType.obsidianAmber:
        return const AppThemeData(
          activeThemeType: ThemeType.obsidianAmber,
          background: Color(0xFF09090B),
          cardBg: Color(0xFF18181B),
          borderGlass: Color(0x1AFFFFFF),
          hoverBg: Color(0x0FFFFFFF),
          primaryText: Color(0xFFFAFAFA),
          secondaryText: Color(0xFFA1A1AA),
          mutedText: Color(0xFF71717A),
          accentPrimary: Color(0xFFF97316),
          accentSecondary: Color(0xFF06B6D4),
          accentTertiary: Color(0xFFEC4899),
          accentQuaternary: Color(0xFF22C55E),
        );
      case ThemeType.neonCyberpunk:
        return const AppThemeData(
          activeThemeType: ThemeType.neonCyberpunk,
          background: Color(0xFF0A0712),
          cardBg: Color(0xFF130F20),
          borderGlass: Color(0x1AEC4899),
          hoverBg: Color(0x0FEC4899),
          primaryText: Color(0xFFFDF8FF),
          secondaryText: Color(0xFFBCA9D3),
          mutedText: Color(0xFF86729A),
          accentPrimary: Color(0xFFEC4899), // Hot Pink
          accentSecondary: Color(0xFF06B6D4), // Cyber Cyan
          accentTertiary: Color(0xFFD946EF), // Fuchsia
          accentQuaternary: Color(0xFF10B981), // Emerald
        );
      case ThemeType.obsidianEmerald:
        return const AppThemeData(
          activeThemeType: ThemeType.obsidianEmerald,
          background: Color(0xFF06090A),
          cardBg: Color(0xFF0D1214),
          borderGlass: Color(0x1A10B981),
          hoverBg: Color(0x0F10B981),
          primaryText: Color(0xFFE8FAF1),
          secondaryText: Color(0xFF8EADA0),
          mutedText: Color(0xFF637D72),
          accentPrimary: Color(0xFF10B981), // Emerald Green
          accentSecondary: Color(0xFF34D399), // Mint
          accentTertiary: Color(0xFFEC4899),
          accentQuaternary: Color(0xFF059669),
        );
      case ThemeType.royalAmethyst:
        return const AppThemeData(
          activeThemeType: ThemeType.royalAmethyst,
          background: Color(0xFF06050C),
          cardBg: Color(0xFF0F0C1E),
          borderGlass: Color(0x1A8B5CF6),
          hoverBg: Color(0x0F8B5CF6),
          primaryText: Color(0xFFFBF8FF),
          secondaryText: Color(0xFFB1ACD0),
          mutedText: Color(0xFF7B75A0),
          accentPrimary: Color(0xFF8B5CF6), // Royal Violet
          accentSecondary: Color(0xFFD946EF), // Fuchsia
          accentTertiary: Color(0xFFC084FC),
          accentQuaternary: Color(0xFF10B981),
        );
      case ThemeType.sunsetSunrise:
        return const AppThemeData(
          activeThemeType: ThemeType.sunsetSunrise,
          background: Color(0xFF0B0908),
          cardBg: Color(0xFF15100E),
          borderGlass: Color(0x1AF97316),
          hoverBg: Color(0x0FF97316),
          primaryText: Color(0xFFFFF7F5),
          secondaryText: Color(0xFFD1B6B0),
          mutedText: Color(0xFF9E847F),
          accentPrimary: Color(0xFFF97316), // Sunburn Orange
          accentSecondary: Color(0xFFF43F5E), // Sunset Rose
          accentTertiary: Color(0xFFFB7185),
          accentQuaternary: Color(0xFF22C55E),
        );
    }
  }

  BoxDecoration glassDecoration({
    Color? color,
    double borderRadius = 20,
    double borderOpacity = 0.08,
    bool showGradient = true,
    Color? glowColor,
    double glowOpacity = 0.0,
  }) {
    final activeColor = color ?? cardBg.withValues(alpha: 0.5);
    return BoxDecoration(
      color: showGradient ? null : activeColor,
      gradient: showGradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                activeColor,
                activeColor.withValues(alpha: activeColor.a * 0.4),
              ],
            )
          : null,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withValues(alpha: borderOpacity),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 20,
          spreadRadius: -4,
          offset: const Offset(0, 10),
        ),
        if (glowColor != null && glowOpacity > 0.0)
          BoxShadow(
            color: glowColor.withValues(alpha: glowOpacity),
            blurRadius: 14,
            spreadRadius: 1,
            offset: Offset.zero,
          ),
      ],
    );
  }

  static const List<String> fontFallbacks = [
    'Noto Sans',
    'Noto Sans Devanagari',
    'Noto Sans Arabic',
    'Noto Sans Thai',
    'Noto Sans Hebrew',
    'Noto Sans Tamil',
    'Noto Sans Telugu',
    'Noto Sans Bengali',
    'Noto Sans Gujarati',
    'Noto Sans Kannada',
    'Noto Sans Malayalam',
    'Noto Sans Gurmukhi',
    'Noto Sans Oriya',
    'Noto Sans Sinhala',
    'Noto Sans Myanmar',
    'Noto Sans Khmer',
    'Noto Sans Lao',
    'Noto Sans Georgian',
    'Noto Sans Armenian',
    'Noto Sans Ethiopic',
    'Noto Nastaliq Urdu',
    'Noto Sans SC',
    'Noto Sans JP',
    'Noto Sans KR',
    'Noto Sans TC',
  ];

  ThemeData get darkTheme {
    final baseTheme = ThemeData.dark(useMaterial3: true);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: accentPrimary,
      colorScheme: ColorScheme.dark(
        primary: accentPrimary,
        secondary: accentSecondary,
        surface: cardBg,
        onSurface: primaryText,
        error: Colors.redAccent,
      ),
      
      // Default Typography Settings via Outfit + Multilingual Noto Fallbacks
      textTheme: baseTheme.textTheme.copyWith(
        headlineLarge: TextStyle(
          fontFamily: 'Outfit',
          fontFamilyFallback: fontFallbacks,
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: primaryText,
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Outfit',
          fontFamilyFallback: fontFallbacks,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryText,
        ),
        titleMedium: TextStyle(
          fontFamily: 'Outfit',
          fontFamilyFallback: fontFallbacks,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: primaryText,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Outfit',
          fontFamilyFallback: fontFallbacks,
          fontSize: 14,
          color: primaryText,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Outfit',
          fontFamilyFallback: fontFallbacks,
          fontSize: 12,
          color: secondaryText,
        ),
        labelSmall: TextStyle(
          fontFamily: 'Outfit',
          fontFamilyFallback: fontFallbacks,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: mutedText,
          letterSpacing: 1.5,
        ),
      ),
      
      // Custom Scrollbar Behavior
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.15)),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
      ),
    );
  }
}

class AppTheme {
  AppTheme._();

  static AppThemeData _current = AppThemeData.getTheme(ThemeType.obsidianAmber);

  static AppThemeData get current => _current;

  static ThemeType get activeThemeType => _current.activeThemeType;

  // Static getters for clean backwards compatibility (no warnings, clean facade)
  static Color get background => _current.background;
  static Color get cardBg => _current.cardBg;
  static Color get borderGlass => _current.borderGlass;
  static Color get hoverBg => _current.hoverBg;
  static Color get primaryText => _current.primaryText;
  static Color get secondaryText => _current.secondaryText;
  static Color get mutedText => _current.mutedText;
  static Color get accentPrimary => _current.accentPrimary;
  static Color get accentSecondary => _current.accentSecondary;
  static Color get accentTertiary => _current.accentTertiary;
  static Color get accentQuaternary => _current.accentQuaternary;
  
  // Legacy color getters mapped to correct semantic tokens
  static Color get accentOrange => _current.accentPrimary;
  static Color get accentCyan => _current.accentSecondary;
  static Color get accentPink => _current.accentTertiary;
  static Color get accentGreen => _current.accentQuaternary;
  static Color get iconMuted => _current.mutedText;
  static Color get textSubtle => _current.secondaryText;
  
  static InputBorder defaultBorder({double radius = 8}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: borderGlass, width: 1),
      );

  static InputBorder focusedBorder({double radius = 8}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(color: accentOrange, width: 1.5),
      );

  static SliderThemeData premiumSliderTheme(BuildContext context) =>
      SliderTheme.of(context).copyWith(
        trackHeight: 2,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
        activeTrackColor: accentOrange,
        inactiveTrackColor: Colors.white12,
        thumbColor: accentOrange,
        overlayColor: accentOrange.withValues(alpha: 0.15),
      );

  /// Update the current theme facade globally
  static void update(AppThemeData data) {
    _current = data;
  }

  /// Maintain applyTheme method signature for compatibility (e.g. testing)
  static void applyTheme(ThemeType type) {
    _current = AppThemeData.getTheme(type);
  }

  static BoxDecoration glassDecoration({
    Color? color,
    double borderRadius = 20,
    double borderOpacity = 0.08,
    bool showGradient = true,
    Color? glowColor,
    double glowOpacity = 0.0,
  }) {
    return _current.glassDecoration(
      color: color,
      borderRadius: borderRadius,
      borderOpacity: borderOpacity,
      showGradient: showGradient,
      glowColor: glowColor,
      glowOpacity: glowOpacity,
    );
  }

  static ThemeData get darkTheme => _current.darkTheme;
}

// ─── Glowing Ambient Background Painter ────────────────────────────────────

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

    // Glow 1: Top Right
    paint.color = primaryGlow.withValues(alpha: 0.12);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), size.width * 0.25, paint);

    // Glow 2: Bottom Left
    paint.color = secondaryGlow.withValues(alpha: 0.08);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.85), size.width * 0.3, paint);

    // Glow 3: Center Ambient
    paint.color = primaryGlow.withValues(alpha: 0.03);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), size.width * 0.2, paint);
  }

  @override
  bool shouldRepaint(covariant GlowingBackgroundPainter oldDelegate) {
    return oldDelegate.primaryGlow != primaryGlow ||
           oldDelegate.secondaryGlow != secondaryGlow ||
           oldDelegate.devicePixelRatio != devicePixelRatio;
  }
}

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
    this.blur = 16,
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
    final activeColor = color ?? theme.cardBg.withValues(alpha: 0.55);

    return Container(
      margin: margin,
      width: width,
      height: height,
      alignment: alignment,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
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
                color: Colors.white.withValues(alpha: borderOpacity),
                width: borderWidth,
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.04),
                  Colors.white.withValues(alpha: 0.0),
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
