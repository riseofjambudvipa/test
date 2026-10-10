import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_provider.dart';
import '../controllers/editor_controller.dart';

class EditorKeyboardHintBar extends ConsumerWidget {
  const EditorKeyboardHintBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appTheme = ref.watch(themeProvider);
    final isDark = appTheme.isDark;
    final hasUnsavedChanges = ref.watch(editorProvider.select((s) => s.hasUnsavedChanges));
    final isMac = !kIsWeb && Platform.isMacOS;
    final modifier = isMac ? 'Cmd' : 'Ctrl';

    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF120D1C) : const Color(0xFFF6F2F9),
        border: Border(
          top: BorderSide(
            color: AppTheme.borderGlass,
            width: 1.0,
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppTheme.borderGlass,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    pair[0],
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'monospace',
                      color: AppTheme.primaryText,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  pair[1],
                  style: TextStyle(
                    fontSize: 9.5,
                    color: AppTheme.secondaryText,
                    letterSpacing: 0.2,
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
                  fontSize: 9.5,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.secondaryText,
                  letterSpacing: 0.2,
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
