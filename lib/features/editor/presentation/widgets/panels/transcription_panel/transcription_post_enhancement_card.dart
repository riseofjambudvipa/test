import 'package:flutter/material.dart';
import '../../../../../../app/theme.dart';

/// Card allowing creators to automatically trigger AI Magic Emojis and Magic SFX
/// immediately upon transcription completion or subtitle file import.
class TranscriptionPostEnhancementCard extends StatelessWidget {
  final bool autoApplyEmojis;
  final bool autoApplySfx;
  final ValueChanged<bool> onAutoApplyEmojisChanged;
  final ValueChanged<bool> onAutoApplySfxChanged;

  const TranscriptionPostEnhancementCard({
    super.key,
    required this.autoApplyEmojis,
    required this.autoApplySfx,
    required this.onAutoApplyEmojisChanged,
    required this.onAutoApplySfxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBgElevated,
        borderRadius: 12,
        borderOpacity: 0.12,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.accentCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.accentCyan,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI POST-PROCESSING',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Automatically enhance captions right after transcription',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppTheme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'FREE & OFFLINE',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: AppTheme.accentGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Option 1: Auto-Apply Magic Emojis
          _buildEnhancementRow(
            icon: Icons.insert_emoticon_rounded,
            iconColor: AppTheme.accentOrange,
            title: 'Auto-Add Magic Emojis',
            description: 'Analyzes spoken keywords and attaches animated viral emojis',
            value: autoApplyEmojis,
            onChanged: onAutoApplyEmojisChanged,
          ),
          const SizedBox(height: 10),

          // Option 2: Auto-Apply Magic SFX
          _buildEnhancementRow(
            icon: Icons.graphic_eq_rounded,
            iconColor: AppTheme.accentCyan,
            title: 'Auto-Add Magic SFX',
            description: 'Places punchy whoosh, pop, and impact audio cues on transitions',
            value: autoApplySfx,
            onChanged: onAutoApplySfxChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancementRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: value ? iconColor.withValues(alpha: 0.3) : AppTheme.borderGlass,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: value ? iconColor : AppTheme.mutedText, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: iconColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
