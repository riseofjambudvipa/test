import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../controllers/editor_controller.dart';
import '../../../../../../l10n/app_localizations.dart';

/// Position, alignment, word highlight box, and subtitle chunking controls
/// extracted from [StylePanel] for modularity and maintainability.
class PositionSettingsSection extends ConsumerWidget {
  final ProjectConfigSchema config;

  const PositionSettingsSection({
    super.key,
    required this.config,
  });

  Widget _buildSectionHeader(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: AppTheme.secondaryText,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSliderRow({
    required BuildContext context,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeStart,
    ValueChanged<double>? onChangeEnd,
    int fractionDigits = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: AppTheme.primaryText)),
            Text(
              value.toStringAsFixed(fractionDigits),
              style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppTheme.secondaryText),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: AppTheme.accentOrange,
            inactiveTrackColor: AppTheme.dividerColor,
            thumbColor: AppTheme.accentOrange,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
            onChangeStart: onChangeStart,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final style = config.style;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n?.sizeAndPosition ?? 'SIZE & POSITION'),
        const SizedBox(height: 8),

        // Y Position Slider
        _buildSliderRow(
          context: context,
          label: l10n?.verticalYPos ?? 'Vertical Y Position (%)',
          value: style.top,
          min: 0,
          max: 100,
          onChangeStart: (_) => ref.read(editorProvider.notifier).beginHistoryBatch(),
          onChangeEnd: (_) => ref.read(editorProvider.notifier).endHistoryBatch(),
          onChanged: (val) {
            ref.read(editorProvider.notifier).updateStyleProp('top', val);
          },
        ),
        const SizedBox(height: 8),

        // X Position Slider
        _buildSliderRow(
          context: context,
          label: 'Horizontal X Position (%)',
          value: style.left,
          min: 0,
          max: 100,
          onChangeStart: (_) => ref.read(editorProvider.notifier).beginHistoryBatch(),
          onChangeEnd: (_) => ref.read(editorProvider.notifier).endHistoryBatch(),
          onChanged: (val) {
            ref.read(editorProvider.notifier).updateStyleProp('left', val);
          },
        ),
        const SizedBox(height: 4),

        // Quick Alignment Buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  side: BorderSide(
                    color: (style.left - 20.0).abs() < 2.0 ? AppTheme.accentOrange : AppTheme.borderGlass,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {
                  ref.read(editorProvider.notifier).updateStyleProp('left', 20.0);
                },
                child: Text('Left (20%)', style: TextStyle(fontSize: 10, color: AppTheme.secondaryText)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  side: BorderSide(
                    color: (style.left - 50.0).abs() < 2.0 ? AppTheme.accentOrange : AppTheme.borderGlass,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {
                  ref.read(editorProvider.notifier).updateStyleProp('left', 50.0);
                },
                child: Text('Center (50%)', style: TextStyle(fontSize: 10, color: AppTheme.secondaryText)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  side: BorderSide(
                    color: (style.left - 80.0).abs() < 2.0 ? AppTheme.accentOrange : AppTheme.borderGlass,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                onPressed: () {
                  ref.read(editorProvider.notifier).updateStyleProp('left', 80.0);
                },
                child: Text('Right (80%)', style: TextStyle(fontSize: 10, color: AppTheme.secondaryText)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Word Highlight Box Toggle
        SwitchListTile(
          title: Text(l10n?.wordHighlightBox ?? 'Word Highlight Box', style: TextStyle(fontSize: 13, color: AppTheme.primaryText)),
          subtitle: Text(l10n?.wordHighlightBoxDesc ?? 'Colored pill background behind active spoken words', style: TextStyle(fontSize: 10, color: AppTheme.mutedText)),
          value: style.highlightBackground ?? false,
          activeThumbColor: AppTheme.accentOrange,
          contentPadding: EdgeInsets.zero,
          onChanged: (v) {
            ref.read(editorProvider.notifier).updateStyleProp('highlightBackground', v);
          },
        ),
        const SizedBox(height: 8),

        // Chunk Size Slider
        _buildSliderRow(
          context: context,
          label: l10n?.maxWordsPerChunk ?? 'Max Words per Subtitle Chunk',
          value: config.subs.chunkSize.toDouble(),
          min: 1,
          max: 15,
          onChangeStart: (_) => ref.read(editorProvider.notifier).beginHistoryBatch(),
          onChangeEnd: (_) => ref.read(editorProvider.notifier).endHistoryBatch(),
          onChanged: (val) {
            ref.read(editorProvider.notifier).updateStyleProp('chunkSize', val.toInt());
          },
        ),

        // Char Limit Slider
        _buildSliderRow(
          context: context,
          label: l10n?.maxCharsPerLine ?? 'Max Characters per Subtitle Line',
          value: config.subs.chunkLineMaxLength.toDouble(),
          min: 10,
          max: 60,
          onChangeStart: (_) => ref.read(editorProvider.notifier).beginHistoryBatch(),
          onChangeEnd: (_) => ref.read(editorProvider.notifier).endHistoryBatch(),
          onChanged: (val) {
            ref.read(editorProvider.notifier).updateStyleProp('chunkLineMaxLength', val.toInt());
          },
        ),

        Divider(color: AppTheme.dividerColor, height: 32),
      ],
    );
  }
}
