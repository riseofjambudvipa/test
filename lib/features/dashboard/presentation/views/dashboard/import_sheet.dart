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
import '../../../../../core/downloader/binary_downloader_service.dart';
import '../../../../../core/utils/app_dirs.dart';
import '../../../../../core/settings/settings_service.dart';
import '../../../../../core/widgets/whisper_threads_slider.dart';
import '../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../core/utils/whisper_quality_selection.dart';
import 'package:file_picker/file_picker.dart';

class HoverableImportCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const HoverableImportCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<HoverableImportCard> createState() => _HoverableImportCardState();
}

class _HoverableImportCardState extends State<HoverableImportCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late final AnimationController _iconAnimController;

  @override
  void initState() {
    super.initState();
    _iconAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _iconAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobileWidth = size.width < 600;
    final isSmallHeight = size.height < 500;
    final double effectiveHeight = isMobileWidth 
        ? 84.0 
        : (isSmallHeight ? 90.0 : 160.0);
    final bool useRowLayout = effectiveHeight <= 100;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.015 : 1.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: GlassContainer(
            height: effectiveHeight,
            borderRadius: 16,
            borderOpacity: _isHovered ? 0.24 : 0.08,
            glowColor: AppTheme.accentOrange,
            glowOpacity: _isHovered ? 0.08 : 0.0,
            color: _isHovered
                ? AppTheme.cardBg.withValues(alpha: 0.6)
                : AppTheme.cardBg.withValues(alpha: 0.35),
            child: useRowLayout
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        AnimatedBuilder(
                          animation: _iconAnimController,
                          builder: (context, child) {
                            final double offset = _isHovered ? (_iconAnimController.value * -4.0) : 0.0;
                            return Transform.translate(
                              offset: Offset(0, offset),
                              child: Icon(
                                widget.icon,
                                size: 32,
                                color: _isHovered ? AppTheme.accentOrange : AppTheme.accentOrange.withValues(alpha: 0.8),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                  color: _isHovered ? AppTheme.primaryText : AppTheme.primaryText.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 10,
                                  color: _isHovered ? AppTheme.secondaryText : AppTheme.secondaryText.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppTheme.secondaryText.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _iconAnimController,
                              builder: (context, child) {
                                final double offset = _isHovered ? (_iconAnimController.value * -6.0) : 0.0;
                                return Transform.translate(
                                  offset: Offset(0, offset),
                                  child: Icon(
                                    widget.icon,
                                    size: 44,
                                    color: _isHovered ? AppTheme.accentOrange : AppTheme.accentOrange.withValues(alpha: 0.8),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                widget.title,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                  color: _isHovered ? AppTheme.primaryText : AppTheme.primaryText.withValues(alpha: 0.9),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                widget.subtitle,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 11,
                                  color: _isHovered ? AppTheme.secondaryText : AppTheme.secondaryText.withValues(alpha: 0.7),
                                ),
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
    );
  }
}

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
    
    // Close the import dialog immediately to reveal the full-screen progress loader on the dashboard
    Navigator.pop(context);

    final notifier = ref.read(dashboardProvider.notifier);
    
    String? modelPath;
    if (!_useMock && selectedModel != null) {
      modelPath = p.join(AppDirs.support, 'models', 'ggml-${selectedModel!.name}.bin');
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
            content: Text(error ?? 'Import failed.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Import failed: $e'),
          backgroundColor: Colors.redAccent,
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
                ? AppTheme.accentOrange.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.015),
            borderRadius: 12,
            borderOpacity: isSelected ? 0.35 : (isSupported ? 0.08 : 0.02),
            glowColor: isSelected ? AppTheme.accentOrange : null,
            glowOpacity: isSelected ? 0.15 : 0.0,
          ).copyWith(
            border: Border.all(
              color: isSelected
                  ? AppTheme.accentOrange.withValues(alpha: 0.4)
                  : (isRecommended
                      ? AppTheme.accentCyan.withValues(alpha: 0.25)
                      : (isSupported ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.02))),
              width: isSelected ? 1.5 : 1.0,
            ),
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
                            color: isSelected ? AppTheme.accentOrange : Colors.white,
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
                            borderOpacity: 0.3,
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
                    style: const TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.w500),
                    maxLines: 2,
                  ),
                ),
                SizedBox(height: isCompactWidth ? 2 : 4),
                SizedBox(
                  height: isCompactWidth ? null : 32,
                  child: Text(
                    mode.getDetailsWithSystemInfo(hardwareInfo),
                    style: const TextStyle(fontSize: 8, color: Colors.white38),
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
                              style: const TextStyle(fontSize: 8, color: Colors.white30, fontFamily: 'monospace'),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (isDownloaded)
                            Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 12)
                          else if (isDownloading)
                            const SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 1.2, color: Colors.amber),
                            )
                          else
                            Icon(Icons.download_for_offline_outlined, color: Colors.white.withValues(alpha: 0.25), size: 12),
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
                            Expanded(
                              child: Text(
                                '${(downloadProgress.downloadProgress * 100).toInt()}%',
                                style: const TextStyle(fontSize: 8, color: Colors.white38),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (downloadProgress.eta != null)
                              Text(
                                '${downloadProgress.eta!.inSeconds}s',
                                style: const TextStyle(fontSize: 8, color: Colors.white38),
                              ),
                          ],
                        ),
                      ] else if (!isDownloaded) ...[
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
                                      logTag: 'ImportVideoDialog',
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
                'IMPORT NEW VIDEO',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.accentOrange,
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    style: TextStyle(fontSize: 13, color: AppTheme.primaryText),
                    decoration: InputDecoration(
                      labelText: 'Project Name',
                      border: AppTheme.defaultBorder(),
                      focusedBorder: AppTheme.focusedBorder(),
                      filled: true,
                      fillColor: AppTheme.cardBg,
                    ),
                  ),
                  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS) && _videoDuration != null && _videoDuration! > 7200) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AppTheme.glassDecoration(
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: 8,
                        borderOpacity: 0.15,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Warning: This video is over 2 hours. Transcription and video rendering on mobile devices may take a long time and drain battery. For large projects, the desktop version of CapStudio is recommended.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.amber.shade200,
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
                        color: Colors.amber.withValues(alpha: 0.08),
                        borderRadius: 8,
                        borderOpacity: 0.15,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'CapStudio Web limits: Running long video rendering in a browser sandbox is not supported. Subtitles will be mocked. For full GPU-accelerated video rendering, please use the desktop app.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.amber.shade200,
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
                            : Colors.white.withValues(alpha: 0.015),
                        borderRadius: 8,
                        borderOpacity: _selectedSubtitlePath != null ? 0.35 : 0.08,
                        glowColor: _selectedSubtitlePath != null ? AppTheme.accentCyan : null,
                        glowOpacity: _selectedSubtitlePath != null ? 0.15 : 0.0,
                      ).copyWith(
                        border: Border.all(
                          color: _selectedSubtitlePath != null
                              ? AppTheme.accentCyan.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.08),
                          width: _selectedSubtitlePath != null ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.subtitles_outlined,
                            color: _selectedSubtitlePath != null ? AppTheme.accentCyan : Colors.white38,
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
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Using external file (Whisper transcription will be skipped)',
                                        style: TextStyle(fontSize: 9, color: Colors.greenAccent),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'No subtitle file selected (.srt, .vtt)',
                                    style: TextStyle(fontSize: 11, color: Colors.white30),
                                  ),
                          ),
                          if (_selectedSubtitlePath != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 16, color: Colors.redAccent),
                              onPressed: () {
                                setState(() {
                                  _selectedSubtitlePath = null;
                                });
                              },
                            )
                          else
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white10,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                                textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () async {
                                try {
                                  final result = await FilePicker.pickFiles(
                                    dialogTitle: 'Select Subtitle File',
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
                              child: const Text('CHOOSE FILE'),
                            ),
                        ],
                      ),
                    ),
                    if (_selectedSubtitlePath == null) ...[
                      const SizedBox(height: 16),
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
                        initialValue: _selectedLanguage,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Transcription Language',
                          border: AppTheme.defaultBorder(),
                          focusedBorder: AppTheme.focusedBorder(),
                          filled: true,
                          fillColor: AppTheme.cardBg,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                        dropdownColor: AppTheme.cardBg,
                        items: [
                          const DropdownMenuItem(value: 'auto', child: Text('Auto Detect')),
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
                                Text('Translate captions to English', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryText)),
                                const SizedBox(height: 2),
                                Text('Convert foreign speech directly into English subtitles', style: TextStyle(fontSize: 9, color: AppTheme.mutedText)),
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
                            color: AppTheme.cardBg.withValues(alpha: 0.25),
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
                                    const Icon(Icons.speed, size: 12, color: Colors.white38),
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
                                    const Icon(Icons.developer_board, size: 12, color: Colors.white38),
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
                              const Divider(color: Colors.white10, height: 20),
                              WhisperThreadsSlider(
                                value: SettingsService.instance.whisperThreads,
                                onChanged: (v) => setState(() {
                                  SettingsService.instance.setWhisperThreads(v);
                                }),
                                usePremiumTheme: true,
                                valueStyle: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Voice Activity Detection (VAD)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                        const SizedBox(height: 2),
                                        Text('Skips silent regions during processing', style: TextStyle(fontSize: 9, color: AppTheme.mutedText)),
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
                                      style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                                    ),
                                    Expanded(
                                      child: SliderTheme(
                                        data: AppTheme.premiumSliderTheme(context).copyWith(
                                          inactiveTrackColor: Colors.white12,
                                        ),
                                        child: Slider(
                                          value: _vadThreshold,
                                          min: 0.0,
                                          max: 1.0,
                                          divisions: 20,
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
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: (_useMock || hasSelectedModelDownloaded)
                    ? () => _executeImport()
                    : null,
                child: const Text('CREATE PROJECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL', style: TextStyle(color: AppTheme.secondaryText, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
