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

  @override
  String get exportBurnIn => 'VIDEOEXPORT MIT EINGEBRANNTEN UNTERTITELN';

  @override
  String get exportTimecodeFormats => 'ZEITCODE-UNTERITELFORMATE';

  @override
  String get exportWebEnabled =>
      'Der clientseitige Videoexport ist aktiviert. Das Rendering läuft lokal in Ihrem Browser.';

  @override
  String get exportWebCaptionOnly =>
      'Der Webexport enthält derzeit nur Untertitel – Emojis und Soundeffekte werden noch nicht in das Video eingebrannt. Exportieren Sie über die Desktop- oder Mobile-App, um das vollständige Ergebnis zu erhalten.';

  @override
  String get exportOutputName => 'Name des Ausgabevideos';

  @override
  String get exportMode => 'Exportmodus';

  @override
  String get exportModeFast => 'Schnell (Natives FFmpeg)';

  @override
  String get exportModeFastUnsupported =>
      'Schnell (Natives FFmpeg) ⚠️ Nicht unterstützt';

  @override
  String get exportModeSlow => 'Langsam (1:1-Vorschau-Render)';

  @override
  String get exportTargetFps => 'Ziel-FPS';

  @override
  String get exportFps24 => '24 FPS (Film)';

  @override
  String get exportFps25 => '25 FPS (PAL)';

  @override
  String get exportFps30 => '30 FPS (Standard)';

  @override
  String get exportFps50 => '50 FPS';

  @override
  String get exportFps60 => '60 FPS (Flüssig)';

  @override
  String get exportFastUnsupported =>
      'Der Schnellmodus wird auf diesem Gerät nicht unterstützt, da die System-FFmpeg-Version keine Untertitel-Rendering-Filter (libass) enthält. Der langsame Modus wird stattdessen verwendet.';

  @override
  String get exportSlowInfo =>
      'Erfasst jeden Frame exakt so, wie er in der Vorschau angezeigt wird. Dies garantiert pixelgenaue Untertitel, rendert aber langsamer.';

  @override
  String get exportDestDirectory => 'ZIELVERZEICHNIS';

  @override
  String get exportDestBrowser => 'Download-Speicherort des Browsers';

  @override
  String get exportDestAndroid =>
      'Downloads-Ordner (/storage/emulated/0/Download)';

  @override
  String get exportDestIos => 'App-Dokumente (Freigabeblatt nach dem Export)';

  @override
  String get exportChooseFolder => 'Ausgabeordner auswählen';

  @override
  String get exportStartMp4 => 'MP4-EXPORT STARTEN';

  @override
  String get exportSrtTitle => 'SubRip-Untertitel (.srt)';

  @override
  String get exportSrtDesc =>
      'Universeller Standard mit Zeitcodes. Kompatibel mit YouTube, VLC und Premiere Pro.';

  @override
  String get exportVttTitle => 'WebVTT-Untertitel (.vtt)';

  @override
  String get exportVttDesc =>
      'Weboptimiertes Untertitelformat, das häufig in HTML5-Playern und beim Online-Streaming verwendet wird.';

  @override
  String get exportAssTitle => 'Advanced SubStation Alpha (.ass)';

  @override
  String get exportAssDesc =>
      'Professionelles Format mit Schriftgrößen, Stilen, Rändern und Inline-Hervorhebungen.';

  @override
  String get exportTxtTitle => 'Reines Text-Transkript (.txt)';

  @override
  String get exportTxtDesc =>
      'Zeilenweises Transkript mit Zeitstempel-Präfixen.';

  @override
  String exportSuccess(String type) {
    return '$type erfolgreich exportiert!';
  }

  @override
  String get exportNoLocation =>
      'Kein Speicherort ausgewählt. Bitte wählen Sie einen Dateipfad.';

  @override
  String get exportNoLocationCancelled =>
      'Kein Speicherort ausgewählt. Export abgebrochen.';

  @override
  String exportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get exportCopySrtTooltip => 'SRT in die Zwischenablage kopieren';

  @override
  String get exportCopiedSrt => 'SRT in die Zwischenablage kopiert!';

  @override
  String exportCopyFailedSrt(String error) {
    return 'SRT konnte nicht kopiert werden: $error';
  }

  @override
  String exportSubtitlesDialogTitle(String type) {
    return '$type-Untertitel exportieren';
  }

  @override
  String get exportVideoDialogTitle => 'Video als MP4 exportieren';

  @override
  String get ffmpegRequiredTitle => 'FFmpeg erforderlich';

  @override
  String get ffmpegRequiredBody =>
      'Zum Einbrennen von Untertiteln in eine Videodatei ist eine lokale FFmpeg-Installation erforderlich.\n\nBitte konfigurieren Sie den FFmpeg-Pfad in den Einstellungen.';

  @override
  String get okLabel => 'OK';

  @override
  String get exportWebTitle => 'Video wird exportiert (clientseitig)';

  @override
  String exportWebSuccess(String fileName) {
    return 'Video erfolgreich als $fileName exportiert!';
  }

  @override
  String exportWebFailed(String error) {
    return 'Rendering fehlgeschlagen: $error';
  }

  @override
  String get viralShortsTitle => 'VIRAL SHORTS STUDIO';

  @override
  String get viralShortsSubtitle =>
      'Vertikales 9:16-Reframe, Stille-Jump-Cuts & KI-Hook-Detektor';

  @override
  String get viralReframeTitle => '1. VERTIKALES 9:16-REFRAME';

  @override
  String get viralSilenceTitle => '2. STILLE ENTFERNEN (JUMP-CUTS)';

  @override
  String get viralHooksTitle => '3. KI-DETEKTOR FÜR VIRALE HOOKS';

  @override
  String get btnFindViralMoments => 'VIRALE MOMENTE FINDEN';

  @override
  String get btnScanSilences => 'NACH STILLE SUCHEN';

  @override
  String get btnApplyJumpCuts => 'JUMP-CUTS ANWENDEN';

  @override
  String get editorTabShorts => 'Shorts';

  @override
  String get editorTabClips => 'Clips';

  @override
  String get captionList => 'UNTERTITELLISTE';

  @override
  String get uncertainLabel => 'Unsicher (<40 %)';

  @override
  String get mediumConfidenceLabel => 'Mittel (40-60 %)';

  @override
  String get jumpToUncertain => 'Zum nächsten unsicheren Wort springen';

  @override
  String get noUncertainWords => 'Keine unsicheren Wörter gefunden.';

  @override
  String get findAndReplace => 'Suchen & Ersetzen';

  @override
  String get addWordTitle => 'Wort hinzufügen';

  @override
  String get editWordTitle => 'Wort bearbeiten';

  @override
  String get wordTextLabel => 'Worttext';

  @override
  String get startTimeLabel => 'Startzeit (s)';

  @override
  String get endTimeLabel => 'Endzeit (s)';

  @override
  String get splitChunk => 'Segment teilen';

  @override
  String get insertLineAfter => 'Zeile danach einfügen';

  @override
  String get duplicateLine => 'Zeile duplizieren';

  @override
  String get deleteLine => 'Zeile löschen';

  @override
  String get chooseSfxTitle => 'Soundeffekt auswählen';

  @override
  String get searchSfxPlaceholder => 'Soundeffekte suchen...';

  @override
  String get noSfxFound => 'Keine Soundeffekte gefunden';

  @override
  String get emojiSearch => 'Emoji-Suche';

  @override
  String get noEmojisFound => 'Keine Emojis gefunden.';

  @override
  String get mySavedPresets => 'MEINE GESPEICHERTEN VORLAGEN';

  @override
  String get btnImport => 'IMPORTIEREN';

  @override
  String get btnExportCaps => 'EXPORTIEREN';

  @override
  String get btnSaveCurrent => 'AKTUELLEN SPEICHERN';

  @override
  String get resetToDefault => 'Auf Standard zurücksetzen';

  @override
  String get resetConfirmBody =>
      'Dadurch werden alle Untertitelstile auf die Standardeinstellungen zurückgesetzt. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get btnReset => 'Zurücksetzen';

  @override
  String get wordHighlightBox => 'Wort-Hervorhebungsbox';

  @override
  String get wordHighlightBoxDesc =>
      'Farbiger Pillen-Hintergrund hinter aktiv gesprochenen Wörtern';

  @override
  String get maxWordsPerChunk => 'Max. Wörter pro Untertitelsegment';

  @override
  String get maxCharsPerLine => 'Max. Zeichen pro Untertitelzeile';

  @override
  String get fontSettings => 'Schrifteinstellungen';

  @override
  String get colorSettings => 'Farbeinstellungen';

  @override
  String get borderSettings => 'Rahmen- & Schatteneinstellungen';

  @override
  String get speechToTextTitle => 'SPRACHE-ZU-TEXT-TRANSKRIPTION';

  @override
  String get speechToTextDesc =>
      'Lokale Sprache-zu-Text-Transkription erneut ausführen. Alle manuellen Änderungen oder Zeitkorrekturen werden überschrieben.';

  @override
  String get useLocalAi => 'Lokale KI-Transkription verwenden';

  @override
  String get runOnDeviceDesc =>
      'Sprache-zu-Text direkt auf diesem Gerät ausführen';

  @override
  String get offlineDemoModeActive =>
      'Offline-Demomodus ist aktiv. Lokale Whisper-KI-Transkription wird im Web nicht unterstützt.';

  @override
  String get demoModeNote =>
      'Der Demomodus erzeugt sofort hochrealistische Transkriptionstoken. Perfekt zum Testen von Stilen, Vorlagen und Timeline-Aktionen ohne vorherige Einrichtung.';

  @override
  String get transcriptionQuality => 'Transkriptionsqualität';

  @override
  String get advancedSettings => 'Erweiterte Einstellungen';

  @override
  String get cpuThreadsLabel => 'CPU-Threads';

  @override
  String get vadSensitivity => 'VAD-Empfindlichkeit';

  @override
  String get translateToEnglish => 'Untertitel ins Englische übersetzen';

  @override
  String get startTranscriptionBtn => 'TRANSKRIPTION STARTEN';

  @override
  String get hardwareLocked => 'Hardware gesperrt';

  @override
  String get btnDownload => 'Herunterladen';

  @override
  String get welcomeTitle => 'Willkommen bei CapStudio';

  @override
  String get welcomeSubtitle =>
      'Hochpräzise Untertitel und virale Shorts, 100 % offline.';

  @override
  String get setupAssetDirTitle => 'Asset-Verzeichnis auswählen';

  @override
  String get setupAssetDirDesc =>
      'Wählen Sie ein Verzeichnis zum Speichern von Modellen, Schriftarten und Emoji-Paketen.';

  @override
  String get downloadPacksTitle => 'Inhaltspakete herunterladen (Optional)';

  @override
  String get downloadPacksDesc =>
      'Optionale Schriftarten und Soundeffekte für Ihre Videoprojekte.';

  @override
  String get setupCompleteTitle => 'Einrichtung abgeschlossen';

  @override
  String get setupCompleteDesc =>
      'Sie sind bereit, beeindruckende Videos mit Untertiteln zu erstellen.';

  @override
  String get btnGetStarted => 'Loslegen';

  @override
  String get btnNext => 'WEITER';

  @override
  String get btnSkip => 'ÜBERSPRINGEN';

  @override
  String get onboardingFeaturePrivacy => '100 % Datenschutz';

  @override
  String get onboardingFeaturePrivacyDesc =>
      'Ihre Dateien verlassen niemals Ihr Gerät. Alle KI-Modelle laufen lokal.';

  @override
  String get onboardingFeatureGpu => 'GPU-beschleunigte Wiedergabe';

  @override
  String get onboardingFeatureGpuDesc =>
      'Hochleistungs-Videobearbeitung mit Hardware-Dekodierung.';

  @override
  String get onboardingFeatureAssets => 'Offline-Sidecar-Assets';

  @override
  String get onboardingFeatureAssetsDesc =>
      'Laden Sie umfangreiche Emoji-Pakete einmal herunter und nutzen Sie diese komplett offline.';

  @override
  String get onboardingReadyTitle => 'Sie können loslegen!';

  @override
  String get onboardingConfigDetails => 'Konfigurationsdetails:';

  @override
  String get btnLaunchCapStudio => 'CapStudio starten';

  @override
  String get assetVerificationFailed =>
      'Asset-Überprüfung fehlgeschlagen. Bitte stellen Sie sicher, dass die Assets ordnungsgemäß heruntergeladen wurden.';

  @override
  String get assetsFolderNotFound => 'Asset-Ordner nicht gefunden';

  @override
  String get assetsFolderNotFoundDesc =>
      'CapStudio konnte den Asset-Ordner am konfigurierten Speicherort nicht finden. Falls sich der Ordner auf einem externen Laufwerk befindet, schließen Sie dieses bitte an.';

  @override
  String get expectedPathLabel => 'ERWARTETER PFAD:';

  @override
  String get browseNewLocation => 'Neuen Speicherort durchsuchen';

  @override
  String get resetToDefaultPath => 'Auf Standardpfad zurücksetzen';

  @override
  String get retryVerification => 'Überprüfung wiederholen';

  @override
  String get storagePathFolder => 'Speicherpfad-Ordner';

  @override
  String get tipWindowsDrive =>
      'Tipp: Wenn Laufwerk C: klein ist, wählen Sie einen Pfad auf D: oder E: für mehr Speicherplatz.';

  @override
  String get tipGeneralDrive =>
      'Tipp: Sie können einen Pfad auf einem externen Laufwerk wählen, wenn Ihr Hauptlaufwerk voll ist.';

  @override
  String get confirmLocation => 'Speicherort bestätigen';

  @override
  String get requiredBadge => 'ERFORDERLICH';

  @override
  String get emojiPacksHeader => 'EMOJI-PAKETE';

  @override
  String get fontPacksHeader => 'SCHRIFTARTEN-PAKETE';

  @override
  String get connectCliTitle => 'Lokale CLI-Tools verbinden';

  @override
  String get connectCliDesc =>
      'CapStudio benötigt die Binärdateien whisper.cpp und FFmpeg, um Transkriptionen und Videoexporte lokal durchzuführen.';

  @override
  String get skipSetup => 'Einrichtung vorerst überspringen';

  @override
  String get btnValidate => 'Validieren';

  @override
  String get autoDetectAndValidate => 'Automatisch erkennen & validieren';

  @override
  String get whisperCliPathLabel =>
      'Pfad zur ausführbaren Datei von Whisper CLI';

  @override
  String get ffmpegCliPathLabel => 'Pfad zur ausführbaren Datei von FFmpeg CLI';

  @override
  String get newProject => 'Neues Projekt';

  @override
  String get searchProjects => 'Projekte suchen...';

  @override
  String get filterAll => 'Alle';

  @override
  String get sortByRecent => 'Zuletzt verwendet';

  @override
  String get sortByDuration => 'Dauer';

  @override
  String get noMatchingProjects => 'Keine Projekte entsprechen Ihrer Suche';

  @override
  String get btnEdit => 'BEARBEITEN';

  @override
  String get btnDuplicate => 'DUPLIZIEREN';

  @override
  String get tooltipEdit => 'Bearbeiten';

  @override
  String get tooltipRename => 'Umbenennen';

  @override
  String get tooltipDuplicate => 'Duplizieren';

  @override
  String get tooltipDelete => 'Löschen';

  @override
  String get tooltipTheme => 'Design';

  @override
  String get tooltipSettings => 'Einstellungen';

  @override
  String get selectDemoFormat => 'DEMO-FORMAT AUSWÄHLEN';

  @override
  String get selectDemoDesc =>
      'Wählen Sie ein Layout-Format, um die hochpräzise Untertitel-Engine, Live-Wortanimationen und Audio-Wellenformen von CapStudio sofort zu testen.';

  @override
  String get landscapeDemo => 'Querformat-Demo';

  @override
  String get landscapeDemoDesc =>
      'Perfekt für YouTube, Desktop & Präsentationen.';

  @override
  String get portraitDemo => 'Hochformat-Demo';

  @override
  String get portraitDemoDesc =>
      'Ideal für TikTok, Shorts, Reels & Mobilgeräte.';

  @override
  String get format16x9 => '16:9-Format';

  @override
  String get format9x16 => '9:16-Format';

  @override
  String get dropVideoHere => 'VIDEO HIER ABLEGEN';

  @override
  String get dropVideoSupported => 'Unterstützt MP4, MOV, AVI usw.';

  @override
  String get statusLocalOffline => 'LOKAL OFFLINE';

  @override
  String get speechModelTitle => 'Spracherkennungsmodell';

  @override
  String get hardwareUpgradesTitle => 'Hardware-Leistungsupgrades';

  @override
  String get showAdvancedPaths => 'ERWEITERTE PFADKONFIGURATION ANZEIGEN';

  @override
  String get hideAdvancedPaths => 'ERWEITERTE PFADKONFIGURATION AUSBLENDEN';

  @override
  String get autoDownload => 'AUTOMATISCHER DOWNLOAD';

  @override
  String get gpuAcceleratedTranscription =>
      'GPU-beschleunigte Transkription (CUDA)';

  @override
  String get gpuRequiresNvidia =>
      'Erfordert eine NVIDIA-GPU mit CUDA-Kompatibilität';

  @override
  String get gpuExportEncoder => 'GPU-Export-Encoder';

  @override
  String get gpuExportEncoderDesc =>
      'Hardwarebeschleunigung für den MP4-Videoexport';

  @override
  String get defaultLanguage => 'Standardsprache';

  @override
  String get vadTitle => 'Sprachaktivitätserkennung (VAD)';

  @override
  String get vadDesc => 'Überspringt stille Bereiche während der Verarbeitung';

  @override
  String get vadThreshold => 'VAD-Schwellenwert';

  @override
  String get autoSaveTitle => 'Automatisches Speichern';

  @override
  String get autoSaveDesc =>
      'Projektänderungen alle 3 Sekunden automatisch in der Datenbank speichern';

  @override
  String get defaultOutputsTitle => 'Standard-Ausgaben';

  @override
  String get defaultExportFolder => 'Standard-Exportordner';

  @override
  String get alwaysAskExportPath => 'Immer nach dem Exportpfad fragen';

  @override
  String get alwaysAskExportPathDesc =>
      'Fragt bei jedem Export nach dem Ausgabepfad (Desktop)';

  @override
  String get performanceTitle => 'Leistung';

  @override
  String get exportCpuThreads => 'CPU-Threads für den Export';

  @override
  String get exportCpuThreadsDesc =>
      'Prozessor-Threads für das Rendering (Passt sich automatisch sicher an das Gerät an)';

  @override
  String get aboutAppSubtitle =>
      '100 % Offline, datenschutzorientiertes KI-Untertitel- und Caption-Studio';

  @override
  String get openSourceLicenses => 'Open-Source-Lizenzen';

  @override
  String get openSourceComplianceDesc =>
      'CapStudio basiert auf vielen Open-Source-Bibliotheken. Eine vollständige Übersicht aller Dart-Pakete, transitiven Abhängigkeiten und vollständigen Lizenztexte ist unten für die rechtliche Store-Konformität aufgeführt.';

  @override
  String get visitWebsite => 'Webseite besuchen';

  @override
  String get btnContinue => 'Fortfahren';

  @override
  String get btnBack => 'Zurück';

  @override
  String get editTiming => 'Timing bearbeiten';

  @override
  String get wordSettingsTitle => 'Wort-Einstellungen';

  @override
  String get emojiSettingsTitle => 'EMOJI-EINSTELLUNGEN';

  @override
  String get changeEmojiTooltip => 'Emoji ändern';

  @override
  String get searchEmojisHint => 'Emojis suchen...';

  @override
  String emojiPosX(String offset) {
    return 'Emoji-Position (X-Versatz: ${offset}px)';
  }

  @override
  String emojiPosY(String offset) {
    return 'Emoji-Position (Y-Versatz: ${offset}px)';
  }

  @override
  String emojiScale(String scale) {
    return 'Emoji-Skalierung (${scale}x)';
  }

  @override
  String emojiAnimSpeed(String speed) {
    return 'Animationsgeschwindigkeit (${speed}x)';
  }

  @override
  String get emojiStylePack => 'Emoji-Stil / Paket';

  @override
  String get selectStylePackTooltip => 'Stilpaket auswählen';

  @override
  String get selectEmojiTitle => 'EMOJI AUSWÄHLEN';

  @override
  String get stylePackLabel => 'STILPAKET';

  @override
  String get searchHint => 'Suchen...';

  @override
  String get btnCreateProject => 'PROJEKT ERSTELLEN';

  @override
  String get btnChooseFile => 'DATEI AUSWÄHLEN';

  @override
  String get selectSubtitleFile => 'Untertiteldatei auswählen';

  @override
  String get selectTranscriptionQuality => 'TRANSKRIPTIONSQUALITÄT AUSWÄHLEN';

  @override
  String get translateToEnglishDesc =>
      'Fremdsprachige Sprache direkt in englische Untertitel umwandeln';

  @override
  String get hardwareSettings => 'HARDWARE- & LEISTUNGSEINSTELLUNGEN';

  @override
  String get styleTemplatesHeader => 'STILVORLAGEN';

  @override
  String get resetToDefaultStyle => 'Auf Standardstil zurücksetzen';

  @override
  String get resetStylingTitle => 'Stil zurücksetzen?';

  @override
  String get resetStylingDesc =>
      'Dadurch werden alle Untertitelstile auf den Standard zurückgesetzt. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get sizeAndPosition => 'GRÖSSE & POSITION';

  @override
  String get verticalYPos => 'Vertikale Y-Position (%)';

  @override
  String get fontConfigHeader => 'SCHRIFTKONFIGURATION';

  @override
  String get fontFamilyLabel => 'Schriftfamilie';

  @override
  String get btnImportCustomFont =>
      'BENUTZERDEFINIERTE SCHRIFTART IMPORTIEREN (.ttf / .otf)';

  @override
  String get fontWeightLabel => 'Schriftstärke';

  @override
  String get textCaseLabel => 'Groß-/Kleinschreibung';

  @override
  String get fontSizeLabel => 'Schriftgröße';

  @override
  String get letterSpacingLabel => 'Zeichenabstand';

  @override
  String get lineHeightLabel => 'Zeilenhöhe';

  @override
  String get onboardingAppTagline =>
      '100 % lokaler Offline-KI-Untertiteleditor';

  @override
  String get configLabelWhisperCli => 'Whisper CLI';

  @override
  String get configValueDemoMode => 'Demomodus (Mock)';

  @override
  String get configLabelFfmpegCli => 'FFmpeg CLI';

  @override
  String get configValueSystemPathDefault => 'Standard-System-PATH';

  @override
  String get configLabelAssetsLocation => 'Speicherort der Assets';

  @override
  String get filePickerAssetsDialogTitle => 'CapStudio-Asset-Ordner auswählen';

  @override
  String errorSelectFolderFailed(String error) {
    return 'Ordnerauswahl fehlgeschlagen: $error';
  }

  @override
  String errorResetFailed(String error) {
    return 'Zurücksetzen fehlgeschlagen: $error';
  }

  @override
  String errorVerificationFailed(String error) {
    return 'Überprüfung fehlgeschlagen: $error';
  }

  @override
  String errorAssetsFolderStillMissing(String path) {
    return 'Asset-Ordner weiterhin nicht gefunden unter: $path';
  }

  @override
  String get dbRecoveredTitle => 'Datenbank automatisch wiederhergestellt';

  @override
  String dbRecoveredBody(String backupPath) {
    return 'Eine Schemainkompatibilität oder Beschädigung der Datenbank wurde erkannt. Die Datenbank wurde zurückgesetzt und Ihre bisherigen Daten wurden gesichert unter:\n\n$backupPath';
  }

  @override
  String errorDemoLoadFailed(String error) {
    return 'Laden des Demovideos fehlgeschlagen: $error';
  }

  @override
  String importProgressPercent(int percent) {
    return '$percent % abgeschlossen';
  }

  @override
  String get errorInvalidDropFileFormat =>
      'Ungültiges Dateiformat. Bitte legen Sie eine Videodatei ab.';

  @override
  String get findTextLabel => 'Text suchen';

  @override
  String get replaceWithLabel => 'Ersetzen durch';

  @override
  String findReplaceSuccessCount(int count) {
    return '$count Vorkommen ersetzt!';
  }

  @override
  String get btnReplaceAll => 'ALLE ERSETZEN';

  @override
  String errorVideoFileNotFound(String path) {
    return 'Videodatei nicht gefunden:\n$path\nBitte verknüpfen Sie die Videodatei erneut.';
  }

  @override
  String get errorTranscriptionFailed =>
      'Transkription fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String transcriptionActiveModel(String quality, String model) {
    return 'Aktiv: $quality ($model)';
  }

  @override
  String get badgeRecommended => 'EMPFEHLUNG';

  @override
  String get languageLabel => 'Sprache';

  @override
  String warningEnglishOnlyModel(String model, String language) {
    return 'Warnung: Das ausgewählte Modell ($model) unterstützt nur Englisch. Eine Transkription auf „$language“ schlägt fehl oder liefert englische Untertitel. Bitte wählen Sie ein mehrsprachiges Modell (z. B. Tiny oder Base).';
  }

  @override
  String get tipAutoDetectMixedLanguage =>
      'Tipp: Die automatische Erkennung wird für gemischte Sprachen (wie Hinglish) nicht empfohlen. Das explizite Auswählen der gesprochenen Sprache (z. B. Hindi oder Englisch) liefert wesentlich genauere Untertitel.';

  @override
  String get detectedHardwareLabel => 'Erkannte Systemhardware:';

  @override
  String hardwareRamSize(String ramGB) {
    return 'RAM-Größe: $ramGB GB';
  }

  @override
  String hardwareCpuCores(int cores) {
    return 'Logische CPU-Kerne: $cores';
  }

  @override
  String hardwareGpuDevice(String gpu) {
    return 'GPU-Gerät: $gpu';
  }

  @override
  String get hardwareDetecting => 'Hardware-Daten werden ermittelt...';

  @override
  String get btnStartReTranscribe => 'NEU-TRANSKRIPTION STARTEN';

  @override
  String get btnImportSrtVtt => 'SRT/VTT-DATEI IMPORTIEREN';

  @override
  String importedSubtitleWords(int count) {
    return '$count Wörter aus der Untertiteldatei importiert.';
  }

  @override
  String get errorImportSubtitleFailed =>
      'Importieren der Untertiteldatei fehlgeschlagen. Bitte überprüfen Sie das Dateiformat.';

  @override
  String get noProjectLoaded => 'Kein Projekt geladen';

  @override
  String get badge916Vertical => '9:16 HOCHFORMAT';

  @override
  String get badge169Landscape => '16:9 QUERFORMAT';

  @override
  String get reframeTargetCanvas =>
      'Ziel-Leinwand: 1080 × 1920 (TikTok, YouTube Shorts, Instagram Reels)';

  @override
  String get reframeModeLabel => 'Reframe-Modus:';

  @override
  String get reframeModeBlurPillarbox => 'Weichzeichner-Pillarbox (Empfohlen)';

  @override
  String get reframeModeBlurPillarboxDesc =>
      'Skaliert & zeichnet das Video im Hintergrund weich, um 9:16 auszufüllen, während das zentrierte Video scharf bleibt.';

  @override
  String get reframeModeCenterCrop => 'Intelligenter Zuschnitt (Zentriert)';

  @override
  String get reframeModeCenterCropDesc =>
      'Füllt den gesamten 9:16-Bildschirm durch Beschneiden der linken und rechten Ränder aus.';

  @override
  String get reframeModeSplitScreen => 'Geteilter Bildschirm / Dual-Layer';

  @override
  String get reframeModeSplitScreenDesc =>
      'Stapelt zwei Videofenster vertikal (ideal für Reactions und Podcast-Gespräche).';

  @override
  String get btnResetTo169 => 'AKTUELL 9:16 (AUF 16:9 ZURÜCKSETZEN)';

  @override
  String get btnSetCanvas916 => 'PROJEKT-LEINWAND AUF 9:16 SETZEN';

  @override
  String get silenceRemovalDesc =>
      'Schneidet Sprechpausen und Atemgeräusche automatisch heraus, um die Zuschauerbindung zu maximieren.';

  @override
  String get silenceAggressivenessLabel => 'Schnitt-Aggressivität:';

  @override
  String silenceNoiseGateLabel(int db) {
    return 'Stille-Noise-Gate: $db dB';
  }

  @override
  String silenceMinPauseLabel(String duration) {
    return 'Min. Pause: ${duration}s';
  }

  @override
  String get btnScanning => 'SCANNT...';

  @override
  String silenceNoneFound(String duration) {
    return 'Keine Stillepausen gefunden, die ${duration}s überschreiten.';
  }

  @override
  String silenceFoundCount(int count, String totalSecs) {
    return '$count Stillephasen gefunden (${totalSecs}s Leerlauf eingespart)!';
  }

  @override
  String errorScanningAudio(String error) {
    return 'Fehler beim Analysieren des Audios: $error';
  }

  @override
  String jumpCutsApplied(int count) {
    return '$count Jump-Cuts auf der Projekt-Timeline angewendet!';
  }

  @override
  String get viralHooksDesc =>
      'Analysiert Transkriptionswörter auf über 80 virale Hooks, Sprechtempo (120–170 WPM), Fragen, Energiedichte und Clip-Grenzen.';

  @override
  String get btnAnalyzingTranscript => 'TRANSKRIPT WIRD ANALYSIERT...';

  @override
  String get selectAllLabel => 'Alle auswählen';

  @override
  String selectedCountOf(int selected, int total) {
    return '$selected von $total ausgewählt';
  }

  @override
  String get btnSelectClipsToBatchExport => 'CLIPS FÜR BATCH-EXPORT AUSWÄHLEN';

  @override
  String btnBatchExportCount(int count) {
    return 'BATCH-EXPORT FÜR $count CLIP(S)';
  }

  @override
  String get viralNoClipsDetected =>
      'In diesem Videodauerbereich wurden keine hoch bewerteten viralen Clips erkannt.';

  @override
  String get badgeCleanCut => 'SAUBERER SCHNITT';

  @override
  String get badgeFirst5s => 'ERSTE 5s';

  @override
  String get btnPreview => 'Vorschau';

  @override
  String get btnTrim => 'Trimmen';

  @override
  String get tooltipForkAs916 => 'Als neues 9:16-Short-Projekt abzweigen';

  @override
  String wpmLabelOk(int wpm) {
    return '$wpm WPM ✓';
  }

  @override
  String wpmLabelFast(int wpm) {
    return '$wpm WPM SCHNELL';
  }

  @override
  String wpmLabelSlow(int wpm) {
    return '$wpm WPM LANGSAM';
  }

  @override
  String hookScoreLabel(int score) {
    return 'Hook $score/40';
  }

  @override
  String energyScoreLabel(int score) {
    return 'Energie $score/20';
  }

  @override
  String get filePickerClipsFolderTitle =>
      'Ordner zum Speichern von Clips auswählen';

  @override
  String get errorChooseOutputFolderFirst =>
      'Bitte wählen Sie zuerst einen Ausgabeordner.';

  @override
  String batchExportSheetTitle(int count) {
    return 'BATCH-EXPORT VON $count CLIP(S)';
  }

  @override
  String get tapToChooseOutputFolder => 'Tippen, um Ausgabeordner zu wählen…';

  @override
  String get burnCaptionsOnClipsLabel =>
      'Dynamische Untertitel in Clips einbrennen';

  @override
  String get burnCaptionsOnClipsDesc =>
      'Brennt animierte, stilisierte Untertitel synchron zum Clip-Audio ein';

  @override
  String exportCancelledProgress(int done, int total) {
    return 'Export abgebrochen. $done/$total fertiggestellt.';
  }

  @override
  String exportProgressSummary(int done, int total, int failed) {
    return '$done/$total exportiert · $failed fehlgeschlagen';
  }

  @override
  String get btnExporting => 'EXPORTIERT…';

  @override
  String get btnExportComplete => 'EXPORT ABGESCHLOSSEN ✓';

  @override
  String get btnStartExport => 'EXPORT STARTEN';

  @override
  String exportClipSavedAt(String path) {
    return '✓ Gespeichert: $path';
  }

  @override
  String projectTrimmedToClip(int rank, String start, String end) {
    return 'Projekt auf viralen Clip #$rank getrimmt ($start - $end)!';
  }

  @override
  String shortProjectCreated(String name) {
    return '9:16-Short erstellt: \"$name\"';
  }

  @override
  String get btnOpen => 'ÖFFNEN';

  @override
  String errorCreateShortProjectFailed(String error) {
    return 'Fehler beim Erstellen des Short-Projekts: $error';
  }

  @override
  String get autoDetect => 'Automatisch erkennen';

  @override
  String presetSaved(String name) {
    return 'Stilvorlage \"$name\" erfolgreich gespeichert!';
  }

  @override
  String get presetDeleted => 'Vorlage erfolgreich gelöscht.';

  @override
  String get presetExported => 'Stilvorlagen erfolgreich exportiert!';

  @override
  String errorPresetExportFailed(String error) {
    return 'Fehler beim Exportieren der Vorlagen: $error';
  }

  @override
  String get presetImported => 'Stilvorlagen erfolgreich importiert!';

  @override
  String errorPresetImportFailed(String error) {
    return 'Fehler beim Importieren der Vorlagen: $error';
  }

  @override
  String get selectFontFileDialogTitle =>
      'TTF- oder OTF-Schriftartdatei auswählen';

  @override
  String get fontWeightThin => 'Dünn';

  @override
  String get fontWeightExtraLight => 'Extra leicht';

  @override
  String get fontWeightLight => 'Leicht';

  @override
  String get fontWeightNormal => 'Normal';

  @override
  String get fontWeightMedium => 'Mittel';

  @override
  String get fontWeightSemiBold => 'Halbfett';

  @override
  String get fontWeightBold => 'Fett';

  @override
  String get fontWeightExtraBold => 'Extrafett';

  @override
  String get fontWeightBlack => 'Schwarz';

  @override
  String get fontCaseNormal => 'Normal';

  @override
  String get fontCaseUppercase => 'GROSSBUCHSTABEN';

  @override
  String get fontCaseCapitalize => 'Großschreibung';

  @override
  String get strokeStyleThickOutline => 'Dicke Kontur';

  @override
  String get strokeStyleNoneFlat => 'Keine (Flach)';

  @override
  String get shadowStyleSoft => 'Weicher Schatten';

  @override
  String get shadowStyleNone => 'Keiner';

  @override
  String get animStyleActivePop => 'Aktiver Pop';

  @override
  String get animStyleActiveBounce => 'Aktiver Sprung-Bounce';

  @override
  String get animStyleKineticTilt => 'Kinetische Kipp-Animation';

  @override
  String get animStyleGlowPulse => 'Leuchtender Aktiv-Puls';

  @override
  String get animStyleWordReveal => 'Wort-Staffel-Enthüllung';

  @override
  String get animStyleNoneStatic => 'Keine (Statisch)';

  @override
  String fontImportedSuccess(String name) {
    return 'Benutzerdefinierte Schriftart erfolgreich importiert und angewendet: \"$name\"';
  }

  @override
  String get errorFontImportFailed =>
      'Schriftartdatei konnte nicht geladen werden. Ungültige Daten.';

  @override
  String get invalidTimingError =>
      'Ungültiges Start-/End-Timing. Der Start muss >= 0 sein und das Ende muss >= Start sowie <= Videodauer sein.';

  @override
  String get projectSavedSuccess => 'Projekt erfolgreich gespeichert.';

  @override
  String wordDeletedSuccess(String text) {
    return 'Wort gelöscht: \"$text\"';
  }

  @override
  String get splitClip => 'Clip teilen';

  @override
  String get removeClip => 'Clip entfernen';

  @override
  String get resetToOriginal => 'Auf Original zurücksetzen';

  @override
  String splitTimelineAt(String time) {
    return 'Timeline bei $time s getrennt.';
  }

  @override
  String get splitTimelineError =>
      'Der Abspielkopf muss sich im aktiven Bereich befinden, um zu teilen.';

  @override
  String get exclusionToggled =>
      'Segmentausschluss unter dem Abspielkopf umgeschaltet.';

  @override
  String get splitsReset =>
      'Alle Timeline-Trennungen und -Ausschlüsse zurückgesetzt.';

  @override
  String get shareVideo => 'Video teilen';

  @override
  String get openOutputFolder => 'Ausgabeordner öffnen';

  @override
  String get errorLogCopied => 'Fehlerprotokoll in die Zwischenablage kopiert.';

  @override
  String get diagnosticsExported =>
      'Gefilterter Diagnosebericht im Freigabe-Dialog geöffnet.';

  @override
  String errorDiagnosticsFailed(String error) {
    return 'Diagnosebericht konnte nicht exportiert werden: $error';
  }

  @override
  String logLineCopied(String message) {
    return 'Protokollzeile in die Zwischenablage kopiert: \"$message\"';
  }

  @override
  String commandCopied(String command) {
    return 'Kopiert: \"$command\"';
  }

  @override
  String get settingsRestored =>
      'Einstellungen auf Standardwerte zurückgesetzt.';

  @override
  String get gpuEncoderNoneCpu => 'Keiner (CPU)';

  @override
  String get gpuEncoderNvidia => 'NVIDIA NVENC';

  @override
  String get gpuEncoderAmd => 'AMD AMF';

  @override
  String get gpuEncoderIntel => 'Intel QSV';

  @override
  String get gpuEncoderApple => 'Apple VideoToolbox';

  @override
  String get btnDownloadVcRedist => 'VC++ REDISTRIBUTABLE HERUNTERLADEN';

  @override
  String errorDownloadToolFailed(String error) {
    return 'Tool-Download fehlgeschlagen: $error';
  }

  @override
  String get errorFolderNotAccessible =>
      'Der ausgewählte Ordner existiert nicht oder ist nicht zugänglich.';

  @override
  String modelDeleted(String name) {
    return 'Modell gelöscht: $name';
  }

  @override
  String errorModelDeleteFailed(String error) {
    return 'Löschen des Modells fehlgeschlagen: $error';
  }

  @override
  String errorModelDownloadFailed(String name, String error) {
    return 'Herunterladen des Modells $name fehlgeschlagen: $error';
  }

  @override
  String errorOpenFolderFailed(String path) {
    return 'Ordner konnte nicht automatisch geöffnet werden. Pfad: $path';
  }

  @override
  String errorDownloadPackFailed(String error) {
    return 'Download des Pakets fehlgeschlagen: $error';
  }

  @override
  String errorPackDownloadNamedFailed(String name, String error) {
    return 'Download des Pakets $name fehlgeschlagen: $error';
  }

  @override
  String get stickersIndexRefreshed =>
      'Index benutzerdefinierter Sticker erfolgreich aktualisiert!';

  @override
  String errorChangeAssetFolderFailed(String error) {
    return 'Ändern des Asset-Ordners fehlgeschlagen: $error';
  }

  @override
  String errorSetAssetFolderFailed(String error) {
    return 'Festlegen des Asset-Ordners fehlgeschlagen: $error';
  }

  @override
  String get warningNoAvx =>
      'Fehlende AVX-Unterstützung erkannt! Lade kompatibles whisper-cli (ohne AVX) herunter...';

  @override
  String get errorAutoDetectWhisper =>
      'whisper-cli konnte nicht automatisch erkannt werden. Bitte manuell auswählen.';

  @override
  String get errorAutoDetectFfmpeg =>
      'ffmpeg konnte nicht automatisch erkannt werden. Bitte manuell auswählen.';

  @override
  String errorToolDownloadFailed(String error) {
    return 'Herunterladen des Tools fehlgeschlagen: $error';
  }

  @override
  String get returnToDashboard => 'Zurück zum Dashboard';

  @override
  String errorImportVideoFailed(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get videoRelinkedSuccess => 'Video erfolgreich neu verknüpft!';

  @override
  String get errorRelinkVideoFailed =>
      'Erneutes Verknüpfen des Videos fehlgeschlagen.';

  @override
  String get retranscriptionSuccess => 'Neu-Transkription erfolgreich!';

  @override
  String get retranscriptionFailed => 'Neu-Transkription fehlgeschlagen.';
}
