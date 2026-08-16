import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme.dart';
import '../../../../../app/theme_provider.dart';
import '../../../../../core/database/schemas/project.dart';
import '../../../../../core/database/schemas/word.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../core/audio/audio_service.dart';
import '../../../domain/caption_engine.dart';
import '../../controllers/editor_controller.dart';

import 'word_panel/chunk_header.dart';
import 'word_panel/add_word_dialog.dart';
import 'word_panel/emoji_picker_sheet.dart';
import 'word_panel/sfx_picker_dialog.dart';
import '../../../../../core/utils/premium_blur_dialog.dart';

/// Builds chunks only when structural data changes (words, config, trim, segments).
/// Keyed on `revision` so it does NOT rebuild on every currentTime tick during playback.
final builtChunksProvider = Provider<List<Chunk>>((ref) {
  // Watch only the revision + structural fields — NOT currentTime.
  final project = ref.watch(editorProvider.select((s) => s.project));
  ref.watch(editorProvider.select((s) => s.revision)); // invalidates on structural change only
  if (project == null) return const [];
  return CaptionEngine.buildChunks(
    project.words,
    project.segments,
    project.trimStart,
    project.trimEnd,
    project.config.subs.chunkSize,
    project.config.subs.chunkLineMaxLength,
  );
});

final builtChunksWithHiddenProvider = Provider<List<Chunk>>((ref) {
  final project = ref.watch(editorProvider.select((s) => s.project));
  ref.watch(editorProvider.select((s) => s.revision));
  if (project == null) return const [];
  return CaptionEngine.buildChunks(
    project.words,
    project.segments,
    project.trimStart,
    project.trimEnd,
    project.config.subs.chunkSize,
    project.config.subs.chunkLineMaxLength,
    includeHidden: true,
  );
});

final activeWordIdProvider = Provider<String?>((ref) {
  // Read pre-built chunks (no per-frame rebuild). Watch only currentTime for lookup.
  final chunks = ref.watch(builtChunksProvider);
  final currentTime = ref.watch(editorProvider.select((s) => s.currentTime));
  if (chunks.isEmpty) return null;

  final activeChunk = CaptionEngine.getActiveChunk(chunks, currentTime);
  if (activeChunk == null) return null;

  // Scan only the small set of words in the active chunk (typically 2–6 words)
  for (final w in activeChunk.words) {
    if (w.hidden != true &&
        w.start != null &&
        w.end != null &&
        currentTime >= w.start! &&
        currentTime <= w.end!) {
      return w.wordId;
    }
  }
  return null;
});

final activeChunkIndexProvider = Provider<int?>((ref) {
  // Use hidden-inclusive chunks, also rebuilt only on revision change.
  final chunks = ref.watch(builtChunksWithHiddenProvider);
  final currentTime = ref.watch(editorProvider.select((s) => s.currentTime));
  if (chunks.isEmpty) return null;
  final activeChunk = CaptionEngine.getActiveChunk(chunks, currentTime);
  return activeChunk?.index;
});

class WordPanel extends ConsumerStatefulWidget {
  const WordPanel({super.key});

  @override
  ConsumerState<WordPanel> createState() => _WordPanelState();
}

class _WordPanelState extends ConsumerState<WordPanel> {
  int _lastFindReplaceCounter = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(themeProvider);
    final project = ref.watch(editorProvider.select((s) => s.project));
    if (project == null) return const SizedBox.shrink();

