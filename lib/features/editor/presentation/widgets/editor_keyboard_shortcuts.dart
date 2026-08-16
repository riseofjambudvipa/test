import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:collection/collection.dart';
import '../controllers/editor_controller.dart';
import '../controllers/editor_state.dart';

class EditorKeyboardShortcuts extends ConsumerWidget {
  final FocusNode focusNode;
  final Widget child;
  final Player? player;
  final VoidCallback togglePlayback;
  final Future<void> Function() handleSave;
  final void Function(double amount) seekRelative;
  final bool isFullscreen;
  final ValueChanged<bool> onFullscreenChanged;
  final bool mobileSidebarOpen;
  final ValueChanged<bool> onMobileSidebarOpenChanged;
  final bool desktopSidebarOpen;
  final ValueChanged<bool> onDesktopSidebarOpenChanged;

  const EditorKeyboardShortcuts({
    super.key,
    required this.focusNode,
    required this.child,
    required this.player,
    required this.togglePlayback,
    required this.handleSave,
    required this.seekRelative,
    required this.isFullscreen,
    required this.onFullscreenChanged,
    required this.mobileSidebarOpen,
    required this.onMobileSidebarOpenChanged,
    required this.desktopSidebarOpen,
    required this.onDesktopSidebarOpenChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Focus(
      focusNode: focusNode,
      autofocus: true,
      onKeyEvent: (node, event) => _handleKeyEvent(context, ref, event),
      child: child,
    );
  }

  KeyEventResult _handleKeyEvent(BuildContext context, WidgetRef ref, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final primaryFocus = FocusManager.instance.primaryFocus;
    final isInputFocused = primaryFocus != null && 
        (primaryFocus.context?.widget is EditableText || 
         primaryFocus.context?.findAncestorWidgetOfExactType<EditableText>() != null);
    if (isInputFocused) return KeyEventResult.ignored;

    final isCmdOrCtrl = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;

    // Space — Play/Pause
    if (event.logicalKey == LogicalKeyboardKey.space) {
      togglePlayback();
      return KeyEventResult.handled;
    }

    // Ctrl+S — Save
    if (isCmdOrCtrl && event.logicalKey == LogicalKeyboardKey.keyS) {
      handleSave();
      return KeyEventResult.handled;
    }

    // Ctrl+Z — Undo
    if (isCmdOrCtrl && !isShift && event.logicalKey == LogicalKeyboardKey.keyZ) {
      ref.read(editorProvider.notifier).undo();
      return KeyEventResult.handled;
    }

    // Ctrl+Y or Ctrl+Shift+Z — Redo
    if ((isCmdOrCtrl && event.logicalKey == LogicalKeyboardKey.keyY) ||
        (isCmdOrCtrl && isShift && event.logicalKey == LogicalKeyboardKey.keyZ)) {
      ref.read(editorProvider.notifier).redo();
      return KeyEventResult.handled;
    }

    // Ctrl+F — Find & Replace (switch to caption tab and trigger find dialog)
    if (isCmdOrCtrl && event.logicalKey == LogicalKeyboardKey.keyF) {
      ref.read(editorProvider.notifier).setActiveTab(EditorTab.caption);
      Future.microtask(() {
        ref.read(editorProvider.notifier).triggerFindReplace();
      });
      return KeyEventResult.handled;
    }

    // Left Arrow — Seek -0.1s (fine frame step)
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      seekRelative(-0.1);
      return KeyEventResult.handled;
    }

    // Right Arrow — Seek +0.1s (fine frame step)
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      seekRelative(0.1);
      return KeyEventResult.handled;
    }

    // J — Seek -5s (video editor convention)
    if (event.logicalKey == LogicalKeyboardKey.keyJ) {
      seekRelative(-5.0);
      return KeyEventResult.handled;
    }

    // L — Seek +5s (video editor convention)
    if (event.logicalKey == LogicalKeyboardKey.keyL) {
      seekRelative(5.0);
      return KeyEventResult.handled;
    }

    // K — Pause (video editor convention; fire-and-forget since handler is sync)
    if (event.logicalKey == LogicalKeyboardKey.keyK) {
      if (ref.read(editorProvider).isPlaying) {
        unawaited(player?.pause());
      }
      return KeyEventResult.handled;
    }

    // F — Toggle Fullscreen (only when Ctrl is NOT held, to not conflict with Ctrl+F)
    if (!isCmdOrCtrl && event.logicalKey == LogicalKeyboardKey.keyF) {
      onFullscreenChanged(!isFullscreen);
      return KeyEventResult.handled;
    }

    // Delete — Delete word under playhead
    if (event.logicalKey == LogicalKeyboardKey.delete) {
      final editorState = ref.read(editorProvider);
      final project = editorState.project;
      if (project != null) {
        final activeWord = project.words.firstWhereOrNull((w) =>
            editorState.currentTime >= (w.start ?? 0.0) &&
            editorState.currentTime <= (w.end ?? 0.0));
        if (activeWord != null && activeWord.wordId != null) {
          ref.read(editorProvider.notifier).deleteWords([activeWord.wordId!]);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted word: "${activeWord.text}"'),
              duration: const Duration(seconds: 2),
            ),
          );
          return KeyEventResult.handled;
        }
      }
    }

    // '?' = Shift + '/'
    if (event.logicalKey == LogicalKeyboardKey.slash && isShift) {
      final activeTab = ref.read(editorProvider).activeTab;
      if (activeTab == EditorTab.shortcuts) {
        ref.read(editorProvider.notifier).closeShortcuts();
      } else {
        ref.read(editorProvider.notifier).setActiveTab(EditorTab.shortcuts);
      }
      return KeyEventResult.handled;
    }

    // Escape — Toggle sidebar or close shortcuts panel
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      final activeTab = ref.read(editorProvider).activeTab;
      if (activeTab == EditorTab.shortcuts) {
        ref.read(editorProvider.notifier).closeShortcuts();
        return KeyEventResult.handled;
      }
      final isCompactWidth = MediaQuery.of(context).size.width < 600;
      if (isCompactWidth) {
        onMobileSidebarOpenChanged(!mobileSidebarOpen);
      } else {
        onDesktopSidebarOpenChanged(!desktopSidebarOpen);
      }
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }
}
