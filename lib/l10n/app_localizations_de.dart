// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appName => 'CapStudio';

  @override
  String get dashboardTitle => 'Meine Projekte';

  @override
  String get dashboardSubtitle =>
      'Offline-Studio für KI-Untertitelung und Transkription';

  @override
  String get importVideo => 'Video importieren';

  @override
  String get dragDropText => 'Ziehen Sie Ihre Videodatei hierher';

  @override
  String get clickBrowse =>
      'oder klicken Sie, um lokale Dateien zu durchsuchen';

  @override
  String get demoMode => 'DEMO-MODUS';

  @override
  String get demoModeDesc =>
      'Laden Sie ein Demoprojekt, um Stile und Editor-Funktionen auszuprobieren.';

  @override
  String get warningAssets =>
      'Wiederherstellung des Asset-Ordners erforderlich';

  @override
  String get warningAssetsDesc =>
      'Die integrierten Assets wurden im Anwendungs-Supportordner nicht gefunden. Doppelklicken Sie hier, um sie wiederherzustellen oder das Verzeichnis zu ändern.';

  @override
  String get deleteProjectTitle => 'Projekt löschen';

  @override
  String deleteProjectConfirm(String projectName) {
    return 'Sind Sie sicher, dass Sie \"$projectName\" dauerhaft löschen möchten? Diese Aktion kann nicht rückgängig gemacht werden.';
  }

  @override
  String get renameProjectTitle => 'Projekt umbenennen';

  @override
  String get projectNameLabel => 'Projektname';

  @override
  String get btnCancel => 'ABBRECHEN';

  @override
  String get btnDelete => 'LÖSCHEN';

  @override
  String get btnRename => 'UMBENENNEN';

  @override
  String get btnSave => 'SPEICHERN';

  @override
  String get btnConfirm => 'BESTÄTIGEN';

  @override
  String get btnExport => 'EXPORTIEREN';

  @override
  String get btnUndo => 'Rückgängig';

  @override
  String get btnRedo => 'Wiederholen';

  @override
  String get statusDraft => 'Entwurf';

  @override
  String get statusCompleted => 'Abgeschlossen';

  @override
  String get createdLabel => 'Erstellt am:';

  @override
  String get durationLabel => 'Dauer:';

  @override
  String get statusLabel => 'Status:';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingsGeneral => 'Allgemeine Einstellungen';

  @override
  String get settingsTheme => 'App-Design';

  @override
  String get themeSystem => 'Systemstandard';

  @override
  String get themeLight => 'Hell-Modus';

  @override
  String get themeDark => 'Dunkel-Modus';

  @override
  String get settingsLanguage => 'Oberflächensprache';

  @override
  String get settingsTranscription => 'Transkriptionseinstellungen';

  @override
  String get settingsWhisperModel => 'Whisper-Modell';

  @override
  String get settingsWhisperModelDesc =>
      'Wählen Sie ein Modell für die Transkription. Kleinere sind schneller, größere sind genauer.';

  @override
  String get settingsTranscribeLang => 'Transkriptionssprache';

  @override
  String get settingsAutoDetect => 'Sprache automatisch erkennen';

  @override
  String get settingsGPU => 'GPU-Beschleunigung (CUDA)';

  @override
  String get settingsVAD => 'VAD-Schwellenwert (Sprachaktivität)';

  @override
  String get settingsExport => 'Exporteinstellungen';

  @override
  String get settingsExportDest => 'Standardmäßiges Exportverzeichnis';

  @override
  String get settingsBrowse => 'Durchsuchen';

  @override
  String get settingsEmojiPacks => 'Emoji- und Stil-Pakete';

  @override
  String get settingsEmojiPacksDesc =>
      'Passen Sie Emoji-Rendering-Stile und aktive Untertiteldateien an.';

  @override
  String get settingsEmojiSearchLang => 'Emoji-Suchsprache';

  @override
  String get settingsBtnManagePacks => 'EMOJI-PAKETE VERWALTEN';

  @override
  String get systemTitle => 'Systeminformationen';

  @override
  String get systemVersion => 'Version';

  @override
  String get systemReset => 'Standardeinstellungen wiederherstellen';

  @override
  String get editorTabCaptions => 'Untertitel';

  @override
  String get editorTabStyles => 'Stile';

  @override
  String get editorTabTrim => 'Schneiden';

  @override
  String get editorTabAudio => 'Audio';

  @override
  String get editorTabTranscription => 'Transkription';

  @override
  String get editorTabShortcuts => 'Tastaturkürzel';

  @override
  String get editorTabDebug => 'Debuggen';

  @override
  String get editorHeaderBack => 'Zurück';

  @override
  String get editorKeyboardShortcuts => 'Tastaturkurzbefehle';

  @override
  String get dialogAnalyzing => 'Video wird analysiert...';

  @override
  String get dialogTranscribing => 'Audio wird transkribiert...';

  @override
  String get dialogExtracting => 'Audio wird extrahiert...';

  @override
  String get dialogWait => 'Dies kann einen Moment dauern. Bitte warten.';

  @override
  String get dialogError => 'Fehler';

  @override
  String get dialogImportFailed => 'Video konnte nicht importiert werden.';

  @override
  String get noProjects => 'Noch keine Projekte erstellt';

  @override
  String get aboutApp => 'Über CapStudio';

  @override
  String get aboutAppDesc =>
      'Informationen über CapStudio, Credits und Open-Source-Lizenzen.';

  @override
  String get aboutAppThanks =>
      'Besonderer Dank geht an die Open-Source-Projekte, die CapStudio ermöglichen:';

  @override
  String get btnViewAllLicenses => 'ALLE PAKETLIZENZEN ANZEIGEN';
}
