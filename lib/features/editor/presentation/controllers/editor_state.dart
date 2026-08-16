import '../../../../core/database/schemas/project.dart';

enum EditorTab {
  caption,
  style,
  transcription,
  export,
  trim,
  debug,
  shortcuts;

  String get value => name;
}

class EditorState {
  final Project? project;
  final double currentTime;
  final bool isPlaying;
  final EditorTab activeTab;
  final EditorTab previousTab;
  final bool hasUnsavedChanges;
  final bool showCjkFontPrompt;
  final int revision;
  /// Incremented each time Ctrl+F is pressed; WordPanel watches this to open Find & Replace.
  final int findReplaceCounter;
  final bool canUndo;
  final bool canRedo;

  const EditorState({
    this.project,
    this.currentTime = 0.0,
    this.isPlaying = false,
    this.activeTab = EditorTab.caption,
    this.previousTab = EditorTab.caption,
    this.hasUnsavedChanges = false,
    this.showCjkFontPrompt = false,
    this.revision = 0,
    this.findReplaceCounter = 0,
    this.canUndo = false,
    this.canRedo = false,
  });

  EditorState copyWith({
    Object? project = const Object(),
    double? currentTime,
    bool? isPlaying,
    EditorTab? activeTab,
    EditorTab? previousTab,
    bool? hasUnsavedChanges,
    bool? showCjkFontPrompt,
    int? revision,
    int? findReplaceCounter,
    bool? canUndo,
    bool? canRedo,
  }) {
    return EditorState(
      project: project == const Object() ? this.project : (project as Project?),
      currentTime: currentTime ?? this.currentTime,
      isPlaying: isPlaying ?? this.isPlaying,
      activeTab: activeTab ?? this.activeTab,
      previousTab: previousTab ?? this.previousTab,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      showCjkFontPrompt: showCjkFontPrompt ?? this.showCjkFontPrompt,
      revision: revision ?? this.revision,
      findReplaceCounter: findReplaceCounter ?? this.findReplaceCounter,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }
}
