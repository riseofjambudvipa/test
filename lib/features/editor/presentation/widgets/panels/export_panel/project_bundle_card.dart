import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../../../../core/project/project_bundle_service.dart';
import '../../../../../../core/utils/web_download_helper.dart';
import '../../../controllers/editor_controller.dart';

/// Card in the Export Panel allowing creators to export or import
/// portable project bundles (.capstudio) for backups and cross-device collaboration.
class ProjectBundleCard extends ConsumerStatefulWidget {
  final Project project;

  const ProjectBundleCard({super.key, required this.project});

  @override
  ConsumerState<ProjectBundleCard> createState() => _ProjectBundleCardState();
}

class _ProjectBundleCardState extends ConsumerState<ProjectBundleCard> {
  bool _isExporting = false;

  Future<void> _exportBundle() async {
    setState(() => _isExporting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final safeName = widget.project.name.replaceAll(RegExp(r'[^\w\s-]'), '').trim();
      final defaultFileName = '${safeName.isNotEmpty ? safeName : 'project'}.capstudio';
      final map = ProjectBundleService.instance.serialize(widget.project);
      final jsonStr = const JsonEncoder.withIndent('  ').convert(map);

      if (kIsWeb) {
        downloadFileWeb(jsonStr, defaultFileName);
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Downloaded project bundle (.capstudio)!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      } else {
        final bytes = Uint8List.fromList(utf8.encode(jsonStr));
        final savePath = await FilePicker.saveFile(
          dialogTitle: 'Export Project Backup (.capstudio)',
          fileName: defaultFileName,
          type: FileType.custom,
          allowedExtensions: ['capstudio', 'json'],
          bytes: bytes,
        );

        if (savePath != null) {
          await ProjectBundleService.instance.exportProjectToFile(widget.project, savePath);
          messenger.showSnackBar(
            SnackBar(
              content: Text('Project bundle exported to: $savePath'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to export project bundle: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _importBundle() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['capstudio', 'json'],
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      Project imported;

      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        final content = utf8.decode(bytes);
        final decoded = json.decode(content) as Map<String, dynamic>;
        imported = ProjectBundleService.instance.deserialize(decoded, generateNewId: true);
      } else {
        final path = file.path;
        if (path == null) throw Exception('File path missing');
        imported = await ProjectBundleService.instance.importProjectFromFile(path, generateNewId: true);
      }

      // Load imported project into current editor session and route
      ref.read(editorProvider.notifier).setProject(imported);
      if (mounted) {
        context.go('/editor/${imported.projectId}');
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('Loaded imported project "${imported.name}"!'),
          backgroundColor: AppTheme.accentGreen,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to import project bundle: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBg,
        borderRadius: 12,
        borderOpacity: 0.08,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: AppTheme.glassDecoration(
                  color: AppTheme.accentCyan.withValues(alpha: 0.12),
                  borderRadius: 8,
                  borderOpacity: 0.2,
                ),
                child: Icon(Icons.archive_rounded, color: AppTheme.accentCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Project Backup & Sharing (.capstudio)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryText,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Package all caption timings, styles, speaker tags, and edits into a single portable bundle.',
                      style: TextStyle(fontSize: 11, color: AppTheme.secondaryText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: AppTheme.dividerColor),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentCyan,
                    foregroundColor: AppTheme.onAccentText,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _isExporting
                      ? SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppTheme.onAccentText)),
                        )
                      : const Icon(Icons.file_upload_outlined, size: 16),
                  label: Text(
                    _isExporting ? 'EXPORTING...' : 'EXPORT .CAPSTUDIO FILE',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isExporting ? null : _exportBundle,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryText,
                  side: BorderSide(color: AppTheme.borderGlass),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                icon: Icon(Icons.file_download_outlined, size: 16, color: AppTheme.secondaryText),
                label: const Text(
                  'IMPORT',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                onPressed: _importBundle,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
