import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/assets/asset_path_service.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/database/isar_service.dart';
import '../../../../core/database/schemas/project.dart';
import '../../../../core/database/schemas/word.dart';
import '../../../../core/whisper/whisper_service.dart';
import '../../../../core/whisper/whisper_mobile_service.dart';
import '../../../../core/logger/logger_service.dart';
import '../../../../core/settings/settings_service.dart';
import '../../../../core/utils/mock_transcription.dart';
import '../../../../core/utils/schema_clones.dart';
import 'editor_state.dart';

/// Maps Whisper-detected language codes to the correct font family.
/// Covers ALL 99+ Whisper-supported languages across 25+ scripts.
/// Latin/Cyrillic/Greek languages use the default template font (Montserrat).
String suggestFontForLanguage(String whisperLang) {
  final lang = whisperLang.trim().toLowerCase();
  if (lang.startsWith('zh-tw') || lang.startsWith('zh-hk') || lang.startsWith('zh-hant')) {
    return 'Noto Sans TC';
  }
  if (lang.startsWith('zh') || lang.startsWith('yue')) {
    return 'Noto Sans SC';
  }
  if (lang.startsWith('ja')) {
    return 'Noto Sans JP';
  }
  if (lang.startsWith('ko')) {
    return 'Noto Sans KR';
  }

  final primary = lang.split('-').first;
  return switch (primary) {
    // Devanagari script
    'hi' || 'mr' || 'ne' || 'sa'       => 'Noto Sans Devanagari',
    // Arabic script
    'ar' || 'fa' || 'ps'               => 'Noto Sans Arabic',
    // Urdu (Nastaliq style)
    'ur'                                => 'Noto Nastaliq Urdu',
    // Thai
    'th'                                => 'Noto Sans Thai',
    // Hebrew / Yiddish
    'he' || 'yi'                        => 'Noto Sans Hebrew',
    // Tamil
    'ta'                                => 'Noto Sans Tamil',
    // Telugu
    'te'                                => 'Noto Sans Telugu',
    // Bengali
    'bn'                                => 'Noto Sans Bengali',
    // Gujarati
    'gu'                                => 'Noto Sans Gujarati',
    // Kannada
    'kn'                                => 'Noto Sans Kannada',
    // Malayalam
    'ml'                                => 'Noto Sans Malayalam',
    // Gurmukhi (Punjabi)
    'pa'                                => 'Noto Sans Gurmukhi',
    // Odia
    'or'                                => 'Noto Sans Oriya',
    // Sinhala
    'si'                                => 'Noto Sans Sinhala',
    // Myanmar (Burmese)
    'my'                                => 'Noto Sans Myanmar',
    // Khmer (Cambodian)
    'km'                                => 'Noto Sans Khmer',
    // Lao
    'lo'                                => 'Noto Sans Lao',
    // Georgian
    'ka'                                => 'Noto Sans Georgian',
    // Armenian
    'hy'                                => 'Noto Sans Armenian',
    // Ethiopic (Amharic)
    'am'                                => 'Noto Sans Ethiopic',
    _                                   => 'Montserrat',
  };
}

/// Returns true if the language needs a CJK downloadable font pack.
bool isCjkLanguage(String whisperLang) {
  final lang = whisperLang.trim().toLowerCase();
  final primary = lang.split('-').first;
  return ['zh', 'yue', 'ja', 'ko'].contains(primary);
}


class HistoryEntry {
  final List<WordSchema> words;
  final ProjectConfigSchema config;
  final double trimStart;
  final double trimEnd;
  final List<VideoSegmentSchema> segments;

  const HistoryEntry({
    required this.words,
    required this.config,
    required this.trimStart,
    required this.trimEnd,
    required this.segments,
  });
}

class EditorController extends StateNotifier<EditorState> {
  final Ref ref;
  final IsarService _dbService = IsarService.instance;
  final _uuid = const Uuid();

  // Undo/Redo Stacks
  final List<HistoryEntry> _history = [];
  int _historyIndex = -1;
  static const int _maxHistory = 50;

  // Debounce timer for auto-save to prevent 60 writes/sec during slider drags
  Timer? _autoSaveTimer;

  bool _isDisposed = false;

  EditorController(this.ref) : super(const EditorState());

