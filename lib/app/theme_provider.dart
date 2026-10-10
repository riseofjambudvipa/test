import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import '../core/settings/settings_service.dart';

class ThemeNotifier extends StateNotifier<AppThemeData> {
  ThemeNotifier() : super(AppThemeData.getTheme(ThemeType.obsidianAmber)) {
    String storedPalette = 'obsidianAmber';
    bool storedIsDark = true;
    try {
      storedIsDark = SettingsService.instance.isDarkMode;
      storedPalette = SettingsService.instance.appThemePalette;
    } catch (_) {
      // Expected during early boot before SettingsService.init completes
    }

    final palette = ThemePalette.values.firstWhere(
      (e) => e.name == storedPalette,
      orElse: () => ThemePalette.obsidianAmber,
    );
    final themeData = AppThemeData.getThemeFor(
      palette: palette,
      isDark: storedIsDark,
    );
    state = themeData;
    AppTheme.update(themeData);
  }

  void setTheme(ThemeType type) {
    if (type == ThemeType.cleanLight) {
      setDualTheme(palette: ThemePalette.obsidianAmber, isDark: false);
      return;
    }
    setDualTheme(palette: type.palette, isDark: true);
  }

  void setPalette(ThemePalette palette) {
    setDualTheme(palette: palette, isDark: state.isDark);
  }

  void setDarkMode(bool isDark) {
    setDualTheme(palette: state.activePalette, isDark: isDark);
  }

  void toggleBrightness() {
    setDualTheme(palette: state.activePalette, isDark: !state.isDark);
  }

  void setDualTheme({required ThemePalette palette, required bool isDark}) {
    final themeData = AppThemeData.getThemeFor(palette: palette, isDark: isDark);
    state = themeData;
    AppTheme.update(themeData);

    try {
      SettingsService.instance.setDarkMode(isDark);
      SettingsService.instance.setAppThemePalette(palette.name);
      SettingsService.instance.setAppTheme(
        isDark ? palette.name : 'cleanLight',
      );
    } catch (_) {}
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeData>((ref) {
  return ThemeNotifier();
});
