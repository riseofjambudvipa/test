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
    state = state.copyWith(project: updated, hasUnsavedChanges: true);
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
    state = state.copyWith(project: updated, hasUnsavedChanges: true);
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
        cloned.text = text.replaceAll(
          RegExp(RegExp.escape(find), caseSensitive: false),
          replace,
        );
        count++;
        return cloned;
      }
      return w;
    }).toList();

    if (count > 0) {
      updated.words = updatedWords;
      state = state.copyWith(project: updated, hasUnsavedChanges: true);
      _recordChange();
      _autoSave();
      LoggerService.instance.log(LogLevel.action, 'EditorController', 'Replaced "$find" with "$replace" in $count words');
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
    state = state.copyWith(project: updated, hasUnsavedChanges: true);
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
    state = state.copyWith(project: updated, hasUnsavedChanges: true);
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
    state = state.copyWith(project: updated, hasUnsavedChanges: true);
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
    final end = start + 0.5;

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
    state = state.copyWith(project: updated, hasUnsavedChanges: true);
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
    final end = start + 0.5;

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
    state = state.copyWith(project: updated, hasUnsavedChanges: true);
    _recordChange();
    _autoSave();
  }
}
