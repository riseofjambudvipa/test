import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../../l10n/app_localizations.dart';
import '../../../controllers/editor_controller.dart';

class FindReplaceDialog extends ConsumerStatefulWidget {
  const FindReplaceDialog({super.key});

  @override
  ConsumerState<FindReplaceDialog> createState() => _FindReplaceDialogState();
}

class _FindReplaceDialogState extends ConsumerState<FindReplaceDialog> {
  late TextEditingController findCtrl;
  late TextEditingController replaceCtrl;
  int replaceCount = 0;

  @override
  void initState() {
    super.initState();
    findCtrl = TextEditingController();
    replaceCtrl = TextEditingController();
  }

  @override
  void dispose() {
    findCtrl.dispose();
    replaceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PremiumBlurDialog(
      maxWidth: 400,
      glowColor: AppTheme.accentOrange,
      glowOpacity: 0.1,
      useScrollView: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n?.findAndReplace ?? 'FIND & REPLACE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryText,
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: AppTheme.secondaryText),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(color: AppTheme.dividerColor, height: 16),
          TextField(
            controller: findCtrl,
            style: TextStyle(fontSize: 13, color: AppTheme.primaryText),
            decoration: InputDecoration(
              labelText: l10n?.findTextLabel ?? 'Find text',
              border: AppTheme.defaultBorder(),
              focusedBorder: AppTheme.focusedBorder(),
              filled: true,
              fillColor: AppTheme.cardBg,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: replaceCtrl,
            style: TextStyle(fontSize: 13, color: AppTheme.primaryText),
            decoration: InputDecoration(
              labelText: l10n?.replaceWithLabel ?? 'Replace with',
              border: AppTheme.defaultBorder(),
              focusedBorder: AppTheme.focusedBorder(),
              filled: true,
              fillColor: AppTheme.cardBg,
            ),
          ),
          if (replaceCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                l10n?.findReplaceSuccessCount(replaceCount) ?? 'Replaced $replaceCount occurrences!',
                style: TextStyle(color: AppTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n?.btnCancel ?? 'CANCEL', style: TextStyle(color: AppTheme.secondaryText, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: AppTheme.onAccentText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final findText = findCtrl.text;
                  final replaceText = replaceCtrl.text;
                  if (findText.isEmpty) return;

                  final count = ref.read(editorProvider.notifier).findAndReplaceText(findText, replaceText);
                  setState(() {
                    replaceCount = count;
                  });
                },
                child: Text(l10n?.btnReplaceAll ?? 'REPLACE ALL', style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
