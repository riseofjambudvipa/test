import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/plugins/plugin_models.dart';
import '../../../../../../core/plugins/plugin_manager_service.dart';
import '../../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../../core/logger/logger_service.dart';

/// Modal dialog managing CapStudio community extensions, creator toolkits,
/// and `.capplugin` packages.
class PluginsDialog extends ConsumerStatefulWidget {
  const PluginsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const PluginsDialog(),
    );
  }

  @override
  ConsumerState<PluginsDialog> createState() => _PluginsDialogState();
}

class _PluginsDialogState extends ConsumerState<PluginsDialog> {
  List<PluginPackage> _plugins = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedTag = 'all';

  @override
  void initState() {
    super.initState();
    _loadPlugins();
  }

  Future<void> _loadPlugins() async {
    setState(() => _isLoading = true);
    final list = await PluginManagerService.instance.getInstalledPlugins();
    if (mounted) {
      setState(() {
        _plugins = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePlugin(PluginPackage plugin, bool isEnabled) async {
    await PluginManagerService.instance.togglePlugin(plugin.manifest.id, isEnabled);
    await _loadPlugins();
  }

  Future<void> _importPluginFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['capplugin', 'json'],
      );

      if (result == null || result.files.isEmpty) return;

      String content;
      if (kIsWeb) {
        final bytes = await result.files.first.xFile.readAsBytes();
        content = utf8.decode(bytes);
      } else {
        final path = result.files.first.path;
        if (path == null) return;
        content = await File(path).readAsString();
      }

      final installed = await PluginManagerService.instance.installPluginFromJson(content);
      await _loadPlugins();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Installed plugin: ${installed.manifest.name}!',
              style: TextStyle(color: AppTheme.primaryText),
            ),
            backgroundColor: AppTheme.cardBgElevated,
          ),
        );
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'PluginsDialog', 'Import failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to import plugin: $e',
              style: TextStyle(color: AppTheme.accentRed),
            ),
            backgroundColor: AppTheme.cardBgElevated,
          ),
        );
      }
    }
  }

  Future<void> _exportPlugin(PluginPackage plugin) async {
    try {
      final jsonStr = PluginManagerService.instance.exportPluginPackage(plugin);
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      if (kIsWeb) {
        await Clipboard.setData(ClipboardData(text: jsonStr));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Plugin package JSON copied to clipboard!',
                style: TextStyle(color: AppTheme.primaryText),
              ),
              backgroundColor: AppTheme.cardBgElevated,
            ),
          );
        }
        return;
      }

      final result = await FilePicker.saveFile(
        dialogTitle: 'Export Plugin Package',
        fileName: '${plugin.manifest.id}.capplugin',
        type: FileType.custom,
        allowedExtensions: ['capplugin', 'json'],
        bytes: bytes,
      );

      if (result != null) {
        final file = File(result);
        await file.writeAsString(jsonStr);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Exported "${plugin.manifest.name}" successfully!',
                style: TextStyle(color: AppTheme.primaryText),
              ),
              backgroundColor: AppTheme.cardBgElevated,
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'PluginsDialog', 'Export failed: $e');
    }
  }

  Future<void> _deletePlugin(PluginPackage plugin) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => PremiumBlurDialog(
        maxWidth: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Uninstall Plugin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to uninstall "${plugin.manifest.name}"?',
              style: TextStyle(fontSize: 13, color: AppTheme.secondaryText),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('CANCEL', style: TextStyle(color: AppTheme.secondaryText)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentRed,
                    foregroundColor: AppTheme.onAccentText,
                  ),
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('UNINSTALL'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirm == true) {
      await PluginManagerService.instance.uninstallPlugin(plugin.manifest.id);
      await _loadPlugins();
    }
  }

  void _showPluginDetails(PluginPackage plugin) {
    showDialog<void>(
      context: context,
      builder: (ctx) => PremiumBlurDialog(
        maxWidth: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _buildPluginIcon(plugin.manifest.icon, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plugin.manifest.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryText,
                        ),
                      ),
                      Text(
                        'v${plugin.manifest.version} by ${plugin.manifest.author}',
                        style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: AppTheme.secondaryText),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plugin.manifest.description,
              style: TextStyle(fontSize: 13, color: AppTheme.primaryText),
            ),
            const SizedBox(height: 14),
            _buildDetailSection('Caption Templates (${plugin.styleTemplates.length})', [
              for (final t in plugin.styleTemplates)
                '${t["name"] ?? "Template"} (${t["fontFamily"] ?? "Default"})',
            ]),
            const SizedBox(height: 8),
            _buildDetailSection('Viral Retention Hooks (${plugin.customHooks.length})', [
              for (final h in plugin.customHooks)
                '${h.tag.toUpperCase()}: ${h.explanation}',
            ]),
            const SizedBox(height: 8),
            _buildDetailSection('Keyword Emojis (${plugin.customEmojis.length})', [
              plugin.customEmojis.entries.map((e) => '${e.key} → ${e.value}').join(', '),
            ]),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: AppTheme.onAccentText,
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('CLOSE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<String> items) {
    if (items.isEmpty || (items.length == 1 && items.first.isEmpty)) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.cardBgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderGlass),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentOrange,
            ),
          ),
          const SizedBox(height: 4),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(
                '• $item',
                style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
              ),
            ),
        ],
      ),
    );
  }

  IconData _mapIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'bolt':
        return Icons.bolt_rounded;
      case 'movie':
        return Icons.movie_filter_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'auto_awesome':
        return Icons.auto_awesome_rounded;
      case 'star':
        return Icons.star_rounded;
      default:
        return Icons.extension_rounded;
    }
  }

  Widget _buildPluginIcon(String iconName, {double size = 20}) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.accentOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.accentOrange.withValues(alpha: 0.3),
        ),
      ),
      child: Icon(
        _mapIconData(iconName),
        color: AppTheme.accentOrange,
        size: size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _plugins.where((p) {
      if (_selectedTag != 'all' &&
          !p.manifest.tags.any((t) => t.toLowerCase() == _selectedTag)) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = p.manifest.name.toLowerCase().contains(query);
        final matchesDesc = p.manifest.description.toLowerCase().contains(query);
        final matchesAuthor = p.manifest.author.toLowerCase().contains(query);
        if (!matchesName && !matchesDesc && !matchesAuthor) return false;
      }
      return true;
    }).toList();

    return PremiumBlurDialog(
      maxWidth: 720,
      glowColor: AppTheme.accentOrange,
      glowOpacity: 0.12,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dialog Header
            Row(
              children: [
                _buildPluginIcon('extension', size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community Plugins & Creator Packs',
                        style: TextStyle(
                          color: AppTheme.primaryText,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Modular caption presets, viral hook detectors & emoji triggers (.capplugin)',
                        style: TextStyle(
                          color: AppTheme.secondaryText,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _importPluginFile,
                  icon: const Icon(Icons.file_open_rounded, size: 15),
                  label: const Text(
                    'IMPORT PLUGIN',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentOrange,
                    foregroundColor: AppTheme.onAccentText,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close, color: AppTheme.secondaryText, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Search Bar & Tag Filters
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderGlass),
              ),
              child: TextField(
                style: TextStyle(color: AppTheme.primaryText, fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Search creator packs, hooks, or authors...',
                  hintStyle: TextStyle(color: AppTheme.mutedText, fontSize: 12),
                  prefixIcon: Icon(Icons.search, size: 16, color: AppTheme.mutedText),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTagChip('All', 'all'),
                  const SizedBox(width: 4),
                  _buildTagChip('Shorts', 'shorts'),
                  const SizedBox(width: 4),
                  _buildTagChip('Cinema', 'cinema'),
                  const SizedBox(width: 4),
                  _buildTagChip('Fitness', 'fitness'),
                  const SizedBox(width: 4),
                  _buildTagChip('Tech', 'tech'),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Plugins List
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final plugin = filtered[index];
                            return _buildPluginCard(plugin);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String label, String tag) {
    final isSelected = _selectedTag == tag;
    return InkWell(
      onTap: () => setState(() => _selectedTag = tag),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.accentOrange.withValues(alpha: 0.2)
              : AppTheme.cardBgElevated,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppTheme.accentOrange : AppTheme.borderGlass,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.accentOrange : AppTheme.secondaryText,
          ),
        ),
      ),
    );
  }

  Widget _buildPluginCard(PluginPackage plugin) {
    final isEnabled = plugin.isEnabled;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEnabled ? AppTheme.cardBgElevated : AppTheme.cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isEnabled ? AppTheme.borderGlass : AppTheme.borderGlass.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPluginIcon(plugin.manifest.icon, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plugin.manifest.name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isEnabled ? AppTheme.primaryText : AppTheme.mutedText,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: plugin.isBundled
                                ? AppTheme.accentCyan.withValues(alpha: 0.15)
                                : AppTheme.accentPink.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: plugin.isBundled
                                  ? AppTheme.accentCyan.withValues(alpha: 0.3)
                                  : AppTheme.accentPink.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            plugin.isBundled ? 'OFFICIAL' : 'COMMUNITY',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: plugin.isBundled ? AppTheme.accentCyan : AppTheme.accentPink,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'v${plugin.manifest.version} • by ${plugin.manifest.author}',
                      style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isEnabled,
                activeThumbColor: AppTheme.accentOrange,
                onChanged: (val) => _togglePlugin(plugin, val),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            plugin.manifest.description,
            style: TextStyle(
              fontSize: 12,
              color: isEnabled ? AppTheme.secondaryText : AppTheme.mutedText,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFeatureBadge(
                  '${plugin.styleTemplates.length} Styles',
                  Icons.palette_outlined,
                ),
                const SizedBox(width: 6),
                _buildFeatureBadge(
                  '${plugin.customHooks.length} Hooks',
                  Icons.trending_up_rounded,
                ),
                const SizedBox(width: 6),
                _buildFeatureBadge(
                  '${plugin.customEmojis.length} Emojis',
                  Icons.emoji_emotions_outlined,
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: () => _showPluginDetails(plugin),
                  child: Text(
                    'INSPECT',
                    style: TextStyle(fontSize: 11, color: AppTheme.accentOrange),
                  ),
                ),
                IconButton(
                  tooltip: 'Export .capplugin',
                  icon: Icon(Icons.share_outlined, size: 16, color: AppTheme.secondaryText),
                  onPressed: () => _exportPlugin(plugin),
                ),
                if (!plugin.isBundled)
                  IconButton(
                    tooltip: 'Uninstall Plugin',
                    icon: Icon(Icons.delete_outline, size: 16, color: AppTheme.accentRed),
                    onPressed: () => _deletePlugin(plugin),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.borderGlass),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppTheme.mutedText),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 10, color: AppTheme.secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.extension_off_outlined, size: 40, color: AppTheme.mutedText),
          const SizedBox(height: 12),
          Text(
            'No Plugins Found',
            style: TextStyle(color: AppTheme.primaryText, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Try clearing your search query or import a new .capplugin package.',
            style: TextStyle(color: AppTheme.secondaryText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
