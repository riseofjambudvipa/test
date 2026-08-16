import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../core/assets/asset_path_service.dart';
import '../../../../../core/assets/asset_verification_service.dart';

class AssetsFolderStep extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const AssetsFolderStep({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  @override
  ConsumerState<AssetsFolderStep> createState() => _AssetsFolderStepState();
}

class _AssetsFolderStepState extends ConsumerState<AssetsFolderStep> {
  final _assetsFolderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _assetsFolderController.text = AssetPathService.instance.assetsRoot;
  }

  @override
  void dispose() {
    _assetsFolderController.dispose();
    super.dispose();
  }

  Future<void> _pickAssetsFolder() async {
    try {
      final result = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Assets Root Storage Folder',
      );
      if (!mounted) return;
      if (result != null) {
        setState(() {
          _assetsFolderController.text = result;
        });
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'AssetsFolderStep', 'Failed to pick directory: $e');
    }
  }

  Future<void> _confirmAssetsFolder() async {
    final path = _assetsFolderController.text.trim();
    if (path.isEmpty) return;
    try {
      await AssetPathService.instance.setDesktopAssetsFolder(path);
      await ref.read(assetVerificationProvider.notifier).reVerify();
      widget.onContinue();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to set assets folder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      key: const ValueKey('step_assets_folder'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Asset Directory',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Configure where CapStudio stores sidecar emoji packs and fonts on your computer (~350 MB to 2.5 GB required).',
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.secondaryText),
        ),
        const SizedBox(height: 24),
        
        const Text('Storage Path Folder', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _assetsFolderController,
                style: const TextStyle(fontSize: 11, color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black26,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: AppTheme.accentOrange),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.folder_open_outlined, size: 20),
              onPressed: _pickAssetsFolder,
              tooltip: 'Browse',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.cardBg.withValues(alpha: 0.15),
            borderRadius: 8,
            borderOpacity: 0.06,
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 16, color: AppTheme.accentCyan),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  (!kIsWeb && Platform.isWindows)
                      ? 'Tip: If C: drive is small, choose a path on D: or E: for more space.'
                      : 'Tip: You can select an external drive path if your root volume is full.',
                  style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: widget.onBack,
              child: const Text('Back', style: TextStyle(color: Colors.white30)),
            ),
            ElevatedButton(
              onPressed: _confirmAssetsFolder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Confirm Location', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    ).animate().fade(duration: 300.ms);
  }
}
