import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show compute, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../core/logger/logger_service.dart';
import '../../../../core/assets/asset_path_service.dart';
import '../../../../core/assets/asset_manifest.dart';
import '../../../../core/assets/asset_verification_service.dart';
import '../../../../core/assets/pack_download_service.dart';
import '../../../../core/emoji/emoji_service.dart';
import '../../../../l10n/app_localizations.dart';

class PackManagerScreen extends ConsumerStatefulWidget {
  const PackManagerScreen({super.key});

  @override
  ConsumerState<PackManagerScreen> createState() => _PackManagerScreenState();
}

class _PackManagerScreenState extends ConsumerState<PackManagerScreen> {
  double _totalDiskUsageMB = 0.0;
  bool _calculatingDisk = true;

  @override
  void initState() {
    super.initState();
    // FIX (audit, double verification): _updateDiskUsage() already runs
    // reVerify() internally; the extra post-frame reVerify spawned two
    // concurrent verification isolates on open.
    unawaited(_updateDiskUsage());
  }

  Future<void> _updateDiskUsage() async {
    if (!mounted) return;
    setState(() => _calculatingDisk = true);
    try {
      if (!kIsWeb) {
        await ref.read(assetVerificationProvider.notifier).reVerify();
      }
      final usage = await _calculateDiskUsage();
      if (mounted) {
        setState(() {
          _totalDiskUsageMB = usage;
          _calculatingDisk = false;
        });
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.warning, 'PackManager', 'Failed to calculate disk usage: $e');
      if (mounted) {
        setState(() => _calculatingDisk = false);
      }
    }
  }

