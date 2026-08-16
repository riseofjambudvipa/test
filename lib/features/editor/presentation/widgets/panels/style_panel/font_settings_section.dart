import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/fonts/font_service.dart';
import '../../../../../../core/logger/logger_service.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../controllers/editor_controller.dart';

class FontSettingsSection extends ConsumerStatefulWidget {
  final ProjectConfigSchema config;
  const FontSettingsSection({super.key, required this.config});

  @override
  ConsumerState<FontSettingsSection> createState() => _FontSettingsSectionState();
}

class _FontSettingsSectionState extends ConsumerState<FontSettingsSection> {
  Future<void> _importCustomFont() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ttf', 'otf'],
        dialogTitle: 'Select TTF or OTF Font File',
      );
      if (result != null) {
        final bytes = await result.files.single.readAsBytes();
        
        final rawName = result.files.single.name;
        final fontName = rawName.contains('.') 
            ? rawName.substring(0, rawName.lastIndexOf('.')) 
            : rawName;
        final ext = result.files.single.extension;
        final registeredName = await FontService.instance.importFontBytes(
          bytes,
          fontName,
          fileExtension: ext,
        );
        if (registeredName != null) {
          if (!mounted) return;
          ref.read(editorProvider.notifier).updateStyleProp('fontFamily', registeredName);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully imported and applied custom font: "$registeredName"'),
                backgroundColor: AppTheme.accentGreen,
              ),
            );
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to load font file. Invalid data.')),
            );
          }
        }
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'FontSettingsSection', 'Error picking font: $e');
    }
  }

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

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    int fractionDigits = 0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value.toStringAsFixed(fractionDigits),
              style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: AppTheme.secondaryText),
            ),
          ],
        ),
        SliderTheme(
          data: AppTheme.premiumSliderTheme(context),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.config.style;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('FONT CONFIGURATION'),
        const SizedBox(height: 12),

        // Font Family Dropdown
        DropdownButtonFormField<String>(
          dropdownColor: AppTheme.cardBg,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Font Family',
            border: AppTheme.defaultBorder(),
            focusedBorder: AppTheme.focusedBorder(),
          ),
          initialValue: FontService.instance.availableFonts.contains(style.fontFamily)
              ? style.fontFamily
              : (FontService.instance.availableFonts.contains('Montserrat')
                  ? 'Montserrat'
                  : (FontService.instance.availableFonts.isNotEmpty
                      ? FontService.instance.availableFonts.first
                      : 'Montserrat')),
          items: (FontService.instance.availableFonts.isNotEmpty
              ? FontService.instance.availableFonts
              : ['Montserrat']).map((font) {
            return DropdownMenuItem(
              value: font,
              child: Text(font, style: TextStyle(fontFamily: font)),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              ref.read(editorProvider.notifier).updateStyleProp('fontFamily', val);
            }
          },
        ),
        const SizedBox(height: 12),

        // Import Custom Font Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.font_download_outlined, size: 14),
            label: const Text('IMPORT CUSTOM FONT (.ttf / .otf)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _importCustomFont,
          ),
        ),
        const SizedBox(height: 16),

        // Font Weight & Text Transform
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                dropdownColor: AppTheme.cardBg,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Font Weight',
                  border: AppTheme.defaultBorder(),
                  focusedBorder: AppTheme.focusedBorder(),
                ),
                initialValue: const ['100', '200', '300', '400', '500', '600', '700', '800', '900'].contains(style.fontWeight)
                    ? style.fontWeight
                    : '700',
                items: const [
                  DropdownMenuItem(value: '100', child: Text('Thin')),
                  DropdownMenuItem(value: '200', child: Text('Extra Light')),
                  DropdownMenuItem(value: '300', child: Text('Light')),
                  DropdownMenuItem(value: '400', child: Text('Normal')),
                  DropdownMenuItem(value: '500', child: Text('Medium')),
                  DropdownMenuItem(value: '600', child: Text('Semi Bold')),
                  DropdownMenuItem(value: '700', child: Text('Bold')),
                  DropdownMenuItem(value: '800', child: Text('Extra Bold')),
                  DropdownMenuItem(value: '900', child: Text('Black')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(editorProvider.notifier).updateStyleProp('fontWeight', val);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                dropdownColor: AppTheme.cardBg,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Text Case',
                  border: AppTheme.defaultBorder(),
                  focusedBorder: AppTheme.focusedBorder(),
                ),
                initialValue: const ['none', 'uppercase', 'capitalize'].contains(style.textTransform)
                    ? style.textTransform
                    : 'none',
                items: const [
                  DropdownMenuItem(value: 'none', child: Text('Normal')),
                  DropdownMenuItem(value: 'uppercase', child: Text('UPPERCASE')),
                  DropdownMenuItem(value: 'capitalize', child: Text('Capitalize')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(editorProvider.notifier).updateStyleProp('textTransform', val);
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Font Size Slider
        _buildSliderRow(
          label: 'Font Size',
          value: style.fontSize,
          min: 24,
          max: 72,
          onChanged: (val) {
            ref.read(editorProvider.notifier).updateStyleProp('fontSize', val);
          },
        ),
        const SizedBox(height: 8),

        // Letter Spacing Slider
        _buildSliderRow(
          label: 'Letter Spacing',
          value: style.letterSpacing ?? 0.0,
          min: 0.0,
          max: 8.0,
          fractionDigits: 1,
          onChanged: (val) {
            ref.read(editorProvider.notifier).updateStyleProp('letterSpacing', val);
          },
        ),
        const SizedBox(height: 8),

        // Line Height Slider
        _buildSliderRow(
          label: 'Line Height',
          value: style.lineHeight ?? 1.2,
          min: 0.8,
          max: 2.5,
          fractionDigits: 1,
          onChanged: (val) {
            ref.read(editorProvider.notifier).updateStyleProp('lineHeight', val);
          },
        ),

        const Divider(color: Colors.white12, height: 32),
      ],
    );
  }
}
