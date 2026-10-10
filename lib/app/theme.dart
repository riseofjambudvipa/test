import 'package:flutter/material.dart';
import 'theme_palettes.dart';

export 'theme_palettes.dart';
export '../core/widgets/glass_container.dart';

class AppThemeData {
  final ThemeType activeThemeType;
  final ThemePalette activePalette;
  final bool isDark;
  final Color background;
  final Color cardBg;
  final Color cardBgElevated;
  final Color surfaceDim;
  final Color borderGlass;
  final Color dividerColor;
  final Color hoverBg;
  final Color primaryText;
  final Color secondaryText;
  final Color mutedText;
  final Color accentPrimary;
  final Color accentSecondary;
  final Color accentTertiary;
  final Color accentQuaternary;
  final Color onAccentText;

  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 20;
  static const double space2xl = 24;
  static const double space3xl = 32;

  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;

  const AppThemeData({
    required this.activeThemeType,
    required this.activePalette,
    required this.isDark,
    required this.background,
    required this.cardBg,
    required this.cardBgElevated,
    required this.surfaceDim,
    required this.borderGlass,
    required this.dividerColor,
    required this.hoverBg,
    required this.primaryText,
    required this.secondaryText,
    required this.mutedText,
    required this.accentPrimary,
    required this.accentSecondary,
    required this.accentTertiary,
    required this.accentQuaternary,
    this.onAccentText = Colors.white,
  });

  Color get accentOrange => accentPrimary;
  Color get accentCyan => accentSecondary;
  Color get accentPink => accentTertiary;
  Color get accentGreen => accentQuaternary;
  Color get accentLime => accentQuaternary;
  Color get iconMuted => mutedText;
  Color get textSubtle => secondaryText;
  bool get isLight => !isDark;

  static AppThemeData getTheme(ThemeType type) {
    if (type == ThemeType.cleanLight) {
      return getThemeFor(palette: ThemePalette.obsidianAmber, isDark: false);
    }
    return getThemeFor(palette: type.palette, isDark: true);
  }

