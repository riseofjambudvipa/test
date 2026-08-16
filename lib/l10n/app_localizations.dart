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
  /// **'Import Video'**
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
  /// **'EXPORT'**
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
  /// **'App Theme Theme'**
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
