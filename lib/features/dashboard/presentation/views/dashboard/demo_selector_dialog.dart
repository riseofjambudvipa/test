import 'package:flutter/material.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../l10n/app_localizations.dart';

class DemoSelectorDialog extends StatelessWidget {
  final ValueChanged<bool> onSelectDemo;

  const DemoSelectorDialog({
    super.key,
    required this.onSelectDemo,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PremiumBlurDialog(
      maxWidth: 580,
      borderOpacity: 0.08,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.selectDemoFormat ?? 'SELECT DEMO FORMAT',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppTheme.accentCyan,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppTheme.secondaryText, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.selectDemoDesc ??
                'Select a layout format to preview CapStudio\'s high-fidelity caption engine, live word-level animations, and audio waveforms instantly.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.secondaryText,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildDemoCard(
                  context: context,
                  title: l10n?.landscapeDemo ?? 'Landscape Demo',
                  subtitle: l10n?.landscapeDemoDesc ?? 'Perfect for YouTube, desktop & presentations.',
                  aspectRatio: l10n?.format16x9 ?? '16:9 Format',
                  icon: Icons.desktop_windows_outlined,
                  gradientColor: AppTheme.accentCyan,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectDemo(true);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDemoCard(
                  context: context,
                  title: l10n?.portraitDemo ?? 'Portrait Demo',
                  subtitle: l10n?.portraitDemoDesc ?? 'Ideal for TikTok, Shorts, Reels & mobile.',
                  aspectRatio: l10n?.format9x16 ?? '9:16 Format',
                  icon: Icons.phone_android_outlined,
                  gradientColor: AppTheme.accentOrange,
                  onTap: () {
                    Navigator.pop(context);
                    onSelectDemo(false);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDemoCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String aspectRatio,
    required IconData icon,
    required Color gradientColor,
    required VoidCallback onTap,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 500;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: GlassContainer(
        padding: EdgeInsets.all(isNarrow ? 12 : 20),
        borderRadius: 12,
        borderOpacity: 0.12,
        glowColor: gradientColor,
        glowOpacity: 0.04,
        color: AppTheme.cardBgElevated,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(isNarrow ? 8 : 10),
              decoration: AppTheme.glassDecoration(
                color: gradientColor.withValues(alpha: 0.1),
                borderRadius: 24,
                borderOpacity: 0.15,
              ),
              child: Icon(icon, color: gradientColor, size: isNarrow ? 20 : 28),
            ),
            SizedBox(height: isNarrow ? 10 : 16),
            Text(
              title,
              style: TextStyle(
                fontSize: isNarrow ? 12 : 15,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: isNarrow ? 10 : 12,
                color: AppTheme.mutedText,
                height: 1.35,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isNarrow ? 10 : 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: AppTheme.glassDecoration(
                color: gradientColor.withValues(alpha: 0.15),
                borderRadius: 4,
                borderOpacity: 0.2,
              ),
              child: Text(
                aspectRatio,
                style: TextStyle(
                  fontSize: isNarrow ? 8 : 10,
                  fontWeight: FontWeight.bold,
                  color: gradientColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
