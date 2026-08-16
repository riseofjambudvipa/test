import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/assets/asset_path_service.dart';
import '../../../../../core/assets/asset_manifest.dart';
import '../../../../../core/assets/asset_verification_service.dart';
import '../../../../../core/assets/pack_download_service.dart';

class PacksDownloadStep extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const PacksDownloadStep({
    super.key,
    required this.onBack,
    required this.onContinue,
  });

  @override
  ConsumerState<PacksDownloadStep> createState() => _PacksDownloadStepState();
}

class _PacksDownloadStepState extends ConsumerState<PacksDownloadStep> {
  final _packsScrollController = ScrollController();

  @override
  void dispose() {
    _packsScrollController.dispose();
    super.dispose();
  }

  Widget _buildPackOnboardingRow(AssetPack pack, AssetVerificationResult verification) {
    final isInstalled = verification.installedPackIds.contains(pack.id);

    return StreamBuilder<DownloadProgress>(
      stream: PackDownloadService.instance.stream(pack.id),
      initialData: DownloadProgress(
        packId: pack.id,
        status: isInstalled ? DownloadStatus.complete : DownloadStatus.idle,
      ),
      builder: (context, snapshot) {
        final progress = snapshot.data!;
        final status = progress.status;
        final isDownloading = status == DownloadStatus.downloading;
        final isExtracting = status == DownloadStatus.extracting;
        final isComplete = status == DownloadStatus.complete;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: AppTheme.glassDecoration(
            color: isComplete
                ? AppTheme.accentGreen.withValues(alpha: 0.03)
                : AppTheme.cardBg.withValues(alpha: 0.2),
            borderRadius: 8,
            borderOpacity: isComplete ? 0.2 : 0.06,
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
                            Flexible(
                              child: Text(
                                pack.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (pack.required) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: AppTheme.glassDecoration(
                                  color: AppTheme.accentOrange.withValues(alpha: 0.15),
                                  borderRadius: 3,
                                  borderOpacity: 0.2,
                                ),
                                child: Text(
                                  'REQUIRED',
                                  style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: AppTheme.accentOrange),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pack.description} (${pack.sizeMB.toStringAsFixed(0)} MB)',
                          style: const TextStyle(fontSize: 10, color: Colors.white30),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isComplete)
                    Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.accentGreen)
                  else if (isDownloading || isExtracting)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.15),
                        foregroundColor: AppTheme.accentOrange,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                      onPressed: () {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        PackDownloadService.instance.download(pack).catchError((Object e) {
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text('Failed to download pack ${pack.name}: $e'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        });
                      },
                      child: const Text('DOWNLOAD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              if (isDownloading || isExtracting) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress.overall,
                    backgroundColor: Colors.white10,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.accentOrange),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      progress.label,
                      style: const TextStyle(fontSize: 8, color: Colors.white30),
                    ),
                    Text(
                      '${(progress.overall * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 8, color: Colors.white30, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
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
    final theme = Theme.of(context);
    final manifest = ref.watch(assetManifestProvider);
    final verification = ref.watch(assetVerificationProvider);

    final emojiPacks = manifest.packs.where((p) => p.format != 'ttf').toList();
    final fontPacks = manifest.packs.where((p) => p.format == 'ttf').toList();

    return Column(
      key: const ValueKey('step_download_pack'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Download Content Packs (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose optional emoji packs and fonts to style your captions. You can download them now or skip this and set them up later in settings.',
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.secondaryText),
        ),
        const SizedBox(height: 16),

        SizedBox(
          height: 280,
          child: Scrollbar(
            controller: _packsScrollController,
            thumbVisibility: true,
            child: ListView(
              controller: _packsScrollController,
              padding: const EdgeInsets.only(right: 12),
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('EMOJI PACKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white30, letterSpacing: 0.5)),
                ),
                ...emojiPacks.map((pack) => _buildPackOnboardingRow(pack, verification)),
                if (fontPacks.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Text('FONT PACKS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white30, letterSpacing: 0.5)),
                  ),
                  ...fontPacks.map((pack) => _buildPackOnboardingRow(pack, verification)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (!AssetPathService.instance.isMobile)
              TextButton(
                onPressed: widget.onBack,
                child: const Text('Back', style: TextStyle(color: Colors.white30)),
              )
            else
              const SizedBox(),
            ElevatedButton(
              onPressed: widget.onContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    ).animate().fade(duration: 300.ms);
  }
}
