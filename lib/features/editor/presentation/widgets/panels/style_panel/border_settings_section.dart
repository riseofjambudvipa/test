import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../controllers/editor_controller.dart';
import 'color_picker_row.dart';

class BorderSettingsSection extends ConsumerWidget {
  final ProjectConfigSchema config;
  const BorderSettingsSection({super.key, required this.config});

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('OUTLINES & EFFECTS'),
        const SizedBox(height: 12),

        // Stroke Outline Selector
        DropdownButtonFormField<String>(
          dropdownColor: AppTheme.cardBg,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Outline Stroke', border: OutlineInputBorder()),
          initialValue: const ['thick', 'none'].contains(config.stroke)
              ? config.stroke
              : 'none',
          items: const [
            DropdownMenuItem(value: 'thick', child: Text('Thick Outline')),
            DropdownMenuItem(value: 'none', child: Text('None (Flat)')),
          ],
          onChanged: (val) {
            if (val != null) {
              ref.read(editorProvider.notifier).updateStyleProp('stroke', val);
            }
          },
        ),
        const SizedBox(height: 12),

        // Text Animation Selector
        DropdownButtonFormField<String>(
          dropdownColor: AppTheme.cardBg,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Active Word Animation', border: OutlineInputBorder()),
          initialValue: const ['pop', 'bounce', 'kineticTilt', 'glowPulse', 'wordReveal', 'none'].contains(config.animation)
              ? config.animation
              : 'none',
          items: const [
            DropdownMenuItem(value: 'pop', child: Text('Active Pop')),
            DropdownMenuItem(value: 'bounce', child: Text('Active Bounce Jump')),
            DropdownMenuItem(value: 'kineticTilt', child: Text('Kinetic Bouncy Tilt')),
            DropdownMenuItem(value: 'glowPulse', child: Text('Glowing Active Pulse')),
            DropdownMenuItem(value: 'wordReveal', child: Text('Word Reveal Stagger')),
            DropdownMenuItem(value: 'none', child: Text('None (Static)')),
          ],
          onChanged: (val) {
            if (val != null) {
              ref.read(editorProvider.notifier).updateStyleProp('animation', val);
            }
          },
        ),
        const SizedBox(height: 12),

        // Shadow Toggle
        DropdownButtonFormField<String>(
          dropdownColor: AppTheme.cardBg,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Drop Shadow', border: OutlineInputBorder()),
          initialValue: const ['soft', 'none'].contains(config.shadow)
              ? config.shadow
              : 'none',
          items: const [
            DropdownMenuItem(value: 'soft', child: Text('Soft Shadow')),
            DropdownMenuItem(value: 'none', child: Text('None')),
          ],
          onChanged: (val) {
            if (val != null) {
              ref.read(editorProvider.notifier).updateStyleProp('shadow', val);
            }
          },
        ),
        const SizedBox(height: 12),

        // Background Fill Color
        ColorPickerRow(
          label: 'Background Fill (Optional)',
          currentHex: config.background ?? '#000000',
          onColorSelected: (hex) {
            ref.read(editorProvider.notifier).updateStyleProp('background', hex);
          },
        ),
        if (config.background != null)
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              icon: const Icon(Icons.clear_rounded, size: 14, color: Colors.redAccent),
              label: const Text('REMOVE BACKGROUND FILL', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              onPressed: () {
                ref.read(editorProvider.notifier).updateStyleProp('background', null);
              },
            ),
          ),
      ],
    );
  }
}
