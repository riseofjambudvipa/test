import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../controllers/editor_controller.dart';

class EditorKeyboardHintBar extends ConsumerWidget {
  const EditorKeyboardHintBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasUnsavedChanges = ref.watch(editorProvider.select((s) => s.hasUnsavedChanges));
    final isMac = !kIsWeb && Platform.isMacOS;
    final modifier = isMac ? 'Cmd' : 'Ctrl';

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: AppTheme.glassDecoration(
        color: AppTheme.cardBg.withValues(alpha: 0.55),
        borderRadius: 0,
        borderOpacity: 0.0,
      ).copyWith(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
        children: [
          ...[
            ['$modifier+S', 'Save'],
            ['Space', 'Play/Pause'],
            ['K', 'Pause'],
            ['J/L', '±5s'],
            ['←→', '±0.1s'],
            ['F', 'Fullscreen'],
            ['$modifier+Z', 'Undo'],
            ['$modifier+Y', 'Redo'],
            ['$modifier+F', 'Find'],
            ['Esc', 'Close Panel'],
          ].map((pair) => Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: AppTheme.glassDecoration(
                    color: AppTheme.cardBg.withValues(alpha: 0.25),
                    borderRadius: 8,
                    borderOpacity: 0.12,
                  ),
                  child: Text(
                    pair[0],
                    style: TextStyle(
                      fontSize: 8,
                      fontFamily: 'monospace',
                      color: AppTheme.mutedText,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  pair[1],
                  style: TextStyle(
                    fontSize: 8,
                    color: AppTheme.mutedText,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          )),
          const SizedBox(width: 24),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: hasUnsavedChanges ? AppTheme.accentOrange : AppTheme.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                hasUnsavedChanges ? 'Unsaved' : 'Saved',
                style: TextStyle(
                  fontSize: 8,
                  color: AppTheme.mutedText,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }
}
