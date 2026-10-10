// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'CapStudio';

  @override
  String get dashboardTitle => 'Mes Projets';

  @override
  String get dashboardSubtitle =>
      'Studio d\'IA hors ligne pour sous-titrage et légendage';

  @override
  String get importVideo => 'Importer une Vidéo';

  @override
  String get dragDropText => 'Glissez et déposez votre fichier vidéo ici';

  @override
  String get clickBrowse => 'ou cliquez pour parcourir les fichiers locaux';

  @override
  String get demoMode => 'MODE DÉMO';

  @override
  String get demoModeDesc =>
      'Chargez un projet de démonstration pour tester les styles et les fonctionnalités de l\'éditeur.';

  @override
  String get warningAssets => 'Récupération du dossier de ressources requise';

  @override
  String get warningAssetsDesc =>
      'Les ressources intégrées n\'ont pas été trouvées dans le dossier de support de l\'application. Double-cliquez ici pour les restaurer ou changer de répertoire.';

  @override
  String get deleteProjectTitle => 'Supprimer le Projet';

  @override
  String deleteProjectConfirm(String projectName) {
    return 'Êtes-vous sûr de vouloir supprimer définitivement \"$projectName\" ? Cette action est irréversible.';
  }

  @override
  String get renameProjectTitle => 'Renommer le Projet';

  @override
  String get projectNameLabel => 'Nom du Projet';

  @override
  String get btnCancel => 'ANNULER';

  @override
  String get btnDelete => 'SUPPRIMER';

  @override
  String get btnRename => 'RENOMMER';

  @override
  String get btnSave => 'ENREGISTRER';

  @override
  String get btnConfirm => 'CONFIRMER';

  @override
  String get btnExport => 'EXPORTER';

  @override
  String get btnUndo => 'Annuler';

  @override
  String get btnRedo => 'Rétablir';

  @override
  String get statusDraft => 'Brouillon';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get createdLabel => 'Créé le :';

  @override
  String get durationLabel => 'Durée :';

  @override
  String get statusLabel => 'Statut :';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsGeneral => 'Paramètres Généraux';

  @override
  String get settingsTheme => 'Thème de l\'application';

  @override
  String get themeSystem => 'Par Défaut du Système';

  @override
  String get themeLight => 'Mode Clair';

  @override
  String get themeDark => 'Mode Sombre';

  @override
  String get settingsLanguage => 'Langue de l\'interface';

  @override
  String get settingsTranscription => 'Paramètres de Transcription';

  @override
  String get settingsWhisperModel => 'Modèle Whisper';

  @override
  String get settingsWhisperModelDesc =>
      'Sélectionnez le modèle de transcription. Plus le modèle est petit, plus il est rapide; plus il est grand, plus il est précis.';

  @override
  String get settingsTranscribeLang => 'Langue de transcription';

  @override
  String get settingsAutoDetect => 'Détecter automatiquement la langue';

  @override
  String get settingsGPU => 'Accélération GPU (CUDA)';

  @override
  String get settingsVAD => 'Seuil VAD (Activité Vocale)';

  @override
  String get settingsExport => 'Paramètres d\'Exportation';

  @override
  String get settingsExportDest => 'Dossier d\'exportation par défaut';

  @override
  String get settingsBrowse => 'Parcourir';

  @override
  String get settingsEmojiPacks => 'Packs d\'Emojis et de Styles';

  @override
  String get settingsEmojiPacksDesc =>
      'Personnalisez les styles d\'affichage des emojis et les fichiers de sous-titres actifs.';

  @override
  String get settingsEmojiSearchLang => 'Langue de recherche d\'emojis';

  @override
  String get settingsBtnManagePacks => 'GÉRER LES PACKS D\'EMOJIS';

  @override
  String get systemTitle => 'Informations Système';

  @override
  String get systemVersion => 'Version';

  @override
  String get systemReset => 'Réinitialiser les Valeurs par Défaut';

  @override
  String get editorTabCaptions => 'Sous-titres';

  @override
  String get editorTabStyles => 'Styles';

  @override
  String get editorTabTrim => 'Découper';

  @override
  String get editorTabAudio => 'Audio';

  @override
  String get editorTabTranscription => 'Transcription';

  @override
  String get editorTabShortcuts => 'Raccourcis';

  @override
  String get editorTabDebug => 'Débogage';

  @override
  String get editorHeaderBack => 'Retour';

  @override
  String get editorKeyboardShortcuts => 'Raccourcis Clavier';

  @override
  String get dialogAnalyzing => 'Analyse de la vidéo...';

  @override
  String get dialogTranscribing => 'Transcription de l\'audio...';

  @override
  String get dialogExtracting => 'Extraction de l\'audio...';

  @override
  String get dialogWait => 'Cela peut prendre un moment. Veuillez patienter.';

  @override
  String get dialogError => 'Erreur';

  @override
  String get dialogImportFailed => 'Échec de l\'importation de la vidéo.';

  @override
  String get noProjects => 'Aucun projet créé pour le moment';

  @override
  String get aboutApp => 'À propos de CapStudio';

  @override
  String get aboutAppDesc =>
      'Présentation de CapStudio, crédits et licences open-source.';

  @override
  String get aboutAppThanks =>
      'Remerciements particuliers aux projets open-source qui rendent CapStudio possible :';

  @override
  String get btnViewAllLicenses => 'VOIR TOUTES LES LICENCES DES PACKAGES';

  @override
  String get exportBurnIn => 'EXPORTATION VIDÉO AVEC SOUS-TITRES INCORPORÉS';

  @override
  String get exportTimecodeFormats =>
      'FORMATS DE SOUS-TITRES AVEC CODES TEMPORELS';

  @override
  String get exportWebEnabled =>
      'L\'exportation vidéo côté client est activée. Le rendu s\'exécute localement dans votre navigateur.';

  @override
  String get exportWebCaptionOnly =>
      'L\'exportation web n\'inclut actuellement que les sous-titres : les emojis et les effets sonores ne sont pas encore incorporés à la vidéo. Exportez depuis l\'application de bureau ou mobile pour obtenir le résultat complet.';

  @override
  String get exportOutputName => 'Nom de la vidéo de sortie';

  @override
  String get exportMode => 'Mode d\'exportation';

  @override
  String get exportModeFast => 'Rapide (FFmpeg natif)';

  @override
  String get exportModeFastUnsupported =>
      'Rapide (FFmpeg natif) ⚠️ Non pris en charge';

  @override
  String get exportModeSlow => 'Lent (rendu d\'aperçu 1:1)';

  @override
  String get exportTargetFps => 'FPS cible';

  @override
  String get exportFps24 => '24 FPS (Cinéma)';

  @override
  String get exportFps25 => '25 FPS (PAL)';

  @override
  String get exportFps30 => '30 FPS (Standard)';

  @override
  String get exportFps50 => '50 FPS';

  @override
  String get exportFps60 => '60 FPS (Fluide)';

  @override
  String get exportFastUnsupported =>
      'Le mode rapide n\'est pas pris en charge sur cet appareil car la version système de FFmpeg ne dispose pas des filtres de rendu de sous-titres (libass). Le mode lent sera utilisé à la place.';

  @override
  String get exportSlowInfo =>
      'Capture chaque image exactement comme affichée dans l\'aperçu. Cela garantit des sous-titres parfaits au pixel près, mais le rendu est plus lent.';

  @override
  String get exportDestDirectory => 'DOSSIER DE DESTINATION';

  @override
  String get exportDestBrowser => 'Emplacement de téléchargement du navigateur';

  @override
  String get exportDestAndroid =>
      'Dossier Téléchargements (/storage/emulated/0/Download)';

  @override
  String get exportDestIos =>
      'Documents de l\'application (feuille de partage après l\'exportation)';

  @override
  String get exportChooseFolder => 'Choisir le dossier de sortie';

  @override
  String get exportStartMp4 => 'DÉMARRER L\'EXPORTATION MP4';

  @override
  String get exportSrtTitle => 'Sous-titres SubRip (.srt)';

  @override
  String get exportSrtDesc =>
      'Norme universelle avec codes temporels. Compatible avec YouTube, VLC et Premiere Pro.';

  @override
  String get exportVttTitle => 'Sous-titres WebVTT (.vtt)';

  @override
  String get exportVttDesc =>
      'Format de sous-titres optimisé pour le web, largement utilisé dans les lecteurs HTML5 et la diffusion en ligne.';

  @override
  String get exportAssTitle => 'Advanced SubStation Alpha (.ass)';

  @override
  String get exportAssDesc =>
      'Format professionnel intégrant tailles de police, styles, marges et surlignages en ligne.';

  @override
  String get exportTxtTitle => 'Transcription en texte brut (.txt)';

  @override
  String get exportTxtDesc =>
      'Transcription ligne par ligne avec préfixes d\'horodatage.';

  @override
  String exportSuccess(String type) {
    return '$type exporté avec succès !';
  }

  @override
  String get exportNoLocation =>
      'Aucun emplacement d\'enregistrement sélectionné. Veuillez choisir un chemin de fichier.';

  @override
  String get exportNoLocationCancelled =>
      'Aucun emplacement d\'enregistrement sélectionné. Exportation annulée.';

  @override
  String exportFailed(String error) {
    return 'Échec de l\'exportation : $error';
  }

  @override
  String get exportCopySrtTooltip => 'Copier le SRT dans le presse-papiers';

  @override
  String get exportCopiedSrt => 'SRT copié dans le presse-papiers !';

  @override
  String exportCopyFailedSrt(String error) {
    return 'Échec de la copie du SRT : $error';
  }

  @override
  String exportSubtitlesDialogTitle(String type) {
    return 'Exporter les sous-titres $type';
  }

  @override
  String get exportVideoDialogTitle => 'Exporter la vidéo MP4';

  @override
  String get ffmpegRequiredTitle => 'FFmpeg requis';

  @override
  String get ffmpegRequiredBody =>
      'Une installation locale de FFmpeg est requise pour incorporer des sous-titres dans un fichier vidéo.\n\nVeuillez configurer le chemin de FFmpeg dans les paramètres.';

  @override
  String get okLabel => 'OK';

  @override
  String get exportWebTitle => 'Exportation de la vidéo (côté client)';

  @override
  String exportWebSuccess(String fileName) {
    return 'Vidéo exportée avec succès sous le nom $fileName !';
  }

  @override
  String exportWebFailed(String error) {
    return 'Échec du rendu : $error';
  }

  @override
  String get viralShortsTitle => 'STUDIO SHORTS VIRAUX';

  @override
  String get viralShortsSubtitle =>
      'Recadrage vertical 9:16, jump-cuts de silence et détecteur de hooks IA';

  @override
  String get viralReframeTitle => '1. RECADRAGE VERTICAL 9:16';

  @override
  String get viralSilenceTitle => '2. SUPPRESSION DES SILENCES (JUMP-CUTS)';

  @override
  String get viralHooksTitle => '3. DÉTECTEUR DE HOOKS VIRAUX IA';

  @override
  String get btnFindViralMoments => 'TROUVER DES MOMENTS VIRAUX';

  @override
  String get btnScanSilences => 'DÉTECTER LES SILENCES';

  @override
  String get btnApplyJumpCuts => 'APPLIQUER LES JUMP-CUTS';

  @override
  String get editorTabShorts => 'Shorts';

  @override
  String get editorTabClips => 'Clips';

  @override
  String get captionList => 'LISTE DES SOUS-TITRES';

  @override
  String get uncertainLabel => 'Incertain (<40 %)';

  @override
  String get mediumConfidenceLabel => 'Moyen (40-60 %)';

  @override
  String get jumpToUncertain => 'Aller au mot incertain suivant';

  @override
  String get noUncertainWords => 'Aucun mot incertain trouvé.';

  @override
  String get findAndReplace => 'Rechercher et remplacer';

  @override
  String get addWordTitle => 'Ajouter un mot';

  @override
  String get editWordTitle => 'Modifier le mot';

  @override
  String get wordTextLabel => 'Texte du mot';

  @override
  String get startTimeLabel => 'Heure de début (s)';

  @override
  String get endTimeLabel => 'Heure de fin (s)';

  @override
  String get splitChunk => 'Scinder le segment';

  @override
  String get insertLineAfter => 'Insérer une ligne après';

  @override
  String get duplicateLine => 'Dupliquer la ligne';

  @override
  String get deleteLine => 'Supprimer la ligne';

  @override
  String get chooseSfxTitle => 'Choisir un effet sonore';

  @override
  String get searchSfxPlaceholder => 'Rechercher un effet sonore...';

  @override
  String get noSfxFound => 'Aucun effet sonore trouvé';

  @override
  String get emojiSearch => 'Recherche d\'émojis';

  @override
  String get noEmojisFound => 'Aucun émoji trouvé.';

  @override
  String get mySavedPresets => 'MES PRÉRÉGLAGES ENREGISTRÉS';

  @override
  String get btnImport => 'IMPORTER';

  @override
  String get btnExportCaps => 'EXPORTER';

  @override
  String get btnSaveCurrent => 'ENREGISTRER L\'ACTUEL';

  @override
  String get resetToDefault => 'Rétablir par défaut';

  @override
  String get resetConfirmBody =>
      'Tous les styles de sous-titres seront réinitialisés par défaut. Cette action est irréversible.';

  @override
  String get btnReset => 'Réinitialiser';

  @override
  String get wordHighlightBox => 'Encadré de surbrillance de mot';

  @override
  String get wordHighlightBoxDesc =>
      'Arrière-plan arrondi coloré derrière les mots prononcés actifs';

  @override
  String get maxWordsPerChunk => 'Mots max par segment de sous-titre';

  @override
  String get maxCharsPerLine => 'Caractères max par ligne de sous-titre';

  @override
  String get fontSettings => 'Paramètres de police';

  @override
  String get colorSettings => 'Paramètres de couleur';

  @override
  String get borderSettings => 'Paramètres de bordure et d\'ombre';

  @override
  String get speechToTextTitle => 'TRANSCRIPTION VOCALE (SPEECH-TO-TEXT)';

  @override
  String get speechToTextDesc =>
      'Relancer la transcription vocale locale. Toutes les modifications manuelles ou décalages temporels seront remplacés.';

  @override
  String get useLocalAi => 'Utiliser la transcription par IA locale';

  @override
  String get runOnDeviceDesc =>
      'Exécuter la reconnaissance vocale directement sur cet appareil';

  @override
  String get offlineDemoModeActive =>
      'Le mode démo hors ligne est actif. La transcription locale Whisper AI n\'est pas prise en charge sur le Web.';

  @override
  String get demoModeNote =>
      'Le mode démo génère instantanément des segments de transcription très réalistes. Idéal pour tester les styles, modèles et opérations de montage sans configuration préalable.';

  @override
  String get transcriptionQuality => 'Qualité de transcription';

  @override
  String get advancedSettings => 'Paramètres avancés';

  @override
  String get cpuThreadsLabel => 'Threads CPU';

  @override
  String get vadSensitivity => 'Sensibilité VAD';

  @override
  String get translateToEnglish => 'Traduire les sous-titres en anglais';

  @override
  String get startTranscriptionBtn => 'DÉMARRER LA TRANSCRIPTION';

  @override
  String get hardwareLocked => 'Matériel verrouillé';

  @override
  String get btnDownload => 'Télécharger';

  @override
  String get welcomeTitle => 'Bienvenue dans CapStudio';

  @override
  String get welcomeSubtitle =>
      'Sous-titres haute précision et formats courts viraux, 100 % hors ligne.';

  @override
  String get setupAssetDirTitle => 'Choisir le dossier de ressources';

  @override
  String get setupAssetDirDesc =>
      'Sélectionnez un dossier pour stocker les modèles, les polices et les packs d\'émojis.';

  @override
  String get downloadPacksTitle =>
      'Télécharger les packs de contenu (Facultatif)';

  @override
  String get downloadPacksDesc =>
      'Polices et effets sonores facultatifs pour vos projets vidéo.';

  @override
  String get setupCompleteTitle => 'Configuration terminée';

  @override
  String get setupCompleteDesc =>
      'Vous êtes prêt à créer de superbes vidéos sous-titrées.';

  @override
  String get btnGetStarted => 'Commencer';

  @override
  String get btnNext => 'SUIVANT';

  @override
  String get btnSkip => 'IGNORER';

  @override
  String get onboardingFeaturePrivacy => 'Confidentialité 100 % garantie';

  @override
  String get onboardingFeaturePrivacyDesc =>
      'Vos fichiers ne quittent jamais votre appareil. Tous les modèles d\'IA s\'exécutent localement.';

  @override
  String get onboardingFeatureGpu => 'Lecture accélérée par GPU';

  @override
  String get onboardingFeatureGpuDesc =>
      'Montage vidéo haute performance grâce au décodage matériel.';

  @override
  String get onboardingFeatureAssets => 'Ressources intégrées hors ligne';

  @override
  String get onboardingFeatureAssetsDesc =>
      'Téléchargez des packs d\'émojis complets une seule fois et travaillez entièrement hors ligne.';

  @override
  String get onboardingReadyTitle => 'Vous êtes prêt à vous lancer !';

  @override
  String get onboardingConfigDetails => 'Détails de la configuration :';

  @override
  String get btnLaunchCapStudio => 'Lancer CapStudio';

  @override
  String get assetVerificationFailed =>
      'Échec de la vérification des ressources. Veuillez vous assurer qu\'elles ont été correctement téléchargées.';

  @override
  String get assetsFolderNotFound => 'Dossier de ressources introuvable';

  @override
  String get assetsFolderNotFoundDesc =>
      'CapStudio n\'a pas pu localiser le dossier de ressources à l\'emplacement configuré. S\'il se trouve sur un disque externe, veuillez le connecter.';

  @override
  String get expectedPathLabel => 'CHEMIN ATTENDU :';

  @override
  String get browseNewLocation => 'Parcourir un nouvel emplacement';

  @override
  String get resetToDefaultPath => 'Rétablir le chemin par défaut';

  @override
  String get retryVerification => 'Réessayer la vérification';

  @override
  String get storagePathFolder => 'Dossier de stockage';

  @override
  String get tipWindowsDrive =>
      'Astuce : si le disque C: est saturé, choisissez un chemin sur D: ou E: pour libérer de l\'espace.';

  @override
  String get tipGeneralDrive =>
      'Astuce : vous pouvez sélectionner un disque externe si votre volume principal est plein.';

  @override
  String get confirmLocation => 'Confirmer l\'emplacement';

  @override
  String get requiredBadge => 'REQUIS';

  @override
  String get emojiPacksHeader => 'PACKS D\'ÉMOJIS';

  @override
  String get fontPacksHeader => 'PACKS DE POLICES';

  @override
  String get connectCliTitle => 'Connecter les outils CLI locaux';

  @override
  String get connectCliDesc =>
      'CapStudio nécessite les exécutables whisper.cpp et FFmpeg pour transcrire et exporter des vidéos localement.';

  @override
  String get skipSetup => 'Ignorer la configuration pour le moment';

  @override
  String get btnValidate => 'Valider';

  @override
  String get autoDetectAndValidate => 'Détecter automatiquement et valider';

  @override
  String get whisperCliPathLabel => 'Chemin de l\'exécutable Whisper CLI';

  @override
  String get ffmpegCliPathLabel => 'Chemin de l\'exécutable FFmpeg CLI';

  @override
  String get newProject => 'Nouveau projet';

  @override
  String get searchProjects => 'Rechercher des projets...';

  @override
  String get filterAll => 'Tous';

  @override
  String get sortByRecent => 'Plus récents';

  @override
  String get sortByDuration => 'Durée';

  @override
  String get noMatchingProjects =>
      'Aucun projet ne correspond à votre recherche';

  @override
  String get btnEdit => 'MODIFIER';

  @override
  String get btnDuplicate => 'DUPLIQUER';

  @override
  String get tooltipEdit => 'Modifier';

  @override
  String get tooltipRename => 'Renommer';

  @override
  String get tooltipDuplicate => 'Dupliquer';

  @override
  String get tooltipDelete => 'Supprimer';

  @override
  String get tooltipTheme => 'Thème';

  @override
  String get tooltipSettings => 'Paramètres';

  @override
  String get selectDemoFormat => 'SÉLECTIONNER LE FORMAT DE DÉMO';

  @override
  String get selectDemoDesc =>
      'Sélectionnez un format pour prévisualiser instantanément le moteur de sous-titrage haute fidélité, les animations au mot près et les formes d\'onde audio de CapStudio.';

  @override
  String get landscapeDemo => 'Démo paysage';

  @override
  String get landscapeDemoDesc =>
      'Idéal pour YouTube, ordinateurs et présentations.';

  @override
  String get portraitDemo => 'Démo portrait';

  @override
  String get portraitDemoDesc => 'Idéal pour TikTok, Shorts, Reels et mobiles.';

  @override
  String get format16x9 => 'Format 16:9';

  @override
  String get format9x16 => 'Format 9:16';

  @override
  String get dropVideoHere => 'DÉPOSEZ LA VIDÉO ICI';

  @override
  String get dropVideoSupported => 'Prend en charge MP4, MOV, AVI, etc.';

  @override
  String get statusLocalOffline => 'LOCAL HORS LIGNE';

  @override
  String get speechModelTitle => 'Modèle de reconnaissance vocale';

  @override
  String get hardwareUpgradesTitle =>
      'Améliorations des performances matérielles';

  @override
  String get showAdvancedPaths =>
      'AFFICHER LA CONFIGURATION AVANCÉE DES CHEMINS';

  @override
  String get hideAdvancedPaths =>
      'MASQUER LA CONFIGURATION AVANCÉE DES CHEMINS';

  @override
  String get autoDownload => 'TÉLÉCHARGEMENT AUTO';

  @override
  String get gpuAcceleratedTranscription =>
      'Transcription accélérée par GPU (CUDA)';

  @override
  String get gpuRequiresNvidia => 'Nécessite un GPU NVIDIA compatible CUDA';

  @override
  String get gpuExportEncoder => 'Encodeur d\'exportation GPU';

  @override
  String get gpuExportEncoderDesc =>
      'Accélération matérielle pour l\'exportation vidéo MP4';

  @override
  String get defaultLanguage => 'Langue par défaut';

  @override
  String get vadTitle => 'Détection d\'activité vocale (VAD)';

  @override
  String get vadDesc => 'Ignore les zones de silence pendant le traitement';

  @override
  String get vadThreshold => 'Seuil VAD';

  @override
  String get autoSaveTitle => 'Sauvegarde automatique';

  @override
  String get autoSaveDesc =>
      'Enregistre automatiquement les modifications du projet dans la base de données toutes les 3 secondes';

  @override
  String get defaultOutputsTitle => 'Sorties par défaut';

  @override
  String get defaultExportFolder => 'Dossier d\'exportation par défaut';

  @override
  String get alwaysAskExportPath =>
      'Toujours demander le chemin d\'exportation';

  @override
  String get alwaysAskExportPathDesc =>
      'Demande l\'emplacement de sortie à chaque exportation (Bureau)';

  @override
  String get performanceTitle => 'Performances';

  @override
  String get exportCpuThreads => 'Threads CPU pour l\'exportation';

  @override
  String get exportCpuThreadsDesc =>
      'Threads du processeur à allouer au rendu (Ajustement automatique sécurisé selon l\'appareil)';

  @override
  String get aboutAppSubtitle =>
      'Studio de sous-titrage par IA 100 % hors ligne et respectueux de la vie privée';

  @override
  String get openSourceLicenses => 'Licences Open Source';

  @override
  String get openSourceComplianceDesc =>
      'CapStudio repose sur de nombreuses bibliothèques open source. Un registre complet de tous les paquets Dart, dépendances transitives et textes de licence intégraux est répertorié ci-dessous pour la conformité légale des boutiques d\'applications.';

  @override
  String get visitWebsite => 'Visiter le site web';

  @override
  String get btnContinue => 'Continuer';

  @override
  String get btnBack => 'Retour';

  @override
  String get editTiming => 'Modifier le minutage';

  @override
  String get wordSettingsTitle => 'Paramètres du mot';

  @override
  String get emojiSettingsTitle => 'PARAMÈTRES D\'ÉMOJIS';

  @override
  String get changeEmojiTooltip => 'Changer d\'émoji';

  @override
  String get searchEmojisHint => 'Rechercher des émojis...';

  @override
  String emojiPosX(String offset) {
    return 'Position de l\'émoji (Décalage X : $offset px)';
  }

  @override
  String emojiPosY(String offset) {
    return 'Position de l\'émoji (Décalage Y : $offset px)';
  }

  @override
  String emojiScale(String scale) {
    return 'Échelle de l\'émoji (${scale}x)';
  }

  @override
  String emojiAnimSpeed(String speed) {
    return 'Vitesse d\'animation (${speed}x)';
  }

  @override
  String get emojiStylePack => 'Style / Pack d\'émojis';

  @override
  String get selectStylePackTooltip => 'Sélectionner un pack de styles';

  @override
  String get selectEmojiTitle => 'SÉLECTIONNER UN ÉMOJI';

  @override
  String get stylePackLabel => 'PACK DE STYLES';

  @override
  String get searchHint => 'Rechercher...';

  @override
  String get btnCreateProject => 'CRÉER UN PROJET';

  @override
  String get btnChooseFile => 'CHOISIR UN FICHIER';

  @override
  String get selectSubtitleFile => 'Sélectionner un fichier de sous-titres';

  @override
  String get selectTranscriptionQuality =>
      'SÉLECTIONNER LA QUALITÉ DE TRANSCRIPTION';

  @override
  String get translateToEnglishDesc =>
      'Convertir directement les paroles en langue étrangère en sous-titres anglais';

  @override
  String get hardwareSettings => 'PARAMÈTRES MATÉRIELS ET DE PERFORMANCES';

  @override
  String get styleTemplatesHeader => 'MODÈLES DE STYLE';

  @override
  String get resetToDefaultStyle => 'Rétablir le style par défaut';

  @override
  String get resetStylingTitle => 'Réinitialiser le style ?';

  @override
  String get resetStylingDesc =>
      'Tous les styles de sous-titres seront réinitialisés par défaut. Cette action est irréversible.';

  @override
  String get sizeAndPosition => 'TAILLE ET POSITION';

  @override
  String get verticalYPos => 'Position verticale Y (%)';

  @override
  String get fontConfigHeader => 'CONFIGURATION DE LA POLICE';

  @override
  String get fontFamilyLabel => 'Famille de police';

  @override
  String get btnImportCustomFont =>
      'IMPORTER UNE POLICE PERSONNALISÉE (.ttf / .otf)';

  @override
  String get fontWeightLabel => 'Graisse de la police';

  @override
  String get textCaseLabel => 'Casse du texte';

  @override
  String get fontSizeLabel => 'Taille de police';

  @override
  String get letterSpacingLabel => 'Espacement des lettres';

  @override
  String get lineHeightLabel => 'Hauteur de ligne';

  @override
  String get onboardingAppTagline =>
      'Éditeur de sous-titres par IA 100 % hors ligne et local';

  @override
  String get configLabelWhisperCli => 'Whisper CLI';

  @override
  String get configValueDemoMode => 'Mode démo (Simulé)';

  @override
  String get configLabelFfmpegCli => 'FFmpeg CLI';

  @override
  String get configValueSystemPathDefault =>
      'Valeur par défaut du PATH système';

  @override
  String get configLabelAssetsLocation => 'Emplacement des ressources';

  @override
  String get filePickerAssetsDialogTitle =>
      'Sélectionner le dossier de ressources CapStudio';

  @override
  String errorSelectFolderFailed(String error) {
    return 'Échec de la sélection du dossier : $error';
  }

  @override
  String errorResetFailed(String error) {
    return 'Échec de la réinitialisation : $error';
  }

  @override
  String errorVerificationFailed(String error) {
    return 'Échec de la vérification : $error';
  }

  @override
  String errorAssetsFolderStillMissing(String path) {
    return 'Dossier de ressources toujours introuvable à : $path';
  }

  @override
  String get dbRecoveredTitle => 'Base de données récupérée automatiquement';

  @override
  String dbRecoveredBody(String backupPath) {
    return 'Une incompatibilité de schéma ou une altération de la base de données a été détectée. La base de données a été réinitialisée et vos données précédentes ont été sauvegardées sous :\n\n$backupPath';
  }

  @override
  String errorDemoLoadFailed(String error) {
    return 'Échec du chargement de la vidéo de démonstration : $error';
  }

  @override
  String importProgressPercent(int percent) {
    return '$percent % effectué';
  }

  @override
  String get errorInvalidDropFileFormat =>
      'Format de fichier non valide. Veuillez déposer un fichier vidéo.';

  @override
  String get findTextLabel => 'Rechercher du texte';

  @override
  String get replaceWithLabel => 'Remplacer par';

  @override
  String findReplaceSuccessCount(int count) {
    return '$count occurrences remplacées !';
  }

  @override
  String get btnReplaceAll => 'TOUT REMPLACER';

  @override
  String errorVideoFileNotFound(String path) {
    return 'Fichier vidéo introuvable :\n$path\nVeuillez reconnecter le fichier vidéo.';
  }

  @override
  String get errorTranscriptionFailed =>
      'Échec de la transcription. Veuillez réessayer.';

  @override
  String transcriptionActiveModel(String quality, String model) {
    return 'Actif : $quality ($model)';
  }

  @override
  String get badgeRecommended => 'REC';

  @override
  String get languageLabel => 'Langue';

  @override
  String warningEnglishOnlyModel(String model, String language) {
    return 'Avertissement : le modèle sélectionné ($model) est exclusivement en anglais. Transcrire en \"$language\" échouera ou produira des sous-titres en anglais. Veuillez choisir un modèle multilingue (ex. Tiny ou Base).';
  }

  @override
  String get tipAutoDetectMixedLanguage =>
      'Astuce : la détection automatique est déconseillée pour les langues mixtes (comme l\'anglais mélangé). Sélectionner explicitement votre langue parlée (ex. hindi ou anglais) fournira des sous-titres beaucoup plus précis.';

  @override
  String get detectedHardwareLabel => 'Matériel système détecté :';

  @override
  String hardwareRamSize(String ramGB) {
    return 'Mémoire RAM : $ramGB Go';
  }

  @override
  String hardwareCpuCores(int cores) {
    return 'Cœurs logiques CPU : $cores';
  }

  @override
  String hardwareGpuDevice(String gpu) {
    return 'Périphérique GPU : $gpu';
  }

  @override
  String get hardwareDetecting =>
      'Détection des caractéristiques matérielles...';

  @override
  String get btnStartReTranscribe => 'DÉMARRER LA RE-TRANSCRIPTION';

  @override
  String get btnImportSrtVtt => 'IMPORTER UN FICHIER SRT/VTT';

  @override
  String importedSubtitleWords(int count) {
    return '$count mots importés depuis le fichier de sous-titres.';
  }

  @override
  String get errorImportSubtitleFailed =>
      'Échec de l\'importation du fichier de sous-titres. Veuillez vérifier le format du fichier.';

  @override
  String get noProjectLoaded => 'Aucun projet chargé';

  @override
  String get badge916Vertical => 'VERTICAL 9:16';

  @override
  String get badge169Landscape => 'PAYSAGE 16:9';

  @override
  String get reframeTargetCanvas =>
      'Zone de travail cible : 1080 × 1920 (TikTok, YouTube Shorts, Instagram Reels)';

  @override
  String get reframeModeLabel => 'Mode de recadrage :';

  @override
  String get reframeModeBlurPillarbox => 'Flou d\'arrière-plan (Recommandé)';

  @override
  String get reframeModeBlurPillarboxDesc =>
      'Met à l\'échelle et floute la vidéo en arrière-plan pour remplir le 9:16, tout en gardant la vidéo centrale nette.';

  @override
  String get reframeModeCenterCrop => 'Recadrage intelligent au centre';

  @override
  String get reframeModeCenterCropDesc =>
      'Remplit tout l\'écran 9:16 en rognant les bords gauche et droit.';

  @override
  String get reframeModeSplitScreen => 'Écran partagé / Double calque';

  @override
  String get reframeModeSplitScreenDesc =>
      'Superpose deux fenêtres vidéo verticalement (idéal pour les réactions et les dialogues de podcasts).';

  @override
  String get btnResetTo169 => 'ACTUELLEMENT EN 9:16 (RÉTABLIR EN 16:9)';

  @override
  String get btnSetCanvas916 => 'DÉFINIR LA ZONE DU PROJET EN 9:16';

  @override
  String get silenceRemovalDesc =>
      'Supprime automatiquement les silences et bruits de respiration pour maximiser la rétention vidéo.';

  @override
  String get silenceAggressivenessLabel => 'Agressivité de coupe :';

  @override
  String silenceNoiseGateLabel(int db) {
    return 'Seuil de bruit de silence : $db dB';
  }

  @override
  String silenceMinPauseLabel(String duration) {
    return 'Pause minimale : $duration s';
  }

  @override
  String get btnScanning => 'ANALYSE EN COURS...';

  @override
  String silenceNoneFound(String duration) {
    return 'Aucun silence supérieur à $duration s n\'a été trouvé.';
  }

  @override
  String silenceFoundCount(int count, String totalSecs) {
    return '$count silences détectés ($totalSecs s de temps mort supprimées) !';
  }

  @override
  String errorScanningAudio(String error) {
    return 'Erreur lors de l\'analyse audio : $error';
  }

  @override
  String jumpCutsApplied(int count) {
    return '$count jump-cuts appliqués à la timeline du projet !';
  }

  @override
  String get viralHooksDesc =>
      'Analyse les mots transcrits pour détecter plus de 80 accroches virales, le rythme (120–170 MPM), les questions, la densité énergétique et les limites de clips.';

  @override
  String get btnAnalyzingTranscript => 'ANALYSE DE LA TRANSCRIPTION...';

  @override
  String get selectAllLabel => 'Tout sélectionner';

  @override
  String selectedCountOf(int selected, int total) {
    return '$selected sur $total sélectionné(s)';
  }

  @override
  String get btnSelectClipsToBatchExport =>
      'SÉLECTIONNER LES CLIPS À EXPORTER EN LOT';

  @override
  String btnBatchExportCount(int count) {
    return 'EXPORTER EN LOT $count CLIP(S)';
  }

  @override
  String get viralNoClipsDetected =>
      'Aucun clip viral à score élevé détecté dans cette plage de durée vidéo.';

  @override
  String get badgeCleanCut => 'COUPE NETTE';

  @override
  String get badgeFirst5s => '5 PREMIÈRES SEC';

  @override
  String get btnPreview => 'Aperçu';

  @override
  String get btnTrim => 'Découper';

  @override
  String get tooltipForkAs916 => 'Créer un nouveau projet Short 9:16 dérivé';

  @override
  String wpmLabelOk(int wpm) {
    return '$wpm MPM ✓';
  }

  @override
  String wpmLabelFast(int wpm) {
    return '$wpm MPM RAPIDE';
  }

  @override
  String wpmLabelSlow(int wpm) {
    return '$wpm MPM LENT';
  }

  @override
  String hookScoreLabel(int score) {
    return 'Accroche $score/40';
  }

  @override
  String energyScoreLabel(int score) {
    return 'Énergie $score/20';
  }

  @override
  String get filePickerClipsFolderTitle =>
      'Choisir le dossier de sauvegarde des clips';

  @override
  String get errorChooseOutputFolderFirst =>
      'Veuillez d\'abord choisir un dossier de sortie.';

  @override
  String batchExportSheetTitle(int count) {
    return 'EXPORTATION EN LOT DE $count CLIP(S)';
  }

  @override
  String get tapToChooseOutputFolder =>
      'Appuyez pour choisir le dossier de sortie…';

  @override
  String get burnCaptionsOnClipsLabel =>
      'Incruster des sous-titres dynamiques sur les clips';

  @override
  String get burnCaptionsOnClipsDesc =>
      'Incruste des sous-titres animés et stylisés synchronisés avec l\'audio du clip';

  @override
  String exportCancelledProgress(int done, int total) {
    return 'Exportation annulée. $done/$total terminé(s).';
  }

  @override
  String exportProgressSummary(int done, int total, int failed) {
    return '$done/$total exporté(s) · $failed en échec';
  }

  @override
  String get btnExporting => 'EXPORTATION EN COURS…';

  @override
  String get btnExportComplete => 'EXPORTATION TERMINÉE ✓';

  @override
  String get btnStartExport => 'LANCER L\'EXPORTATION';

  @override
  String exportClipSavedAt(String path) {
    return '✓ Enregistré : $path';
  }

  @override
  String projectTrimmedToClip(int rank, String start, String end) {
    return 'Projet ajusté au clip viral n°$rank ($start - $end) !';
  }

  @override
  String shortProjectCreated(String name) {
    return 'Short 9:16 créé : \"$name\"';
  }

  @override
  String get btnOpen => 'OUVRIR';

  @override
  String errorCreateShortProjectFailed(String error) {
    return 'Échec de la création du projet Short : $error';
  }

  @override
  String get autoDetect => 'Détection automatique';

  @override
  String presetSaved(String name) {
    return 'Préréglage de style « $name » enregistré avec succès !';
  }

  @override
  String get presetDeleted => 'Préréglage supprimé avec succès.';

  @override
  String get presetExported => 'Préréglages de style exportés avec succès !';

  @override
  String errorPresetExportFailed(String error) {
    return 'Échec de l\'exportation des préréglages : $error';
  }

  @override
  String get presetImported => 'Préréglages de style importés avec succès !';

  @override
  String errorPresetImportFailed(String error) {
    return 'Échec de l\'importation des préréglages : $error';
  }

  @override
  String get selectFontFileDialogTitle =>
      'Sélectionner un fichier de police TTF ou OTF';

  @override
  String get fontWeightThin => 'Fin';

  @override
  String get fontWeightExtraLight => 'Extra fin';

  @override
  String get fontWeightLight => 'Léger';

  @override
  String get fontWeightNormal => 'Normal';

  @override
  String get fontWeightMedium => 'Moyen';

  @override
  String get fontWeightSemiBold => 'Semi-gras';

  @override
  String get fontWeightBold => 'Gras';

  @override
  String get fontWeightExtraBold => 'Extra gras';

  @override
  String get fontWeightBlack => 'Ultra gras';

  @override
  String get fontCaseNormal => 'Normal';

  @override
  String get fontCaseUppercase => 'MAJUSCULES';

  @override
  String get fontCaseCapitalize => 'Première lettre en majuscule';

  @override
  String get strokeStyleThickOutline => 'Contour épais';

  @override
  String get strokeStyleNoneFlat => 'Aucun (Plat)';

  @override
  String get shadowStyleSoft => 'Ombre douce';

  @override
  String get shadowStyleNone => 'Aucune';

  @override
  String get animStyleActivePop => 'Pop actif';

  @override
  String get animStyleActiveBounce => 'Rebond actif';

  @override
  String get animStyleKineticTilt => 'Inclinaison cinétique rebondissante';

  @override
  String get animStyleGlowPulse => 'Pulsation lumineuse active';

  @override
  String get animStyleWordReveal => 'Apparition échelonnée des mots';

  @override
  String get animStyleNoneStatic => 'Aucun (Statique)';

  @override
  String fontImportedSuccess(String name) {
    return 'Police personnalisée importée et appliquée avec succès : « $name »';
  }

  @override
  String get errorFontImportFailed =>
      'Échec du chargement du fichier de police. Données non valides.';

  @override
  String get invalidTimingError =>
      'Minutages de début/fin non valides. Le début doit être >= 0 et la fin doit être >= au début et <= à la durée de la vidéo.';

  @override
  String get projectSavedSuccess => 'Projet enregistré avec succès.';

  @override
  String wordDeletedSuccess(String text) {
    return 'Mot supprimé : « $text »';
  }

  @override
  String get splitClip => 'Scinder le clip';

  @override
  String get removeClip => 'Supprimer le clip';

  @override
  String get resetToOriginal => 'Rétablir l\'original';

  @override
  String splitTimelineAt(String time) {
    return 'Timeline scindée à $time s.';
  }

  @override
  String get splitTimelineError =>
      'La tête de lecture doit être située dans la région active pour pouvoir scinder.';

  @override
  String get exclusionToggled =>
      'Exclusion du segment sous la tête de lecture activée/désactivée.';

  @override
  String get splitsReset =>
      'Toutes les scissions et exclusions de la timeline ont été réinitialisées.';

  @override
  String get shareVideo => 'Partager la vidéo';

  @override
  String get openOutputFolder => 'Ouvrir le dossier de sortie';

  @override
  String get errorLogCopied =>
      'Journal des erreurs copié dans le presse-papiers.';

  @override
  String get diagnosticsExported =>
      'Rapport de diagnostic filtré ouvert dans la feuille de partage.';

  @override
  String errorDiagnosticsFailed(String error) {
    return 'Échec de l\'exportation du rapport de diagnostic : $error';
  }

  @override
  String logLineCopied(String message) {
    return 'Ligne de journal copiée dans le presse-papiers : « $message »';
  }

  @override
  String commandCopied(String command) {
    return 'Copié : « $command »';
  }

  @override
  String get settingsRestored => 'Paramètres rétablis par défaut.';

  @override
  String get gpuEncoderNoneCpu => 'Aucun (CPU)';

  @override
  String get gpuEncoderNvidia => 'NVIDIA NVENC';

  @override
  String get gpuEncoderAmd => 'AMD AMF';

  @override
  String get gpuEncoderIntel => 'Intel QSV';

  @override
  String get gpuEncoderApple => 'Apple VideoToolbox';

  @override
  String get btnDownloadVcRedist => 'TÉLÉCHARGER VC++ REDISTRIBUTABLE';

  @override
  String errorDownloadToolFailed(String error) {
    return 'Échec du téléchargement de l\'outil : $error';
  }

  @override
  String get errorFolderNotAccessible =>
      'Le dossier sélectionné n\'existe pas ou n\'est pas accessible.';

  @override
  String modelDeleted(String name) {
    return 'Modèle supprimé : $name';
  }

  @override
  String errorModelDeleteFailed(String error) {
    return 'Échec de la suppression du modèle : $error';
  }

  @override
  String errorModelDownloadFailed(String name, String error) {
    return 'Échec du téléchargement du modèle $name : $error';
  }

  @override
  String errorOpenFolderFailed(String path) {
    return 'Impossible d\'ouvrir le dossier automatiquement. Chemin : $path';
  }

  @override
  String errorDownloadPackFailed(String error) {
    return 'Échec du téléchargement du pack : $error';
  }

  @override
  String errorPackDownloadNamedFailed(String name, String error) {
    return 'Échec du téléchargement du pack $name : $error';
  }

  @override
  String get stickersIndexRefreshed =>
      'Index des stickers personnalisés actualisé avec succès !';

  @override
  String errorChangeAssetFolderFailed(String error) {
    return 'Échec du changement de dossier de ressources : $error';
  }

  @override
  String errorSetAssetFolderFailed(String error) {
    return 'Échec de la définition du dossier de ressources : $error';
  }

  @override
  String get warningNoAvx =>
      'Absence de prise en charge AVX détectée ! Téléchargement de whisper-cli compatible (sans AVX)...';

  @override
  String get errorAutoDetectWhisper =>
      'Impossible de détecter automatiquement whisper-cli. Veuillez parcourir vos fichiers manuellement.';

  @override
  String get errorAutoDetectFfmpeg =>
      'Impossible de détecter automatiquement ffmpeg. Veuillez parcourir vos fichiers manuellement.';

  @override
  String errorToolDownloadFailed(String error) {
    return 'Échec du téléchargement de l\'outil : $error';
  }

  @override
  String get returnToDashboard => 'Retour au tableau de bord';

  @override
  String errorImportVideoFailed(String error) {
    return 'Échec de l\'importation : $error';
  }

  @override
  String get videoRelinkedSuccess => 'Vidéo reconnectée avec succès !';

  @override
  String get errorRelinkVideoFailed => 'Échec de la reconnexion de la vidéo.';

  @override
  String get retranscriptionSuccess => 'Re-transcription réussie !';

  @override
  String get retranscriptionFailed => 'Échec de la re-transcription.';
}
