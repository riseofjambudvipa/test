// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'CapStudio';

  @override
  String get dashboardTitle => 'My Projects';

  @override
  String get dashboardSubtitle => 'Offline AI Captioning & Subtitle Studio';

  @override
  String get importVideo => 'Import New Video';

  @override
  String get dragDropText => 'Drag and drop your video file here';

  @override
  String get clickBrowse => 'or click to browse local files';

  @override
  String get demoMode => 'DEMO MODE';

  @override
  String get demoModeDesc =>
      'Load a demo project to try out styling and editor features.';

  @override
  String get warningAssets => 'Assets Folder Recovery Required';

  @override
  String get warningAssetsDesc =>
      'Bundled assets were not found in the app support folder. Double-click here to restore or change the assets directory.';

  @override
  String get deleteProjectTitle => 'Delete Project';

  @override
  String deleteProjectConfirm(String projectName) {
    return 'Are you sure you want to permanently delete \"$projectName\"? This action cannot be undone.';
  }

  @override
  String get renameProjectTitle => 'Rename Project';

  @override
  String get projectNameLabel => 'Project Name';

  @override
  String get btnCancel => 'CANCEL';

  @override
  String get btnDelete => 'DELETE';

  @override
  String get btnRename => 'RENAME';

  @override
  String get btnSave => 'SAVE';

  @override
  String get btnConfirm => 'CONFIRM';

  @override
  String get btnExport => 'Export';

  @override
  String get btnUndo => 'Undo';

  @override
  String get btnRedo => 'Redo';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get createdLabel => 'Created:';

  @override
  String get durationLabel => 'Duration:';

  @override
  String get statusLabel => 'Status:';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsGeneral => 'General Settings';

  @override
  String get settingsTheme => 'App Theme';

  @override
  String get themeSystem => 'System Default';

  @override
  String get themeLight => 'Light Mode';

  @override
  String get themeDark => 'Dark Mode';

  @override
  String get settingsLanguage => 'App UI Language';

  @override
  String get settingsTranscription => 'Transcription Settings';

  @override
  String get settingsWhisperModel => 'Whisper Model';

  @override
  String get settingsWhisperModelDesc =>
      'Select a model for transcription. Smaller is faster; larger is more accurate.';

  @override
  String get settingsTranscribeLang => 'Transcription Language';

  @override
  String get settingsAutoDetect => 'Auto-detect Language';

  @override
  String get settingsGPU => 'GPU Acceleration (CUDA)';

  @override
  String get settingsVAD => 'VAD Threshold (Voice Activity)';

  @override
  String get settingsExport => 'Export Settings';

  @override
  String get settingsExportDest => 'Default Export Directory';

  @override
  String get settingsBrowse => 'Browse';

  @override
  String get settingsEmojiPacks => 'Emoji & Style Packs';

  @override
  String get settingsEmojiPacksDesc =>
      'Customize emoji rendering styles and active subtitle assets.';

  @override
  String get settingsEmojiSearchLang => 'Emoji Search Language';

  @override
  String get settingsBtnManagePacks => 'MANAGE EMOJI PACKS';

  @override
  String get systemTitle => 'System Info';

  @override
  String get systemVersion => 'Version';

  @override
  String get systemReset => 'Reset Defaults';

  @override
  String get editorTabCaptions => 'Captions';

  @override
  String get editorTabStyles => 'Styles';

  @override
  String get editorTabTrim => 'Trim';

  @override
  String get editorTabAudio => 'Audio';

  @override
  String get editorTabTranscription => 'Transcription';

  @override
  String get editorTabShortcuts => 'Shortcuts';

  @override
  String get editorTabDebug => 'Debug';

  @override
  String get editorHeaderBack => 'Back';

  @override
  String get editorKeyboardShortcuts => 'Keyboard Shortcuts';

  @override
  String get dialogAnalyzing => 'Analyzing video...';

  @override
  String get dialogTranscribing => 'Transcribing audio...';

  @override
  String get dialogExtracting => 'Extracting audio...';

  @override
  String get dialogWait => 'This may take a moment. Please wait.';

  @override
  String get dialogError => 'Error';

  @override
  String get dialogImportFailed => 'Failed to import video.';

  @override
  String get noProjects => 'No projects created yet';

  @override
  String get aboutApp => 'About CapStudio';

  @override
  String get aboutAppDesc =>
      'Tell about CapStudio, credits, and open-source licenses.';

  @override
  String get aboutAppThanks =>
      'Special thanks to the open-source projects that make CapStudio possible:';

  @override
  String get btnViewAllLicenses => 'VIEW ALL PACKAGES LICENSES';

  @override
  String get exportBurnIn => 'BURN-IN VIDEO EXPORT';

  @override
  String get exportTimecodeFormats => 'TIMECODE SUBTITLE FORMATS';

  @override
  String get exportWebEnabled =>
      'Client-side video export is enabled. Rendering runs locally in your browser.';

  @override
  String get exportWebCaptionOnly =>
      'Web export currently includes captions only — emoji and sound effects are not yet burned into the video. Export from the desktop or mobile app for the full result.';

  @override
  String get exportOutputName => 'Output Video Name';

  @override
  String get exportMode => 'Export Mode';

  @override
  String get exportModeFast => 'Fast (Native FFmpeg)';

  @override
  String get exportModeFastUnsupported => 'Fast (Native FFmpeg) ⚠️ Unsupported';

  @override
  String get exportModeSlow => 'Slow (1:1 Preview Render)';

  @override
  String get exportTargetFps => 'Target FPS';

  @override
  String get exportFps24 => '24 FPS (Film)';

  @override
  String get exportFps25 => '25 FPS (PAL)';

  @override
  String get exportFps30 => '30 FPS (Standard)';

  @override
  String get exportFps50 => '50 FPS';

  @override
  String get exportFps60 => '60 FPS (Smooth)';

  @override
  String get exportFastUnsupported =>
      'Fast Mode is not supported on this device because the system FFmpeg build lacks subtitle rendering filters (libass). Slow Mode will be used instead.';

  @override
  String get exportSlowInfo =>
      'Captures each frame exactly as shown in preview. This guarantees pixel-perfect captions, but renders slower.';

  @override
  String get exportDestDirectory => 'DESTINATION DIRECTORY';

  @override
  String get exportDestBrowser => 'Browser Download Location';

  @override
  String get exportDestAndroid =>
      'Downloads folder (/storage/emulated/0/Download)';

  @override
  String get exportDestIos =>
      'Application Documents (Share Sheet after export)';

  @override
  String get exportChooseFolder => 'Choose Output Folder';

  @override
  String get exportStartMp4 => 'START MP4 EXPORT';

  @override
  String get exportSrtTitle => 'SubRip Subtitles (.srt)';

  @override
  String get exportSrtDesc =>
      'Universal timecoded standard. Compatible with YouTube, VLC, and Premiere Pro.';

  @override
  String get exportVttTitle => 'WebVTT Subtitles (.vtt)';

  @override
  String get exportVttDesc =>
      'Web-optimized subtitle format widely used in HTML5 players and online streaming.';

  @override
  String get exportAssTitle => 'Advanced SubStation Alpha (.ass)';

  @override
  String get exportAssDesc =>
      'Professional format embedding font sizes, styles, margins, and inline highlights.';

  @override
  String get exportTxtTitle => 'Plain Text Transcript (.txt)';

  @override
  String get exportTxtDesc =>
      'Line-by-line transcript with timestamp prefix markers.';

  @override
  String exportSuccess(String type) {
    return '$type exported successfully!';
  }

  @override
  String get exportNoLocation =>
      'No save location selected. Please choose a file path.';

  @override
  String get exportNoLocationCancelled =>
      'No save location selected. Export cancelled.';

  @override
  String exportFailed(String error) {
    return 'Failed to export: $error';
  }

  @override
  String get exportCopySrtTooltip => 'Copy SRT to clipboard';

  @override
  String get exportCopiedSrt => 'SRT copied to clipboard!';

  @override
  String exportCopyFailedSrt(String error) {
    return 'Failed to copy SRT: $error';
  }

  @override
  String exportSubtitlesDialogTitle(String type) {
    return 'Export $type Subtitles';
  }

  @override
  String get exportVideoDialogTitle => 'Export Video MP4';

  @override
  String get ffmpegRequiredTitle => 'FFmpeg Required';

  @override
  String get ffmpegRequiredBody =>
      'A local installation of FFmpeg is required to burn subtitles into a video file.\n\nPlease configure the FFmpeg path in Settings.';

  @override
  String get okLabel => 'OK';

  @override
  String get exportWebTitle => 'Exporting Video (Client-Side)';

  @override
  String exportWebSuccess(String fileName) {
    return 'Video exported successfully as $fileName!';
  }

  @override
  String exportWebFailed(String error) {
    return 'Rendering failed: $error';
  }

  @override
  String get viralShortsTitle => 'VIRAL SHORTS STUDIO';

  @override
  String get viralShortsSubtitle =>
      '9:16 Vertical Reframe, Silence Jump-Cuts & AI Hook Detector';

  @override
  String get viralReframeTitle => '1. VERTICAL 9:16 REFRAME';

  @override
  String get viralSilenceTitle => '2. SILENCE REMOVAL (JUMP-CUTS)';

  @override
  String get viralHooksTitle => '3. AI VIRAL HOOK DETECTOR';

  @override
  String get btnFindViralMoments => 'FIND VIRAL MOMENTS';

  @override
  String get btnScanSilences => 'SCAN FOR SILENCES';

  @override
  String get btnApplyJumpCuts => 'APPLY JUMP-CUTS';

  @override
  String get editorTabShorts => 'Shorts';

  @override
  String get editorTabClips => 'Clips';

  @override
  String get captionList => 'CAPTION LIST';

  @override
  String get uncertainLabel => 'Uncertain (<40%)';

  @override
  String get mediumConfidenceLabel => 'Medium (40-60%)';

  @override
  String get jumpToUncertain => 'Jump to next uncertain word';

  @override
  String get noUncertainWords => 'No uncertain words found.';

  @override
  String get findAndReplace => 'Find & Replace';

  @override
  String get addWordTitle => 'Add Word';

  @override
  String get editWordTitle => 'Edit Word';

  @override
  String get wordTextLabel => 'Word Text';

  @override
  String get startTimeLabel => 'Start Time (s)';

  @override
  String get endTimeLabel => 'End Time (s)';

  @override
  String get splitChunk => 'Split Chunk';

  @override
  String get insertLineAfter => 'Insert Line After';

  @override
  String get duplicateLine => 'Duplicate Line';

  @override
  String get deleteLine => 'Delete Line';

  @override
  String get chooseSfxTitle => 'Choose Sound Effect';

  @override
  String get searchSfxPlaceholder => 'Search SFX...';

  @override
  String get noSfxFound => 'No sound effects found';

  @override
  String get emojiSearch => 'Emoji Search';

  @override
  String get noEmojisFound => 'No emojis found.';

  @override
  String get mySavedPresets => 'MY SAVED PRESETS';

  @override
  String get btnImport => 'IMPORT';

  @override
  String get btnExportCaps => 'EXPORT';

  @override
  String get btnSaveCurrent => 'SAVE CURRENT';

  @override
  String get resetToDefault => 'Reset to Default';

  @override
  String get resetConfirmBody =>
      'This will reset all caption styles to default. Cannot be undone.';

  @override
  String get btnReset => 'Reset';

  @override
  String get wordHighlightBox => 'Word Highlight Box';

  @override
  String get wordHighlightBoxDesc =>
      'Colored pill background behind active spoken words';

  @override
  String get maxWordsPerChunk => 'Max Words per Subtitle Chunk';

  @override
  String get maxCharsPerLine => 'Max Characters per Subtitle Line';

  @override
  String get fontSettings => 'Font Settings';

  @override
  String get colorSettings => 'Color Settings';

  @override
  String get borderSettings => 'Border & Shadow Settings';

  @override
  String get speechToTextTitle => 'SPEECH-TO-TEXT TRANSCRIPTION';

  @override
  String get speechToTextDesc =>
      'Re-run local Speech-to-Text transcription. Any manual edits or timing offsets will be replaced.';

  @override
  String get useLocalAi => 'Use Local AI Transcription';

  @override
  String get runOnDeviceDesc => 'Run speech-to-text directly on this device';

  @override
  String get offlineDemoModeActive =>
      'Offline Demo mode is active. Local Whisper AI transcription is not supported on Web.';

  @override
  String get demoModeNote =>
      'Demo mode instantly generates highly realistic transcript tokens. Perfect for testing styles, templates, and timeline operations without setup.';

  @override
  String get transcriptionQuality => 'Transcription Quality';

  @override
  String get advancedSettings => 'Advanced Settings';

  @override
  String get cpuThreadsLabel => 'CPU Threads';

  @override
  String get vadSensitivity => 'VAD Sensitivity';

  @override
  String get translateToEnglish => 'Translate captions to English';

  @override
  String get startTranscriptionBtn => 'START TRANSCRIPTION';

  @override
  String get hardwareLocked => 'Hardware Locked';

  @override
  String get btnDownload => 'Download';

  @override
  String get welcomeTitle => 'Welcome to CapStudio';

  @override
  String get welcomeSubtitle =>
      'High-precision captions and viral shorts, 100% offline.';

  @override
  String get setupAssetDirTitle => 'Choose Asset Directory';

  @override
  String get setupAssetDirDesc =>
      'Select a directory to store models, fonts, and emoji packs.';

  @override
  String get downloadPacksTitle => 'Download Content Packs (Optional)';

  @override
  String get downloadPacksDesc =>
      'Optional fonts and sound effects for your video projects.';

  @override
  String get setupCompleteTitle => 'Setup Complete';

  @override
  String get setupCompleteDesc =>
      'You are ready to create stunning captioned videos.';

  @override
  String get btnGetStarted => 'Get Started';

  @override
  String get btnNext => 'NEXT';

  @override
  String get btnSkip => 'SKIP';

  @override
  String get onboardingFeaturePrivacy => '100% Privacy';

  @override
  String get onboardingFeaturePrivacyDesc =>
      'Your files never leave your device. All AI models run locally.';

  @override
  String get onboardingFeatureGpu => 'GPU Accelerated Playback';

  @override
  String get onboardingFeatureGpuDesc =>
      'High performance video editing using hardware decoding.';

  @override
  String get onboardingFeatureAssets => 'Offline Sidecar Assets';

  @override
  String get onboardingFeatureAssetsDesc =>
      'Download rich emoji packs once and run completely offline.';

  @override
  String get onboardingReadyTitle => 'You\'re Ready to Roll!';

  @override
  String get onboardingConfigDetails => 'Configuration Details:';

  @override
  String get btnLaunchCapStudio => 'Launch CapStudio';

  @override
  String get assetVerificationFailed =>
      'Asset verification failed. Please ensure assets downloaded properly.';

  @override
  String get assetsFolderNotFound => 'Assets Folder Not Found';

  @override
  String get assetsFolderNotFoundDesc =>
      'CapStudio could not locate the assets folder at the configured location. If the folder is on an external drive, please connect it.';

  @override
  String get expectedPathLabel => 'EXPECTED PATH:';

  @override
  String get browseNewLocation => 'Browse New Location';

  @override
  String get resetToDefaultPath => 'Reset to Default Path';

  @override
  String get retryVerification => 'Retry Verification';

  @override
  String get storagePathFolder => 'Storage Path Folder';

  @override
  String get tipWindowsDrive =>
      'Tip: If C: drive is small, choose a path on D: or E: for more space.';

  @override
  String get tipGeneralDrive =>
      'Tip: You can select an external drive path if your root volume is full.';

  @override
  String get confirmLocation => 'Confirm Location';

  @override
  String get requiredBadge => 'REQUIRED';

  @override
  String get emojiPacksHeader => 'EMOJI PACKS';

  @override
  String get fontPacksHeader => 'FONT PACKS';

  @override
  String get connectCliTitle => 'Connect Local CLI Tools';

  @override
  String get connectCliDesc =>
      'CapStudio needs whisper.cpp and FFmpeg binaries to perform transcription and export videos locally.';

  @override
  String get skipSetup => 'Skip setup for now';

  @override
  String get btnValidate => 'Validate';

  @override
  String get autoDetectAndValidate => 'Auto-detect & Validate';

  @override
  String get whisperCliPathLabel => 'Whisper CLI Executable Path';

  @override
  String get ffmpegCliPathLabel => 'FFmpeg CLI Executable Path';

  @override
  String get newProject => 'New Project';

  @override
  String get searchProjects => 'Search projects...';

  @override
  String get filterAll => 'All';

  @override
  String get sortByRecent => 'Most Recent';

  @override
  String get sortByDuration => 'Duration';

  @override
  String get noMatchingProjects => 'No projects match your search';

  @override
  String get btnEdit => 'EDIT';

  @override
  String get btnDuplicate => 'DUPLICATE';

  @override
  String get tooltipEdit => 'Edit';

  @override
  String get tooltipRename => 'Rename';

  @override
  String get tooltipDuplicate => 'Duplicate';

  @override
  String get tooltipDelete => 'Delete';

  @override
  String get tooltipTheme => 'Theme';

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get selectDemoFormat => 'SELECT DEMO FORMAT';

  @override
  String get selectDemoDesc =>
      'Select a layout format to preview CapStudio\'s high-fidelity caption engine, live word-level animations, and audio waveforms instantly.';

  @override
  String get landscapeDemo => 'Landscape Demo';

  @override
  String get landscapeDemoDesc =>
      'Perfect for YouTube, desktop & presentations.';

  @override
  String get portraitDemo => 'Portrait Demo';

  @override
  String get portraitDemoDesc => 'Ideal for TikTok, Shorts, Reels & mobile.';

  @override
  String get format16x9 => '16:9 Format';

  @override
  String get format9x16 => '9:16 Format';

  @override
  String get dropVideoHere => 'DROP VIDEO HERE';

  @override
  String get dropVideoSupported => 'Supports MP4, MOV, AVI, etc.';

  @override
  String get statusLocalOffline => 'LOCAL OFFLINE';

  @override
  String get speechModelTitle => 'Speech Recognition Model';

  @override
  String get hardwareUpgradesTitle => 'Hardware Performance Upgrades';

  @override
  String get showAdvancedPaths => 'SHOW ADVANCED PATH CONFIGURATION';

  @override
  String get hideAdvancedPaths => 'HIDE ADVANCED PATH CONFIGURATION';

  @override
  String get autoDownload => 'AUTO DOWNLOAD';

  @override
  String get gpuAcceleratedTranscription =>
      'GPU Accelerated Transcription (CUDA)';

  @override
  String get gpuRequiresNvidia => 'Requires NVIDIA GPU with CUDA compatibility';

  @override
  String get gpuExportEncoder => 'GPU Export Encoder';

  @override
  String get gpuExportEncoderDesc =>
      'Hardware acceleration for MP4 video export';

  @override
  String get defaultLanguage => 'Default Language';

  @override
  String get vadTitle => 'Voice Activity Detection (VAD)';

  @override
  String get vadDesc => 'Skips silent regions during processing';

  @override
  String get vadThreshold => 'VAD Threshold';

  @override
  String get autoSaveTitle => 'Automatic Auto-Save';

  @override
  String get autoSaveDesc =>
      'Automatically save project edits to database every 3 seconds';

  @override
  String get defaultOutputsTitle => 'Default Outputs';

  @override
  String get defaultExportFolder => 'Default Export Folder';

  @override
  String get alwaysAskExportPath => 'Always Ask for Export Path';

  @override
  String get alwaysAskExportPathDesc =>
      'Prompts for output path on each export (Desktop)';

  @override
  String get performanceTitle => 'Performance';

  @override
  String get exportCpuThreads => 'Export CPU Threads';

  @override
  String get exportCpuThreadsDesc =>
      'Processor threads to use for rendering (Auto scales safely per device)';

  @override
  String get aboutAppSubtitle =>
      '100% Offline, Privacy-First AI Captioning & Subtitle Studio';

  @override
  String get openSourceLicenses => 'Open Source Licenses';

  @override
  String get openSourceComplianceDesc =>
      'CapStudio relies on many other open-source libraries. A complete registry of all Dart packages, transitive dependencies, and full license texts is compiled below for legal store compliance.';

  @override
  String get visitWebsite => 'Visit Website';

  @override
  String get btnContinue => 'Continue';

  @override
  String get btnBack => 'Back';

  @override
  String get editTiming => 'Edit Timing';

  @override
  String get wordSettingsTitle => 'Word Settings';

  @override
  String get emojiSettingsTitle => 'EMOJI SETTINGS';

  @override
  String get changeEmojiTooltip => 'Change Emoji';

  @override
  String get searchEmojisHint => 'Search Emojis...';

  @override
  String emojiPosX(String offset) {
    return 'Emoji Position (X Offset: ${offset}px)';
  }

  @override
  String emojiPosY(String offset) {
    return 'Emoji Position (Y Offset: ${offset}px)';
  }

  @override
  String emojiScale(String scale) {
    return 'Emoji Scale (${scale}x)';
  }

  @override
  String emojiAnimSpeed(String speed) {
    return 'Animation Speed (${speed}x)';
  }

  @override
  String get emojiStylePack => 'Emoji Style / Pack';

  @override
  String get selectStylePackTooltip => 'Select Style Pack';

  @override
  String get selectEmojiTitle => 'SELECT EMOJI';

  @override
  String get stylePackLabel => 'STYLE PACK';

  @override
  String get searchHint => 'Search...';

  @override
  String get btnCreateProject => 'CREATE PROJECT';

  @override
  String get btnChooseFile => 'CHOOSE FILE';

  @override
  String get selectSubtitleFile => 'Select Subtitle File';

  @override
  String get selectTranscriptionQuality => 'SELECT TRANSCRIPTION QUALITY';

  @override
  String get translateToEnglishDesc =>
      'Convert foreign speech directly into English subtitles';

  @override
  String get hardwareSettings => 'HARDWARE & PERFORMANCE SETTINGS';

  @override
  String get styleTemplatesHeader => 'STYLE TEMPLATES';

  @override
  String get resetToDefaultStyle => 'Reset to default style';

  @override
  String get resetStylingTitle => 'Reset Styling?';

  @override
  String get resetStylingDesc =>
      'This will reset all caption styles to default. Cannot be undone.';

  @override
  String get sizeAndPosition => 'SIZE & POSITION';

  @override
  String get verticalYPos => 'Vertical Y Position (%)';

  @override
  String get fontConfigHeader => 'FONT CONFIGURATION';

  @override
  String get fontFamilyLabel => 'Font Family';

  @override
  String get btnImportCustomFont => 'IMPORT CUSTOM FONT (.ttf / .otf)';

  @override
  String get fontWeightLabel => 'Font Weight';

  @override
  String get textCaseLabel => 'Text Case';

  @override
  String get fontSizeLabel => 'Font Size';

  @override
  String get letterSpacingLabel => 'Letter Spacing';

  @override
  String get lineHeightLabel => 'Line Height';

  @override
  String get onboardingAppTagline => '100% Offline Local AI Caption Editor';

  @override
  String get configLabelWhisperCli => 'Whisper CLI';

  @override
  String get configValueDemoMode => 'Demo Mode (Mock)';

  @override
  String get configLabelFfmpegCli => 'FFmpeg CLI';

  @override
  String get configValueSystemPathDefault => 'System PATH default';

  @override
  String get configLabelAssetsLocation => 'Assets Location';

  @override
  String get filePickerAssetsDialogTitle => 'Select CapStudio Assets Folder';

  @override
  String errorSelectFolderFailed(String error) {
    return 'Failed to select folder: $error';
  }

  @override
  String errorResetFailed(String error) {
    return 'Failed to reset: $error';
  }

  @override
  String errorVerificationFailed(String error) {
    return 'Verification failed: $error';
  }

  @override
  String errorAssetsFolderStillMissing(String path) {
    return 'Assets folder still not found at: $path';
  }

  @override
  String get dbRecoveredTitle => 'Database Automatically Recovered';

  @override
  String dbRecoveredBody(String backupPath) {
    return 'A database schema mismatch or corruption was detected. The database was reset, and your previous data was backed up to:\n\n$backupPath';
  }

  @override
  String errorDemoLoadFailed(String error) {
    return 'Failed to load demo video: $error';
  }

  @override
  String importProgressPercent(int percent) {
    return '$percent% Completed';
  }

  @override
  String get errorInvalidDropFileFormat =>
      'Invalid file format. Please drop a video file.';

  @override
  String get findTextLabel => 'Find text';

  @override
  String get replaceWithLabel => 'Replace with';

  @override
  String findReplaceSuccessCount(int count) {
    return 'Replaced $count occurrences!';
  }

  @override
  String get btnReplaceAll => 'REPLACE ALL';

  @override
  String errorVideoFileNotFound(String path) {
    return 'Video file not found:\n$path\nPlease re-link the video file.';
  }

  @override
  String get errorTranscriptionFailed =>
      'Transcription failed. Please try again.';

  @override
  String transcriptionActiveModel(String quality, String model) {
    return 'Active: $quality ($model)';
  }

  @override
  String get badgeRecommended => 'REC';

  @override
  String get languageLabel => 'Language';

  @override
  String warningEnglishOnlyModel(String model, String language) {
    return 'Warning: The selected model ($model) is English-only. Transcribing in \"$language\" will fail or produce English captions. Please select a Multilingual model (e.g. Tiny or Base).';
  }

  @override
  String get tipAutoDetectMixedLanguage =>
      'Tip: Auto-detect is not recommended for mixed languages (like Hinglish). Explicitly selecting your spoken language (e.g. Hindi or English) will provide much more accurate captions.';

  @override
  String get detectedHardwareLabel => 'Detected System Hardware:';

  @override
  String hardwareRamSize(String ramGB) {
    return 'RAM Size: $ramGB GB';
  }

  @override
  String hardwareCpuCores(int cores) {
    return 'CPU Logical Cores: $cores';
  }

  @override
  String hardwareGpuDevice(String gpu) {
    return 'GPU Device: $gpu';
  }

  @override
  String get hardwareDetecting => 'Detecting hardware stats...';

  @override
  String get btnStartReTranscribe => 'START RE-TRANSCRIBE';

  @override
  String get btnImportSrtVtt => 'IMPORT SRT/VTT FILE';

  @override
  String importedSubtitleWords(int count) {
    return 'Imported $count words from subtitle file.';
  }

  @override
  String get errorImportSubtitleFailed =>
      'Failed to import subtitle file. Please check the file format.';

  @override
  String get noProjectLoaded => 'No project loaded';

  @override
  String get badge916Vertical => '9:16 VERTICAL';

  @override
  String get badge169Landscape => '16:9 LANDSCAPE';

  @override
  String get reframeTargetCanvas =>
      'Target canvas: 1080 × 1920 (TikTok, YouTube Shorts, Instagram Reels)';

  @override
  String get reframeModeLabel => 'Reframe Mode:';

  @override
  String get reframeModeBlurPillarbox => 'Blur Pillarbox (Recommended)';

  @override
  String get reframeModeBlurPillarboxDesc =>
      'Scales & blurs video in the background to fill 9:16, keeping the centered video crisp.';

  @override
  String get reframeModeCenterCrop => 'Center Smart Crop';

  @override
  String get reframeModeCenterCropDesc =>
      'Fills the full 9:16 screen by cropping the left and right edges.';

  @override
  String get reframeModeSplitScreen => 'Split Screen / Dual Layer';

  @override
  String get reframeModeSplitScreenDesc =>
      'Stacks two video windows vertically (ideal for reactions and podcast dialogue).';

  @override
  String get btnResetTo169 => 'CURRENTLY 9:16 (RESET TO 16:9)';

  @override
  String get btnSetCanvas916 => 'SET PROJECT CANVAS TO 9:16';

  @override
  String get silenceRemovalDesc =>
      'Automatically cuts out dead pauses and breathing gaps to maximize video retention.';

  @override
  String get silenceAggressivenessLabel => 'Cut Aggressiveness:';

  @override
  String silenceNoiseGateLabel(int db) {
    return 'Silence Noise Gate: $db dB';
  }

  @override
  String silenceMinPauseLabel(String duration) {
    return 'Min Pause: ${duration}s';
  }

  @override
  String get btnScanning => 'SCANNING...';

  @override
  String silenceNoneFound(String duration) {
    return 'No silence gaps found exceeding ${duration}s.';
  }

  @override
  String silenceFoundCount(int count, String totalSecs) {
    return 'Found $count silences (${totalSecs}s dead air saved)!';
  }

  @override
  String errorScanningAudio(String error) {
    return 'Error scanning audio: $error';
  }

  @override
  String jumpCutsApplied(int count) {
    return 'Applied $count jump-cuts to project timeline!';
  }

  @override
  String get viralHooksDesc =>
      'Scans transcription words for 80+ viral hooks, pacing (120–170 WPM), questions, energy density & clip boundaries.';

  @override
  String get btnAnalyzingTranscript => 'ANALYZING TRANSCRIPT...';

  @override
  String get selectAllLabel => 'Select All';

  @override
  String selectedCountOf(int selected, int total) {
    return '$selected of $total selected';
  }

  @override
  String get btnSelectClipsToBatchExport => 'SELECT CLIPS TO BATCH EXPORT';

  @override
  String btnBatchExportCount(int count) {
    return 'BATCH EXPORT $count CLIP(S)';
  }

  @override
  String get viralNoClipsDetected =>
      'No high-scoring viral clips detected in this video duration range.';

  @override
  String get badgeCleanCut => 'CLEAN CUT';

  @override
  String get badgeFirst5s => 'FIRST 5s';

  @override
  String get btnPreview => 'Preview';

  @override
  String get btnTrim => 'Trim';

  @override
  String get tooltipForkAs916 => 'Fork as New 9:16 Short Project';

  @override
  String wpmLabelOk(int wpm) {
    return '$wpm WPM ✓';
  }

  @override
  String wpmLabelFast(int wpm) {
    return '$wpm WPM FAST';
  }

  @override
  String wpmLabelSlow(int wpm) {
    return '$wpm WPM SLOW';
  }

  @override
  String hookScoreLabel(int score) {
    return 'Hook $score/40';
  }

  @override
  String energyScoreLabel(int score) {
    return 'Energy $score/20';
  }

  @override
  String get filePickerClipsFolderTitle => 'Choose folder to save clips';

  @override
  String get errorChooseOutputFolderFirst =>
      'Please choose an output folder first.';

  @override
  String batchExportSheetTitle(int count) {
    return 'BATCH EXPORT $count CLIP(S)';
  }

  @override
  String get tapToChooseOutputFolder => 'Tap to choose output folder…';

  @override
  String get burnCaptionsOnClipsLabel => 'Burn Dynamic Captions on Clips';

  @override
  String get burnCaptionsOnClipsDesc =>
      'Burns styled animated subtitles synchronized to clip audio';

  @override
  String exportCancelledProgress(int done, int total) {
    return 'Export cancelled. $done/$total done.';
  }

  @override
  String exportProgressSummary(int done, int total, int failed) {
    return '$done/$total exported · $failed failed';
  }

  @override
  String get btnExporting => 'EXPORTING…';

  @override
  String get btnExportComplete => 'EXPORT COMPLETE ✓';

  @override
  String get btnStartExport => 'START EXPORT';

  @override
  String exportClipSavedAt(String path) {
    return '✓ Saved: $path';
  }

  @override
  String projectTrimmedToClip(int rank, String start, String end) {
    return 'Project trimmed to viral clip #$rank ($start - $end)!';
  }

  @override
  String shortProjectCreated(String name) {
    return 'Created 9:16 Short: \"$name\"';
  }

  @override
  String get btnOpen => 'OPEN';

  @override
  String errorCreateShortProjectFailed(String error) {
    return 'Failed to create short project: $error';
  }

  @override
  String get autoDetect => 'Auto Detect';

  @override
  String presetSaved(String name) {
    return 'Saved style preset \"$name\" successfully!';
  }

  @override
  String get presetDeleted => 'Preset deleted successfully.';

  @override
  String get presetExported => 'Style presets exported successfully!';

  @override
  String errorPresetExportFailed(String error) {
    return 'Failed to export presets: $error';
  }

  @override
  String get presetImported => 'Imported style presets successfully!';

  @override
  String errorPresetImportFailed(String error) {
    return 'Failed to import presets: $error';
  }

  @override
  String get selectFontFileDialogTitle => 'Select TTF or OTF Font File';

  @override
  String get fontWeightThin => 'Thin';

  @override
  String get fontWeightExtraLight => 'Extra Light';

  @override
  String get fontWeightLight => 'Light';

  @override
  String get fontWeightNormal => 'Normal';

  @override
  String get fontWeightMedium => 'Medium';

  @override
  String get fontWeightSemiBold => 'Semi Bold';

  @override
  String get fontWeightBold => 'Bold';

  @override
  String get fontWeightExtraBold => 'Extra Bold';

  @override
  String get fontWeightBlack => 'Black';

  @override
  String get fontCaseNormal => 'Normal';

  @override
  String get fontCaseUppercase => 'UPPERCASE';

  @override
  String get fontCaseCapitalize => 'Capitalize';

  @override
  String get strokeStyleThickOutline => 'Thick Outline';

  @override
  String get strokeStyleNoneFlat => 'None (Flat)';

  @override
  String get shadowStyleSoft => 'Soft Shadow';

  @override
  String get shadowStyleNone => 'None';

  @override
  String get animStyleActivePop => 'Active Pop';

  @override
  String get animStyleActiveBounce => 'Active Bounce Jump';

  @override
  String get animStyleKineticTilt => 'Kinetic Bouncy Tilt';

  @override
  String get animStyleGlowPulse => 'Glowing Active Pulse';

  @override
  String get animStyleWordReveal => 'Word Reveal Stagger';

  @override
  String get animStyleNoneStatic => 'None (Static)';

  @override
  String fontImportedSuccess(String name) {
    return 'Successfully imported and applied custom font: \"$name\"';
  }

  @override
  String get errorFontImportFailed => 'Failed to load font file. Invalid data.';

  @override
  String get invalidTimingError =>
      'Invalid start/end timings. Start must be >= 0, and end must be >= start and <= video duration.';

  @override
  String get projectSavedSuccess => 'Project saved successfully.';

  @override
  String wordDeletedSuccess(String text) {
    return 'Deleted word: \"$text\"';
  }

  @override
  String get splitClip => 'Split clip';

  @override
  String get removeClip => 'Remove clip';

  @override
  String get resetToOriginal => 'Reset to original';

  @override
  String splitTimelineAt(String time) {
    return 'Split timeline at ${time}s.';
  }

  @override
  String get splitTimelineError =>
      'Playhead must be inside the active region to split.';

  @override
  String get exclusionToggled => 'Toggled segment exclusion under playhead.';

  @override
  String get splitsReset => 'Reset all timeline splits and exclusions.';

  @override
  String get shareVideo => 'Share Video';

  @override
  String get openOutputFolder => 'Open output folder';

  @override
  String get errorLogCopied => 'Error log copied to clipboard.';

  @override
  String get diagnosticsExported =>
      'Filtered diagnostic report opened in share sheet.';

  @override
  String errorDiagnosticsFailed(String error) {
    return 'Failed to export diagnostics report: $error';
  }

  @override
  String logLineCopied(String message) {
    return 'Copied log line to clipboard: \"$message\"';
  }

  @override
  String commandCopied(String command) {
    return 'Copied: \"$command\"';
  }

  @override
  String get settingsRestored => 'Settings restored to defaults.';

  @override
  String get gpuEncoderNoneCpu => 'None (CPU)';

  @override
  String get gpuEncoderNvidia => 'NVIDIA NVENC';

  @override
  String get gpuEncoderAmd => 'AMD AMF';

  @override
  String get gpuEncoderIntel => 'Intel QSV';

  @override
  String get gpuEncoderApple => 'Apple VideoToolbox';

  @override
  String get btnDownloadVcRedist => 'DOWNLOAD VC++ REDISTRIBUTABLE';

  @override
  String errorDownloadToolFailed(String error) {
    return 'Failed to download tool: $error';
  }

  @override
  String get errorFolderNotAccessible =>
      'Selected folder does not exist or is not accessible.';

  @override
  String modelDeleted(String name) {
    return 'Deleted model: $name';
  }

  @override
  String errorModelDeleteFailed(String error) {
    return 'Failed to delete model: $error';
  }

  @override
  String errorModelDownloadFailed(String name, String error) {
    return 'Failed to download model $name: $error';
  }

  @override
  String errorOpenFolderFailed(String path) {
    return 'Could not open folder automatically. Path: $path';
  }

  @override
  String errorDownloadPackFailed(String error) {
    return 'Failed to download pack: $error';
  }

  @override
  String errorPackDownloadNamedFailed(String name, String error) {
    return 'Failed to download pack $name: $error';
  }

  @override
  String get stickersIndexRefreshed =>
      'Custom stickers index refreshed successfully!';

  @override
  String errorChangeAssetFolderFailed(String error) {
    return 'Failed to change assets folder: $error';
  }

  @override
  String errorSetAssetFolderFailed(String error) {
    return 'Failed to set assets folder: $error';
  }

  @override
  String get warningNoAvx =>
      'Missing AVX support detected! Downloading compatible whisper-cli (no-AVX)...';

  @override
  String get errorAutoDetectWhisper =>
      'Could not auto-detect whisper-cli. Please browse manually.';

  @override
  String get errorAutoDetectFfmpeg =>
      'Could not auto-detect ffmpeg. Please browse manually.';

  @override
  String errorToolDownloadFailed(String error) {
    return 'Failed to download tool: $error';
  }

  @override
  String get returnToDashboard => 'Return to Dashboard';

  @override
  String errorImportVideoFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get videoRelinkedSuccess => 'Video relinked successfully!';

  @override
  String get errorRelinkVideoFailed => 'Failed to relink video.';

  @override
  String get retranscriptionSuccess => 'Re-transcription successful!';

  @override
  String get retranscriptionFailed => 'Re-transcription failed.';
}