  /// Initialize the controller with a loaded project and reset the history stack
  void setProject(Project project) {
    LoggerService.instance.info('EditorController', 'Project "${project.name}" loaded into editor session. ID: ${project.projectId}. Words: ${project.words.length}');
    _history.clear();
    
    final clonedProject = _cloneProject(project);
    
    // Asynchronously verify video dimensions to repair legacy/incorrect dimensions (e.g. hardcoded 1920x1080 vertical videos)
    _verifyAndUpdateDimensions(clonedProject);

    // Initialize segments if missing (for legacy projects or newly created projects)
    if (clonedProject.segments == null || clonedProject.segments!.isEmpty) {
      final start = clonedProject.trimStart;
      final end = (clonedProject.trimEnd <= 0.0) ? clonedProject.duration : clonedProject.trimEnd;
      clonedProject.segments = [
        VideoSegmentSchema()
          ..start = start
          ..end = end > 0.2 ? end : 1.0
          ..isDeleted = false,
      ];
    }
    
    // Capture current references dynamically inside structural sharing memento
    final initialEntry = HistoryEntry(
      words: List<WordSchema>.from(clonedProject.words), // Structural sharing (shallow copy)
      config: _cloneConfig(clonedProject.config),
      trimStart: clonedProject.trimStart,
      trimEnd: clonedProject.trimEnd,
      segments: _cloneSegments(clonedProject.segments),
    );
    _history.add(initialEntry);
    _historyIndex = 0;

    state = EditorState(
      project: clonedProject,
      currentTime: 0.0,
      isPlaying: false,
      activeTab: EditorTab.caption,
      hasUnsavedChanges: false,
      revision: 1,
    );
  }

  // --- History Management (Undo / Redo) ---

  void _recordChange() {
    final project = state.project;
    if (project == null) return;

    // Remove any redo history beyond the current index
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    // Shallow copy the words list (structural sharing)
    // Individual words are treated as immutable and only cloned when modified
    final entry = HistoryEntry(
      words: List<WordSchema>.from(project.words),
      config: _cloneConfig(project.config),
      trimStart: project.trimStart,
      trimEnd: project.trimEnd,
      segments: _cloneSegments(project.segments),
    );

    _history.add(entry);
    if (_history.length > _maxHistory) {
      _history.removeAt(0);
    }
    _historyIndex = _history.length - 1;

    state = state.copyWith(
      revision: state.revision + 1,
      canUndo: _historyIndex > 0,
      canRedo: _historyIndex < _history.length - 1,
    );
  }

  void undo() {
    final project = state.project;
    if (project == null || _historyIndex <= 0) return;

    _historyIndex--;
    final prevEntry = _history[_historyIndex];
    LoggerService.instance.action('EditorController', 'Executed Undo operation. Moving to index $_historyIndex / ${_history.length - 1}.');

    // Clone the project to trigger reference-equality updates in Riverpod listeners
    final restored = _cloneProject(project);
    restored.words = List<WordSchema>.from(prevEntry.words);
    restored.config = _cloneConfig(prevEntry.config);
    restored.trimStart = prevEntry.trimStart;
    restored.trimEnd = prevEntry.trimEnd;
    restored.segments = _cloneSegments(prevEntry.segments);

    state = state.copyWith(
      project: restored,
      hasUnsavedChanges: true,
      revision: state.revision + 1,
      canUndo: _historyIndex > 0,
      canRedo: _historyIndex < _history.length - 1,
    );
    
    _autoSave();
  }

  void redo() {
    final project = state.project;
    if (project == null || _historyIndex >= _history.length - 1) return;

    _historyIndex++;
    final nextEntry = _history[_historyIndex];
    LoggerService.instance.action('EditorController', 'Executed Redo operation. Moving to index $_historyIndex / ${_history.length - 1}.');

    // Clone the project to trigger reference-equality updates in Riverpod listeners
    final restored = _cloneProject(project);
    restored.words = List<WordSchema>.from(nextEntry.words);
    restored.config = _cloneConfig(nextEntry.config);
    restored.trimStart = nextEntry.trimStart;
    restored.trimEnd = nextEntry.trimEnd;
    restored.segments = _cloneSegments(nextEntry.segments);

    state = state.copyWith(
      project: restored,
      hasUnsavedChanges: true,
      revision: state.revision + 1,
      canUndo: _historyIndex > 0,
      canRedo: _historyIndex < _history.length - 1,
    );
    
    _autoSave();
  }

