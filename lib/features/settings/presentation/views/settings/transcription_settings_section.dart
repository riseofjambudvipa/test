import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../../../app/theme.dart';
import '../../../../../app/theme_provider.dart';
import '../../../../../core/settings/settings_service.dart';
import '../../../../../core/whisper/whisper_languages.dart';
import '../../../../../core/whisper/whisper_model.dart';
import '../../../../../l10n/app_localizations.dart';

class TranscriptionSettingsSection extends ConsumerStatefulWidget {
  const TranscriptionSettingsSection({super.key});

  @override
  ConsumerState<TranscriptionSettingsSection> createState() => _TranscriptionSettingsSectionState();
}

class _TranscriptionSettingsSectionState extends ConsumerState<TranscriptionSettingsSection> {
  String _defaultLanguage = 'auto';
  bool _useVad = false;
  double _vadThreshold = 0.5;
  bool _autoSaveEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final settings = SettingsService.instance;
    _defaultLanguage = settings.defaultLanguage;
    _useVad = settings.useVad;
    _vadThreshold = settings.vadThreshold;
    _autoSaveEnabled = settings.autoSaveEnabled;
  }

  Widget _buildSectionHeader(String title, IconData icon, [AppThemeData? themeData]) {
    final primaryColor = themeData?.primaryText ?? AppTheme.primaryText;
    final accentColor = themeData?.accentOrange ?? AppTheme.accentOrange;
    return Row(
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
    );
  }

  Widget _buildLanguageWarningCard([AppThemeData? themeData]) {
    final primaryColor = themeData?.primaryText ?? AppTheme.primaryText;
    if (_defaultLanguage == 'auto') {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.accentOrange.withValues(alpha: 0.08),
            borderRadius: 8,
            borderOpacity: 0.12,
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.accentOrange, size: 16),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Tip: Auto-detect is not recommended for mixed languages (like Hinglish). '
                  'Explicitly selecting your spoken language (e.g. Hindi or English) will provide much more accurate captions.',
                  style: TextStyle(color: primaryColor, fontSize: 11, height: 1.3),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final modelName = SettingsService.instance.whisperModelName;
    final activeModel = kWhisperModels.firstWhereOrNull((m) => m.name == modelName);
    final isEnglishOnly = activeModel?.englishOnly ?? (modelName?.endsWith('.en') ?? false);
    final showWarning = _defaultLanguage != 'auto' && _defaultLanguage != 'en' && isEnglishOnly;

    if (!showWarning) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: AppTheme.glassDecoration(
          color: AppTheme.accentRed.withValues(alpha: 0.08),
          borderRadius: 8,
          borderOpacity: 0.12,
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Warning: Your active model (${activeModel?.displayName ?? modelName ?? 'English Only'}) is English-only. '
                'Transcribing in "${kWhisperLanguages.firstWhere((l) => l.code == _defaultLanguage, orElse: () => WhisperLanguage('', _defaultLanguage)).name}" will fail or produce English captions. '
                'Please download/select a Multilingual model.',
                style: TextStyle(color: AppTheme.accentRed, fontSize: 11, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeProvider);
    final isCompactWidth = MediaQuery.of(context).size.width < 600;
    final l10n = AppLocalizations.of(context);

    final dropdownDecoration = InputDecoration(
      filled: true,
      fillColor: themeData.cardBgElevated,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: themeData.borderGlass),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: themeData.borderGlass),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n?.settingsTranscription ?? 'Transcription Settings', Icons.mic_none_rounded, themeData),
        const SizedBox(height: 16),
        isCompactWidth
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.defaultLanguage ?? 'Default Language',
                    style: TextStyle(fontWeight: FontWeight.w600, color: themeData.primaryText),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    dropdownColor: themeData.cardBg,
                    style: TextStyle(color: themeData.primaryText, fontSize: 13),
                    initialValue: kWhisperLanguages.any((l) => l.code == _defaultLanguage)
                        ? _defaultLanguage
                        : 'auto',
                    decoration: dropdownDecoration,
                    items: [
                      DropdownMenuItem(
                        value: 'auto',
                        child: Text(l10n?.settingsAutoDetect ?? 'Auto Detect', style: TextStyle(color: themeData.primaryText)),
                      ),
                      ...kWhisperLanguages.map((lang) => DropdownMenuItem(
                            value: lang.code,
                            child: Text('${lang.name} (${lang.code})', style: TextStyle(color: themeData.primaryText)),
                          )),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _defaultLanguage = val);
                        SettingsService.instance.setDefaultLanguage(val);
                      }
                    },
                  ),
                  _buildLanguageWarningCard(themeData),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n?.defaultLanguage ?? 'Default Language',
                      style: TextStyle(fontWeight: FontWeight.w600, color: themeData.primaryText),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          dropdownColor: themeData.cardBg,
                          style: TextStyle(color: themeData.primaryText, fontSize: 13),
                          initialValue: kWhisperLanguages.any((l) => l.code == _defaultLanguage)
                              ? _defaultLanguage
                              : 'auto',
                          decoration: dropdownDecoration,
                          items: [
                            DropdownMenuItem(
                              value: 'auto',
                              child: Text(l10n?.settingsAutoDetect ?? 'Auto Detect', style: TextStyle(color: themeData.primaryText)),
                            ),
                            ...kWhisperLanguages.map((lang) => DropdownMenuItem(
                                  value: lang.code,
                                  child: Text('${lang.name} (${lang.code})', style: TextStyle(color: themeData.primaryText)),
                                )),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _defaultLanguage = val);
                              SettingsService.instance.setDefaultLanguage(val);
                            }
                          },
                        ),
                        _buildLanguageWarningCard(themeData),
                      ],
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.vadTitle ?? 'Voice Activity Detection (VAD)',
                    style: TextStyle(fontWeight: FontWeight.w600, color: themeData.primaryText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n?.vadDesc ?? 'Skips silent regions during processing',
                    style: TextStyle(fontSize: 11, color: themeData.mutedText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _useVad,
              activeThumbColor: themeData.accentOrange,
              onChanged: (val) {
                setState(() => _useVad = val);
                SettingsService.instance.setUseVad(val);
              },
            ),
          ],
        ),
        if (_useVad) ...[
          const SizedBox(height: 12),
          isCompactWidth
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.vadThreshold ?? 'VAD Threshold',
                      style: TextStyle(fontSize: 12, color: themeData.secondaryText),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SliderTheme(
                            data: AppTheme.premiumSliderTheme(context),
                            child: Slider(
                              value: _vadThreshold,
                              min: 0.1,
                              max: 0.9,
                              activeColor: themeData.accentOrange,
                              inactiveColor: themeData.dividerColor,
                              onChanged: (val) {
                                setState(() => _vadThreshold = val);
                              },
                              onChangeEnd: (val) {
                                SettingsService.instance.setVadThreshold(val);
                              },
                            ),
                          ),
                        ),
                        Text(
                          _vadThreshold.toStringAsFixed(1),
                          style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: themeData.primaryText),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        l10n?.vadThreshold ?? 'VAD Threshold',
                        style: TextStyle(fontSize: 12, color: themeData.secondaryText),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: SliderTheme(
                        data: AppTheme.premiumSliderTheme(context),
                        child: Slider(
                          value: _vadThreshold,
                          min: 0.1,
                          max: 0.9,
                          activeColor: themeData.accentOrange,
                          inactiveColor: themeData.dividerColor,
                          onChanged: (val) {
                            setState(() => _vadThreshold = val);
                          },
                          onChangeEnd: (val) {
                            SettingsService.instance.setVadThreshold(val);
                          },
                        ),
                      ),
                    ),
                    Text(
                      _vadThreshold.toStringAsFixed(1),
                      style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: themeData.primaryText),
                    ),
                  ],
                ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.autoSaveTitle ?? 'Automatic Auto-Save',
                    style: TextStyle(fontWeight: FontWeight.w600, color: themeData.primaryText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n?.autoSaveDesc ??
                        'Automatically save project edits to database every 3 seconds',
                    style: TextStyle(fontSize: 11, color: themeData.mutedText),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _autoSaveEnabled,
              activeThumbColor: themeData.accentOrange,
              onChanged: (val) {
                setState(() => _autoSaveEnabled = val);
                SettingsService.instance.setAutoSave(val);
              },
            ),
          ],
        ),
        Divider(color: themeData.borderGlass, height: 32),
      ],
    );
  }

  void reloadSettings() {
    setState(() {
      _loadSettings();
    });
  }
}
