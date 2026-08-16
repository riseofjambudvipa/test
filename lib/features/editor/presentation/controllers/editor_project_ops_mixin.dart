part of 'editor_controller.dart';

/// Project-level operations for [EditorController]: re-transcription and the
/// language-aware font application that follows it. Depends on the trim/style
/// ops mixin for the shared state and history access.
mixin EditorProjectOpsMixin on EditorTrimStyleOpsMixin {
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
}
