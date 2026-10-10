import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/assets/asset_path_service.dart';
import '../../../../../core/assets/asset_manifest.dart';
import '../../../../../core/assets/asset_verification_service.dart';
import '../../../../../core/assets/pack_download_service.dart';
import '../../../../../l10n/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);

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
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.primaryText),
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
                                  l10n?.requiredBadge ?? 'REQUIRED',
                                  style: TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: AppTheme.accentOrange),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${pack.description} (${pack.sizeMB.toStringAsFixed(0)} MB)',
                          style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isComplete)
                    Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.accentGreen)
                  else if (isDownloading || isExtracting)
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.secondaryText),
                    )
                  else if (kIsWeb)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        pack.format == 'ttf' ? 'WEB FONT' : 'WEB READY',
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
                      ),
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
                              content: Text(
                                l10n?.errorPackDownloadNamedFailed(pack.name, e.toString()) ??
                                    'Failed to download pack ${pack.name}: $e',
                              ),
                              backgroundColor: AppTheme.accentRed,
                            ),
                          );
                        });
                      },
                      child: Text((l10n?.btnDownload ?? 'Download').toUpperCase(), style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              if (isDownloading || isExtracting) ...[
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress.overall,
                    backgroundColor: AppTheme.dividerColor,
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
                      style: TextStyle(fontSize: 8, color: AppTheme.secondaryText),
                    ),
                    Text(
                      '${(progress.overall * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 8, color: AppTheme.secondaryText, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ],
              if (status == DownloadStatus.failed && progress.error != null && progress.error!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.accentRed.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, size: 12, color: AppTheme.accentRed),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          progress.error!,
                          style: TextStyle(fontSize: 9, color: AppTheme.accentRed, fontWeight: FontWeight.w500),
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
    final theme = Theme.of(context);
    final manifest = ref.watch(assetManifestProvider);
    final verification = ref.watch(assetVerificationProvider);

    final emojiPacks = manifest.packs.where((p) => p.format != 'ttf').toList();

    final l10n = AppLocalizations.of(context);

    return Column(
      key: const ValueKey('step_download_pack'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.downloadPacksTitle ?? 'Download Content Packs (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryText,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          l10n?.downloadPacksDesc ??
              'Choose optional emoji packs and fonts to style your captions. You can download them now or skip this and set them up later in settings.',
          style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.secondaryText, fontSize: 12),
        ),
        const SizedBox(height: 16),

        Container(
          constraints: BoxConstraints(
            maxHeight: (MediaQuery.of(context).size.height * 0.38).clamp(160.0, 280.0),
          ),
          padding: const EdgeInsets.all(8),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.cardBgElevated.withValues(alpha: 0.25),
            borderRadius: 12,
            borderOpacity: 0.08,
          ),
          child: Scrollbar(
            controller: _packsScrollController,
            thumbVisibility: true,
            child: ListView(
              controller: _packsScrollController,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(Icons.emoji_emotions_outlined, size: 14, color: AppTheme.accentOrange),
                      const SizedBox(width: 6),
                      Text(
                        l10n?.emojiPacksHeader ?? 'EMOJI PACKS',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.mutedText, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                ...emojiPacks.map((pack) => _buildPackOnboardingRow(pack, verification)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        LayoutBuilder(
          builder: (context, actionConstraints) {
            final isNarrow = actionConstraints.maxWidth < 360;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!AssetPathService.instance.isMobile)
                  TextButton.icon(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text(l10n?.btnBack ?? 'Back', style: TextStyle(color: AppTheme.secondaryText)),
                  )
                else
                  const SizedBox(),
                ElevatedButton.icon(
                  onPressed: widget.onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: AppTheme.onAccentText,
                    padding: EdgeInsets.symmetric(horizontal: isNarrow ? 18 : 24, vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                  ),
                  label: Text(l10n?.btnContinue ?? 'Continue', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        ),
      ],
    ).animate().fade(duration: 300.ms);
  }
}
