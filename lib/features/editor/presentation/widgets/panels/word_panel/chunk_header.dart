import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../../../../app/theme.dart';
import '../../../../../../core/database/schemas/project.dart';
import '../../../../../../core/database/schemas/word.dart';
import '../../../../../../core/emoji/emoji_service.dart';
import '../../../../../../core/audio/audio_service.dart';
import '../../../../../../core/logger/logger_service.dart';
import '../../../../../../core/audio/speaker_diarization_service.dart';
import '../../../../domain/caption_engine.dart';
import '../../../controllers/editor_controller.dart';
import '../word_panel.dart';
import 'word_card.dart';
import 'speaker_diarization_dialog.dart';

class ChunkRow extends ConsumerWidget {
  final Project project;
  final Chunk chunk;
  final int index;
  final ProjectConfigSchema config;
  final void Function(WordSchema word, bool isFirstWord) onWordSettingsTap;
  final VoidCallback onTimeEditTap;
  final void Function(Chunk chunk, WordSchema emojiWord) onEmojiSettingsTap;
  final VoidCallback onEmojiPickerTap;
  final VoidCallback onSoundPickerTap;

  const ChunkRow({
    super.key,
    required this.project,
    required this.chunk,
    required this.index,
    required this.config,
    required this.onWordSettingsTap,
    required this.onTimeEditTap,
    required this.onEmojiSettingsTap,
    required this.onEmojiPickerTap,
    required this.onSoundPickerTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isChunkActive = ref.watch(activeChunkIndexProvider.select((idx) => idx == chunk.index));

    // Find all emoji words in this chunk and their local preview assets
    final chunkEmojiWords = <(WordSchema, String?)>[];
    for (final w in chunk.words) {
      final emoji = w.emoji;
      if (emoji != null && emoji.isNotEmpty && emoji != 'none') {
        String? emojiAssetPath;
        final parsed = EmojiPackParser.parse(emoji, config.emojiPack ?? 'notoColorEmoji');
        final activePack = (parsed.pack.isEmpty || parsed.pack == 'default')
            ? (config.emojiPack ?? 'notoColorEmoji')
            : parsed.pack;

        final resolvedSticker = (!kIsWeb)
            ? (EmojiService.resolveStickerPath(parsed.glyph) ??
                EmojiService.resolveStickerPath(emoji))
            : null;
        if (resolvedSticker != null) {
          emojiAssetPath = resolvedSticker;
        } else if (activePack != 'systemDefault') {
          // Use the static equivalent of animated packs for the editor list sidebar
          final String staticPack = activePack == 'googleAnimated'
              ? 'googleNonAnimated'
              : (activePack == 'microsoftAnimated' ? 'microsoftNonAnimated' : activePack);

          final emojiModel = EmojiService.instance.findByGlyph(parsed.glyph);
          if (emojiModel != null) {
            final bool exists = EmojiService.instance.hasAssetOnDisk(emojiModel, staticPack);
            if (exists) {
              final asset = EmojiService.instance.getAssetPath(emojiModel, staticPack);
              if (asset != null) {
                emojiAssetPath = asset.absolutePath;
              }
            }
          }
        }
        chunkEmojiWords.add((w, emojiAssetPath));
      }
    }

    // Find if this chunk has a chunk-level sound effect.
    WordSchema? soundWord;
    if (chunk.words.isNotEmpty) {
      final firstWord = chunk.words.first;
      final sfxData = SfxData.parse(firstWord.soundEffect, fallbackVolume: firstWord.soundVolume ?? 100);
      if (sfxData.chunk != null) {
        soundWord = firstWord;
      }
    }

    final isHidden = chunk.words.every((w) => w.hidden == true);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: isHidden ? 0.45 : 1.0,
        child: InkWell(
          onTap: () {
            ref.read(editorProvider.notifier).setCurrentTime(chunk.startTime);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: AppTheme.glassDecoration(
              color: isChunkActive ? AppTheme.accentOrange.withValues(alpha: 0.08) : AppTheme.cardBg,
              borderRadius: 8,
              borderOpacity: isChunkActive ? 0.2 : 0.06,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chunk Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Chunk ${index + 1}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isChunkActive ? AppTheme.accentOrange : AppTheme.mutedText,
                            ),
                          ),
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => showSpeakerDiarizationDialog(context, ref, targetChunk: chunk),
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: AppTheme.glassDecoration(
                                color: chunk.speaker != null && chunk.speaker!.isNotEmpty
                                    ? SpeakerDiarizationService.getSpeakerColor(chunk.speaker!).withValues(alpha: 0.15)
                                    : AppTheme.cardBg,
                                borderRadius: 4,
                                borderOpacity: chunk.speaker != null && chunk.speaker!.isNotEmpty ? 0.25 : 0.06,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.person_rounded,
                                    size: 10,
                                    color: chunk.speaker != null && chunk.speaker!.isNotEmpty
                                        ? SpeakerDiarizationService.getSpeakerColor(chunk.speaker!)
                                        : AppTheme.mutedText,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    chunk.speaker != null && chunk.speaker!.isNotEmpty
                                        ? chunk.speaker!
                                        : 'Speaker',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: chunk.speaker != null && chunk.speaker!.isNotEmpty
                                          ? SpeakerDiarizationService.getSpeakerColor(chunk.speaker!)
                                          : AppTheme.mutedText,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.arrow_drop_down,
                                    size: 12,
                                    color: chunk.speaker != null && chunk.speaker!.isNotEmpty
                                        ? SpeakerDiarizationService.getSpeakerColor(chunk.speaker!)
                                        : AppTheme.mutedText,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isChunkActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: AppTheme.glassDecoration(
                            color: AppTheme.accentOrange.withValues(alpha: 0.15),
                            borderRadius: 4,
                            borderOpacity: 0.2,
                          ),
                          child: Text(
                            'ACTIVE',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.accentOrange,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTheme.dividerColor),

                // Chunk Words Area
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...chunk.words.map((word) {
                        return WordCard(
                          key: ValueKey(word.wordId),
                          project: project,
                          word: word,
                          isFirstWord: word == chunk.words.first,
                          onWordSettingsTap: onWordSettingsTap,
                        );
                      }),
                    ],
                  ),
                ),
                Divider(height: 1, color: AppTheme.dividerColor),

                // Chunk Footer Toolbar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final useColumnLayout = constraints.maxWidth < 340;

                      final firstRow = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: onTimeEditTap,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: AppTheme.glassDecoration(
                                color: AppTheme.cardBg.withValues(alpha: 0.25),
                                borderRadius: 6,
                                borderOpacity: 0.08,
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 10, color: AppTheme.accentOrange),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${chunk.startTime.toStringAsFixed(2)}s → ${chunk.endTime.toStringAsFixed(2)}s',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontFamily: 'monospace',
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.secondaryText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Emoji quick selector / settings
                          if (chunkEmojiWords.isEmpty) ...[
                            IconButton(
                              icon: Text(
                                '😀',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.mutedText,
                                  fontFamily: 'Noto Color Emoji',
                                ),
                              ),
                              tooltip: 'Add Emoji',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 16,
                              onPressed: onEmojiPickerTap,
                            ),
                          ] else ...[
                            for (final item in chunkEmojiWords) ...[
                              Builder(
                                builder: (context) {
                                  final parsed = EmojiPackParser.parse(item.$1.emoji ?? '', '');
                                  final resolvedSticker = (!kIsWeb)
                                      ? (EmojiService.resolveStickerPath(item.$2) ??
                                          EmojiService.resolveStickerPath(parsed.glyph))
                                      : null;
                                  final isFilePath = parsed.glyph.startsWith('/') ||
                                      RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(parsed.glyph) ||
                                      parsed.pack == 'custom' ||
                                      parsed.glyph.endsWith('.png') ||
                                      parsed.glyph.endsWith('.webp') ||
                                      parsed.glyph.endsWith('.jpg') ||
                                      parsed.glyph.endsWith('.jpeg') ||
                                      parsed.glyph.endsWith('.gif') ||
                                      parsed.glyph.contains('/') ||
                                      parsed.glyph.contains('\\');
                                  final hasValidFile = !kIsWeb && resolvedSticker != null;
                                  final label = (!kIsWeb && isFilePath)
                                      ? p.basenameWithoutExtension(parsed.glyph)
                                      : parsed.glyph;

                                  Widget iconWidget;
                                  if (hasValidFile) {
                                    iconWidget = Image.file(
                                      File(resolvedSticker),
                                      width: 16,
                                      height: 16,
                                      fit: BoxFit.contain,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined, size: 14),
                                    );
                                  } else if (isFilePath) {
                                    iconWidget = const Icon(Icons.image_outlined, size: 14);
                                  } else {
                                    iconWidget = Text(
                                      parsed.glyph,
                                      style: const TextStyle(fontSize: 12, fontFamily: 'Noto Color Emoji'),
                                    );
                                  }

                                  return IconButton(
                                    icon: iconWidget,
                                    tooltip: 'Emoji Settings ($label)',
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    splashRadius: 16,
                                    onPressed: () => onEmojiSettingsTap(chunk, item.$1),
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                            ],
                            IconButton(
                              icon: Icon(Icons.add_reaction_outlined, size: 14, color: AppTheme.mutedText),
                              tooltip: 'Add Another Emoji',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 16,
                              onPressed: onEmojiPickerTap,
                            ),
                          ],
                          const SizedBox(width: 8),

                          // Sound Quick Selector
                          IconButton(
                            icon: Icon(
                              soundWord != null ? Icons.volume_up : Icons.volume_mute_outlined,
                              size: 14,
                              color: soundWord != null ? AppTheme.accentCyan : AppTheme.mutedText,
                            ),
                            tooltip: soundWord != null ? 'Sound: ${soundWord.soundEffect!.replaceFirst('chunk:', '')}' : 'Add Sound Effect',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 16,
                            onPressed: onSoundPickerTap,
                          ),
                        ],
                      );

