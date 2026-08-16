import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../../../../core/whisper/whisper_model.dart';
import '../../../../core/settings/settings_service.dart';
import '../../../../core/downloader/binary_downloader_service.dart';
import '../../../../core/utils/app_dirs.dart';
import '../../../../app/theme.dart';
import '../../../../core/utils/premium_blur_dialog.dart';

class WhisperModelPicker extends StatefulWidget {
  const WhisperModelPicker({super.key});

  @override
  State<WhisperModelPicker> createState() => _WhisperModelPickerState();
}

class _WhisperModelPickerState extends State<WhisperModelPicker> {
  String? _activeModelName;
  final Map<String, bool> _modelExists = {};
  final Map<String, BinaryDownloadProgress?> _progressMap = {};
  final List<StreamSubscription<BinaryDownloadProgress>> _subscriptions = [];
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _loadActiveModel();
    _checkDownloadedModels();
    _listenToStreams();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  void _loadActiveModel() {
    setState(() {
      _activeModelName = SettingsService.instance.whisperModelName;
    });
  }

  Future<void> _checkDownloadedModels() async {
    final modelsDir = p.join(AppDirs.support, 'models');
    final Map<String, bool> tempExists = {};
    for (final model in kWhisperModels) {
      final path = p.join(modelsDir, 'ggml-${model.name}.bin');
      tempExists[model.name] = await File(path).exists();
    }
    if (mounted) {
      setState(() {
        _modelExists.clear();
        _modelExists.addAll(tempExists);
      });
    }
  }

  void _listenToStreams() {
    for (final model in kWhisperModels) {
      final toolId = 'model_${model.name}';
      final sub = BinaryDownloaderService.instance.stream(toolId).listen((progress) {
        if (mounted) {
          setState(() {
            _progressMap[model.name] = progress;
            if (progress.status == BinaryDownloadStatus.complete) {
              _modelExists[model.name] = true;
              _loadActiveModel();
            }
          });
        }
      });
      _subscriptions.add(sub);
    }
  }

