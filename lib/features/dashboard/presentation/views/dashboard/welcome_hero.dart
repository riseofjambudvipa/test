import 'package:flutter/material.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../../../app/theme.dart';

class WelcomeHero extends StatelessWidget {
  const WelcomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: GlassContainer(
          padding: const EdgeInsets.all(32),
          borderRadius: 16,
          borderOpacity: 0.06,
          color: AppTheme.cardBg.withValues(alpha: 0.35),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.video_library_outlined,
                size: 48,
                color: AppTheme.mutedText,
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)?.noProjects ?? 'No projects created yet',
                style: TextStyle(
                  color: AppTheme.secondaryText,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