  // --- Playback Settings ---

  void setCurrentTime(double time) {
    state = state.copyWith(currentTime: time);
  }

  void setIsPlaying(bool playing) {
    state = state.copyWith(isPlaying: playing);
  }

  void setActiveTab(EditorTab tab) {
    if (tab == EditorTab.shortcuts) {
      if (state.activeTab != EditorTab.shortcuts) {
        state = state.copyWith(previousTab: state.activeTab, activeTab: tab);
      }
    } else {
      state = state.copyWith(activeTab: tab);
    }
  }

  void closeShortcuts() {
    if (state.activeTab == EditorTab.shortcuts) {
      state = state.copyWith(activeTab: state.previousTab);
    }
  }

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

  /// Commits a history step and triggers database write.
  /// Used after quiet operations (e.g. at the end of a drag).
  void commitHistoryAndSave() {
    final project = state.project;
    if (project == null) return;
    _recordChange();
    _autoSave();
    LoggerService.instance.action('EditorController', 'Committed quiet timeline changes to history and triggered auto-save.');
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

  /// Update trim boundaries through proper state management
  void setTrim(double start, double end) {
    final project = state.project;
    if (project == null) return;
    if (start >= end) {
      LoggerService.instance.warning('EditorController', 'setTrim ignored: start ($start) must be strictly less than end ($end).');
      return;
    }
    LoggerService.instance.action('EditorController', 'Setting project active trim window from ${start.toStringAsFixed(2)}s to ${end.toStringAsFixed(2)}s.');

    final updated = _cloneProject(project);
    updated.trimStart = start;
    updated.trimEnd = end;

    // Align segments with outer boundaries:
    if (updated.segments != null && updated.segments!.isNotEmpty) {
      final segments = <VideoSegmentSchema>[];
      for (final s in updated.segments!) {
        final clampedStart = (s.start ?? 0.0).clamp(start, end);
        final clampedEnd = (s.end ?? 0.0).clamp(start, end);
        if (clampedStart < clampedEnd) {
          segments.add(VideoSegmentSchema()
            ..start = clampedStart
            ..end = clampedEnd
            ..isDeleted = s.isDeleted);
        }
      }
      
      if (segments.isEmpty) {
        segments.add(VideoSegmentSchema()
          ..start = start
          ..end = end
          ..isDeleted = false);
      } else {
        // Guarantee first starts at start, last ends at end
        final first = segments.first;
        segments[0] = VideoSegmentSchema()
          ..start = start
          ..end = first.end
          ..isDeleted = first.isDeleted;

        final lastIdx = segments.length - 1;
        final last = segments[lastIdx];
        segments[lastIdx] = VideoSegmentSchema()
          ..start = last.start
          ..end = end
          ..isDeleted = last.isDeleted;
      }
      updated.segments = segments;
    }

    state = state.copyWith(project: updated, hasUnsavedChanges: true);
    _recordChange();
    _autoSave();
  }

  void splitSegmentAtTime(double time) {
    final project = state.project;
    if (project == null || project.segments == null) return;
    
    LoggerService.instance.action('EditorController', 'Splitting segment at ${time.toStringAsFixed(2)}s');

    final updated = _cloneProject(project);
    final segments = List<VideoSegmentSchema>.from(updated.segments!);
    int indexToSplit = -1;
    for (int i = 0; i < segments.length; i++) {
      final s = segments[i].start ?? 0.0;
      final e = segments[i].end ?? 0.0;
      if (time > s && time < e) {
        indexToSplit = i;
        break;
      }
    }

    if (indexToSplit != -1) {
      final originalSeg = segments[indexToSplit];
      final isDel = originalSeg.isDeleted ?? false;
      
      final firstPart = VideoSegmentSchema()
        ..start = originalSeg.start
        ..end = time
        ..isDeleted = isDel;
        
      final secondPart = VideoSegmentSchema()
        ..start = time
        ..end = originalSeg.end
        ..isDeleted = isDel;

      segments.removeAt(indexToSplit);
      segments.insert(indexToSplit, firstPart);
      segments.insert(indexToSplit + 1, secondPart);
      
      updated.segments = segments;
      state = state.copyWith(project: updated, hasUnsavedChanges: true);
      _recordChange();
      _autoSave();
    }
  }

  void toggleSegmentDeleted(double time) {
    final project = state.project;
    if (project == null || project.segments == null) return;
    
    LoggerService.instance.action('EditorController', 'Toggling deletion status of segment at ${time.toStringAsFixed(2)}s');

    final updated = _cloneProject(project);
    final segments = List<VideoSegmentSchema>.from(updated.segments!);
    int indexToToggle = -1;
    for (int i = 0; i < segments.length; i++) {
      final s = segments[i].start ?? 0.0;
      final e = segments[i].end ?? 0.0;
      if (time >= s && time <= e) {
        indexToToggle = i;
        break;
      }
    }

    if (indexToToggle != -1) {
      final seg = segments[indexToToggle];
      final currentDeleted = seg.isDeleted ?? false;
      final newSeg = VideoSegmentSchema()
        ..start = seg.start
        ..end = seg.end
        ..isDeleted = !currentDeleted;

      segments[indexToToggle] = newSeg;
      updated.segments = segments;
      state = state.copyWith(project: updated, hasUnsavedChanges: true);
      _recordChange();
      _autoSave();
    }
  }

  void resetSegments() {
    final project = state.project;
    if (project == null) return;
    
    LoggerService.instance.action('EditorController', 'Resetting all segments to original duration');

    final updated = _cloneProject(project);
    updated.segments = [
      VideoSegmentSchema()
        ..start = 0.0
        ..end = updated.duration
        ..isDeleted = false,
    ];
    
    updated.trimStart = 0.0;
    updated.trimEnd = updated.duration;
    
    state = state.copyWith(project: updated, hasUnsavedChanges: true);
    _recordChange();
    _autoSave();
  }

  /// Replace entire config at once (used for template/theme changes)
  void setFullConfig(ProjectConfigSchema newConfig) {
    final project = state.project;
    if (project == null) return;
    LoggerService.instance.action('EditorController', 'Applying style config template layout: "${newConfig.name}".');

    final updated = _cloneProject(project);
    updated.config = _cloneConfig(newConfig);
    state = state.copyWith(project: updated, hasUnsavedChanges: true);
    _recordChange();
    _autoSave();
  }

  // --- Style Configuration Actions ---

  /// Update a single style properties like fontSize, fontFamily, Y position, stroke, animation, and chunkSize
  void updateStyleProp(String key, dynamic value) {
    final project = state.project;
    if (project == null) return;
    LoggerService.instance.action('EditorController', 'Updating style property "$key" to "$value".');

    final updated = _cloneProject(project);
    final config = updated.config;
    final style = config.style;

    switch (key) {
      case 'emojiPack':
        if (value is String?) {
          config.emojiPack = value;
        } else {
          LoggerService.instance.warning('EditorController', 'Invalid type for emojiPack: ${value.runtimeType}');
        }
        break;
      case 'stroke':
        if (value is String) {
          config.stroke = value;
        } else {
          LoggerService.instance.warning('EditorController', 'Invalid type for stroke: ${value.runtimeType}');
        }
        break;
      case 'animation':
        if (value is String) {
          config.animation = value;
        } else {
          LoggerService.instance.warning('EditorController', 'Invalid type for animation: ${value.runtimeType}');
        }
        break;
      case 'shadow':
        if (value is String) {
          config.shadow = value;
        } else {
          LoggerService.instance.warning('EditorController', 'Invalid type for shadow: ${value.runtimeType}');
        }
        break;
      case 'background':
        if (value is String?) {
          config.background = value;
        } else {
          LoggerService.instance.warning('EditorController', 'Invalid type for background: ${value.runtimeType}');
        }
        break;
      case 'chunkSize':
        if (value is int) {
          config.subs.chunkSize = value;
        } else {
          LoggerService.instance.warning('EditorController', 'Invalid type for chunkSize: ${value.runtimeType}');
        }
        break;
      case 'chunkLineMaxLength':
        if (value is int) {
          config.subs.chunkLineMaxLength = value;
        } else {
          LoggerService.instance.warning('EditorController', 'Invalid type for chunkLineMaxLength: ${value.runtimeType}');
        }
        break;
      default:
        final newStyle = StyleConfigSchema()
          ..fontFamily = style.fontFamily
          ..fontWeight = style.fontWeight
          ..textTransform = style.textTransform
          ..color = style.color
          ..fontSize = style.fontSize
          ..top = style.top
          ..highlightBackground = style.highlightBackground
          ..letterSpacing = style.letterSpacing
          ..lineHeight = style.lineHeight;

        switch (key) {
          case 'fontFamily':
            if (value is String) {
              newStyle.fontFamily = value;
            } else {
              LoggerService.instance.warning('EditorController', 'Invalid type for fontFamily: ${value.runtimeType}');
            }
            break;
          case 'fontWeight':
            if (value is String) {
              newStyle.fontWeight = value;
            } else if (value != null) {
              newStyle.fontWeight = value.toString();
            } else {
              LoggerService.instance.warning('EditorController', 'Invalid type for fontWeight: null');
            }
            break;
          case 'textTransform':
            if (value is String) {
              newStyle.textTransform = value;
            } else {
              LoggerService.instance.warning('EditorController', 'Invalid type for textTransform: ${value.runtimeType}');
            }
            break;
          case 'color':
            if (value is String) {
              newStyle.color = value;
            } else {
              LoggerService.instance.warning('EditorController', 'Invalid type for color: ${value.runtimeType}');
            }
            break;
          case 'fontSize':
            if (value is num) {
              newStyle.fontSize = value.toDouble();
            } else {
              LoggerService.instance.warning('EditorController', 'Invalid type for fontSize: ${value.runtimeType}');
            }
            break;
          case 'top':
            if (value is num) {
              newStyle.top = value.toDouble();
            } else {
              LoggerService.instance.warning('EditorController', 'Invalid type for top: ${value.runtimeType}');
            }
            break;
          case 'highlightBackground':
            if (value is bool?) {
              newStyle.highlightBackground = value;
            } else {
              LoggerService.instance.warning('EditorController', 'Invalid type for highlightBackground: ${value.runtimeType}');
            }
            break;
          case 'letterSpacing':
            if (value is num?) {
              newStyle.letterSpacing = value?.toDouble();
            } else {
              LoggerService.instance.warning('EditorController', 'Invalid type for letterSpacing: ${value.runtimeType}');
            }
            break;
          case 'lineHeight':
            if (value is num?) {
              newStyle.lineHeight = value?.toDouble();
            } else {
              LoggerService.instance.warning('EditorController', 'Invalid type for lineHeight: ${value.runtimeType}');
            }
            break;
        }
        config.style = newStyle;
    }

    updated.config = config;

    state = state.copyWith(project: updated, hasUnsavedChanges: true);
    _recordChange();
    _autoSave();
  }

  /// Update custom highlight text colors
  void updateHighlightStyle({String? mainColor, String? secondColor, String? thirdColor}) {
    final project = state.project;
    if (project == null) return;
    LoggerService.instance.action('EditorController', 'Updating text highlight colors (Main: $mainColor, Sec: $secondColor, Tri: $thirdColor).');

    final updated = _cloneProject(project);
    final config = updated.config;
    final hs = config.highlightStyle;

    final newHs = HighlightStyleSchema()
      ..mainColor = mainColor ?? hs.mainColor
      ..secondColor = secondColor ?? hs.secondColor
      ..thirdColor = thirdColor ?? hs.thirdColor;

    config.highlightStyle = newHs;
    updated.config = config;

    state = state.copyWith(project: updated, hasUnsavedChanges: true);
    _recordChange();
    _autoSave();
  }

  // --- Project Management ---

  /// Mark project status completed
  void markCompleted() {
    final project = state.project;
    if (project == null) return;

    final updated = _cloneProject(project);
    updated.status = 'completed';
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
    _autoSave();
  }

  /// Persist local changes to Isar database
  Future<void> saveProject() async {
    final project = state.project;
    if (project != null && _dbService.isInitialized) {
      LoggerService.instance.info('EditorController', 'Saving project "${project.name}" dynamically to database.');
      await _dbService.saveProject(project);
      if (_isDisposed) return;
      if (state.project?.projectId == project.projectId) {
        state = state.copyWith(hasUnsavedChanges: false);
      }
      LoggerService.instance.info('EditorController', 'Project "${project.name}" saved successfully.');
    }
  }

  /// Re-run speech-to-text transcription on the video
  Future<bool> retranscribe({
    required bool useMock,
    String? language,
    String? whisperCliPath,
    String? whisperModelPath,
    String? ffmpegCliPath,
    bool? useVad,
    double? vadThreshold,
    bool? translate,
    required void Function(double progress, String status) onProgress,
  }) async {
    final project = state.project;
    if (project == null) return false;

    LoggerService.instance.log(LogLevel.action, 'EditorController', 'Re-transcribe requested for project: ${project.projectId}, useMock: $useMock, VAD: $useVad ($vadThreshold), translate: $translate');

    try {
      List<WordSchema> newWords = [];
      String? detectedLanguage;

      if (useMock) {
        onProgress(0.5, 'Generating demo captions...');
        await Future<void>.delayed(const Duration(milliseconds: 600));
        if (_isDisposed) return false;
        newWords = generateMockWords(project.duration);
      } else {
        final whisperService = WhisperService.instance;
        if (whisperCliPath != null) whisperService.configureCli(whisperCliPath);
        if (ffmpegCliPath != null) whisperService.configureFfmpeg(ffmpegCliPath);

        final String wavPath;
        if (kIsWeb) {
          wavPath = project.videoPath;
        } else {
          onProgress(0.2, 'Extracting audio track...');
          final tempDir = AssetPathService.instance.tempDir;
          wavPath = await whisperService.extractAudio(project.videoPath, tempDir);
        }
        if (_isDisposed) return false;

        onProgress(0.5, 'Running speech-to-text...');
        final result = await whisperService.transcribe(
          wavPath: wavPath,
          modelPath: whisperModelPath,
          language: language,
          useVad: useVad,
          vadThreshold: vadThreshold,
          expectedDuration: project.duration,
          translate: translate,
          onWebProgress: onProgress,
        );
        if (_isDisposed) return false;
        newWords = result.words;
        detectedLanguage = result.language;

        try {
          await File(wavPath).delete();
        } catch (_) {}
      }

      final updated = _cloneProject(project);
      // Overwrite project words
      updated.words = newWords;

      // Auto-apply language-appropriate font after transcription
      if (detectedLanguage != null) {
        _autoApplyLanguageFont(detectedLanguage, updated);
      }
      
      if (_isDisposed) return false;
      if (state.project?.projectId != project.projectId) {
        LoggerService.instance.warning('EditorController', 'Re-transcription completed, but project ID changed. Ignoring state update.');
        return false;
      }

      // Update state and record history entry
      state = state.copyWith(project: updated, hasUnsavedChanges: true);
      _recordChange();
      await saveProject();
      if (_isDisposed) return false;
      
      LoggerService.instance.log(LogLevel.info, 'EditorController', 'Re-transcription complete. Successfully loaded ${newWords.length} words.');

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        unawaited(Future.delayed(const Duration(seconds: 5), () {
          if (_isDisposed) return;
          WhisperMobileService.instance.freeModel();
        }));
      }

      return true;
    } catch (e) {
      LoggerService.instance.log(LogLevel.error, 'EditorController', 'Re-transcription failed: $e');
      return false;
    }
  }

