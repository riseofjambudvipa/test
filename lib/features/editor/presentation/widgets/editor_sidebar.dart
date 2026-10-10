import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_provider.dart';
import '../../../../core/logger/logger_service.dart';
import '../controllers/editor_controller.dart';
import '../controllers/editor_state.dart';
import 'panels/style_panel.dart';
import 'panels/word_panel.dart';
import 'panels/transcription_panel.dart';
import 'panels/debug_panel.dart';
import 'panels/export_panel.dart';
import 'panels/viral_clipping_panel.dart';
import 'shortcuts_panel.dart';
import '../../../../l10n/app_localizations.dart';

class EditorSidebar extends ConsumerWidget {
  final Future<void> Function({
    required bool useMock,
    String? language,
    String? whisperCliPath,
    String? whisperModelPath,
    String? ffmpegCliPath,
    bool? useVad,
    double? vadThreshold,
    bool? translate,
  })? onRetranscribe;

  const EditorSidebar({
    super.key,
    this.onRetranscribe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider);
    final l10n = AppLocalizations.of(context);
    final currentTab = ref.watch(editorProvider.select((s) => s.activeTab));
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final isDesktop = isLandscape || MediaQuery.of(context).size.width >= 600;

    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      final isNarrow = maxW < 340;
      final double tabHPad = maxW >= 520
          ? 18.0
          : (maxW >= 360
              ? ((maxW - 360.0) / 160.0 * 10.0 + 8.0).clamp(8.0, 18.0)
              : 7.0);
      final double tabFontSize = maxW >= 480 ? 13.0 : (maxW >= 360 ? 11.5 : 10.5);
      final double tabIconSize = maxW >= 480 ? 18.0 : (maxW >= 360 ? 16.0 : 14.0);
      return RepaintBoundary(
          child: Container(
        decoration: AppTheme.glassDecoration(
          borderRadius: 0,
          borderOpacity: 0.08,
          color: AppTheme.cardBg.withValues(alpha: 0.55),
        ),
        child: Column(
          children: [
            // Render Tab Switcher header ONLY on Desktop
            if (isDesktop)
              Container(
                height: 52,
                width: double.infinity,
                decoration: AppTheme.glassDecoration(
                  color: Colors.transparent,
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
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _TabButton(
                        tabId: EditorTab.caption,
                        icon: Icons.closed_caption_outlined,
                        label: isNarrow
                            ? 'CC'
                            : (l10n?.editorTabCaptions ?? 'Captions'),
                        currentTab: currentTab,
                        horizontalPadding: tabHPad,
                        fontSize: tabFontSize,
                        iconSize: tabIconSize,
                      ),
                      _TabButton(
                        tabId: EditorTab.style,
                        icon: Icons.palette_outlined,
                        label: isNarrow
                            ? 'Style'
                            : (l10n?.editorTabStyles ?? 'Styles'),
                        currentTab: currentTab,
                        horizontalPadding: tabHPad,
                        fontSize: tabFontSize,
                        iconSize: tabIconSize,
                      ),
                      _TabButton(
                        tabId: EditorTab.clipping,
                        icon: Icons.auto_awesome,
                        label: isNarrow
                            ? (l10n?.editorTabClips ?? 'Clips')
                            : (l10n?.editorTabShorts ?? 'Shorts'),
                        currentTab: currentTab,
                        horizontalPadding: tabHPad,
                        fontSize: tabFontSize,
                        iconSize: tabIconSize,
                      ),
                      _TabButton(
                        tabId: EditorTab.transcription,
                        icon: Icons.translate_outlined,
                        label: 'STT',
                        currentTab: currentTab,
                        horizontalPadding: tabHPad,
                        fontSize: tabFontSize,
                        iconSize: tabIconSize,
                      ),
                      if (kDebugMode)
                        _TabButton(
                          tabId: EditorTab.debug,
                          icon: Icons.terminal_outlined,
                          label: l10n?.editorTabDebug ?? 'Logs',
                          currentTab: currentTab,
                          horizontalPadding: tabHPad,
                          fontSize: tabFontSize,
                          iconSize: tabIconSize,
                        ),
                    ],
                  ),
                ),
              ),

            // Render Selected Tab Panel Content with Premium AnimatedSwitcher Slide+Fade
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                switchInCurve: Curves.easeInOut,
                switchOutCurve: Curves.easeInOut,
                layoutBuilder:
                    (Widget? currentChild, List<Widget> previousChildren) {
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: <Widget>[
                      ...previousChildren,
                      if (currentChild != null) currentChild,
                    ],
                  );
                },
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.04, 0.0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey<EditorTab>(currentTab),
                  child: switch (currentTab) {
                    EditorTab.style => const StylePanel(),
                    EditorTab.caption => const WordPanel(),
                    EditorTab.clipping => const ViralClippingPanel(),
                    EditorTab.transcription =>
                      TranscriptionPanel(onRetranscribe: onRetranscribe),
                    EditorTab.debug => const DebugPanel(),
                    EditorTab.export => const ExportPanel(),
                    EditorTab.shortcuts => const ShortcutsPanel(),
                    EditorTab.trim => const SizedBox.shrink(),
                  },
                ),
              ),
            ),
          ],
        ),
      ));
    });
  }
}

class _TabButton extends ConsumerStatefulWidget {
  final EditorTab tabId;
  final IconData icon;
  final String label;
  final EditorTab currentTab;
  final double horizontalPadding;
  final double fontSize;
  final double iconSize;

  const _TabButton({
    required this.tabId,
    required this.icon,
    required this.label,
    required this.currentTab,
    this.horizontalPadding = 18.0,
    this.fontSize = 13.0,
    this.iconSize = 18.0,
  });

  @override
  ConsumerState<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends ConsumerState<_TabButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isActive = widget.currentTab == widget.tabId;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: InkWell(
          onTap: () {
            ref.read(editorProvider.notifier).setActiveTab(widget.tabId);
            LoggerService.instance.log(LogLevel.action, 'EditorSidebar',
                'Tab switched to: ${widget.tabId.name}');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: widget.horizontalPadding,
              vertical: 12,
            ),
            decoration: AppTheme.glassDecoration(
              color: isActive
                  ? AppTheme.accentOrange.withValues(alpha: 0.06)
                  : (_isHovered
                      ? AppTheme.cardBgElevated
                      : Colors.transparent),
              borderRadius: 0,
              borderOpacity: isActive ? 0.35 : 0.0,
              glowColor: isActive ? AppTheme.accentOrange : null,
              glowOpacity: isActive ? 0.06 : 0.0,
            ).copyWith(
              border: Border(
                bottom: BorderSide(
                  color: isActive ? AppTheme.accentOrange : Colors.transparent,
                  width: 3.0,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  size: widget.iconSize,
                  color:
                      isActive ? AppTheme.accentOrange : AppTheme.secondaryText,
                ),
                if (widget.label.isNotEmpty) ...[
                  const SizedBox(width: 5),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w900,
                      color: isActive
                          ? AppTheme.primaryText
                          : AppTheme.secondaryText,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
