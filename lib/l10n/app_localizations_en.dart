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
  String get importVideo => 'Import Video';

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
  String get btnExport => 'EXPORT';

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
  String get settingsTheme => 'App Theme Theme';

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
}