  /// Auto-apply the correct font for the detected language.
  /// For languages with a dedicated preset (e.g., Hindi), apply the full preset.
  /// For other non-Latin languages, just update the font family.
  void _autoApplyLanguageFont(String detectedLang, Project project) {
    final suggestedFont = suggestFontForLanguage(detectedLang);
    
    // Default font means Latin/Cyrillic/Greek — no change needed
    if (suggestedFont == 'Montserrat') return;

    // Just update the font family to the correct script
    final config = project.config;
    final style = config.style;
    final newStyle = StyleConfigSchema()
      ..fontFamily = suggestedFont
      ..fontWeight = style.fontWeight
      ..textTransform = style.textTransform
      ..color = style.color
      ..fontSize = style.fontSize
      ..top = style.top
      ..highlightBackground = style.highlightBackground
      ..letterSpacing = style.letterSpacing
      ..lineHeight = style.lineHeight;
    config.style = newStyle;
    project.config = config;
    LoggerService.instance.log(LogLevel.info, 'EditorController',
      'Language "$detectedLang" detected — auto-set font to "$suggestedFont".');

  }



  void updateCaptionTop(double top) {
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
      ..words = project.words
      ..segments = project.segments;
      
    final oldConfig = project.config;
    final style = oldConfig.style;
    
    final newStyle = StyleConfigSchema()
      ..fontFamily = style.fontFamily
      ..fontWeight = style.fontWeight
      ..textTransform = style.textTransform
      ..color = style.color
      ..fontSize = style.fontSize
      ..top = top.clamp(5.0, 95.0)
      ..highlightBackground = style.highlightBackground
      ..letterSpacing = style.letterSpacing
      ..lineHeight = style.lineHeight;
      
    final newConfig = ProjectConfigSchema()
      ..name = oldConfig.name
      ..style = newStyle
      ..highlightStyle = oldConfig.highlightStyle
      ..subs = oldConfig.subs
      ..animation = oldConfig.animation
      ..shadow = oldConfig.shadow
      ..stroke = oldConfig.stroke
      ..background = oldConfig.background
      ..emojiPack = oldConfig.emojiPack;
      
    updated.config = newConfig;
    
    state = state.copyWith(project: updated, hasUnsavedChanges: true, revision: state.revision + 1);
    _autoSave();
  }

