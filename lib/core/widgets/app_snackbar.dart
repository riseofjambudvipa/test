import 'package:flutter/material.dart';
import '../../app/theme.dart';

enum SnackBarType { info, success, warning, error }

/// Unified SnackBar presentation helper providing consistent feedback across CapStudio.
class AppSnackBar {
  AppSnackBar._();

  static void show(
    BuildContext context,
    String message, {
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger == null) return;

    Color iconColor;
    IconData icon;

    switch (type) {
      case SnackBarType.success:
        iconColor = AppTheme.accentGreen;
        icon = Icons.check_circle_outline_rounded;
        break;
      case SnackBarType.warning:
        iconColor = AppTheme.accentOrange;
        icon = Icons.warning_amber_rounded;
        break;
      case SnackBarType.error:
        iconColor = AppTheme.accentRed;
        icon = Icons.error_outline_rounded;
        break;
      case SnackBarType.info:
        iconColor = AppTheme.accentCyan;
        icon = Icons.info_outline_rounded;
        break;
    }

    scaffoldMessenger.hideCurrentSnackBar();
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: AppTheme.primaryText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.cardBgElevated,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: AppTheme.borderGlass),
        ),
        action: action,
      ),
    );
  }

  static void success(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: SnackBarType.success, duration: duration);
  }

  static void error(BuildContext context, String message, {Duration duration = const Duration(seconds: 4)}) {
    show(context, message, type: SnackBarType.error, duration: duration);
  }

  static void info(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: SnackBarType.info, duration: duration);
  }

  static void warning(BuildContext context, String message, {Duration duration = const Duration(seconds: 3)}) {
    show(context, message, type: SnackBarType.warning, duration: duration);
  }
}
