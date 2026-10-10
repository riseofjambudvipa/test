part of 'editor_controller.dart';

/// Trim/segment boundaries and style configuration operations for
/// [EditorController]: trim window, segment split/toggle/reset, and style
/// property updates. Depends on the shared state and history mixins.
mixin EditorTrimStyleOpsMixin on EditorWordOpsMixin {
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
      state = state.copyWith(
        project: updated,
        hasUnsavedChanges: true,
        revision: state.revision + 1,
      );
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
      state = state.copyWith(
        project: updated,
        hasUnsavedChanges: true,
        revision: state.revision + 1,
      );
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
    
    state = state.copyWith(
      project: updated,
      hasUnsavedChanges: true,
      revision: state.revision + 1,
    );
    _recordChange();
    _autoSave();
  }

  /// Applies a new list of video segments (e.g. from silence jump-cut detection).
  /// Clones the project, updates segments, records history, and auto-saves.
  void applySegments(List<VideoSegmentSchema> segments) {
    final project = state.project;
    if (project == null) return;

    LoggerService.instance.action('EditorController', 'Applying ${segments.length} video segments to project');

    final updated = _cloneProject(project);
    updated.segments = segments
        .map((s) => VideoSegmentSchema()
          ..start = s.start
          ..end = s.end
          ..isDeleted = s.isDeleted)
        .toList();

    state = state.copyWith(
      project: updated,
      hasUnsavedChanges: true,
    );
    _recordChange();
    _autoSave();
  }

  /// Cuts out a video segment between [startTime] and [endTime] (transcript-based video editing).
  /// Video playback will seamlessly skip this range, and video export will slice around it.
  void cutVideoSegmentForTimeRange(double startTime, double endTime, {bool hideWords = false}) {
    cutVideoSegmentsForTimeRanges([(start: startTime, end: endTime)], hideWords: hideWords);
  }

  /// Batch cuts out multiple video intervals (e.g. from filler word removal or multi-word script cut).
  void cutVideoSegmentsForTimeRanges(List<({double start, double end})> ranges, {bool hideWords = false}) {
    final project = state.project;
    if (project == null || ranges.isEmpty) return;

    final validRanges = <({double start, double end})>[];
    for (final r in ranges) {
      final s = r.start.clamp(0.0, project.duration);
      final e = r.end.clamp(0.0, project.duration);
      if (s < e) {
        validRanges.add((start: s, end: e));
      }
    }
    if (validRanges.isEmpty) return;

    LoggerService.instance.action('EditorController', 'Batch cutting ${validRanges.length} video segments from timeline');

    final updated = _cloneProject(project);
    final segments = (updated.segments != null && updated.segments!.isNotEmpty)
        ? List<VideoSegmentSchema>.from(updated.segments!)
        : [
            VideoSegmentSchema()
              ..start = 0.0
              ..end = updated.duration
              ..isDeleted = false,
          ];

    for (final r in validRanges) {
      _splitSegmentListAt(segments, r.start);
      _splitSegmentListAt(segments, r.end);
    }

    // Any segment that falls inside any of the cut ranges is marked isDeleted = true
    for (int i = 0; i < segments.length; i++) {
      final segStart = segments[i].start ?? 0.0;
      final segEnd = segments[i].end ?? 0.0;
      final isInsideAny = validRanges.any((r) => segStart >= r.start - 0.001 && segEnd <= r.end + 0.001);
      if (isInsideAny) {
        segments[i] = VideoSegmentSchema()
          ..start = segStart
          ..end = segEnd
          ..isDeleted = true;
      }
    }

    // Merge adjacent segments with identical isDeleted status for clean timeline
    final merged = <VideoSegmentSchema>[];
    for (final s in segments) {
      if (merged.isEmpty) {
        merged.add(s);
      } else {
        final prev = merged.last;
        if (prev.isDeleted == s.isDeleted) {
          merged[merged.length - 1] = VideoSegmentSchema()
            ..start = prev.start
            ..end = s.end
            ..isDeleted = prev.isDeleted;
        } else {
          merged.add(s);
        }
      }
    }

    updated.segments = merged;

    if (hideWords) {
      for (final w in updated.words) {
        final wStart = w.start ?? 0.0;
        final wEnd = w.end ?? 0.0;
        final isInsideAny = validRanges.any((r) => wStart >= r.start - 0.001 && wEnd <= r.end + 0.001);
        if (isInsideAny) {
          w.hidden = true;
        }
      }
    }

    state = state.copyWith(
      project: updated,
      hasUnsavedChanges: true,
      revision: state.revision + 1,
    );
    _recordChange();
    _autoSave();
  }

  /// Automatically detects speech hesitations and filler words ("um", "uh", "like", "basically")
  /// and cuts their time spans out of the video segments, seamlessly jump-cutting them from
  /// playback and final video export (Descript parity).
  int cutFillerWordsFromVideo() {
    final project = state.project;
    if (project == null || project.words.isEmpty) return 0;

    final ranges = <({double start, double end})>[];
    for (final w in project.words) {
      if (w.hidden == true) continue;
      final clean = AutoEnhancementService.cleanWord(w.text);
      if (AutoEnhancementService.fillerWords.contains(clean)) {
        final s = w.start ?? 0.0;
        final e = w.end ?? 0.0;
        if (s < e) {
          ranges.add((start: s, end: e));
        }
      }
    }
    if (ranges.isEmpty) return 0;

    cutVideoSegmentsForTimeRanges(ranges, hideWords: true);
    return ranges.length;
  }

  static void _splitSegmentListAt(List<VideoSegmentSchema> segments, double time) {
    for (int i = 0; i < segments.length; i++) {
      final s = segments[i].start ?? 0.0;
      final e = segments[i].end ?? 0.0;
      if (time > s + 0.01 && time < e - 0.01) {
        final original = segments[i];
        final first = VideoSegmentSchema()
          ..start = original.start
          ..end = time
          ..isDeleted = original.isDeleted;
        final second = VideoSegmentSchema()
          ..start = time
          ..end = original.end
          ..isDeleted = original.isDeleted;
        segments.removeAt(i);
        segments.insert(i, first);
        segments.insert(i + 1, second);
        return;
      }
    }
  }

  /// Replace entire config at once (used for template/theme changes)
  void setFullConfig(ProjectConfigSchema newConfig) {
    final project = state.project;
    if (project == null) return;
    LoggerService.instance.action('EditorController', 'Applying style config template layout: "${newConfig.name}".');

    final updated = _cloneProject(project);
    // Preserve existing chunking configuration and chosen emojiPack so style preset changes
    // do not destroy the user's chunk sizing or wipe custom emoji packs.
    if (project.config.subs.chunkSize > 0) {
      newConfig.subs.chunkSize = project.config.subs.chunkSize;
      newConfig.subs.chunkLineMaxLength = project.config.subs.chunkLineMaxLength;
    }
    if (newConfig.emojiPack == null || newConfig.emojiPack == 'notoColorEmoji') {
      if (project.config.emojiPack != null && project.config.emojiPack!.isNotEmpty) {
        newConfig.emojiPack = project.config.emojiPack;
      }
    }
    updated.config = _cloneConfig(newConfig);
    state = state.copyWith(
      project: updated,
      hasUnsavedChanges: true,
      revision: state.revision + 1,
    );
    _recordChange();
    _autoSave();
  }

  // --- Style Configuration Actions ---

  /// Update a single style properties like fontSize, fontFamily, Y position, stroke, animation, and chunkSize
  void updateStyleProp(String key, Object? value) {
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
          ..left = style.left
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
          case 'left':
            if (value is num) {
              newStyle.left = value.toDouble();
            } else {
              LoggerService.instance.warning('EditorController', 'Invalid type for left: ${value.runtimeType}');
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

    state = state.copyWith(
      project: updated,
      hasUnsavedChanges: true,
      revision: state.revision + 1,
    );
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

    state = state.copyWith(
      project: updated,
      hasUnsavedChanges: true,
      revision: state.revision + 1,
    );
    _recordChange();
    _autoSave();
  }

  /// Apply a Brand Kit's colors and typography to the current project in 1-click
  void applyBrandKit({
    required String primaryColor,
    required String secondaryColor,
    required String accentColor,
    required String fontFamily,
    String? templateId,
  }) {
    final project = state.project;
    if (project == null) return;
    LoggerService.instance.action('EditorController', 'Applying Brand Kit styles ($fontFamily, primary: $primaryColor).');

    final updated = _cloneProject(project);
    final config = updated.config;

    // Apply font
    final newStyle = StyleConfigSchema()
      ..fontFamily = fontFamily
      ..fontWeight = config.style.fontWeight
      ..textTransform = config.style.textTransform
      ..color = config.style.color
      ..fontSize = config.style.fontSize
      ..top = config.style.top
      ..left = config.style.left
      ..highlightBackground = config.style.highlightBackground
      ..letterSpacing = config.style.letterSpacing
      ..lineHeight = config.style.lineHeight;
    config.style = newStyle;

    // Apply 3 brand highlight colors
    final newHs = HighlightStyleSchema()
      ..mainColor = primaryColor
      ..secondColor = secondaryColor
      ..thirdColor = accentColor;
    config.highlightStyle = newHs;

    updated.config = config;

    state = state.copyWith(
      project: updated,
      hasUnsavedChanges: true,
      revision: state.revision + 1,
    );
    _recordChange();
    _autoSave();
  }

  /// Updates the dynamic retention progress bar configuration and persists it.
  void updateRetentionBarConfig(RetentionProgressBarConfig config) {
    state = state.copyWith(
      retentionBarConfig: config,
      revision: state.revision + 1,
    );
    final projectId = state.project?.projectId;
    if (projectId != null && projectId.isNotEmpty) {
      RetentionProgressBarService.instance.saveConfig(projectId, config);
    }
  }

  /// Updates the background music and speech ducking configuration and persists it.
  void setBackgroundMusicConfig(BackgroundMusicConfig config) {
    state = state.copyWith(
      backgroundMusicConfig: config,
      hasUnsavedChanges: true,
      revision: state.revision + 1,
    );
    final projectId = state.project?.projectId;
    if (projectId != null && projectId.isNotEmpty) {
      BackgroundMusicService.instance.saveConfig(projectId, config);
    }
  }

  /// Permanently ripple-deletes all segments marked `isDeleted = true`, closing
  /// dead air gaps and shifting subsequent segments, cuts, and subtitle words leftward.
  void rippleDeleteAllDeletedSegments() {
    final project = state.project;
    if (project == null || project.segments == null || project.segments!.isEmpty) return;

    final originalSegments = project.segments!;
    final hasDeleted = originalSegments.any((s) => s.isDeleted == true);
    if (!hasDeleted) return;

    LoggerService.instance.action('EditorController', 'Executing timeline ripple-delete across deleted segments');

    final updated = _cloneProject(project);
    final survivingSegments = <VideoSegmentSchema>[];
    final deletedIntervals = <({double start, double end})>[];

    for (final seg in originalSegments) {
      final s = seg.start ?? 0.0;
      final e = seg.end ?? 0.0;
      if (seg.isDeleted == true) {
        deletedIntervals.add((start: s, end: e));
      }
    }

    // Sort deleted intervals chronologically
    deletedIntervals.sort((a, b) => a.start.compareTo(b.start));

    // Construct continuous surviving segments
    double currentPos = 0.0;
    for (final seg in originalSegments) {
      if (seg.isDeleted != true) {
        final dur = ((seg.end ?? 0.0) - (seg.start ?? 0.0)).clamp(0.0, double.infinity);
        survivingSegments.add(
          VideoSegmentSchema()
            ..start = currentPos
            ..end = currentPos + dur
            ..isDeleted = false,
        );
        currentPos += dur;
      }
    }

    if (survivingSegments.isEmpty) {
      survivingSegments.add(
        VideoSegmentSchema()
          ..start = 0.0
          ..end = 0.0
          ..isDeleted = false,
      );
      currentPos = 0.0;
    }

    // Remap subtitle words:
    // Drop words that fall inside any deleted interval, shift surviving words leftward
    final survivingWords = <WordSchema>[];
    for (final word in updated.words) {
      final wStart = word.start ?? 0.0;
      final wEnd = word.end ?? 0.0;

      // Check if word is completely or substantially inside a deleted interval
      final isInsideDeleted = deletedIntervals.any((d) =>
          (wStart >= d.start - 0.05 && wEnd <= d.end + 0.05) ||
          (wStart >= d.start && wStart < d.end && (wEnd - wStart) < 0.2));

      if (isInsideDeleted) continue;

      // Calculate shift from deleted time before word start
      double shift = 0.0;
      for (final d in deletedIntervals) {
        if (d.end <= wStart) {
          shift += (d.end - d.start);
        } else if (d.start < wStart && d.end > wStart) {
          shift += (wStart - d.start);
        }
      }

      final newStart = (wStart - shift).clamp(0.0, currentPos);
      final newEnd = (wEnd - shift).clamp(newStart, currentPos);

      final clonedWord = WordSchema()
        ..wordId = word.wordId
        ..text = word.text
        ..start = newStart
        ..end = newEnd
        ..type = word.type
        ..hidden = word.hidden
        ..speaker = word.speaker
        ..emoji = word.emoji
        ..soundEffect = word.soundEffect;

      survivingWords.add(clonedWord);
    }

    updated.segments = survivingSegments;
    updated.words = survivingWords;
    updated.duration = currentPos;
    updated.trimStart = 0.0;
    updated.trimEnd = currentPos;

    state = state.copyWith(
      project: updated,
      currentTime: state.currentTime.clamp(0.0, currentPos),
      hasUnsavedChanges: true,
      revision: state.revision + 1,
    );
    _recordChange();
    _autoSave();
  }

  /// Ripple-deletes the segment containing [time], immediately removing the gap.
  void rippleDeleteSegmentAtTime(double time) {
    final project = state.project;
    if (project == null || project.segments == null || project.segments!.isEmpty) return;

    final segs = project.segments!;
    final index = segs.indexWhere((s) => time >= (s.start ?? 0.0) && time <= (s.end ?? 0.0));
    if (index == -1) return;

    // Toggle to deleted if not already
    if (segs[index].isDeleted != true) {
      toggleSegmentDeleted(time);
    }
    rippleDeleteAllDeletedSegments();
  }
}