  void _autoSave() {
    _autoSaveTimer?.cancel();
    if (!SettingsService.instance.autoSaveEnabled) return;
    _autoSaveTimer = Timer(const Duration(seconds: 3), () async {
      final project = state.project;
      if (project != null && _dbService.isInitialized) {
        if (state.project?.projectId != project.projectId) return;
        LoggerService.instance.info('EditorController', 'Debounced auto-saving project "${project.name}"...');
        await _dbService.saveProject(project);
        if (_isDisposed) return;
        if (state.project?.projectId == project.projectId) {
          state = state.copyWith(hasUnsavedChanges: false);
        }
      }
    });
  }

  void resetCjkPrompt() {
    if (_isDisposed) return;
    state = state.copyWith(showCjkFontPrompt: false);
  }

  /// Increments the findReplaceCounter so WordPanel knows to open the Find & Replace dialog.
  /// Called by the Ctrl+F keyboard shortcut in EditorScreen.
  void triggerFindReplace() {
    if (_isDisposed) return;
    state = state.copyWith(findReplaceCounter: state.findReplaceCounter + 1);
    LoggerService.instance.action('EditorController', 'Find & Replace triggered via keyboard shortcut (counter: ${state.findReplaceCounter}).');
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoSaveTimer?.cancel();
    final project = state.project;
    // Fire-and-forget final save: only attempt if Isar is still open.
    // The IsarService.close() call in _cleanTeardownAndExit() runs concurrently
    // with Flutter's disposal, so we must check isInitialized to avoid
    // writing to an already-closed database instance.
    if (state.hasUnsavedChanges && project != null && _dbService.isInitialized) {
      LoggerService.instance.info('EditorController', 'Final save on dispose for project "${project.name}"...');
      unawaited(_dbService.saveProject(project));
    }
    WhisperService.instance.cancelActiveTranscription();
    super.dispose();
  }

