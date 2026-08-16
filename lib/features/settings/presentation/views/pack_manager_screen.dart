import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
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
    unawaited(_updateDiskUsage());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(assetVerificationProvider.notifier).reVerify();
      }
    });
  }

  Future<void> _updateDiskUsage() async {
    if (!mounted) return;
    setState(() => _calculatingDisk = true);
    try {
      await ref.read(assetVerificationProvider.notifier).reVerify();
      final usage = await _calculateDiskUsage();
      if (mounted) {
        setState(() {
          _totalDiskUsageMB = usage;
          _calculatingDisk = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _calculatingDisk = false);
      }
    }
  }

  Future<double> _calculateDiskUsage() async {
    final emojisDir = AssetPathService.instance.emojisDir;
    final dir = Directory(emojisDir);
    if (!dir.existsSync()) return 0.0;

    try {
      final entities = await dir.list(recursive: true, followLinks: false).toList();
      final files = entities.whereType<File>().toList();
      final lengths = await Future.wait(files.map((f) => f.length().catchError((_) => 0)));
      final totalBytes = lengths.fold<int>(0, (sum, len) => sum + len);
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open folder automatically. Path: $path')),
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
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
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
                          style: const TextStyle(fontSize: 11, color: Colors.white30),
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
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white70, fontFamily: 'monospace'),
                      ),
                      const SizedBox(height: 8),
                      if (isComplete)
                        Row(
                          children: [
                            Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.accentGreen),
                            if (!pack.required) ...[
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () async {
                                  await PackDownloadService.instance.removePack(pack);
                                  if (!mounted) return;
                                  await ref.read(assetVerificationProvider.notifier).reVerify();
                                  await _updateDiskUsage();
                                },
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'REMOVE',
                                  style: TextStyle(fontSize: 10, color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ],
                        )
                      else if (isDownloading || isExtracting)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                        )
                      else
                        ElevatedButton.icon(
                          icon: const Icon(Icons.download_rounded, size: 12),
                          label: const Text('DOWNLOAD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () {
                            final scaffoldMessenger = ScaffoldMessenger.of(context);
                            unawaited(PackDownloadService.instance.download(pack).then((_) async {
                              if (!mounted) return;
                              await ref.read(assetVerificationProvider.notifier).reVerify();
                              await _updateDiskUsage();
                            }).catchError((Object e) {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to download pack: $e'),
                                    backgroundColor: Colors.redAccent,
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
                    backgroundColor: Colors.white10,
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
                      style: const TextStyle(fontSize: 9, color: Colors.white30),
                    ),
                    Text(
                      '${(progress.overall * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 9, color: Colors.white30, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ],
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
    final manifest = ref.watch(assetManifestProvider);
    final verification = ref.watch(assetVerificationProvider);
    final paths = AssetPathService.instance;

    final emojiPacks = manifest.packs.where((p) => p.format != 'ttf').toList();
    final fontPacks = manifest.packs.where((p) => p.format == 'ttf').toList();

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
                        const Text(
                          'Total Disk Storage Space Used',
                          style: TextStyle(fontSize: 12, color: Colors.white54, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        _calculatingDisk
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                              )
                            : Text(
                                '${_totalDiskUsageMB.toStringAsFixed(1)} MB',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                ),
                              ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white54),
                    onPressed: _updateDiskUsage,
                    tooltip: 'Recalculate Storage Size',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (emojiPacks.isNotEmpty) ...[
              const Text(
                'EMOJI STYLE PACKS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              ...emojiPacks.map((pack) => _buildPackCard(pack, verification)),
              const SizedBox(height: 16),
            ],

            if (fontPacks.isNotEmpty) ...[
              const Text(
                'CJK LANGUAGE FONT PACKS',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
              ),
              const SizedBox(height: 8),
              ...fontPacks.map((pack) => _buildPackCard(pack, verification)),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),

            const Text(
              'USER CUSTOM STICKERS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
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
                  const Text(
                    'Overlay Custom Stickers / Emojis',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Place your custom image overlay assets (.png, .jpg, .webp, .gif) in the folder below. Emojis and overlays will automatically index and become searchable inside the caption editor under their file names!',
                    style: TextStyle(fontSize: 11, color: Colors.white30, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                     decoration: AppTheme.glassDecoration(
                      color: AppTheme.cardBg.withValues(alpha: 0.25),
                      borderRadius: 6,
                      borderOpacity: 0.06,
                    ),
                    child: Text(
                      paths.customStickersDir,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white70),
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
                          await EmojiService.instance.scanCustomStickers(paths.customStickersDir);
                          if (mounted) {
                            messenger.showSnackBar(
                              const SnackBar(content: Text('Custom stickers index refreshed successfully!')),
                            );
                          }
                        },
                      ),
                      if (paths.isDesktop) ...[
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.folder_open_outlined, size: 14),
                          label: const Text('OPEN FOLDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final uri = Uri.directory(paths.customStickersDir);
                            try {
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              } else {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(content: Text('Could not open folder automatically. Path: ${paths.customStickersDir}')),
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
            const Text(
              'ASSET FOLDER CONFIGURATION',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.5),
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
                  const Text(
                    'Assets Root Folder Location',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 12),
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
                            : Colors.redAccent.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      paths.assetsRoot,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.white70),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (paths.isDesktop) ...[
                        ElevatedButton.icon(
                          icon: const Icon(Icons.folder_open_outlined, size: 14),
                          label: const Text('OPEN DIRECTORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withValues(alpha: 0.05),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: _openAssetsFolder,
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.edit_location_alt_outlined, size: 14),
                          label: const Text('CHANGE FOLDER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.15),
                            foregroundColor: AppTheme.accentOrange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () async {
                            final result = await FilePicker.getDirectoryPath(
                              dialogTitle: 'Select Assets Root Storage Folder',
                            );
                            if (!mounted) return;
                            if (result != null) {
                              await paths.setDesktopAssetsFolder(result);
                              if (!mounted) return;
                              await ref.read(assetVerificationProvider.notifier).reVerify();
                              await _updateDiskUsage();
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
        ),
      ),
    );
  }
}
