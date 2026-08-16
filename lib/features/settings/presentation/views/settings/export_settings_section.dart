import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../core/settings/settings_service.dart';

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
        setState(() {
          _outputFolderController.text = result;
        });
        await SettingsService.instance.setOutputFolder(result);
      }
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'ExportSettingsSection', 'Failed to pick directory: $e');
    }
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: Colors.white,
        letterSpacing: 1.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('📁 Default Outputs'),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Default Export Folder', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
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
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        _outputFolderController.text.isNotEmpty
                            ? _outputFolderController.text
                            : 'System default downloads/documents folder',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  onPressed: _pickDirectory,
                  tooltip: 'Choose directory',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Always Ask for Export Path', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
                      SizedBox(height: 4),
                      Text('Prompts for output path on each export (Desktop)', style: TextStyle(fontSize: 11, color: Colors.white30)),
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
        const Divider(color: Colors.white10, height: 40),
        _buildSectionHeader('⚙️ Performance'),
        const SizedBox(height: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Export CPU Threads', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
                      SizedBox(height: 4),
                      Text('Processor threads to use for rendering (Auto scales safely per device)', style: TextStyle(fontSize: 11, color: Colors.white30)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Slider(
                      value: _exportThreads.clamp(0, kIsWeb ? 16 : Platform.numberOfProcessors).toDouble(),
                      min: 0,
                      max: (kIsWeb ? 16 : Platform.numberOfProcessors).toDouble(),
                      divisions: kIsWeb ? 16 : Platform.numberOfProcessors,
                      activeColor: AppTheme.accentOrange,
                      inactiveColor: Colors.white10,
                      label: _exportThreads == 0 ? 'Auto' : '$_exportThreads',
                      onChanged: (val) {
                        setState(() => _exportThreads = val.toInt());
                        SettingsService.instance.setExportThreads(val.toInt());
                      },
                    ),
                    SizedBox(
                      width: 45,
                      child: Text(
                        _exportThreads == 0 ? 'Auto' : '$_exportThreads',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const Divider(color: Colors.white10, height: 40),
      ],
    );
  }

  void reloadSettings() {
    setState(() {
      _loadSettings();
    });
  }
}
