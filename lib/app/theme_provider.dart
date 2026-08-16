import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme.dart';
import '../core/settings/settings_service.dart';

class ThemeNotifier extends StateNotifier<AppThemeData> {
  ThemeNotifier() : super(AppThemeData.getTheme(ThemeType.obsidianAmber)) {
    final stored = SettingsService.instance.appTheme;
    final type = ThemeType.values.firstWhere(
      (e) => e.name == stored,
      orElse: () => ThemeType.obsidianAmber,
    );
    final themeData = AppThemeData.getTheme(type);
    state = themeData;
    AppTheme.update(themeData);
  }

  void setTheme(ThemeType type) {
    final themeData = AppThemeData.getTheme(type);
    state = themeData;
    AppTheme.update(themeData);
    SettingsService.instance.setAppTheme(type.name);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeData>((ref) {
  return ThemeNotifier();
});