  Future<void> _downloadModel(WhisperModel model) async {
    if (kIsWeb) {
      unawaited(showDialog(
        context: context,
        builder: (ctx) => PremiumBlurDialog(
          maxWidth: 360,
          glowColor: AppTheme.accentOrange,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Web Platform',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryText,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'On web, local model downloads are not supported.',
                style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('OK', style: TextStyle(color: AppTheme.secondaryText)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ));
      return;
    }
    setState(() {
      _progressMap[model.name] = BinaryDownloadProgress(
        toolId: 'model_${model.name}',
        status: BinaryDownloadStatus.downloading,
        downloadProgress: 0.0,
      );
    });
    try {
      await BinaryDownloaderService.instance.downloadWhisperModel(model.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download model ${model.displayName}: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      // ROBUSTNESS FIX (found in second-pass review): previously left
      // _progressMap[model.name] stuck at 'downloading, 0%' forever after
      // a failure — the SnackBar told the user it failed, but the card's
      // own progress bar didn't reflect that, so it looked like a download
      // that started and silently hung. Same root cause as the fix applied
      // to core/utils/whisper_quality_selection.dart's downloadWhisperModel.
      if (mounted) {
        setState(() {
          _progressMap[model.name] = BinaryDownloadProgress(
            toolId: 'model_${model.name}',
            status: BinaryDownloadStatus.failed,
            error: e.toString(),
          );
        });
      }
    } finally {
      await _checkDownloadedModels();
    }
  }

  Future<void> _deleteModel(WhisperModel model) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => PremiumBlurDialog(
        maxWidth: 380,
        glowColor: Colors.redAccent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delete Model?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to delete the ${model.displayName} model file to free up space? You will need to download it again to use it.',
              style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('Cancel', style: TextStyle(color: AppTheme.secondaryText)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final path = p.join(AppDirs.support, 'models', 'ggml-${model.name}.bin');
    final file = File(path);
    if (await file.exists()) {
      try {
        try {
          await file.delete();
        } catch (_) {
          // If first delete fails (e.g. read-only file/write protection issues on Linux/Android),
          // attempt to make the file writeable/accessible and delete again.
          if (!Platform.isWindows) {
            await Process.run('chmod', ['777', path]);
          }
          await file.delete();
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted model: ${model.displayName}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        if (_activeModelName == model.name) {
          await SettingsService.instance.setWhisperModelPath('');
          await SettingsService.instance.setWhisperModelName('');
          _loadActiveModel();
        }
        await _checkDownloadedModels();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete model: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final activeModel = kWhisperModels.firstWhere(
      (m) => m.name == _activeModelName,
      orElse: () => kWhisperModels.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'AI Speech Models',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryText,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: AppTheme.glassDecoration(
                              color: AppTheme.accentOrange.withValues(alpha: 0.1),
                              borderRadius: 4,
                              borderOpacity: 0.2,
                            ),
                            child: Text(
                              'Local',
                              style: TextStyle(
                                color: AppTheme.accentOrange,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _activeModelName != null && _activeModelName!.isNotEmpty
                            ? 'Active: ${activeModel.displayName} (${activeModel.sizeMb.toInt()}MB)'
                            : 'No active model selected (downloads required)',
                        style: TextStyle(
                          color: AppTheme.accentOrange.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
          child: !_isExpanded
              ? const SizedBox.shrink()
              : Column(
                  key: const ValueKey('expanded_whisper_models'),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Select the speech recognition model. Higher accuracy models transcribe better but require more CPU/RAM and take longer to run.',
                      style: TextStyle(color: AppTheme.secondaryText, fontSize: 13, height: 1.4),
                    ),
                    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: AppTheme.glassDecoration(
                          color: Colors.blue.withValues(alpha: 0.08),
                          borderRadius: 8,
                          borderOpacity: 0.2,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.phone_android, size: 16, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('📱 Mobile Recommendations', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('• Tiny (75MB): Safe for all devices (1GB+ RAM).', style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
                            Text('• Base (142MB): Best balance of speed and accuracy (2GB+ RAM).', style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
                            Text('• Small (466MB): High accuracy, requires newer devices (2.5GB+ RAM, recommended 3GB+).', style: TextStyle(fontSize: 11, color: AppTheme.secondaryText)),
                            const SizedBox(height: 4),
                            const Text('Warning: Medium or Large models may crash or fail to load on lower-end devices.', style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: kWhisperModels.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final model = kWhisperModels[index];
                        final isActive = _activeModelName == model.name;
                        final isDownloaded = _modelExists[model.name] ?? false;
                        final progress = _progressMap[model.name];

                        final isDownloading = progress != null &&
                            progress.status == BinaryDownloadStatus.downloading;

                        return InkWell(
                          onTap: !isDownloaded
                              ? null
                              : () async {
                                  final path = p.join(AppDirs.support, 'models', 'ggml-${model.name}.bin');
                                  await SettingsService.instance.setWhisperModelPath(path);
                                  await SettingsService.instance.setWhisperModelName(model.name);
                                  _loadActiveModel();
                                },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.glassDecoration(
                              color: isActive
                                  ? AppTheme.accentOrange.withValues(alpha: 0.05)
                                  : AppTheme.cardBg,
                              borderRadius: 12,
                              borderOpacity: isActive ? 0.35 : (isDownloaded ? 0.08 : 0.02),
                              glowColor: isActive ? AppTheme.accentOrange : null,
                              glowOpacity: isActive ? 0.15 : 0.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                model.displayName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 15,
                                                  color: AppTheme.primaryText,
                                                ),
                                              ),
                                              if (model.englishOnly)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: AppTheme.glassDecoration(
                                                    color: Colors.blue.withValues(alpha: 0.15),
                                                    borderRadius: 4,
                                                    borderOpacity: 0.2,
                                                  ),
                                                  child: const Text(
                                                    'EN ONLY',
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: AppTheme.glassDecoration(
                                                  color: Colors.white.withValues(alpha: 0.08),
                                                  borderRadius: 4,
                                                  borderOpacity: 0.06,
                                                ),
                                                child: Text(
                                                  '${model.sizeMb.round()} MB',
                                                  style: TextStyle(
                                                    color: AppTheme.secondaryText,
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            model.description,
                                            style: TextStyle(
                                              color: AppTheme.secondaryText,
                                              fontSize: 12,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    _buildActions(model, isActive, isDownloaded, isDownloading, progress),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (isDownloading) ...[
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress.downloadProgress,
                                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentOrange),
                                      minHeight: 6,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        progress.label,
                                        style: TextStyle(color: AppTheme.mutedText, fontSize: 11),
                                      ),
                                      if (progress.eta != null)
                                        Text(
                                          'ETA: ${progress.eta?.inSeconds ?? 0}s',
                                          style: TextStyle(color: AppTheme.mutedText, fontSize: 11),
                                        ),
                                    ],
                                  ),
                                ] else ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatBar('Speed', model.relativeSpeed, Colors.cyan),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        child: _buildStatBar('Accuracy', model.relativeAccuracy, Colors.green),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildActions(
    WhisperModel model,
    bool isActive,
    bool isDownloaded,
    bool isDownloading,
    BinaryDownloadProgress? progress,
  ) {
    if (isDownloading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (isDownloaded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: AppTheme.glassDecoration(
              color: AppTheme.accentGreen.withValues(alpha: 0.1),
              borderRadius: 6,
              borderOpacity: 0.15,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check, color: AppTheme.accentGreen, size: 12),
                const SizedBox(width: 4),
                Text(
                  'Downloaded',
                  style: TextStyle(color: AppTheme.accentGreen, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _deleteModel(model),
            child: const Text(
              'REMOVE',
              style: TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.05),
        foregroundColor: AppTheme.primaryText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      onPressed: () => _downloadModel(model),
      icon: const Icon(Icons.download_rounded, size: 16),
      label: const Text('Download', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
    );
  }

  Widget _buildStatBar(String label, int value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value / 10.0,
              backgroundColor: Colors.white.withValues(alpha: 0.03),
              valueColor: AlwaysStoppedAnimation<Color>(color.withValues(alpha: 0.7)),
              minHeight: 4,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value/10',
          style: TextStyle(color: AppTheme.mutedText, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
