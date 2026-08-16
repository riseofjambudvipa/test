import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../../core/utils/web_download_helper.dart';
import '../../../../../app/theme.dart';
import '../../../../../app/theme_provider.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../domain/style_templates.dart';
import '../../controllers/editor_controller.dart';
import 'style_panel/font_settings_section.dart';
import 'style_panel/color_settings_section.dart';
import 'style_panel/border_settings_section.dart';
import '../../../../../core/utils/premium_blur_dialog.dart';

class StylePanel extends ConsumerStatefulWidget {
  const StylePanel({super.key});

  @override
  ConsumerState<StylePanel> createState() => _StylePanelState();
}

class _StylePanelState extends ConsumerState<StylePanel> {
  StyleCategory _selectedTemplateCategory = StyleCategory.all;
  List<StyleTemplate> _customPresets = [];
  bool _loadingPresets = true;

  @override
  void initState() {
    super.initState();
    _loadCustomPresets();
  }

  Future<void> _loadCustomPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('custom_presets') ?? [];
      final loaded = list.map((item) {
        try {
          return StyleTemplate.fromJson(jsonDecode(item) as Map<String, dynamic>);
        } catch (_) {
          return null;
        }
      }).whereType<StyleTemplate>().toList();

      if (mounted) {
        setState(() {
          _customPresets = loaded;
          _loadingPresets = false;
        });
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'StylePanel', 'Error loading custom presets: $e');
      if (mounted) {
        setState(() => _loadingPresets = false);
      }
    }
  }

  Future<void> _saveCustomPreset(String name) async {
    final stateVal = ref.read(editorProvider);
    final project = stateVal.project;
    if (project == null) return;

    final config = project.config;
    final style = config.style;
    final hs = config.highlightStyle;

    final newPreset = StyleTemplate(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name.toUpperCase(),
      category: StyleCategory.custom,
      fontFamily: style.fontFamily,
      fontWeight: style.fontWeight,
      textTransform: style.textTransform,
      color: style.color,
      fontSize: style.fontSize,
      top: style.top,
      mainColor: hs.mainColor,
      secondColor: hs.secondColor,
      thirdColor: hs.thirdColor,
      stroke: config.stroke,
      animation: config.animation,
      shadow: config.shadow,
      background: config.background,
      highlightBackground: style.highlightBackground,
      letterSpacing: style.letterSpacing,
      lineHeight: style.lineHeight,
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final updated = [..._customPresets, newPreset];
      final list = updated.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList('custom_presets', list);

      if (mounted) {
        setState(() {
          _customPresets = updated;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved style preset "$name" successfully!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'StylePanel', 'Error saving custom preset: $e');
    }
  }

  Future<void> _deleteCustomPreset(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final updated = _customPresets.where((p) => p.id != id).toList();
      final list = updated.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList('custom_presets', list);

      if (mounted) {
        setState(() {
          _customPresets = updated;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preset deleted successfully.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'StylePanel', 'Error deleting custom preset: $e');
    }
  }

  Future<void> _exportPresets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('custom_presets') ?? [];
      if (list.isEmpty) return;

      final jsonString = jsonEncode(list);
      if (kIsWeb) {
        downloadFileWeb(jsonString, 'capstudio_presets.json');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Style presets exported successfully!'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
        return;
      }
      final bytes = Uint8List.fromList(utf8.encode(jsonString));
      final path = await FilePicker.saveFile(
        dialogTitle: 'Export Style Presets',
        fileName: 'capstudio_presets.json',
        bytes: bytes,
      );
      if (path != null) {
        await File(path).writeAsString(jsonString);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Style presets exported successfully!'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'StylePanel', 'Error exporting presets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export presets: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _importPresets() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        final bytes = await result.files.single.readAsBytes();
        final content = utf8.decode(bytes);
        final list = (jsonDecode(content) as List).cast<String>();
        
        final prefs = await SharedPreferences.getInstance();
        final existing = prefs.getStringList('custom_presets') ?? [];
        
        final merged = <String>[...existing];
        for (final item in list) {
          try {
            final parsedItem = jsonDecode(item) as Map<String, dynamic>;
            final itemId = parsedItem['id'] as String;
            final hasMatch = merged.any((m) {
              try {
                return (jsonDecode(m) as Map<String, dynamic>)['id'] == itemId;
              } catch (_) {
                return false;
              }
            });
            if (!hasMatch) {
              merged.add(item);
            }
          } catch (_) {
            merged.add(item);
          }
        }

        await prefs.setStringList('custom_presets', merged);
        await _loadCustomPresets();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Imported style presets successfully!'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'StylePanel', 'Error importing presets: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import presets: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showSavePresetDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return _SavePresetDialog(
          onSave: (name) => _saveCustomPreset(name),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final project = ref.watch(editorProvider.select((s) => s.project));
    ref.watch(editorProvider.select((s) => s.revision));
    if (project == null) return const SizedBox.shrink();

    final config = project.config;
    final style = config.style;
    final hs = config.highlightStyle;

    // Filter templates by category
    final filteredTemplates = allTemplates.where((t) {
      if (_selectedTemplateCategory == StyleCategory.all) return true;
      return t.category == _selectedTemplateCategory;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 💾 Saved Presets Section
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _buildSectionHeader('MY SAVED PRESETS'),
              Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  TextButton.icon(
                    onPressed: _importPresets,
                    icon: Icon(Icons.upload_file_rounded, size: 14, color: AppTheme.accentCyan),
                    label: Text(
                      'IMPORT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _customPresets.isEmpty ? null : _exportPresets,
                    icon: Icon(Icons.download_rounded, size: 14, color: _customPresets.isEmpty ? Colors.white24 : AppTheme.accentGreen),
                    label: Text(
                      'EXPORT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _customPresets.isEmpty ? Colors.white24 : AppTheme.accentGreen,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showSavePresetDialog,
                    icon: Icon(Icons.add_rounded, size: 14, color: AppTheme.accentOrange),
                    label: Text(
                      'SAVE CURRENT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentOrange,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loadingPresets)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accentOrange),
                ),
              ),
            )
          else if (_customPresets.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDecoration(
                color: AppTheme.cardBg.withValues(alpha: 0.15),
                borderRadius: 12,
                borderOpacity: 0.06,
              ),
              child: Column(
                children: [
                  Icon(Icons.style_outlined, color: Colors.white.withValues(alpha: 0.2), size: 24),
                  const SizedBox(height: 8),
                  Text(
                    'No saved presets yet.',
                    style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customize style settings below and tap "Save Current" to create your own brand style.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: Colors.white.withValues(alpha: 0.3)),
                  ),
                ],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                mainAxisExtent: 68,
              ),
              itemCount: _customPresets.length,
              itemBuilder: (context, index) {
                final template = _customPresets[index];
                // Check if current settings match this preset
                final isActive = config.name.toLowerCase() == template.name.toLowerCase() ||
                    (style.fontFamily == template.fontFamily &&
                        style.color == template.color &&
                        hs.mainColor == template.mainColor &&
                        config.animation == template.animation &&
                        config.stroke == template.stroke);
                return _buildCustomTemplateCard(template, isActive);
              },
            ),

          const Divider(color: Colors.white12, height: 32),

          // 🎨 built-in templates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader('STYLE TEMPLATES'),
              IconButton(
                icon: const Icon(Icons.restore_rounded, size: 16, color: Colors.white60),
                tooltip: 'Reset to default style',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 16,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => PremiumBlurDialog(
                      maxWidth: 360,
                      glowColor: Colors.redAccent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Reset Styling?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This will reset all caption styles to default. Cannot be undone.',
                            style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('Cancel', style: TextStyle(color: AppTheme.secondaryText)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  final defaultTemplate = allTemplates.first;
                                  final newConfig = templateToConfig(defaultTemplate);
                                  ref.read(editorProvider.notifier).setFullConfig(newConfig);
                                  LoggerService.instance.log(LogLevel.action, 'StylePanel', 'Reset styling to default: ${defaultTemplate.name}');
                                },
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Category selector chips
          SizedBox(
            height: 32,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: templateCategories.map((cat) {
                final isSelected = _selectedTemplateCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(cat.displayName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    selected: isSelected,
                    selectedColor: AppTheme.accentOrange.withValues(alpha: 0.2),
                    backgroundColor: Colors.white.withValues(alpha: 0.03),
                    labelStyle: TextStyle(
                      color: isSelected ? AppTheme.accentOrange : AppTheme.secondaryText,
                    ),
                    side: BorderSide(
                      color: isSelected ? AppTheme.accentOrange.withValues(alpha: 0.4) : Colors.transparent,
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedTemplateCategory = cat;
                        });
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Templates Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 68,
            ),
            itemCount: filteredTemplates.length,
            itemBuilder: (context, index) {
              final template = filteredTemplates[index];
              final isActive = config.name.toLowerCase() == template.name.toLowerCase();
              return _buildTemplateCard(template, isActive);
            },
          ),

          const Divider(color: Colors.white12, height: 32),

          // 🗛 Text Font styling controls
          FontSettingsSection(config: config),

          _buildSectionHeader('SIZE & POSITION'),
          const SizedBox(height: 8),

          // Y Position Slider
          _buildSliderRow(
            label: 'Vertical Y Position (%)',
            value: style.top,
            min: 0,
            max: 100,
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateStyleProp('top', val);
            },
          ),
          const SizedBox(height: 8),

          // Word Highlight Box Toggle
          SwitchListTile(
            title: const Text('Word Highlight Box', style: TextStyle(fontSize: 13, color: Colors.white70)),
            subtitle: const Text('Colored pill background behind active spoken words', style: TextStyle(fontSize: 10, color: Colors.white30)),
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
            label: 'Max Words per Subtitle Chunk',
            value: config.subs.chunkSize.toDouble(),
            min: 1,
            max: 15,
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateStyleProp('chunkSize', val.toInt());
            },
          ),
          
          // Char Limit Slider
          _buildSliderRow(
            label: 'Max Characters per Subtitle Line',
            value: config.subs.chunkLineMaxLength.toDouble(),
            min: 10,
            max: 60,
            onChanged: (val) {
              ref.read(editorProvider.notifier).updateStyleProp('chunkLineMaxLength', val.toInt());
            },
          ),

          const Divider(color: Colors.white12, height: 32),

          ColorSettingsSection(config: config),

          BorderSettingsSection(config: config),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Color(0xFF71717A),
        letterSpacing: 1.5,
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
            Text(label, style: const TextStyle(fontSize: 13, color: Colors.white70)),
            Text(
              value.toStringAsFixed(fractionDigits),
              style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: Colors.white70),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 2,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            activeTrackColor: AppTheme.accentOrange,
            inactiveTrackColor: Colors.white12,
            thumbColor: AppTheme.accentOrange,
          ),
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

  Widget _buildTemplateCard(StyleTemplate template, bool isActive) {
    return GestureDetector(
      onTap: () {
        final newConfig = templateToConfig(template);
        ref.read(editorProvider.notifier).setFullConfig(newConfig);
      },
      child: GlassContainer(
        borderRadius: 8,
        borderOpacity: isActive ? 0.25 : 0.06,
        color: isActive ? AppTheme.accentOrange.withValues(alpha: 0.1) : AppTheme.cardBg.withValues(alpha: 0.4),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              template.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: template.fontFamily,
                fontWeight: template.fontWeight == '900' ? FontWeight.w900 : FontWeight.bold,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              template.category.name.toUpperCase(),
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: isActive ? AppTheme.accentOrange : AppTheme.mutedText,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildCustomTemplateCard(StyleTemplate template, bool isActive) {
    return GestureDetector(
      onTap: () {
        final newConfig = templateToConfig(template);
        ref.read(editorProvider.notifier).setFullConfig(newConfig);
      },
      child: Stack(
        children: [
          GlassContainer(
            width: double.infinity,
            height: double.infinity,
            borderRadius: 8,
            borderOpacity: isActive ? 0.25 : 0.06,
            color: isActive ? AppTheme.accentOrange.withValues(alpha: 0.1) : AppTheme.cardBg.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  template.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: template.fontFamily,
                    fontWeight: template.fontWeight == '900' ? FontWeight.w900 : FontWeight.bold,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'CUSTOM PRESET',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: isActive ? AppTheme.accentOrange : AppTheme.accentGreen,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                showDialog<void>(
                  context: context,
                    builder: (ctx) => PremiumBlurDialog(
                      maxWidth: 380,
                      glowColor: Colors.redAccent,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete Preset',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Are you sure you want to delete your custom preset "${template.name}"?',
                            style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: Text('Cancel', style: TextStyle(color: AppTheme.secondaryText)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _deleteCustomPreset(template.id);
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}



class _SavePresetDialog extends StatefulWidget {
  final void Function(String name) onSave;

  const _SavePresetDialog({required this.onSave});

  @override
  State<_SavePresetDialog> createState() => _SavePresetDialogState();
}

class _SavePresetDialogState extends State<_SavePresetDialog> {
  late TextEditingController controller;

  @override
  void initState() {
    super.initState();
    controller = TextEditingController();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBlurDialog(
      maxWidth: 360,
      glowColor: AppTheme.accentOrange,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Save Custom Style Preset',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            style: TextStyle(color: AppTheme.primaryText),
            decoration: InputDecoration(
              labelText: 'Preset Name',
              hintText: 'e.g., My Vibrant Pink',
              labelStyle: TextStyle(color: AppTheme.secondaryText),
              hintStyle: TextStyle(color: AppTheme.mutedText),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: AppTheme.defaultBorder(radius: 6),
              focusedBorder: AppTheme.focusedBorder(radius: 6),
              filled: true,
              fillColor: AppTheme.cardBg,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: TextStyle(color: AppTheme.secondaryText)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    Navigator.of(context).pop();
                    widget.onSave(name);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
