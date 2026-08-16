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
  String _appVersion = '0.1.0';
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
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          _appVersion = '${packageInfo.version}+${packageInfo.buildNumber}';
        });
      }
    } catch (_) {}
  }

  Future<void> _resetToDefaults() async {
    final l10n = AppLocalizations.of(context)!;
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
              l10n.systemReset,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Are you sure you want to clear all configurations and restore defaults?',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(l10n.btnCancel, style: const TextStyle(color: Colors.white70)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(l10n.systemReset, style: const TextStyle(color: Colors.redAccent)),
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
      
      if (!mounted) return;
      ref.read(themeProvider.notifier).setTheme(ThemeType.obsidianAmber);
      
      setState(() {
        _resetKey++;
      });
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings restored to defaults.')),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompactWidth = MediaQuery.of(context).size.width < 600;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.cardBg.withValues(alpha: 0.8),
        title: Text(
          l10n.settingsTitle.toUpperCase(),
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
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
            padding: EdgeInsets.all(isCompactWidth ? 12.0 : 24.0),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                padding: EdgeInsets.all(isCompactWidth ? 12.0 : 24.0),
                decoration: AppTheme.glassDecoration(
                  color: AppTheme.cardBg.withValues(alpha: 0.5),
                  borderRadius: 12,
                  borderOpacity: 0.08,
                ),
                child: Column(
                  key: ValueKey(_resetKey),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🌐 SECTION: APP UI LANGUAGE
                    _buildSectionHeader('🌐 ${l10n.settingsLanguage}'),
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
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                            isExpanded: true,
                            menuMaxHeight: 320,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.03),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: Colors.white10),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'system', child: Text('System Default (System)')),
                              DropdownMenuItem(value: 'en', child: Text('English (English)')),
                              DropdownMenuItem(value: 'es', child: Text('Español (Spanish)')),
                              DropdownMenuItem(value: 'zh', child: Text('简体中文 (Chinese)')),
                              DropdownMenuItem(value: 'ja', child: Text('日本語 (Japanese)')),
                              DropdownMenuItem(value: 'ko', child: Text('한국어 (Korean)')),
                              DropdownMenuItem(value: 'hi', child: Text('हिन्दी (Hindi)')),
                              DropdownMenuItem(value: 'ar', child: Text('العربية (Arabic) - RTL')),
                              DropdownMenuItem(value: 'pt', child: Text('Português (Portuguese)')),
                              DropdownMenuItem(value: 'fr', child: Text('Français (French)')),
                              DropdownMenuItem(value: 'de', child: Text('Deutsch (German)')),
                              DropdownMenuItem(value: 'ru', child: Text('Русский (Russian)')),
                              DropdownMenuItem(value: 'tr', child: Text('Türkçe (Turkish)')),
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

                    const Divider(color: Colors.white10, height: 40),

                    const GeneralSettingsSection(),
                    const TranscriptionSettingsSection(),
                    const ExportSettingsSection(),

                    // 📦 SECTION: STORAGE & EMOJI PACKS
                    _buildSectionHeader('📦 ${l10n.settingsEmojiPacks}'),
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
                            l10n.settingsEmojiPacksDesc,
                            style: const TextStyle(fontSize: 12, color: Colors.white54, height: 1.4),
                          ),
                          const Divider(color: Colors.white10, height: 24),
                          Text(
                            l10n.settingsEmojiSearchLang.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white70,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Locale dropdown is fully data-driven — populated from
                          // assets/emojis/locales_manifest.json, which is generated
                          // by tools/generate_emoji_data.py.  No codes are hardcoded here.
                          if (!_localesLoaded)
                            const SizedBox(
                              height: 40,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white38,
                                  ),
                                ),
                              ),
                            )
                          else
                            DropdownButtonFormField<String>(
                              dropdownColor: AppTheme.cardBg,
                              initialValue:
                                  SettingsService.instance.emojiSearchLanguage,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13),
                              isExpanded: true,
                              menuMaxHeight: 320,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor:
                                    Colors.white.withValues(alpha: 0.03),
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Colors.white10),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide:
                                      const BorderSide(color: Colors.white10),
                                ),
                              ),
                              items: _locales
                                  .map(
                                    (locale) => DropdownMenuItem<String>(
                                      value: locale['code'],
                                      child: Text(
                                        locale['name']!,
                                        overflow: TextOverflow.ellipsis,
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
                                l10n.settingsBtnManagePacks,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentOrange,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                elevation: 0,
                              ),
                              onPressed: () => context.push('/settings/packs'),
                            ),
                          ),
                        ],
                      ),
                    ),



                    const Divider(color: Colors.white10, height: 40),

                    const ThemeSettingsSection(),

                    // ℹ️ SECTION: SYSTEM & ABOUT
                    _buildSectionHeader('ℹ️ ${l10n.systemTitle}'),
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
                                      '${l10n.systemVersion} $_appVersion',
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
                                icon: const Icon(Icons.refresh, size: 14, color: Colors.redAccent),
                                label: Text(
                                  l10n.systemReset,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          const Divider(color: Colors.white10, height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.info_outline, size: 18),
                              label: Text(
                                l10n.aboutApp.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent.withValues(alpha: 0.12),
                                foregroundColor: Colors.redAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.25)),
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
