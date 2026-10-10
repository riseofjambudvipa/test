import 'package:flutter/material.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../../l10n/app_localizations.dart';

class SavePresetDialog extends StatefulWidget {
  final void Function(String name) onSave;

  const SavePresetDialog({super.key, required this.onSave});

  @override
  State<SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends State<SavePresetDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBlurDialog(
      maxWidth: 360,
      glowColor: AppTheme.accentOrange,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save Custom Style Preset',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: AppTheme.primaryText),
            decoration: InputDecoration(
              labelText: 'Preset Name',
              hintText: 'e.g., My Vibrant Pink',
              labelStyle: TextStyle(color: AppTheme.secondaryText),
              hintStyle: TextStyle(color: AppTheme.mutedText),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: AppTheme.defaultBorder(radius: 6),
              focusedBorder: AppTheme.focusedBorder(radius: 6),
              filled: true,
              fillColor: AppTheme.cardBg,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)?.btnCancel ?? 'Cancel', style: TextStyle(color: AppTheme.secondaryText)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: AppTheme.onAccentText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.of(context).pop();
                    widget.onSave(name);
                  }
                },
                child: Text(AppLocalizations.of(context)?.btnSave ?? 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
