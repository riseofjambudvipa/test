import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/database/schemas/project.dart';
import '../../../../../core/utils/premium_blur_dialog.dart';

class DeleteConfirmDialog extends StatelessWidget {
  final Project project;
  final VoidCallback onDelete;

  const DeleteConfirmDialog({
    super.key,
    required this.project,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PremiumBlurDialog(
      maxWidth: 400,
      glassColor: AppTheme.accentRed.withValues(alpha: 0.03),
      borderOpacity: 0.15,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.accentRed, size: 24),
              const SizedBox(width: 8),
              Text(
                l10n?.deleteProjectTitle ?? 'Delete Project',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppTheme.primaryText,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n?.deleteProjectConfirm(project.name) ??
                'Are you sure you want to permanently delete "${project.name}"? This action cannot be undone.',
            style: TextStyle(color: AppTheme.secondaryText, height: 1.4, fontSize: 13),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  l10n?.btnCancel ?? 'CANCEL',
                  style: TextStyle(color: AppTheme.secondaryText, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentRed,
                  foregroundColor: AppTheme.onAccentText,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  onDelete();
                },
                child: Text(
                  l10n?.btnDelete ?? 'DELETE',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
