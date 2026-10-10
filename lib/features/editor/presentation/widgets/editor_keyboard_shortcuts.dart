import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';
import 'package:collection/collection.dart';
import '../../../../l10n/app_localizations.dart';
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
  final VoidCallback? onExport;

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
    this.onExport,
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

    // FIX (audit): Space/Delete etc. used to fire even while a modal dialog
    // was open (only text input was excluded), so pressing Space or Delete in
    // the emoji/SFX/word pickers could toggle playback or delete a word
    // underneath. Ignore keys while focus is inside a dialog.
    final focusCtx = primaryFocus?.context;
    final isInDialog = focusCtx != null &&
        (focusCtx.findAncestorWidgetOfExactType<Dialog>() != null ||
            focusCtx.findAncestorWidgetOfExactType<ModalBarrier>() != null);
    if (isInDialog) return KeyEventResult.ignored;

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

    // Ctrl+E — Export Dialog / Panel
    if (isCmdOrCtrl && event.logicalKey == LogicalKeyboardKey.keyE) {
      if (onExport != null) {
        onExport!();
      } else {
        ref.read(editorProvider.notifier).setActiveTab(EditorTab.export);
      }
      return KeyEventResult.handled;
    }

    // Ctrl+1 to 4 — Panel Tabs
    if (isCmdOrCtrl && event.logicalKey == LogicalKeyboardKey.digit1) {
      ref.read(editorProvider.notifier).setActiveTab(EditorTab.caption);
      return KeyEventResult.handled;
    }
    if (isCmdOrCtrl && event.logicalKey == LogicalKeyboardKey.digit2) {
      ref.read(editorProvider.notifier).setActiveTab(EditorTab.style);
      return KeyEventResult.handled;
    }
    if (isCmdOrCtrl && event.logicalKey == LogicalKeyboardKey.digit3) {
      ref.read(editorProvider.notifier).setActiveTab(EditorTab.clipping);
      return KeyEventResult.handled;
    }
    if (isCmdOrCtrl && event.logicalKey == LogicalKeyboardKey.digit4) {
      ref.read(editorProvider.notifier).setActiveTab(EditorTab.transcription);
      return KeyEventResult.handled;
    }

    // Home — Jump to start
    if (event.logicalKey == LogicalKeyboardKey.home) {
      seekRelative(-999999.0);
      return KeyEventResult.handled;
    }

    // End — Jump to end
    if (event.logicalKey == LogicalKeyboardKey.end) {
      final duration = ref.read(editorProvider).project?.duration ?? 0.0;
      final currentTime = ref.read(editorProvider).currentTime;
      seekRelative(duration - currentTime);
      return KeyEventResult.handled;
    }

    // Shift + Left Arrow — Seek -1s (medium step)
    if (isShift && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      seekRelative(-1.0);
      return KeyEventResult.handled;
    }

    // Shift + Right Arrow — Seek +1s (medium step)
    if (isShift && event.logicalKey == LogicalKeyboardKey.arrowRight) {
      seekRelative(1.0);
      return KeyEventResult.handled;
    }

    // Left Arrow — Seek -0.1s (fine frame step)
    if (!isShift && event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      seekRelative(-0.1);
      return KeyEventResult.handled;
    }

    // Right Arrow — Seek +0.1s (fine frame step)
    if (!isShift && event.logicalKey == LogicalKeyboardKey.arrowRight) {
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
        // FIX (audit): pause the provider state too, otherwise the pause icon
        // desyncs from the actual playback state.
        ref.read(editorProvider.notifier).setIsPlaying(false);
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
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.wordDeletedSuccess(activeWord.text ?? '') ??
                    'Deleted word: "${activeWord.text ?? ''}"',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
          return KeyEventResult.handled;
        }
      }
    }

    // S — Split timeline at playhead (Blade tool — standard NLE convention)
    if (!isCmdOrCtrl && event.logicalKey == LogicalKeyboardKey.keyS) {
      final editorState = ref.read(editorProvider);
      final curr = editorState.currentTime;
      final project = editorState.project;
      if (project != null && curr > project.trimStart && curr < project.trimEnd) {
        ref.read(editorProvider.notifier).splitSegmentAtTime(curr);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Split clip at ${curr.toStringAsFixed(2)}s'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return KeyEventResult.handled;
    }

    // X — Toggle current segment exclusion / Ripple Delete (standard NLE convention)
    if (!isCmdOrCtrl && event.logicalKey == LogicalKeyboardKey.keyX) {
      ref.read(editorProvider.notifier).toggleSegmentDeleted(
        ref.read(editorProvider).currentTime,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toggled segment exclusion under playhead'),
          duration: Duration(seconds: 2),
        ),
      );
      return KeyEventResult.handled;
    }

    // I — Set trim In point at playhead (standard NLE convention)
    if (!isCmdOrCtrl && event.logicalKey == LogicalKeyboardKey.keyI) {
      final editorState = ref.read(editorProvider);
      final curr = editorState.currentTime;
      final project = editorState.project;
      if (project != null) {
        final newEnd = project.trimEnd > curr ? project.trimEnd : project.duration;
        ref.read(editorProvider.notifier).setTrim(curr, newEnd);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('In point set at ${curr.toStringAsFixed(2)}s'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return KeyEventResult.handled;
    }

    // O — Set trim Out point at playhead (standard NLE convention)
    if (!isCmdOrCtrl && event.logicalKey == LogicalKeyboardKey.keyO) {
      final editorState = ref.read(editorProvider);
      final curr = editorState.currentTime;
      final project = editorState.project;
      if (project != null) {
        final newStart = project.trimStart < curr ? project.trimStart : 0.0;
        ref.read(editorProvider.notifier).setTrim(newStart, curr);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Out point set at ${curr.toStringAsFixed(2)}s'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return KeyEventResult.handled;
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
