import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import '../../../../app/theme.dart';
import '../../../../core/database/schemas/project.dart';
import '../../../../core/logger/logger_service.dart';
import '../../../editor/domain/caption_engine.dart';
import '../../../editor/presentation/widgets/caption_overlay.dart';
import '../../../editor/presentation/widgets/retention_progress_bar_overlay.dart';
import '../../../../core/video/retention_progress_bar_models.dart';
import '../../../../core/video/b_roll_models.dart' show BRollClip;
import '../../data/ffmpeg_exporter.dart';
import '../../../../core/utils/share_service.dart';
import '../../../../core/assets/asset_path_service.dart';
import '../../../../l10n/app_localizations.dart';

class ExportProgressSheet extends StatefulWidget {
  final Project project;
  final String outputFilePath;
  final String ffmpegPath;
  final String exportMode;
  final int exportFps;
  final bool enableStudioSound;
  final AudioMasteringConfig? audioMastering;
  final bool enableAudioCrossfade;
  final RetentionProgressBarConfig? progressBarConfig;
  final AspectConversionMode? conversionMode;
  final BackgroundMusicConfig? backgroundMusic;
  final List<BRollClip>? bRollClips;

  const ExportProgressSheet({
    super.key,
    required this.project,
    required this.outputFilePath,
    required this.ffmpegPath,
    this.exportMode = 'fast',
    this.exportFps = 30,
    this.enableStudioSound = false,
    this.audioMastering,
    this.enableAudioCrossfade = true,
    this.progressBarConfig,
    this.conversionMode,
    this.backgroundMusic,
    this.bRollClips,
  });

  @override
  State<ExportProgressSheet> createState() => _ExportProgressSheetState();
}

class _ExportProgressSheetState extends State<ExportProgressSheet> {
  late final FfmpegExporter _exporter;
  StreamSubscription<ExportProgress>? _subscription;
  late final List<Chunk> _chunks;

  double _progress = 0.0;
  String _statusText = 'Initializing...';
  String _statusMessage = 'Preparing export pipeline...';
  String? _errorMessage;
  
  // Timer state
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  String _elapsedStr = '00:00';
  String _etaStr = 'Calculating...';

  // Slow export state
  final GlobalKey _repaintKey = GlobalKey();
  double _exportCurrentTime = 0.0;
  double _exportRelativeTime = 0.0;
  double _exportTotalDuration = 0.0;

  @override
  void initState() {
    super.initState();
    _exporter = FfmpegExporter();
    _exporter.configureCli(widget.ffmpegPath);
    try {
      _chunks = CaptionEngine.buildChunks(
        widget.project.words,
        widget.project.segments,
        widget.project.trimStart,
        widget.project.trimEnd,
        widget.project.config.subs.chunkSize,
        widget.project.config.subs.chunkLineMaxLength,
      );
    } catch (e) {
      // Malformed project data must not crash the sheet before any error UI
      // exists — surface the failure instead of throwing from initState.
      LoggerService.instance.log(LogLevel.error, 'ExportProgressSheet', 'Failed to build caption chunks: $e');
      _statusText = 'failed';
      _statusMessage = 'Export failed to initialize';
      _errorMessage = e.toString();
      return;
    }

    _startTimer();
    _startExport();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    // Cancel any in-flight FFmpeg process so a dispose outside the explicit
    // cancel path (route teardown, hot reload) doesn't leave an orphaned
    // child process writing the output file.
    _exporter.cancelExport();
    super.dispose();
  }

