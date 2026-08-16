import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../controllers/editor_controller.dart';
import 'color_picker_row.dart';

class ColorSettingsSection extends ConsumerWidget {
  final ProjectConfigSchema config;
  const ColorSettingsSection({super.key, required this.config});

  Widget _buildSectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppTheme.secondaryText,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final style = config.style;
    final hs = config.highlightStyle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('CAPTION HIGHLIGHT COLORS'),
        const SizedBox(height: 12),
        
        ColorPickerRow(
          label: 'Highlight 1 (Active Word)',
          currentHex: hs.mainColor,
          onColorSelected: (hex) {
            ref.read(editorProvider.notifier).updateHighlightStyle(mainColor: hex);
          },
        ),
        ColorPickerRow(
          label: 'Highlight 2 (Emphasis 1)',
          currentHex: hs.secondColor,
          onColorSelected: (hex) {
            ref.read(editorProvider.notifier).updateHighlightStyle(secondColor: hex);
          },
        ),
        ColorPickerRow(
          label: 'Highlight 3 (Emphasis 2)',
          currentHex: hs.thirdColor,
          onColorSelected: (hex) {
            ref.read(editorProvider.notifier).updateHighlightStyle(thirdColor: hex);
          },
        ),
        ColorPickerRow(
          label: 'Base Subtitle Text Color',
          currentHex: style.color,
          onColorSelected: (hex) {
            ref.read(editorProvider.notifier).updateStyleProp('color', hex);
          },
        ),

        const Divider(color: Colors.white12, height: 32),
      ],
    );
  }
}
