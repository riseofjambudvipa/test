import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../../../app/theme.dart';
import '../../../../../app/theme_provider.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../core/settings/settings_service.dart';
import '../../../../../core/whisper/whisper_service.dart';
import '../../../../exporter/data/subtitle_exporter.dart';
import '../../../../exporter/presentation/widgets/export_progress_sheet.dart';
import '../../../../exporter/data/ffmpeg_exporter.dart';
import '../../controllers/editor_controller.dart';
import '../../../../../core/database/schemas/project.dart';
import '../../../../../core/utils/web_download_helper.dart';
import '../../../../../core/utils/web_wasm_bridge.dart';
import '../../../../../core/video/video_web_helper.dart';
import '../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../core/assets/asset_path_service.dart';
import 'export_panel/subtitle_export_section.dart';
import 'export_panel/project_bundle_card.dart';
import 'export_panel/audio_enhancement_card.dart';
import 'export_panel/auto_reframe_export_card.dart';

class ExportPanel extends ConsumerStatefulWidget {
  const ExportPanel({super.key});

  @override
  ConsumerState<ExportPanel> createState() => _ExportPanelState();
}

class _ExportPanelState extends ConsumerState<ExportPanel> {
  final _outputNameController = TextEditingController();
  String? _selectedDirectory;
  String _exportMode = 'fast';
  int _exportFps = 30;
  bool _isFastModeSupported = true;
  bool _enableStudioSound = false;
  AudioMasteringConfig _audioMastering = const AudioMasteringConfig();
  bool _enableAudioCrossfade = true;
  AspectConversionMode? _conversionMode;
  bool _hasInitializedReframe = false;
  BackgroundMusicConfig _backgroundMusic = const BackgroundMusicConfig();

  @override
  void initState() {
    super.initState();
    _backgroundMusic = ref.read(editorProvider).backgroundMusicConfig;
    if (!kIsWeb) {
      final defaultFolder = SettingsService.instance.outputFolder;
      if (defaultFolder != null && defaultFolder.isNotEmpty && Directory(defaultFolder).existsSync()) {
        _selectedDirectory = defaultFolder;
      } else {
        _initDefaultDirectory();
      }
      _checkFastModeSupport();
    }
  }

  Future<void> _initDefaultDirectory() async {
    final project = ref.read(editorProvider).project;
    if (project != null) {
      final dir = await _resolveDefaultExportDirectory(project);
      if (mounted && _selectedDirectory == null && dir.isNotEmpty) {
        setState(() {
          _selectedDirectory = dir;
        });
      }
    }
  }