    // Listen for Ctrl+F keyboard trigger: open Find & Replace dialog when counter increments.
    final findReplaceCounter = ref.watch(editorProvider.select((s) => s.findReplaceCounter));
    if (findReplaceCounter != _lastFindReplaceCounter) {
      _lastFindReplaceCounter = findReplaceCounter;
      // Use post-frame so the widget is fully built before showing the dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showFindReplaceDialog();
      });
    }

    final config = project.config;
    final chunks = ref.watch(builtChunksWithHiddenProvider);

    return Column(
      children: [
        // Sub-header toolbar: Emoji Style Pack Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: AppTheme.glassDecoration(
            color: Colors.transparent,
            borderRadius: 0,
            borderOpacity: 0.0,
          ).copyWith(
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAPTION LIST',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryText,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${chunks.length} lines · ${project.words.where((w) => w.hidden != true).length} words',
                      style: TextStyle(fontSize: 8, color: AppTheme.mutedText, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Uncertain (<40%)',
                              style: TextStyle(fontSize: 8, color: AppTheme.mutedText),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                color: Colors.orangeAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Medium (40-60%)',
                              style: TextStyle(fontSize: 8, color: AppTheme.mutedText),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.error_outline, size: 16, color: Colors.orangeAccent),
                    tooltip: 'Jump to next uncertain word',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                    onPressed: () {
                      final state = ref.read(editorProvider);
                      final project = state.project;
                      if (project == null || project.words.isEmpty) return;
                      try {
                        final nextUncertain = project.words.firstWhere(
                          (w) => (w.confidence ?? 1.0) < 0.6 &&
                                 (w.start ?? 0.0) > state.currentTime,
                          orElse: () => project.words.firstWhere(
                            (w) => (w.confidence ?? 1.0) < 0.6,
                            orElse: () => project.words.first,
                          ),
                        );
                        final start = nextUncertain.start;
                        if (start != null) {
                          ref.read(editorProvider.notifier).setCurrentTime(start);
                          LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Jumped to uncertain word at ${start.toStringAsFixed(2)}s');
                        }
                      } catch (e) {
                        LoggerService.instance.log(LogLevel.warning, 'WordPanel', 'Failed to jump to uncertain word: $e');
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.find_replace_rounded, size: 16, color: Colors.white70),
                    tooltip: 'Find & Replace',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                    onPressed: _showFindReplaceDialog,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chunks.length,
            itemBuilder: (context, index) {
              final chunk = chunks[index];
              return ChunkRow(
                key: ValueKey(chunk.words.isEmpty ? 'empty_$index' : chunk.words.first.wordId),
                project: project,
                chunk: chunk,
                index: index,
                config: config,
                onWordSettingsTap: (word, isFirstWord) => _showWordSettingsDialog(project, word, isFirstWord: isFirstWord),
                onTimeEditTap: () => _showTimeEditDialog(context, project, chunk),
                onEmojiSettingsTap: (chunk, emojiWord) => _showEmojiSettingsDialog(context, project, chunk, emojiWord),
                onEmojiPickerTap: () => _showEmojiPicker(context, project, chunk),
                onSoundPickerTap: () => _showSoundPickerDialog(context, project, chunk),
              );
            },
          ),
        ),
      ],
    );
  }

  void _saveChunkTiming(Chunk chunk, double newStart, double newEnd) {
    if (chunk.words.isEmpty) return;
    final oldStart = chunk.startTime;
    final oldEnd = chunk.endTime;
    final oldDuration = oldEnd - oldStart;
    final newDuration = newEnd - newStart;
    if (oldDuration <= 0) return;
    final scale = newDuration / oldDuration;

    for (final word in chunk.words) {
      final wordId = word.wordId;
      if (wordId == null) continue;
      final wordStart = word.start ?? oldStart;
      final wordEnd = word.end ?? oldEnd;
      final relStart = (wordStart - oldStart) * scale + newStart;
      final relEnd = (wordEnd - oldStart) * scale + newStart;
      ref.read(editorProvider.notifier).updateWordTimingsQuietly(
        wordId,
        start: relStart,
        end: relEnd,
      );
    }
    ref.read(editorProvider.notifier).commitHistoryAndSave();
    LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Updated chunk timing (proportionally) to: ${newStart.toStringAsFixed(2)}s - ${newEnd.toStringAsFixed(2)}s');
  }

  void _showTimeEditDialog(BuildContext context, Project project, Chunk chunk) {
    if (chunk.words.isEmpty) return;
    ref.read(editorProvider.notifier).setIsPlaying(false);
    final firstWord = chunk.words.first;
    final lastWord = chunk.words.last;

    final double startTime = firstWord.start ?? 0.0;
    final double endTime = lastWord.end ?? 0.0;

    showDialog<void>(
      context: context,
      builder: (context) {
        return TimeEditDialog(
          initialStart: startTime,
          initialEnd: endTime,
          videoDuration: project.duration,
          onSave: (newStart, newEnd) {
            _saveChunkTiming(chunk, newStart, newEnd);
          },
        );
      },
    );
  }

  void _showSoundPickerDialog(BuildContext context, Project project, Chunk chunk) {
    if (chunk.words.isEmpty) return;
    ref.read(editorProvider.notifier).setIsPlaying(false);
    final firstWord = chunk.words.first;
    final firstWordId = firstWord.wordId;
    if (firstWordId == null) return;
    
    final sfxData = SfxData.parse(firstWord.soundEffect, fallbackVolume: firstWord.soundVolume ?? 100);
    final hasChunkSfx = sfxData.chunk != null;
    final initialSfx = hasChunkSfx ? sfxData.chunk!.name : '';
    final initialVolume = (hasChunkSfx ? sfxData.chunk!.volume : 100).toDouble();

    _showSoundLibraryDialog(
      context: context,
      initialSfx: initialSfx,
      initialVolume: initialVolume,
      onSelect: (sfx, vol) {
        final newSfxData = SfxData(
          chunk: sfx.isEmpty ? null : SfxItem(sfx, vol.toInt()),
          word: sfxData.word,
        );
        ref.read(editorProvider.notifier).updateWord(
          firstWordId,
          soundEffect: newSfxData.toRaw(),
          soundVolume: vol.toInt(),
        );
        LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Updated chunk sound to: chunk:$sfx');
      },
      onRemove: !hasChunkSfx ? null : () {
        final newSfxData = SfxData(
          chunk: null,
          word: sfxData.word,
        );
        ref.read(editorProvider.notifier).updateWord(
          firstWordId,
          soundEffect: newSfxData.toRaw(),
          soundVolume: 100,
        );
        LoggerService.instance.log(LogLevel.action, 'WordPanel', 'Removed sound from chunk');
      },
    );
  }

  void _showSoundLibraryDialog({
    required BuildContext context,
    required String initialSfx,
    required double initialVolume,
    required void Function(String sfxId, double volume) onSelect,
    VoidCallback? onRemove,
  }) {
    ref.read(editorProvider.notifier).setIsPlaying(false);
    showDialog<void>(
      context: context,
      builder: (context) {
        return SfxPickerDialog(
          initialSfx: initialSfx,
          initialVolume: initialVolume,
          onSelect: onSelect,
          onRemove: onRemove,
        );
      },
    );
  }

  void _showEmojiPicker(BuildContext context, Project project, Chunk chunk) {
    ref.read(editorProvider.notifier).setIsPlaying(false);
    showDialog<void>(
      context: context,
      builder: (context) {
        return EmojiPickerDialog(
          project: project,
          chunk: chunk,
        );
      },
    );
  }

  void _showEmojiSettingsDialog(BuildContext context, Project project, Chunk chunk, WordSchema word) {
    ref.read(editorProvider.notifier).setIsPlaying(false);
    showDialog<void>(
      context: context,
      builder: (context) {
        return EmojiSettingsDialog(
          word: word,
          project: project,
          chunk: chunk,
        );
      },
    );
  }

  void _showWordSettingsDialog(Project project, WordSchema word, {bool isFirstWord = false}) {
    ref.read(editorProvider.notifier).setIsPlaying(false);
    showDialog<void>(
      context: context,
      builder: (context) {
        return WordSettingsDialog(
          project: project,
          word: word,
          isFirstWord: isFirstWord,
          onSoundLibraryTap: (ctx, initialSfx, initialVolume, onSelect, onRemove) {
            _showSoundLibraryDialog(
              context: ctx,
              initialSfx: initialSfx,
              initialVolume: initialVolume,
              onSelect: onSelect,
              onRemove: onRemove,
            );
          },
        );
      },
    );
  }

  void _showFindReplaceDialog() {
    ref.read(editorProvider.notifier).setIsPlaying(false);
    showDialog<void>(
      context: context,
      builder: (context) {
        return const _FindReplaceDialog();
      },
    );
  }
}