  static AppThemeData getThemeFor({
    required ThemePalette palette,
    required bool isDark,
  }) {
    final type = palette.toThemeType(isDark: isDark);

    if (!isDark) {
      // ═══════════════════════════════════════════════════════════════════════
      // LIGHT MODES: High contrast Slate-50 base, pure white glass cards,
      // dark slate typography, and crisp palette-tuned vibrant accents.
      // ═══════════════════════════════════════════════════════════════════════
      switch (palette) {
        case ThemePalette.obsidianAmber:
          return AppThemeData(
            activeThemeType: type,
            activePalette: palette,
            isDark: false,
            background: const Color(0xFFFFFBF7),
            cardBg: const Color(0xFFFFFFFF),
            cardBgElevated: const Color(0xFFFFF4EC),
            surfaceDim: const Color(0xFFF3ECE5),
            borderGlass: const Color(0x22EA580C),
            dividerColor: const Color(0x18EA580C),
            hoverBg: const Color(0x0CEA580C),
            primaryText: const Color(0xFF1C1917),
            secondaryText: const Color(0xFF44403C),
            mutedText: const Color(0xFF78716C),
            accentPrimary: const Color(0xFFEA580C),
            accentSecondary: const Color(0xFF0284C7),
            accentTertiary: const Color(0xFFDB2777),
            accentQuaternary: const Color(0xFF16A34A),
            onAccentText: Colors.white,
          );
        case ThemePalette.neonCyberpunk:
          return AppThemeData(
            activeThemeType: type,
            activePalette: palette,
            isDark: false,
            background: const Color(0xFFFDF9FF),
            cardBg: const Color(0xFFFFFFFF),
            cardBgElevated: const Color(0xFFF8EFFE),
            surfaceDim: const Color(0xFFECE1F5),
            borderGlass: const Color(0x24DB2777),
            dividerColor: const Color(0x18DB2777),
            hoverBg: const Color(0x0CDB2777),
            primaryText: const Color(0xFF180E29),
            secondaryText: const Color(0xFF402E5C),
            mutedText: const Color(0xFF766396),
            accentPrimary: const Color(0xFFDB2777),
            accentSecondary: const Color(0xFF0891B2),
            accentTertiary: const Color(0xFFC026D3),
            accentQuaternary: const Color(0xFF059669),
            onAccentText: Colors.white,
          );
        case ThemePalette.obsidianEmerald:
          return AppThemeData(
            activeThemeType: type,
            activePalette: palette,
            isDark: false,
            background: const Color(0xFFF6FBF8),
            cardBg: const Color(0xFFFFFFFF),
            cardBgElevated: const Color(0xFFEDF8F2),
            surfaceDim: const Color(0xFFDFEFE6),
            borderGlass: const Color(0x24059669),
            dividerColor: const Color(0x18059669),
            hoverBg: const Color(0x0C059669),
            primaryText: const Color(0xFF0B1F17),
            secondaryText: const Color(0xFF2B473C),
            mutedText: const Color(0xFF5A7C6E),
            accentPrimary: const Color(0xFF059669),
            accentSecondary: const Color(0xFF0D9488),
            accentTertiary: const Color(0xFFDB2777),
            accentQuaternary: const Color(0xFF16A34A),
            onAccentText: Colors.white,
          );
        case ThemePalette.royalAmethyst:
          return AppThemeData(
            activeThemeType: type,
            activePalette: palette,
            isDark: false,
            background: const Color(0xFFFAF8FE),
            cardBg: const Color(0xFFFFFFFF),
            cardBgElevated: const Color(0xFFF4EEFC),
            surfaceDim: const Color(0xFFE9DEF6),
            borderGlass: const Color(0x247C3AED),
            dividerColor: const Color(0x187C3AED),
            hoverBg: const Color(0x0C7C3AED),
            primaryText: const Color(0xFF160F2E),
            secondaryText: const Color(0xFF3E3161),
            mutedText: const Color(0xFF706197),
            accentPrimary: const Color(0xFF7C3AED),
            accentSecondary: const Color(0xFFC026D3),
            accentTertiary: const Color(0xFF9333EA),
            accentQuaternary: const Color(0xFF059669),
            onAccentText: Colors.white,
          );
        case ThemePalette.sunsetSunrise:
          return AppThemeData(
            activeThemeType: type,
            activePalette: palette,
            isDark: false,
            background: const Color(0xFFFFF8F6),
            cardBg: const Color(0xFFFFFFFF),
            cardBgElevated: const Color(0xFFFFEEEA),
            surfaceDim: const Color(0xFFFCE1DB),
            borderGlass: const Color(0x24E11D48),
            dividerColor: const Color(0x18E11D48),
            hoverBg: const Color(0x0CE11D48),
            primaryText: const Color(0xFF23120E),
            secondaryText: const Color(0xFF563630),
            mutedText: const Color(0xFF8E6B64),
            accentPrimary: const Color(0xFFEA580C),
            accentSecondary: const Color(0xFFE11D48),
            accentTertiary: const Color(0xFFF43F5E),
            accentQuaternary: const Color(0xFF16A34A),
            onAccentText: Colors.white,
          );
        case ThemePalette.midnightSapphire:
          return AppThemeData(
            activeThemeType: type,
            activePalette: palette,
            isDark: false,
            background: const Color(0xFFF6F9FD),
            cardBg: const Color(0xFFFFFFFF),
            cardBgElevated: const Color(0xFFEEF4FC),
            surfaceDim: const Color(0xFFE2ECF8),
            borderGlass: const Color(0x240284C7),
            dividerColor: const Color(0x180284C7),
            hoverBg: const Color(0x0C0284C7),
            primaryText: const Color(0xFF0F172A),
            secondaryText: const Color(0xFF334155),
            mutedText: const Color(0xFF64748B),
            accentPrimary: const Color(0xFF0284C7),
            accentSecondary: const Color(0xFF2563EB),
            accentTertiary: const Color(0xFF06B6D4),
            accentQuaternary: const Color(0xFF10B981),
            onAccentText: Colors.white,
          );
      }
    }

    // ═══════════════════════════════════════════════════════════════════════
    // DARK MODES: Deep Obsidian / Midnight bases, dark glass cards,
    // luminous typography, and glowing vibrant palette accents.
    // ═══════════════════════════════════════════════════════════════════════
    switch (palette) {
      case ThemePalette.obsidianAmber:
        return AppThemeData(
          activeThemeType: type,
          activePalette: palette,
          isDark: true,
          background: const Color(0xFF09090B),
          cardBg: const Color(0xFF18181B),
          cardBgElevated: const Color(0xFF27272A),
          surfaceDim: const Color(0xFF000000),
          borderGlass: const Color(0x22FFFFFF),
          dividerColor: const Color(0x1AFFFFFF),
          hoverBg: const Color(0x0FFFFFFF),
          primaryText: const Color(0xFFFAFAFA),
          secondaryText: const Color(0xFFD4D4D8),
          mutedText: const Color(0xFFA1A1AA),
          accentPrimary: const Color(0xFFF97316),
          accentSecondary: const Color(0xFF06B6D4),
          accentTertiary: const Color(0xFFEC4899),
          accentQuaternary: const Color(0xFF22C55E),
          onAccentText: Colors.white,
        );
      case ThemePalette.neonCyberpunk:
        return AppThemeData(
          activeThemeType: type,
          activePalette: palette,
          isDark: true,
          background: const Color(0xFF0A0712),
          cardBg: const Color(0xFF130F20),
          cardBgElevated: const Color(0xFF1D1732),
          surfaceDim: const Color(0xFF050309),
          borderGlass: const Color(0x22EC4899),
          dividerColor: const Color(0x1AEC4899),
          hoverBg: const Color(0x0FEC4899),
          primaryText: const Color(0xFFFDF8FF),
          secondaryText: const Color(0xFFD8CCEB),
          mutedText: const Color(0xFFBCA9D3),
          accentPrimary: const Color(0xFFEC4899),
          accentSecondary: const Color(0xFF06B6D4),
          accentTertiary: const Color(0xFFD946EF),
          accentQuaternary: const Color(0xFF10B981),
          onAccentText: Colors.white,
        );
      case ThemePalette.obsidianEmerald:
        return AppThemeData(
          activeThemeType: type,
          activePalette: palette,
          isDark: true,
          background: const Color(0xFF06090A),
          cardBg: const Color(0xFF0D1214),
          cardBgElevated: const Color(0xFF161F23),
          surfaceDim: const Color(0xFF030506),
          borderGlass: const Color(0x2210B981),
          dividerColor: const Color(0x1A10B981),
          hoverBg: const Color(0x0F10B981),
          primaryText: const Color(0xFFE8FAF1),
          secondaryText: const Color(0xFFB0C9BE),
          mutedText: const Color(0xFF8EADA0),
          accentPrimary: const Color(0xFF10B981),
          accentSecondary: const Color(0xFF34D399),
          accentTertiary: const Color(0xFFEC4899),
          accentQuaternary: const Color(0xFF059669),
          onAccentText: Colors.white,
        );
      case ThemePalette.royalAmethyst:
        return AppThemeData(
          activeThemeType: type,
          activePalette: palette,
          isDark: true,
          background: const Color(0xFF06050C),
          cardBg: const Color(0xFF0F0C1E),
          cardBgElevated: const Color(0xFF191432),
          surfaceDim: const Color(0xFF030206),
          borderGlass: const Color(0x228B5CF6),
          dividerColor: const Color(0x1A8B5CF6),
          hoverBg: const Color(0x0F8B5CF6),
          primaryText: const Color(0xFFFBF8FF),
          secondaryText: const Color(0xFFD0CCEA),
          mutedText: const Color(0xFFB1ACD0),
          accentPrimary: const Color(0xFF8B5CF6),
          accentSecondary: const Color(0xFFD946EF),
          accentTertiary: const Color(0xFFC084FC),
          accentQuaternary: const Color(0xFF10B981),
          onAccentText: Colors.white,
        );
      case ThemePalette.sunsetSunrise:
        return AppThemeData(
          activeThemeType: type,
          activePalette: palette,
          isDark: true,
          background: const Color(0xFF0B0908),
          cardBg: const Color(0xFF15100E),
          cardBgElevated: const Color(0xFF231A17),
          surfaceDim: const Color(0xFF050404),
          borderGlass: const Color(0x22F97316),
          dividerColor: const Color(0x1AF97316),
          hoverBg: const Color(0x0FF97316),
          primaryText: const Color(0xFFFFF7F5),
          secondaryText: const Color(0xFFE8D5D1),
          mutedText: const Color(0xFFD1B6B0),
          accentPrimary: const Color(0xFFF97316),
          accentSecondary: const Color(0xFFF43F5E),
          accentTertiary: const Color(0xFFFB7185),
          accentQuaternary: const Color(0xFF22C55E),
          onAccentText: Colors.white,
        );
      case ThemePalette.midnightSapphire:
        return AppThemeData(
          activeThemeType: type,
          activePalette: palette,
          isDark: true,
          background: const Color(0xFF070B14),
          cardBg: const Color(0xFF0E1626),
          cardBgElevated: const Color(0xFF16233B),
          surfaceDim: const Color(0xFF04060B),
          borderGlass: const Color(0x2438BDF8),
          dividerColor: const Color(0x1A38BDF8),
          hoverBg: const Color(0x0F38BDF8),
          primaryText: const Color(0xFFF0F6FC),
          secondaryText: const Color(0xFFCBD5E1),
          mutedText: const Color(0xFF94A3B8),
          accentPrimary: const Color(0xFF38BDF8),
          accentSecondary: const Color(0xFF3B82F6),
          accentTertiary: const Color(0xFF06B6D4),
          accentQuaternary: const Color(0xFF34D399),
          onAccentText: Colors.white,
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
    final activeColor = color ?? cardBg.withValues(alpha: isLight ? 0.85 : 0.5);
    return BoxDecoration(
      color: showGradient ? null : activeColor,
      gradient: showGradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                activeColor,
                activeColor.withValues(
                  alpha: isLight
                      ? (activeColor.a * 0.8).clamp(0.0, 1.0)
                      : (activeColor.a * 0.4).clamp(0.0, 1.0),
                ),
              ],
            )
          : null,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: (isLight ? Colors.black : Colors.white).withValues(alpha: borderOpacity),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: isLight
              ? Colors.black.withValues(alpha: 0.04)
              : Colors.black.withValues(alpha: 0.25),
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

  ThemeData get theme {
    if (isLight) {
      final baseTheme = ThemeData.light(useMaterial3: true);
      return ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: background,
        primaryColor: accentPrimary,
        colorScheme: ColorScheme.light(
          primary: accentPrimary,
          secondary: accentSecondary,
          surface: cardBg,
          onSurface: primaryText,
          error: const Color(0xFFEF4444),
        ),
        dividerColor: dividerColor,
        dividerTheme: DividerThemeData(
          color: dividerColor,
          space: 1,
          thickness: 1,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: cardBg,
          surfaceTintColor: Colors.transparent,
          textStyle: TextStyle(
            fontFamily: 'Outfit',
            fontFamilyFallback: fontFallbacks,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: primaryText,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderGlass),
          ),
        ),
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: cardBgElevated,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: borderGlass),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          textStyle: TextStyle(
            fontFamily: 'Outfit',
            fontFamilyFallback: fontFallbacks,
            fontSize: 11,
            color: primaryText,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: cardBgElevated,
          contentTextStyle: TextStyle(
            fontFamily: 'Outfit',
            fontFamilyFallback: fontFallbacks,
            fontSize: 12,
            color: primaryText,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: borderGlass),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accentPrimary,
            foregroundColor: onAccentText,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryText,
            side: BorderSide(color: borderGlass),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            textStyle: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: secondaryText,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            textStyle: const TextStyle(
              fontFamily: 'Outfit',
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
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
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.15)),
          thickness: WidgetStateProperty.all(6),
          radius: const Radius.circular(3),
        ),
      );
    }

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
        error: const Color(0xFFEF4444),
      ),
      dividerColor: dividerColor,
      dividerTheme: DividerThemeData(
        color: dividerColor,
        space: 1,
        thickness: 1,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardBg,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(
          fontFamily: 'Outfit',
          fontFamilyFallback: fontFallbacks,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: primaryText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderGlass),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: cardBgElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: borderGlass),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        textStyle: TextStyle(
          fontFamily: 'Outfit',
          fontFamilyFallback: fontFallbacks,
          fontSize: 11,
          color: primaryText,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardBgElevated,
        contentTextStyle: TextStyle(
          fontFamily: 'Outfit',
          fontFamilyFallback: fontFallbacks,
          fontSize: 12,
          color: primaryText,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: borderGlass),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentPrimary,
          foregroundColor: onAccentText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryText,
          side: BorderSide(color: borderGlass),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: secondaryText,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(
            fontFamily: 'Outfit',
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
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
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.15)),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
      ),
    );
  }

  ThemeData get darkTheme => theme;
}

