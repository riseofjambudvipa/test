// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appName => 'CapStudio';

  @override
  String get dashboardTitle => 'Meus Projetos';

  @override
  String get dashboardSubtitle =>
      'Estúdio offline de legendagem e transcrição com IA';

  @override
  String get importVideo => 'Importar Vídeo';

  @override
  String get dragDropText => 'Arraste e solte seu arquivo de vídeo aqui';

  @override
  String get clickBrowse => 'ou clique para navegar pelos arquivos locais';

  @override
  String get demoMode => 'MODO DE DEMONSTRAÇÃO';

  @override
  String get demoModeDesc =>
      'Carregue um projeto de demonstração para testar os estilos e recursos do editor.';

  @override
  String get warningAssets => 'Recuperação de pasta de recursos necessária';

  @override
  String get warningAssetsDesc =>
      'Os recursos integrados não foram encontrados na pasta de suporte do app. Clique duas vezes aqui para restaurar ou alterar o diretório de recursos.';

  @override
  String get deleteProjectTitle => 'Excluir Projeto';

  @override
  String deleteProjectConfirm(String projectName) {
    return 'Tem certeza de que deseja excluir permanentemente \"$projectName\"? Esta ação não pode ser desfeita.';
  }

  @override
  String get renameProjectTitle => 'Renomear Projeto';

  @override
  String get projectNameLabel => 'Nome do Projeto';

  @override
  String get btnCancel => 'CANCELAR';

  @override
  String get btnDelete => 'EXCLUIR';

  @override
  String get btnRename => 'RENOMEAR';

  @override
  String get btnSave => 'SALVAR';

  @override
  String get btnConfirm => 'CONFIRMAR';

  @override
  String get btnExport => 'EXPORTAR';

  @override
  String get btnUndo => 'Desfazer';

  @override
  String get btnRedo => 'Refazer';

  @override
  String get statusDraft => 'Rascunho';

  @override
  String get statusCompleted => 'Concluído';

  @override
  String get createdLabel => 'Criado em:';

  @override
  String get durationLabel => 'Duração:';

  @override
  String get statusLabel => 'Status:';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsGeneral => 'Configurações Gerais';

  @override
  String get settingsTheme => 'Tema do aplicativo';

  @override
  String get themeSystem => 'Padrão do Sistema';

  @override
  String get themeLight => 'Modo Claro';

  @override
  String get themeDark => 'Modo Escuro';

  @override
  String get settingsLanguage => 'Idioma da interface';

  @override
  String get settingsTranscription => 'Configurações de Transcrição';

  @override
  String get settingsWhisperModel => 'Modelo do Whisper';

  @override
  String get settingsWhisperModelDesc =>
      'Selecione o modelo para transcrição. Modelos menores são mais rápidos; maiores são mais precisos.';

  @override
  String get settingsTranscribeLang => 'Idioma da transcrição';

  @override
  String get settingsAutoDetect => 'Detectar idioma automaticamente';

  @override
  String get settingsGPU => 'Aceleração por GPU (CUDA)';

  @override
  String get settingsVAD => 'Limiar de VAD (Atividade de Voz)';

  @override
  String get settingsExport => 'Configurações de Exportação';

  @override
  String get settingsExportDest => 'Diretório de exportação padrão';

  @override
  String get settingsBrowse => 'Procurar';

  @override
  String get settingsEmojiPacks => 'Pacotes de Emojis e Estilos';

  @override
  String get settingsEmojiPacksDesc =>
      'Personalize estilos de exibição de emojis e recursos de legenda ativos.';

  @override
  String get settingsEmojiSearchLang => 'Idioma de pesquisa de emojis';

  @override
  String get settingsBtnManagePacks => 'GERENCIAR PACOTES DE EMOJIS';

  @override
  String get systemTitle => 'Informações do Sistema';

  @override
  String get systemVersion => 'Versão';

  @override
  String get systemReset => 'Redefinir Padrões';

  @override
  String get editorTabCaptions => 'Legendas';

  @override
  String get editorTabStyles => 'Estilos';

  @override
  String get editorTabTrim => 'Cortar';

  @override
  String get editorTabAudio => 'Áudio';

  @override
  String get editorTabTranscription => 'Transcrição';

  @override
  String get editorTabShortcuts => 'Atalhos';

  @override
  String get editorTabDebug => 'Depuração';

  @override
  String get editorHeaderBack => 'Voltar';

  @override
  String get editorKeyboardShortcuts => 'Atalhos de Teclado';

  @override
  String get dialogAnalyzing => 'Analisando vídeo...';

  @override
  String get dialogTranscribing => 'Transcrevendo áudio...';

  @override
  String get dialogExtracting => 'Extraindo áudio...';

  @override
  String get dialogWait =>
      'Isso pode levar alguns instantes. Por favor, aguarde.';

  @override
  String get dialogError => 'Erro';

  @override
  String get dialogImportFailed => 'Falha ao importar o vídeo.';

  @override
  String get noProjects => 'Nenhum projeto criado ainda';

  @override
  String get aboutApp => 'Sobre o CapStudio';

  @override
  String get aboutAppDesc =>
      'Detalhes sobre o CapStudio, créditos e licenças de código aberto.';

  @override
  String get aboutAppThanks =>
      'Agradecimento especial aos projetos de código aberto que tornam o CapStudio possível:';

  @override
  String get btnViewAllLicenses => 'VER LICENÇAS DE TODOS OS PACOTES';
}
