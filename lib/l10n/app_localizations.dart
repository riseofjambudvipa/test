import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh')
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'CapStudio'**
  String get appName;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'My Projects'**
  String get dashboardTitle;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Offline AI Captioning & Subtitle Studio'**
  String get dashboardSubtitle;

  /// No description provided for @importVideo.
  ///
  /// In en, this message translates to:
  /// **'Import New Video'**
  String get importVideo;

  /// No description provided for @dragDropText.
  ///
  /// In en, this message translates to:
  /// **'Drag and drop your video file here'**
  String get dragDropText;

  /// No description provided for @clickBrowse.
  ///
  /// In en, this message translates to:
  /// **'or click to browse local files'**
  String get clickBrowse;

  /// No description provided for @demoMode.
  ///
  /// In en, this message translates to:
  /// **'DEMO MODE'**
  String get demoMode;

  /// No description provided for @demoModeDesc.
  ///
  /// In en, this message translates to:
  /// **'Load a demo project to try out styling and editor features.'**
  String get demoModeDesc;

  /// No description provided for @warningAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets Folder Recovery Required'**
  String get warningAssets;

  /// No description provided for @warningAssetsDesc.
  ///
  /// In en, this message translates to:
  /// **'Bundled assets were not found in the app support folder. Double-click here to restore or change the assets directory.'**
  String get warningAssetsDesc;

  /// No description provided for @deleteProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get deleteProjectTitle;

  /// No description provided for @deleteProjectConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to permanently delete \"{projectName}\"? This action cannot be undone.'**
  String deleteProjectConfirm(String projectName);

  /// No description provided for @renameProjectTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Project'**
  String get renameProjectTitle;

  /// No description provided for @projectNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get projectNameLabel;

  /// No description provided for @btnCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get btnCancel;

  /// No description provided for @btnDelete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get btnDelete;

  /// No description provided for @btnRename.
  ///
  /// In en, this message translates to:
  /// **'RENAME'**
  String get btnRename;

  /// No description provided for @btnSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get btnSave;

  /// No description provided for @btnConfirm.
  ///
  /// In en, this message translates to:
  /// **'CONFIRM'**
  String get btnConfirm;

  /// No description provided for @btnExport.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get btnExport;

  /// No description provided for @btnUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get btnUndo;

  /// No description provided for @btnRedo.
  ///
  /// In en, this message translates to:
  /// **'Redo'**
  String get btnRedo;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @createdLabel.
  ///
  /// In en, this message translates to:
  /// **'Created:'**
  String get createdLabel;

  /// No description provided for @durationLabel.
  ///
  /// In en, this message translates to:
  /// **'Duration:'**
  String get durationLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status:'**
  String get statusLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsGeneral.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get settingsGeneral;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'App Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeDark;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'App UI Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTranscription.
  ///
  /// In en, this message translates to:
  /// **'Transcription Settings'**
  String get settingsTranscription;

  /// No description provided for @settingsWhisperModel.
  ///
  /// In en, this message translates to:
  /// **'Whisper Model'**
  String get settingsWhisperModel;

  /// No description provided for @settingsWhisperModelDesc.
  ///
  /// In en, this message translates to:
  /// **'Select a model for transcription. Smaller is faster; larger is more accurate.'**
  String get settingsWhisperModelDesc;

  /// No description provided for @settingsTranscribeLang.
  ///
  /// In en, this message translates to:
  /// **'Transcription Language'**
  String get settingsTranscribeLang;

  /// No description provided for @settingsAutoDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect Language'**
  String get settingsAutoDetect;

  /// No description provided for @settingsGPU.
  ///
  /// In en, this message translates to:
  /// **'GPU Acceleration (CUDA)'**
  String get settingsGPU;

  /// No description provided for @settingsVAD.
  ///
  /// In en, this message translates to:
  /// **'VAD Threshold (Voice Activity)'**
  String get settingsVAD;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export Settings'**
  String get settingsExport;

  /// No description provided for @settingsExportDest.
  ///
  /// In en, this message translates to:
  /// **'Default Export Directory'**
  String get settingsExportDest;

  /// No description provided for @settingsBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get settingsBrowse;

  /// No description provided for @settingsEmojiPacks.
  ///
  /// In en, this message translates to:
  /// **'Emoji & Style Packs'**
  String get settingsEmojiPacks;

  /// No description provided for @settingsEmojiPacksDesc.
  ///
  /// In en, this message translates to:
  /// **'Customize emoji rendering styles and active subtitle assets.'**
  String get settingsEmojiPacksDesc;

  /// No description provided for @settingsEmojiSearchLang.
  ///
  /// In en, this message translates to:
  /// **'Emoji Search Language'**
  String get settingsEmojiSearchLang;

  /// No description provided for @settingsBtnManagePacks.
  ///
  /// In en, this message translates to:
  /// **'MANAGE EMOJI PACKS'**
  String get settingsBtnManagePacks;

  /// No description provided for @systemTitle.
  ///
  /// In en, this message translates to:
  /// **'System Info'**
  String get systemTitle;

  /// No description provided for @systemVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get systemVersion;

  /// No description provided for @systemReset.
  ///
  /// In en, this message translates to:
  /// **'Reset Defaults'**
  String get systemReset;

  /// No description provided for @editorTabCaptions.
  ///
  /// In en, this message translates to:
  /// **'Captions'**
  String get editorTabCaptions;

  /// No description provided for @editorTabStyles.
  ///
  /// In en, this message translates to:
  /// **'Styles'**
  String get editorTabStyles;

  /// No description provided for @editorTabTrim.
  ///
  /// In en, this message translates to:
  /// **'Trim'**
  String get editorTabTrim;

  /// No description provided for @editorTabAudio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get editorTabAudio;

  /// No description provided for @editorTabTranscription.
  ///
  /// In en, this message translates to:
  /// **'Transcription'**
  String get editorTabTranscription;

  /// No description provided for @editorTabShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get editorTabShortcuts;

  /// No description provided for @editorTabDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get editorTabDebug;

  /// No description provided for @editorHeaderBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get editorHeaderBack;

  /// No description provided for @editorKeyboardShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Keyboard Shortcuts'**
  String get editorKeyboardShortcuts;

  /// No description provided for @dialogAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing video...'**
  String get dialogAnalyzing;

  /// No description provided for @dialogTranscribing.
  ///
  /// In en, this message translates to:
  /// **'Transcribing audio...'**
  String get dialogTranscribing;

  /// No description provided for @dialogExtracting.
  ///
  /// In en, this message translates to:
  /// **'Extracting audio...'**
  String get dialogExtracting;

  /// No description provided for @dialogWait.
  ///
  /// In en, this message translates to:
  /// **'This may take a moment. Please wait.'**
  String get dialogWait;

  /// No description provided for @dialogError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get dialogError;

  /// No description provided for @dialogImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import video.'**
  String get dialogImportFailed;

  /// No description provided for @noProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects created yet'**
  String get noProjects;

  /// No description provided for @aboutApp.
  ///
  /// In en, this message translates to:
  /// **'About CapStudio'**
  String get aboutApp;

  /// No description provided for @aboutAppDesc.
  ///
  /// In en, this message translates to:
  /// **'Tell about CapStudio, credits, and open-source licenses.'**
  String get aboutAppDesc;

  /// No description provided for @aboutAppThanks.
  ///
  /// In en, this message translates to:
  /// **'Special thanks to the open-source projects that make CapStudio possible:'**
  String get aboutAppThanks;

  /// No description provided for @btnViewAllLicenses.
  ///
  /// In en, this message translates to:
  /// **'VIEW ALL PACKAGES LICENSES'**
  String get btnViewAllLicenses;

  /// No description provided for @exportBurnIn.
  ///
  /// In en, this message translates to:
  /// **'BURN-IN VIDEO EXPORT'**
  String get exportBurnIn;

  /// No description provided for @exportTimecodeFormats.
  ///
  /// In en, this message translates to:
  /// **'TIMECODE SUBTITLE FORMATS'**
  String get exportTimecodeFormats;

  /// No description provided for @exportWebEnabled.
  ///
  /// In en, this message translates to:
  /// **'Client-side video export is enabled. Rendering runs locally in your browser.'**
  String get exportWebEnabled;

  /// No description provided for @exportWebCaptionOnly.
  ///
  /// In en, this message translates to:
  /// **'Web export currently includes captions only — emoji and sound effects are not yet burned into the video. Export from the desktop or mobile app for the full result.'**
  String get exportWebCaptionOnly;

  /// No description provided for @exportOutputName.
  ///
  /// In en, this message translates to:
  /// **'Output Video Name'**
  String get exportOutputName;

  /// No description provided for @exportMode.
  ///
  /// In en, this message translates to:
  /// **'Export Mode'**
  String get exportMode;

  /// No description provided for @exportModeFast.
  ///
  /// In en, this message translates to:
  /// **'Fast (Native FFmpeg)'**
  String get exportModeFast;

  /// No description provided for @exportModeFastUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Fast (Native FFmpeg) ⚠️ Unsupported'**
  String get exportModeFastUnsupported;

  /// No description provided for @exportModeSlow.
  ///
  /// In en, this message translates to:
  /// **'Slow (1:1 Preview Render)'**
  String get exportModeSlow;

  /// No description provided for @exportTargetFps.
  ///
  /// In en, this message translates to:
  /// **'Target FPS'**
  String get exportTargetFps;

  /// No description provided for @exportFps24.
  ///
  /// In en, this message translates to:
  /// **'24 FPS (Film)'**
  String get exportFps24;

  /// No description provided for @exportFps25.
  ///
  /// In en, this message translates to:
  /// **'25 FPS (PAL)'**
  String get exportFps25;

  /// No description provided for @exportFps30.
  ///
  /// In en, this message translates to:
  /// **'30 FPS (Standard)'**
  String get exportFps30;

  /// No description provided for @exportFps50.
  ///
  /// In en, this message translates to:
  /// **'50 FPS'**
  String get exportFps50;

  /// No description provided for @exportFps60.
  ///
  /// In en, this message translates to:
  /// **'60 FPS (Smooth)'**
  String get exportFps60;

  /// No description provided for @exportFastUnsupported.
  ///
  /// In en, this message translates to:
  /// **'Fast Mode is not supported on this device because the system FFmpeg build lacks subtitle rendering filters (libass). Slow Mode will be used instead.'**
  String get exportFastUnsupported;

  /// No description provided for @exportSlowInfo.
  ///
  /// In en, this message translates to:
  /// **'Captures each frame exactly as shown in preview. This guarantees pixel-perfect captions, but renders slower.'**
  String get exportSlowInfo;

  /// No description provided for @exportDestDirectory.
  ///
  /// In en, this message translates to:
  /// **'DESTINATION DIRECTORY'**
  String get exportDestDirectory;

  /// No description provided for @exportDestBrowser.
  ///
  /// In en, this message translates to:
  /// **'Browser Download Location'**
  String get exportDestBrowser;

  /// No description provided for @exportDestAndroid.
  ///
  /// In en, this message translates to:
  /// **'Downloads folder (/storage/emulated/0/Download)'**
  String get exportDestAndroid;

  /// No description provided for @exportDestIos.
  ///
  /// In en, this message translates to:
  /// **'Application Documents (Share Sheet after export)'**
  String get exportDestIos;

  /// No description provided for @exportChooseFolder.
  ///
  /// In en, this message translates to:
  /// **'Choose Output Folder'**
  String get exportChooseFolder;

  /// No description provided for @exportStartMp4.
  ///
  /// In en, this message translates to:
  /// **'START MP4 EXPORT'**
  String get exportStartMp4;

  /// No description provided for @exportSrtTitle.
  ///
  /// In en, this message translates to:
  /// **'SubRip Subtitles (.srt)'**
  String get exportSrtTitle;

  /// No description provided for @exportSrtDesc.
  ///
  /// In en, this message translates to:
  /// **'Universal timecoded standard. Compatible with YouTube, VLC, and Premiere Pro.'**
  String get exportSrtDesc;

  /// No description provided for @exportVttTitle.
  ///
  /// In en, this message translates to:
  /// **'WebVTT Subtitles (.vtt)'**
  String get exportVttTitle;

  /// No description provided for @exportVttDesc.
  ///
  /// In en, this message translates to:
  /// **'Web-optimized subtitle format widely used in HTML5 players and online streaming.'**
  String get exportVttDesc;

  /// No description provided for @exportAssTitle.
  ///
  /// In en, this message translates to:
  /// **'Advanced SubStation Alpha (.ass)'**
  String get exportAssTitle;

  /// No description provided for @exportAssDesc.
  ///
  /// In en, this message translates to:
  /// **'Professional format embedding font sizes, styles, margins, and inline highlights.'**
  String get exportAssDesc;

  /// No description provided for @exportTxtTitle.
  ///
  /// In en, this message translates to:
  /// **'Plain Text Transcript (.txt)'**
  String get exportTxtTitle;

  /// No description provided for @exportTxtDesc.
  ///
  /// In en, this message translates to:
  /// **'Line-by-line transcript with timestamp prefix markers.'**
  String get exportTxtDesc;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'{type} exported successfully!'**
  String exportSuccess(String type);

  /// No description provided for @exportNoLocation.
  ///
  /// In en, this message translates to:
  /// **'No save location selected. Please choose a file path.'**
  String get exportNoLocation;

  /// No description provided for @exportNoLocationCancelled.
  ///
  /// In en, this message translates to:
  /// **'No save location selected. Export cancelled.'**
  String get exportNoLocationCancelled;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to export: {error}'**
  String exportFailed(String error);

  /// No description provided for @exportCopySrtTooltip.
  ///
  /// In en, this message translates to:
  /// **'Copy SRT to clipboard'**
  String get exportCopySrtTooltip;

  /// No description provided for @exportCopiedSrt.
  ///
  /// In en, this message translates to:
  /// **'SRT copied to clipboard!'**
  String get exportCopiedSrt;

  /// No description provided for @exportCopyFailedSrt.
  ///
  /// In en, this message translates to:
  /// **'Failed to copy SRT: {error}'**
  String exportCopyFailedSrt(String error);

  /// No description provided for @exportSubtitlesDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export {type} Subtitles'**
  String exportSubtitlesDialogTitle(String type);

  /// No description provided for @exportVideoDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Video MP4'**
  String get exportVideoDialogTitle;

  /// No description provided for @ffmpegRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg Required'**
  String get ffmpegRequiredTitle;

  /// No description provided for @ffmpegRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'A local installation of FFmpeg is required to burn subtitles into a video file.\n\nPlease configure the FFmpeg path in Settings.'**
  String get ffmpegRequiredBody;

  /// No description provided for @okLabel.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get okLabel;

  /// No description provided for @exportWebTitle.
  ///
  /// In en, this message translates to:
  /// **'Exporting Video (Client-Side)'**
  String get exportWebTitle;

  /// No description provided for @exportWebSuccess.
  ///
  /// In en, this message translates to:
  /// **'Video exported successfully as {fileName}!'**
  String exportWebSuccess(String fileName);

  /// No description provided for @exportWebFailed.
  ///
  /// In en, this message translates to:
  /// **'Rendering failed: {error}'**
  String exportWebFailed(String error);

  /// No description provided for @viralShortsTitle.
  ///
  /// In en, this message translates to:
  /// **'VIRAL SHORTS STUDIO'**
  String get viralShortsTitle;

  /// No description provided for @viralShortsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'9:16 Vertical Reframe, Silence Jump-Cuts & AI Hook Detector'**
  String get viralShortsSubtitle;

  /// No description provided for @viralReframeTitle.
  ///
  /// In en, this message translates to:
  /// **'1. VERTICAL 9:16 REFRAME'**
  String get viralReframeTitle;

  /// No description provided for @viralSilenceTitle.
  ///
  /// In en, this message translates to:
  /// **'2. SILENCE REMOVAL (JUMP-CUTS)'**
  String get viralSilenceTitle;

  /// No description provided for @viralHooksTitle.
  ///
  /// In en, this message translates to:
  /// **'3. AI VIRAL HOOK DETECTOR'**
  String get viralHooksTitle;

  /// No description provided for @btnFindViralMoments.
  ///
  /// In en, this message translates to:
  /// **'FIND VIRAL MOMENTS'**
  String get btnFindViralMoments;

  /// No description provided for @btnScanSilences.
  ///
  /// In en, this message translates to:
  /// **'SCAN FOR SILENCES'**
  String get btnScanSilences;

  /// No description provided for @btnApplyJumpCuts.
  ///
  /// In en, this message translates to:
  /// **'APPLY JUMP-CUTS'**
  String get btnApplyJumpCuts;

  /// No description provided for @editorTabShorts.
  ///
  /// In en, this message translates to:
  /// **'Shorts'**
  String get editorTabShorts;

  /// No description provided for @editorTabClips.
  ///
  /// In en, this message translates to:
  /// **'Clips'**
  String get editorTabClips;

  /// No description provided for @captionList.
  ///
  /// In en, this message translates to:
  /// **'CAPTION LIST'**
  String get captionList;

  /// No description provided for @uncertainLabel.
  ///
  /// In en, this message translates to:
  /// **'Uncertain (<40%)'**
  String get uncertainLabel;

  /// No description provided for @mediumConfidenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Medium (40-60%)'**
  String get mediumConfidenceLabel;

  /// No description provided for @jumpToUncertain.
  ///
  /// In en, this message translates to:
  /// **'Jump to next uncertain word'**
  String get jumpToUncertain;

  /// No description provided for @noUncertainWords.
  ///
  /// In en, this message translates to:
  /// **'No uncertain words found.'**
  String get noUncertainWords;

  /// No description provided for @findAndReplace.
  ///
  /// In en, this message translates to:
  /// **'Find & Replace'**
  String get findAndReplace;

  /// No description provided for @addWordTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Word'**
  String get addWordTitle;

  /// No description provided for @editWordTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Word'**
  String get editWordTitle;

  /// No description provided for @wordTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Word Text'**
  String get wordTextLabel;

  /// No description provided for @startTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Start Time (s)'**
  String get startTimeLabel;

  /// No description provided for @endTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'End Time (s)'**
  String get endTimeLabel;

  /// No description provided for @splitChunk.
  ///
  /// In en, this message translates to:
  /// **'Split Chunk'**
  String get splitChunk;

  /// No description provided for @insertLineAfter.
  ///
  /// In en, this message translates to:
  /// **'Insert Line After'**
  String get insertLineAfter;

  /// No description provided for @duplicateLine.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Line'**
  String get duplicateLine;

  /// No description provided for @deleteLine.
  ///
  /// In en, this message translates to:
  /// **'Delete Line'**
  String get deleteLine;

  /// No description provided for @chooseSfxTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Sound Effect'**
  String get chooseSfxTitle;

  /// No description provided for @searchSfxPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search SFX...'**
  String get searchSfxPlaceholder;

  /// No description provided for @noSfxFound.
  ///
  /// In en, this message translates to:
  /// **'No sound effects found'**
  String get noSfxFound;

  /// No description provided for @emojiSearch.
  ///
  /// In en, this message translates to:
  /// **'Emoji Search'**
  String get emojiSearch;

  /// No description provided for @noEmojisFound.
  ///
  /// In en, this message translates to:
  /// **'No emojis found.'**
  String get noEmojisFound;

  /// No description provided for @mySavedPresets.
  ///
  /// In en, this message translates to:
  /// **'MY SAVED PRESETS'**
  String get mySavedPresets;

  /// No description provided for @btnImport.
  ///
  /// In en, this message translates to:
  /// **'IMPORT'**
  String get btnImport;

  /// No description provided for @btnExportCaps.
  ///
  /// In en, this message translates to:
  /// **'EXPORT'**
  String get btnExportCaps;

  /// No description provided for @btnSaveCurrent.
  ///
  /// In en, this message translates to:
  /// **'SAVE CURRENT'**
  String get btnSaveCurrent;

  /// No description provided for @resetToDefault.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default'**
  String get resetToDefault;

  /// No description provided for @resetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will reset all caption styles to default. Cannot be undone.'**
  String get resetConfirmBody;

  /// No description provided for @btnReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get btnReset;

  /// No description provided for @wordHighlightBox.
  ///
  /// In en, this message translates to:
  /// **'Word Highlight Box'**
  String get wordHighlightBox;

  /// No description provided for @wordHighlightBoxDesc.
  ///
  /// In en, this message translates to:
  /// **'Colored pill background behind active spoken words'**
  String get wordHighlightBoxDesc;

  /// No description provided for @maxWordsPerChunk.
  ///
  /// In en, this message translates to:
  /// **'Max Words per Subtitle Chunk'**
  String get maxWordsPerChunk;

  /// No description provided for @maxCharsPerLine.
  ///
  /// In en, this message translates to:
  /// **'Max Characters per Subtitle Line'**
  String get maxCharsPerLine;

  /// No description provided for @fontSettings.
  ///
  /// In en, this message translates to:
  /// **'Font Settings'**
  String get fontSettings;

  /// No description provided for @colorSettings.
  ///
  /// In en, this message translates to:
  /// **'Color Settings'**
  String get colorSettings;

  /// No description provided for @borderSettings.
  ///
  /// In en, this message translates to:
  /// **'Border & Shadow Settings'**
  String get borderSettings;

  /// No description provided for @speechToTextTitle.
  ///
  /// In en, this message translates to:
  /// **'SPEECH-TO-TEXT TRANSCRIPTION'**
  String get speechToTextTitle;

  /// No description provided for @speechToTextDesc.
  ///
  /// In en, this message translates to:
  /// **'Re-run local Speech-to-Text transcription. Any manual edits or timing offsets will be replaced.'**
  String get speechToTextDesc;

  /// No description provided for @useLocalAi.
  ///
  /// In en, this message translates to:
  /// **'Use Local AI Transcription'**
  String get useLocalAi;

  /// No description provided for @runOnDeviceDesc.
  ///
  /// In en, this message translates to:
  /// **'Run speech-to-text directly on this device'**
  String get runOnDeviceDesc;

  /// No description provided for @offlineDemoModeActive.
  ///
  /// In en, this message translates to:
  /// **'Offline Demo mode is active. Local Whisper AI transcription is not supported on Web.'**
  String get offlineDemoModeActive;

  /// No description provided for @demoModeNote.
  ///
  /// In en, this message translates to:
  /// **'Demo mode instantly generates highly realistic transcript tokens. Perfect for testing styles, templates, and timeline operations without setup.'**
  String get demoModeNote;

  /// No description provided for @transcriptionQuality.
  ///
  /// In en, this message translates to:
  /// **'Transcription Quality'**
  String get transcriptionQuality;

  /// No description provided for @advancedSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced Settings'**
  String get advancedSettings;

  /// No description provided for @cpuThreadsLabel.
  ///
  /// In en, this message translates to:
  /// **'CPU Threads'**
  String get cpuThreadsLabel;

  /// No description provided for @vadSensitivity.
  ///
  /// In en, this message translates to:
  /// **'VAD Sensitivity'**
  String get vadSensitivity;

  /// No description provided for @translateToEnglish.
  ///
  /// In en, this message translates to:
  /// **'Translate captions to English'**
  String get translateToEnglish;

  /// No description provided for @startTranscriptionBtn.
  ///
  /// In en, this message translates to:
  /// **'START TRANSCRIPTION'**
  String get startTranscriptionBtn;

  /// No description provided for @hardwareLocked.
  ///
  /// In en, this message translates to:
  /// **'Hardware Locked'**
  String get hardwareLocked;

  /// No description provided for @btnDownload.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get btnDownload;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to CapStudio'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'High-precision captions and viral shorts, 100% offline.'**
  String get welcomeSubtitle;

  /// No description provided for @setupAssetDirTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Asset Directory'**
  String get setupAssetDirTitle;

  /// No description provided for @setupAssetDirDesc.
  ///
  /// In en, this message translates to:
  /// **'Select a directory to store models, fonts, and emoji packs.'**
  String get setupAssetDirDesc;

  /// No description provided for @downloadPacksTitle.
  ///
  /// In en, this message translates to:
  /// **'Download Content Packs (Optional)'**
  String get downloadPacksTitle;

  /// No description provided for @downloadPacksDesc.
  ///
  /// In en, this message translates to:
  /// **'Optional fonts and sound effects for your video projects.'**
  String get downloadPacksDesc;

  /// No description provided for @setupCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup Complete'**
  String get setupCompleteTitle;

  /// No description provided for @setupCompleteDesc.
  ///
  /// In en, this message translates to:
  /// **'You are ready to create stunning captioned videos.'**
  String get setupCompleteDesc;

  /// No description provided for @btnGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get btnGetStarted;

  /// No description provided for @btnNext.
  ///
  /// In en, this message translates to:
  /// **'NEXT'**
  String get btnNext;

  /// No description provided for @btnSkip.
  ///
  /// In en, this message translates to:
  /// **'SKIP'**
  String get btnSkip;

  /// No description provided for @onboardingFeaturePrivacy.
  ///
  /// In en, this message translates to:
  /// **'100% Privacy'**
  String get onboardingFeaturePrivacy;

  /// No description provided for @onboardingFeaturePrivacyDesc.
  ///
  /// In en, this message translates to:
  /// **'Your files never leave your device. All AI models run locally.'**
  String get onboardingFeaturePrivacyDesc;

  /// No description provided for @onboardingFeatureGpu.
  ///
  /// In en, this message translates to:
  /// **'GPU Accelerated Playback'**
  String get onboardingFeatureGpu;

  /// No description provided for @onboardingFeatureGpuDesc.
  ///
  /// In en, this message translates to:
  /// **'High performance video editing using hardware decoding.'**
  String get onboardingFeatureGpuDesc;

  /// No description provided for @onboardingFeatureAssets.
  ///
  /// In en, this message translates to:
  /// **'Offline Sidecar Assets'**
  String get onboardingFeatureAssets;

  /// No description provided for @onboardingFeatureAssetsDesc.
  ///
  /// In en, this message translates to:
  /// **'Download rich emoji packs once and run completely offline.'**
  String get onboardingFeatureAssetsDesc;

  /// No description provided for @onboardingReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re Ready to Roll!'**
  String get onboardingReadyTitle;

  /// No description provided for @onboardingConfigDetails.
  ///
  /// In en, this message translates to:
  /// **'Configuration Details:'**
  String get onboardingConfigDetails;

  /// No description provided for @btnLaunchCapStudio.
  ///
  /// In en, this message translates to:
  /// **'Launch CapStudio'**
  String get btnLaunchCapStudio;

  /// No description provided for @assetVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Asset verification failed. Please ensure assets downloaded properly.'**
  String get assetVerificationFailed;

  /// No description provided for @assetsFolderNotFound.
  ///
  /// In en, this message translates to:
  /// **'Assets Folder Not Found'**
  String get assetsFolderNotFound;

  /// No description provided for @assetsFolderNotFoundDesc.
  ///
  /// In en, this message translates to:
  /// **'CapStudio could not locate the assets folder at the configured location. If the folder is on an external drive, please connect it.'**
  String get assetsFolderNotFoundDesc;

  /// No description provided for @expectedPathLabel.
  ///
  /// In en, this message translates to:
  /// **'EXPECTED PATH:'**
  String get expectedPathLabel;

  /// No description provided for @browseNewLocation.
  ///
  /// In en, this message translates to:
  /// **'Browse New Location'**
  String get browseNewLocation;

  /// No description provided for @resetToDefaultPath.
  ///
  /// In en, this message translates to:
  /// **'Reset to Default Path'**
  String get resetToDefaultPath;

  /// No description provided for @retryVerification.
  ///
  /// In en, this message translates to:
  /// **'Retry Verification'**
  String get retryVerification;

  /// No description provided for @storagePathFolder.
  ///
  /// In en, this message translates to:
  /// **'Storage Path Folder'**
  String get storagePathFolder;

  /// No description provided for @tipWindowsDrive.
  ///
  /// In en, this message translates to:
  /// **'Tip: If C: drive is small, choose a path on D: or E: for more space.'**
  String get tipWindowsDrive;

  /// No description provided for @tipGeneralDrive.
  ///
  /// In en, this message translates to:
  /// **'Tip: You can select an external drive path if your root volume is full.'**
  String get tipGeneralDrive;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm Location'**
  String get confirmLocation;

  /// No description provided for @requiredBadge.
  ///
  /// In en, this message translates to:
  /// **'REQUIRED'**
  String get requiredBadge;

  /// No description provided for @emojiPacksHeader.
  ///
  /// In en, this message translates to:
  /// **'EMOJI PACKS'**
  String get emojiPacksHeader;

  /// No description provided for @fontPacksHeader.
  ///
  /// In en, this message translates to:
  /// **'FONT PACKS'**
  String get fontPacksHeader;

  /// No description provided for @connectCliTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Local CLI Tools'**
  String get connectCliTitle;

  /// No description provided for @connectCliDesc.
  ///
  /// In en, this message translates to:
  /// **'CapStudio needs whisper.cpp and FFmpeg binaries to perform transcription and export videos locally.'**
  String get connectCliDesc;

  /// No description provided for @skipSetup.
  ///
  /// In en, this message translates to:
  /// **'Skip setup for now'**
  String get skipSetup;

  /// No description provided for @btnValidate.
  ///
  /// In en, this message translates to:
  /// **'Validate'**
  String get btnValidate;

  /// No description provided for @autoDetectAndValidate.
  ///
  /// In en, this message translates to:
  /// **'Auto-detect & Validate'**
  String get autoDetectAndValidate;

  /// No description provided for @whisperCliPathLabel.
  ///
  /// In en, this message translates to:
  /// **'Whisper CLI Executable Path'**
  String get whisperCliPathLabel;

  /// No description provided for @ffmpegCliPathLabel.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg CLI Executable Path'**
  String get ffmpegCliPathLabel;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProject;

  /// No description provided for @searchProjects.
  ///
  /// In en, this message translates to:
  /// **'Search projects...'**
  String get searchProjects;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @sortByRecent.
  ///
  /// In en, this message translates to:
  /// **'Most Recent'**
  String get sortByRecent;

  /// No description provided for @sortByDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get sortByDuration;

  /// No description provided for @noMatchingProjects.
  ///
  /// In en, this message translates to:
  /// **'No projects match your search'**
  String get noMatchingProjects;

  /// No description provided for @btnEdit.
  ///
  /// In en, this message translates to:
  /// **'EDIT'**
  String get btnEdit;

  /// No description provided for @btnDuplicate.
  ///
  /// In en, this message translates to:
  /// **'DUPLICATE'**
  String get btnDuplicate;

  /// No description provided for @tooltipEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get tooltipEdit;

  /// No description provided for @tooltipRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get tooltipRename;

  /// No description provided for @tooltipDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get tooltipDuplicate;

  /// No description provided for @tooltipDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tooltipDelete;

  /// No description provided for @tooltipTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get tooltipTheme;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tooltipSettings;

  /// No description provided for @selectDemoFormat.
  ///
  /// In en, this message translates to:
  /// **'SELECT DEMO FORMAT'**
  String get selectDemoFormat;

  /// No description provided for @selectDemoDesc.
  ///
  /// In en, this message translates to:
  /// **'Select a layout format to preview CapStudio\'s high-fidelity caption engine, live word-level animations, and audio waveforms instantly.'**
  String get selectDemoDesc;

  /// No description provided for @landscapeDemo.
  ///
  /// In en, this message translates to:
  /// **'Landscape Demo'**
  String get landscapeDemo;

  /// No description provided for @landscapeDemoDesc.
  ///
  /// In en, this message translates to:
  /// **'Perfect for YouTube, desktop & presentations.'**
  String get landscapeDemoDesc;

  /// No description provided for @portraitDemo.
  ///
  /// In en, this message translates to:
  /// **'Portrait Demo'**
  String get portraitDemo;

  /// No description provided for @portraitDemoDesc.
  ///
  /// In en, this message translates to:
  /// **'Ideal for TikTok, Shorts, Reels & mobile.'**
  String get portraitDemoDesc;

  /// No description provided for @format16x9.
  ///
  /// In en, this message translates to:
  /// **'16:9 Format'**
  String get format16x9;

  /// No description provided for @format9x16.
  ///
  /// In en, this message translates to:
  /// **'9:16 Format'**
  String get format9x16;

  /// No description provided for @dropVideoHere.
  ///
  /// In en, this message translates to:
  /// **'DROP VIDEO HERE'**
  String get dropVideoHere;

  /// No description provided for @dropVideoSupported.
  ///
  /// In en, this message translates to:
  /// **'Supports MP4, MOV, AVI, etc.'**
  String get dropVideoSupported;

  /// No description provided for @statusLocalOffline.
  ///
  /// In en, this message translates to:
  /// **'LOCAL OFFLINE'**
  String get statusLocalOffline;

  /// No description provided for @speechModelTitle.
  ///
  /// In en, this message translates to:
  /// **'Speech Recognition Model'**
  String get speechModelTitle;

  /// No description provided for @hardwareUpgradesTitle.
  ///
  /// In en, this message translates to:
  /// **'Hardware Performance Upgrades'**
  String get hardwareUpgradesTitle;

  /// No description provided for @showAdvancedPaths.
  ///
  /// In en, this message translates to:
  /// **'SHOW ADVANCED PATH CONFIGURATION'**
  String get showAdvancedPaths;

  /// No description provided for @hideAdvancedPaths.
  ///
  /// In en, this message translates to:
  /// **'HIDE ADVANCED PATH CONFIGURATION'**
  String get hideAdvancedPaths;

  /// No description provided for @autoDownload.
  ///
  /// In en, this message translates to:
  /// **'AUTO DOWNLOAD'**
  String get autoDownload;

  /// No description provided for @gpuAcceleratedTranscription.
  ///
  /// In en, this message translates to:
  /// **'GPU Accelerated Transcription (CUDA)'**
  String get gpuAcceleratedTranscription;

  /// No description provided for @gpuRequiresNvidia.
  ///
  /// In en, this message translates to:
  /// **'Requires NVIDIA GPU with CUDA compatibility'**
  String get gpuRequiresNvidia;

  /// No description provided for @gpuExportEncoder.
  ///
  /// In en, this message translates to:
  /// **'GPU Export Encoder'**
  String get gpuExportEncoder;

  /// No description provided for @gpuExportEncoderDesc.
  ///
  /// In en, this message translates to:
  /// **'Hardware acceleration for MP4 video export'**
  String get gpuExportEncoderDesc;

  /// No description provided for @defaultLanguage.
  ///
  /// In en, this message translates to:
  /// **'Default Language'**
  String get defaultLanguage;

  /// No description provided for @vadTitle.
  ///
  /// In en, this message translates to:
  /// **'Voice Activity Detection (VAD)'**
  String get vadTitle;

  /// No description provided for @vadDesc.
  ///
  /// In en, this message translates to:
  /// **'Skips silent regions during processing'**
  String get vadDesc;

  /// No description provided for @vadThreshold.
  ///
  /// In en, this message translates to:
  /// **'VAD Threshold'**
  String get vadThreshold;

  /// No description provided for @autoSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic Auto-Save'**
  String get autoSaveTitle;

  /// No description provided for @autoSaveDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically save project edits to database every 3 seconds'**
  String get autoSaveDesc;

  /// No description provided for @defaultOutputsTitle.
  ///
  /// In en, this message translates to:
  /// **'Default Outputs'**
  String get defaultOutputsTitle;

  /// No description provided for @defaultExportFolder.
  ///
  /// In en, this message translates to:
  /// **'Default Export Folder'**
  String get defaultExportFolder;

  /// No description provided for @alwaysAskExportPath.
  ///
  /// In en, this message translates to:
  /// **'Always Ask for Export Path'**
  String get alwaysAskExportPath;

  /// No description provided for @alwaysAskExportPathDesc.
  ///
  /// In en, this message translates to:
  /// **'Prompts for output path on each export (Desktop)'**
  String get alwaysAskExportPathDesc;

  /// No description provided for @performanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performanceTitle;

  /// No description provided for @exportCpuThreads.
  ///
  /// In en, this message translates to:
  /// **'Export CPU Threads'**
  String get exportCpuThreads;

  /// No description provided for @exportCpuThreadsDesc.
  ///
  /// In en, this message translates to:
  /// **'Processor threads to use for rendering (Auto scales safely per device)'**
  String get exportCpuThreadsDesc;

  /// No description provided for @aboutAppSubtitle.
  ///
  /// In en, this message translates to:
  /// **'100% Offline, Privacy-First AI Captioning & Subtitle Studio'**
  String get aboutAppSubtitle;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open Source Licenses'**
  String get openSourceLicenses;

  /// No description provided for @openSourceComplianceDesc.
  ///
  /// In en, this message translates to:
  /// **'CapStudio relies on many other open-source libraries. A complete registry of all Dart packages, transitive dependencies, and full license texts is compiled below for legal store compliance.'**
  String get openSourceComplianceDesc;

  /// No description provided for @visitWebsite.
  ///
  /// In en, this message translates to:
  /// **'Visit Website'**
  String get visitWebsite;

  /// No description provided for @btnContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get btnContinue;

  /// No description provided for @btnBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get btnBack;

  /// No description provided for @editTiming.
  ///
  /// In en, this message translates to:
  /// **'Edit Timing'**
  String get editTiming;

  /// No description provided for @wordSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Word Settings'**
  String get wordSettingsTitle;

  /// No description provided for @emojiSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'EMOJI SETTINGS'**
  String get emojiSettingsTitle;

  /// No description provided for @changeEmojiTooltip.
  ///
  /// In en, this message translates to:
  /// **'Change Emoji'**
  String get changeEmojiTooltip;

  /// No description provided for @searchEmojisHint.
  ///
  /// In en, this message translates to:
  /// **'Search Emojis...'**
  String get searchEmojisHint;

  /// No description provided for @emojiPosX.
  ///
  /// In en, this message translates to:
  /// **'Emoji Position (X Offset: {offset}px)'**
  String emojiPosX(String offset);

  /// No description provided for @emojiPosY.
  ///
  /// In en, this message translates to:
  /// **'Emoji Position (Y Offset: {offset}px)'**
  String emojiPosY(String offset);

  /// No description provided for @emojiScale.
  ///
  /// In en, this message translates to:
  /// **'Emoji Scale ({scale}x)'**
  String emojiScale(String scale);

  /// No description provided for @emojiAnimSpeed.
  ///
  /// In en, this message translates to:
  /// **'Animation Speed ({speed}x)'**
  String emojiAnimSpeed(String speed);

  /// No description provided for @emojiStylePack.
  ///
  /// In en, this message translates to:
  /// **'Emoji Style / Pack'**
  String get emojiStylePack;

  /// No description provided for @selectStylePackTooltip.
  ///
  /// In en, this message translates to:
  /// **'Select Style Pack'**
  String get selectStylePackTooltip;

  /// No description provided for @selectEmojiTitle.
  ///
  /// In en, this message translates to:
  /// **'SELECT EMOJI'**
  String get selectEmojiTitle;

  /// No description provided for @stylePackLabel.
  ///
  /// In en, this message translates to:
  /// **'STYLE PACK'**
  String get stylePackLabel;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get searchHint;

  /// No description provided for @btnCreateProject.
  ///
  /// In en, this message translates to:
  /// **'CREATE PROJECT'**
  String get btnCreateProject;

  /// No description provided for @btnChooseFile.
  ///
  /// In en, this message translates to:
  /// **'CHOOSE FILE'**
  String get btnChooseFile;

  /// No description provided for @selectSubtitleFile.
  ///
  /// In en, this message translates to:
  /// **'Select Subtitle File'**
  String get selectSubtitleFile;

  /// No description provided for @selectTranscriptionQuality.
  ///
  /// In en, this message translates to:
  /// **'SELECT TRANSCRIPTION QUALITY'**
  String get selectTranscriptionQuality;

  /// No description provided for @translateToEnglishDesc.
  ///
  /// In en, this message translates to:
  /// **'Convert foreign speech directly into English subtitles'**
  String get translateToEnglishDesc;

  /// No description provided for @hardwareSettings.
  ///
  /// In en, this message translates to:
  /// **'HARDWARE & PERFORMANCE SETTINGS'**
  String get hardwareSettings;

  /// No description provided for @styleTemplatesHeader.
  ///
  /// In en, this message translates to:
  /// **'STYLE TEMPLATES'**
  String get styleTemplatesHeader;

  /// No description provided for @resetToDefaultStyle.
  ///
  /// In en, this message translates to:
  /// **'Reset to default style'**
  String get resetToDefaultStyle;

  /// No description provided for @resetStylingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Styling?'**
  String get resetStylingTitle;

  /// No description provided for @resetStylingDesc.
  ///
  /// In en, this message translates to:
  /// **'This will reset all caption styles to default. Cannot be undone.'**
  String get resetStylingDesc;

  /// No description provided for @sizeAndPosition.
  ///
  /// In en, this message translates to:
  /// **'SIZE & POSITION'**
  String get sizeAndPosition;

  /// No description provided for @verticalYPos.
  ///
  /// In en, this message translates to:
  /// **'Vertical Y Position (%)'**
  String get verticalYPos;

  /// No description provided for @fontConfigHeader.
  ///
  /// In en, this message translates to:
  /// **'FONT CONFIGURATION'**
  String get fontConfigHeader;

  /// No description provided for @fontFamilyLabel.
  ///
  /// In en, this message translates to:
  /// **'Font Family'**
  String get fontFamilyLabel;

  /// No description provided for @btnImportCustomFont.
  ///
  /// In en, this message translates to:
  /// **'IMPORT CUSTOM FONT (.ttf / .otf)'**
  String get btnImportCustomFont;

  /// No description provided for @fontWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Font Weight'**
  String get fontWeightLabel;

  /// No description provided for @textCaseLabel.
  ///
  /// In en, this message translates to:
  /// **'Text Case'**
  String get textCaseLabel;

  /// No description provided for @fontSizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Font Size'**
  String get fontSizeLabel;

  /// No description provided for @letterSpacingLabel.
  ///
  /// In en, this message translates to:
  /// **'Letter Spacing'**
  String get letterSpacingLabel;

  /// No description provided for @lineHeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Line Height'**
  String get lineHeightLabel;

  /// No description provided for @onboardingAppTagline.
  ///
  /// In en, this message translates to:
  /// **'100% Offline Local AI Caption Editor'**
  String get onboardingAppTagline;

  /// No description provided for @configLabelWhisperCli.
  ///
  /// In en, this message translates to:
  /// **'Whisper CLI'**
  String get configLabelWhisperCli;

  /// No description provided for @configValueDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo Mode (Mock)'**
  String get configValueDemoMode;

  /// No description provided for @configLabelFfmpegCli.
  ///
  /// In en, this message translates to:
  /// **'FFmpeg CLI'**
  String get configLabelFfmpegCli;

  /// No description provided for @configValueSystemPathDefault.
  ///
  /// In en, this message translates to:
  /// **'System PATH default'**
  String get configValueSystemPathDefault;

  /// No description provided for @configLabelAssetsLocation.
  ///
  /// In en, this message translates to:
  /// **'Assets Location'**
  String get configLabelAssetsLocation;

  /// No description provided for @filePickerAssetsDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select CapStudio Assets Folder'**
  String get filePickerAssetsDialogTitle;

  /// No description provided for @errorSelectFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to select folder: {error}'**
  String errorSelectFolderFailed(String error);

  /// No description provided for @errorResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to reset: {error}'**
  String errorResetFailed(String error);

  /// No description provided for @errorVerificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Verification failed: {error}'**
  String errorVerificationFailed(String error);

  /// No description provided for @errorAssetsFolderStillMissing.
  ///
  /// In en, this message translates to:
  /// **'Assets folder still not found at: {path}'**
  String errorAssetsFolderStillMissing(String path);

  /// No description provided for @dbRecoveredTitle.
  ///
  /// In en, this message translates to:
  /// **'Database Automatically Recovered'**
  String get dbRecoveredTitle;

  /// No description provided for @dbRecoveredBody.
  ///
  /// In en, this message translates to:
  /// **'A database schema mismatch or corruption was detected. The database was reset, and your previous data was backed up to:\n\n{backupPath}'**
  String dbRecoveredBody(String backupPath);

  /// No description provided for @errorDemoLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load demo video: {error}'**
  String errorDemoLoadFailed(String error);

  /// No description provided for @importProgressPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Completed'**
  String importProgressPercent(int percent);

  /// No description provided for @errorInvalidDropFileFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid file format. Please drop a video file.'**
  String get errorInvalidDropFileFormat;

  /// No description provided for @findTextLabel.
  ///
  /// In en, this message translates to:
  /// **'Find text'**
  String get findTextLabel;

  /// No description provided for @replaceWithLabel.
  ///
  /// In en, this message translates to:
  /// **'Replace with'**
  String get replaceWithLabel;

  /// No description provided for @findReplaceSuccessCount.
  ///
  /// In en, this message translates to:
  /// **'Replaced {count} occurrences!'**
  String findReplaceSuccessCount(int count);

  /// No description provided for @btnReplaceAll.
  ///
  /// In en, this message translates to:
  /// **'REPLACE ALL'**
  String get btnReplaceAll;

  /// No description provided for @errorVideoFileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Video file not found:\n{path}\nPlease re-link the video file.'**
  String errorVideoFileNotFound(String path);

  /// No description provided for @errorTranscriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Transcription failed. Please try again.'**
  String get errorTranscriptionFailed;

  /// No description provided for @transcriptionActiveModel.
  ///
  /// In en, this message translates to:
  /// **'Active: {quality} ({model})'**
  String transcriptionActiveModel(String quality, String model);

  /// No description provided for @badgeRecommended.
  ///
  /// In en, this message translates to:
  /// **'REC'**
  String get badgeRecommended;

  /// No description provided for @languageLabel.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageLabel;

  /// No description provided for @warningEnglishOnlyModel.
  ///
  /// In en, this message translates to:
  /// **'Warning: The selected model ({model}) is English-only. Transcribing in \"{language}\" will fail or produce English captions. Please select a Multilingual model (e.g. Tiny or Base).'**
  String warningEnglishOnlyModel(String model, String language);

  /// No description provided for @tipAutoDetectMixedLanguage.
  ///
  /// In en, this message translates to:
  /// **'Tip: Auto-detect is not recommended for mixed languages (like Hinglish). Explicitly selecting your spoken language (e.g. Hindi or English) will provide much more accurate captions.'**
  String get tipAutoDetectMixedLanguage;

  /// No description provided for @detectedHardwareLabel.
  ///
  /// In en, this message translates to:
  /// **'Detected System Hardware:'**
  String get detectedHardwareLabel;

  /// No description provided for @hardwareRamSize.
  ///
  /// In en, this message translates to:
  /// **'RAM Size: {ramGB} GB'**
  String hardwareRamSize(String ramGB);

  /// No description provided for @hardwareCpuCores.
  ///
  /// In en, this message translates to:
  /// **'CPU Logical Cores: {cores}'**
  String hardwareCpuCores(int cores);

  /// No description provided for @hardwareGpuDevice.
  ///
  /// In en, this message translates to:
  /// **'GPU Device: {gpu}'**
  String hardwareGpuDevice(String gpu);

  /// No description provided for @hardwareDetecting.
  ///
  /// In en, this message translates to:
  /// **'Detecting hardware stats...'**
  String get hardwareDetecting;

  /// No description provided for @btnStartReTranscribe.
  ///
  /// In en, this message translates to:
  /// **'START RE-TRANSCRIBE'**
  String get btnStartReTranscribe;

  /// No description provided for @btnImportSrtVtt.
  ///
  /// In en, this message translates to:
  /// **'IMPORT SRT/VTT FILE'**
  String get btnImportSrtVtt;

  /// No description provided for @importedSubtitleWords.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} words from subtitle file.'**
  String importedSubtitleWords(int count);

  /// No description provided for @errorImportSubtitleFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import subtitle file. Please check the file format.'**
  String get errorImportSubtitleFailed;

  /// No description provided for @noProjectLoaded.
  ///
  /// In en, this message translates to:
  /// **'No project loaded'**
  String get noProjectLoaded;

  /// No description provided for @badge916Vertical.
  ///
  /// In en, this message translates to:
  /// **'9:16 VERTICAL'**
  String get badge916Vertical;

  /// No description provided for @badge169Landscape.
  ///
  /// In en, this message translates to:
  /// **'16:9 LANDSCAPE'**
  String get badge169Landscape;

  /// No description provided for @reframeTargetCanvas.
  ///
  /// In en, this message translates to:
  /// **'Target canvas: 1080 × 1920 (TikTok, YouTube Shorts, Instagram Reels)'**
  String get reframeTargetCanvas;

  /// No description provided for @reframeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Reframe Mode:'**
  String get reframeModeLabel;

  /// No description provided for @reframeModeBlurPillarbox.
  ///
  /// In en, this message translates to:
  /// **'Blur Pillarbox (Recommended)'**
  String get reframeModeBlurPillarbox;

  /// No description provided for @reframeModeBlurPillarboxDesc.
  ///
  /// In en, this message translates to:
  /// **'Scales & blurs video in the background to fill 9:16, keeping the centered video crisp.'**
  String get reframeModeBlurPillarboxDesc;

  /// No description provided for @reframeModeCenterCrop.
  ///
  /// In en, this message translates to:
  /// **'Center Smart Crop'**
  String get reframeModeCenterCrop;

  /// No description provided for @reframeModeCenterCropDesc.
  ///
  /// In en, this message translates to:
  /// **'Fills the full 9:16 screen by cropping the left and right edges.'**
  String get reframeModeCenterCropDesc;

  /// No description provided for @reframeModeSplitScreen.
  ///
  /// In en, this message translates to:
  /// **'Split Screen / Dual Layer'**
  String get reframeModeSplitScreen;

  /// No description provided for @reframeModeSplitScreenDesc.
  ///
  /// In en, this message translates to:
  /// **'Stacks two video windows vertically (ideal for reactions and podcast dialogue).'**
  String get reframeModeSplitScreenDesc;

  /// No description provided for @btnResetTo169.
  ///
  /// In en, this message translates to:
  /// **'CURRENTLY 9:16 (RESET TO 16:9)'**
  String get btnResetTo169;

  /// No description provided for @btnSetCanvas916.
  ///
  /// In en, this message translates to:
  /// **'SET PROJECT CANVAS TO 9:16'**
  String get btnSetCanvas916;

  /// No description provided for @silenceRemovalDesc.
  ///
  /// In en, this message translates to:
  /// **'Automatically cuts out dead pauses and breathing gaps to maximize video retention.'**
  String get silenceRemovalDesc;

  /// No description provided for @silenceAggressivenessLabel.
  ///
  /// In en, this message translates to:
  /// **'Cut Aggressiveness:'**
  String get silenceAggressivenessLabel;

  /// No description provided for @silenceNoiseGateLabel.
  ///
  /// In en, this message translates to:
  /// **'Silence Noise Gate: {db} dB'**
  String silenceNoiseGateLabel(int db);

  /// No description provided for @silenceMinPauseLabel.
  ///
  /// In en, this message translates to:
  /// **'Min Pause: {duration}s'**
  String silenceMinPauseLabel(String duration);

  /// No description provided for @btnScanning.
  ///
  /// In en, this message translates to:
  /// **'SCANNING...'**
  String get btnScanning;

  /// No description provided for @silenceNoneFound.
  ///
  /// In en, this message translates to:
  /// **'No silence gaps found exceeding {duration}s.'**
  String silenceNoneFound(String duration);

  /// No description provided for @silenceFoundCount.
  ///
  /// In en, this message translates to:
  /// **'Found {count} silences ({totalSecs}s dead air saved)!'**
  String silenceFoundCount(int count, String totalSecs);

  /// No description provided for @errorScanningAudio.
  ///
  /// In en, this message translates to:
  /// **'Error scanning audio: {error}'**
  String errorScanningAudio(String error);

  /// No description provided for @jumpCutsApplied.
  ///
  /// In en, this message translates to:
  /// **'Applied {count} jump-cuts to project timeline!'**
  String jumpCutsApplied(int count);

  /// No description provided for @viralHooksDesc.
  ///
  /// In en, this message translates to:
  /// **'Scans transcription words for 80+ viral hooks, pacing (120–170 WPM), questions, energy density & clip boundaries.'**
  String get viralHooksDesc;

  /// No description provided for @btnAnalyzingTranscript.
  ///
  /// In en, this message translates to:
  /// **'ANALYZING TRANSCRIPT...'**
  String get btnAnalyzingTranscript;

  /// No description provided for @selectAllLabel.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAllLabel;

  /// No description provided for @selectedCountOf.
  ///
  /// In en, this message translates to:
  /// **'{selected} of {total} selected'**
  String selectedCountOf(int selected, int total);

  /// No description provided for @btnSelectClipsToBatchExport.
  ///
  /// In en, this message translates to:
  /// **'SELECT CLIPS TO BATCH EXPORT'**
  String get btnSelectClipsToBatchExport;

  /// No description provided for @btnBatchExportCount.
  ///
  /// In en, this message translates to:
  /// **'BATCH EXPORT {count} CLIP(S)'**
  String btnBatchExportCount(int count);

  /// No description provided for @viralNoClipsDetected.
  ///
  /// In en, this message translates to:
  /// **'No high-scoring viral clips detected in this video duration range.'**
  String get viralNoClipsDetected;

  /// No description provided for @badgeCleanCut.
  ///
  /// In en, this message translates to:
  /// **'CLEAN CUT'**
  String get badgeCleanCut;

  /// No description provided for @badgeFirst5s.
  ///
  /// In en, this message translates to:
  /// **'FIRST 5s'**
  String get badgeFirst5s;

  /// No description provided for @btnPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get btnPreview;

  /// No description provided for @btnTrim.
  ///
  /// In en, this message translates to:
  /// **'Trim'**
  String get btnTrim;

  /// No description provided for @tooltipForkAs916.
  ///
  /// In en, this message translates to:
  /// **'Fork as New 9:16 Short Project'**
  String get tooltipForkAs916;

  /// No description provided for @wpmLabelOk.
  ///
  /// In en, this message translates to:
  /// **'{wpm} WPM ✓'**
  String wpmLabelOk(int wpm);

  /// No description provided for @wpmLabelFast.
  ///
  /// In en, this message translates to:
  /// **'{wpm} WPM FAST'**
  String wpmLabelFast(int wpm);

  /// No description provided for @wpmLabelSlow.
  ///
  /// In en, this message translates to:
  /// **'{wpm} WPM SLOW'**
  String wpmLabelSlow(int wpm);

  /// No description provided for @hookScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Hook {score}/40'**
  String hookScoreLabel(int score);

  /// No description provided for @energyScoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Energy {score}/20'**
  String energyScoreLabel(int score);

  /// No description provided for @filePickerClipsFolderTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose folder to save clips'**
  String get filePickerClipsFolderTitle;

  /// No description provided for @errorChooseOutputFolderFirst.
  ///
  /// In en, this message translates to:
  /// **'Please choose an output folder first.'**
  String get errorChooseOutputFolderFirst;

  /// No description provided for @batchExportSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'BATCH EXPORT {count} CLIP(S)'**
  String batchExportSheetTitle(int count);

  /// No description provided for @tapToChooseOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose output folder…'**
  String get tapToChooseOutputFolder;

  /// No description provided for @burnCaptionsOnClipsLabel.
  ///
  /// In en, this message translates to:
  /// **'Burn Dynamic Captions on Clips'**
  String get burnCaptionsOnClipsLabel;

  /// No description provided for @burnCaptionsOnClipsDesc.
  ///
  /// In en, this message translates to:
  /// **'Burns styled animated subtitles synchronized to clip audio'**
  String get burnCaptionsOnClipsDesc;

  /// No description provided for @exportCancelledProgress.
  ///
  /// In en, this message translates to:
  /// **'Export cancelled. {done}/{total} done.'**
  String exportCancelledProgress(int done, int total);

  /// No description provided for @exportProgressSummary.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} exported · {failed} failed'**
  String exportProgressSummary(int done, int total, int failed);

  /// No description provided for @btnExporting.
  ///
  /// In en, this message translates to:
  /// **'EXPORTING…'**
  String get btnExporting;

  /// No description provided for @btnExportComplete.
  ///
  /// In en, this message translates to:
  /// **'EXPORT COMPLETE ✓'**
  String get btnExportComplete;

  /// No description provided for @btnStartExport.
  ///
  /// In en, this message translates to:
  /// **'START EXPORT'**
  String get btnStartExport;

  /// No description provided for @exportClipSavedAt.
  ///
  /// In en, this message translates to:
  /// **'✓ Saved: {path}'**
  String exportClipSavedAt(String path);

  /// No description provided for @projectTrimmedToClip.
  ///
  /// In en, this message translates to:
  /// **'Project trimmed to viral clip #{rank} ({start} - {end})!'**
  String projectTrimmedToClip(int rank, String start, String end);

  /// No description provided for @shortProjectCreated.
  ///
  /// In en, this message translates to:
  /// **'Created 9:16 Short: \"{name}\"'**
  String shortProjectCreated(String name);

  /// No description provided for @btnOpen.
  ///
  /// In en, this message translates to:
  /// **'OPEN'**
  String get btnOpen;

  /// No description provided for @errorCreateShortProjectFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create short project: {error}'**
  String errorCreateShortProjectFailed(String error);

  /// No description provided for @autoDetect.
  ///
  /// In en, this message translates to:
  /// **'Auto Detect'**
  String get autoDetect;

  /// No description provided for @presetSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved style preset \"{name}\" successfully!'**
  String presetSaved(String name);

  /// No description provided for @presetDeleted.
  ///
  /// In en, this message translates to:
  /// **'Preset deleted successfully.'**
  String get presetDeleted;

  /// No description provided for @presetExported.
  ///
  /// In en, this message translates to:
  /// **'Style presets exported successfully!'**
  String get presetExported;

  /// No description provided for @errorPresetExportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to export presets: {error}'**
  String errorPresetExportFailed(String error);

  /// No description provided for @presetImported.
  ///
  /// In en, this message translates to:
  /// **'Imported style presets successfully!'**
  String get presetImported;

  /// No description provided for @errorPresetImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to import presets: {error}'**
  String errorPresetImportFailed(String error);

  /// No description provided for @selectFontFileDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Select TTF or OTF Font File'**
  String get selectFontFileDialogTitle;

  /// No description provided for @fontWeightThin.
  ///
  /// In en, this message translates to:
  /// **'Thin'**
  String get fontWeightThin;

  /// No description provided for @fontWeightExtraLight.
  ///
  /// In en, this message translates to:
  /// **'Extra Light'**
  String get fontWeightExtraLight;

  /// No description provided for @fontWeightLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get fontWeightLight;

  /// No description provided for @fontWeightNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get fontWeightNormal;

  /// No description provided for @fontWeightMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get fontWeightMedium;

  /// No description provided for @fontWeightSemiBold.
  ///
  /// In en, this message translates to:
  /// **'Semi Bold'**
  String get fontWeightSemiBold;

  /// No description provided for @fontWeightBold.
  ///
  /// In en, this message translates to:
  /// **'Bold'**
  String get fontWeightBold;

  /// No description provided for @fontWeightExtraBold.
  ///
  /// In en, this message translates to:
  /// **'Extra Bold'**
  String get fontWeightExtraBold;

  /// No description provided for @fontWeightBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get fontWeightBlack;

  /// No description provided for @fontCaseNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get fontCaseNormal;

  /// No description provided for @fontCaseUppercase.
  ///
  /// In en, this message translates to:
  /// **'UPPERCASE'**
  String get fontCaseUppercase;

  /// No description provided for @fontCaseCapitalize.
  ///
  /// In en, this message translates to:
  /// **'Capitalize'**
  String get fontCaseCapitalize;

  /// No description provided for @strokeStyleThickOutline.
  ///
  /// In en, this message translates to:
  /// **'Thick Outline'**
  String get strokeStyleThickOutline;

  /// No description provided for @strokeStyleNoneFlat.
  ///
  /// In en, this message translates to:
  /// **'None (Flat)'**
  String get strokeStyleNoneFlat;

  /// No description provided for @shadowStyleSoft.
  ///
  /// In en, this message translates to:
  /// **'Soft Shadow'**
  String get shadowStyleSoft;

  /// No description provided for @shadowStyleNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get shadowStyleNone;

  /// No description provided for @animStyleActivePop.
  ///
  /// In en, this message translates to:
  /// **'Active Pop'**
  String get animStyleActivePop;

  /// No description provided for @animStyleActiveBounce.
  ///
  /// In en, this message translates to:
  /// **'Active Bounce Jump'**
  String get animStyleActiveBounce;

  /// No description provided for @animStyleKineticTilt.
  ///
  /// In en, this message translates to:
  /// **'Kinetic Bouncy Tilt'**
  String get animStyleKineticTilt;

  /// No description provided for @animStyleGlowPulse.
  ///
  /// In en, this message translates to:
  /// **'Glowing Active Pulse'**
  String get animStyleGlowPulse;

  /// No description provided for @animStyleWordReveal.
  ///
  /// In en, this message translates to:
  /// **'Word Reveal Stagger'**
  String get animStyleWordReveal;

  /// No description provided for @animStyleNoneStatic.
  ///
  /// In en, this message translates to:
  /// **'None (Static)'**
  String get animStyleNoneStatic;

  /// No description provided for @fontImportedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Successfully imported and applied custom font: \"{name}\"'**
  String fontImportedSuccess(String name);

  /// No description provided for @errorFontImportFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load font file. Invalid data.'**
  String get errorFontImportFailed;

  /// No description provided for @invalidTimingError.
  ///
  /// In en, this message translates to:
  /// **'Invalid start/end timings. Start must be >= 0, and end must be >= start and <= video duration.'**
  String get invalidTimingError;

  /// No description provided for @projectSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Project saved successfully.'**
  String get projectSavedSuccess;

  /// No description provided for @wordDeletedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Deleted word: \"{text}\"'**
  String wordDeletedSuccess(String text);

  /// No description provided for @splitClip.
  ///
  /// In en, this message translates to:
  /// **'Split clip'**
  String get splitClip;

  /// No description provided for @removeClip.
  ///
  /// In en, this message translates to:
  /// **'Remove clip'**
  String get removeClip;

  /// No description provided for @resetToOriginal.
  ///
  /// In en, this message translates to:
  /// **'Reset to original'**
  String get resetToOriginal;

  /// No description provided for @splitTimelineAt.
  ///
  /// In en, this message translates to:
  /// **'Split timeline at {time}s.'**
  String splitTimelineAt(String time);

  /// No description provided for @splitTimelineError.
  ///
  /// In en, this message translates to:
  /// **'Playhead must be inside the active region to split.'**
  String get splitTimelineError;

  /// No description provided for @exclusionToggled.
  ///
  /// In en, this message translates to:
  /// **'Toggled segment exclusion under playhead.'**
  String get exclusionToggled;

  /// No description provided for @splitsReset.
  ///
  /// In en, this message translates to:
  /// **'Reset all timeline splits and exclusions.'**
  String get splitsReset;

  /// No description provided for @shareVideo.
  ///
  /// In en, this message translates to:
  /// **'Share Video'**
  String get shareVideo;

  /// No description provided for @openOutputFolder.
  ///
  /// In en, this message translates to:
  /// **'Open output folder'**
  String get openOutputFolder;

  /// No description provided for @errorLogCopied.
  ///
  /// In en, this message translates to:
  /// **'Error log copied to clipboard.'**
  String get errorLogCopied;

  /// No description provided for @diagnosticsExported.
  ///
  /// In en, this message translates to:
  /// **'Filtered diagnostic report opened in share sheet.'**
  String get diagnosticsExported;

  /// No description provided for @errorDiagnosticsFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to export diagnostics report: {error}'**
  String errorDiagnosticsFailed(String error);

  /// No description provided for @logLineCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied log line to clipboard: \"{message}\"'**
  String logLineCopied(String message);

  /// No description provided for @commandCopied.
  ///
  /// In en, this message translates to:
  /// **'Copied: \"{command}\"'**
  String commandCopied(String command);

  /// No description provided for @settingsRestored.
  ///
  /// In en, this message translates to:
  /// **'Settings restored to defaults.'**
  String get settingsRestored;

  /// No description provided for @gpuEncoderNoneCpu.
  ///
  /// In en, this message translates to:
  /// **'None (CPU)'**
  String get gpuEncoderNoneCpu;

  /// No description provided for @gpuEncoderNvidia.
  ///
  /// In en, this message translates to:
  /// **'NVIDIA NVENC'**
  String get gpuEncoderNvidia;

  /// No description provided for @gpuEncoderAmd.
  ///
  /// In en, this message translates to:
  /// **'AMD AMF'**
  String get gpuEncoderAmd;

  /// No description provided for @gpuEncoderIntel.
  ///
  /// In en, this message translates to:
  /// **'Intel QSV'**
  String get gpuEncoderIntel;

  /// No description provided for @gpuEncoderApple.
  ///
  /// In en, this message translates to:
  /// **'Apple VideoToolbox'**
  String get gpuEncoderApple;

  /// No description provided for @btnDownloadVcRedist.
  ///
  /// In en, this message translates to:
  /// **'DOWNLOAD VC++ REDISTRIBUTABLE'**
  String get btnDownloadVcRedist;

  /// No description provided for @errorDownloadToolFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download tool: {error}'**
  String errorDownloadToolFailed(String error);

  /// No description provided for @errorFolderNotAccessible.
  ///
  /// In en, this message translates to:
  /// **'Selected folder does not exist or is not accessible.'**
  String get errorFolderNotAccessible;

  /// No description provided for @modelDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted model: {name}'**
  String modelDeleted(String name);

  /// No description provided for @errorModelDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete model: {error}'**
  String errorModelDeleteFailed(String error);

  /// No description provided for @errorModelDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download model {name}: {error}'**
  String errorModelDownloadFailed(String name, String error);

  /// No description provided for @errorOpenFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open folder automatically. Path: {path}'**
  String errorOpenFolderFailed(String path);

  /// No description provided for @errorDownloadPackFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download pack: {error}'**
  String errorDownloadPackFailed(String error);

  /// No description provided for @errorPackDownloadNamedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download pack {name}: {error}'**
  String errorPackDownloadNamedFailed(String name, String error);

  /// No description provided for @stickersIndexRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Custom stickers index refreshed successfully!'**
  String get stickersIndexRefreshed;

  /// No description provided for @errorChangeAssetFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to change assets folder: {error}'**
  String errorChangeAssetFolderFailed(String error);

  /// No description provided for @errorSetAssetFolderFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to set assets folder: {error}'**
  String errorSetAssetFolderFailed(String error);

  /// No description provided for @warningNoAvx.
  ///
  /// In en, this message translates to:
  /// **'Missing AVX support detected! Downloading compatible whisper-cli (no-AVX)...'**
  String get warningNoAvx;

  /// No description provided for @errorAutoDetectWhisper.
  ///
  /// In en, this message translates to:
  /// **'Could not auto-detect whisper-cli. Please browse manually.'**
  String get errorAutoDetectWhisper;

  /// No description provided for @errorAutoDetectFfmpeg.
  ///
  /// In en, this message translates to:
  /// **'Could not auto-detect ffmpeg. Please browse manually.'**
  String get errorAutoDetectFfmpeg;

  /// No description provided for @errorToolDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download tool: {error}'**
  String errorToolDownloadFailed(String error);

  /// No description provided for @returnToDashboard.
  ///
  /// In en, this message translates to:
  /// **'Return to Dashboard'**
  String get returnToDashboard;

  /// No description provided for @errorImportVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String errorImportVideoFailed(String error);

  /// No description provided for @videoRelinkedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Video relinked successfully!'**
  String get videoRelinkedSuccess;

  /// No description provided for @errorRelinkVideoFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to relink video.'**
  String get errorRelinkVideoFailed;

  /// No description provided for @retranscriptionSuccess.
  ///
  /// In en, this message translates to:
  /// **'Re-transcription successful!'**
  String get retranscriptionSuccess;

  /// No description provided for @retranscriptionFailed.
  ///
  /// In en, this message translates to:
  /// **'Re-transcription failed.'**
  String get retranscriptionFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'ar',
        'de',
        'en',
        'es',
        'fr',
        'hi',
        'ja',
        'ko',
        'pt',
        'ru',
        'tr',
        'zh'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