  // --- Deep Cloning Helpers ---

  // FIX (Issue #1, CapStudio 1.0 audit): these 4 methods previously each
  // hand-duplicated the same field-by-field object cloning that also
  // existed independently in isar_service.dart and caption_engine.dart.
  // Bodies now delegate to core/utils/schema_clones.dart's single shared
  // implementation. Signatures are UNCHANGED on purpose — this method is
  // called from 30+ places in this file, so keeping the same name/shape
  // means none of those call sites need to change.
  //
  // _cloneProject's shallow-copy-of-words ("structural sharing") is
  // intentionally NOT delegated to SchemaClones.cloneProjectDeep (which
  // deep-clones every word) — this shallow behavior was specifically
  // verified safe during the audit (every word-mutating method in this
  // class clones-then-replaces rather than mutating a shared WordSchema in
  // place), and deep-cloning every word on every history entry would be
  // needlessly slow on a hot path (every edit).
  Project _cloneProject(Project p) {
    final clone = Project()
      ..id = p.id
      ..projectId = p.projectId
      ..name = p.name
      ..videoPath = p.videoPath
      ..duration = p.duration
      ..width = p.width
      ..height = p.height
      ..createdAt = p.createdAt
      ..trimStart = p.trimStart
      ..trimEnd = p.trimEnd
      ..status = p.status
      ..thumbnailPath = p.thumbnailPath
      ..config = _cloneConfig(p.config)
      ..words = List<WordSchema>.from(p.words) // Shallow copy for structural sharing — see class doc comment above
      ..segments = _cloneSegments(p.segments);
    return clone;
  }

