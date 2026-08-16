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
}
