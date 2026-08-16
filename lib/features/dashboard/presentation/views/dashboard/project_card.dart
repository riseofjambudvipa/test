import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme.dart';
import '../../../../../core/database/schemas/project.dart';
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
      if (mounted) {
        setState(() => _thumbnailExists = false);
      }
      return;
    }
    File(path).exists().then((exists) {
      if (mounted) {
        setState(() => _thumbnailExists = exists);
      }
    });
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
                            color: Colors.white.withValues(alpha: 0.04),
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
                                          color: Colors.white.withValues(alpha: 0.15),
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
                                          color: Colors.white.withValues(alpha: 0.15),
                                        ),
                                      ),
                                    ))
                              : Center(
                                  child: Icon(
                                    Icons.movie_creation_outlined,
                                    size: 24,
                                    color: Colors.white.withValues(alpha: 0.15),
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
                                      color: Colors.white,
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
                                      '${AppLocalizations.of(context)!.createdLabel} $formattedDate',
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
                  return Container(
                    height: 40,
                    decoration: AppTheme.glassDecoration(
                      color: Colors.white.withValues(alpha: 0.015),
                      borderRadius: 0,
                      borderOpacity: 0.0,
                    ).copyWith(
                      border: Border(
                        top: BorderSide(
                          color: Colors.white.withValues(alpha: 0.04),
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
                                  'EDIT',
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
                                tooltip: 'Edit',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                        const VerticalDivider(width: 1, color: Colors.white10, indent: 6, endIndent: 6),
                        showLabels
                            ? TextButton.icon(
                                onPressed: widget.onRename,
                                icon: Icon(Icons.drive_file_rename_outline, size: 12, color: AppTheme.accentPink),
                                label: Text(
                                  'RENAME',
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
                                tooltip: 'Rename',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                        const VerticalDivider(width: 1, color: Colors.white10, indent: 6, endIndent: 6),
                        showLabels
                            ? TextButton.icon(
                                onPressed: () {
                                  ref.read(dashboardProvider.notifier).duplicateProject(widget.project.projectId);
                                },
                                icon: Icon(Icons.copy_outlined, size: 12, color: AppTheme.accentCyan),
                                label: Text(
                                  'DUPLICATE',
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
                                tooltip: 'Duplicate',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                        const VerticalDivider(width: 1, color: Colors.white10, indent: 6, endIndent: 6),
                        showLabels
                            ? TextButton.icon(
                                onPressed: widget.onDelete,
                                icon: const Icon(Icons.delete_forever_outlined, size: 12, color: Colors.redAccent),
                                label: const Text(
                                  'DELETE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.redAccent,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.delete_forever_outlined, size: 16, color: Colors.redAccent),
                                 onPressed: widget.onDelete,
                                 tooltip: 'Delete',
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
    final l10n = AppLocalizations.of(context)!;
    return PremiumBlurDialog(
      maxWidth: 400,
      glowColor: AppTheme.accentOrange,
      glowOpacity: 0.1,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.renameProjectTitle,
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
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: l10n.projectNameLabel,
              hintStyle: const TextStyle(color: Colors.white30),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
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
                child: Text(l10n.btnCancel, style: const TextStyle(color: Colors.white70)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final newName = _controller.text.trim();
                  Navigator.pop(context);
                  if (newName.isNotEmpty) {
                    widget.ref.read(dashboardProvider.notifier).renameProject(widget.project.projectId, newName);
                  }
                },
                child: Text(l10n.btnRename),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
