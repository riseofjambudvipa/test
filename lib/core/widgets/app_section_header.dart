import 'package:flutter/material.dart';
import '../../app/theme.dart';

/// Unified section header widget used consistently across all settings screens,
/// editor panels, dialogs, and sheets in CapStudio.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final bool showAccentBar;
  final double fontSize;
  final Color? titleColor;
  final EdgeInsetsGeometry padding;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
    this.showAccentBar = false,
    this.fontSize = 13,
    this.titleColor,
    this.padding = const EdgeInsets.only(bottom: 8),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: fontSize + 4, color: AppTheme.accentOrange),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: titleColor ?? AppTheme.primaryText,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (showAccentBar) ...[
            const SizedBox(height: 6),
            Container(
              height: 2,
              width: 44,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
