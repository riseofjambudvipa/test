import 'package:flutter/material.dart';
import '../../../../app/theme.dart';

class RetranscribeOverlayWidget extends StatelessWidget {
  final String statusText;
  final double progressValue;

  const RetranscribeOverlayWidget({
    super.key,
    required this.statusText,
    required this.progressValue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(32),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.cardBg,
            borderRadius: 16,
            borderOpacity: 0.12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.accentOrange),
              ),
              const SizedBox(height: 24),
              Text(
                statusText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progressValue,
                color: AppTheme.accentOrange,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progressValue * 100).toInt()}% Progress',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
