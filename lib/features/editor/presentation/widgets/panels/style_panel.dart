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
import 'style_panel/position_settings_section.dart';
import 'style_panel/retention_bar_section.dart';
import 'style_panel/save_preset_dialog.dart';
import 'style_panel/community_presets_dialog.dart';
import 'style_panel/brand_kit_dialog.dart';
import 'style_panel/plugins_dialog.dart';
import '../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../l10n/app_localizations.dart';

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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.presetSaved(name) ?? 'Saved style preset "$name" successfully!'),
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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n?.presetDeleted ?? 'Preset deleted successfully.'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'StylePanel', 'Error deleting custom preset: $e');
    }
  }

  Future<void> _exportPresets() async {
    // Capture l10n before any async gaps
    final l10n = AppLocalizations.of(context);
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
              content: Text(l10n?.presetExported ?? 'Style presets exported successfully!'),
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
              content: Text(l10n?.presetExported ?? 'Style presets exported successfully!'),
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
            content: Text(
                l10n?.errorPresetExportFailed(e.toString()) ??
                    'Failed to export presets: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  Future<void> _importPresets() async {
    // Capture l10n before any async gaps
    final l10n = AppLocalizations.of(context);
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
              } catch (e) {
                LoggerService.instance.debug('Error decoding preset while matching: $e');
                return false;
              }
            });
            if (!hasMatch) {
              merged.add(item);
            }
          } catch (e) {
            LoggerService.instance.debug('Error parsing imported preset item: $e');
            merged.add(item);
          }
        }

        await prefs.setStringList('custom_presets', merged);
        await _loadCustomPresets();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n?.presetImported ?? 'Imported style presets successfully!'),
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
            content: Text(
                l10n?.errorPresetImportFailed(e.toString()) ??
                    'Failed to import presets: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  void _showSavePresetDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return SavePresetDialog(
          onSave: (name) => _saveCustomPreset(name),
        );
      },
    );
  }

  void _applyTemplate(StyleTemplate template) {
    final stateVal = ref.read(editorProvider);
    final project = stateVal.project;
    final newConfig = templateToConfig(template, currentEmojiPack: project?.config.emojiPack, existingSubs: project?.config.subs);
    LoggerService.instance.log(LogLevel.action, 'StylePanel', 'Applied template: ${template.name} (${template.fontFamily})');
    ref.read(editorProvider.notifier).setFullConfig(newConfig);

    if (project != null && project.words.isNotEmpty) {
      final firstStart = project.words.first.start ?? 0.0;
      final lastEnd = project.words.last.end ?? project.duration;
      if (stateVal.currentTime < firstStart || stateVal.currentTime > lastEnd) {
        ref.read(editorProvider.notifier).setCurrentTime(firstStart);
      }
    }
  }

  void _showCommunityPresetsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return CommunityPresetsDialog(
          onApplyPreset: (template) => _applyTemplate(template),
          onPacksUpdated: () => _loadCustomPresets(),
        );
      },
    );
  }

  void _showBrandKitDialog() {
    BrandKitDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final project = ref.watch(editorProvider.select((s) => s.project));
    ref.watch(editorProvider.select((s) => s.revision));
    if (project == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
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
              _buildSectionHeader(l10n?.mySavedPresets ?? 'MY SAVED PRESETS'),
              Wrap(
                spacing: 2,
                runSpacing: 2,
                children: [
                  TextButton.icon(
                    onPressed: _importPresets,
                    icon: Icon(Icons.upload_file_rounded, size: 14, color: AppTheme.accentCyan),
                    label: Text(
                      l10n?.btnImport ?? 'IMPORT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accentCyan,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _customPresets.isEmpty ? null : _exportPresets,
                    icon: Icon(Icons.download_rounded, size: 14, color: _customPresets.isEmpty ? AppTheme.mutedText : AppTheme.accentGreen),
                    label: Text(
                      l10n?.btnExportCaps ?? 'EXPORT',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _customPresets.isEmpty ? AppTheme.mutedText : AppTheme.accentGreen,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _showSavePresetDialog,
                    icon: Icon(Icons.add_rounded, size: 14, color: AppTheme.accentOrange),
                    label: Text(
                      l10n?.btnSaveCurrent ?? 'SAVE CURRENT',
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
                  Icon(Icons.style_outlined, color: AppTheme.mutedText, size: 24),
                  const SizedBox(height: 8),
                  Text(
                    'No saved presets yet.',
                    style: TextStyle(fontSize: 11, color: AppTheme.secondaryText, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Customize style settings below and tap "Save Current" to create your own brand style.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 9, color: AppTheme.mutedText),
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

          Divider(color: AppTheme.dividerColor, height: 32),

          // 🎨 built-in templates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSectionHeader(l10n?.styleTemplatesHeader ?? 'STYLE TEMPLATES'),
              IconButton(
                icon: Icon(Icons.restore_rounded, size: 16, color: AppTheme.secondaryText),
                tooltip: l10n?.resetToDefaultStyle ?? 'Reset to default style',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 16,
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => PremiumBlurDialog(
                      maxWidth: 360,
                      glowColor: AppTheme.accentRed,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n?.resetStylingTitle ?? 'Reset Styling?',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryText,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n?.resetStylingDesc ?? 'This will reset all caption styles to default. Cannot be undone.',
                            style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(l10n?.btnCancel ?? 'Cancel', style: TextStyle(color: AppTheme.secondaryText)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.accentRed,
                                  foregroundColor: AppTheme.onAccentText,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Navigator.pop(ctx);
                                  final project = ref.read(editorProvider).project;
                                  final defaultTemplate = allTemplates.first;
                                  final newConfig = templateToConfig(defaultTemplate, currentEmojiPack: project?.config.emojiPack, existingSubs: project?.config.subs);
                                  ref.read(editorProvider.notifier).setFullConfig(newConfig);
                                  LoggerService.instance.log(LogLevel.action, 'StylePanel', 'Reset styling to default: ${defaultTemplate.name}');
                                },
                                child: Text(l10n?.btnReset ?? 'Reset'),
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
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _showBrandKitDialog,
                  icon: Icon(Icons.verified_user_rounded, size: 14, color: AppTheme.accentCyan),
                  label: Text(
                    'BRAND KITS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentCyan,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: _showCommunityPresetsDialog,
                  icon: Icon(Icons.auto_awesome_rounded, size: 14, color: AppTheme.accentPink),
                  label: Text(
                    'COMMUNITY PACKS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentPink,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: () => PluginsDialog.show(context),
                  icon: Icon(Icons.extension_rounded, size: 14, color: AppTheme.accentOrange),
                  label: Text(
                    'PLUGINS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentOrange,
                    ),
                  ),
                ),
              ],
            ),
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
                    backgroundColor: AppTheme.cardBgElevated,
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

          Divider(color: AppTheme.dividerColor, height: 32),

          // 🗛 Text Font styling controls
          FontSettingsSection(config: config),

          PositionSettingsSection(config: config),

          ColorSettingsSection(config: config),

          BorderSettingsSection(config: config),

          const RetentionBarSection(),
        ],
      ),
    );
  }

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

  Widget _buildTemplateCard(StyleTemplate template, bool isActive) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _applyTemplate(template),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          decoration: AppTheme.glassDecoration(
            borderRadius: 8,
            borderOpacity: isActive ? 0.35 : 0.08,
            color: isActive ? AppTheme.accentOrange.withValues(alpha: 0.15) : AppTheme.cardBgElevated,
          ),
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
                  color: AppTheme.primaryText,
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
      ),
    );
  }

  Widget _buildCustomTemplateCard(StyleTemplate template, bool isActive) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _applyTemplate(template),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: AppTheme.glassDecoration(
                borderRadius: 8,
                borderOpacity: isActive ? 0.35 : 0.08,
                color: isActive ? AppTheme.accentOrange.withValues(alpha: 0.15) : AppTheme.cardBgElevated,
              ),
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
                      color: AppTheme.primaryText,
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
                      glowColor: AppTheme.accentRed,
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
                                  backgroundColor: AppTheme.accentRed,
                                  foregroundColor: AppTheme.onAccentText,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  _deleteCustomPreset(template.id);
                                },
                                child: Builder(
                                  builder: (context) {
                                    final l10n = AppLocalizations.of(context);
                                    return Text(l10n?.btnDelete ?? 'Delete');
                                  },
                                ),
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
                  color: AppTheme.mutedText,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

