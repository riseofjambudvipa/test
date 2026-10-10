import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/database/schemas/project.dart';
import '../../../../../core/project/project_bundle_service.dart';
import '../../../../../core/utils/web_download_helper.dart';
import '../../../../../core/utils/premium_blur_dialog.dart';
import '../../controllers/dashboard_controller.dart';
import '../../../../../l10n/app_localizations.dart';

class HoverableProjectCard extends ConsumerStatefulWidget {
  final Project project;
  final VoidCallback onEdit;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const HoverableProjectCard({
    super.key,
    required this.project,
    required this.onEdit,
    required this.onRename,
    required this.onDelete,
  });

  @override
  ConsumerState<HoverableProjectCard> createState() => _HoverableProjectCardState();
}

class _HoverableProjectCardState extends ConsumerState<HoverableProjectCard> {
  bool _isHovered = false;
  bool _thumbnailExists = false;

  @override
  void initState() {
    super.initState();
    _checkThumbnail();
  }

  @override
  void didUpdateWidget(covariant HoverableProjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.project.thumbnailPath != widget.project.thumbnailPath) {
      _checkThumbnail();
    }
  }

  void _checkThumbnail() {
    final path = widget.project.thumbnailPath;
    if (path == null || path.isEmpty) {
      if (_thumbnailExists) {
        _thumbnailExists = false;
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() {});
          });
        }
      }
      return;
    }
    if (kIsWeb) {
      // FIX (audit): this used to force _thumbnailExists = false, making the
      // Image.network branch below permanently dead code — web users never
      // saw thumbnails. dart:io File checks don't work on web, so trust the
      // stored path and let the image's errorBuilder handle failures.
      if (widget.project.thumbnailPath != null && mounted) {
        setState(() => _thumbnailExists = true);
      }
      return;
    }
    File(path).exists().then((exists) {
      if (mounted) {
        setState(() => _thumbnailExists = exists);
      }
    });
  }

  Future<void> _exportProjectBundle(BuildContext context) async {
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
            content: const Text('Exported project bundle (.capstudio)!'),
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
          await File(savePath).writeAsString(jsonStr);
          messenger.showSnackBar(
            SnackBar(
              content: Text('Exported project backup: $savePath'),
              backgroundColor: AppTheme.accentGreen,
            ),
          );
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to export project: $e'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        '${widget.project.createdAt.year}-${widget.project.createdAt.month.toString().padLeft(2, '0')}-${widget.project.createdAt.day.toString().padLeft(2, '0')}';
    final dur = widget.project.duration.toStringAsFixed(1);
    final isSmallHeight = MediaQuery.of(context).size.height < 550;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.025 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: GlassContainer(
          borderRadius: 16,
          borderOpacity: _isHovered ? 0.22 : 0.08,
          glowColor: AppTheme.accentOrange,
          glowOpacity: _isHovered ? 0.08 : 0.0,
          color: _isHovered
              ? AppTheme.cardBg.withValues(alpha: 0.6)
              : AppTheme.cardBg.withValues(alpha: 0.35),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 90,
                      height: double.infinity,
                      decoration: AppTheme.glassDecoration(
                        color: Colors.black26,
                        borderRadius: 0,
                        borderOpacity: 0.0,
                      ).copyWith(
                        border: Border(
                          right: BorderSide(
                            color: AppTheme.borderGlass,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _thumbnailExists && widget.project.thumbnailPath != null
                              ? (kIsWeb
                                  ? Image.network(
                                      widget.project.thumbnailPath!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Icon(
                                          Icons.movie_creation_outlined,
                                          size: 24,
                                          color: AppTheme.mutedText,
                                        ),
                                      ),
                                    )
                                  : Image.file(
                                      File(widget.project.thumbnailPath!),
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Icon(
                                          Icons.movie_creation_outlined,
                                          size: 24,
                                          color: AppTheme.mutedText,
                                        ),
                                      ),
                                    ))
                              : Center(
                                  child: Icon(
                                    Icons.movie_creation_outlined,
                                    size: 24,
                                    color: AppTheme.mutedText,
                                  ),
                                ),
                          AnimatedOpacity(
                            opacity: _isHovered ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 180),
                            child: Container(
                              color: Colors.black45,
                              child: Center(
                                  child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  size: 28,
                                  color: AppTheme.accentOrange,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallHeight ? 8.0 : 12.0,
                          vertical: isSmallHeight ? 6.0 : 8.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.project.name,
                                    maxLines: isSmallHeight ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryText,
                                      fontSize: isSmallHeight ? 13 : 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: AppTheme.glassDecoration(
                                    color: AppTheme.accentCyan.withValues(alpha: 0.1),
                                    borderRadius: 4,
                                    borderOpacity: 0.2,
                                  ),
                                  child: Text(
                                    '${dur}s',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.accentCyan,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!isSmallHeight) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today_outlined, size: 10, color: AppTheme.secondaryText),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${AppLocalizations.of(context)?.createdLabel ?? 'Created:'} $formattedDate',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 10,
                                        color: AppTheme.secondaryText,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final showLabels = constraints.maxWidth >= 450;
                  final l10n = AppLocalizations.of(context);
                  return Container(
                    height: 40,
                    decoration: AppTheme.glassDecoration(
                      color: AppTheme.cardBgElevated,
                      borderRadius: 0,
                      borderOpacity: 0.0,
                    ).copyWith(
                      border: Border(
                        top: BorderSide(
                          color: AppTheme.borderGlass,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        showLabels
                            ? TextButton.icon(
                                onPressed: widget.onEdit,
                                icon: Icon(Icons.edit_outlined, size: 12, color: AppTheme.accentOrange),
                                label: Text(
                                  l10n?.btnEdit ?? 'EDIT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentOrange,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              )
                            : IconButton(
                                icon: Icon(Icons.edit_outlined, size: 16, color: AppTheme.accentOrange),
                                onPressed: widget.onEdit,
                                tooltip: l10n?.tooltipEdit ?? 'Edit',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                        VerticalDivider(width: 1, color: AppTheme.dividerColor, indent: 6, endIndent: 6),
                        showLabels
                            ? TextButton.icon(
                                onPressed: widget.onRename,
                                icon: Icon(Icons.drive_file_rename_outline, size: 12, color: AppTheme.accentPink),
                                label: Text(
                                  l10n?.btnRename ?? 'RENAME',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentPink,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              )
                            : IconButton(
                                icon: Icon(Icons.drive_file_rename_outline, size: 16, color: AppTheme.accentPink),
                                onPressed: widget.onRename,
                                tooltip: l10n?.tooltipRename ?? 'Rename',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                        VerticalDivider(width: 1, color: AppTheme.dividerColor, indent: 6, endIndent: 6),
                        showLabels
                            ? TextButton.icon(
                                onPressed: () {
                                  ref.read(dashboardProvider.notifier).duplicateProject(widget.project.projectId);
                                },
                                icon: Icon(Icons.copy_outlined, size: 12, color: AppTheme.accentCyan),
                                label: Text(
                                  l10n?.btnDuplicate ?? 'DUPLICATE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentCyan,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              )
                            : IconButton(
                                icon: Icon(Icons.copy_outlined, size: 16, color: AppTheme.accentCyan),
                                onPressed: () {
                                  ref.read(dashboardProvider.notifier).duplicateProject(widget.project.projectId);
                                },
                                tooltip: l10n?.tooltipDuplicate ?? 'Duplicate',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                        VerticalDivider(width: 1, color: AppTheme.dividerColor, indent: 6, endIndent: 6),
                        showLabels
                            ? TextButton.icon(
                                onPressed: () => _exportProjectBundle(context),
                                icon: Icon(Icons.archive_outlined, size: 12, color: AppTheme.accentOrange),
                                label: Text(
                                  'EXPORT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentOrange,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              )
                            : IconButton(
                                icon: Icon(Icons.archive_outlined, size: 16, color: AppTheme.accentOrange),
                                onPressed: () => _exportProjectBundle(context),
                                tooltip: 'Export Project Backup (.capstudio)',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                        VerticalDivider(width: 1, color: AppTheme.dividerColor, indent: 6, endIndent: 6),
                        showLabels
                            ? TextButton.icon(
                                onPressed: widget.onDelete,
                                icon: Icon(Icons.delete_forever_outlined, size: 12, color: AppTheme.accentRed),
                                label: Text(
                                  l10n?.btnDelete ?? 'DELETE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.accentRed,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              )
                            : IconButton(
                                icon: Icon(Icons.delete_forever_outlined, size: 16, color: AppTheme.accentRed),
                                onPressed: widget.onDelete,
                                tooltip: l10n?.tooltipDelete ?? 'Delete',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RenameProjectDialog extends StatefulWidget {
  final Project project;
  final WidgetRef ref;

  const RenameProjectDialog({
    super.key,
    required this.project,
    required this.ref,
  });

  @override
  State<RenameProjectDialog> createState() => _RenameProjectDialogState();
}

class _RenameProjectDialogState extends State<RenameProjectDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.project.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PremiumBlurDialog(
      maxWidth: 400,
      glowColor: AppTheme.accentOrange,
      glowOpacity: 0.1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.renameProjectTitle ?? 'Rename Project',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: AppTheme.primaryText,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(color: AppTheme.primaryText),
            decoration: InputDecoration(
              hintText: l10n?.projectNameLabel ?? 'Project Name',
              hintStyle: TextStyle(color: AppTheme.mutedText),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.borderGlass),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.accentOrange),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n?.btnCancel ?? 'CANCEL', style: TextStyle(color: AppTheme.secondaryText)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: AppTheme.onAccentText,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final newName = _controller.text.trim();
                  Navigator.pop(context);
                  if (newName.isNotEmpty) {
                    widget.ref.read(dashboardProvider.notifier).renameProject(widget.project.projectId, newName);
                  }
                },
                child: Text(l10n?.btnRename ?? 'RENAME'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
