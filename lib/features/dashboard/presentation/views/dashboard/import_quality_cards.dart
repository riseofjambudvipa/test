import 'package:flutter/material.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/downloader/binary_downloader_service.dart';
import '../../../../../core/utils/native_helper.dart';
import '../../../../../core/whisper/whisper_model.dart';

/// Renders the wrap of quality selection cards (Turbo, Balanced, Maximum, etc.)
/// within the video import dialog.
class ImportQualityCards extends StatelessWidget {
  final QualityMode selectedQuality;
  final SystemHardwareInfo? hardwareInfo;
  final Map<String, bool> modelExists;
  final Map<String, BinaryDownloadProgress?> downloadProgressMap;
  final ValueChanged<QualityMode> onSelectQuality;
  final void Function(WhisperModel model) onDownloadModel;

  const ImportQualityCards({
    super.key,
    required this.selectedQuality,
    required this.hardwareInfo,
    required this.modelExists,
    required this.downloadProgressMap,
    required this.onSelectQuality,
    required this.onDownloadModel,
  });

  @override
  Widget build(BuildContext context) {
    final isCompactWidth = MediaQuery.of(context).size.width < 600;

    final cards = QualityMode.values.map((mode) {
      final isSelected = selectedQuality == mode;
      final modelName = mode.modelName;
      final isDownloaded = modelExists[modelName] ?? false;
      final downloadProgress = downloadProgressMap[modelName];
      final isDownloading = downloadProgress != null && downloadProgress.status == BinaryDownloadStatus.downloading;

      final isRecommended = hardwareInfo != null && QualityMode.getRecommended(hardwareInfo!) == mode;
      final isSupported = mode.isSupported(hardwareInfo);

      final cardChild = InkWell(
        onTap: !isSupported ? null : () => onSelectQuality(mode),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          margin: isCompactWidth ? const EdgeInsets.only(bottom: 10) : const EdgeInsets.symmetric(horizontal: 4),
          decoration: AppTheme.glassDecoration(
            color: isSelected
                ? AppTheme.accentOrange.withValues(alpha: 0.05)
                : AppTheme.cardBg,
            borderRadius: 12,
            borderOpacity: isSelected ? 0.35 : (isSupported ? 0.08 : 0.02),
            glowColor: isSelected ? AppTheme.accentOrange : null,
            glowOpacity: isSelected ? 0.15 : 0.0,
          ).copyWith(
            border: Border.all(
              color: isSelected
                  ? AppTheme.accentOrange.withValues(alpha: 0.4)
                  : (isRecommended
                      ? AppTheme.accentCyan.withValues(alpha: 0.25)
                      : (isSupported ? AppTheme.borderGlass : AppTheme.borderGlass.withValues(alpha: 0.04))),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Opacity(
            opacity: isSupported ? 1.0 : 0.45,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: isCompactWidth ? null : 32,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          mode.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.accentOrange : AppTheme.primaryText,
                          ),
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (!isSupported)
                        Icon(Icons.lock_outline, color: AppTheme.mutedText, size: 12)
                      else if (isRecommended)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: AppTheme.glassDecoration(
                            color: AppTheme.accentCyan.withValues(alpha: 0.15),
                            borderRadius: 4,
                            borderOpacity: 0.3,
                          ),
                          child: Text(
                            'REC',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.accentCyan,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: isCompactWidth ? 4 : 6),
                SizedBox(
                  height: isCompactWidth ? null : 24,
                  child: Text(
                    mode.speedAccuracyText,
                    style: TextStyle(fontSize: 9, color: AppTheme.secondaryText, fontWeight: FontWeight.w500),
                    maxLines: 2,
                  ),
                ),
                SizedBox(height: isCompactWidth ? 2 : 4),
                SizedBox(
                  height: isCompactWidth ? null : 32,
                  child: Text(
                    mode.getDetailsWithSystemInfo(hardwareInfo),
                    style: TextStyle(fontSize: 8, color: AppTheme.mutedText),
                    maxLines: 3,
                  ),
                ),
                if (!isCompactWidth) const Spacer(),
                if (isCompactWidth) const SizedBox(height: 8),
                SizedBox(
                  height: isCompactWidth ? null : 60,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Model: $modelName',
                              style: TextStyle(fontSize: 8, color: AppTheme.mutedText, fontFamily: 'monospace'),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (isDownloaded)
                            Icon(Icons.check_circle, color: AppTheme.accentGreen, size: 12)
                          else if (isDownloading)
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(strokeWidth: 1.2, color: AppTheme.accentOrange),
                            )
                          else
                            Icon(Icons.download_for_offline_outlined, color: AppTheme.mutedText.withValues(alpha: 0.25), size: 12),
                        ],
                      ),
                      if (isDownloading) ...[
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: downloadProgress.downloadProgress,
                          color: AppTheme.accentOrange,
                          backgroundColor: AppTheme.dividerColor,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${(downloadProgress.downloadProgress * 100).toInt()}%',
                                style: TextStyle(fontSize: 8, color: AppTheme.mutedText),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (downloadProgress.eta != null)
                              Text(
                                '${downloadProgress.eta!.inSeconds}s',
                                style: TextStyle(fontSize: 8, color: AppTheme.mutedText),
                              ),
                          ],
                        ),
                      ] else if (!isDownloaded) ...[
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          height: 20,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: !isSupported
                                  ? AppTheme.cardBgElevated
                                  : AppTheme.accentOrange.withValues(alpha: 0.15),
                              foregroundColor: !isSupported ? AppTheme.mutedText : AppTheme.accentOrange,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              elevation: 0,
                            ),
                            onPressed: !isSupported
                                ? null
                                : () => onDownloadModel(
                                      kWhisperModels.firstWhere(
                                        (m) => m.name == modelName,
                                        orElse: () => kWhisperModels.first,
                                      ),
                                    ),
                            child: Text(
                              !isSupported ? 'Hardware Locked' : 'Download',
                              style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        if (!isCompactWidth) const SizedBox(height: 4),
                      ] else ...[
                        if (!isCompactWidth) const SizedBox(height: 44),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      return SizedBox(
        width: isCompactWidth ? double.infinity : 166,
        height: isCompactWidth ? null : 195,
        child: cardChild,
      );
    }).toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: cards,
    );
  }
}
