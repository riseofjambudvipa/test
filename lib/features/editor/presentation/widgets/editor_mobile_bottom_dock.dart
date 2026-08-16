import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../controllers/editor_controller.dart';
import '../controllers/editor_state.dart';

class EditorMobileBottomDock extends ConsumerWidget {
  final bool mobileSidebarOpen;
  final ValueChanged<bool> onMobileSidebarOpenChanged;

  const EditorMobileBottomDock({
    super.key,
    required this.mobileSidebarOpen,
    required this.onMobileSidebarOpenChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(editorProvider.select((s) => s.activeTab));
    return Container(
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.65),
        borderRadius: 0,
        borderOpacity: 0.0,
      ).copyWith(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMobileTab(context, ref, EditorTab.style, Icons.palette_outlined, 'Style', activeTab),
                  _buildMobileTab(context, ref, EditorTab.caption, Icons.closed_caption_outlined, 'Captions', activeTab),
                  _buildMobileTab(context, ref, EditorTab.transcription, Icons.translate_outlined, 'Import', activeTab),
                  _buildMobileTab(context, ref, EditorTab.debug, Icons.terminal_outlined, 'Logs', activeTab),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTab(BuildContext context, WidgetRef ref, EditorTab tabId, IconData icon, String label, EditorTab activeTab) {
    final isActive = activeTab == tabId && mobileSidebarOpen;
    final screenWidth = MediaQuery.of(context).size.width;
    final padVal = screenWidth < 360 ? 8.0 : 10.0;

    return InkWell(
      onTap: () {
        if (activeTab == tabId && mobileSidebarOpen) {
          onMobileSidebarOpenChanged(false);
        } else {
          ref.read(editorProvider.notifier).setActiveTab(tabId);
          onMobileSidebarOpenChanged(true);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padVal, vertical: 8),
        decoration: AppTheme.glassDecoration(
          color: isActive ? AppTheme.accentOrange.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: 12,
          borderOpacity: isActive ? 0.2 : 0.0,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? AppTheme.accentOrange : AppTheme.mutedText,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: isActive ? AppTheme.accentOrange : AppTheme.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
