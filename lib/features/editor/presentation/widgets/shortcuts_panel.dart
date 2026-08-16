import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme.dart';
import '../../../../app/theme_provider.dart';
import '../controllers/editor_controller.dart';

class ShortcutsPanel extends ConsumerWidget {
  const ShortcutsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeProvider);
    final theme = Theme.of(context);

    final isTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');

    final mainContent = Container(
      color: isTesting ? Colors.black87 : Colors.black.withValues(alpha: 0.55),
      child: Center(
        child: Container(
          width: 500,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(28),
          decoration: AppTheme.glassDecoration(
            color: AppTheme.cardBg,
            borderRadius: 16,
            borderOpacity: 0.12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'KEYBOARD SHORTCUTS',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accentOrange,
                        letterSpacing: 1.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.white60),
                    onPressed: () {
                      ref.read(editorProvider.notifier).closeShortcuts();
                    },
                  ),
                ],
              ),
              const Divider(color: Colors.white10, height: 20),
              
              // Scrollable shortcut list
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildSectionHeader('PLAYBACK'),
                      _buildShortcutRow('Space', 'Play / Pause'),
                      _buildShortcutRow('K', 'Pause'),
                      _buildShortcutRow('J', 'Seek −5 seconds'),
                      _buildShortcutRow('L', 'Seek +5 seconds'),
                      _buildShortcutRow('← / →', 'Seek ±0.1 seconds (frame step)'),
                      _buildShortcutRow('F', 'Toggle Fullscreen'),

                      const SizedBox(height: 16),
                      _buildSectionHeader('EDITING'),
                      _buildShortcutRow('${!kIsWeb && Platform.isMacOS ? 'Cmd' : 'Ctrl'} + Z', 'Undo'),
                      _buildShortcutRow('${!kIsWeb && Platform.isMacOS ? 'Cmd' : 'Ctrl'} + Y', 'Redo'),
                      _buildShortcutRow('${!kIsWeb && Platform.isMacOS ? 'Cmd' : 'Ctrl'} + Shift + Z', 'Redo (Alternate)'),
                      _buildShortcutRow('${!kIsWeb && Platform.isMacOS ? 'Cmd' : 'Ctrl'} + S', 'Save Project'),
                      _buildShortcutRow('${!kIsWeb && Platform.isMacOS ? 'Cmd' : 'Ctrl'} + F', 'Find & Replace'),
                      _buildShortcutRow('Enter (on word)', 'Start inline text edit'),
                      _buildShortcutRow('Delete / Backspace (on word)', 'Delete focused word'),
                      _buildShortcutRow('Delete', 'Delete word under playhead'),

                      const SizedBox(height: 16),
                      _buildSectionHeader('NAVIGATION'),
                      _buildShortcutRow('Escape', 'Close panel / Deselect'),
                      _buildShortcutRow('?', 'Show / Hide Shortcuts Panel'),

                      const SizedBox(height: 16),
                      _buildSectionHeader('TIMELINE INTERACTIONS'),
                      _buildShortcutRow('Click ruler', 'Seek playhead'),
                      _buildShortcutRow('Click word chip', 'Cycle highlight color'),
                      _buildShortcutRow('Drag word edge', 'Adjust word start / end timing'),
                      _buildShortcutRow('Double-click word', 'Edit word text inline'),
                      _buildShortcutRow('Scroll wheel / Trackpad', 'Scroll timeline horizontally'),
                      _buildShortcutRow('Pinch / Ctrl+Scroll', 'Zoom timeline'),
                    ],
                  ),
                ),
              ),
              
              const Divider(color: Colors.white10, height: 20),
              // Footer / Dismiss Tip
              Center(
                child: Text(
                  'Press Escape or "?" to close this panel',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.mutedText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return ShortcutsPanelWrapper(child: mainContent);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: AppTheme.accentCyan,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(child: Divider(color: Colors.white10)),
        ],
      ),
    );
  }

  Widget _buildShortcutRow(String keys, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white70,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: AppTheme.glassDecoration(
              color: AppTheme.cardBg.withValues(alpha: 0.25),
              borderRadius: 6,
              borderOpacity: 0.12,
            ),
            child: Text(
              keys,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShortcutsPanelWrapper extends StatelessWidget {
  final Widget child;
  const ShortcutsPanelWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isTesting = !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST');
    if (isTesting) return child;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: child,
      ),
    );
  }
}
