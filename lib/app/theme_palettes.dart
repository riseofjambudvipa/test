/// The 6 core color palettes of CapStudio.
/// Each palette is available in BOTH Light and Dark modes.
enum ThemePalette {
  obsidianAmber,   // Classic Premium Amber / Orange
  neonCyberpunk,   // Midnight Cyber Cyan & Hot Pink
  obsidianEmerald, // Emerald Green & Mint
  royalAmethyst,   // Royal Violet, Purple & Lavender
  sunsetSunrise,   // Sunburn Coral & Sunset Rose
  midnightSapphire; // Deep Cobalt, Electric Sapphire & Ice Blue

  String get displayName {
    switch (this) {
      case ThemePalette.obsidianAmber:
        return 'Obsidian Amber';
      case ThemePalette.neonCyberpunk:
        return 'Neon Cyberpunk';
      case ThemePalette.obsidianEmerald:
        return 'Obsidian Emerald';
      case ThemePalette.royalAmethyst:
        return 'Royal Amethyst';
      case ThemePalette.sunsetSunrise:
        return 'Sunset Sunrise';
      case ThemePalette.midnightSapphire:
        return 'Midnight Sapphire';
    }
  }

  ThemeType toThemeType({required bool isDark}) {
    if (!isDark && this == ThemePalette.obsidianAmber) {
      return ThemeType.cleanLight;
    }
    switch (this) {
      case ThemePalette.obsidianAmber:
        return ThemeType.obsidianAmber;
      case ThemePalette.neonCyberpunk:
        return ThemeType.neonCyberpunk;
      case ThemePalette.obsidianEmerald:
        return ThemeType.obsidianEmerald;
      case ThemePalette.royalAmethyst:
        return ThemeType.royalAmethyst;
      case ThemePalette.sunsetSunrise:
        return ThemeType.sunsetSunrise;
      case ThemePalette.midnightSapphire:
        return ThemeType.midnightSapphire;
    }
  }
}

/// Backwards-compatible ThemeType enum.
enum ThemeType {
  cleanLight,      // Obsidian Amber in Light Mode
  obsidianAmber,   // Deep Zinc-950 base with glowing Amber/Orange
  neonCyberpunk,   // Midnight purple base with Hot Pink & Cyber Cyan
  obsidianEmerald, // Slate black base with Mint Emerald Green
  royalAmethyst,   // Deep Royal Indigo base with glowing Purple/Lavender
  sunsetSunrise,   // Rich Charcoal base with glowing Coral Sunset Orange
  midnightSapphire; // Deep Navy/Cobalt base with Electric Sapphire

  String get displayName {
    switch (this) {
      case ThemeType.cleanLight:
        return 'Clean Studio Light';
      case ThemeType.obsidianAmber:
        return 'Obsidian Amber';
      case ThemeType.neonCyberpunk:
        return 'Neon Cyberpunk';
      case ThemeType.obsidianEmerald:
        return 'Obsidian Emerald';
      case ThemeType.royalAmethyst:
        return 'Royal Amethyst';
      case ThemeType.sunsetSunrise:
        return 'Sunset Sunrise';
      case ThemeType.midnightSapphire:
        return 'Midnight Sapphire';
    }
  }

  ThemePalette get palette {
    switch (this) {
      case ThemeType.cleanLight:
      case ThemeType.obsidianAmber:
        return ThemePalette.obsidianAmber;
      case ThemeType.neonCyberpunk:
        return ThemePalette.neonCyberpunk;
      case ThemeType.obsidianEmerald:
        return ThemePalette.obsidianEmerald;
      case ThemeType.royalAmethyst:
        return ThemePalette.royalAmethyst;
      case ThemeType.sunsetSunrise:
        return ThemePalette.sunsetSunrise;
      case ThemeType.midnightSapphire:
        return ThemePalette.midnightSapphire;
    }
  }

  bool get isLightMode => this == ThemeType.cleanLight;
}
