import '../../../../core/database/schemas/project.dart';
import '../../../../core/video/retention_progress_bar_models.dart';
import '../../../../core/video/background_music_models.dart';
import '../../../../core/video/b_roll_models.dart';
import '../../../../core/video/chapter_models.dart';
import '../../../../core/collaboration/project_comment.dart';
import '../widgets/safe_zone_overlay.dart';

enum EditorTab {
  caption,
  style,
  transcription,
  export,
  trim,
  debug,
  shortcuts,
  clipping;

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
  final RetentionProgressBarConfig retentionBarConfig;
  final BackgroundMusicConfig backgroundMusicConfig;
  final List<BRollClip> bRollClips;
  final List<ProjectComment> comments;
  final SafeZonePlatform safeZoneGuide;
  final bool isProxyActive;
  final bool isGeneratingProxy;
  final double proxyProgress;
  final List<VideoChapter> chapters;

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
    this.retentionBarConfig = const RetentionProgressBarConfig(),
    this.backgroundMusicConfig = const BackgroundMusicConfig(),
    this.bRollClips = const [],
    this.comments = const [],
    this.safeZoneGuide = SafeZonePlatform.none,
    this.isProxyActive = false,
    this.isGeneratingProxy = false,
    this.proxyProgress = 0.0,
    this.chapters = const [],
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
    RetentionProgressBarConfig? retentionBarConfig,
    BackgroundMusicConfig? backgroundMusicConfig,
    List<BRollClip>? bRollClips,
    List<ProjectComment>? comments,
    SafeZonePlatform? safeZoneGuide,
    bool? isProxyActive,
    bool? isGeneratingProxy,
    double? proxyProgress,
    List<VideoChapter>? chapters,
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
      retentionBarConfig: retentionBarConfig ?? this.retentionBarConfig,
      backgroundMusicConfig: backgroundMusicConfig ?? this.backgroundMusicConfig,
      bRollClips: bRollClips ?? this.bRollClips,
      comments: comments ?? this.comments,
      safeZoneGuide: safeZoneGuide ?? this.safeZoneGuide,
      isProxyActive: isProxyActive ?? this.isProxyActive,
      isGeneratingProxy: isGeneratingProxy ?? this.isGeneratingProxy,
      proxyProgress: proxyProgress ?? this.proxyProgress,
      chapters: chapters ?? this.chapters,
    );
  }
}