class AppTheme {
  AppTheme._();

  static AppThemeData _current = AppThemeData.getTheme(ThemeType.obsidianAmber);

  static AppThemeData get current => _current;

  static ThemeType get activeThemeType => _current.activeThemeType;
  static ThemePalette get activePalette => _current.activePalette;
  static bool get isDark => _current.isDark;
  static bool get isLight => _current.isLight;

  // Static getters for clean backwards compatibility
  static Color get background => _current.background;
  static Color get cardBg => _current.cardBg;
  static Color get cardBgElevated => _current.cardBgElevated;
  static Color get surfaceDim => _current.surfaceDim;
  static Color get borderGlass => _current.borderGlass;
  static Color get dividerColor => _current.dividerColor;
  static Color get hoverBg => _current.hoverBg;
  static Color get primaryText => _current.primaryText;
  static Color get secondaryText => _current.secondaryText;
  static Color get mutedText => _current.mutedText;
  static Color get accentPrimary => _current.accentPrimary;
  static Color get accentSecondary => _current.accentSecondary;
  static Color get accentTertiary => _current.accentTertiary;
  static Color get accentQuaternary => _current.accentQuaternary;
  static Color get accentLime => _current.accentLime;
  static Color get onAccentText => _current.onAccentText;

  static double get spaceSm => AppThemeData.spaceSm;
  static double get spaceMd => AppThemeData.spaceMd;
  static double get spaceLg => AppThemeData.spaceLg;
  static double get spaceXl => AppThemeData.spaceXl;
  static double get space2xl => AppThemeData.space2xl;
  static double get space3xl => AppThemeData.space3xl;

  static double get radiusSm => AppThemeData.radiusSm;
  static double get radiusMd => AppThemeData.radiusMd;
  static double get radiusLg => AppThemeData.radiusLg;
  static double get radiusXl => AppThemeData.radiusXl;
  
  // Legacy color getters mapped to correct semantic tokens
  static Color get accentOrange => _current.accentPrimary;
  static Color get accentCyan => _current.accentSecondary;
  static Color get accentPink => _current.accentTertiary;
  static Color get accentGreen => _current.accentQuaternary;
  static Color get accentRed => const Color(0xFFEF4444);
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
        inactiveTrackColor: isLight ? Colors.black12 : Colors.white12,
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

  static void applyDualTheme({
    required ThemePalette palette,
    required bool isDark,
  }) {
    _current = AppThemeData.getThemeFor(palette: palette, isDark: isDark);
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

  static ThemeData get theme => _current.theme;
  static ThemeData get darkTheme => _current.darkTheme;
}
