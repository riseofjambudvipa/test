import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../app/theme.dart';
import '../../../../../app/theme_provider.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../core/settings/settings_service.dart';
import '../../../../../core/utils/platform_utils.dart' as platform_utils;
import '../../../../../l10n/app_localizations.dart';

class ExportSettingsSection extends ConsumerStatefulWidget {
  const ExportSettingsSection({super.key});

  @override
  ConsumerState<ExportSettingsSection> createState() => _ExportSettingsSectionState();
}

class _ExportSettingsSectionState extends ConsumerState<ExportSettingsSection> {
  final _outputFolderController = TextEditingController();
  bool _alwaysAskExportPath = false;
  int _exportThreads = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _outputFolderController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    final settings = SettingsService.instance;
    _outputFolderController.text = settings.outputFolder ?? '';
    _alwaysAskExportPath = settings.alwaysAskExportPath;
    _exportThreads = settings.exportThreads;
  }

  Future<void> _pickDirectory() async {
    try {
      final result = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Default Export Directory',
      );
      if (!mounted) return;
      if (result != null) {
        // FIX (audit): a deleted/unwritable folder was previously accepted
        // silently and only failed at export time. Reject it up front.
        if (!kIsWeb && !Directory(result).existsSync()) {
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.errorFolderNotAccessible ??
                    'Selected folder does not exist or is not accessible.',
              ),
              backgroundColor: AppTheme.accentRed,
            ),
          );
          return;
        }
        setState(() {
          _outputFolderController.text = result;
        });
        await SettingsService.instance.setOutputFolder(result);
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'ExportSettingsSection', 'Failed to pick directory: $e');
    }
  }

  Widget _buildSectionHeader(String title, IconData icon, [AppThemeData? themeData]) {
    final primaryColor = themeData?.primaryText ?? AppTheme.primaryText;
    final accentColor = themeData?.accentOrange ?? AppTheme.accentOrange;
    return Row(
      children: [
        Icon(icon, size: 18, color: accentColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: primaryColor,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(l10n?.defaultOutputsTitle ?? 'Default Outputs', Icons.folder_outlined, themeData),
        const SizedBox(height: 16),
        if (platform_utils.isWeb) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glassDecoration(
              color: AppTheme.cardBg,
              borderRadius: 8,
              borderOpacity: 0.08,
            ),
            child: Row(
              children: [
                Icon(Icons.download_rounded, color: AppTheme.accentOrange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Videos and subtitles exported in the browser are downloaded directly to your default Downloads folder.',
                    style: TextStyle(fontSize: 12, color: AppTheme.secondaryText, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ] else if (platform_utils.isMobile) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: AppTheme.glassDecoration(
              color: AppTheme.cardBg,
              borderRadius: 8,
              borderOpacity: 0.08,
            ),
            child: Row(
              children: [
                Icon(Icons.photo_library_outlined, color: AppTheme.accentOrange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Exported videos are automatically saved directly to your device Gallery / Photos (Movies/CapStudio).',
                    style: TextStyle(fontSize: 12, color: AppTheme.secondaryText, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ] else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n?.defaultExportFolder ?? 'Default Export Folder', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryText)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDirectory,
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.cardBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppTheme.borderGlass),
                        ),
                        child: Text(
                          _outputFolderController.text.isNotEmpty
                              ? _outputFolderController.text
                              : 'System default downloads/documents folder',
                          style: TextStyle(fontSize: 12, color: AppTheme.primaryText),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.folder_open, color: AppTheme.secondaryText),
                    onPressed: _pickDirectory,
                    tooltip: 'Choose directory',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n?.alwaysAskExportPath ?? 'Always Ask for Export Path', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryText)),
                        const SizedBox(height: 4),
                        Text(l10n?.alwaysAskExportPathDesc ?? 'Prompts for output path on each export (Desktop)', style: TextStyle(fontSize: 11, color: AppTheme.mutedText)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _alwaysAskExportPath,
                    activeThumbColor: AppTheme.accentOrange,
                    onChanged: (val) {
                      setState(() => _alwaysAskExportPath = val);
                      SettingsService.instance.setAlwaysAskExportPath(val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
        if (platform_utils.isDesktop) ...[
          Divider(color: AppTheme.borderGlass, height: 32),
          _buildSectionHeader(l10n?.performanceTitle ?? 'Performance', Icons.tune_rounded),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n?.exportCpuThreads ?? 'Export CPU Threads', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryText)),
                        const SizedBox(height: 4),
                        Text(l10n?.exportCpuThreadsDesc ?? 'Processor threads to use for rendering (Auto scales safely per device)', style: TextStyle(fontSize: 11, color: AppTheme.mutedText)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SliderTheme(
                        data: AppTheme.premiumSliderTheme(context),
                        child: Slider(
                          value: _exportThreads.clamp(0, Platform.numberOfProcessors).toDouble(),
                          min: 0,
                          max: Platform.numberOfProcessors.toDouble(),
                          divisions: Platform.numberOfProcessors,
                          activeColor: AppTheme.accentOrange,
                          inactiveColor: AppTheme.dividerColor,
                          label: _exportThreads == 0 ? 'Auto' : '$_exportThreads',
                          onChanged: (val) {
                            setState(() => _exportThreads = val.toInt());
                          },
                          onChangeEnd: (val) {
                            SettingsService.instance.setExportThreads(val.toInt());
                          },
                        ),
                      ),
                      SizedBox(
                        width: 45,
                        child: Text(
                          _exportThreads == 0 ? 'Auto' : '$_exportThreads',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
        Divider(color: AppTheme.borderGlass, height: 32),
      ],
    );
  }

  void reloadSettings() {
    setState(() {
      _loadSettings();
    });
  }
}
