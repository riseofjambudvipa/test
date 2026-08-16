import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme.dart';
import '../../../../../app/theme_provider.dart';

class ThemeSettingsSection extends ConsumerWidget {
  const ThemeSettingsSection({super.key});

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 1.0,
      ),
    );
  }

  Color _getThemeAccentColor(ThemeType type) {
    return AppThemeData.getTheme(type).accentPrimary;
  }

  String _getThemeName(ThemeType type) {
    switch (type) {
      case ThemeType.obsidianAmber:
        return 'Obsidian Amber';
      case ThemeType.neonCyberpunk:
        return 'Neon Cyberpunk';
      case ThemeType.obsidianEmerald:
        return 'Obsidian Emerald';
      case ThemeType.royalAmethyst:
        return 'Royal Amethyst';
      case ThemeType.sunsetSunrise:
        return 'Sunset Charcoal';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider).activeThemeType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('🎨 Global Theme Presets'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ThemeType.values.map((t) {
            final isSelected = currentTheme == t;
            return GestureDetector(
              onTap: () {
                ref.read(themeProvider.notifier).setTheme(t);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: AppTheme.glassDecoration(
                  color: isSelected ? _getThemeAccentColor(t).withValues(alpha: 0.15) : AppTheme.cardBg.withValues(alpha: 0.25),
                  borderRadius: 20,
                  borderOpacity: isSelected ? 0.3 : 0.06,
                  glowColor: isSelected ? _getThemeAccentColor(t) : null,
                  glowOpacity: isSelected ? 0.08 : 0.0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _getThemeAccentColor(t),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getThemeName(t),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const Divider(color: Colors.white10, height: 40),
      ],
    );
  }
}
