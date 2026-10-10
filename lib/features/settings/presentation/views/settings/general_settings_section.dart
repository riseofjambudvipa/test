import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../app/theme.dart';
import '../../../../../app/theme_provider.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../core/settings/settings_service.dart';
import '../../../../../core/widgets/whisper_threads_slider.dart';
import '../../../../../core/downloader/binary_downloader_service.dart';
import '../../../../../core/utils/app_dirs.dart';
import '../manual_install_banner.dart';
import '../whisper_model_picker.dart';
import '../../../../../core/utils/native_helper.dart';
import '../../../../../core/utils/executable_validator.dart';
import '../../../../../l10n/app_localizations.dart';

class GeneralSettingsSection extends ConsumerStatefulWidget {
  const GeneralSettingsSection({super.key});

  @override
  ConsumerState<GeneralSettingsSection> createState() => _GeneralSettingsSectionState();
}

class _GeneralSettingsSectionState extends ConsumerState<GeneralSettingsSection> {
  final _whisperController = TextEditingController();
  final _ffmpegController = TextEditingController();

  bool? _whisperValid;
  bool? _ffmpegValid;
  bool _validatingWhisper = false;
  bool _validatingFfmpeg = false;
  bool _vcRuntimeMissing = false;
  bool _showAdvancedPaths = false;
  ManualInstallRequiredException? _whisperManualException;
  int _whisperThreads = 0;
  bool _useGpu = false;
  String _gpuEncoder = 'none';
  SystemHardwareInfo? _hardwareInfo;
  bool _hardwareExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkVcRuntime();
    _detectHardware();
  }

  Future<void> _detectHardware() async {
    final info = await detectSystemHardware();
    if (!mounted) return;
    setState(() {
      _hardwareInfo = info;
    });
  }

  @override
  void dispose() {
    _whisperController.dispose();
    _ffmpegController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final settings = SettingsService.instance;
    _whisperController.text = settings.whisperCliPath ?? '';
    _ffmpegController.text = settings.ffmpegCliPath ?? '';
    _whisperThreads = settings.whisperThreads;
    _useGpu = settings.useGpu;
    _gpuEncoder = settings.gpuEncoder;
  }

  void _checkVcRuntime() {
    if (!kIsWeb && Platform.isWindows) {
      setState(() {
        _vcRuntimeMissing = !AppDirs.isWindowsVcRuntimeInstalled();
      });
    }
  }

  Future<void> _pickFile(TextEditingController controller, String title) async {
    try {
      final result = await FilePicker.pickFiles(
        dialogTitle: title,
        type: FileType.any,
      );
      if (!mounted) return;
      if (result != null && result.files.single.path != null) {
        setState(() {
          controller.text = result.files.single.path!;
          if (controller == _whisperController) _whisperValid = null;
          if (controller == _ffmpegController) _ffmpegValid = null;
        });
        await _savePaths();
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'GeneralSettingsSection', 'Failed to pick file: $e');
    }
  }

  Future<void> _savePaths() async {
    await SettingsService.instance.setWhisperCliPath(_whisperController.text.trim());
    await SettingsService.instance.setFfmpegCliPath(_ffmpegController.text.trim());
  }

  Future<bool> _validateExecutable(String path, List<String> args) async {
    return validateExecutable(
      path,
      args,
      onAvxDetected: () async {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.warningNoAvx ??
                  'Missing AVX support detected! Automatically downloading compatible whisper-cli (no-AVX)...',
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
    // FIX (audit, crash risk): _checkVcRuntime() calls setState; guard it so a
    // user leaving the screen mid-validation can't hit setState after dispose.
    if (mounted) _checkVcRuntime();
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

  Widget _buildSectionHeader(String title, IconData icon, [AppThemeData? themeData]) {
    final primaryColor = themeData?.primaryText ?? AppTheme.primaryText;
    final accentColor = themeData?.accentOrange ?? AppTheme.accentOrange;
    return Row(
      children: [
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: primaryColor,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildWebFeatureRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.accentOrange),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryText)),
              const SizedBox(height: 1),
              Text(subtitle, style: TextStyle(fontSize: 10, color: AppTheme.secondaryText)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPathInput({
    required String toolId,
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool? isValid,
    required bool isValidating,
    required VoidCallback onBrowse,
    required VoidCallback onValidate,
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
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryText, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isWorking && (isValid != true || isFailed))
                  TextButton.icon(
                    onPressed: () {
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final l10n = AppLocalizations.of(context);
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
                              // manual-install failure was previously stored
                              // in _whisperManualException and rendered inside
                              // the whisper-branded banner. Show it as a
                              // snackbar instead.
                              scaffoldMessenger.showSnackBar(
                                SnackBar(
                                  content: Text('${e.toolId} requires manual installation (${e.platform}).'),
                                  backgroundColor: AppTheme.accentRed,
                                ),
                              );
                            }
                          } else {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n?.errorDownloadToolFailed(e.toString()) ??
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
                      AppLocalizations.of(context)?.autoDownload ?? 'AUTO DOWNLOAD',
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
                  color: AppTheme.cardBg,
                  borderRadius: 8,
                  borderOpacity: 0.08,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            progress.label,
                            style: TextStyle(fontSize: 11, color: AppTheme.secondaryText, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                        hintStyle: TextStyle(color: AppTheme.mutedText),
                        filled: true,
                        fillColor: AppTheme.cardBg,
                        border: AppTheme.defaultBorder(radius: 6),
                        focusedBorder: AppTheme.focusedBorder(radius: 6),
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
                  IconButton(
                    icon: Icon(Icons.folder_open, color: AppTheme.secondaryText),
                    onPressed: onBrowse,
                    tooltip: 'Browse',
                  ),
                  IconButton(
                    icon: isValidating
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentOrange),
                          )
                        : Icon(Icons.refresh, color: AppTheme.secondaryText),
                    onPressed: onValidate,
                    tooltip: 'Validate Path',
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
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildVcRuntimeWarning() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBg,
        borderRadius: 12,
        borderOpacity: 0.12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.accentOrange, size: 20),
              const SizedBox(width: 8),
              Text(
                'Microsoft VC++ Runtime Missing',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentOrange),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Whisper JNI requires the MSVC++ 2015-2022 redistributable. Without it, local speech transcription will crash.',
            style: TextStyle(fontSize: 12, color: AppTheme.secondaryText, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.12),
                foregroundColor: AppTheme.accentOrange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.3)),
                ),
              ),
              icon: const Icon(Icons.launch, size: 16),
              label: Text(
                AppLocalizations.of(context)?.btnDownloadVcRedist ??
                    'DOWNLOAD VC++ REDISTRIBUTABLE',
              ),
              onPressed: () async {
                final uri = Uri.parse('https://aka.ms/vs/17/release/vc_redist.x64.exe');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not launch download URL. Please visit https://aka.ms/vs/17/release/vc_redist.x64.exe manually.'),
                      ),
                    );
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeProvider);
    final isCompactWidth = MediaQuery.of(context).size.width < 600;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kIsWeb) ...[
          _buildSectionHeader('In-Browser Speech & Video Engine', Icons.cloud_done_rounded, themeData),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AppTheme.glassDecoration(
              color: AppTheme.cardBg,
              borderRadius: 12,
              borderOpacity: 0.12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: AppTheme.glassDecoration(
                        color: AppTheme.accentGreen.withValues(alpha: 0.15),
                        borderRadius: 8,
                        borderOpacity: 0.2,
                      ),
                      child: Icon(Icons.check_circle_outline, color: AppTheme.accentGreen, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Client-Side WASM & AI Active',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'CapStudio runs 100% locally in your browser sandbox. No videos or audio are uploaded to any server.',
                            style: TextStyle(fontSize: 11, color: AppTheme.secondaryText, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: AppTheme.borderGlass, height: 1),
                const SizedBox(height: 14),
                _buildWebFeatureRow(
                  Icons.psychology_rounded,
                  'AI Transcription Engine',
                  'Transformers.js (ONNX Runtime Web / WebAssembly)',
                ),
                const SizedBox(height: 10),
                _buildWebFeatureRow(
                  Icons.movie_creation_outlined,
                  'Video & Subtitle Burning',
                  'FFmpeg.wasm (Multi-threaded WebAssembly)',
                ),
                const SizedBox(height: 10),
                _buildWebFeatureRow(
                  Icons.security_rounded,
                  'Multi-threading & Isolation',
                  'Cross-Origin Isolated (COOP/COEP & SharedArrayBuffer)',
                ),
              ],
            ),
          ),
          Divider(color: AppTheme.borderGlass, height: 32),
        ] else ...[
          _buildSectionHeader(l10n?.speechModelTitle ?? 'Speech Recognition Model', Icons.psychology_outlined, themeData),
          const SizedBox(height: 16),
          const WhisperModelPicker(),
          
          if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) ...[
            const SizedBox(height: 16),
            InkWell(
              onTap: () => setState(() => _showAdvancedPaths = !_showAdvancedPaths),
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _showAdvancedPaths ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppTheme.mutedText,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showAdvancedPaths
                          ? (l10n?.hideAdvancedPaths ?? 'HIDE ADVANCED PATH CONFIGURATION')
                          : (l10n?.showAdvancedPaths ?? 'SHOW ADVANCED PATH CONFIGURATION'),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.mutedText,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            if (_showAdvancedPaths) ...[
              const SizedBox(height: 16),
              _buildPathInput(
                toolId: 'whisper',
                controller: _whisperController,
                label: 'Whisper CLI Path',
                hint: 'Path to whisper-cli executable',
                isValid: _whisperValid,
                isValidating: _validatingWhisper,
                onBrowse: () => _pickFile(_whisperController, 'Select whisper-cli'),
                onValidate: _validateWhisper,
              ),
              if (_whisperManualException != null)
                ManualInstallBanner(exception: _whisperManualException!),
              if (_vcRuntimeMissing) ...[
                const SizedBox(height: 12),
                _buildVcRuntimeWarning(),
              ],
              const SizedBox(height: 16),
              _buildPathInput(
                toolId: 'ffmpeg',
                controller: _ffmpegController,
                label: 'FFmpeg CLI Path',
                hint: 'Path to ffmpeg executable',
                isValid: _ffmpegValid,
                isValidating: _validatingFfmpeg,
                onBrowse: () => _pickFile(_ffmpegController, 'Select ffmpeg'),
                onValidate: _validateFfmpeg,
              ),
            ],
          ],
          
          if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) ...[
            Divider(color: AppTheme.borderGlass, height: 32),
            InkWell(
          onTap: () {
            setState(() {
              _hardwareExpanded = !_hardwareExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(l10n?.hardwareUpgradesTitle ?? 'Hardware Performance Upgrades', Icons.speed_rounded, themeData),
                Icon(
                  _hardwareExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: AppTheme.accentOrange,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: !_hardwareExpanded
              ? const SizedBox.shrink()
              : Column(
                  key: const ValueKey('expanded_hardware_performance'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    if (!kIsWeb) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: AppTheme.glassDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: 8,
                          borderOpacity: 0.08,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Detected System Hardware:',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                            ),
                            const SizedBox(height: 6),
                            if (_hardwareInfo != null) ...[
                              Row(
                                children: [
                                  Icon(Icons.memory, size: 12, color: AppTheme.mutedText),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'RAM Size: ${_hardwareInfo!.ramGB.toStringAsFixed(1)} GB',
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
                                      'CPU Logical Cores: ${_hardwareInfo!.cpuCores}',
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
                                      'GPU Device: ${_hardwareInfo!.gpuInfo}',
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
                          ],
                        ),
                      ),
                      if (!kIsWeb && !Platform.isAndroid && !Platform.isIOS) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n?.gpuAcceleratedTranscription ?? 'GPU Accelerated Transcription (CUDA)',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryText),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n?.gpuRequiresNvidia ?? 'Requires NVIDIA GPU with CUDA compatibility',
                                    style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch(
                              value: _useGpu,
                              activeThumbColor: AppTheme.accentOrange,
                              onChanged: (val) {
                                setState(() => _useGpu = val);
                                SettingsService.instance.setUseGpu(val);
                              },
                            ),
                          ],
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
                                    l10n?.gpuExportEncoder ?? 'GPU Export Encoder',
                                    style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryText),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n?.gpuExportEncoderDesc ?? 'Hardware acceleration for MP4 video export',
                                    style: TextStyle(fontSize: 11, color: AppTheme.mutedText),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 160,
                              child: DropdownButton<String>(
                                value: _gpuEncoder,
                                dropdownColor: AppTheme.cardBg,
                                underline: const SizedBox.shrink(),
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem(value: 'none', child: Text(l10n?.gpuEncoderNoneCpu ?? 'None (CPU)', style: TextStyle(color: AppTheme.primaryText))),
                                  DropdownMenuItem(value: 'h264_nvenc', child: Text(l10n?.gpuEncoderNvidia ?? 'NVIDIA NVENC', style: TextStyle(color: AppTheme.primaryText))),
                                  DropdownMenuItem(value: 'h264_amf', child: Text(l10n?.gpuEncoderAmd ?? 'AMD AMF', style: TextStyle(color: AppTheme.primaryText))),
                                  DropdownMenuItem(value: 'h264_qsv', child: Text(l10n?.gpuEncoderIntel ?? 'Intel QSV', style: TextStyle(color: AppTheme.primaryText))),
                                  DropdownMenuItem(value: 'h264_videotoolbox', child: Text(l10n?.gpuEncoderApple ?? 'Apple VideoToolbox', style: TextStyle(color: AppTheme.primaryText))),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _gpuEncoder = val);
                                    SettingsService.instance.setGpuEncoder(val);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                      WhisperThreadsSlider(
                        value: _whisperThreads,
                        onChanged: (v) {
                          setState(() => _whisperThreads = v);
                          SettingsService.instance.setWhisperThreads(v);
                        },
                        layout: isCompactWidth
                            ? WhisperThreadsSliderLayout.compact
                            : WhisperThreadsSliderLayout.wide,
                        showDescription: true,
                        titleStyle: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryText),
                        descriptionStyle: TextStyle(fontSize: 11, color: AppTheme.mutedText),
                      ),
                    ],
                  ],
                ),
          ),
          Divider(color: AppTheme.borderGlass, height: 32),
        ],
        ],
      ],
    );
  }

  // Allow resetting this section's controllers/states from parent SettingsScreen
  void reloadSettings() {
    setState(() {
      _loadSettings();
      _whisperValid = null;
      _ffmpegValid = null;
      _whisperManualException = null;
    });
  }
}
