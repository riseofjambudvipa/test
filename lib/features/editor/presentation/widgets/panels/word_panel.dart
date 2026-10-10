import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../app/theme.dart';
import '../../../../../app/theme_provider.dart';
import '../../../../../core/database/schemas/project.dart';
import '../../../../../core/database/schemas/word.dart';
import '../../../../../core/logger/logger_service.dart';
import '../../../../../core/audio/audio_service.dart';
import '../../../../../core/subtitle/srt_importer.dart';
import '../../../domain/caption_engine.dart';
import '../../controllers/editor_controller.dart';
import '../../controllers/editor_state.dart';

import 'word_panel/chunk_header.dart';
import 'word_panel/add_word_dialog.dart';
import 'word_panel/emoji_picker_sheet.dart';
import 'word_panel/sfx_picker_dialog.dart';
import 'word_panel/add_caption_card.dart';
import 'word_panel/find_replace_dialog.dart';
import 'word_panel/b_roll_suggestions_dialog.dart';
import 'word_panel/speaker_diarization_dialog.dart';
import 'word_panel/review_comments_dialog.dart';
import 'word_panel/filler_words_dialog.dart';
import 'word_panel/chapter_generator_dialog.dart';
import '../../../../../core/utils/premium_blur_dialog.dart';
import '../../../../../l10n/app_localizations.dart';

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
  // FIX (audit): guards against a second Ctrl+F stacking another Find dialog
  // while one is already open.
  bool _isFindDialogOpen = false;

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

    final l10n = AppLocalizations.of(context);
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
              bottom: BorderSide(color: AppTheme.borderGlass),
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isVeryNarrow = constraints.maxWidth < 280;
              return Row(
                children: [
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n?.captionList ?? 'CAPTION LIST',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.secondaryText,
                            letterSpacing: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!isVeryNarrow) ...[
                          const SizedBox(height: 2),
                          Text(
                            '${chunks.length} lines · ${project.words.where((w) => w.hidden != true).length} words',
                            style: TextStyle(fontSize: 8, color: AppTheme.mutedText, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 2,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                        Container(
                          constraints: const BoxConstraints(maxWidth: 95),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  l10n?.uncertainLabel ?? 'Uncertain (<40%)',
                                  style: TextStyle(fontSize: 8, color: AppTheme.mutedText),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          constraints: const BoxConstraints(maxWidth: 95),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: AppTheme.accentOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  l10n?.mediumConfidenceLabel ?? 'Medium (40-60%)',
                                  style: TextStyle(fontSize: 8, color: AppTheme.mutedText),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.error_outline, size: 16, color: AppTheme.accentOrange),
                    tooltip: l10n?.jumpToUncertain ?? 'Jump to next uncertain word',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,                    onPressed: () {
                      final state = ref.read(editorProvider);
                      final project = state.project;
                      if (project == null || project.words.isEmpty) return;
                      try {
                        // FIX (audit): with no uncertain word the old orElse
                        // fell back to project.words.first and jumped there
                        // anyway, logging a misleading "jumped to uncertain
                        // word". Only jump when an uncertain word exists.
                        final anyUncertain = project.words
                            .where((w) => (w.confidence ?? 1.0) < 0.6)
                            .toList();
                        if (anyUncertain.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n?.noUncertainWords ?? 'No uncertain words found.')),
                          );
                          return;
                        }
                        final afterCurrent = anyUncertain
                            .where((w) => (w.start ?? 0.0) > state.currentTime)
                            .toList();
                        final nextUncertain = afterCurrent.isNotEmpty
                            ? afterCurrent.first
                            : anyUncertain.first;
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
                    icon: Icon(Icons.find_replace_rounded, size: 16, color: AppTheme.secondaryText),
                    tooltip: l10n?.findAndReplace ?? 'Find & Replace',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                    onPressed: _showFindReplaceDialog,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.post_add_rounded, size: 16, color: AppTheme.accentOrange),
                    tooltip: 'Add Caption at Selected Time',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                    onPressed: () => _showAddCaptionDialog(context, project),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.accentCyan),
                    tooltip: 'AI Auto-Enhancements (Magic Emojis, SFX, Fillers)',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                    color: AppTheme.cardBgElevated,
                    onSelected: (val) => _handleAutoEnhance(val, project),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'magic_emojis',
                        child: Row(
                          children: [
                            const Text('🪄', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Text('Magic Emojis (Keywords)', style: TextStyle(fontSize: 12, color: AppTheme.primaryText)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'magic_sfx',
                        child: Row(
                          children: [
                            const Text('🔊', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 8),
                            Text('Magic SFX (Transitions)', style: TextStyle(fontSize: 12, color: AppTheme.primaryText)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'remove_fillers',
                        child: Row(
                          children: [
                            Icon(Icons.content_cut_rounded, size: 15, color: AppTheme.accentRed),
                            const SizedBox(width: 8),
                            Text('Remove Filler Words (um, uh)', style: TextStyle(fontSize: 12, color: AppTheme.primaryText)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'b_roll_ideas',
                        child: Row(
                          children: [
                            Icon(Icons.video_library_outlined, size: 15, color: AppTheme.accentCyan),
                            const SizedBox(width: 8),
                            Text('AI B-Roll Ideas (Stock Footage)', style: TextStyle(fontSize: 12, color: AppTheme.primaryText)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'speaker_diarization',
                        child: Row(
                          children: [
                            Icon(Icons.record_voice_over_rounded, size: 15, color: AppTheme.accentOrange),
                            const SizedBox(width: 8),
                            Text('Detect Multi-Speakers (Diarization)', style: TextStyle(fontSize: 12, color: AppTheme.primaryText)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'youtube_chapters',
                        child: Row(
                          children: [
                            Icon(Icons.bookmarks_outlined, size: 15, color: AppTheme.accentOrange),
                            const SizedBox(width: 8),
                            Text('YouTube Chapters Generator', style: TextStyle(fontSize: 12, color: AppTheme.primaryText)),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'clear_emojis',
                        child: Row(
                          children: [
                            Icon(Icons.clear_rounded, size: 15, color: AppTheme.mutedText),
                            const SizedBox(width: 8),
                            Text('Clear All Emojis', style: TextStyle(fontSize: 12, color: AppTheme.mutedText)),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'clear_sfx',
                        child: Row(
                          children: [
                            Icon(Icons.volume_off_outlined, size: 15, color: AppTheme.mutedText),
                            const SizedBox(width: 8),
                            Text('Clear All SFX', style: TextStyle(fontSize: 12, color: AppTheme.mutedText)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.rate_review_outlined, size: 16, color: AppTheme.accentCyan),
                    tooltip: 'Team Review Notes & Approvals',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                    onPressed: () => ReviewCommentsDialog.show(context),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  ),
),
        Expanded(
          child: chunks.isEmpty
              ? _buildEmptyCaptionsView(context, project, l10n)
              : ListView.builder(
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

  Widget _buildEmptyCaptionsView(BuildContext context, Project project, AppLocalizations? l10n) {
    final currentTime = ref.watch(editorProvider.select((s) => s.currentTime));
    final isDemoProject = project.videoPath.contains('demo') || project.name.toLowerCase().contains('demo');
    final duration = project.duration > 0 ? project.duration : 60.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        children: [
          // ── Empty state icon + message ──
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentOrange.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.subtitles_off_rounded, size: 32, color: AppTheme.accentOrange),
          ),
          const SizedBox(height: 12),
          Text(
            'No Captions in Project',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryText),
          ),
          const SizedBox(height: 6),
          Text(
            'Add captions manually, import a subtitle file, or auto-transcribe.',
            style: TextStyle(fontSize: 11, color: AppTheme.secondaryText, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // ── 1. Add caption at custom time ──
          AddCaptionAtTimeCard(
            currentTime: currentTime,
            maxDuration: duration,
            onAdd: (start, end, text) {
              ref.read(editorProvider.notifier).addCaptionAtPlayhead(
                text: text,
                atTime: start,
                duration: end - start,
              );
            },
          ),
          const SizedBox(height: 10),

          // ── 2. Import SRT/VTT ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(Icons.file_open_rounded, size: 16, color: AppTheme.accentCyan),
              label: Text(
                'IMPORT SRT / VTT FILE',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentCyan),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.accentCyan.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => _importSubtitleFile(project),
            ),
          ),
          const SizedBox(height: 10),

          // ── 3. Auto-transcribe ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: Icon(Icons.record_voice_over_rounded, size: 16, color: AppTheme.accentOrange),
              label: Text(
                'AUTO-TRANSCRIBE AUDIO (STT)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentOrange),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.accentOrange.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                ref.read(editorProvider.notifier).setActiveTab(EditorTab.transcription);
              },
            ),
          ),

          // ── 4. Restore demo subtitles ──
          if (isDemoProject) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: Icon(Icons.restore_rounded, size: 16, color: AppTheme.accentGreen),
                label: Text(
                  'RESTORE DEMO SUBTITLES',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.accentGreen),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppTheme.accentGreen.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await ref.read(editorProvider.notifier).restoreDemoSubtitles();
                  if (success) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: const Text('Demo subtitles restored successfully!'),
                        backgroundColor: AppTheme.accentGreen,
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _importSubtitleFile(Project project) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['srt', 'vtt', 'txt'],
      );
      if (result == null || result.files.isEmpty) return;

      final bytes = await result.files.single.readAsBytes();
      final content = utf8.decode(bytes);

      final words = SrtImporter.parseSrtString(content);
      if (words.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No captions found in file. Check format (SRT/VTT).'),
              backgroundColor: AppTheme.accentRed,
            ),
          );
        }
        return;
      }

      ref.read(editorProvider.notifier).importSubtitles(words);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${words.length} words from subtitle file!'),
            backgroundColor: AppTheme.accentGreen,
          ),
        );
      }
      LoggerService.instance.action('WordPanel', 'Imported ${words.length} words from ${result.files.single.name}');
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'WordPanel', 'SRT import failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import subtitle file: $e'),
            backgroundColor: AppTheme.accentRed,
          ),
        );
      }
    }
  }

  void _saveChunkTiming(Chunk chunk, double newStart, double newEnd) {
    if (chunk.words.isEmpty) return;
    final oldStart = chunk.startTime;
    final oldEnd = chunk.endTime;
    final oldDuration = oldEnd - oldStart;
    final newDuration = newEnd - newStart;
    if (oldDuration <= 0) return;
    final scale = newDuration / oldDuration;

    // FIX (perf): compute all scaled timings first, then apply in ONE project
    // clone + revision bump (the old per-word loop cloned the entire project
    // for every word in the chunk).
    final timings = <({String wordId, double start, double end})>[];
    for (final word in chunk.words) {
      final wordId = word.wordId;
      if (wordId == null) continue;
      final wordStart = word.start ?? oldStart;
      final wordEnd = word.end ?? oldEnd;
      final relStart = (wordStart - oldStart) * scale + newStart;
      final relEnd = (wordEnd - oldStart) * scale + newStart;
      timings.add((wordId: wordId, start: relStart, end: relEnd));
    }
    if (timings.isNotEmpty) {
      ref.read(editorProvider.notifier).updateWordTimingsQuietlyBatch(timings);
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

  void _showAddCaptionDialog(BuildContext context, Project project) {
    ref.read(editorProvider.notifier).setIsPlaying(false);
    final currentTime = ref.read(editorProvider).currentTime;
    final maxDuration = project.duration > 0 ? project.duration : 3600.0;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return PremiumBlurDialog(
          maxWidth: 380,
          useScrollView: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ADD CAPTION',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryText,
                      letterSpacing: 1.5,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: AppTheme.secondaryText),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Divider(color: AppTheme.dividerColor, height: 16),
              AddCaptionAtTimeCard(
                currentTime: currentTime,
                maxDuration: maxDuration,
                onAdd: (start, end, text) {
                  ref.read(editorProvider.notifier).addCaptionAtPlayhead(
                    text: text,
                    atTime: start,
                    duration: end - start,
                  );
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFindReplaceDialog() {
    // FIX (audit): guard against stacking a second dialog via repeated Ctrl+F.
    if (_isFindDialogOpen) return;
    _isFindDialogOpen = true;
    ref.read(editorProvider.notifier).setIsPlaying(false);
    showDialog<void>(
      context: context,
      builder: (context) {
        return const FindReplaceDialog();
      },
    ).whenComplete(() {
      _isFindDialogOpen = false;
    });
  }

  void _handleAutoEnhance(String action, Project project) {
    final notifier = ref.read(editorProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    switch (action) {
      case 'magic_emojis':
        final count = notifier.autoApplyMagicEmojis();
        messenger.showSnackBar(
          SnackBar(
            content: Text(count > 0 ? '🪄 Added $count Magic Emojis to keywords!' : 'No new keyword matches found for emojis.'),
            backgroundColor: count > 0 ? AppTheme.accentGreen : AppTheme.cardBgElevated,
          ),
        );
        break;
      case 'magic_sfx':
        final count = notifier.autoApplyMagicSfx();
        messenger.showSnackBar(
          SnackBar(
            content: Text(count > 0 ? '🔊 Added $count Magic SFX across transitions!' : 'No new transition keywords found for SFX.'),
            backgroundColor: count > 0 ? AppTheme.accentGreen : AppTheme.cardBgElevated,
          ),
        );
        break;
      case 'remove_fillers':
        FillerWordsDialog.show(context, project);
        break;
      case 'b_roll_ideas':
        BRollSuggestionsDialog.show(
          context,
          project,
          onSeekToTime: (time) {
            notifier.setCurrentTime(time);
          },
          activeClips: ref.read(editorProvider).bRollClips,
          onAttachClip: notifier.addBRollClip,
          onRemoveClip: notifier.removeBRollClip,
          onUpdateClip: notifier.updateBRollClip,
        );
        break;
      case 'speaker_diarization':
        showSpeakerDiarizationDialog(context, ref);
        break;
      case 'youtube_chapters':
        ChapterGeneratorDialog.show(context, project);
        break;
      case 'clear_emojis':
        final count = notifier.clearAllEmojis();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Cleared $count emojis.'),
            backgroundColor: AppTheme.cardBgElevated,
          ),
        );
        break;
      case 'clear_sfx':
        final count = notifier.clearAllSfx();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Cleared $count sound effects.'),
            backgroundColor: AppTheme.cardBgElevated,
          ),
        );
        break;
    }
  }
}