  Future<double> _calculateDiskUsage() async {
    if (kIsWeb) return 0.0;
    final emojisDir = AssetPathService.instance.emojisDir;
    final dir = Directory(emojisDir);
    if (!dir.existsSync()) return 0.0;

    try {
      final totalBytes = await compute((String path) {
        final d = Directory(path);
        if (!d.existsSync()) return 0;
        int bytes = 0;
        try {
          for (final entity in d.listSync(recursive: true, followLinks: false)) {
            if (entity is File) {
              try {
                bytes += entity.lengthSync();
              } catch (e) {
                LoggerService.instance.log(LogLevel.error, 'PackManagerScreen', 'Failed to read length: $e');
              }
            }
          }
        } catch (e) {
          LoggerService.instance.log(LogLevel.error, 'PackManagerScreen', 'Failed to list directory: $e');
        }
        return bytes;
      }, emojisDir);
      return totalBytes / (1024 * 1024);
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'PackManagerScreen', 'Error calculating disk usage: $e');
      return 0.0;
    }
  }

  Future<void> _openAssetsFolder() async {
    final path = AssetPathService.instance.assetsRoot;
    final uri = Uri.directory(path);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.errorOpenFolderFailed(path) ??
                    'Could not open folder automatically. Path: $path',
              ),
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'PackManagerScreen', 'Error opening folder: $e');
    }
  }

  Widget _buildPackCard(AssetPack pack, AssetVerificationResult verification) {
    final isInstalled = verification.installedPackIds.contains(pack.id);
    return StreamBuilder<DownloadProgress>(
      stream: PackDownloadService.instance.stream(pack.id),
      initialData: PackDownloadService.instance.getActiveProgress(pack.id) ?? DownloadProgress(
        packId: pack.id,
        status: isInstalled ? DownloadStatus.complete : DownloadStatus.idle,
      ),
      builder: (context, snapshot) {
        final l10n = AppLocalizations.of(context);
        final progress = snapshot.data!;
        var status = progress.status;
        if (status == DownloadStatus.complete || status == DownloadStatus.idle) {
          status = isInstalled ? DownloadStatus.complete : DownloadStatus.idle;
        }
        final isDownloading = status == DownloadStatus.downloading;
        final isExtracting = status == DownloadStatus.extracting;
        final isComplete = status == DownloadStatus.complete;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.cardBg,
            borderRadius: 12,
            borderOpacity: isComplete ? 0.08 : 0.04,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              pack.name,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryText),
                            ),
                            if (pack.required) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                decoration: AppTheme.glassDecoration(
                                  color: AppTheme.accentOrange.withValues(alpha: 0.15),
                                  borderRadius: 4,
                                  borderOpacity: 0.2,
                                ),
                                child: Text(
                                  'REQUIRED',
                                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.accentOrange),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pack.description,
                          style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${pack.sizeMB.toStringAsFixed(0)} MB',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondaryText, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                      if (isComplete)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.accentGreen.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 11, color: AppTheme.accentGreen),
                                  const SizedBox(width: 4),
                                  Text(
                                    pack.format == 'ttf' ? 'BUILT-IN' : 'INSTALLED',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
                                  ),
                                ],
                              ),
                            ),
                            if (!pack.required && pack.format != 'ttf' && !kIsWeb) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () async {
                                  await PackDownloadService.instance.removePack(pack);
                                  if (!mounted) return;
                                  await _updateDiskUsage();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'REMOVE',
                                  style: TextStyle(fontSize: 10, color: AppTheme.accentRed, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ],
                        )
                      else if (kIsWeb)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentCyan.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppTheme.accentCyan.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_done_rounded, size: 12, color: AppTheme.accentCyan),
                              const SizedBox(width: 4),
                              Text(
                                pack.format == 'ttf' ? 'WEB FONT' : 'WEB READY',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentCyan,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isDownloading || isExtracting)
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentOrange),
                        )
                      else
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download_rounded, size: 12),
                          label: Text(l10n?.btnDownload.toUpperCase() ?? 'DOWNLOAD', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cardBgElevated,
                            foregroundColor: AppTheme.primaryText,
                            side: BorderSide(color: AppTheme.borderGlass),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            final l10n = AppLocalizations.of(context);
                            unawaited(PackDownloadService.instance.download(pack).then((_) async {
                              if (!mounted) return;
                              await _updateDiskUsage();
                            }).catchError((Object e) {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n?.errorDownloadPackFailed(e.toString()) ??
                                          'Failed to download pack: $e',
                                    ),
                                    backgroundColor: AppTheme.accentRed,
                                  ),
                                );
                              }
                            }));
                          },
                        ),
                    ],
                  ),
                ],
              ),
              if (isDownloading || isExtracting) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress.overall,
                    backgroundColor: AppTheme.dividerColor,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentOrange),
                    minHeight: 4,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      progress.label,
                      style: TextStyle(fontSize: 9, color: AppTheme.secondaryText),
                    ),
                    Text(
                      '${(progress.overall * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 9, color: AppTheme.primaryText, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
              if (status == DownloadStatus.failed && progress.error != null && progress.error!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline_rounded, size: 14, color: AppTheme.accentRed),
                      const SizedBox(width: 8),
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final manifest = ref.watch(assetManifestProvider);
    final verification = ref.watch(assetVerificationProvider);
    final paths = AssetPathService.instance;

    final emojiPacks = manifest.packs.where((p) => p.format != 'ttf').toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Manage Content Packs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Disk Usage Banner Block
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration(
                color: AppTheme.cardBg,
                borderRadius: 12,
                borderOpacity: 0.1,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: AppTheme.glassDecoration(
                      color: AppTheme.accentOrange.withValues(alpha: 0.15),
                      borderRadius: 24,
                      borderOpacity: 0.2,
                    ),
                    child: Icon(Icons.pie_chart_outline_rounded, color: AppTheme.accentOrange, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          kIsWeb ? 'Web Engine Storage' : 'Total Disk Storage Space Used',
                          style: TextStyle(fontSize: 12, color: AppTheme.secondaryText, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        _calculatingDisk
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentOrange),
                              )
                            : Text(
                                kIsWeb ? 'In-Browser Ready' : '${_totalDiskUsageMB.toStringAsFixed(1)} MB',
                                style: TextStyle(
                                  fontSize: kIsWeb ? 16 : 22,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.primaryText,
                                  fontFamily: kIsWeb ? null : 'monospace',
                                ),
                              ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: AppTheme.secondaryText),
                    onPressed: _updateDiskUsage,
                    tooltip: 'Recalculate Storage Size',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (emojiPacks.isNotEmpty) ...[
              Text(
                'EMOJI STYLE PACKS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.secondaryText, letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              ...emojiPacks.map((pack) => _buildPackCard(pack, verification)),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),

            if (!kIsWeb) ...[
              Text(
                'USER CUSTOM STICKERS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.secondaryText, letterSpacing: 1.5),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: AppTheme.glassDecoration(
                color: AppTheme.cardBg,
                borderRadius: 12,
                borderOpacity: 0.04,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overlay Custom Stickers / Emojis',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryText, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Place your custom image overlay assets (.png, .jpg, .webp, .gif) in the folder below. Emojis and overlays will automatically index and become searchable inside the caption editor under their file names!',
                    style: TextStyle(fontSize: 11, color: AppTheme.secondaryText, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                     decoration: AppTheme.glassDecoration(
                      color: AppTheme.cardBgElevated,
                      borderRadius: 6,
                      borderOpacity: 0.06,
                    ),
                    child: Text(
                      paths.customStickersDir,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.primaryText),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 14),
                        label: const Text('REFRESH STICKERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.15),
                          foregroundColor: AppTheme.accentOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final l10n = AppLocalizations.of(context);
                          await EmojiService.instance.scanCustomStickers(paths.customStickersDir);
                          if (mounted) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n?.stickersIndexRefreshed ??
                                      'Custom stickers index refreshed successfully!',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      if (paths.isDesktop) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.folder_open_outlined, size: 14),
                          label: Text(l10n?.openOutputFolder.toUpperCase() ?? 'OPEN FOLDER', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cardBgElevated,
                            foregroundColor: AppTheme.primaryText,
                            side: BorderSide(color: AppTheme.borderGlass),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final l10n = AppLocalizations.of(context);
                            final uri = Uri.directory(paths.customStickersDir);
                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        l10n?.errorOpenFolderFailed(paths.customStickersDir) ??
                                            'Could not open folder automatically. Path: ${paths.customStickersDir}',
                                      ),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              LoggerService.instance.log(LogLevel.error, 'PackManagerScreen', 'Error opening folder: $e');
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Directory / Location Settings
            Text(
              'ASSET FOLDER CONFIGURATION',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: AppTheme.mutedText, letterSpacing: 1.5),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration(
                color: AppTheme.cardBg,
                borderRadius: 12,
                borderOpacity: 0.04,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assets Root Folder Location',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.secondaryText, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: AppTheme.glassDecoration(
                      color: AppTheme.cardBg.withValues(alpha: 0.25),
                      borderRadius: 6,
                      borderOpacity: 0.08,
                    ).copyWith(
                      border: Border.all(
                        color: verification.allRequiredPresent
                            ? AppTheme.accentGreen.withValues(alpha: 0.4)
                            : AppTheme.accentRed.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      paths.assetsRoot,
                      style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppTheme.secondaryText),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (paths.isDesktop) ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.folder_open_outlined, size: 14),
                          label: Text(l10n?.openOutputFolder.toUpperCase() ?? 'OPEN DIRECTORY', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.cardBgElevated,
                            foregroundColor: AppTheme.primaryText,
                            side: BorderSide(color: AppTheme.borderGlass),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: _openAssetsFolder,
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit_location_alt_outlined, size: 14),
                          label: Text(l10n?.exportChooseFolder.toUpperCase() ?? 'CHANGE FOLDER', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.15),
                            foregroundColor: AppTheme.accentOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () async {
                            // Capture before awaits to avoid using the
                            // BuildContext across an async gap.
                            final messenger = ScaffoldMessenger.of(context);
                            final l10n = AppLocalizations.of(context);
                            final result = await FilePicker.getDirectoryPath(
                              dialogTitle: 'Select Assets Root Storage Folder',
                            );
                            if (!mounted) return;
                            if (result != null) {
                              // FIX (audit): any throw here became an
                              // unhandled async exception with no UI feedback.
                              try {
                                await paths.setDesktopAssetsFolder(result);
                                if (!mounted) return;
                                await ref.read(assetVerificationProvider.notifier).reVerify();
                                await _updateDiskUsage();
                              } catch (e) {
                                LoggerService.instance.log(LogLevel.error, 'PackManager', 'Failed to change assets folder: $e');
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n?.errorChangeAssetFolderFailed(e.toString()) ??
                                          'Failed to change assets folder: $e',
                                    ),
                                    backgroundColor: AppTheme.accentRed,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}
