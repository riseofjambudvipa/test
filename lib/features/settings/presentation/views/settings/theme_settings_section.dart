import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme.dart';
import '../../../../../app/theme_provider.dart';

class ThemeSettingsSection extends ConsumerWidget {
  const ThemeSettingsSection({super.key});

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.accentOrange),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryText,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeProvider);
    final activePalette = themeData.activePalette;
    final isDark = themeData.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Visual Theme & Appearance', Icons.palette_outlined),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.cardBg,
            borderRadius: 12,
            borderOpacity: 0.08,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customize your appearance with Light or Dark mode, paired with vibrant studio glass color palettes.',
                style: TextStyle(fontSize: 12, color: AppTheme.mutedText, height: 1.4),
              ),
              const SizedBox(height: 16),

              // ─── Mode Switcher (Light / Dark) ──────────────────────────────
              Text(
                'APPEARANCE MODE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.secondaryText,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (!isDark) return;
                        ref.read(themeProvider.notifier).setDarkMode(false);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: AppTheme.glassDecoration(
                          color: !isDark
                              ? AppTheme.accentPrimary.withValues(alpha: 0.15)
                              : AppTheme.cardBgElevated,
                          borderRadius: 8,
                          borderOpacity: !isDark ? 0.35 : 0.06,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.wb_sunny_rounded,
                              size: 16,
                              color: !isDark ? AppTheme.accentPrimary : AppTheme.mutedText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Light Studio',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: !isDark ? AppTheme.primaryText : AppTheme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        if (isDark) return;
                        ref.read(themeProvider.notifier).setDarkMode(true);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: AppTheme.glassDecoration(
                          color: isDark
                              ? AppTheme.accentPrimary.withValues(alpha: 0.15)
                              : AppTheme.cardBgElevated,
                          borderRadius: 8,
                          borderOpacity: isDark ? 0.35 : 0.06,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.nightlight_round,
                              size: 16,
                              color: isDark ? AppTheme.accentPrimary : AppTheme.mutedText,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Dark Studio',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppTheme.primaryText : AppTheme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ─── 6 Color Palettes ──────────────────────────────────────────
              Text(
                'STUDIO COLOR PALETTES',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.secondaryText,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  // Desktop / Tablet (>= 480px): balanced 3x2 grid. Mobile (< 480px): balanced 2x3 grid.
                  final crossAxisCount = width >= 480 ? 3 : 2;

                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ThemePalette.values.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      mainAxisExtent: 44, // Uniform fixed height prevents any jumping or vertical misalignments
                    ),
                    itemBuilder: (context, index) {
                      final p = ThemePalette.values[index];
                      final isSelected = activePalette == p;
                      final paletteData = AppThemeData.getThemeFor(palette: p, isDark: isDark);
                      final accent = paletteData.accentPrimary;
                      final secAccent = paletteData.accentSecondary;

                      return InkWell(
                        onTap: () {
                          ref.read(themeProvider.notifier).setPalette(p);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: AppTheme.glassDecoration(
                            color: isSelected
                                ? accent.withValues(alpha: 0.16)
                                : (AppTheme.isLight
                                    ? Colors.black.withValues(alpha: 0.03)
                                    : AppTheme.cardBgElevated),
                            borderRadius: 10,
                            borderOpacity: isSelected ? 0.4 : 0.08,
                            glowColor: isSelected ? accent : null,
                            glowOpacity: isSelected ? 0.1 : 0.0,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [accent, secAccent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected
                                        ? (isDark ? AppTheme.primaryText : accent)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.displayName,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? AppTheme.primaryText : AppTheme.secondaryText,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              // Fixed checkmark with animated opacity preserves layout width
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 150),
                                opacity: isSelected ? 1.0 : 0.0,
                                child: Icon(Icons.check_circle_rounded, size: 14, color: accent),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        Divider(color: AppTheme.dividerColor, height: 40),
      ],
    );
  }
}
