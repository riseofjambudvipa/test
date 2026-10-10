import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/utils/color_utils.dart';
import '../../../../../../core/video/retention_progress_bar_models.dart';
import '../../../controllers/editor_controller.dart';
import 'color_picker_row.dart';

/// Settings section for the dynamic video retention progress bar
/// (Submagic & OpusClip parity). Allows creators to toggle, style,
/// position, and preview the animated retention stripe on their video.
class RetentionBarSection extends ConsumerStatefulWidget {
  const RetentionBarSection({super.key});

  @override
  ConsumerState<RetentionBarSection> createState() => _RetentionBarSectionState();
}

class _RetentionBarSectionState extends ConsumerState<RetentionBarSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _previewController;

  static const List<(String, String)> _quickColors = [
    ('Ember', '#f97316'),
    ('Cyan', '#06b6d4'),
    ('Magenta', '#ec4899'),
    ('Acid', '#22c55e'),
    ('White', '#ffffff'),
    ('Gold', '#eab308'),
    ('Violet', '#8b5cf6'),
  ];

  @override
  void initState() {
    super.initState();
    _previewController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();
  }

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  void _updateConfig(RetentionProgressBarConfig Function(RetentionProgressBarConfig current) updater) {
    final current = ref.read(editorProvider).retentionBarConfig;
    final updated = updater(current);
    ref.read(editorProvider.notifier).updateRetentionBarConfig(updated);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(editorProvider.select((s) => s.retentionBarConfig));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: AppTheme.dividerColor, height: 32),

        // Section Title & Badge
        Row(
          children: [
            Icon(Icons.linear_scale_rounded, size: 16, color: AppTheme.accentOrange),
            const SizedBox(width: 8),
            Text(
              'RETENTION PROGRESS BAR',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppTheme.secondaryText,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppTheme.accentOrange.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Text(
                'VIRAL RETENTION',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.accentOrange,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Enable / Disable Master Switch
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: config.enabled
                ? AppTheme.accentOrange.withValues(alpha: 0.08)
                : AppTheme.cardBgElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: config.enabled
                  ? AppTheme.accentOrange.withValues(alpha: 0.35)
                  : AppTheme.borderGlass,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Animated Progress Bar',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Boosts completion rate by showing viewers real-time video progress',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: config.enabled,
                activeTrackColor: AppTheme.accentOrange,
                onChanged: (val) {
                  _updateConfig((c) => c.copyWith(enabled: val));
                },
              ),
            ],
          ),
        ),

        if (config.enabled) ...[
          const SizedBox(height: 14),

          // Live Animated Mini-Preview Box
          _buildLiveMiniPreview(config),

          const SizedBox(height: 16),

          // Quick Presets Row
          Text(
            'QUICK PRESETS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.mutedText,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPresetChip('Viral Ember', RetentionProgressBarConfig.viralEmber, config),
                const SizedBox(width: 6),
                _buildPresetChip('Electric Cyan', RetentionProgressBarConfig.electricCyan, config),
                const SizedBox(width: 6),
                _buildPresetChip('Hot Magenta', RetentionProgressBarConfig.hotMagenta, config),
                const SizedBox(width: 6),
                _buildPresetChip('Acid Green', RetentionProgressBarConfig.acidGreen, config),
                const SizedBox(width: 6),
                _buildPresetChip('Minimalist', RetentionProgressBarConfig.pureMinimalist, config),
                const SizedBox(width: 6),
                _buildPresetChip('Top Header', RetentionProgressBarConfig.topHeader, config),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Vertical Position Selector
          Text(
            'BAR POSITION',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.mutedText,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildPositionOption(
                  label: 'Bottom Edge',
                  icon: Icons.vertical_align_bottom_rounded,
                  isSelected: config.position == 'bottom',
                  onTap: () => _updateConfig((c) => c.copyWith(position: 'bottom')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildPositionOption(
                  label: 'Top Edge',
                  icon: Icons.vertical_align_top_rounded,
                  isSelected: config.position == 'top',
                  onTap: () => _updateConfig((c) => c.copyWith(position: 'top')),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Height Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'THICKNESS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.mutedText,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${config.height.toStringAsFixed(0)} px',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentOrange,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: AppTheme.premiumSliderTheme(context),
            child: Slider(
              value: config.height.clamp(2.0, 16.0),
              min: 2.0,
              max: 16.0,
              divisions: 14,
              onChanged: (val) {
                _updateConfig((c) => c.copyWith(height: val));
              },
            ),
          ),

          const SizedBox(height: 12),

          // Edge Padding Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EDGE OFFSET',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.mutedText,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${config.padding.toStringAsFixed(0)} px',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentCyan,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: AppTheme.premiumSliderTheme(context),
            child: Slider(
              value: config.padding.clamp(0.0, 24.0),
              min: 0.0,
              max: 24.0,
              divisions: 24,
              onChanged: (val) {
                _updateConfig((c) => c.copyWith(padding: val));
              },
            ),
          ),

          const SizedBox(height: 14),

          // Color Palette Swatches
          Text(
            'BAR COLOR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.mutedText,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _quickColors.map((item) {
              final isSelected = config.color.toLowerCase() == item.$2.toLowerCase();
              final color = ColorUtils.fromHex(item.$2);
              return InkWell(
                onTap: () => _updateConfig((c) => c.copyWith(color: item.$2)),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.25) : AppTheme.cardBgElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? color : AppTheme.borderGlass,
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.$1,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppTheme.primaryText : AppTheme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 12),

          // Custom Hex Color Picker
          ColorPickerRow(
            label: 'CUSTOM COLOR',
            currentHex: config.color,
            onColorSelected: (String newHex) {
              _updateConfig((c) => c.copyWith(color: newHex));
            },
          ),

          const SizedBox(height: 12),

          // Dark Background Track Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: AppTheme.glassDecoration(
              color: AppTheme.cardBgElevated,
              borderRadius: 8,
              borderOpacity: 0.06,
            ),
            child: Row(
              children: [
                Icon(Icons.contrast_rounded, size: 16, color: AppTheme.secondaryText),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dark Background Track',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      Text(
                        'Ensures contrast against light video footage',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppTheme.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: config.backgroundColor != null && config.backgroundColor!.isNotEmpty,
                  activeTrackColor: AppTheme.accentOrange,
                  onChanged: (val) {
                    _updateConfig(
                      (c) => c.copyWith(backgroundColor: val ? '#00000066' : ''),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLiveMiniPreview(RetentionProgressBarConfig config) {
    final barColor = ColorUtils.fromHex(config.color);
    final hasTrack = config.backgroundColor != null && config.backgroundColor!.isNotEmpty;
    final trackColor = hasTrack ? ColorUtils.fromHex(config.backgroundColor!) : Colors.transparent;

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.borderGlass),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Center preview label
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.play_arrow_rounded, size: 20, color: AppTheme.mutedText.withValues(alpha: 0.4)),
                  Text(
                    'LIVE RETENTION BAR PREVIEW',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.mutedText.withValues(alpha: 0.6),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            // Animated progress stripe
            AnimatedBuilder(
              animation: _previewController,
              builder: (context, _) {
                final isTop = config.position == 'top';
                final barH = config.height.clamp(2.0, 16.0);

                return Positioned(
                  top: isTop ? 0 : null,
                  bottom: !isTop ? 0 : null,
                  left: 0,
                  right: 0,
                  height: barH,
                  child: Container(
                    color: trackColor,
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _previewController.value,
                      child: Container(
                        decoration: BoxDecoration(
                          color: barColor,
                          boxShadow: [
                            BoxShadow(
                              color: barColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    RetentionProgressBarConfig preset,
    RetentionProgressBarConfig current,
  ) {
    final isSelected = current.color.toLowerCase() == preset.color.toLowerCase() &&
        current.position == preset.position;
    final presetColor = ColorUtils.fromHex(preset.color);

    return InkWell(
      onTap: () {
        ref.read(editorProvider.notifier).updateRetentionBarConfig(preset);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? presetColor.withValues(alpha: 0.2)
              : AppTheme.cardBgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? presetColor : AppTheme.borderGlass,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: presetColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryText : AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentOrange.withValues(alpha: 0.15)
              : AppTheme.cardBgElevated,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.accentOrange : AppTheme.borderGlass,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.accentOrange : AppTheme.secondaryText,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? AppTheme.primaryText : AppTheme.secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