  void _startTimer() {
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      
      final elapsed = _stopwatch.elapsed;
      final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
      final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
      
      setState(() {
        _elapsedStr = '$minutes:$seconds';
        
        // Calculate ETA based on progress rate
        if (_progress > 0.05 && _progress < 1.0) {
          final totalEstSeconds = (elapsed.inSeconds / _progress).round();
          final remainingSeconds = totalEstSeconds - elapsed.inSeconds;
          if (remainingSeconds > 0) {
            final etaMins = (remainingSeconds ~/ 60).toString().padLeft(2, '0');
            final etaSecs = (remainingSeconds % 60).toString().padLeft(2, '0');
            _etaStr = '$etaMins:$etaSecs';
          } else {
            _etaStr = 'Finalizing...';
          }
        } else {
          _etaStr = 'Calculating...';
        }
      });
    });
  }

  Future<Uint8List?> _renderFrame(
    double time, {
    double? relativeTime,
    double? exportDuration,
  }) async {
    if (!mounted) return null;
    setState(() {
      _exportCurrentTime = time;
      _exportRelativeTime = relativeTime ?? time;
      if (exportDuration != null && exportDuration > 0) {
        _exportTotalDuration = exportDuration;
      }
    });
    
    await WidgetsBinding.instance.endOfFrame;
    
    try {
      final boundary = _repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return byteData?.buffer.asUint8List();
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'ExportProgressSheet', 'Failed to capture frame at $time: $e');
      return null;
    }
  }

  void _startExport() {
    final String? tempDir;
    try {
      tempDir = AssetPathService.instance.tempDir;
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'ExportProgressSheet', 'Failed to resolve temp directory: $e');
      setState(() {
        _statusText = 'failed';
        _statusMessage = 'Export failed to initialize';
        _errorMessage = e.toString();
      });
      return;
    }

    final stream = widget.exportMode == 'slow'
        ? _exporter.exportVideoSlow(
            project: widget.project,
            chunks: _chunks,
            outputFilePath: widget.outputFilePath,
            tempDir: tempDir,
            fps: widget.exportFps,
            renderFrame: _renderFrame,
            conversionMode: widget.conversionMode,
            enableStudioSound: widget.enableStudioSound,
            audioMastering: widget.audioMastering,
            enableAudioCrossfade: widget.enableAudioCrossfade,
            progressBarConfig: widget.progressBarConfig,
            backgroundMusic: widget.backgroundMusic,
            bRollClips: widget.bRollClips,
          )
        : _exporter.exportVideo(
            project: widget.project,
            chunks: _chunks,
            outputFilePath: widget.outputFilePath,
            tempDir: tempDir,
            conversionMode: widget.conversionMode,
            enableStudioSound: widget.enableStudioSound,
            audioMastering: widget.audioMastering,
            enableAudioCrossfade: widget.enableAudioCrossfade,
            progressBarConfig: widget.progressBarConfig,
            backgroundMusic: widget.backgroundMusic,
            bRollClips: widget.bRollClips,
          );

    _subscription = stream.listen(
      (event) {
        if (!mounted) return;
        setState(() {
          _progress = event.progress;
          _statusText = event.status;
          
          // Map progress value to premium descriptive status messages
          if (_progress <= 0.05) {
            _statusMessage = 'Preparing export pipeline...';
          } else if (_progress <= 0.30) {
            _statusMessage = 'Rendering subtitle text overlays...';
          } else if (_progress <= 0.80) {
            _statusMessage = 'Burning karaoke styled captions via FFmpeg...';
          } else if (_progress <= 0.95) {
            final hasBgm = widget.backgroundMusic != null && widget.backgroundMusic!.hasMusic;
            final isStudio = widget.enableStudioSound || (widget.audioMastering?.enableStudioSound ?? false);
            _statusMessage = hasBgm
                ? 'Mixing background music, ducking & voiceover...'
                : (isStudio
                    ? 'Mastering ${widget.audioMastering?.platform.label ?? "studio"} voice track...'
                    : 'Mixing audio tracks and sound effects...');
          } else if (_progress < 1.0) {
            _statusMessage = 'Finalizing output container file...';
          } else {
            _statusMessage = 'Export complete!';
          }

          if (_statusText == 'failed') {
            _errorMessage = event.error ?? 'Unknown export error occurred.';
            _stopTimer(failed: true);
          } else if (_statusText == 'completed' || _progress >= 1.0) {
            _stopTimer(failed: false);
          }
        });
      },
      onError: (Object err) {
        if (!mounted) return;
        setState(() {
          _statusText = 'failed';
          _statusMessage = 'Export crashed!';
          _errorMessage = err.toString();
          _stopTimer(failed: true);
        });
      },
      onDone: () {
        if (!mounted) return;
        if (_statusText != 'completed' && _statusText != 'failed') {
          setState(() {
            _statusText = 'failed';
            _statusMessage = 'Export ended unexpectedly.';
            _errorMessage = 'The export process ended without a final status. The output file may be incomplete.';
          });
          _stopTimer(failed: true);
        }
      },
    );
  }

  void _stopTimer({required bool failed}) {
    _stopwatch.stop();
    _timer?.cancel();
    if (!failed) {
      String sizeStr = '';
      try {
        final file = File(widget.outputFilePath);
        if (file.existsSync()) {
          final sizeBytes = file.lengthSync();
          final sizeMb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
          sizeStr = ' ($sizeMb MB)';
          
          if (Platform.isAndroid) {
            _saveToAndroidGallery(widget.outputFilePath);
          } else if (Platform.isIOS) {
            _saveToIosCameraRoll(widget.outputFilePath);
          }
        }
      } catch (e) {
        LoggerService.instance.log(LogLevel.error, 'ExportProgress', 'Failed to verify/save exported file: $e');
      }

      setState(() {
        _progress = 1.0;
        _statusMessage = 'Export complete!$sizeStr';
        _etaStr = '00:00';
      });
    }
  }

  Future<void> _saveToAndroidGallery(String filePath) async {
    try {
      final name = p.basename(filePath);
      const channel = MethodChannel('com.capstudio/native');
      await channel.invokeMethod('saveVideoToGallery', {
        'path': filePath,
        'name': name,
      });
      LoggerService.instance.log(LogLevel.action, 'ExportProgressSheet', 'Android export successfully copied to gallery: $name');
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'ExportProgressSheet', 'Failed to copy Android export to gallery: $e');
    }
  }

  Future<void> _saveToIosCameraRoll(String filePath) async {
    try {
      const channel = MethodChannel('com.capstudio/native');
      await channel.invokeMethod('saveVideoToGallery', {
        'path': filePath,
      });
      LoggerService.instance.log(LogLevel.action, 'ExportProgressSheet', 'iOS export successfully saved to Camera Roll: $filePath');
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'ExportProgressSheet', 'Failed to save iOS export to Camera Roll: $e');
    }
  }

  void _cancelExport() {
    _subscription?.cancel();
    _subscription = null;
    _timer?.cancel();
    _timer = null;
    _stopwatch.stop();
    _exporter.cancelExport();
    Navigator.pop(context, false);
  }

  Future<void> _openOutputFolder() async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS) {
      return; // Opening local folders is not supported on web or mobile
    }
    try {
      final absPath = p.absolute(widget.outputFilePath);
      final file = File(absPath);

      if (Platform.isWindows) {
        final winPath = absPath.replaceAll('/', '\\');
        if (file.existsSync()) {
          await Process.run('explorer.exe', ['/select,', winPath]);
        } else {
          final parentDir = Directory(p.dirname(winPath));
          if (!parentDir.existsSync()) {
            try {
              parentDir.createSync(recursive: true);
            } catch (_) {}
          }
          await Process.run('explorer.exe', [parentDir.path]);
        }
      } else if (Platform.isMacOS) {
        // Reveal the exported video file in Finder (highlights it)
        if (file.existsSync()) {
          await Process.run('open', ['-R', absPath]);
        } else {
          await Process.run('open', [p.dirname(absPath)]);
        }
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [file.parent.path]);
      } else {
        await Process.run('open', [file.parent.path]);
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'ExportProgressSheet', 'Failed to open output directory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isDone = _statusText == 'completed' || _progress >= 1.0;
    final isFailed = _statusText == 'failed';
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final double verticalSpacing = isLandscape ? 12.0 : 24.0;
    
    return PopScope(
      canPop: isDone || isFailed, // Prevent close unless complete or failed
      child: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: EdgeInsets.all(isLandscape ? 16.0 : 24.0),
              decoration: AppTheme.glassDecoration(
                color: AppTheme.cardBg.withValues(alpha: 0.55),
                borderRadius: 20,
                borderOpacity: 0.0,
              ).copyWith(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(color: AppTheme.borderGlass, width: 1),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isDone 
                              ? 'EXPORT COMPLETE' 
                              : isFailed 
                                  ? 'EXPORT FAILED' 
                                  : 'EXPORTING VIDEO',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: isFailed 
                                ? AppTheme.accentRed 
                                : isDone 
                                    ? AppTheme.accentGreen 
                                    : AppTheme.accentOrange,
                          ),
                        ),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryText,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: verticalSpacing),
                    
                    // Progress Bar / Circular
                    if (!isFailed) ...[
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: AppTheme.borderGlass,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDone ? AppTheme.accentGreen : AppTheme.accentOrange,
                        ),
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      SizedBox(height: isLandscape ? 8.0 : 16.0),
                    ],
                    
                    // Status and Messages
                    Text(
                      _statusMessage,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    if (isFailed && _errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        constraints: BoxConstraints(
                          maxHeight: isLandscape ? 90.0 : 130.0,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: AppTheme.glassDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: 8,
                          borderOpacity: 0.12,
                        ).copyWith(
                          border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.error_outline_rounded, color: AppTheme.accentRed, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Error Log',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.accentRed,
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: _errorMessage!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Error copied to clipboard!'),
                                        backgroundColor: AppTheme.accentGreen,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(4),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.copy_rounded, size: 12, color: AppTheme.mutedText),
                                        const SizedBox(width: 4),
                                        Text('Copy', style: TextStyle(fontSize: 10, color: AppTheme.mutedText)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Expanded(
                              child: SingleChildScrollView(
                                child: SelectableText(
                                  _errorMessage!,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: AppTheme.accentRed,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: verticalSpacing),
                    
                    // Metrics row (Elapsed / ETA)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricColumn('Elapsed Time', _elapsedStr, theme),
                        _buildMetricColumn('Estimated Remaining (ETA)', isDone ? '00:00' : isFailed ? '--:--' : _etaStr, theme),
                      ],
                    ),
                    SizedBox(height: isLandscape ? 16.0 : 32.0),
                    
                    // Action Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!isDone && !isFailed)
                          ElevatedButton(
                            onPressed: _cancelExport,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentRed.withValues(alpha: 0.15),
                              foregroundColor: AppTheme.accentRed,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Cancel Export', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        if (isDone) ...[
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Close window', style: TextStyle(color: AppTheme.secondaryText)),
                          ),
                          const SizedBox(width: 12),
                          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS))
                            ElevatedButton.icon(
                              onPressed: () async {
                                try {
                                  await ShareService.shareFile(widget.outputFilePath, mimeType: 'video/mp4');
                                } catch (e) {
                                  LoggerService.instance.log(LogLevel.error, 'ExportProgressSheet', 'Failed to share exported video: $e');
                                }
                              },
                              icon: const Icon(Icons.share, size: 16),
                              label: Text(l10n?.shareVideo ?? 'Share Video'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.15),
                                foregroundColor: AppTheme.accentOrange,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: _openOutputFolder,
                              icon: const Icon(Icons.folder_open_outlined, size: 16),
                              label: Text(l10n?.openOutputFolder ?? 'Open output folder'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentGreen.withValues(alpha: 0.15),
                                foregroundColor: AppTheme.accentGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                        ],
                        if (isFailed) ...[
                          OutlinedButton.icon(
                            onPressed: () {
                              final textToCopy = _errorMessage?.isNotEmpty == true
                                  ? _errorMessage!
                                  : _statusMessage;
                              Clipboard.setData(ClipboardData(text: textToCopy));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Error log copied to clipboard!'),
                                  backgroundColor: AppTheme.accentGreen,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 16),
                            label: const Text('Copy Error to Clipboard'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.accentRed,
                              side: BorderSide(color: AppTheme.accentRed.withValues(alpha: 0.4)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context, false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.cardBgElevated,
                              foregroundColor: AppTheme.primaryText,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Close'),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.exportMode == 'slow' && !isDone && !isFailed)
            Positioned(
              left: -20000,
              top: -20000,
              child: RepaintBoundary(
                key: _repaintKey,
                child: Container(
                  width: (widget.conversionMode != null && widget.project.width > widget.project.height)
                      ? 1080.0
                      : widget.project.width.toDouble(),
                  height: (widget.conversionMode != null && widget.project.width > widget.project.height)
                      ? 1920.0
                      : widget.project.height.toDouble(),
                  color: Colors.transparent,
                  child: Stack(
                    children: [
                      if (widget.progressBarConfig != null)
                        RetentionProgressBarOverlay(
                          currentTime: _exportRelativeTime,
                          duration: _exportTotalDuration > 0
                              ? _exportTotalDuration
                              : widget.project.duration,
                          config: widget.progressBarConfig!,
                          scale: ((widget.conversionMode != null && widget.project.width > widget.project.height)
                                  ? 1920.0
                                  : widget.project.height.toDouble()) /
                              640.0,
                        ),
                      CaptionOverlay(
                        chunks: _chunks,
                        currentTime: _exportCurrentTime,
                        config: widget.project.config,
                        scale: ((widget.conversionMode != null && widget.project.width > widget.project.height)
                                ? 1920.0
                                : widget.project.height.toDouble()) /
                            640.0,
                        allowDrag: false,
                        videoWidth: (widget.conversionMode != null && widget.project.width > widget.project.height)
                            ? 1080.0
                            : widget.project.width.toDouble(),
                        videoHeight: (widget.conversionMode != null && widget.project.width > widget.project.height)
                            ? 1920.0
                            : widget.project.height.toDouble(),
                        isExporting: true,
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

  Widget _buildMetricColumn(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.secondaryText)),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.w900,
            color: AppTheme.primaryText,
          ),
        ),
      ],
    );
  }
}
