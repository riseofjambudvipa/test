import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import '../../../../../app/theme.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../controllers/dashboard_controller.dart';
import '../../../../../core/whisper/whisper_model.dart';
import '../../../../../core/whisper/whisper_languages.dart';
import '../../../../../core/assets/asset_path_service.dart';
import '../../../../../core/settings/settings_service.dart';
import '../../../../../core/widgets/whisper_threads_slider.dart';
import '../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../core/utils/whisper_quality_selection.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../l10n/app_localizations.dart';
import 'import_quality_cards.dart';
export 'hoverable_import_card.dart';

class ImportVideoDialog extends ConsumerStatefulWidget {
  final String filePath;
  final bool isDemo;
  const ImportVideoDialog({super.key, required this.filePath, required this.isDemo});

  @override
  ConsumerState<ImportVideoDialog> createState() => _ImportVideoDialogState();
}

class _ImportVideoDialogState extends ConsumerState<ImportVideoDialog> with WhisperQualitySelectionMixin {
  late final TextEditingController _nameController;
  bool _useMock = true;
  bool _useVad = false;
  double _vadThreshold = 0.5;
  String _selectedLanguage = 'auto';
  bool _translateToEnglish = false;

  bool _showAdvancedSettings = false;

  double? _videoDuration;
  String? _selectedSubtitlePath;

  @override
  String get selectedLanguageForQualityPicker => _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _useMock = widget.isDemo;
    _selectedLanguage = SettingsService.instance.defaultLanguage;
    final fileName = p.basenameWithoutExtension(widget.filePath);
    String projectDefaultName = '${fileName}_project';
    if (widget.isDemo) {
      if (widget.filePath.contains('landscape')) {
        projectDefaultName = 'Landscape Demo';
      } else if (widget.filePath.contains('protrait') || widget.filePath.contains('portrait')) {
        projectDefaultName = 'Portrait Demo';
      }
    }
    _nameController = TextEditingController(text: projectDefaultName);

    selectedModel = kWhisperModels.firstWhere((m) => m.name == 'tiny');

