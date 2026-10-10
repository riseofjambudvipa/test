import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/settings/settings_service.dart';
import '../../../../../core/widgets/whisper_threads_slider.dart';
import '../../../../../core/whisper/whisper_model.dart';
import '../../../../../core/whisper/whisper_languages.dart';
import '../../../../../core/downloader/binary_downloader_service.dart';
import '../../../../../core/assets/asset_path_service.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../core/subtitle/srt_importer.dart';
import '../../../../../core/utils/whisper_quality_selection.dart';
import '../../controllers/editor_controller.dart';
import '../../../../../l10n/app_localizations.dart';
import 'transcription_panel/transcription_post_enhancement_card.dart';

class TranscriptionPanel extends ConsumerStatefulWidget {
  final Future<void> Function({
    required bool useMock,
    String? language,
    String? whisperCliPath,
    String? whisperModelPath,
    String? ffmpegCliPath,
    bool? useVad,
    double? vadThreshold,
    bool? translate,
  })? onRetranscribe;

  const TranscriptionPanel({super.key, this.onRetranscribe});

  @override
  ConsumerState<TranscriptionPanel> createState() => _TranscriptionPanelState();
}

class _TranscriptionPanelState extends ConsumerState<TranscriptionPanel> with WhisperQualitySelectionMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  bool _useMock = false;
  bool _useVad = false;
  double _vadThreshold = 0.5;
  String _selectedLanguage = 'auto';
  bool _translateToEnglish = false;
  bool _autoApplyEmojis = false;
  bool _autoApplySfx = false;

  bool _showAdvancedSettings = false;

  @override
  String get selectedLanguageForQualityPicker => _selectedLanguage;

  @override
  void initState() {
    super.initState();
    // Load from settings
    _useMock = kIsWeb ? false : (SettingsService.instance.whisperModelPath == null && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS));
    _useVad = SettingsService.instance.useVad;
    _vadThreshold = SettingsService.instance.vadThreshold;
    _selectedLanguage = SettingsService.instance.defaultLanguage;
    _autoApplyEmojis = SettingsService.instance.autoApplyEmojis;
    _autoApplySfx = SettingsService.instance.autoApplySfx;

    initWhisperQualitySelection();
  }

  @override
  void dispose() {
    disposeWhisperQualitySelection();
    super.dispose();
  }

  Future<void> _triggerRetranscribe() async {
    if (widget.onRetranscribe == null) return;

    // Verify video file exists before starting
    // FIX (audit): existsSync() is a blocking filesystem call on the UI
    // thread; use the async exists() instead.
    final project = ref.read(editorProvider).project;
    final l10n = AppLocalizations.of(context);
    if (project != null && !kIsWeb && !await File(project.videoPath).exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorVideoFileNotFound(project.videoPath)
                ?? 'Video file not found:\n${project.videoPath}\nPlease re-link the video file.',
          ),
          backgroundColor: AppTheme.accentRed,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // Save to settings immediately
    await SettingsService.instance.setUseVad(_useVad);
    await SettingsService.instance.setVadThreshold(_vadThreshold);
    await SettingsService.instance.setDefaultLanguage(_selectedLanguage);

    final model = selectedModel;
    final modelPath = _useMock || model == null
        ? ''
        : AssetPathService.instance.resolveModelPath(model.name);

    try {
      // FIX (audit): the retranscribe future was fired unawaited with no
      // error handling — any pipeline failure became an unhandled async
      // exception. Surface it to the user instead.
      await widget.onRetranscribe!(
        useMock: _useMock,
        language: _selectedLanguage,
        whisperCliPath: SettingsService.instance.whisperCliPath,
        whisperModelPath: modelPath,
        ffmpegCliPath: SettingsService.instance.ffmpegCliPath,
        useVad: _useVad,
        vadThreshold: _vadThreshold,
        translate: _translateToEnglish,
      );

      if (_autoApplyEmojis) {
        ref.read(editorProvider.notifier).autoApplyMagicEmojis();
      }
      if (_autoApplySfx) {
        ref.read(editorProvider.notifier).autoApplyMagicSfx();
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'TranscriptionPanel', 'Retranscription failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n?.errorTranscriptionFailed ?? 'Transcription failed. Please try again.'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  Widget _buildQualityCards() {
    final l10n = AppLocalizations.of(context);
    final isCompactWidth = MediaQuery.of(context).size.width < 600;
    
    final cards = QualityMode.values.map((mode) {
      final isSelected = selectedQuality == mode;
      final modelName = mode.modelName;
      final isDownloaded = modelExists[modelName] ?? false;
      final downloadProgress = downloadProgressMap[modelName];
      final isDownloading = downloadProgress != null && downloadProgress.status == BinaryDownloadStatus.downloading;
      
      final isRecommended = hardwareInfo != null && getRecommendedQualityMode(hardwareInfo!) == mode;
      final isSupported = mode.isSupported(hardwareInfo);

      final cardChild = InkWell(
          onTap: !isSupported
              ? null
              : () {
                  setState(() {
                    selectedQuality = mode;
                    updateModelForSelectedQuality();
                    isQualitySelectorExpanded = false;
                  });
                },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            margin: isCompactWidth ? const EdgeInsets.only(bottom: 10) : const EdgeInsets.symmetric(horizontal: 4),
            decoration: AppTheme.glassDecoration(
              color: isSelected
                  ? AppTheme.accentOrange.withValues(alpha: 0.08)
                  : AppTheme.cardBg.withValues(alpha: 0.25),
              borderRadius: 12,
              borderOpacity: isSelected ? 0.24 : (isSupported ? 0.06 : 0.015),
              glowColor: isSelected ? AppTheme.accentOrange : (isRecommended ? AppTheme.accentCyan : null),
              glowOpacity: isSelected ? 0.08 : (isRecommended ? 0.03 : 0.0),
            ),
            child: Opacity(
              opacity: isSupported ? 1.0 : 0.45,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: isCompactWidth ? null : 32,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            mode.displayName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppTheme.accentOrange : AppTheme.primaryText,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(width: 4),
                        if (!isSupported)
                          Icon(Icons.lock_outline, color: AppTheme.mutedText, size: 12)
                        else if (isRecommended)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: AppTheme.glassDecoration(
                              color: AppTheme.accentCyan.withValues(alpha: 0.15),
                              borderRadius: 4,
                              borderOpacity: 0.15,
                            ),
                            child: Text(
                              l10n?.badgeRecommended ?? 'REC',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.accentCyan,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: isCompactWidth ? 4 : 6),
                  SizedBox(
                    height: isCompactWidth ? null : 24,
                    child: Text(
                      mode.speedAccuracyText,
                      style: TextStyle(fontSize: 9, color: AppTheme.secondaryText, fontWeight: FontWeight.w500),
                      maxLines: 2,
                    ),
                  ),
                  SizedBox(height: isCompactWidth ? 2 : 4),
                  SizedBox(
                    height: isCompactWidth ? null : 32,
                    child: Text(
                      mode.getDetailsWithSystemInfo(hardwareInfo),
                      style: TextStyle(fontSize: 8, color: AppTheme.mutedText),
                      maxLines: 3,
                    ),
                  ),
                  if (!isCompactWidth) const Spacer(),
                  if (isCompactWidth) const SizedBox(height: 8),
                  SizedBox(
                    height: isCompactWidth ? null : 60,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Model: $modelName',
                                style: TextStyle(fontSize: 8, color: AppTheme.mutedText, fontFamily: 'monospace'),
                              ),
                            ),
                            const SizedBox(width: 4),
                            if (isDownloaded)
                              Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 12)
                            else if (isDownloading)
                              SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(strokeWidth: 1.2, color: AppTheme.accentOrange),
                              )
                            else
                              Icon(Icons.download_for_offline_outlined, color: AppTheme.mutedText.withValues(alpha: 0.25), size: 12),
                          ],
                        ),
                        if (isDownloading) ...[
                          const SizedBox(height: 6),
                          LinearProgressIndicator(
                            value: downloadProgress.downloadProgress,
                            color: AppTheme.accentOrange,
                            backgroundColor: AppTheme.dividerColor,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(downloadProgress.downloadProgress * 100).toInt()}%',
                                style: TextStyle(fontSize: 8, color: AppTheme.mutedText),
                              ),
                              if (downloadProgress.eta != null)
                                Text(
                                  '${downloadProgress.eta!.inSeconds}s',
                                  style: TextStyle(fontSize: 8, color: AppTheme.mutedText),
                                ),
                            ],
                          ),
                        ] else if (!kIsWeb && !isDownloaded && !isDownloading) ...[
                          const SizedBox(height: 6),
                          SizedBox(
                            width: double.infinity,
                            height: 20,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !isSupported
                                    ? AppTheme.cardBgElevated
                                    : AppTheme.accentOrange.withValues(alpha: 0.15),
                                foregroundColor: !isSupported ? AppTheme.mutedText : AppTheme.accentOrange,
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                elevation: 0,
                              ),
                              onPressed: !isSupported
                                  ? null
                                  : () => downloadWhisperModel(
                                        kWhisperModels.firstWhere((m) => m.name == modelName, orElse: () => kWhisperModels.first),
                                        logTag: 'TranscriptionPanel',
                                      ),
                              child: Text(
                                !isSupported ? (l10n?.hardwareLocked ?? 'Hardware Locked') : (l10n?.btnDownload ?? 'Download'),
                                style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          if (!isCompactWidth) const SizedBox(height: 4),
                        ] else ...[
                          if (!isCompactWidth) const SizedBox(height: 44),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      );

      return SizedBox(
        width: isCompactWidth ? double.infinity : 166,
        height: isCompactWidth ? null : 195,
        child: cardChild,
      );
    }).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cards,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context);
    final selectedModelName = selectedQuality.modelName;
    final hasSelectedModelDownloaded = modelExists[selectedModelName] ?? false;
    final bool isReadyToTranscribe = kIsWeb || _useMock || hasSelectedModelDownloaded;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.speechToTextTitle ?? 'SPEECH-TO-TEXT TRANSCRIPTION',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppTheme.secondaryText,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          GlassContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 12,
            borderOpacity: 0.08,
            color: AppTheme.cardBg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.speechToTextDesc ?? 'Re-run local Speech-to-Text transcription. Any manual edits or timing offsets will be replaced.',
                  style: TextStyle(fontSize: 11, color: AppTheme.secondaryText, height: 1.4),
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
                            kIsWeb
                                ? 'Use In-Browser AI Transcription'
                                : (l10n?.useLocalAi ?? 'Use Local AI Transcription'),
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            kIsWeb
                                ? 'Run speech-to-text directly in your browser with Transformers.js'
                                : (l10n?.runOnDeviceDesc ?? 'Run speech-to-text directly on this device'),
                            style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: !_useMock,
                      activeThumbColor: AppTheme.accentOrange,
                      onChanged: (val) {
                        setState(() {
                          _useMock = !val;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: AppTheme.dividerColor),
                const SizedBox(height: 16),

                if (_useMock) ...[
                  if (kIsWeb) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.glassDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.08),
                        borderRadius: 8,
                        borderOpacity: 0.12,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.accentOrange, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Offline Demo mode is active. Instant preview captions will be generated without running the speech model.',
                              style: TextStyle(fontSize: 11, color: AppTheme.accentOrange, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: AppTheme.glassDecoration(
                      color: AppTheme.cardBg.withValues(alpha: 0.15),
                      borderRadius: 8,
                      borderOpacity: 0.06,
                    ),
                    child: Text(
                      l10n?.demoModeNote ?? 'Demo mode instantly generates highly realistic transcript tokens. Perfect for testing styles, templates, and timeline operations without setup.',
                      style: TextStyle(fontSize: 11, color: AppTheme.secondaryText, height: 1.4),
                    ),
                  ),
                ] else ...[
                  if (kIsWeb) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.glassDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.08),
                        borderRadius: 8,
                        borderOpacity: 0.15,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.psychology_rounded, color: AppTheme.accentOrange, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'In-Browser AI Speech Recognition',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Powered by Transformers.js (ONNX Runtime Web). Audio is transcribed 100% locally in your browser sandbox without sending any data to servers.',
                                  style: TextStyle(fontSize: 10, color: AppTheme.secondaryText, height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    InkWell(
                    onTap: () {
                      setState(() {
                        isQualitySelectorExpanded = !isQualitySelectorExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n?.selectTranscriptionQuality ?? 'SELECT TRANSCRIPTION QUALITY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryText,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n?.transcriptionActiveModel(
                                      selectedQuality.displayName,
                                      selectedModel?.displayName ?? "none",
                                    ) ??
                                    'Active: ${selectedQuality.displayName} (${selectedModel?.displayName ?? "none"})',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.accentOrange.withValues(alpha: 0.8),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            isQualitySelectorExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppTheme.accentOrange,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedCrossFade(
                    firstChild: Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: _buildQualityCards(),
                    ),
                    secondChild: const SizedBox.shrink(),
                    crossFadeState: isQualitySelectorExpanded
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    duration: const Duration(milliseconds: 200),
                  ),
                  ],
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    dropdownColor: AppTheme.cardBg,
                    initialValue: _selectedLanguage,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: l10n?.languageLabel ?? 'Language',
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: TextStyle(fontSize: 12, color: AppTheme.primaryText),
                    items: [
                      DropdownMenuItem(
                        value: 'auto',
                        child: Text(l10n?.autoDetect ?? 'Auto Detect', style: const TextStyle(fontSize: 12)),
                      ),
                      ...kWhisperLanguages.map((lang) => DropdownMenuItem(
                            value: lang.code,
                            child: Text(lang.name, style: const TextStyle(fontSize: 12)),
                          )),
                    ],
                    onChanged: (lang) {
                      if (lang != null) {
                        setState(() {
                          _selectedLanguage = lang;
                          updateModelForSelectedQuality();
                        });
                      }
                    },
                  ),
                  if (!_useMock &&
                      _selectedLanguage != 'auto' &&
                      _selectedLanguage != 'en' &&
                      selectedModel != null &&
                      selectedModel!.englishOnly) ...[
                    const SizedBox(height: 8),
                    Container(
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
                              l10n?.warningEnglishOnlyModel(
                                    selectedModel!.displayName,
                                    kWhisperLanguages.firstWhere((l) => l.code == _selectedLanguage, orElse: () => WhisperLanguage('', _selectedLanguage)).name,
                                  ) ??
                                  'Warning: The selected model (${selectedModel!.displayName}) is English-only. '
                                  'Transcribing in "${kWhisperLanguages.firstWhere((l) => l.code == _selectedLanguage, orElse: () => WhisperLanguage('', _selectedLanguage)).name}" will fail or produce English captions. '
                                  'Please select a Multilingual model (e.g. Tiny or Base).',
                              style: TextStyle(color: AppTheme.accentRed, fontSize: 11, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (!_useMock && _selectedLanguage == 'auto') ...[
                    const SizedBox(height: 8),
                    Container(
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
                              l10n?.tipAutoDetectMixedLanguage ??
                                  'Tip: Auto-detect is not recommended for mixed languages (like Hinglish). '
                                  'Explicitly selecting your spoken language (e.g. Hindi or English) will provide much more accurate captions.',
                              style: TextStyle(color: AppTheme.secondaryText, fontSize: 11, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n?.translateToEnglish ?? 'Translate captions to English',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              l10n?.translateToEnglishDesc ?? 'Convert foreign speech directly into English subtitles',
                              style: TextStyle(fontSize: 9, color: AppTheme.mutedText),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _translateToEnglish,
                        activeThumbColor: AppTheme.accentOrange,
                        onChanged: (val) {
                          setState(() {
                            _translateToEnglish = val;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _showAdvancedSettings = !_showAdvancedSettings;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            _showAdvancedSettings ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                            size: 16,
                            color: AppTheme.accentOrange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            (kIsWeb || (!kIsWeb && (Platform.isAndroid || Platform.isIOS)))
                                ? (l10n?.advancedSettings.toUpperCase() ?? 'ADVANCED SETTINGS')
                                : (l10n?.hardwareSettings ?? 'HARDWARE & PERFORMANCE SETTINGS'),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentOrange,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showAdvancedSettings) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.glassDecoration(
                        color: AppTheme.cardBg.withValues(alpha: 0.15),
                        borderRadius: 8,
                        borderOpacity: 0.06,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) ...[
                            Text(
                              l10n?.detectedHardwareLabel ?? 'Detected System Hardware:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                          ),
                          const SizedBox(height: 6),
                          if (hardwareInfo != null) ...[
                            Row(
                              children: [
                                Icon(Icons.memory, size: 12, color: AppTheme.mutedText),
                                const SizedBox(width: 6),
                                Text(
                                  l10n?.hardwareRamSize(hardwareInfo!.ramGB.toStringAsFixed(1)) ??
                                      'RAM Size: ${hardwareInfo!.ramGB.toStringAsFixed(1)} GB',
                                  style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.speed, size: 12, color: AppTheme.mutedText),
                                const SizedBox(width: 6),
                                Text(
                                  l10n?.hardwareCpuCores(hardwareInfo!.cpuCores) ??
                                      'CPU Logical Cores: ${hardwareInfo!.cpuCores}',
                                  style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.developer_board, size: 12, color: AppTheme.mutedText),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    l10n?.hardwareGpuDevice(hardwareInfo!.gpuInfo) ??
                                        'GPU Device: ${hardwareInfo!.gpuInfo}',
                                    style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            Text(
                              l10n?.hardwareDetecting ?? 'Detecting hardware stats...',
                              style: TextStyle(fontSize: 10, color: AppTheme.mutedText),
                            ),
                          ],
                          Divider(color: AppTheme.dividerColor, height: 20),
                          WhisperThreadsSlider(
                            value: SettingsService.instance.whisperThreads,
                            onChanged: (v) => setState(() {
                              SettingsService.instance.setWhisperThreads(v);
                            }),
                            valueStyle: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                        ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n?.vadTitle ?? 'Voice Activity Detection (VAD)',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n?.vadDesc ?? 'Skips silent regions during processing',
                                      style: TextStyle(fontSize: 9, color: AppTheme.mutedText),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _useVad,
                                activeThumbColor: AppTheme.accentOrange,
                                onChanged: (val) {
                                  setState(() {
                                    _useVad = val;
                                  });
                                },
                              ),
                            ],
                          ),
                          if (_useVad) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  '${l10n?.vadThreshold ?? "VAD Threshold"}: ${_vadThreshold.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _vadThreshold.clamp(0.1, 0.9),
                                    min: 0.1,
                                    max: 0.9,
                                    divisions: 16,
                                    activeColor: AppTheme.accentOrange,
                                    onChanged: (val) {
                                      setState(() {
                                        _vadThreshold = val;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                TranscriptionPostEnhancementCard(
                  autoApplyEmojis: _autoApplyEmojis,
                  autoApplySfx: _autoApplySfx,
                  onAutoApplyEmojisChanged: (val) {
                    setState(() => _autoApplyEmojis = val);
                    SettingsService.instance.setAutoApplyEmojis(val);
                  },
                  onAutoApplySfxChanged: (val) {
                    setState(() => _autoApplySfx = val);
                    SettingsService.instance.setAutoApplySfx(val);
                  },
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      l10n?.btnStartReTranscribe ?? 'START RE-TRANSCRIBE',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReadyToTranscribe ? AppTheme.accentOrange : AppTheme.cardBgElevated,
                      foregroundColor: isReadyToTranscribe ? AppTheme.onAccentText : AppTheme.mutedText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isReadyToTranscribe ? _triggerRetranscribe : null,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file, size: 16),
                    label: Text(
                      l10n?.btnImportSrtVtt ?? 'IMPORT SRT/VTT FILE',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentCyan,
                      foregroundColor: AppTheme.onAccentText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      try {
                        // FIX (audit): the try block started AFTER the picker
                        // call, so a picker exception escaped the catch.
                        final result = await FilePicker.pickFiles(
                          type: FileType.custom,
                          allowedExtensions: ['srt', 'vtt'],
                        );
                        if (result != null) {
                          final bytes = await result.files.single.readAsBytes();
                          final words = SrtImporter.parseSrtBytes(bytes);
                          if (!mounted) return;
                          final project = ref.read(editorProvider).project;
                          if (project != null) {
                            ref.read(editorProvider.notifier).importSubtitles(words);
                            if (_autoApplyEmojis) {
                              ref.read(editorProvider.notifier).autoApplyMagicEmojis();
                            }
                            if (_autoApplySfx) {
                              ref.read(editorProvider.notifier).autoApplyMagicSfx();
                            }
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n?.importedSubtitleWords(words.length) ??
                                      'Imported ${words.length} words from subtitle file.',
                                ),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        // FIX (audit): keep the message generic instead of
                        // interpolating raw picker/path internals.
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n?.errorImportSubtitleFailed ??
                                  'Failed to import subtitle file. Please check the file format.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
