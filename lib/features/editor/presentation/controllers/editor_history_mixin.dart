part of 'editor_controller.dart';

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

/// Undo/redo history management for [EditorController]. Depends on the shared
/// state and clone helpers from [EditorCoreMixin].
mixin EditorHistoryMixin on EditorCoreMixin {
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
    if (_history.length > _kMaxHistory) {
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

  /// Commits a history step and triggers database write.
  /// Used after quiet operations (e.g. at the end of a drag).
  void commitHistoryAndSave() {
    final project = state.project;
    if (project == null) return;
    _recordChange();
    _autoSave();
    LoggerService.instance.action('EditorController', 'Committed quiet timeline changes to history and triggered auto-save.');
  }
}
