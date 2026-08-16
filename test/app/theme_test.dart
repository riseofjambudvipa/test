import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:capstudio/app/theme.dart';
import 'package:capstudio/app/theme_provider.dart';
import 'package:capstudio/core/settings/settings_service.dart';
import 'package:capstudio/core/utils/app_dirs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('capstudio_theme_test_');
    AppDirs.setSupportPathForTesting(tempDir.path);
    await AppDirs.init();

    SharedPreferences.setMockInitialValues({
      'app_theme': 'obsidianAmber',
    });
    await SettingsService.instance.init();
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('Theme System Tests', () {
    test('AppThemeData.getTheme returns different configs for each ThemeType', () {
      for (final type in ThemeType.values) {
        final theme = AppThemeData.getTheme(type);
        expect(theme.activeThemeType, equals(type));
        expect(theme.background, isA<Color>());
        expect(theme.cardBg, isA<Color>());
        expect(theme.primaryText, isA<Color>());
        expect(theme.darkTheme, isA<ThemeData>());
        expect(theme.glassDecoration(), isA<BoxDecoration>());
      }
    });

    test('AppTheme facade updates correctly when AppTheme.applyTheme is called', () {
      AppTheme.applyTheme(ThemeType.neonCyberpunk);
      expect(AppTheme.activeThemeType, equals(ThemeType.neonCyberpunk));
      expect(AppTheme.background, equals(AppThemeData.getTheme(ThemeType.neonCyberpunk).background));

      AppTheme.applyTheme(ThemeType.obsidianEmerald);
      expect(AppTheme.activeThemeType, equals(ThemeType.obsidianEmerald));
      expect(AppTheme.background, equals(AppThemeData.getTheme(ThemeType.obsidianEmerald).background));
    });

    test('ThemeNotifier initializes from settings and updates settings when theme changes', () {
      final notifier = ThemeNotifier();
      // Should default to obsidianAmber from shared preferences setup
      expect(notifier.state.activeThemeType, equals(ThemeType.obsidianAmber));

      notifier.setTheme(ThemeType.royalAmethyst);
      expect(notifier.state.activeThemeType, equals(ThemeType.royalAmethyst));
      expect(AppTheme.activeThemeType, equals(ThemeType.royalAmethyst));
      expect(SettingsService.instance.appTheme, equals('royalAmethyst'));
    });

    test('GlowingBackgroundPainter shouldRepaint delegate returns correct values', () {
      final painter1 = GlowingBackgroundPainter(
        primaryGlow: Colors.amber,
        secondaryGlow: Colors.cyan,
        devicePixelRatio: 2.0,
      );

      final painter2 = GlowingBackgroundPainter(
        primaryGlow: Colors.amber,
        secondaryGlow: Colors.cyan,
        devicePixelRatio: 2.0,
      );

      final painterDifferentGlow = GlowingBackgroundPainter(
        primaryGlow: Colors.red,
        secondaryGlow: Colors.cyan,
        devicePixelRatio: 2.0,
      );

      expect(painter1.shouldRepaint(painter2), isFalse);
      expect(painter1.shouldRepaint(painterDifferentGlow), isTrue);
    });
  });
}
