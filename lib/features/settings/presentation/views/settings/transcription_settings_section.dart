import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:collection/collection.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/settings/settings_service.dart';
import '../../../../../core/whisper/whisper_languages.dart';
import '../../../../../core/whisper/whisper_model.dart';

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

  Widget _buildLanguageWarningCard() {
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
              const Expanded(
                child: Text(
                  'Tip: Auto-detect is not recommended for mixed languages (like Hinglish). '
                  'Explicitly selecting your spoken language (e.g. Hindi or English) will provide much more accurate captions.',
                  style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
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
          color: Colors.redAccent.withValues(alpha: 0.08),
          borderRadius: 8,
          borderOpacity: 0.12,
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Warning: Your active model (${activeModel?.displayName ?? modelName ?? 'English Only'}) is English-only. '
                'Transcribing in "${kWhisperLanguages.firstWhere((l) => l.code == _defaultLanguage, orElse: () => WhisperLanguage('', _defaultLanguage)).name}" will fail or produce English captions. '
                'Please download/select a Multilingual model.',
                style: const TextStyle(color: Colors.redAccent, fontSize: 11, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompactWidth = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('📝 Transcription Settings'),
        const SizedBox(height: 16),
        isCompactWidth
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Default Language', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_defaultLanguage),
                    isExpanded: true,
                    dropdownColor: AppTheme.cardBg,
                    initialValue: _defaultLanguage,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'auto', child: Text('Auto Detect')),
                      ...kWhisperLanguages.map((lang) => DropdownMenuItem(
                            value: lang.code,
                            child: Text('${lang.name} (${lang.code})'),
                          )),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _defaultLanguage = val);
                        SettingsService.instance.setDefaultLanguage(val);
                      }
                    },
                  ),
                  _buildLanguageWarningCard(),
                ],
              )
            : Row(
                children: [
                  const Expanded(
                    flex: 2,
                    child: Text('Default Language', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
                  ),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          key: ValueKey(_defaultLanguage),
                          isExpanded: true,
                          dropdownColor: AppTheme.cardBg,
                          initialValue: _defaultLanguage,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          items: [
                            const DropdownMenuItem(value: 'auto', child: Text('Auto Detect')),
                            ...kWhisperLanguages.map((lang) => DropdownMenuItem(
                                  value: lang.code,
                                  child: Text('${lang.name} (${lang.code})'),
                                )),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _defaultLanguage = val);
                              SettingsService.instance.setDefaultLanguage(val);
                            }
                          },
                        ),
                        _buildLanguageWarningCard(),
                      ],
                    ),
                  ),
                ],
              ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Voice Activity Detection (VAD)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
                  SizedBox(height: 4),
                  Text('Skips silent regions during processing', style: TextStyle(fontSize: 11, color: Colors.white30)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _useVad,
              activeThumbColor: AppTheme.accentOrange,
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
                    const Text('VAD Threshold', style: TextStyle(fontSize: 12, color: Colors.white60)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _vadThreshold,
                            min: 0.1,
                            max: 0.9,
                            activeColor: AppTheme.accentOrange,
                            inactiveColor: Colors.white12,
                            onChanged: (val) {
                              setState(() => _vadThreshold = val);
                              SettingsService.instance.setVadThreshold(val);
                            },
                          ),
                        ),
                        Text(
                          _vadThreshold.toStringAsFixed(1),
                          style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: Text('VAD Threshold', style: TextStyle(fontSize: 12, color: Colors.white60)),
                    ),
                    Expanded(
                      flex: 3,
                      child: Slider(
                        value: _vadThreshold,
                        min: 0.1,
                        max: 0.9,
                        activeColor: AppTheme.accentOrange,
                        inactiveColor: Colors.white12,
                        onChanged: (val) {
                          setState(() => _vadThreshold = val);
                          SettingsService.instance.setVadThreshold(val);
                        },
                      ),
                    ),
                    Text(
                      _vadThreshold.toStringAsFixed(1),
                      style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ],
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Automatic Auto-Save', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
                  SizedBox(height: 4),
                  Text('Automatically save project edits to database every 3 seconds', style: TextStyle(fontSize: 11, color: Colors.white30)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Switch(
              value: _autoSaveEnabled,
              activeThumbColor: AppTheme.accentOrange,
              onChanged: (val) {
                setState(() => _autoSaveEnabled = val);
                SettingsService.instance.setAutoSave(val);
              },
            ),
          ],
        ),
        const Divider(color: Colors.white10, height: 40),
      ],
    );
  }

  void reloadSettings() {
    setState(() {
      _loadSettings();
    });
  }
}
