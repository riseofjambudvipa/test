import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../core/settings/settings_service.dart';
import '../../../../../core/widgets/whisper_threads_slider.dart';
import '../../../../../core/downloader/binary_downloader_service.dart';
import '../../../../../core/utils/app_dirs.dart';
import '../manual_install_banner.dart';
import '../whisper_model_picker.dart';
import '../../../../../core/utils/native_helper.dart';
import '../../../../../core/utils/executable_validator.dart';

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
          const SnackBar(
            content: Text(
              'Missing AVX support detected! Automatically downloading compatible whisper-cli (no-AVX)...',
            ),
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
    _checkVcRuntime();
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 1.0,
      ),
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
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
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
                            setState(() {
                              _whisperManualException = e;
                            });
                          } else {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: Text('Failed to download tool: $e'),
                                backgroundColor: Colors.redAccent,
                              ),
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
                        Expanded(
                          child: Text(
                            progress.label,
                            style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
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
                        fillColor: AppTheme.cardBg.withValues(alpha: 0.6),
                        border: AppTheme.defaultBorder(radius: 6),
                        focusedBorder: AppTheme.focusedBorder(radius: 6),
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
                  IconButton(
                    icon: const Icon(Icons.folder_open),
                    onPressed: onBrowse,
                    tooltip: 'Browse',
                  ),
                  IconButton(
                    icon: isValidating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white60),
                          )
                        : const Icon(Icons.refresh),
                    onPressed: onValidate,
                    tooltip: 'Validate Path',
                  ),
                ],
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
          const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent, size: 20),
              SizedBox(width: 8),
              Text(
                'Microsoft VC++ Runtime Missing',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orangeAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Whisper JNI requires the MSVC++ 2015-2022 redistributable. Without it, local speech transcription will crash.',
            style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white10,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: const Icon(Icons.launch, size: 16),
              label: const Text('DOWNLOAD VC++ REDISTRIBUTABLE'),
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
    final isCompactWidth = MediaQuery.of(context).size.width < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!kIsWeb) ...[
          _buildSectionHeader('🧠 Speech Recognition Model'),
          const SizedBox(height: 16),
          const WhisperModelPicker(),
          
          if (!Platform.isAndroid && !Platform.isIOS) ...[
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
                      color: Colors.white30,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _showAdvancedPaths ? 'HIDE ADVANCED PATH CONFIGURATION' : 'SHOW ADVANCED PATH CONFIGURATION',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white30,
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
          
          const Divider(color: Colors.white10, height: 40),
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
                _buildSectionHeader('🚀 Hardware Performance Upgrades'),
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
                            if (_hardwareInfo != null) ...[
                              Row(
                                children: [
                                  const Icon(Icons.memory, size: 12, color: Colors.white38),
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
                                  const Icon(Icons.speed, size: 12, color: Colors.white38),
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
                                  const Icon(Icons.developer_board, size: 12, color: Colors.white38),
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
                      if (!Platform.isAndroid && !Platform.isIOS) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('GPU Accelerated Transcription (CUDA)', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
                                  SizedBox(height: 4),
                                  Text('Requires NVIDIA GPU with CUDA compatibility', style: TextStyle(fontSize: 11, color: Colors.white30)),
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
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('GPU Export Encoder', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
                                  SizedBox(height: 4),
                                  Text('Hardware acceleration for MP4 video export', style: TextStyle(fontSize: 11, color: Colors.white30)),
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
                                items: const [
                                  DropdownMenuItem(value: 'none', child: Text('None (CPU)')),
                                  DropdownMenuItem(value: 'h264_nvenc', child: Text('NVIDIA NVENC')),
                                  DropdownMenuItem(value: 'h264_amf', child: Text('AMD AMF')),
                                  DropdownMenuItem(value: 'h264_qsv', child: Text('Intel QSV')),
                                  DropdownMenuItem(value: 'h264_videotoolbox', child: Text('Apple VideoToolbox')),
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
                        titleStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70),
                        descriptionStyle: const TextStyle(fontSize: 11, color: Colors.white30),
                      ),
                    ],
                  ],
                ),
        ),          const Divider(color: Colors.white10, height: 40),
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
