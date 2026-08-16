import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../../../app/theme.dart';
import '../../../../../app/theme_provider.dart';
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
import '../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../core/assets/asset_path_service.dart';

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

  @override
  void initState() {
    super.initState();
    // Default output directory is read from settings or the project video path's parent
    if (!kIsWeb) {
      final defaultFolder = SettingsService.instance.outputFolder;
      if (defaultFolder != null && Directory(defaultFolder).existsSync()) {
        _selectedDirectory = defaultFolder;
      }
      _checkFastModeSupport();
    }
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
              content: Text('${type.toUpperCase()} exported successfully!'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
          LoggerService.instance.log(LogLevel.action, 'ExportPanel', 'Exported $type via web download');
        }
        return;
      }

      final bytes = Uint8List.fromList(utf8.encode(content));

      // Save file path selector
      final result = await FilePicker.saveFile(
        dialogTitle: 'Export ${type.toUpperCase()} Subtitles',
        fileName: defaultFileName,
        type: FileType.custom,
        allowedExtensions: [type],
        bytes: bytes,
      );

      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No save location selected. Please choose a file path.'),
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
            content: Text('${type.toUpperCase()} exported successfully!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
        LoggerService.instance.log(LogLevel.action, 'ExportPanel', 'Exported $type to $result');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
        LoggerService.instance.log(LogLevel.error, 'ExportPanel', 'Failed to export $type: $e');
      }
    }
  }

  Future<String?> _getMobileOutputPath(Project project, String format) async {
    if (kIsWeb) return null;
    if (Platform.isAndroid || Platform.isIOS) {
      final tempDir = Directory(p.join(AssetPathService.instance.tempDir, 'subtitles'));
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
      ffmpegPath = SettingsService.instance.ffmpegCliPath ?? WhisperService.instance.ffmpegCliPath;
      // Accept bare command names (e.g. 'ffmpeg', 'ffmpeg.exe') that are
      // resolved via the system PATH at runtime. Only validate the filesystem
      // when the path contains a directory separator, indicating an absolute path.
      final looksLikeAbsolutePath = ffmpegPath.contains('/') || ffmpegPath.contains('\\');
      if (kIsWeb || ffmpegPath.isEmpty || (looksLikeAbsolutePath && !File(ffmpegPath).existsSync())) {
        _showFfmpegWarning();
        return;
      }

      final String outputDir = _selectedDirectory ?? (!kIsWeb && project.videoPath.isNotEmpty ? p.dirname(project.videoPath) : '');
      final String baseName = _outputNameController.text.trim().isNotEmpty
          ? _outputNameController.text.trim()
          : '${p.basenameWithoutExtension(project.name)}_capped';
      
      final String cleanBaseName = baseName.endsWith('.mp4') 
          ? baseName.substring(0, baseName.length - 4) 
          : baseName;

      if (SettingsService.instance.alwaysAskExportPath) {
        final result = await FilePicker.saveFile(
          dialogTitle: 'Export Video MP4',
          fileName: '$cleanBaseName.mp4',
          type: FileType.custom,
          allowedExtensions: ['mp4'],
          bytes: Uint8List(0),
        );
        if (result == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No save location selected. Export cancelled.'),
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
        );
      },
    ));
  }

  void _showFfmpegWarning() {
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
                  Icon(Icons.warning_amber_rounded, color: AppTheme.accentOrange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'FFmpeg Required',
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
                'A local installation of FFmpeg is required to burn subtitles into a video file.\n\nPlease configure the FFmpeg path in Settings.',
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('OK', style: TextStyle(color: AppTheme.secondaryText)),
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
                    'Exporting Video (Client-Side)',
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
                    backgroundColor: Colors.white12,
                  ),
                  const SizedBox(height: 16),
                  Text(status, style: TextStyle(color: AppTheme.secondaryText, fontSize: 12)),
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
      final String cleanName = baseName.endsWith('.mp4') ? baseName : '$baseName.mp4';
      
      final optionsJson = jsonEncode({
        'trimStart': project.trimStart,
        'trimEnd': project.trimEnd,
        'duration': project.duration,
        'fileName': cleanName,
      });

      await WebWasmBridge.exportVideo(
        videoUrl: project.videoPath,
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
            content: Text('Video exported successfully as $cleanName!'),
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
            content: Text('Rendering failed: $e'),
            backgroundColor: Colors.redAccent,
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

    final defaultOutputDir = _selectedDirectory ?? (!kIsWeb && project.videoPath.isNotEmpty ? p.dirname(project.videoPath) : '');

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
                      'Client-side video export is enabled. Rendering runs locally in your browser.',
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
                      'Web export currently includes captions only — emoji and sound effects are not yet burned into the video. Export from the desktop or mobile app for the full result.',
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
          ] else ...[
            _buildSectionHeader('BURN-IN VIDEO EXPORT'),
            const SizedBox(height: 8),

            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: 12,
              borderOpacity: 0.08,
              color: Colors.white.withValues(alpha: 0.02),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _outputNameController,
                    decoration: InputDecoration(
                      labelText: 'Output Video Name',
                      hintText: '${p.basenameWithoutExtension(project.name)}_capped',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      suffixText: '.mp4',
                    ),
                  ),
                  const SizedBox(height: 16),
 
                  DropdownButtonFormField<String>(
                    key: ValueKey(_exportMode),
                    initialValue: _exportMode,
                    decoration: const InputDecoration(
                      labelText: 'Export Mode',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    dropdownColor: AppTheme.cardBg,
                    items: [
                      DropdownMenuItem(
                        value: 'fast',
                        enabled: _isFastModeSupported,
                        child: Text(
                          _isFastModeSupported
                              ? 'Fast (Native FFmpeg)'
                              : 'Fast (Native FFmpeg) ⚠️ Unsupported',
                          style: TextStyle(
                            color: _isFastModeSupported ? null : Colors.white38,
                          ),
                        ),
                      ),
                      const DropdownMenuItem(
                        value: 'slow',
                        child: Text('Slow (1:1 Preview Render)'),
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
                      decoration: const InputDecoration(
                        labelText: 'Target FPS',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      dropdownColor: AppTheme.cardBg,
                      items: const [
                        DropdownMenuItem(value: 24, child: Text('24 FPS (Film)')),
                        DropdownMenuItem(value: 25, child: Text('25 FPS (PAL)')),
                        DropdownMenuItem(value: 30, child: Text('30 FPS (Standard)')),
                        DropdownMenuItem(value: 50, child: Text('50 FPS')),
                        DropdownMenuItem(value: 60, child: Text('60 FPS (Smooth)')),
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
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Fast Mode is not supported on this device because the system FFmpeg build lacks subtitle rendering filters (libass). Slow Mode will be used instead.',
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
                          Icon(Icons.info_outline, color: AppTheme.accentOrange, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Captures each frame exactly as shown in preview. This guarantees pixel-perfect captions, but renders slower.',
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
                  const SizedBox(height: 16),
 
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DESTINATION DIRECTORY',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryText,
                              ),
                            ),
                            const SizedBox(height: 4),
                             Text(
                              kIsWeb
                                  ? 'Browser Download Location'
                                  : Platform.isAndroid 
                                      ? 'Downloads folder (/storage/emulated/0/Download)'
                                      : Platform.isIOS
                                          ? 'Application Documents (Share Sheet after export)'
                                          : defaultOutputDir,
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!kIsWeb && !(Platform.isAndroid || Platform.isIOS)) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.folder_open_outlined, size: 20),
                          tooltip: 'Choose Output Folder',
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
                      label: const Text(
                        'START MP4 EXPORT',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _startVideoExport,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
          ],
          _buildSectionHeader('TIMECODE SUBTITLE FORMATS'),
          const SizedBox(height: 8),

          _buildSubtitleCard(
            title: 'SubRip Subtitles (.srt)',
            desc: 'Universal timecoded standard. Compatible with YouTube, VLC, and Premiere Pro.',
            icon: Icons.subtitles_outlined,
            color: AppTheme.accentCyan,
            onTap: () => _exportSubtitles('srt'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.copy_rounded, color: AppTheme.mutedText, size: 18),
                  tooltip: 'Copy SRT to clipboard',
                  splashRadius: 18,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () async {
                    final state = ref.read(editorProvider);
                    final project = state.project;
                    if (project == null) return;
                    try {
                      final content = SubtitleExporter.toSrt(project);
                      await Clipboard.setData(ClipboardData(text: content));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('SRT copied to clipboard!'),
                            backgroundColor: AppTheme.accentGreen,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to copy SRT: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: 12),
                Icon(Icons.download_rounded, color: AppTheme.mutedText, size: 18),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          _buildSubtitleCard(
            title: 'WebVTT Subtitles (.vtt)',
            desc: 'Web-optimized subtitle format widely used in HTML5 players and online streaming.',
            icon: Icons.html_outlined,
            color: AppTheme.accentPink,
            onTap: () => _exportSubtitles('vtt'),
          ),

          const SizedBox(height: 12),
          _buildSubtitleCard(
            title: 'Advanced SubStation Alpha (.ass)',
            desc: 'Professional format embedding font sizes, styles, margins, and inline highlights.',
            icon: Icons.style_outlined,
            color: AppTheme.accentOrange,
            onTap: () => _exportSubtitles('ass'),
          ),

          const SizedBox(height: 12),
          _buildSubtitleCard(
            title: 'Plain Text Transcript (.txt)',
            desc: 'Line-by-line transcript with timestamp prefix markers.',
            icon: Icons.notes_outlined,
            color: AppTheme.accentGreen,
            onTap: () => _exportSubtitles('txt'),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitleCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GlassContainer(
      borderRadius: 10,
      borderOpacity: 0.08,
      color: AppTheme.cardBg.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: AppTheme.glassDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: 8,
                  borderOpacity: 0.2,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      desc,
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.secondaryText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              trailing ?? Icon(Icons.download_rounded, color: AppTheme.mutedText, size: 18),
            ],
          ),
        ),
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