                      final secondRow = Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: isHidden ? 'Unhide Line' : 'Hide Line',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () {
                                final ids = chunk.words.map((w) => w.wordId).whereType<String>().toList();
                                ref.read(editorProvider.notifier).batchUpdateWords(ids, hidden: !isHidden);
                                LoggerService.instance.log(LogLevel.action, 'WordPanel', '${isHidden ? "Unhid" : "Hid"} chunk at index $index');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(
                                  isHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  size: 14,
                                  color: isHidden ? AppTheme.accentRed : AppTheme.mutedText,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          if (chunk.words.length > 1) ...[
                            Tooltip(
                              message: 'Split Chunk',
                              child: InkWell(
                                borderRadius: BorderRadius.circular(4),
                                onTap: () {
                                  WordSchema? bestSplitWord;
                                  double maxGap = 0;
                                  for (int i = 1; i < chunk.words.length; i++) {
                                    final prevEnd = chunk.words[i - 1].end ?? 0.0;
                                    final currStart = chunk.words[i].start ?? 0.0;
                                    final gap = currStart - prevEnd;
                                    if (gap > maxGap) {
                                      maxGap = gap;
                                      bestSplitWord = chunk.words[i];
                                    }
                                  }
                                  if (bestSplitWord == null || maxGap <= 0) {
                                    final midIdx = (chunk.words.length / 2).ceil();
                                    bestSplitWord = chunk.words[midIdx];
                                  }
                                  final wordId = bestSplitWord.wordId;
                                  if (wordId != null) {
                                    ref.read(editorProvider.notifier).splitChunkAtWord(wordId);
                                    LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Split chunk at word "${bestSplitWord.text}"');
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(6.0),
                                  child: Icon(Icons.content_cut_rounded, size: 12, color: AppTheme.mutedText),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],

                          Tooltip(
                            message: 'Insert Line After',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () {
                                final lastWord = chunk.words.last;
                                final lastWordId = lastWord.wordId;
                                if (lastWordId != null) {
                                  ref.read(editorProvider.notifier).addChunkAfter(lastWordId);
                                  LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Inserted new line after chunk $index');
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(Icons.add_circle_outline_rounded, size: 14, color: AppTheme.mutedText),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          Tooltip(
                            message: 'Duplicate Chunk',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () {
                                final ids = chunk.words.map((w) => w.wordId).whereType<String>().toList();
                                if (ids.isNotEmpty) {
                                  ref.read(editorProvider.notifier).duplicateChunk(ids);
                                  LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Duplicated chunk at index $index');
                                }
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(Icons.copy_outlined, size: 13, color: AppTheme.mutedText),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          Tooltip(
                            message: 'Cut Video for Chunk (Transcript Edit)',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () {
                                ref.read(editorProvider.notifier).cutVideoSegmentForTimeRange(
                                  chunk.startTime,
                                  chunk.endTime,
                                  hideWords: true,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Cut video for chunk ${index + 1} (${chunk.startTime.toStringAsFixed(1)}s – ${chunk.endTime.toStringAsFixed(1)}s)'),
                                    backgroundColor: AppTheme.accentOrange,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(Icons.movie_filter_outlined, size: 14, color: AppTheme.accentOrange),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          Tooltip(
                            message: 'Delete Chunk',
                            child: InkWell(
                              borderRadius: BorderRadius.circular(4),
                              onTap: () {
                                final ids = chunk.words.map((w) => w.wordId).whereType<String>().toList();
                                ref.read(editorProvider.notifier).deleteWords(ids);
                                LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Deleted chunk at index $index');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(6.0),
                                child: Icon(Icons.delete_outline_rounded, size: 14, color: AppTheme.accentRed),
                              ),
                            ),
                          ),
                        ],
                      );

                      if (useColumnLayout) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                firstRow,
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                secondRow,
                              ],
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            firstRow,
                            secondRow,
                          ],
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
