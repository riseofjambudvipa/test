import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../app/theme.dart';
import '../../../../core/assets/asset_path_service.dart';
import '../../../../core/assets/asset_verification_service.dart';
import '../../../../core/logger/logger_service.dart';
import '../../../../core/utils/app_dirs.dart';

class AssetsFolderRecoveryScreen extends ConsumerStatefulWidget {
  const AssetsFolderRecoveryScreen({super.key});

  @override
  ConsumerState<AssetsFolderRecoveryScreen> createState() => _AssetsFolderRecoveryScreenState();
}

class _AssetsFolderRecoveryScreenState extends ConsumerState<AssetsFolderRecoveryScreen> {
  bool _retrying = false;
  String? _errorMessage;

  Future<void> _browseNewLocation() async {
    try {
      final result = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select CapStudio Assets Folder',
      );
      if (!mounted) return;
      if (result != null) {
        await AssetPathService.instance.setDesktopAssetsFolder(result);
        LoggerService.instance.log(LogLevel.action, 'Recovery', 'Assets folder changed to: $result');
        await _retryVerification();
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'Recovery', 'Failed to pick directory: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to select folder: $e';
        });
      }
    }
  }

  Future<void> _resetToDefault() async {
    try {
      // Clear preferences to fallback to default
      final defaultRoot = AppDirs.support; // Set default support root
      await AssetPathService.instance.setDesktopAssetsFolder(defaultRoot);
      LoggerService.instance.log(LogLevel.action, 'Recovery', 'Reset assets folder to default support path.');
      await _retryVerification();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to reset: $e';
        });
      }
    }
  }

  Future<void> _retryVerification() async {
    setState(() {
      _retrying = true;
      _errorMessage = null;
    });

    // Re-verify assets
    await ref.read(assetVerificationProvider.notifier).reVerify();
    if (!mounted) return;

    final verification = ref.read(assetVerificationProvider);

    setState(() {
      _retrying = false;
    });

    if (verification.assetsRootMissing == null) {
      // Re-verified successfully, folder is back!
      context.go('/');
    } else {
      setState(() {
        _errorMessage = 'Assets folder still not found at: ${AssetPathService.instance.assetsRoot}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expectedPath = AssetPathService.instance.assetsRoot;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.cardBg.withValues(alpha: 0.8),
            borderRadius: 16,
            borderOpacity: 0.08,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 56, color: AppTheme.accentOrange),
              const SizedBox(height: 16),
              Text(
                'Assets Folder Not Found',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'CapStudio could not locate the assets folder at the configured location. If the folder is on an external drive, please connect it.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.secondaryText),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: AppTheme.glassDecoration(
                  color: AppTheme.cardBg.withValues(alpha: 0.25),
                  borderRadius: 8,
                  borderOpacity: 0.08,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EXPECTED PATH:',
                      style: TextStyle(fontSize: 9, color: Colors.white30, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expectedPath,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 32),
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _browseNewLocation,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Browse New Location'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _resetToDefault,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reset to Default Path'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _retrying ? null : _retryVerification,
                    icon: _retrying
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh),
                    label: const Text('Retry Verification'),
                    style: TextButton.styleFrom(foregroundColor: AppTheme.accentCyan),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