  WordSchema _cloneWord(WordSchema w) => SchemaClones.cloneWord(w);

  ProjectConfigSchema _cloneConfig(ProjectConfigSchema c) => SchemaClones.cloneConfig(c);

  List<VideoSegmentSchema> _cloneSegments(List<VideoSegmentSchema>? source) {
    if (source == null) return [];
    return source.map(SchemaClones.cloneSegment).toList();
  }

  Future<void> _verifyAndUpdateDimensions(Project project) async {
    if (kIsWeb || Platform.isAndroid || Platform.isIOS || Platform.environment.containsKey('FLUTTER_TEST')) {
      return; // Skip ffprobe verification on mobile, web, and tests — dimensions from DB are sufficient
    }

    try {
      final localFfprobe = p.join(
        p.dirname(SettingsService.instance.ffmpegCliPath ?? ''),
        Platform.isWindows ? 'ffprobe.exe' : 'ffprobe',
      );
      final ffprobePath = File(localFfprobe).existsSync() ? localFfprobe : 'ffprobe';

      final process = await Process.run(
        ffprobePath,
        [
          '-v', 'error',
          '-select_streams', 'v:0',
          '-show_entries', 'stream=width,height:stream_side_data=rotation:stream_tags=rotate',
          '-of', 'json',
          project.videoPath
        ],
      );
      if (_isDisposed) return;
      if (process.exitCode == 0) {
        final Map<String, dynamic> data = jsonDecode(process.stdout.toString()) as Map<String, dynamic>;
        final streams = data['streams'] as List<dynamic>?;

        int w = 1920;
        int h = 1080;
        int rotation = 0;

        if (streams != null && streams.isNotEmpty) {
          final stream = streams.first;
          w = stream['width'] as int? ?? 1920;
          h = stream['height'] as int? ?? 1080;

          final sideDataList = stream['side_data_list'] as List<dynamic>?;
          if (sideDataList != null) {
            for (final sideData in sideDataList) {
              if (sideData['side_data_type'] == 'Display Matrix' && sideData['rotation'] != null) {
                rotation = (sideData['rotation'] as num).toInt();
                break;
              }
            }
          }

          final tags = stream['tags'] as Map<String, dynamic>?;
          if (tags != null && tags['rotate'] != null) {
            rotation = int.tryParse(tags['rotate'].toString()) ?? rotation;
          }
        }

        if (rotation == 90 || rotation == -90 || rotation == 270 || rotation == -270) {
          final temp = w;
          w = h;
          h = temp;
        }

        if (project.width != w || project.height != h) {
          LoggerService.instance.log(LogLevel.warning, 'EditorController', 
            'Project dimensions mismatch detected for ${project.name}. DB: ${project.width}x${project.height}, Real: ${w}x$h. Repairing database record...');
          
          final currentProject = state.project;
          if (currentProject != null && currentProject.projectId == project.projectId) {
            final updated = _cloneProject(currentProject);
            updated.width = w;
            updated.height = h;
            if (_dbService.isInitialized) {
              await _dbService.saveProject(updated);
              if (_isDisposed) return;
            }
            if (state.project?.projectId == project.projectId) {
              state = state.copyWith(project: updated, revision: state.revision + 1);
            }
          }
        }
      }
    } catch (e) {
      if (e is ProcessException) {
        LoggerService.instance.log(LogLevel.warning, 'EditorController', 
            'ffprobe executable was not found in standard PATH or configured directories. '
            'Please install FFmpeg or configure its path in Settings to enable automatic video dimension verification. Detail: $e');
      } else {
        LoggerService.instance.log(LogLevel.error, 'EditorController', 'Failed to verify project dimensions: $e');
      }
    }
  }
}

// Riverpod provider definition
final editorProvider = StateNotifierProvider<EditorController, EditorState>((ref) {
  return EditorController(ref);
});
