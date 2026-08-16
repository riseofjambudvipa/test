import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../../../../app/theme.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../core/settings/settings_service.dart';
import '../../../../../core/utils/executable_validator.dart';
import '../../../../../core/downloader/binary_downloader_service.dart';
import '../../../../settings/presentation/views/manual_install_banner.dart';

class ToolsSetupStep extends ConsumerStatefulWidget {
  final VoidCallback onContinue;
  final VoidCallback onSkip;

  const ToolsSetupStep({
    super.key,
    required this.onContinue,
    required this.onSkip,
  });

  @override
  ConsumerState<ToolsSetupStep> createState() => _ToolsSetupStepState();
}

class _ToolsSetupStepState extends ConsumerState<ToolsSetupStep> {
  final _whisperController = TextEditingController();
  final _ffmpegController = TextEditingController();

  bool? _whisperValid;
  bool? _ffmpegValid;
  bool _validatingWhisper = false;
  bool _validatingFfmpeg = false;
  ManualInstallRequiredException? _whisperManualException;

  @override
  void initState() {
    super.initState();
    _whisperController.text = SettingsService.instance.whisperCliPath ?? '';
    _ffmpegController.text = SettingsService.instance.ffmpegCliPath ?? '';
  }

  @override
  void dispose() {
    _whisperController.dispose();
    _ffmpegController.dispose();
    super.dispose();
  }

  Future<void> _pickFile(TextEditingController controller, String title) async {
    try {
      final result = await FilePicker.pickFiles(dialogTitle: title, type: FileType.any);
      if (!mounted) return;
      if (result != null && result.files.single.path != null) {
        setState(() {
          controller.text = result.files.single.path!;
          if (controller == _whisperController) _whisperValid = null;
          if (controller == _ffmpegController) _ffmpegValid = null;
        });
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'ToolsSetupStep', 'Failed to pick file: $e');
    }
  }

