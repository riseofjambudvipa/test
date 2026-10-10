import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_provider.dart';
import '../../../../core/database/schemas/project.dart';
import '../../../../core/logger/logger_service.dart';
import '../../../../core/utils/premium_blur_dialog.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/editor_controller.dart';
import 'panels/word_panel/review_comments_dialog.dart';

class EditorHeaderBar extends ConsumerWidget {
  final Project project;
  final bool isCompactWidth;
  final bool desktopSidebarOpen;
  final VoidCallback onToggleSidebar;
  final VoidCallback onSave;
  final VoidCallback onExport;
  final VoidCallback onBack;

  const EditorHeaderBar({
    super.key,
    required this.project,
    required this.isCompactWidth,
    required this.desktopSidebarOpen,
    required this.onToggleSidebar,
    required this.onSave,
    required this.onExport,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final hasUnsavedChanges = ref.watch(editorProvider.select((s) => s.hasUnsavedChanges));
    final canUndo = ref.watch(editorProvider.select((s) => s.canUndo));
    final canRedo = ref.watch(editorProvider.select((s) => s.canRedo));
    final isPhonePlatform = !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final effectiveHeight = isLandscape && isPhonePlatform
        ? 36.0
        : (isPhonePlatform ? 44.0 : (isCompactWidth ? 48.0 : 56.0));
    final effectivePadding = isLandscape && isPhonePlatform
        ? 4.0
        : (isPhonePlatform ? 6.0 : (isCompactWidth ? 8.0 : 16.0));

    return Container(
      height: effectiveHeight,
      padding: EdgeInsets.symmetric(horizontal: effectivePadding),
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.65),
        borderRadius: 0,
        borderOpacity: 0.0,
      ).copyWith(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.borderGlass,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: l10n?.returnToDashboard ?? 'Back to Dashboard',
            onPressed: () async {
              if (hasUnsavedChanges) {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => PremiumBlurDialog(
                    maxWidth: 400,
                    glowColor: AppTheme.accentOrange,
                    glowOpacity: 0.1,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unsaved Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryText,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'You have unsaved changes. Are you sure you want to return to the dashboard? Unsaved changes will be lost.',
                          style: TextStyle(color: AppTheme.secondaryText, fontSize: 13),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(l10n?.btnCancel ?? 'CANCEL', style: TextStyle(color: AppTheme.secondaryText, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentRed,
                                foregroundColor: AppTheme.onAccentText,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => Navigator.pop(context, true),
                               child: Text(l10n?.btnConfirm ?? 'LEAVE', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
                if (confirm != true) return;
              }
              onBack();
            },
          ),
          if (!isPhonePlatform && !isCompactWidth) const SizedBox(width: 8),
          Expanded(
            child: Text(
              project.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: isPhonePlatform ? 12 : (isCompactWidth ? 13 : 16),
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
          ),
          if (hasUnsavedChanges)
            Container(
              width: 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                shape: BoxShape.circle,
              ),
            ),
          
          // Actions
          Flexible(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCompactWidth || isLandscape) ...[
                    IconButton(
                      icon: Icon(
                        desktopSidebarOpen ? Icons.view_sidebar : Icons.view_sidebar_outlined,
                        size: 20,
                        color: desktopSidebarOpen ? AppTheme.accentOrange : AppTheme.secondaryText,
                      ),
                      tooltip: desktopSidebarOpen ? 'Hide Sidebar' : 'Show Sidebar',
                      onPressed: onToggleSidebar,
                    ),
                    const SizedBox(width: 12),
                  ],
                  IconButton(
                    icon: const Icon(Icons.undo, size: 20),
                    tooltip: isPhonePlatform ? (l10n?.btnUndo ?? "Undo") : '${l10n?.btnUndo ?? "Undo"} (Ctrl+Z)',
                    color: canUndo ? AppTheme.primaryText : AppTheme.mutedText.withValues(alpha: 0.35),
                    onPressed: canUndo ? () => ref.read(editorProvider.notifier).undo() : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo, size: 20),
                    tooltip: isPhonePlatform ? (l10n?.btnRedo ?? "Redo") : '${l10n?.btnRedo ?? "Redo"} (Ctrl+Y)',
                    color: canRedo ? AppTheme.primaryText : AppTheme.mutedText.withValues(alpha: 0.35),
                    onPressed: canRedo ? () => ref.read(editorProvider.notifier).redo() : null,
                  ),
                  SizedBox(width: isPhonePlatform ? 4 : 8),
                  if (!isPhonePlatform && !isCompactWidth) ...[
                    IconButton(
                      icon: Icon(
                        AppTheme.isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                        size: 20,
                        color: AppTheme.accentOrange,
                      ),
                      tooltip: AppTheme.isDark ? (l10n?.themeLight ?? 'Light Mode') : (l10n?.themeDark ?? 'Dark Mode'),
                      onPressed: () {
                        ref.read(themeProvider.notifier).toggleBrightness();
                      },
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<ThemePalette>(
                      icon: Icon(Icons.palette_outlined, size: 20, color: AppTheme.accentOrange),
                      tooltip: l10n?.tooltipTheme ?? 'Change Theme Palette',
                      color: AppTheme.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: AppTheme.borderGlass),
                      ),
                      onSelected: (val) {
                        ref.read(themeProvider.notifier).setPalette(val);
                        LoggerService.instance.log(LogLevel.action, 'Editor', 'Global dynamic theme palette changed to: ${val.name}');
                      },
                      itemBuilder: (context) => ThemePalette.values
                          .map(
                            (p) {
                              final pData = AppThemeData.getThemeFor(palette: p, isDark: AppTheme.isDark);
                              final isSelected = AppTheme.activePalette == p;
                              return PopupMenuItem(
                                value: p,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [pData.accentPrimary, pData.accentSecondary],
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        p.displayName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                          color: isSelected ? AppTheme.accentOrange : AppTheme.primaryText,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check, size: 14, color: AppTheme.accentOrange),
                                  ],
                                ),
                              );
                            },
                          )
                          .toList(),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 20),
                    tooltip: l10n?.tooltipSettings ?? 'Settings',
                    color: AppTheme.secondaryText,
                    onPressed: () {
                      context.push('/settings');
                    },
                  ),
                  const SizedBox(width: 4),
                  // Team Review & Revisions
                  Builder(
                    builder: (btnContext) {
                      final comments = ref.watch(editorProvider.select((s) => s.comments));
                      final pendingCount = comments.where((c) => !c.isResolved).length;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.rate_review_outlined, size: 20),
                            tooltip: 'Team Review Notes (${comments.length})',
                            color: pendingCount > 0 ? AppTheme.accentCyan : AppTheme.secondaryText,
                            onPressed: () => ReviewCommentsDialog.show(btnContext),
                          ),
                          if (pendingCount > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentCyan,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                child: Text(
                                  pendingCount > 9 ? '9+' : '$pendingCount',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.onAccentText,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  SizedBox(width: isPhonePlatform ? 4 : 8),
                  ElevatedButton.icon(
                    icon: Icon(
                      hasUnsavedChanges ? Icons.save_rounded : Icons.check, 
                      size: isPhonePlatform || isCompactWidth ? 12 : 14
                    ),
                    label: Text(isPhonePlatform || isCompactWidth ? '' : (l10n?.btnSave ?? 'SAVE'), style: const TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasUnsavedChanges 
                          ? AppTheme.accentOrange 
                          : AppTheme.cardBgElevated,
                      foregroundColor: hasUnsavedChanges 
                          ? AppTheme.onAccentText 
                          : AppTheme.secondaryText,
                      disabledBackgroundColor: AppTheme.cardBgElevated,
                      disabledForegroundColor: AppTheme.mutedText,
                      padding: EdgeInsets.symmetric(horizontal: isPhonePlatform || isCompactWidth ? 8 : 16, vertical: 8),
                      minimumSize: isPhonePlatform || isCompactWidth ? const Size(32, 32) : null,
                    ),
                    onPressed: hasUnsavedChanges ? onSave : null,
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    icon: Icon(Icons.rocket_launch, size: isPhonePlatform || isCompactWidth ? 12 : 14),
                    label: Text(isPhonePlatform || isCompactWidth ? '' : (l10n?.btnExportCaps ?? 'EXPORT'), style: const TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: AppTheme.onAccentText,
                      padding: EdgeInsets.symmetric(horizontal: isPhonePlatform || isCompactWidth ? 8 : 16, vertical: 8),
                      minimumSize: isPhonePlatform || isCompactWidth ? const Size(32, 32) : null,
                    ),
                    onPressed: onExport,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
