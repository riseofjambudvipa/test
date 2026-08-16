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
import '../controllers/editor_controller.dart';

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
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 20),
            tooltip: 'Back to Dashboard',
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
                              child: Text('CANCEL', style: TextStyle(color: AppTheme.secondaryText, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('LEAVE', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        size: 18,
                        color: desktopSidebarOpen ? AppTheme.accentOrange : Colors.white54,
                      ),
                      tooltip: desktopSidebarOpen ? 'Hide Sidebar Panel' : 'Show Sidebar Panel',
                      onPressed: onToggleSidebar,
                    ),
                    const SizedBox(width: 12),
                  ],
                  IconButton(
                    icon: const Icon(Icons.undo, size: 18),
                    tooltip: 'Undo (Ctrl+Z)',
                    color: canUndo ? Colors.white : Colors.white24,
                    onPressed: canUndo ? () => ref.read(editorProvider.notifier).undo() : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.redo, size: 18),
                    tooltip: 'Redo (Ctrl+Y)',
                    color: canRedo ? Colors.white : Colors.white24,
                    onPressed: canRedo ? () => ref.read(editorProvider.notifier).redo() : null,
                  ),
                  SizedBox(width: isPhonePlatform ? 4 : 8),
                  if (!isPhonePlatform && !isCompactWidth) ...[
                    PopupMenuButton<ThemeType>(
                      icon: Icon(Icons.palette_outlined, size: 18, color: AppTheme.accentOrange),
                      tooltip: 'Change Theme',
                      color: AppTheme.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      onSelected: (val) {
                        ref.read(themeProvider.notifier).setTheme(val);
                        LoggerService.instance.log(LogLevel.action, 'Editor', 'Global dynamic theme changed to: ${val.name}');
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: ThemeType.obsidianAmber, child: Text('Deep Obsidian', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                        PopupMenuItem(value: ThemeType.neonCyberpunk, child: Text('Neon Cyberpunk', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                        PopupMenuItem(value: ThemeType.obsidianEmerald, child: Text('Obsidian Emerald', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                        PopupMenuItem(value: ThemeType.royalAmethyst, child: Text('Royal Amethyst', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                        PopupMenuItem(value: ThemeType.sunsetSunrise, child: Text('Sunset Sunrise', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(width: 12),
                  ],
                  IconButton(
                    icon: const Icon(Icons.settings_outlined, size: 18),
                    tooltip: 'Settings',
                    onPressed: () {
                      context.push('/settings');
                    },
                  ),
                  SizedBox(width: isPhonePlatform ? 4 : 8),
                  ElevatedButton.icon(
                    icon: Icon(
                      hasUnsavedChanges ? Icons.save_rounded : Icons.check, 
                      size: isPhonePlatform || isCompactWidth ? 12 : 14
                    ),
                    label: Text(isPhonePlatform || isCompactWidth ? '' : 'SAVE', style: const TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasUnsavedChanges 
                          ? AppTheme.accentOrange 
                          : Colors.white.withValues(alpha: 0.06),
                      foregroundColor: hasUnsavedChanges 
                          ? Colors.white 
                          : Colors.white70,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.06),
                      disabledForegroundColor: Colors.white38,
                      padding: EdgeInsets.symmetric(horizontal: isPhonePlatform || isCompactWidth ? 8 : 16, vertical: 8),
                      minimumSize: isPhonePlatform || isCompactWidth ? const Size(32, 32) : null,
                    ),
                    onPressed: hasUnsavedChanges ? onSave : null,
                  ),
                  const SizedBox(width: 4),
                  ElevatedButton.icon(
                    icon: Icon(Icons.rocket_launch, size: isPhonePlatform || isCompactWidth ? 12 : 14),
                    label: Text(isPhonePlatform || isCompactWidth ? '' : 'EXPORT', style: const TextStyle(fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentOrange,
                      foregroundColor: Colors.white,
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