class _FindReplaceDialog extends ConsumerStatefulWidget {
  const _FindReplaceDialog();

  @override
  ConsumerState<_FindReplaceDialog> createState() => _FindReplaceDialogState();
}

class _FindReplaceDialogState extends ConsumerState<_FindReplaceDialog> {
  late TextEditingController findCtrl;
  late TextEditingController replaceCtrl;
  int replaceCount = 0;

  @override
  void initState() {
    super.initState();
    findCtrl = TextEditingController();
    replaceCtrl = TextEditingController();
  }

  @override
  void dispose() {
    findCtrl.dispose();
    replaceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBlurDialog(
      maxWidth: 400,
      glowColor: AppTheme.accentOrange,
      glowOpacity: 0.1,
      useScrollView: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'FIND & REPLACE',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryText,
                  letterSpacing: 1.5,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.white70),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 16),
          TextField(
            controller: findCtrl,
            style: TextStyle(fontSize: 13, color: AppTheme.primaryText),
            decoration: InputDecoration(
              labelText: 'Find text',
              border: AppTheme.defaultBorder(),
              focusedBorder: AppTheme.focusedBorder(),
              filled: true,
              fillColor: AppTheme.cardBg,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: replaceCtrl,
            style: TextStyle(fontSize: 13, color: AppTheme.primaryText),
            decoration: InputDecoration(
              labelText: 'Replace with',
              border: AppTheme.defaultBorder(),
              focusedBorder: AppTheme.focusedBorder(),
              filled: true,
              fillColor: AppTheme.cardBg,
            ),
          ),
          if (replaceCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Replaced $replaceCount occurrences!',
                style: TextStyle(color: AppTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('CANCEL', style: TextStyle(color: AppTheme.secondaryText, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  final findText = findCtrl.text;
                  final replaceText = replaceCtrl.text;
                  if (findText.isEmpty) return;

                  final count = ref.read(editorProvider.notifier).findAndReplaceText(findText, replaceText);
                  setState(() {
                    replaceCount = count;
                  });
                },
                child: const Text('REPLACE ALL', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
