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
import 'shortcuts_panel.dart';

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
    final currentTab = ref.watch(editorProvider.select((s) => s.activeTab));
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isDesktop = isLandscape || MediaQuery.of(context).size.width >= 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 300;
        return GlassContainer(
          borderRadius: 0,
          borderOpacity: 0.08,
          color: AppTheme.cardBg.withValues(alpha: 0.55),
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
                        color: Colors.white.withValues(alpha: 0.04),
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
                          label: isNarrow ? 'CC' : 'Captions',
                          currentTab: currentTab,
                          isNarrow: isNarrow,
                        ),
                        _TabButton(
                          tabId: EditorTab.style,
                          icon: Icons.palette_outlined,
                          label: isNarrow ? 'Style' : 'Styles',
                          currentTab: currentTab,
                          isNarrow: isNarrow,
                        ),
                        _TabButton(
                          tabId: EditorTab.transcription,
                          icon: Icons.translate_outlined,
                          label: isNarrow ? 'STT' : 'STT',
                          currentTab: currentTab,
                          isNarrow: isNarrow,
                        ),
                        _TabButton(
                          tabId: EditorTab.debug,
                          icon: Icons.terminal_outlined,
                          label: isNarrow ? 'Logs' : 'Logs',
                          currentTab: currentTab,
                          isNarrow: isNarrow,
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
                  layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
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
                      EditorTab.style         => const StylePanel(),
                      EditorTab.caption       => const WordPanel(),
                      EditorTab.transcription => TranscriptionPanel(onRetranscribe: onRetranscribe),
                      EditorTab.debug         => const DebugPanel(),
                      EditorTab.export        => const ExportPanel(),
                      EditorTab.shortcuts     => const ShortcutsPanel(),
                      EditorTab.trim          => const SizedBox.shrink(),
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }
}

class _TabButton extends ConsumerStatefulWidget {
  final EditorTab tabId;
  final IconData icon;
  final String label;
  final EditorTab currentTab;
  final bool isNarrow;

  const _TabButton({
    required this.tabId,
    required this.icon,
    required this.label,
    required this.currentTab,
    this.isNarrow = false,
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
            LoggerService.instance.log(LogLevel.action, 'EditorSidebar', 'Tab switched to: ${widget.tabId.name}');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isNarrow ? 12 : 20,
              vertical: 12,
            ),
            decoration: AppTheme.glassDecoration(
              color: isActive
                  ? AppTheme.accentOrange.withValues(alpha: 0.06)
                  : (_isHovered ? Colors.white.withValues(alpha: 0.025) : Colors.transparent),
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
                  size: 20,
                  color: isActive ? AppTheme.accentOrange : AppTheme.secondaryText,
                ),
                if (widget.label.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: isActive ? AppTheme.primaryText : AppTheme.secondaryText,
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
