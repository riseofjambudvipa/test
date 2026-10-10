import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../../../../core/database/schemas/word.dart';
import '../../../../../../core/emoji/emoji_service.dart';
import '../../../../../../core/logger/logger_service.dart';
import '../../../../../../core/audio/audio_service.dart';
import '../../../controllers/editor_controller.dart';
import '../word_panel.dart';

class WordCard extends ConsumerWidget {
  final Project project;
  final WordSchema word;
  final bool isFirstWord;
  final void Function(WordSchema word, bool isFirstWord) onWordSettingsTap;

  const WordCard({
    super.key,
    required this.project,
    required this.word,
    required this.isFirstWord,
    required this.onWordSettingsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWordActive = ref.watch(activeWordIdProvider.select((id) => id == word.wordId));

    Color wordColor = AppTheme.primaryText;
    if (word.className != null) {
      if (word.className == 'mainColor') wordColor = AppTheme.accentOrange;
      if (word.className == 'secondColor') wordColor = AppTheme.accentCyan;
      if (word.className == 'thirdColor') wordColor = AppTheme.accentGreen;
    } else if (isWordActive) {
      wordColor = AppTheme.accentOrange;
    }

    final wordId = word.wordId;
    if (wordId == null) return const SizedBox.shrink();

    return RepaintBoundary(
      child: Focus(
        debugLabel: 'WordChip_$wordId',
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter) {
              onWordSettingsTap(word, isFirstWord);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.delete ||
                event.logicalKey == LogicalKeyboardKey.backspace) {
              // FIX (audit): holding Delete/Backspace fires auto-repeated
              // KeyRepeatEvent instances that deleted several words in a burst
              // with no confirmation. Swallow repeats so only deliberate
              // presses act.
              if (event is KeyRepeatEvent) return KeyEventResult.handled;
              ref.read(editorProvider.notifier).deleteWords([wordId]);
              LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Deleted word via keyboard shortcut');
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Builder(
          builder: (context) {
            final hasFocus = Focus.of(context).hasFocus;
            return InkWell(
              onTap: () => onWordSettingsTap(word, isFirstWord),
              onDoubleTap: () => onWordSettingsTap(word, isFirstWord),
              onLongPress: () => onWordSettingsTap(word, isFirstWord),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: AppTheme.glassDecoration(
                  color: isWordActive
                      ? AppTheme.cardBgElevated
                      : (hasFocus ? AppTheme.hoverBg : Colors.transparent),
                  borderRadius: 4,
                  borderOpacity: isWordActive
                      ? 0.3
                      : (hasFocus ? 0.5 : 0.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      (word.text == null || word.text!.isEmpty) ? '[New Word]' : word.text!,
                      style: TextStyle(
                        fontSize: 13,
                        fontFamilyFallback: AppThemeData.fontFallbacks,
                        color: (word.text == null || word.text!.isEmpty) ? wordColor.withValues(alpha: 0.5) : wordColor,
                        fontStyle: (word.text == null || word.text!.isEmpty) ? FontStyle.italic : FontStyle.normal,
                        fontWeight: isWordActive ? FontWeight.bold : FontWeight.normal,
                        decoration: word.hidden == true ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (word.emoji != null && word.emoji!.isNotEmpty && word.emoji != 'none') ...[
                      const SizedBox(width: 3),
                      Builder(
                        builder: (context) {
                          final parsed = EmojiPackParser.parse(word.emoji!, '');
                          final resolvedPath = (!kIsWeb) ? EmojiService.resolveStickerPath(parsed.glyph) : null;
                          final isSticker = !kIsWeb &&
                              (resolvedPath != null ||
                                  parsed.pack == 'custom' ||
                                  parsed.glyph.endsWith('.png') ||
                                  parsed.glyph.endsWith('.webp') ||
                                  parsed.glyph.endsWith('.jpg') ||
                                  parsed.glyph.endsWith('.jpeg') ||
                                  parsed.glyph.endsWith('.gif') ||
                                  parsed.glyph.contains('/') ||
                                  parsed.glyph.contains('\\'));
                          if (resolvedPath != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Image.file(
                                File(resolvedPath),
                                width: 14,
                                height: 14,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 12),
                              ),
                            );
                          }
                          if (isSticker) {
                            return const Icon(Icons.image_outlined, size: 12);
                          }
                          return Text(
                            parsed.glyph,
                            style: const TextStyle(fontSize: 11, fontFamily: 'Noto Color Emoji'),
                          );
                        },
                      ),
                    ],
                    Builder(
                      builder: (context) {
                        final sfxData = SfxData.parse(word.soundEffect, fallbackVolume: word.soundVolume ?? 100);
                        if (sfxData.word != null) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 2),
                              Icon(Icons.volume_up, size: 10, color: AppTheme.accentCyan),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    if (word.confidence != null && word.confidence! < 0.6) ...[
                      const SizedBox(width: 2),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: word.confidence! < 0.4 ? AppTheme.accentRed : AppTheme.accentOrange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
