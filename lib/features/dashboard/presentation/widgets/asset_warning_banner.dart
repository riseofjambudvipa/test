import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_provider.dart';
import '../../../../core/assets/asset_verification_service.dart';

/// Tracks whether the user has dismissed the optional packs discovery banner
/// for this current session.
final optionalAssetBannerDismissedProvider = StateProvider<bool>((ref) => false);

class AssetWarningBanner extends ConsumerWidget {
  const AssetWarningBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider);
    final result = ref.watch(assetVerificationProvider);
    final isDismissed = ref.watch(optionalAssetBannerDismissedProvider);

    // No assets missing at all
    if (result.missing.isEmpty && result.assetsRootMissing == null) {
      return const SizedBox.shrink();
    }

    final hasRootMissing = result.assetsRootMissing != null;
    final requiredMissing = result.requiredMissing;
    final isUrgent = hasRootMissing || requiredMissing.isNotEmpty;

    // If only optional packs are missing and user dismissed the banner, don't show
    if (!isUrgent && isDismissed) {
      return const SizedBox.shrink();
    }

    // Determine banner text, icon, and colors
    final String title;
    final String subtitle;
    final String actionText;
    final String route;
    final IconData iconData;
    final Color iconColor;
    final Color buttonColor;

    if (hasRootMissing) {
      title = 'Assets Folder Missing';
      subtitle = 'Configured folder not found: ${result.assetsRootMissing}. Fonts and emojis unavailable.';
      actionText = 'Settings';
      route = '/settings';
      iconData = Icons.error_outline_rounded;
      iconColor = AppTheme.accentRed;
      buttonColor = AppTheme.accentRed;
    } else if (requiredMissing.isNotEmpty) {
      title = 'Required Assets Missing';
      subtitle = 'Missing: ${requiredMissing.map((m) => m.packName).join(", ")}. Without these, core assets will fail to render.';
      actionText = 'Install Now';
      route = '/settings/packs';
      iconData = Icons.warning_amber_rounded;
      iconColor = AppTheme.accentOrange;
      buttonColor = AppTheme.accentOrange;
    } else {
      // Optional content packs available
      final count = result.missing.length;
      title = 'Emoji Packs Available';
      subtitle = '$count optional emoji pack${count > 1 ? "s" : ""} can be installed to unlock rich styled emojis in subtitles.';
      actionText = 'Manage Packs';
      route = '/settings/packs';
      iconData = Icons.emoji_emotions_outlined;
      iconColor = AppTheme.accentOrange;
      buttonColor = AppTheme.accentOrange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.glassDecoration(
        color: isUrgent
            ? AppTheme.accentOrange.withValues(alpha: AppTheme.isLight ? 0.08 : 0.12)
            : AppTheme.cardBg,
        borderRadius: 10,
        borderOpacity: AppTheme.isLight ? 0.15 : 0.2,
      ),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.secondaryText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: AppTheme.onAccentText,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            onPressed: () => context.push(route),
            child: Text(
              actionText,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          if (!isUrgent) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.close_rounded, size: 16, color: AppTheme.secondaryText),
              tooltip: 'Dismiss',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () {
                ref.read(optionalAssetBannerDismissedProvider.notifier).state = true;
              },
            ),
          ],
        ],
      ),
    );
  }
}
