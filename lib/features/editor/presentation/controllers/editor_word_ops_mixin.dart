part of 'editor_controller.dart';

/// Word and chunk editing operations for [EditorController]: import, update,
/// batch edit, find & replace, split/duplicate/delete words and chunks.
mixin EditorWordOpsMixin on EditorHistoryMixin {
  // --- Timeline Actions (Word Operations) ---

  /// Import subtitles from an SRT/VTT file safely
  void importSubtitles(List<WordSchema> words) {
    final project = state.project;
    if (project == null) return;

    _recordChange();

    final updated = _cloneProject(project);
    updated.words = words.map((w) => _cloneWord(w)).toList();

    state = state.copyWith(
      project: updated,
      hasUnsavedChanges: true,
    );

    _autoSave();
  }

  /// Update a single word's timing, text, colors, sound, or hide parameters
  void updateWord(
    String wordId, {
    String? text,
    double? start,
    double? end,
    bool? hidden,
    String? emoji,
    String? className,
    String? soundEffect,
    int? soundVolume,
    double? emojiX,
    double? emojiY,
    double? emojiScale,
    double? emojiSpeed,
  }) {
    final project = state.project;
    if (project == null) return;

    LoggerService.instance.action('EditorController', 'Updating word "$wordId" - Text: $text, Start: $start, End: $end, Hidden: $hidden, Emoji: $emoji, SFX: $soundEffect');

    final updated = _cloneProject(project);
    final updatedWords = updated.words.map((w) {
      if (w.wordId == wordId) {
        final cloned = _cloneWord(w);
        if (text != null) cloned.text = text;
        if (start != null) cloned.start = start;
        if (end != null) cloned.end = end;
        if (hidden != null) cloned.hidden = hidden;
        if (emoji != null) {
          cloned.emoji = emoji == 'none' ? null : emoji;
          if (cloned.emoji == null) {
            cloned.emojiConfig = null;
          } else {
            cloned.emojiConfig ??= EmojiConfigSchema()
              ..x = 0.0
              ..y = 0.0
              ..scale = 1.0
              ..speed = 1.0;
          }
        }
        if (className != null) {
          cloned.className = className == 'none' ? null : className;
        }
        if (soundEffect != null) {
          cloned.soundEffect = soundEffect.isEmpty ? null : soundEffect;
          if (soundVolume == null) {
            cloned.soundVolume = (cloned.soundVolume ?? 100).clamp(0, 100);
          }
        }
        if (soundVolume != null && cloned.soundEffect != null) {
          cloned.soundVolume = soundVolume.clamp(0, 100);
        }

        // Update emoji positioning config if provided
        if (emojiX != null || emojiY != null || emojiScale != null || emojiSpeed != null) {
          final config = cloned.emojiConfig ??= (EmojiConfigSchema()
            ..x = 0.0
            ..y = 0.0
            ..scale = 1.0
            ..speed = 1.0);
          if (emojiX != null) config.x = emojiX;
          if (emojiY != null) config.y = emojiY;
          if (emojiScale != null) config.scale = emojiScale;
          if (emojiSpeed != null) config.speed = emojiSpeed;
        }
        return cloned;
      }
      return w;
    }).toList();

    updated.words = updatedWords;
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
    _recordChange();
    _autoSave();
  }

  /// Update a single word's emoji and configurations quietly without recording history step or saving immediately.
  /// Used for smooth, real-time live preview adjustments of emoji positions/scales.
  void updateWordEmojiQuietly(
    String wordId, {
    String? emoji,
    double? emojiX,
    double? emojiY,
    double? emojiScale,
    double? emojiSpeed,
  }) {
    final project = state.project;
    if (project == null) return;

    final updated = _cloneProject(project);
    final updatedWords = updated.words.map((w) {
      if (w.wordId == wordId) {
        final cloned = _cloneWord(w);
        if (emoji != null) {
          cloned.emoji = emoji == 'none' ? null : emoji;
          if (cloned.emoji == null) {
            cloned.emojiConfig = null;
          } else {
            cloned.emojiConfig ??= EmojiConfigSchema()
              ..x = 0.0
              ..y = 0.0
              ..scale = 1.0
              ..speed = 1.0;
          }
        }
        if (emojiX != null || emojiY != null || emojiScale != null || emojiSpeed != null) {
          final config = cloned.emojiConfig ??= (EmojiConfigSchema()
            ..x = 0.0
            ..y = 0.0
            ..scale = 1.0
            ..speed = 1.0);
          if (emojiX != null) config.x = emojiX;
          if (emojiY != null) config.y = emojiY;
          if (emojiScale != null) config.scale = emojiScale;
          if (emojiSpeed != null) config.speed = emojiSpeed;
        }
        return cloned;
      }
      return w;
    }).toList();

    updated.words = updatedWords;
    state = state.copyWith(
      project: updated,
      revision: state.revision + 1,
    );
  }

  /// Update a single word's timing without recording a history step or writing to the database instantly.
  /// Used for smooth, high-performance dragging operations on the timeline.
  void updateWordTimingsQuietly(
    String wordId, {
    double? start,
    double? end,
  }) {
    final project = state.project;
    if (project == null) return;

    final updated = Project()
      ..id = project.id
      ..projectId = project.projectId
      ..name = project.name
      ..videoPath = project.videoPath
      ..duration = project.duration
      ..width = project.width
      ..height = project.height
      ..createdAt = project.createdAt
      ..trimStart = project.trimStart
      ..trimEnd = project.trimEnd
      ..status = project.status
      ..thumbnailPath = project.thumbnailPath
      // Deep-clone config so a quiet drag cannot accidentally share config state
      // with the canonical project object, which could corrupt style on commit.
      ..config = _cloneConfig(project.config)
      ..segments = project.segments;

    final updatedWords = project.words.map((w) {
      if (w.wordId == wordId) {
        final clonedWord = _cloneWord(w);
        if (start != null) clonedWord.start = start;
        if (end != null) clonedWord.end = end;
        return clonedWord;
      }
      return w;
    }).toList();

    updated.words = updatedWords;
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
  }

  /// Update timing for many words in ONE project clone + single revision bump.
  /// Used by chunk timing edits — the old loop called
  /// [updateWordTimingsQuietly] per word, which cloned the whole project and
  /// mapped every word per call (O(chunkSize × wordCount) per save).
  void updateWordTimingsQuietlyBatch(
    List<({String wordId, double start, double end})> timings,
  ) {
    final project = state.project;
    if (project == null || timings.isEmpty) return;

    final byId = {for (final t in timings) t.wordId: t};

    final updated = Project()
      ..id = project.id
      ..projectId = project.projectId
      ..name = project.name
      ..videoPath = project.videoPath
      ..duration = project.duration
      ..width = project.width
      ..height = project.height
      ..createdAt = project.createdAt
      ..trimStart = project.trimStart
      ..trimEnd = project.trimEnd
      ..status = project.status
      ..thumbnailPath = project.thumbnailPath
      // Deep-clone config so a quiet edit cannot accidentally share config
      // state with the canonical project object.
      ..config = _cloneConfig(project.config)
      ..segments = project.segments;

    final updatedWords = project.words.map((w) {
      final t = byId[w.wordId];
      if (t != null) {
        final clonedWord = _cloneWord(w);
        clonedWord.start = t.start;
        clonedWord.end = t.end;
        return clonedWord;
      }
      return w;
    }).toList();

    updated.words = updatedWords;
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
  }

  /// Batch update properties (hidden status, style classes) for multiple words
  void batchUpdateWords(List<String> ids, {bool? hidden, String? className}) {
    final project = state.project;
    if (project == null) return;

    final idsSet = ids.toSet(); // O(1) lookup
    final updated = _cloneProject(project);
    final updatedWords = updated.words.map((w) {
      if (idsSet.contains(w.wordId)) {
        final cloned = _cloneWord(w);
        if (hidden != null) cloned.hidden = hidden;
        if (className != null) {
          cloned.className = className == 'none' ? null : className;
        }
        return cloned;
      }
      return w;
    }).toList();

    updated.words = updatedWords;
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
    _recordChange();
    _autoSave();
  }

  /// Find and replace text in all words in a single transaction. Returns count of replacements.
  int findAndReplaceText(String find, String replace) {
    final project = state.project;
    if (project == null || find.isEmpty) return 0;

    LoggerService.instance.action('EditorController', 'Find and Replace: "$find" -> "$replace"');

    int count = 0;
    final updated = _cloneProject(project);
    final updatedWords = updated.words.map((w) {
      final text = w.text;
      if (text != null && text.toLowerCase().contains(find.toLowerCase())) {
        final cloned = _cloneWord(w);
        final pattern = RegExp(RegExp.escape(find), caseSensitive: false);
        // FIX (audit): count OCCURRENCES, not words — the dialog reported
        // "N occurrences!" but count was incremented once per word.
        count += pattern.allMatches(text).length;
        cloned.text = text.replaceAll(pattern, replace);
        return cloned;
      }
      return w;
    }).toList();

    if (count > 0) {
      updated.words = updatedWords;
      state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
      _recordChange();
      _autoSave();
      LoggerService.instance.log(LogLevel.action, 'EditorController', 'Replaced "$find" with "$replace" ($count occurrences)');
    }
    return count;
  }

  /// Mark splitBefore = true to break subtitle chunk boundaries dynamically
  void splitChunkAtWord(String wordId) {
    final project = state.project;
    if (project == null) return;
    LoggerService.instance.action('EditorController', 'Splitting chunk boundary at word ID "$wordId".');

    final updated = _cloneProject(project);
    final updatedWords = updated.words.map((w) {
      if (w.wordId == wordId) {
        final cloned = _cloneWord(w);
        cloned.splitBefore = true;
        return cloned;
      }
      return w;
    }).toList();

    updated.words = updatedWords;
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
    _recordChange();
    _autoSave();
  }

  /// Delete a list of words from the project
  void deleteWords(List<String> ids) {
    final project = state.project;
    if (project == null) return;
    LoggerService.instance.action('EditorController', 'Deleting words from project: $ids');

    final idsSet = ids.toSet();
    final updated = _cloneProject(project);
    final updatedWords = updated.words.where((w) => !idsSet.contains(w.wordId)).toList();

    updated.words = updatedWords;
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
    _recordChange();
    _autoSave();
  }

  /// Duplicate a chunk, time-shifting duplicates to appear after original
  void duplicateChunk(List<String> ids) {
    final project = state.project;
    if (project == null || ids.isEmpty) return;
    LoggerService.instance.action('EditorController', 'Duplicating chunk with words: $ids');

    final updated = _cloneProject(project);
    final wordsMap = {for (var w in updated.words) w.wordId: w};
    final itemsToDuplicate = ids.map((id) => wordsMap[id]).whereType<WordSchema>().toList();
    if (itemsToDuplicate.isEmpty) return;

    // Find insertion index in original list
    final indices = ids.map((id) => updated.words.indexWhere((w) => w.wordId == id)).toList();
    final lastIdx = indices.reduce((a, b) => a > b ? a : b);
    if (lastIdx == -1) return;

    final lastWord = updated.words[lastIdx];
    final firstWord = itemsToDuplicate.first;
    final timeOffset = (lastWord.end ?? 0.0) - (firstWord.start ?? 0.0) + 0.1;

    final copies = itemsToDuplicate.map((w) {
      final copy = _cloneWord(w);
      copy.wordId = _uuid.v4();
      copy.start = (w.start ?? 0.0) + timeOffset;
      copy.end = (w.end ?? 0.0) + timeOffset;
      return copy;
    }).toList();

    final wordsList = List<WordSchema>.from(updated.words);
    wordsList.insertAll(lastIdx + 1, copies);

    updated.words = wordsList;
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
    _recordChange();
    _autoSave();
  }

  /// Insert a blank word after a specified word ID
  void addWordAfter(String afterWordId) {
    final project = state.project;
    if (project == null) return;
    LoggerService.instance.action('EditorController', 'Adding blank word after word ID "$afterWordId".');

    final updated = _cloneProject(project);
    final idx = updated.words.indexWhere((w) => w.wordId == afterWordId);
    if (idx == -1) return;

    final afterWord = updated.words[idx];
    final start = afterWord.end ?? 0.0;
    // Clamp the new word's end so it does not overlap the next word.
    final nextWordStart = (idx + 1 < updated.words.length)
        ? (updated.words[idx + 1].start ?? (start + 1.0))
        : null;
    final maxEnd = nextWordStart != null ? nextWordStart - 0.01 : start + 1.0;
    final end = math.min(start + 0.5, maxEnd);

    final newWord = WordSchema()
      ..wordId = _uuid.v4()
      ..text = ''
      ..start = start
      ..end = end
      ..type = 'word'
      ..confidence = 1.0;

    final wordsList = List<WordSchema>.from(updated.words);
    wordsList.insert(idx + 1, newWord);

    updated.words = wordsList;
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
    _recordChange();
    _autoSave();
  }

  /// Insert a word marked splitBefore after a word to start a new chunk
  void addChunkAfter(String afterWordId) {
    final project = state.project;
    if (project == null) return;
    LoggerService.instance.action('EditorController', 'Adding new split line chunk after word ID "$afterWordId".');

    final updated = _cloneProject(project);
    final idx = updated.words.indexWhere((w) => w.wordId == afterWordId);
    if (idx == -1) return;

    final afterWord = updated.words[idx];
    final start = afterWord.end ?? 0.0;
    // Clamp the new word's end so it does not overlap the next word.
    final nextWordStart = (idx + 1 < updated.words.length)
        ? (updated.words[idx + 1].start ?? (start + 1.0))
        : null;
    final maxEnd = nextWordStart != null ? nextWordStart - 0.01 : start + 1.0;
    final end = math.min(start + 0.5, maxEnd);

    final newWord = WordSchema()
      ..wordId = _uuid.v4()
      ..text = ''
      ..start = start
      ..end = end
      ..type = 'word'
      ..confidence = 1.0
      ..splitBefore = true;

    final wordsList = List<WordSchema>.from(updated.words);
    wordsList.insert(idx + 1, newWord);

    updated.words = wordsList;
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
    _recordChange();
    _autoSave();
  }

  /// Insert a new caption line at the current playhead timestamp (or specified time).
  /// Multi-word text is automatically tokenized with distributed word-level timings
  /// and splitBefore on the initial word, enabling instant karaoke highlight and ASS export.
  /// Works even when project words are completely empty, preventing empty-state deadlocks.
  void addCaptionAtPlayhead({String text = 'New Caption', double? atTime, double duration = 2.0}) {
    final project = state.project;
    if (project == null) return;

    final double maxDuration = project.duration > 0 ? project.duration : double.infinity;
    final double start = (atTime ?? state.currentTime).clamp(0.0, maxDuration);
    final double rawEnd = (start + duration).clamp(0.0, maxDuration);

    final rawWords = text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (rawWords.isEmpty) return;

    final double end = rawEnd > start ? rawEnd : start + (0.5 * rawWords.length);
    final double wordDuration = (end - start) / rawWords.length;

    final newWords = <WordSchema>[];
    for (int i = 0; i < rawWords.length; i++) {
      final wStart = start + (i * wordDuration);
      final wEnd = start + ((i + 1) * wordDuration);
      final word = WordSchema()
        ..wordId = _uuid.v4()
        ..text = rawWords[i]
        ..start = wStart
        ..end = wEnd
        ..type = 'word'
        ..confidence = 1.0
        ..splitBefore = (i == 0);
      newWords.add(word);
    }

    final updated = _cloneProject(project);
    final wordsList = List<WordSchema>.from(updated.words);

    // Insert sorted by start time
    final insertIdx = wordsList.indexWhere((w) => (w.start ?? 0.0) > start);
    if (insertIdx == -1) {
      wordsList.addAll(newWords);
    } else {
      wordsList.insertAll(insertIdx, newWords);
    }

    updated.words = wordsList;
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
    _recordChange();
    _autoSave();
    LoggerService.instance.action('EditorController', 'Added new caption line (${newWords.length} words) at ${start.toStringAsFixed(2)}s: "$text"');
  }

  /// Restores pre-bundled demo subtitles if this project is based on a demo asset
  Future<bool> restoreDemoSubtitles() async {
    final project = state.project;
    if (project == null) return false;

    final isPortrait = project.videoPath.contains('portrait') || project.name.toLowerCase().contains('portrait');
    final demoSrtPath = isPortrait
        ? 'assets/demo/portrait/demo_subtitles.srt'
        : 'assets/demo/landscape/demo_subtitles.srt';

    try {
      final srtContent = await rootBundle.loadString(demoSrtPath);
      final importedWords = SrtImporter.parseSrtString(srtContent);
      if (importedWords.isNotEmpty) {
        importSubtitles(importedWords);
        LoggerService.instance.action('EditorController', 'Restored ${importedWords.length} demo subtitles from $demoSrtPath');
        return true;
      }
    } catch (e) {
      LoggerService.instance.warning('EditorController', 'Could not restore demo subtitles: $e');
    }
    return false;
  }

  /// Auto-assigns contextual Magic Emojis across all captions based on keywords
  int autoApplyMagicEmojis({String? pack, int minWordSpacing = 4, bool overwrite = false}) {
    final project = state.project;
    if (project == null || project.words.isEmpty) return 0;

    final updated = _cloneProject(project);
    final effectivePack = pack ?? updated.config.emojiPack ?? 'notoColorEmoji';
    final count = AutoEnhancementService.instance.autoApplyEmojis(
      updated.words,
      pack: effectivePack,
      minWordSpacing: minWordSpacing,
      overwriteExisting: overwrite,
    );

    if (count > 0) {
      state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
      _recordChange();
      _autoSave();
      LoggerService.instance.action('EditorController', 'Auto-applied $count Magic Emojis using pack: $effectivePack');
    }
    return count;
  }

  /// Auto-assigns punchy Magic Sound Effects (SFX) across transitions and impact words
  int autoApplyMagicSfx({double minTimeGapSec = 3.0, bool overwrite = false}) {
    final project = state.project;
    if (project == null || project.words.isEmpty) return 0;

    final updated = _cloneProject(project);
    final count = AutoEnhancementService.instance.autoApplySfx(
      updated.words,
      minTimeGapSec: minTimeGapSec,
      overwriteExisting: overwrite,
    );

    if (count > 0) {
      state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
      _recordChange();
      _autoSave();
      LoggerService.instance.action('EditorController', 'Auto-applied $count Magic SFX');
    }
    return count;
  }

  /// Auto-detects and hides filler speech words ("um", "uh", "basically", etc.)
  int removeFillerWords() {
    final project = state.project;
    if (project == null || project.words.isEmpty) return 0;

    final updated = _cloneProject(project);
    final count = AutoEnhancementService.instance.removeFillerWords(updated.words);

    if (count > 0) {
      state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
      _recordChange();
      _autoSave();
      LoggerService.instance.action('EditorController', 'Removed $count filler words');
    }
    return count;
  }

  /// Restores all previously hidden filler words across the transcript
  int restoreFillerWords() {
    final project = state.project;
    if (project == null || project.words.isEmpty) return 0;

    final updated = _cloneProject(project);
    final count = AutoEnhancementService.instance.restoreFillerWords(updated.words);

    if (count > 0) {
      state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
      _recordChange();
      _autoSave();
      LoggerService.instance.action('EditorController', 'Restored $count filler words');
    }
    return count;
  }

  /// Counts the total number of detected filler words in the current project
  int countFillerWords() {
    final project = state.project;
    if (project == null || project.words.isEmpty) return 0;
    return AutoEnhancementService.instance.countFillerWords(project.words);
  }

  /// Clears all emojis from the project
  int clearAllEmojis() {
    final project = state.project;
    if (project == null || project.words.isEmpty) return 0;

    final updated = _cloneProject(project);
    final count = AutoEnhancementService.instance.clearAllEmojis(updated.words);

    if (count > 0) {
      state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
      _recordChange();
      _autoSave();
      LoggerService.instance.action('EditorController', 'Cleared $count emojis');
    }
    return count;
  }

  /// Clears all sound effects from the project
  int clearAllSfx() {
    final project = state.project;
    if (project == null || project.words.isEmpty) return 0;

    final updated = _cloneProject(project);
    final count = AutoEnhancementService.instance.clearAllSfx(updated.words);

    if (count > 0) {
      state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
      _recordChange();
      _autoSave();
      LoggerService.instance.action('EditorController', 'Cleared $count SFX');
    }
    return count;
  }

  /// Auto-detects multi-speaker turns across the transcript and attributes words to speakers.
  int autoDetectSpeakers({
    int speakerCount = 2,
    double pauseThresholdSeconds = 0.65,
    List<String>? speakerNames,
  }) {
    final project = state.project;
    if (project == null || project.words.isEmpty) return 0;

    final updated = _cloneProject(project);
    final tagged = SpeakerDiarizationService.instance.detectSpeakers(
      updated.words,
      speakerCount: speakerCount,
      pauseThresholdSeconds: pauseThresholdSeconds,
      speakerNames: speakerNames,
    );

    updated.words = tagged;
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
    _recordChange();
    _autoSave();
    LoggerService.instance.action('EditorController', 'Auto-detected speakers across transcript');
    return speakerCount;
  }

  /// Renames an existing speaker across the entire project transcript.
  void renameSpeaker(String oldSpeaker, String newSpeaker) {
    final project = state.project;
    if (project == null || project.words.isEmpty) return;

    final updated = _cloneProject(project);
    final renamed = SpeakerDiarizationService.instance.renameSpeaker(
      updated.words,
      oldSpeaker,
      newSpeaker,
    );

    updated.words = renamed;
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
    _recordChange();
    _autoSave();
    LoggerService.instance.action('EditorController', 'Renamed speaker "$oldSpeaker" to "$newSpeaker"');
  }

  /// Assigns a speaker to a chunk's words, optionally updating all matching chunks.
  void setChunkSpeaker(Chunk chunk, String newSpeaker, {bool applyToMatching = false}) {
    final project = state.project;
    if (project == null || project.words.isEmpty) return;

    if (applyToMatching && chunk.speaker != null && chunk.speaker!.isNotEmpty) {
      renameSpeaker(chunk.speaker!, newSpeaker);
      return;
    }

    final updated = _cloneProject(project);
    final wordIds = chunk.words.map((w) => w.wordId).whereType<String>().toSet();

    final reassigned = SpeakerDiarizationService.instance.assignSpeakerToWords(
      updated.words,
      wordIds,
      newSpeaker,
    );

    updated.words = reassigned;
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
    _recordChange();
    _autoSave();
    LoggerService.instance.action('EditorController', 'Assigned speaker "$newSpeaker" to Chunk ${chunk.index + 1}');
  }

  /// Returns analytical metrics per speaker for the current project.
  List<SpeakerStats> getSpeakerStats() {
    final project = state.project;
    if (project == null || project.words.isEmpty) return [];
    return SpeakerDiarizationService.instance.calculateStats(project.words);
  }

  /// Returns unique speaker labels present in the current project.
  List<String> getUniqueSpeakers() {
    final project = state.project;
    if (project == null || project.words.isEmpty) return [];
    return SpeakerDiarizationService.instance.getUniqueSpeakers(project.words);
  }

  /// Adds a B-roll video or image overlay clip to the project timeline.
  void addBRollClip(BRollClip clip) {
    final clips = List<BRollClip>.from(state.bRollClips)..add(clip);
    state = state.copyWith(bRollClips: clips, hasUnsavedChanges: true, revision: state.revision + 1);
    final projectId = state.project?.projectId;
    if (projectId != null && projectId.isNotEmpty) {
      BRollStorageService.instance.saveClips(projectId, clips);
    }
    LoggerService.instance.action('EditorController', 'Added B-roll clip: ${clip.name} [${clip.startTime.toStringAsFixed(1)}s - ${clip.endTime.toStringAsFixed(1)}s]');
  }

  /// Removes an attached B-roll clip by [clipId].
  void removeBRollClip(String clipId) {
    final clips = state.bRollClips.where((c) => c.id != clipId).toList();
    state = state.copyWith(bRollClips: clips, hasUnsavedChanges: true, revision: state.revision + 1);
    final projectId = state.project?.projectId;
    if (projectId != null && projectId.isNotEmpty) {
      BRollStorageService.instance.saveClips(projectId, clips);
    }
    LoggerService.instance.action('EditorController', 'Removed B-roll clip $clipId');
  }

  /// Updates an existing B-roll clip's settings (timing, PiP mode, volume).
  void updateBRollClip(BRollClip updatedClip) {
    final clips = state.bRollClips.map((c) => c.id == updatedClip.id ? updatedClip : c).toList();
    state = state.copyWith(bRollClips: clips, hasUnsavedChanges: true, revision: state.revision + 1);
    final projectId = state.project?.projectId;
    if (projectId != null && projectId.isNotEmpty) {
      BRollStorageService.instance.saveClips(projectId, clips);
    }
  }
}