  Future<bool> _validateExecutable(String path, List<String> args) async {
    return validateExecutable(
      path,
      args,
      onAvxDetected: () async {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Missing AVX support detected! Downloading compatible whisper-cli (no-AVX)...'),
            backgroundColor: Colors.orangeAccent,
            duration: Duration(seconds: 5),
          ),
        );
        unawaited(downloadNoAvxWhisperAndRevalidate(
          onPathResolved: (resolvedPath) {
            if (!mounted) return;
            _whisperController.text = resolvedPath;
          },
          revalidate: _validateWhisper,
        ));
      },
    );
  }

  Future<void> _validateWhisper() async {
    if (!mounted) return;
    setState(() => _validatingWhisper = true);
    final ok = await _validateExecutable(_whisperController.text.trim(), ['--help']);
    if (mounted) {
      setState(() {
        _validatingWhisper = false;
        _whisperValid = ok;
      });
    }
  }

  Future<void> _validateFfmpeg() async {
    if (!mounted) return;
    setState(() => _validatingFfmpeg = true);
    final ok = await _validateExecutable(_ffmpegController.text.trim(), ['-version']);
    if (mounted) {
      setState(() {
        _validatingFfmpeg = false;
        _ffmpegValid = ok;
      });
    }
  }

  Future<void> _autoDetectWhisper() async {
    if (kIsWeb) return;
    setState(() => _validatingWhisper = true);
    final isWin = Platform.isWindows;
    final exeName = isWin ? 'whisper-cli.exe' : 'whisper-cli';

    final pathsToSearch = [
      p.join(Directory.current.path, 'assets', 'bin', exeName),
      p.join(Directory.current.path, 'Capstudio Flutter', 'assets', 'bin', exeName),
      p.join(Platform.environment['USERPROFILE'] ?? '', 'AppData', 'Local', 'Programs', 'whisper.cpp', exeName),
      p.join('C:\\Program Files', 'whisper.cpp', exeName),
      p.join('/usr', 'local', 'bin', exeName),
      p.join('/usr', 'bin', exeName),
      exeName
    ];

    String? foundPath;
    for (final path in pathsToSearch) {
      if (path == exeName) {
        final ok = await _validateExecutable(path, ['--help']);
        if (ok) {
          foundPath = path;
          break;
        }
      } else if (File(path).existsSync()) {
        final ok = await _validateExecutable(path, ['--help']);
        if (ok) {
          foundPath = path;
          break;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _validatingWhisper = false;
      if (foundPath != null) {
        _whisperController.text = foundPath;
        _whisperValid = true;
      } else {
        _whisperValid = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not auto-detect whisper-cli. Please browse manually.')),
        );
      }
    });
  }

  Future<void> _autoDetectFfmpeg() async {
    if (kIsWeb) return;
    setState(() => _validatingFfmpeg = true);
    final isWin = Platform.isWindows;
    final exeName = isWin ? 'ffmpeg.exe' : 'ffmpeg';

    final pathsToSearch = [
      p.join(Directory.current.path, 'assets', 'bin', exeName),
      p.join(Directory.current.path, 'Capstudio Flutter', 'assets', 'bin', exeName),
      p.join('C:\\ffmpeg', 'bin', exeName),
      exeName
    ];

    String? foundPath;
    for (final path in pathsToSearch) {
      if (path == exeName) {
        final ok = await _validateExecutable(path, ['-version']);
        if (ok) {
          foundPath = path;
          break;
        }
      } else if (File(path).existsSync()) {
        final ok = await _validateExecutable(path, ['-version']);
        if (ok) {
          foundPath = path;
          break;
        }
      }
    }

    if (!mounted) return;
    setState(() {
      _validatingFfmpeg = false;
      if (foundPath != null) {
        _ffmpegController.text = foundPath;
        _ffmpegValid = true;
      } else {
        _ffmpegValid = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not auto-detect ffmpeg. Please browse manually.')),
        );
      }
    });
  }

  Future<void> _runValidation() async {
    if (!mounted) return;
    setState(() {
      _validatingWhisper = true;
      _validatingFfmpeg = true;
    });

    final whisperOk = _whisperController.text.isNotEmpty 
        ? await _validateExecutable(_whisperController.text, ['--help'])
        : false;
    final ffmpegOk = _ffmpegController.text.isNotEmpty 
        ? await _validateExecutable(_ffmpegController.text, ['-version'])
        : false;

    if (!mounted) return;
    setState(() {
      _validatingWhisper = false;
      _validatingFfmpeg = false;
      if (_whisperController.text.isNotEmpty) _whisperValid = whisperOk;
      if (_ffmpegController.text.isNotEmpty) _ffmpegValid = ffmpegOk;
    });
  }

  Future<void> _saveAndContinue() async {
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await SettingsService.instance.setWhisperCliPath('');
      await SettingsService.instance.setFfmpegCliPath('');
    } else {
      await SettingsService.instance.setWhisperCliPath(_whisperController.text.trim());
      await SettingsService.instance.setFfmpegCliPath(_ffmpegController.text.trim());
    }
    widget.onContinue();
  }

  Widget _buildPathField({
    required String toolId,
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool? isValid,
    required bool isValidating,
    required VoidCallback onBrowse,
    required VoidCallback onAutoDetect,
  }) {
    return StreamBuilder<BinaryDownloadProgress>(
      stream: BinaryDownloaderService.instance.stream(toolId),
      initialData: BinaryDownloadProgress(toolId: toolId, status: BinaryDownloadStatus.idle),
      builder: (context, snapshot) {
        final progress = snapshot.data!;
        final isDownloading = progress.status == BinaryDownloadStatus.downloading;
        final isExtracting = progress.status == BinaryDownloadStatus.extracting;
        final isVerifying = progress.status == BinaryDownloadStatus.verifying;
        final isFailed = progress.status == BinaryDownloadStatus.failed;
        final isWorking = isDownloading || isExtracting || isVerifying;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70, fontSize: 12)),
                if (!isWorking && (isValid != true || isFailed))
                  TextButton.icon(
                    onPressed: () {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      setState(() => _whisperManualException = null);
                      BinaryDownloaderService.instance.download(toolId).then((_) {
                        if (!mounted) return;
                        if (toolId == 'ffmpeg') {
                          _ffmpegController.text = SettingsService.instance.ffmpegCliPath ?? '';
                          _validateFfmpeg();
                        } else {
                          _whisperController.text = SettingsService.instance.whisperCliPath ?? '';
                          _validateWhisper();
                        }
                      }).catchError((Object e) {
                        if (mounted) {
                          if (e is ManualInstallRequiredException) {
                            setState(() => _whisperManualException = e);
                          } else {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(content: Text('Failed to download tool: $e'), backgroundColor: Colors.redAccent),
                            );
                          }
                        }
                      });
                    },
                    icon: Icon(Icons.download_for_offline, size: 14, color: AppTheme.accentOrange),
                    label: Text(
                      'AUTO DOWNLOAD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentOrange,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (isWorking) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.glassDecoration(
                  color: AppTheme.cardBg.withValues(alpha: 0.2),
                  borderRadius: 8,
                  borderOpacity: 0.06,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          progress.label,
                          style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                        ),
                        if (progress.speedBytesPerSec > 0 && isDownloading)
                          Text(
                            '${(progress.speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s',
                            style: const TextStyle(fontSize: 10, color: Colors.white30, fontFamily: 'monospace'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress.overall,
                      backgroundColor: Colors.white10,
                      color: AppTheme.accentOrange,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      style: const TextStyle(fontSize: 12, color: Colors.white70),
                      decoration: InputDecoration(
                        hintText: hint,
                        filled: true,
                        fillColor: Colors.black26,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: isValid == null
                            ? null
                            : Icon(
                                isValid ? Icons.check_circle_outline : Icons.error_outline,
                                color: isValid ? Colors.greenAccent : Colors.redAccent,
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.folder_open), onPressed: onBrowse, tooltip: 'Browse'),
                  IconButton(
                    icon: isValidating
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white60))
                        : const Icon(Icons.flash_on_outlined),
                    onPressed: onAutoDetect,
                    tooltip: 'Auto-detect & Validate',
                  ),
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('step_setup'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Connect Local CLI Tools',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'CapStudio needs whisper.cpp and FFmpeg binaries to perform transcription and export videos locally.',
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.secondaryText),
        ),
        const SizedBox(height: 24),
        
        _buildPathField(
          toolId: 'whisper',
          controller: _whisperController,
          label: 'Whisper CLI Executable Path',
          hint: 'e.g. A:/Capstudio/assets/bin/whisper-cli.exe',
          isValid: _whisperValid,
          isValidating: _validatingWhisper,
          onBrowse: () => _pickFile(_whisperController, 'Select whisper-cli executable'),
          onAutoDetect: _autoDetectWhisper,
        ),
        const SizedBox(height: 20),
        
        _buildPathField(
          toolId: 'ffmpeg',
          controller: _ffmpegController,
          label: 'FFmpeg CLI Executable Path',
          hint: 'e.g. A:/ffmpeg/bin/ffmpeg.exe',
          isValid: _ffmpegValid,
          isValidating: _validatingFfmpeg,
          onBrowse: () => _pickFile(_ffmpegController, 'Select FFmpeg executable'),
          onAutoDetect: _autoDetectFfmpeg,
        ),
        if (_whisperManualException != null) ...[
          const SizedBox(height: 20),
          ManualInstallBanner(exception: _whisperManualException!),
        ],
        const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: widget.onSkip,
              child: const Text('Skip setup for now', style: TextStyle(color: Colors.white30)),
            ),
            Row(
              children: [
                if (_whisperController.text.isNotEmpty || _ffmpegController.text.isNotEmpty)
                  ElevatedButton(
                    onPressed: _runValidation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white10,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Validate'),
                  ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ],
        ),
      ],
    ).animate().fade(duration: 300.ms);
  }
}
