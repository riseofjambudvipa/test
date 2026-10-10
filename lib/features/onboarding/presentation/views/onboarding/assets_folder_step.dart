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
import '../../../../../l10n/app_localizations.dart';

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
      if (!mounted) return;
      widget.onContinue();
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n?.errorSetAssetFolderFailed(e.toString()) ??
                  'Failed to set assets folder: $e',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      key: const ValueKey('step_assets_folder'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.setupAssetDirTitle ?? 'Choose Asset Directory',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n?.setupAssetDirDesc ??
              'Configure where CapStudio stores sidecar emoji packs and fonts on your computer (~350 MB to 2.5 GB required).',
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.secondaryText, fontSize: 12),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.cardBgElevated.withValues(alpha: 0.35),
            borderRadius: 14,
            borderOpacity: 0.08,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.folder_special_rounded, size: 18, color: AppTheme.accentOrange),
                      const SizedBox(width: 8),
                      Text(
                        l10n?.storagePathFolder ?? 'Storage Path Folder',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryText, fontSize: 12),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'RECOMMENDED',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _assetsFolderController,
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.primaryText),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppTheme.cardBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.borderGlass),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppTheme.accentOrange),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardBgElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.borderGlass),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.folder_open_rounded, size: 20),
                      onPressed: _pickAssetsFolder,
                      tooltip: l10n?.settingsBrowse ?? 'Browse',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.accentCyan.withValues(alpha: 0.05),
            borderRadius: 10,
            borderOpacity: 0.1,
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppTheme.accentCyan),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  (!kIsWeb && Platform.isWindows)
                      ? (l10n?.tipWindowsDrive ?? 'Tip: If C: drive is small, choose a path on D: or E: for more space.')
                      : (l10n?.tipGeneralDrive ?? 'Tip: You can select an external drive path if your root volume is full.'),
                  style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, actionConstraints) {
            final isNarrow = actionConstraints.maxWidth < 380;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text(l10n?.btnBack ?? 'Back', style: TextStyle(color: AppTheme.secondaryText)),
                ),
                ElevatedButton.icon(
                  onPressed: _confirmAssetsFolder,
                  icon: const Icon(Icons.check_rounded, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: AppTheme.onAccentText,
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 16 : 24, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  label: Text(l10n?.confirmLocation ?? 'Confirm Location', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        ),
      ],
    ).animate().fade(duration: 300.ms);
  }
}
