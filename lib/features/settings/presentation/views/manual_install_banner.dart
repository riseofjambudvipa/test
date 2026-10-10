import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/downloader/binary_downloader_service.dart';
import '../../../../app/theme.dart';
import '../../../../l10n/app_localizations.dart';

class ManualInstallBanner extends StatelessWidget {
  final ManualInstallRequiredException exception;

  const ManualInstallBanner({
    super.key,
    required this.exception,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      padding: const EdgeInsets.all(20.0),
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBgElevated,
        borderOpacity: 0.12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppTheme.accentOrange,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Manual Action Required',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.primaryText,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Whisper CLI cannot be auto-downloaded for your platform (${exception.platform}) due to sandboxing or package restrictions. Please follow these simple steps to install it locally:',
            style: TextStyle(
              color: AppTheme.secondaryText,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ...exception.steps.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final step = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: AppTheme.glassDecoration(
                          color: AppTheme.accentOrange.withValues(alpha: 0.15),
                          borderRadius: 16,
                          borderOpacity: 0.3,
                        ),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: Center(
                            child: Text(
                              '$idx',
                              style: TextStyle(
                                color: AppTheme.accentOrange,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          step.title,
                          style: TextStyle(
                            color: AppTheme.primaryText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 44.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                      decoration: AppTheme.glassDecoration(
                        color: AppTheme.surfaceDim,
                        borderRadius: 10,
                        borderOpacity: 0.08,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                step.command,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  color: AppTheme.accentCyan,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            color: AppTheme.secondaryText,
                            tooltip: 'Copy command',
                            onPressed: () {
                              final l10n = AppLocalizations.of(context);
                              Clipboard.setData(ClipboardData(text: step.command));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n?.commandCopied(step.command) ??
                                        'Copied: "${step.command}"',
                                  ),
                                  backgroundColor: AppTheme.cardBg,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 44.0),
            child: Text(
              'Once complete, restart the app or configure the path in settings below.',
              style: TextStyle(
                color: AppTheme.mutedText,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
