import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:file_picker/file_picker.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/settings/settings_service.dart';
import '../../../../../core/widgets/whisper_threads_slider.dart';
import '../../../../../core/whisper/whisper_model.dart';
import '../../../../../core/whisper/whisper_languages.dart';
import '../../../../../core/downloader/binary_downloader_service.dart';
import '../../../../../core/utils/app_dirs.dart';
import '../../../../../core/subtitle/srt_importer.dart';
import '../../../../../core/utils/whisper_quality_selection.dart';
import '../../controllers/editor_controller.dart';

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

class _TranscriptionPanelState extends ConsumerState<TranscriptionPanel> with WhisperQualitySelectionMixin {
  bool _useMock = false;
  bool _useVad = false;
  double _vadThreshold = 0.5;
  String _selectedLanguage = 'auto';
  bool _translateToEnglish = false;

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

    initWhisperQualitySelection();
  }

  @override
  void dispose() {
    disposeWhisperQualitySelection();
    super.dispose();
  }

  void _triggerRetranscribe() {
    if (widget.onRetranscribe == null) return;
    
    // Verify video file exists before starting
    final project = ref.read(editorProvider).project;
    if (project != null && !kIsWeb && !File(project.videoPath).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Video file not found:\n${project.videoPath}\n'
            'Please re-link the video file.',
          ),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    
    // Save to settings immediately
    SettingsService.instance.setUseVad(_useVad);
    SettingsService.instance.setVadThreshold(_vadThreshold);
    SettingsService.instance.setDefaultLanguage(_selectedLanguage);

    final model = selectedModel;
    final modelPath = _useMock || model == null 
        ? '' 
        : p.join(AppDirs.support, 'models', 'ggml-${model.name}.bin');

    widget.onRetranscribe!(
      useMock: _useMock,
      language: _selectedLanguage,
      whisperCliPath: SettingsService.instance.whisperCliPath,
      whisperModelPath: modelPath,
      ffmpegCliPath: SettingsService.instance.ffmpegCliPath,
      useVad: _useVad,
      vadThreshold: _vadThreshold,
      translate: _translateToEnglish,
    );
  }

  Widget _buildQualityCards() {
    final isCompactWidth = MediaQuery.of(context).size.width < 600;
    
    final cards = QualityMode.values.map((mode) {
      final isSelected = selectedQuality == mode;
      final isEn = _selectedLanguage == 'en';
      final modelName = isEn ? mode.modelNameEn : mode.modelName;
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
                          const Icon(Icons.lock_outline, color: Colors.white38, size: 12)
                        else if (isRecommended)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                            decoration: AppTheme.glassDecoration(
                              color: AppTheme.accentCyan.withValues(alpha: 0.15),
                              borderRadius: 4,
                              borderOpacity: 0.15,
                            ),
                            child: Text(
                              'REC',
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
                              const Icon(Icons.check_circle, color: Colors.green, size: 12)
                            else if (isDownloading)
                              const SizedBox(
                                width: 10,
                                height: 10,
                                child: CircularProgressIndicator(strokeWidth: 1.2, color: Colors.amber),
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
                            backgroundColor: Colors.white10,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${(downloadProgress.downloadProgress * 100).toInt()}%',
                                style: const TextStyle(fontSize: 8, color: Colors.white38),
                              ),
                              if (downloadProgress.eta != null)
                                Text(
                                  '${downloadProgress.eta!.inSeconds}s',
                                  style: const TextStyle(fontSize: 8, color: Colors.white38),
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
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : AppTheme.accentOrange.withValues(alpha: 0.15),
                                foregroundColor: !isSupported ? Colors.white24 : Colors.white,
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
                                !isSupported ? 'Hardware Locked' : 'Download',
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
    final isEn = _selectedLanguage == 'en';
    final selectedModelName = isEn ? selectedQuality.modelNameEn : selectedQuality.modelName;
    final hasSelectedModelDownloaded = modelExists[selectedModelName] ?? false;
    final bool isReadyToTranscribe = kIsWeb || _useMock || hasSelectedModelDownloaded;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SPEECH-TO-TEXT TRANSCRIPTION',
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
            color: Colors.white.withValues(alpha: 0.02),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Re-run local Speech-to-Text transcription. Any manual edits or timing offsets will be replaced.',
                  style: TextStyle(fontSize: 11, color: AppTheme.secondaryText, height: 1.4),
                ),
                const SizedBox(height: 20),

                if (!kIsWeb) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Use Local AI Transcription',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Run speech-to-text directly on this device',
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
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 16),
                ],

                if (_useMock) ...[
                  if (kIsWeb) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.glassDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: 8,
                        borderOpacity: 0.12,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Offline Demo mode is active. Local Whisper AI transcription is not supported on Web.',
                              style: TextStyle(fontSize: 11, color: Colors.amber.shade200, height: 1.4),
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
                    child: const Text(
                      'Demo mode instantly generates highly realistic transcript tokens. Perfect for testing styles, templates, and timeline operations without setup.',
                      style: TextStyle(fontSize: 11, color: Colors.white60, height: 1.4),
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
                                'SELECT TRANSCRIPTION QUALITY',
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
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    dropdownColor: AppTheme.cardBg,
                    initialValue: _selectedLanguage,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Language',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    items: [
                      const DropdownMenuItem(value: 'auto', child: Text('Auto Detect', style: TextStyle(fontSize: 12))),
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
                              'Warning: The selected model (${selectedModel!.displayName}) is English-only. '
                              'Transcribing in "${kWhisperLanguages.firstWhere((l) => l.code == _selectedLanguage, orElse: () => WhisperLanguage('', _selectedLanguage)).name}" will fail or produce English captions. '
                              'Please select a Multilingual model (e.g. Tiny or Base).',
                              style: const TextStyle(color: Colors.redAccent, fontSize: 11, height: 1.3),
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
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Translate captions to English', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            SizedBox(height: 2),
                            Text('Convert foreign speech directly into English subtitles', style: TextStyle(fontSize: 9, color: Colors.white30)),
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
                            'HARDWARE & PERFORMANCE SETTINGS',
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
                          Text(
                            'Detected System Hardware:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                          ),
                          const SizedBox(height: 6),
                          if (hardwareInfo != null) ...[
                            Row(
                              children: [
                                const Icon(Icons.memory, size: 12, color: Colors.white38),
                                const SizedBox(width: 6),
                                Text('RAM Size: ${hardwareInfo!.ramGB.toStringAsFixed(1)} GB', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.speed, size: 12, color: Colors.white38),
                                const SizedBox(width: 6),
                                Text('CPU Logical Cores: ${hardwareInfo!.cpuCores}', style: const TextStyle(fontSize: 10, color: Colors.white70)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.developer_board, size: 12, color: Colors.white38),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'GPU Device: ${hardwareInfo!.gpuInfo}',
                                    style: const TextStyle(fontSize: 10, color: Colors.white70),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            const Text('Detecting hardware stats...', style: TextStyle(fontSize: 10, color: Colors.white38)),
                          ],
                          const Divider(color: Colors.white10, height: 20),
                          WhisperThreadsSlider(
                            value: SettingsService.instance.whisperThreads,
                            onChanged: (v) => setState(() {
                              SettingsService.instance.setWhisperThreads(v);
                            }),
                            valueStyle: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Voice Activity Detection (VAD)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                    SizedBox(height: 2),
                                    Text('Skips silent regions during processing', style: TextStyle(fontSize: 9, color: Colors.white30)),
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
                                  'VAD Threshold: ${_vadThreshold.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 10, color: Colors.white54),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _vadThreshold,
                                    min: 0.0,
                                    max: 1.0,
                                    divisions: 20,
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
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      'START RE-TRANSCRIBE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReadyToTranscribe ? AppTheme.accentOrange : Colors.grey.shade800,
                      foregroundColor: isReadyToTranscribe ? Colors.white : Colors.white24,
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
                    label: const Text(
                      'IMPORT SRT/VTT FILE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentCyan,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final result = await FilePicker.pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['srt', 'vtt'],
                      );
                      if (result != null) {
                        try {
                          final bytes = await result.files.single.readAsBytes();
                          final words = SrtImporter.parseSrtBytes(bytes);
                          if (!mounted) return;
                          final project = ref.read(editorProvider).project;
                          if (project != null) {
                            ref.read(editorProvider.notifier).importSubtitles(words);
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Imported ${words.length} words from subtitle file.')),
                            );
                          }
                        } catch (e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(content: Text('Failed to import subtitle file: $e')),
                          );
                        }
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
