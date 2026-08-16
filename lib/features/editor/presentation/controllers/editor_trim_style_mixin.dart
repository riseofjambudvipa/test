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
}