  Future<String> _resolveDefaultExportDirectory(Project project) async {
    if (kIsWeb) return '';

    // 1. Explicit user setting in SettingsService
    final savedFolder = SettingsService.instance.outputFolder;
    if (savedFolder != null && savedFolder.trim().isNotEmpty && Directory(savedFolder).existsSync()) {
      return savedFolder;
    }

    // 2. Original video directory IF it's a real user video outside app demo/assets/temp
    final videoPath = project.videoPath;
    if (videoPath.isNotEmpty) {
      final normalized = videoPath.replaceAll('\\', '/').toLowerCase();
      final isInternal = normalized.contains('/assets/') ||
          normalized.contains('/demo/') ||
          normalized.contains('appdata') ||
          normalized.contains('/temp/') ||
          normalized.contains('/app_flutter/');
      if (!isInternal) {
        final dir = p.dirname(videoPath);
        if (Directory(dir).existsSync()) return dir;
      }
    }

    // 3. User's OS standard Videos, Downloads, or Documents directory
    try {
      if (!kIsWeb && Platform.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          final videos = p.join(userProfile, 'Videos');
          if (Directory(videos).existsSync()) return videos;
          final downloads = p.join(userProfile, 'Downloads');
          if (Directory(downloads).existsSync()) return downloads;
          final docs = p.join(userProfile, 'Documents');
          if (Directory(docs).existsSync()) return docs;
        }
      }
      final downloads = await getDownloadsDirectory();
      if (downloads != null && downloads.existsSync()) return downloads.path;
      final docs = await getApplicationDocumentsDirectory();
      return docs.path;
    } catch (_) {
      return '';
    }
  }

  String _getEffectiveOutputDir(Project project) {
    if (_selectedDirectory != null && _selectedDirectory!.isNotEmpty) {
      return _selectedDirectory!;
    }
    final videoPath = project.videoPath;
    if (!kIsWeb && videoPath.isNotEmpty) {
      final normalized = videoPath.replaceAll('\\', '/').toLowerCase();
      final isInternal = normalized.contains('/assets/') ||
          normalized.contains('/demo/') ||
          normalized.contains('appdata') ||
          normalized.contains('/temp/') ||
          normalized.contains('/app_flutter/');
      if (!isInternal) {
        return p.dirname(videoPath);
      }
    }
    if (!kIsWeb && Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null) {
        final videos = p.join(userProfile, 'Videos');
        if (Directory(videos).existsSync()) return videos;
        final downloads = p.join(userProfile, 'Downloads');
        if (Directory(downloads).existsSync()) return downloads;
      }
    }
    return '';
  }

  Future<void> _checkFastModeSupport() async {
    final exporter = FfmpegExporter();
    final isSupported = await exporter.isSubtitlesFilterSupported();
    if (mounted) {
      setState(() {
        _isFastModeSupported = isSupported;
        if (!isSupported) {
          _exportMode = 'slow';
        }
      });
    }
  }

  @override
  void dispose() {
    _outputNameController.dispose();
    super.dispose();
  }

  Future<void> _exportSubtitles(String type) async {
    final state = ref.read(editorProvider);
    final project = state.project;
    if (project == null) return;
    // Capture the localization object up front — it is safe to use after
    // await gaps because the object is locale-scoped, not element-scoped.
    final l10n = AppLocalizations.of(context)!;

    final defaultFileName = '${p.basenameWithoutExtension(project.name)}.$type';

    try {
      String content;
      if (type == 'srt') {
        content = SubtitleExporter.toSrt(project);
      } else if (type == 'vtt') {
        content = SubtitleExporter.toVtt(project);
      } else if (type == 'ass') {
        content = SubtitleExporter.toAss(project);
      } else {
        content = SubtitleExporter.toTxt(project);
      }

      if (kIsWeb) {
        downloadFileWeb(content, defaultFileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.exportSuccess(type.toUpperCase())),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
          LoggerService.instance.log(LogLevel.action, 'ExportPanel',
              'Exported $type via web download');
        }
        return;
      }

      final bytes = Uint8List.fromList(utf8.encode(content));

      // Save file path selector
      final result = await FilePicker.saveFile(
        dialogTitle: l10n.exportSubtitlesDialogTitle(type.toUpperCase()),
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: [type],
        bytes: bytes,
      );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.exportNoLocation),
            ),
          );
        }
        return;
      }

      // Only manually write files on desktop. On mobile, FilePicker writes the bytes parameter automatically.
      if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) {
        await SubtitleExporter.saveToFile(content, result);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportSuccess(type.toUpperCase())),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        LoggerService.instance
            .log(LogLevel.action, 'ExportPanel', 'Exported $type to $result');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportFailed('$e')),
            backgroundColor: AppTheme.accentRed,
          ),
        );
        LoggerService.instance
            .log(LogLevel.error, 'ExportPanel', 'Failed to export $type: $e');
      }
    }
  }

  Future<String?> _getMobileOutputPath(Project project, String format) async {
    if (kIsWeb) return null;
    if (Platform.isAndroid || Platform.isIOS) {
      final tempDir =
          Directory(p.join(AssetPathService.instance.tempDir, 'subtitles'));
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }
      return p.join(tempDir.path, '${project.name}.$format');
    }
    return null;
  }

  Future<void> _startVideoExport() async {
    final state = ref.read(editorProvider);
    final project = state.project;
    if (project == null) return;

    final visibleWords = project.words.where((w) => w.hidden != true).toList();
    if (visibleWords.isEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => PremiumBlurDialog(
          maxWidth: 380,
          glowColor: AppTheme.accentOrange,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.subtitles_off_rounded, color: AppTheme.accentOrange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'No Captions in Project',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'This project currently has 0 captions. If you export now, the exported video will contain NO burned-in subtitles.\n\nDo you want to export the raw video anyway, or cancel and add captions first?',
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Add Captions First', style: TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.cardBgElevated,
                      foregroundColor: AppTheme.secondaryText,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Export Without Captions'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      if (proceed != true) return;
      if (!mounted) return;
    }

    if (kIsWeb) {
      await _startVideoExportWeb(project);
      return;
    }

    final isMobile = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    String ffmpegPath = '';
    String outputFilePath = '';

    if (isMobile) {
      final mobilePath = await _getMobileOutputPath(project, 'mp4');
      if (mobilePath == null) return;

      final String baseName = _outputNameController.text.trim().isNotEmpty
          ? _outputNameController.text.trim()
          : '${p.basenameWithoutExtension(project.name)}_capped';

      final String cleanBaseName = baseName.endsWith('.mp4')
          ? baseName.substring(0, baseName.length - 4)
          : baseName;

      outputFilePath = p.join(p.dirname(mobilePath), '$cleanBaseName.mp4');
    } else {
      ffmpegPath = SettingsService.instance.ffmpegCliPath ??
          WhisperService.instance.ffmpegCliPath;
      // Accept bare command names (e.g. 'ffmpeg', 'ffmpeg.exe') that are
      // resolved via the system PATH at runtime. Only validate the filesystem
      // when the path contains a directory separator, indicating an absolute path.
      final looksLikeAbsolutePath =
          ffmpegPath.contains('/') || ffmpegPath.contains('\\');
      if (kIsWeb ||
          ffmpegPath.isEmpty ||
          (looksLikeAbsolutePath && !File(ffmpegPath).existsSync())) {
        _showFfmpegWarning();
        return;
      }

      final String outputDir = _getEffectiveOutputDir(project);
      final String baseName = _outputNameController.text.trim().isNotEmpty
          ? _outputNameController.text.trim()
          : '${p.basenameWithoutExtension(project.name)}_capped';

      final String cleanBaseName = baseName.endsWith('.mp4')
          ? baseName.substring(0, baseName.length - 4)
          : baseName;

      if (SettingsService.instance.alwaysAskExportPath) {
        final l10n = AppLocalizations.of(context)!;
        final result = await FilePicker.saveFile(
          dialogTitle: l10n.exportVideoDialogTitle,
          fileName: '$cleanBaseName.mp4',
          type: FileType.custom,
          allowedExtensions: ['mp4'],
          bytes: Uint8List(0),
        );
        if (result == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(l10n.exportNoLocationCancelled),
              ),
            );
          }
          return;
        }
        outputFilePath = result;
      } else {
        outputFilePath = p.join(outputDir, '$cleanBaseName.mp4');
      }
    }

    if (!mounted) return;
    unawaited(showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ExportProgressSheet(
          project: project,
          outputFilePath: outputFilePath,
          ffmpegPath: ffmpegPath,
          exportMode: _exportMode,
          exportFps: _exportFps,
          enableStudioSound: _enableStudioSound,
          audioMastering: _audioMastering,
          enableAudioCrossfade: _enableAudioCrossfade,
          progressBarConfig: ref.read(editorProvider).retentionBarConfig,
          conversionMode: _conversionMode,
          backgroundMusic: _backgroundMusic,
          bRollClips: ref.read(editorProvider).bRollClips,
        );
      },
    ));
  }

  void _showFfmpegWarning() {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (context) {
        return PremiumBlurDialog(
          maxWidth: 380,
          glowColor: AppTheme.accentOrange,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: AppTheme.accentOrange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.ffmpegRequiredTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                l10n.ffmpegRequiredBody,
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.okLabel,
                        style: TextStyle(color: AppTheme.secondaryText)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startVideoExportWeb(Project project) async {
    final l10n = AppLocalizations.of(context)!;
    double progress = 0.0;
    String status = 'Initializing...';

    BuildContext? dialogContext;
    unawaited(showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dCtx) {
        dialogContext = dCtx;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return PremiumBlurDialog(
              maxWidth: 400,
              glowColor: AppTheme.accentOrange,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.exportWebTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: progress,
                    color: AppTheme.accentOrange,
                    backgroundColor: AppTheme.dividerColor,
                  ),
                  const SizedBox(height: 16),
                  Text(status,
                      style: TextStyle(
                          color: AppTheme.secondaryText, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: AppTheme.accentOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ));

    try {
      final assContent = SubtitleExporter.toAss(project);

      final String baseName = _outputNameController.text.trim().isNotEmpty
          ? _outputNameController.text.trim()
          : '${p.basenameWithoutExtension(project.name)}_capped';
      final String cleanName =
          baseName.endsWith('.mp4') ? baseName : '$baseName.mp4';

      final optionsJson = jsonEncode({
        'trimStart': project.trimStart,
        'trimEnd': project.trimEnd,
        'duration': project.duration,
        'fileName': cleanName,
        'enableStudioSound': _enableStudioSound,
      });

      await WebWasmBridge.exportVideo(
        videoUrl: resolveWebVideoUrl(project.videoPath),
        assContent: assContent,
        optionsJson: optionsJson,
        onProgress: (p, s) {
          progress = p;
          status = s;
          if (mounted) {
            setState(() {});
          }
        },
      );

      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportWebSuccess(cleanName)),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      if (dialogContext != null && dialogContext!.mounted) {
        Navigator.pop(dialogContext!);
      }
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.exportWebFailed('$e')),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final project = ref.watch(editorProvider.select((s) => s.project));
    if (project == null) return const SizedBox.shrink();
    if (!_hasInitializedReframe) {
      _hasInitializedReframe = true;
      if (project.height > project.width) {
        _conversionMode = AspectConversionMode.blurPillarbox;
      }
    }
    final l10n = AppLocalizations.of(context)!;

    final defaultOutputDir = _getEffectiveOutputDir(project);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kIsWeb) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                borderRadius: 12,
                borderOpacity: 0.15,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppTheme.accentGreen,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.exportWebEnabled,
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // FIX (Issue #9, CapStudio 1.0 audit): the web export pipeline
            // (web/ffmpeg_web.js) only burns in subtitles — it does not
            // mount emoji or SFX files into ffmpeg.wasm's virtual
            // filesystem or composite them, unlike the native/mobile export
            // paths. That gap existed silently before this fix; this notice
            // makes it a documented, visible limitation instead so a user
            // who added emoji/SFX in the editor isn't surprised by their
            // absence in a web-exported file.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.1),
                borderRadius: 12,
                borderOpacity: 0.15,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: AppTheme.accentOrange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.exportWebCaptionOnly,
                      style: TextStyle(
                        color: AppTheme.primaryText,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
            _buildSectionHeader(l10n.exportBurnIn),
            const SizedBox(height: 8),
            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: 12,
              borderOpacity: 0.08,
              color: AppTheme.cardBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _outputNameController,
                    decoration: InputDecoration(
                      labelText: l10n.exportOutputName,
                      hintText:
                          '${p.basenameWithoutExtension(project.name)}_capped',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixText: '.mp4',
                    ),
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                    key: ValueKey(_exportMode),
                    initialValue: _exportMode,
                    decoration: InputDecoration(
                      labelText: l10n.exportMode,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    dropdownColor: AppTheme.cardBg,
                    items: [
                      DropdownMenuItem(
                        value: 'fast',
                        enabled: _isFastModeSupported,
                        child: Text(
                          _isFastModeSupported
                              ? l10n.exportModeFast
                              : l10n.exportModeFastUnsupported,
                          style: TextStyle(
                            color: _isFastModeSupported ? null : AppTheme.mutedText,
                          ),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'slow',
                        child: Text(l10n.exportModeSlow),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _exportMode = val;
                        });
                      }
                    },
                  ),
                  if (_exportMode == 'slow') ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _exportFps,
                      decoration: InputDecoration(
                        labelText: l10n.exportTargetFps,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      dropdownColor: AppTheme.cardBg,
                      items: [
                        DropdownMenuItem(
                            value: 24, child: Text(l10n.exportFps24)),
                        DropdownMenuItem(
                            value: 25, child: Text(l10n.exportFps25)),
                        DropdownMenuItem(
                            value: 30, child: Text(l10n.exportFps30)),
                        DropdownMenuItem(
                            value: 50, child: Text(l10n.exportFps50)),
                        DropdownMenuItem(
                            value: 60, child: Text(l10n.exportFps60)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _exportFps = val;
                          });
                        }
                      },
                    ),
                  ],
                  if (!_isFastModeSupported) ...[
                    const SizedBox(height: 12),
                    GlassContainer(
                      padding: const EdgeInsets.all(12),
                      borderRadius: 8,
                      borderOpacity: 0.15,
                      color: AppTheme.accentRed.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: AppTheme.accentRed, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.exportFastUnsupported,
                              style: TextStyle(
                                color: AppTheme.secondaryText,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_exportMode == 'slow') ...[
                    const SizedBox(height: 12),
                    GlassContainer(
                      padding: const EdgeInsets.all(12),
                      borderRadius: 8,
                      borderOpacity: 0.15,
                      color: AppTheme.accentOrange.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: AppTheme.accentOrange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.exportSlowInfo,
                              style: TextStyle(
                                color: AppTheme.secondaryText,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  ],
                  const SizedBox(height: 16),
                  AudioEnhancementCard(
                    enableStudioSound: _enableStudioSound,
                    onStudioSoundChanged: (val) {
                      setState(() {
                        _enableStudioSound = val;
                        _audioMastering = _audioMastering.copyWith(enableStudioSound: val);
                      });
                    },
                    audioMastering: _audioMastering,
                    onAudioMasteringChanged: (config) {
                      setState(() {
                        _audioMastering = config;
                        _enableStudioSound = config.enableStudioSound;
                      });
                    },
                    enableAudioCrossfade: _enableAudioCrossfade,
                    onAudioCrossfadeChanged: (val) {
                      setState(() {
                        _enableAudioCrossfade = val;
                      });
                    },
                    backgroundMusic: _backgroundMusic,
                    onBackgroundMusicChanged: (config) {
                      setState(() {
                        _backgroundMusic = config;
                      });
                      ref.read(editorProvider.notifier).setBackgroundMusicConfig(config);
                    },
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(height: 16),
                    AutoReframeExportCard(
                      selectedMode: _conversionMode,
                      onModeChanged: (mode) {
                        setState(() {
                          _conversionMode = mode;
                        });
                      },
                      isLandscapeProject: project.width > project.height,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.exportDestDirectory,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              kIsWeb
                                  ? l10n.exportDestBrowser
                                  : Platform.isAndroid
                                      ? l10n.exportDestAndroid
                                      : Platform.isIOS
                                          ? l10n.exportDestIos
                                          : defaultOutputDir,
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: AppTheme.secondaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!kIsWeb &&
                          !(Platform.isAndroid || Platform.isIOS)) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon:
                              const Icon(Icons.folder_open_outlined, size: 20),
                          tooltip: l10n.exportChooseFolder,
                          onPressed: () async {
                            final folder = await FilePicker.getDirectoryPath();
                            if (folder != null) {
                              setState(() {
                                _selectedDirectory = folder;
                              });
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.rocket_launch, size: 16),
                      label: Text(
                        l10n.exportStartMp4,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: AppTheme.onAccentText,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _startVideoExport,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          _buildSectionHeader(l10n.exportTimecodeFormats),
          const SizedBox(height: 8),
          SubtitleExportSection(
            project: project,
            onExportSubtitles: _exportSubtitles,
          ),
          const SizedBox(height: 12),
          ProjectBundleCard(project: project),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 9,
        fontWeight: FontWeight.bold,
        color: AppTheme.secondaryText,
        letterSpacing: 1.5,
      ),
    );
  }
}
