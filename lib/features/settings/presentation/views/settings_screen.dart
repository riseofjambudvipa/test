import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../app/locale_provider.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_provider.dart';
import '../../../../core/settings/settings_service.dart';
import '../../../../core/emoji/emoji_service.dart';
import '../../../../core/logger/logger_service.dart';
import 'settings/general_settings_section.dart';
import 'settings/transcription_settings_section.dart';
import 'settings/export_settings_section.dart';
import 'settings/theme_settings_section.dart';
import '../../../../core/utils/premium_blur_dialog.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // FIX (audit, consistency): this default now matches the About screen and
  // pubspec (1.0.0) instead of claiming an unrelated 0.1.0.
  String _appVersion = '1.0.0';
  int _resetKey = 0;

  // Locales loaded from assets/emojis/locales_manifest.json.
  // No locale codes are hardcoded here — the generator owns the source of truth.
  List<Map<String, String>> _locales = [];
  bool _localesLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _loadLocales();
  }

  Future<void> _loadLocales() async {
    // FIX (audit): an unhandled throw here left _localesLoaded false and the
    // dropdown showing an infinite spinner. Fall back to just the 'auto' entry.
    try {
      final manifest = await EmojiService.loadLocalesManifest();
      if (!mounted) return;
      setState(() {
        // Prepend the special 'auto' entry
        _locales = [
          {'code': 'auto', 'name': 'Auto (System Language)'},
          ...manifest,
        ];
        _localesLoaded = true;
      });
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'SettingsScreen',
          'Failed to load emoji locales manifest: $e');
      if (!mounted) return;
      setState(() {
        _locales = [
          {'code': 'auto', 'name': 'Auto (System Language)'},
        ];
        _localesLoaded = true;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
        });
      }    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'SettingsScreen', 'Failed to load app version: $e');
    }
  }




  Future<void> _resetToDefaults() async {
    final l10n = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => PremiumBlurDialog(
        maxWidth: 400,
        glowColor: AppTheme.accentOrange,
        glowOpacity: 0.1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n?.systemReset ?? 'Reset Defaults',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to clear all configurations and restore defaults?',
              style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n?.btnCancel ?? 'CANCEL', style: TextStyle(color: AppTheme.secondaryText)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n?.systemReset ?? 'Reset Defaults', style: TextStyle(color: AppTheme.accentRed)),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      // Clear preferences
      await SettingsService.instance.setWhisperCliPath('');
      await SettingsService.instance.setFfmpegCliPath('');
      await SettingsService.instance.setOutputFolder('');
      await SettingsService.instance.setDefaultLanguage('auto');
      await SettingsService.instance.setUseVad(false);
      await SettingsService.instance.setVadThreshold(0.5);
      await SettingsService.instance.setAppTheme('obsidianAmber');
      await SettingsService.instance.setUseGpu(false);
      await SettingsService.instance.setGpuEncoder('none');
      await SettingsService.instance.setWhisperThreads(0); // 0 = auto (CPU cores − 1)
      await SettingsService.instance.setAlwaysAskExportPath(false);
      // FIX (audit): "restore defaults" previously omitted these settings, so
      // model selection, emoji/UI language and auto-save survived the reset.
      await SettingsService.instance.setEmojiSearchLanguage('auto');
      await SettingsService.instance.setUiLanguage('system');
      await SettingsService.instance.setWhisperModelPath('');
      await SettingsService.instance.setWhisperModelName('');
      await SettingsService.instance.setForceNoAvx(false);
      await SettingsService.instance.setExportThreads(0);
      await SettingsService.instance.setAutoSave(true);
      await SettingsService.instance.setLogMinimumLevel('info');
      await SettingsService.instance.setDbSchemaVersion(1);
      
      if (!mounted) return;
      ref.read(themeProvider.notifier).setTheme(ThemeType.obsidianAmber);
      
      setState(() {
        _resetKey++;
      });
      
      if (!mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.settingsRestored ?? 'Settings restored to defaults.')),
      );
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, [AppThemeData? themeData]) {
    final primaryColor = themeData?.primaryText ?? AppTheme.primaryText;
    final accentColor = themeData?.accentOrange ?? AppTheme.accentOrange;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: accentColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 2,
          width: 48,
          decoration: BoxDecoration(
            color: accentColor,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeProvider);
    final theme = Theme.of(context);
    final isCompactWidth = MediaQuery.of(context).size.width < 600;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg.withValues(alpha: 0.8),
        title: Text(
          (l10n?.settingsTitle ?? 'Settings').toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: AppTheme.primaryText,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 18, color: AppTheme.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Glowing Ambient background gradients
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: GlowingBackgroundPainter(
                  primaryGlow: AppTheme.accentOrange,
                  secondaryGlow: AppTheme.accentCyan,
                  devicePixelRatio: MediaQuery.of(context).devicePixelRatio,
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isCompactWidth ? 12.0 : 24.0,
              vertical: 20.0,
            ),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: EdgeInsets.all(isCompactWidth ? 14.0 : 24.0),
                decoration: AppTheme.glassDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: 12,
                  borderOpacity: 0.08,
                ),
                child: Column(
                  key: ValueKey(_resetKey),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION: APP UI LANGUAGE
                    _buildSectionHeader(l10n?.settingsLanguage ?? 'App UI Language', Icons.language_rounded, themeData),
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
                          DropdownButtonFormField<String>(
                            dropdownColor: AppTheme.cardBg,
                            initialValue: SettingsService.instance.uiLanguage,
                            style: TextStyle(color: AppTheme.primaryText, fontSize: 13),
                            isExpanded: true,
                            menuMaxHeight: 320,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppTheme.cardBgElevated,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppTheme.borderGlass),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: AppTheme.borderGlass),
                              ),
                            ),
                            items: [
                              DropdownMenuItem(value: 'system', child: Text('System Default (System)', style: TextStyle(color: AppTheme.primaryText))),
                              DropdownMenuItem(value: 'en', child: Text('English (English)', style: TextStyle(color: AppTheme.primaryText))),
                              DropdownMenuItem(value: 'es', child: Text('Español (Spanish)', style: TextStyle(color: AppTheme.primaryText))),
                              DropdownMenuItem(value: 'zh', child: Text('简体中文 (Chinese)', style: TextStyle(color: AppTheme.primaryText))),
                              DropdownMenuItem(value: 'ja', child: Text('日本語 (Japanese)', style: TextStyle(color: AppTheme.primaryText))),
                              DropdownMenuItem(value: 'ko', child: Text('한국어 (Korean)', style: TextStyle(color: AppTheme.primaryText))),
                              DropdownMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)', style: TextStyle(color: AppTheme.primaryText))),
                              DropdownMenuItem(value: 'ar', child: Text('العربية (Arabic) - RTL', style: TextStyle(color: AppTheme.primaryText))),
                              DropdownMenuItem(value: 'pt', child: Text('Português (Portuguese)', style: TextStyle(color: AppTheme.primaryText))),
                              DropdownMenuItem(value: 'fr', child: Text('Français (French)', style: TextStyle(color: AppTheme.primaryText))),
                              DropdownMenuItem(value: 'de', child: Text('Deutsch (German)', style: TextStyle(color: AppTheme.primaryText))),
                              DropdownMenuItem(value: 'ru', child: Text('Русский (Russian)', style: TextStyle(color: AppTheme.primaryText))),
                              DropdownMenuItem(value: 'tr', child: Text('Türkçe (Turkish)', style: TextStyle(color: AppTheme.primaryText))),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                ref.read(localeProvider.notifier).setLocale(val);
                                LoggerService.instance.log(LogLevel.action, 'Settings', 'App UI language changed to: $val');
                              }
                            },
                          ),
                        ],
                      ),
                    ),

                    Divider(color: AppTheme.borderGlass, height: 40),

                    const GeneralSettingsSection(),
                    const TranscriptionSettingsSection(),
                    const ExportSettingsSection(),

                    // SECTION: STORAGE & EMOJI PACKS
                    _buildSectionHeader(l10n?.settingsEmojiPacks ?? 'Emoji & Style Packs', Icons.emoji_emotions_outlined, themeData),
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
                            l10n?.settingsEmojiPacksDesc ?? 'Customize emoji rendering styles and active subtitle assets.',
                            style: TextStyle(fontSize: 12, color: AppTheme.mutedText, height: 1.4),
                          ),
                          Divider(color: AppTheme.borderGlass, height: 24),
                          Text(
                            (l10n?.settingsEmojiSearchLang ?? 'Emoji Search Language').toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.primaryText,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (!_localesLoaded)
                            SizedBox(
                              height: 40,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppTheme.accentOrange,
                                  ),
                                ),
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              dropdownColor: AppTheme.cardBg,
                              initialValue:
                                  _locales.any((l) =>
                                          l['code'] ==
                                          SettingsService.instance
                                              .emojiSearchLanguage)
                                      ? SettingsService.instance
                                          .emojiSearchLanguage
                                      : 'auto',
                              style: TextStyle(
                                  color: AppTheme.primaryText, fontSize: 13),
                              isExpanded: true,
                              menuMaxHeight: 320,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppTheme.cardBgElevated,
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: AppTheme.borderGlass),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      BorderSide(color: AppTheme.borderGlass),
                                ),
                              ),
                              items: _locales
                                  .map(
                                    (locale) => DropdownMenuItem<String>(
                                      value: locale['code'],
                                      child: Text(
                                        locale['name']!,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: AppTheme.primaryText),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) async {
                                if (val != null) {
                                  await SettingsService.instance
                                      .setEmojiSearchLanguage(val);
                                  await EmojiService.instance.setLanguage(
                                      EmojiService
                                          .instance.activeSearchLocale);
                                }
                              },
                            ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.download_for_offline_outlined, size: 18),
                              label: Text(
                                l10n?.settingsBtnManagePacks ?? 'MANAGE EMOJI PACKS',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentOrange,
                                foregroundColor: AppTheme.onAccentText,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              onPressed: () => context.push('/settings/packs'),
                            ),
                          ),
                        ],
                      ),
                    ),



                    Divider(color: AppTheme.dividerColor, height: 40),

                    const ThemeSettingsSection(),

                    // SECTION: SYSTEM & ABOUT
                    _buildSectionHeader(l10n?.systemTitle ?? 'System Info', Icons.info_outline_rounded, themeData),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: AppTheme.glassDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: 12,
                        borderOpacity: 0.08,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CapStudio Client',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryText,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${l10n?.systemVersion ?? 'Version'} $_appVersion',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.mutedText,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton.icon(
                                onPressed: _resetToDefaults,
                                icon: Icon(Icons.refresh, size: 14, color: AppTheme.accentRed),
                                label: Text(
                                  l10n?.systemReset ?? 'Reset Defaults',
                                  style: TextStyle(color: AppTheme.accentRed, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          Divider(color: AppTheme.borderGlass, height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: Text(
                                (l10n?.aboutApp ?? 'About CapStudio').toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.12),
                                foregroundColor: AppTheme.accentOrange,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () => context.push('/settings/about'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