    _loadVideoMetadata();
    initWhisperQualitySelection();
  }

  Future<void> _loadVideoMetadata() async {
    try {
      final controller = ref.read(dashboardProvider.notifier);
      final meta = await controller.getVideoMetadata(widget.filePath);
      if (mounted) {
        setState(() {
          _videoDuration = meta.duration;
        });
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'ImportVideoDialog', 'Failed to retrieve video metadata: $e');
    }
  }

  Future<void> _executeImport() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    
    final router = GoRouter.maybeOf(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    
    // Close the import dialog immediately to reveal the full-screen progress loader on the dashboard
    Navigator.pop(context);

    final notifier = ref.read(dashboardProvider.notifier);
    
    String? modelPath;
    if (!_useMock && selectedModel != null) {
      modelPath = AssetPathService.instance.resolveModelPath(selectedModel!.name);
      await SettingsService.instance.setWhisperModelPath(modelPath);
      await SettingsService.instance.setWhisperModelName(selectedModel!.name);
    }
 
    try {
      final project = await notifier.importVideo(
        videoPath: widget.filePath,
        projectName: name,
        useMockTranscription: _useMock,
        subtitlePath: _selectedSubtitlePath,
        language: _selectedLanguage,
        whisperCliPath: SettingsService.instance.whisperCliPath,
        whisperModelPath: modelPath,
        ffmpegCliPath: SettingsService.instance.ffmpegCliPath,
        useVad: _useVad,
        vadThreshold: _vadThreshold,
        translate: _translateToEnglish,
      );
 
      if (project != null) {
        router?.go('/editor/${project.projectId}');
      } else {
        final error = ref.read(dashboardProvider).errorMessage;
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(error ?? (l10n?.dialogImportFailed ?? 'Import failed.')),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n?.errorImportVideoFailed(e.toString()) ?? 'Import failed: $e',
          ),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    disposeWhisperQualitySelection();
    super.dispose();
  }

  Widget _buildQualityCards() {
    return ImportQualityCards(
      selectedQuality: selectedQuality,
      hardwareInfo: hardwareInfo,
      modelExists: modelExists,
      downloadProgressMap: downloadProgressMap,
      onSelectQuality: (mode) {
        setState(() {
          selectedQuality = mode;
          updateModelForSelectedQuality();
          isQualitySelectorExpanded = false;
        });
      },
      onDownloadModel: (model) => downloadWhisperModel(model, logTag: 'ImportVideoDialog'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedModelName = selectedQuality.modelName;
    final hasSelectedModelDownloaded = modelExists[selectedModelName] ?? false;

    return PremiumBlurDialog(
      maxWidth: 580,
      borderOpacity: 0.12,
      useScrollView: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.importVideo.toUpperCase() ?? 'IMPORT NEW VIDEO',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.accentOrange,
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: AppTheme.secondaryText),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(color: AppTheme.dividerColor, height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (l10n?.projectNameLabel ?? 'Project Name').toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.secondaryText,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(fontSize: 13, color: AppTheme.primaryText),
                    decoration: InputDecoration(
                      hintText: l10n?.projectNameLabel ?? 'Project Name',
                      hintStyle: TextStyle(fontSize: 12, color: AppTheme.mutedText),
                      border: AppTheme.defaultBorder(),
                      focusedBorder: AppTheme.focusedBorder(),
                      filled: true,
                      fillColor: AppTheme.cardBg,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && _videoDuration != null && _videoDuration! > 7200) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.glassDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.08),
                        borderRadius: 8,
                        borderOpacity: 0.15,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppTheme.accentOrange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Warning: This video is over 2 hours. Transcription and video rendering on mobile devices may take a long time and drain battery. For large projects, the desktop version of CapStudio is recommended.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.accentOrange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (kIsWeb && _videoDuration != null && _videoDuration! > 3600) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.glassDecoration(
                        color: AppTheme.accentOrange.withValues(alpha: 0.08),
                        borderRadius: 8,
                        borderOpacity: 0.15,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: AppTheme.accentOrange, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'CapStudio Web limits: Running long video rendering in a browser sandbox is not supported. Subtitles will be mocked. For full GPU-accelerated video rendering, please use the desktop app.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.accentOrange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: AppTheme.glassDecoration(
                      color: (widget.isDemo ? AppTheme.accentCyan : AppTheme.accentOrange).withValues(alpha: 0.06),
                      borderRadius: 8,
                      borderOpacity: 0.2,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.isDemo ? Icons.bolt_outlined : Icons.settings_voice_outlined,
                          color: widget.isDemo ? AppTheme.accentCyan : AppTheme.accentOrange,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.isDemo
                                ? 'Instant Demo Mode: Mock subtitles will be generated instantly for layout and animation testing.'
                                : 'Standard Transcription Mode: Audio will be transcribed using the local Whisper engine.',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.secondaryText,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_useMock) ...[
                    const SizedBox(height: 16),
                    Text(
                      'IMPORT EXTERNAL SUBTITLES (OPTIONAL)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryText,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: AppTheme.glassDecoration(
                        color: _selectedSubtitlePath != null
                            ? AppTheme.accentCyan.withValues(alpha: 0.05)
                            : AppTheme.cardBg,
                        borderRadius: 8,
                        borderOpacity: _selectedSubtitlePath != null ? 0.35 : 0.08,
                        glowColor: _selectedSubtitlePath != null ? AppTheme.accentCyan : null,
                        glowOpacity: _selectedSubtitlePath != null ? 0.15 : 0.0,
                      ).copyWith(
                        border: Border.all(
                          color: _selectedSubtitlePath != null
                              ? AppTheme.accentCyan.withValues(alpha: 0.4)
                              : AppTheme.borderGlass,
                          width: _selectedSubtitlePath != null ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.subtitles_outlined,
                            color: _selectedSubtitlePath != null ? AppTheme.accentCyan : AppTheme.mutedText,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _selectedSubtitlePath != null
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.basename(_selectedSubtitlePath!),
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Using external file (Whisper transcription will be skipped)',
                                        style: TextStyle(fontSize: 9, color: AppTheme.accentGreen),
                                      ),
                                    ],
                                  )
                                : Text(
                                    'No subtitle file selected (.srt, .vtt)',
                                    style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
                                  ),
                          ),
                          if (_selectedSubtitlePath != null)
                            IconButton(
                              icon: Icon(Icons.clear, size: 16, color: AppTheme.accentRed),
                              onPressed: () {
                                setState(() {
                                  _selectedSubtitlePath = null;
                                });
                              },
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.cardBgElevated,
                                foregroundColor: AppTheme.primaryText,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () async {
                                try {
                                  final result = await FilePicker.pickFiles(
                                    dialogTitle: l10n?.selectSubtitleFile ?? 'Select Subtitle File',
                                    type: FileType.custom,
                                    allowedExtensions: ['srt', 'vtt'],
                                  );
                                  if (result != null && result.files.single.path != null) {
                                    setState(() {
                                      _selectedSubtitlePath = result.files.single.path;
                                    });
                                  }
                                } catch (e) {
                                  LoggerService.instance.log(LogLevel.error, 'ImportVideoDialog', 'Failed to pick subtitle file: $e');
                                }
                              },
                              child: Text(l10n?.btnChooseFile ?? 'CHOOSE FILE'),
                            ),
                        ],
                      ),
                    ),
                    if (_selectedSubtitlePath == null) ...[
                      const SizedBox(height: 16),
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
                                      'Powered by Transformers.js (ONNX Runtime Web). Audio is transcribed 100% locally in your browser sandbox.',
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n?.selectTranscriptionQuality ?? 'SELECT TRANSCRIPTION QUALITY',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.secondaryText,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Active: ${selectedQuality.displayName} (${selectedModel?.displayName ?? "none"})',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: AppTheme.accentOrange.withValues(alpha: 0.8),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
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
                      Text(
                        (l10n?.settingsTranscribeLang ?? 'Transcription Language').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.secondaryText,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedLanguage,
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: AppTheme.defaultBorder(),
                          focusedBorder: AppTheme.focusedBorder(),
                          filled: true,
                          fillColor: AppTheme.cardBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        dropdownColor: AppTheme.cardBg,
                        items: [
                          DropdownMenuItem(value: 'auto', child: Text(l10n?.settingsAutoDetect ?? 'Auto Detect')),
                          ...kWhisperLanguages.map((lang) => DropdownMenuItem(
                                value: lang.code,
                                child: Text('${lang.name} (${lang.code})'),
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
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(l10n?.translateToEnglish ?? 'Translate captions to English', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryText)),
                                const SizedBox(height: 2),
                                Text(l10n?.translateToEnglishDesc ?? 'Convert foreign speech directly into English subtitles', style: TextStyle(fontSize: 9, color: AppTheme.mutedText)),
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
                      if (_selectedLanguage == 'auto') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: AppTheme.glassDecoration(
                            color: AppTheme.accentOrange.withValues(alpha: 0.08),
                            borderRadius: 8,
                            borderOpacity: 0.15,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, color: AppTheme.accentOrange, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Tip: Auto-detect is not recommended for mixed languages (like Hinglish). '
                                  'Explicitly selecting your spoken language (e.g. Hindi or English) will provide much more accurate captions.',
                                  style: TextStyle(color: AppTheme.primaryText, fontSize: 11, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                            color: AppTheme.cardBg.withValues(alpha: 0.25),
                            borderRadius: 8,
                            borderOpacity: 0.06,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) ...[
                                Text(
                                  'Detected System Hardware:',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                              ),
                              const SizedBox(height: 6),
                              if (hardwareInfo != null) ...[
                                Row(
                                  children: [
                                    Icon(Icons.memory, size: 12, color: AppTheme.mutedText),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'RAM Size: ${hardwareInfo!.ramGB.toStringAsFixed(1)} GB',
                                        style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.speed, size: 12, color: AppTheme.mutedText),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'CPU Logical Cores: ${hardwareInfo!.cpuCores}',
                                        style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
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
                                        'GPU Device: ${hardwareInfo!.gpuInfo}',
                                        style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              ] else ...[
                                Text('Detecting hardware stats...', style: TextStyle(fontSize: 10, color: AppTheme.mutedText)),
                              ],
                              Divider(color: AppTheme.dividerColor, height: 20),
                              WhisperThreadsSlider(
                                value: SettingsService.instance.whisperThreads,
                                onChanged: (v) => setState(() {
                                  SettingsService.instance.setWhisperThreads(v);
                                }),
                                usePremiumTheme: true,
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
                                        Text(l10n?.vadTitle ?? 'Voice Activity Detection (VAD)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text(l10n?.vadDesc ?? 'Skips silent regions during processing', style: TextStyle(fontSize: 9, color: AppTheme.mutedText)),
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
                                      child: SliderTheme(
                                        data: AppTheme.premiumSliderTheme(context).copyWith(
                                          inactiveTrackColor: AppTheme.dividerColor,
                                        ),
                                        child: Slider(
                                          value: _vadThreshold.clamp(0.1, 0.9),
                                          min: 0.1,
                                          max: 0.9,
                                          divisions: 16,
                                          onChanged: (val) {
                                            setState(() {
                                              _vadThreshold = val;
                                            });
                                          },
                                        ),
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
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: AppTheme.onAccentText,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: (_useMock || hasSelectedModelDownloaded)
                    ? () => _executeImport()
                    : null,
                child: Text(l10n?.btnCreateProject ?? 'CREATE PROJECT', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(l10n?.btnCancel ?? 'CANCEL', style: TextStyle(color: AppTheme.secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
