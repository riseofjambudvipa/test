import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../core/settings/settings_service.dart';
import '../../../../../core/utils/executable_validator.dart';
import '../../../../../core/downloader/binary_downloader_service.dart';
import '../../../../../core/ffmpeg/ffmpeg_locator.dart';
import '../../../../../core/whisper/whisper_locator.dart';
import '../../../../../l10n/app_localizations.dart';
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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.warningNoAvx ??
                  'Missing AVX support detected! Downloading compatible whisper-cli (no-AVX)...',
            ),
            backgroundColor: AppTheme.accentOrange,
            duration: const Duration(seconds: 5),
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

    final resolved = WhisperLocator.instance.resolve();
    String? foundPath;

    // Check resolved path if it exists or validate it
    if (resolved != 'whisper-cli' && resolved != 'whisper-cli.exe') {
      if (File(resolved).existsSync() && await _validateExecutable(resolved, ['--help'])) {
        foundPath = resolved;
      }
    }

    // Fallback: check exeName directly on PATH
    if (foundPath == null) {
      final exeName = Platform.isWindows ? 'whisper-cli.exe' : 'whisper-cli';
      if (await _validateExecutable(exeName, ['--help'])) {
        foundPath = exeName;
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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.errorAutoDetectWhisper ??
                  'Could not auto-detect whisper-cli. Please browse manually.',
            ),
          ),
        );
      }
    });
  }

  Future<void> _autoDetectFfmpeg() async {
    if (kIsWeb) return;
    setState(() => _validatingFfmpeg = true);

    final resolved = FfmpegLocator.instance.resolve();
    String? foundPath;

    if (resolved != 'ffmpeg' && resolved != 'ffmpeg.exe') {
      if (File(resolved).existsSync() && await _validateExecutable(resolved, ['-version'])) {
        foundPath = resolved;
      }
    }

    if (foundPath == null) {
      final exeName = Platform.isWindows ? 'ffmpeg.exe' : 'ffmpeg';
      if (await _validateExecutable(exeName, ['-version'])) {
        foundPath = exeName;
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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.errorAutoDetectFfmpeg ??
                  'Could not auto-detect ffmpeg. Please browse manually.',
            ),
          ),
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
        final l10n = AppLocalizations.of(context);
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
                Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.secondaryText, fontSize: 12)),
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
                            if (e.toolId == 'whisper') {
                              setState(() => _whisperManualException = e);
                            } else {
                              // FIX (audit, cross-tool mislabel): an FFmpeg
                              // manual-install failure was previously shown in
                              // the whisper-branded banner.
                              scaffoldMessenger.showSnackBar(
                                SnackBar(content: Text('${e.toolId} requires manual installation (${e.platform}).'), backgroundColor: AppTheme.accentRed),
                              );
                            }
                          } else {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n?.errorToolDownloadFailed(e.toString()) ??
                                      'Failed to download tool: $e',
                                ),
                                backgroundColor: AppTheme.accentRed,
                              ),
                            );
                          }
                        }
                      });
                    },
                    icon: Icon(Icons.download_for_offline, size: 14, color: AppTheme.accentOrange),
                    label: Text(
                      l10n?.autoDownload ?? 'AUTO DOWNLOAD',
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
                          style: TextStyle(fontSize: 11, color: AppTheme.secondaryText, fontWeight: FontWeight.bold),
                        ),
                        if (progress.speedBytesPerSec > 0 && isDownloading)
                          Text(
                            '${(progress.speedBytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s',
                            style: TextStyle(fontSize: 10, color: AppTheme.mutedText, fontFamily: 'monospace'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress.overall,
                      backgroundColor: AppTheme.dividerColor,
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
                      style: TextStyle(fontSize: 12, color: AppTheme.primaryText),
                      decoration: InputDecoration(
                        hintText: hint,
                        filled: true,
                        fillColor: AppTheme.cardBgElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        suffixIcon: isValid == null
                            ? null
                            : Icon(
                                isValid ? Icons.check_circle_outline : Icons.error_outline,
                                color: isValid ? AppTheme.accentGreen : AppTheme.accentRed,
                                size: 18,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(icon: const Icon(Icons.folder_open), onPressed: onBrowse, tooltip: l10n?.settingsBrowse ?? 'Browse'),
                  IconButton(
                    icon: isValidating
                        ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondaryText))
                        : const Icon(Icons.flash_on_outlined),
                    onPressed: onAutoDetect,
                    tooltip: l10n?.autoDetectAndValidate ?? 'Auto-detect & Validate',
                  ),
                ],
              ),
            ],
            if (isFailed && progress.error != null && progress.error!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 14, color: AppTheme.accentRed),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        progress.error!,
                        style: TextStyle(fontSize: 10, color: AppTheme.accentRed, fontWeight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
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
    final l10n = AppLocalizations.of(context);

    return Column(
      key: const ValueKey('step_setup'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.connectCliTitle ?? 'Connect Local CLI Tools',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryText,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n?.connectCliDesc ?? 'CapStudio needs whisper.cpp and FFmpeg binaries to perform transcription and export videos locally.',
                    style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.secondaryText, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Quick Auto-Detect Header Banner
        LayoutBuilder(
          builder: (context, bannerConstraints) {
            final isNarrow = bannerConstraints.maxWidth < 420;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: AppTheme.glassDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.08),
                borderRadius: 10,
                borderOpacity: 0.15,
              ),
              child: isNarrow
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.bolt_rounded, size: 18, color: AppTheme.accentOrange),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Automated Discovery: locate binaries automatically.',
                                style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            _autoDetectWhisper();
                            _autoDetectFfmpeg();
                          },
                          icon: const Icon(Icons.search_rounded, size: 14),
                          label: const Text('DETECT ALL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentOrange,
                            side: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Icon(Icons.bolt_rounded, size: 20, color: AppTheme.accentOrange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Automated Discovery: CapStudio can locate system and bundled binaries automatically.',
                            style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            _autoDetectWhisper();
                            _autoDetectFfmpeg();
                          },
                          icon: const Icon(Icons.search_rounded, size: 14),
                          label: const Text('DETECT ALL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentOrange,
                            side: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.4)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
        const SizedBox(height: 18),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.cardBgElevated.withValues(alpha: 0.35),
            borderRadius: 12,
            borderOpacity: 0.08,
          ),
          child: _buildPathField(
            toolId: 'whisper',
            controller: _whisperController,
            label: l10n?.whisperCliPathLabel ?? 'Whisper CLI Executable Path',
            hint: 'e.g. A:/Capstudio/assets/bin/whisper-cli.exe',
            isValid: _whisperValid,
            isValidating: _validatingWhisper,
            onBrowse: () => _pickFile(_whisperController, 'Select whisper-cli executable'),
            onAutoDetect: _autoDetectWhisper,
          ),
        ),
        const SizedBox(height: 14),

        Container(
          padding: const EdgeInsets.all(14),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.cardBgElevated.withValues(alpha: 0.35),
            borderRadius: 12,
            borderOpacity: 0.08,
          ),
          child: _buildPathField(
            toolId: 'ffmpeg',
            controller: _ffmpegController,
            label: l10n?.ffmpegCliPathLabel ?? 'FFmpeg CLI Executable Path',
            hint: 'e.g. A:/ffmpeg/bin/ffmpeg.exe',
            isValid: _ffmpegValid,
            isValidating: _validatingFfmpeg,
            onBrowse: () => _pickFile(_ffmpegController, 'Select FFmpeg executable'),
            onAutoDetect: _autoDetectFfmpeg,
          ),
        ),
        if (_whisperManualException != null) ...[
          const SizedBox(height: 16),
          ManualInstallBanner(exception: _whisperManualException!),
        ],
        const SizedBox(height: 24),

        LayoutBuilder(
          builder: (context, actionConstraints) {
            final isNarrow = actionConstraints.maxWidth < 440;
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (_whisperController.text.isNotEmpty || _ffmpegController.text.isNotEmpty) ...[
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _runValidation,
                            icon: const Icon(Icons.check_rounded, size: 14),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.cardBgElevated,
                              foregroundColor: AppTheme.primaryText,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            label: Text(l10n?.btnValidate ?? 'Validate'),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _saveAndContinue,
                          icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                            foregroundColor: AppTheme.onAccentText,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            elevation: 2,
                          ),
                          label: Text(l10n?.btnContinue ?? 'Continue', style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: widget.onSkip,
                      child: Text(l10n?.skipSetup ?? 'Skip setup for now', style: TextStyle(color: AppTheme.secondaryText)),
                    ),
                  ),
                ],
              );
            }
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: widget.onSkip,
                  child: Text(l10n?.skipSetup ?? 'Skip setup for now', style: TextStyle(color: AppTheme.secondaryText)),
                ),
                Row(
                  children: [
                    if (_whisperController.text.isNotEmpty || _ffmpegController.text.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: _runValidation,
                        icon: const Icon(Icons.check_rounded, size: 14),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.cardBgElevated,
                          foregroundColor: AppTheme.primaryText,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        label: Text(l10n?.btnValidate ?? 'Validate'),
                      ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _saveAndContinue,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange,
                        foregroundColor: AppTheme.onAccentText,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 2,
                      ),
                      label: Text(l10n?.btnContinue ?? 'Continue', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    ).animate().fade(duration: 300.ms);
  }
}
