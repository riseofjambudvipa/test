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

  @override
  String get exportBurnIn => 'EXPORTAÇÃO DE VÍDEO COM LEGENDAS INCORPORADAS';

  @override
  String get exportTimecodeFormats =>
      'FORMATOS DE LEGENDAS COM CÓDIGO DE TEMPO';

  @override
  String get exportWebEnabled =>
      'A exportação de vídeo no lado do cliente está ativada. A renderização é executada localmente no seu navegador.';

  @override
  String get exportWebCaptionOnly =>
      'A exportação para a web atualmente inclui apenas legendas — emojis e efeitos sonoros ainda não são incorporados ao vídeo. Exporte pelo aplicativo de desktop ou celular para obter o resultado completo.';

  @override
  String get exportOutputName => 'Nome do vídeo de saída';

  @override
  String get exportMode => 'Modo de exportação';

  @override
  String get exportModeFast => 'Rápido (FFmpeg nativo)';

  @override
  String get exportModeFastUnsupported =>
      'Rápido (FFmpeg nativo) ⚠️ Sem suporte';

  @override
  String get exportModeSlow => 'Lento (Renderização 1:1 da pré-visualização)';

  @override
  String get exportTargetFps => 'FPS alvo';

  @override
  String get exportFps24 => '24 FPS (Cinema)';

  @override
  String get exportFps25 => '25 FPS (PAL)';

  @override
  String get exportFps30 => '30 FPS (Padrão)';

  @override
  String get exportFps50 => '50 FPS';

  @override
  String get exportFps60 => '60 FPS (Suave)';

  @override
  String get exportFastUnsupported =>
      'O modo rápido não é suportado neste dispositivo porque a versão do FFmpeg do sistema não inclui filtros de renderização de legendas (libass). O modo lento será usado.';

  @override
  String get exportSlowInfo =>
      'Captura cada quadro exatamente como exibido na pré-visualização. Isso garante legendas perfeitas pixel a pixel, mas renderiza mais devagar.';

  @override
  String get exportDestDirectory => 'DIRETÓRIO DE DESTINO';

  @override
  String get exportDestBrowser => 'Local de download do navegador';

  @override
  String get exportDestAndroid =>
      'Pasta Downloads (/storage/emulated/0/Download)';

  @override
  String get exportDestIos =>
      'Documentos do aplicativo (folha de compartilhamento após a exportação)';

  @override
  String get exportChooseFolder => 'Escolher pasta de saída';

  @override
  String get exportStartMp4 => 'INICIAR EXPORTAÇÃO MP4';

  @override
  String get exportSrtTitle => 'Legendas SubRip (.srt)';

  @override
  String get exportSrtDesc =>
      'Padrão universal com código de tempo. Compatível com YouTube, VLC e Premiere Pro.';

  @override
  String get exportVttTitle => 'Legendas WebVTT (.vtt)';

  @override
  String get exportVttDesc =>
      'Formato de legendas otimizado para a web, amplamente usado em players HTML5 e streaming online.';

  @override
  String get exportAssTitle => 'Advanced SubStation Alpha (.ass)';

  @override
  String get exportAssDesc =>
      'Formato profissional que incorpora tamanhos de fonte, estilos, margens e destaques em linha.';

  @override
  String get exportTxtTitle => 'Transcrição em texto simples (.txt)';

  @override
  String get exportTxtDesc =>
      'Transcrição linha por linha com marcadores de prefixo de carimbo de data/hora.';

  @override
  String exportSuccess(String type) {
    return '$type exportado com sucesso!';
  }

  @override
  String get exportNoLocation =>
      'Nenhum local de salvamento selecionado. Escolha um caminho de arquivo.';

  @override
  String get exportNoLocationCancelled =>
      'Nenhum local de salvamento selecionado. Exportação cancelada.';

  @override
  String exportFailed(String error) {
    return 'Falha ao exportar: $error';
  }

  @override
  String get exportCopySrtTooltip => 'Copiar SRT para a área de transferência';

  @override
  String get exportCopiedSrt => 'SRT copiado para a área de transferência!';

  @override
  String exportCopyFailedSrt(String error) {
    return 'Falha ao copiar SRT: $error';
  }

  @override
  String exportSubtitlesDialogTitle(String type) {
    return 'Exportar legendas $type';
  }

  @override
  String get exportVideoDialogTitle => 'Exportar vídeo MP4';

  @override
  String get ffmpegRequiredTitle => 'FFmpeg necessário';

  @override
  String get ffmpegRequiredBody =>
      'É necessária uma instalação local do FFmpeg para incorporar legendas em um arquivo de vídeo.\n\nConfigure o caminho do FFmpeg nas Configurações.';

  @override
  String get okLabel => 'OK';

  @override
  String get exportWebTitle => 'Exportando vídeo (lado do cliente)';

  @override
  String exportWebSuccess(String fileName) {
    return 'Vídeo exportado com sucesso como $fileName!';
  }

  @override
  String exportWebFailed(String error) {
    return 'Falha na renderização: $error';
  }

  @override
  String get viralShortsTitle => 'ESTÚDIO DE SHORTS VIRAIS';

  @override
  String get viralShortsSubtitle =>
      'Reenquadramento vertical 9:16, jump-cuts de silêncio e detector de ganchos com IA';

  @override
  String get viralReframeTitle => '1. REENQUADRAMENTO VERTICAL 9:16';

  @override
  String get viralSilenceTitle => '2. REMOÇÃO DE SILÊNCIO (JUMP-CUTS)';

  @override
  String get viralHooksTitle => '3. DETECTOR DE GANCHOS VIRAIS COM IA';

  @override
  String get btnFindViralMoments => 'ENCONTRAR MOMENTOS VIRAIS';

  @override
  String get btnScanSilences => 'BUSCAR SILÊNCIOS';

  @override
  String get btnApplyJumpCuts => 'APLICAR JUMP-CUTS';

  @override
  String get editorTabShorts => 'Shorts';

  @override
  String get editorTabClips => 'Clipes';

  @override
  String get captionList => 'LISTA DE LEGENDAS';

  @override
  String get uncertainLabel => 'Incerto (<40%)';

  @override
  String get mediumConfidenceLabel => 'Médio (40-60%)';

  @override
  String get jumpToUncertain => 'Pular para a próxima palavra incerta';

  @override
  String get noUncertainWords => 'Nenhuma palavra incerta encontrada.';

  @override
  String get findAndReplace => 'Localizar e substituir';

  @override
  String get addWordTitle => 'Adicionar palavra';

  @override
  String get editWordTitle => 'Editar palavra';

  @override
  String get wordTextLabel => 'Texto da palavra';

  @override
  String get startTimeLabel => 'Tempo inicial (s)';

  @override
  String get endTimeLabel => 'Tempo final (s)';

  @override
  String get splitChunk => 'Dividir trecho';

  @override
  String get insertLineAfter => 'Inserir linha depois';

  @override
  String get duplicateLine => 'Duplicar linha';

  @override
  String get deleteLine => 'Excluir linha';

  @override
  String get chooseSfxTitle => 'Escolher efeito sonoro';

  @override
  String get searchSfxPlaceholder => 'Pesquisar SFX...';

  @override
  String get noSfxFound => 'Nenhum efeito sonoro encontrado';

  @override
  String get emojiSearch => 'Pesquisa de emojis';

  @override
  String get noEmojisFound => 'Nenhum emoji encontrado.';

  @override
  String get mySavedPresets => 'MINHAS PREDEFINIÇÕES SALVAS';

  @override
  String get btnImport => 'IMPORTAR';

  @override
  String get btnExportCaps => 'EXPORTAR';

  @override
  String get btnSaveCurrent => 'SALVAR ATUAL';

  @override
  String get resetToDefault => 'Redefinir para padrão';

  @override
  String get resetConfirmBody =>
      'Isso redefinirá todos os estilos de legendas para o padrão. Não pode ser desfeito.';

  @override
  String get btnReset => 'Redefinir';

  @override
  String get wordHighlightBox => 'Caixa de destaque de palavra';

  @override
  String get wordHighlightBoxDesc =>
      'Fundo colorido estilo pílula atrás das palavras faladas ativas';

  @override
  String get maxWordsPerChunk => 'Máximo de palavras por trecho de legenda';

  @override
  String get maxCharsPerLine => 'Máximo de caracteres por linha de legenda';

  @override
  String get fontSettings => 'Configurações de fonte';

  @override
  String get colorSettings => 'Configurações de cor';

  @override
  String get borderSettings => 'Configurações de borda e sombra';

  @override
  String get speechToTextTitle => 'TRANSCRIÇÃO DE FALA EM TEXTO';

  @override
  String get speechToTextDesc =>
      'Executar novamente a transcrição local de fala em texto. Quaisquer edições manuais ou ajustes de tempo serão substituídos.';

  @override
  String get useLocalAi => 'Usar transcrição local por IA';

  @override
  String get runOnDeviceDesc =>
      'Executar reconhecimento de fala diretamente neste dispositivo';

  @override
  String get offlineDemoModeActive =>
      'O modo de demonstração offline está ativo. A transcrição local do Whisper AI não é suportada na Web.';

  @override
  String get demoModeNote =>
      'O modo de demonstração gera instantaneamente tokens de transcrição altamente realistas. Perfeito para testar estilos, modelos e operações da linha do tempo sem configuração.';

  @override
  String get transcriptionQuality => 'Qualidade da transcrição';

  @override
  String get advancedSettings => 'Configurações avançadas';

  @override
  String get cpuThreadsLabel => 'Threads de CPU';

  @override
  String get vadSensitivity => 'Sensibilidade de VAD';

  @override
  String get translateToEnglish => 'Traduzir legendas para o inglês';

  @override
  String get startTranscriptionBtn => 'INICIAR TRANSCRIÇÃO';

  @override
  String get hardwareLocked => 'Bloqueado por hardware';

  @override
  String get btnDownload => 'Baixar';

  @override
  String get welcomeTitle => 'Bem-vindo ao CapStudio';

  @override
  String get welcomeSubtitle =>
      'Legendas de alta precisão e shorts virais, 100% offline.';

  @override
  String get setupAssetDirTitle => 'Escolher diretório de recursos';

  @override
  String get setupAssetDirDesc =>
      'Selecione um diretório para armazenar modelos, fontes e pacotes de emojis.';

  @override
  String get downloadPacksTitle => 'Baixar pacotes de conteúdo (Opcional)';

  @override
  String get downloadPacksDesc =>
      'Fontes e efeitos sonoros opcionais para seus projetos de vídeo.';

  @override
  String get setupCompleteTitle => 'Configuração concluída';

  @override
  String get setupCompleteDesc =>
      'Você está pronto para criar vídeos incríveis com legendas.';

  @override
  String get btnGetStarted => 'Começar';

  @override
  String get btnNext => 'PRÓXIMO';

  @override
  String get btnSkip => 'PULAR';

  @override
  String get onboardingFeaturePrivacy => '100% de Privacidade';

  @override
  String get onboardingFeaturePrivacyDesc =>
      'Seus arquivos nunca saem do seu dispositivo. Todos os modelos de IA rodam localmente.';

  @override
  String get onboardingFeatureGpu => 'Reprodução acelerada por GPU';

  @override
  String get onboardingFeatureGpuDesc =>
      'Edição de vídeo de alto desempenho com decodificação por hardware.';

  @override
  String get onboardingFeatureAssets => 'Recursos sidecar offline';

  @override
  String get onboardingFeatureAssetsDesc =>
      'Baixe pacotes completos de emojis uma vez e execute totalmente offline.';

  @override
  String get onboardingReadyTitle => 'Tudo pronto para começar!';

  @override
  String get onboardingConfigDetails => 'Detalhes da configuração:';

  @override
  String get btnLaunchCapStudio => 'Iniciar o CapStudio';

  @override
  String get assetVerificationFailed =>
      'Falha na verificação de recursos. Certifique-se de que os recursos foram baixados corretamente.';

  @override
  String get assetsFolderNotFound => 'Pasta de recursos não encontrada';

  @override
  String get assetsFolderNotFoundDesc =>
      'O CapStudio não conseguiu localizar a pasta de recursos no local configurado. Se a pasta estiver em uma unidade externa, conecte-a.';

  @override
  String get expectedPathLabel => 'CAMINHO ESPERADO:';

  @override
  String get browseNewLocation => 'Navegar para novo local';

  @override
  String get resetToDefaultPath => 'Redefinir para o caminho padrão';

  @override
  String get retryVerification => 'Tentar verificação novamente';

  @override
  String get storagePathFolder => 'Pasta de caminho de armazenamento';

  @override
  String get tipWindowsDrive =>
      'Dica: Se a unidade C: tiver pouco espaço, escolha um caminho em D: ou E: para mais capacidade.';

  @override
  String get tipGeneralDrive =>
      'Dica: Você pode selecionar o caminho de uma unidade externa se o volume raiz estiver cheio.';

  @override
  String get confirmLocation => 'Confirmar local';

  @override
  String get requiredBadge => 'OBRIGATÓRIO';

  @override
  String get emojiPacksHeader => 'PACOTES DE EMOJIS';

  @override
  String get fontPacksHeader => 'PACOTES DE FONTES';

  @override
  String get connectCliTitle => 'Conectar ferramentas CLI locais';

  @override
  String get connectCliDesc =>
      'O CapStudio precisa dos binários do whisper.cpp e FFmpeg para realizar a transcrição e exportar vídeos localmente.';

  @override
  String get skipSetup => 'Pular configuração por enquanto';

  @override
  String get btnValidate => 'Validar';

  @override
  String get autoDetectAndValidate => 'Detectar e validar automaticamente';

  @override
  String get whisperCliPathLabel => 'Caminho do executável do Whisper CLI';

  @override
  String get ffmpegCliPathLabel => 'Caminho do executável do FFmpeg CLI';

  @override
  String get newProject => 'Novo Projeto';

  @override
  String get searchProjects => 'Pesquisar projetos...';

  @override
  String get filterAll => 'Todos';

  @override
  String get sortByRecent => 'Mais recentes';

  @override
  String get sortByDuration => 'Duração';

  @override
  String get noMatchingProjects => 'Nenhum projeto corresponde à sua pesquisa';

  @override
  String get btnEdit => 'EDITAR';

  @override
  String get btnDuplicate => 'DUPLICAR';

  @override
  String get tooltipEdit => 'Editar';

  @override
  String get tooltipRename => 'Renomear';

  @override
  String get tooltipDuplicate => 'Duplicar';

  @override
  String get tooltipDelete => 'Excluir';

  @override
  String get tooltipTheme => 'Tema';

  @override
  String get tooltipSettings => 'Configurações';

  @override
  String get selectDemoFormat => 'SELECIONAR FORMATO DA DEMO';

  @override
  String get selectDemoDesc =>
      'Selecione um formato de layout para pré-visualizar instantaneamente o mecanismo de legendas de alta fidelidade do CapStudio, animações palavra por palavra ao vivo e formas de onda de áudio.';

  @override
  String get landscapeDemo => 'Demo horizontal';

  @override
  String get landscapeDemoDesc =>
      'Perfeito para YouTube, desktop e apresentações.';

  @override
  String get portraitDemo => 'Demo vertical';

  @override
  String get portraitDemoDesc =>
      'Ideal para TikTok, Shorts, Reels e dispositivos móveis.';

  @override
  String get format16x9 => 'Formato 16:9';

  @override
  String get format9x16 => 'Formato 9:16';

  @override
  String get dropVideoHere => 'SOLTE O VÍDEO AQUI';

  @override
  String get dropVideoSupported => 'Suporta MP4, MOV, AVI, etc.';

  @override
  String get statusLocalOffline => 'LOCAL OFFLINE';

  @override
  String get speechModelTitle => 'Modelo de reconhecimento de fala';

  @override
  String get hardwareUpgradesTitle => 'Upgrades de desempenho de hardware';

  @override
  String get showAdvancedPaths => 'MOSTRAR CONFIGURAÇÃO AVANÇADA DE CAMINHOS';

  @override
  String get hideAdvancedPaths => 'OCULTAR CONFIGURAÇÃO AVANÇADA DE CAMINHOS';

  @override
  String get autoDownload => 'DOWNLOAD AUTOMÁTICO';

  @override
  String get gpuAcceleratedTranscription =>
      'Transcrição acelerada por GPU (CUDA)';

  @override
  String get gpuRequiresNvidia => 'Requer GPU NVIDIA com suporte a CUDA';

  @override
  String get gpuExportEncoder => 'Codificador de exportação por GPU';

  @override
  String get gpuExportEncoderDesc =>
      'Aceleração por hardware para exportação de vídeo MP4';

  @override
  String get defaultLanguage => 'Idioma padrão';

  @override
  String get vadTitle => 'Detecção de atividade de voz (VAD)';

  @override
  String get vadDesc => 'Ignora regiões silenciosas durante o processamento';

  @override
  String get vadThreshold => 'Limiar de VAD';

  @override
  String get autoSaveTitle => 'Salvamento automático';

  @override
  String get autoSaveDesc =>
      'Salva automaticamente as edições do projeto no banco de dados a cada 3 segundos';

  @override
  String get defaultOutputsTitle => 'Saídas padrão';

  @override
  String get defaultExportFolder => 'Pasta de exportação padrão';

  @override
  String get alwaysAskExportPath => 'Sempre perguntar o caminho de exportação';

  @override
  String get alwaysAskExportPathDesc =>
      'Solicita o caminho de saída a cada exportação (Desktop)';

  @override
  String get performanceTitle => 'Desempenho';

  @override
  String get exportCpuThreads => 'Threads de CPU para exportação';

  @override
  String get exportCpuThreadsDesc =>
      'Threads do processador a usar para renderização (Ajusta com segurança para cada dispositivo)';

  @override
  String get aboutAppSubtitle =>
      'Estúdio de legendagem e transcrição com IA, 100% offline e com privacidade em primeiro lugar';

  @override
  String get openSourceLicenses => 'Licenças de código aberto';

  @override
  String get openSourceComplianceDesc =>
      'O CapStudio utiliza muitas outras bibliotecas de código aberto. Abaixo está compilado um registro completo de todos os pacotes Dart, dependências transitivas e textos completos de licenças para conformidade legal em lojas.';

  @override
  String get visitWebsite => 'Visitar site';

  @override
  String get btnContinue => 'Continuar';

  @override
  String get btnBack => 'Voltar';

  @override
  String get editTiming => 'Editar sincronização';

  @override
  String get wordSettingsTitle => 'Configurações de palavra';

  @override
  String get emojiSettingsTitle => 'CONFIGURAÇÕES DE EMOJIS';

  @override
  String get changeEmojiTooltip => 'Alterar emoji';

  @override
  String get searchEmojisHint => 'Pesquisar emojis...';

  @override
  String emojiPosX(String offset) {
    return 'Posição do emoji (Deslocamento X: ${offset}px)';
  }

  @override
  String emojiPosY(String offset) {
    return 'Posição do emoji (Deslocamento Y: ${offset}px)';
  }

  @override
  String emojiScale(String scale) {
    return 'Escala do emoji (${scale}x)';
  }

  @override
  String emojiAnimSpeed(String speed) {
    return 'Velocidade de animação (${speed}x)';
  }

  @override
  String get emojiStylePack => 'Estilo / Pacote de emojis';

  @override
  String get selectStylePackTooltip => 'Selecionar pacote de estilo';

  @override
  String get selectEmojiTitle => 'SELECIONAR EMOJI';

  @override
  String get stylePackLabel => 'PACOTE DE ESTILO';

  @override
  String get searchHint => 'Pesquisar...';

  @override
  String get btnCreateProject => 'CRIAR PROJETO';

  @override
  String get btnChooseFile => 'ESCOLHER ARQUIVO';

  @override
  String get selectSubtitleFile => 'Selecionar arquivo de legenda';

  @override
  String get selectTranscriptionQuality =>
      'SELECIONAR QUALIDADE DE TRANSCRIÇÃO';

  @override
  String get translateToEnglishDesc =>
      'Converte falas em outros idiomas diretamente em legendas em inglês';

  @override
  String get hardwareSettings => 'CONFIGURAÇÕES DE HARDWARE E DESEMPENHO';

  @override
  String get styleTemplatesHeader => 'MODELOS DE ESTILO';

  @override
  String get resetToDefaultStyle => 'Redefinir para estilo padrão';

  @override
  String get resetStylingTitle => 'Redefinir estilo?';

  @override
  String get resetStylingDesc =>
      'Isso redefinirá todos os estilos de legendas para o padrão. Não pode ser desfeito.';

  @override
  String get sizeAndPosition => 'TAMANHO E POSIÇÃO';

  @override
  String get verticalYPos => 'Posição vertical Y (%)';

  @override
  String get fontConfigHeader => 'CONFIGURAÇÃO DE FONTE';

  @override
  String get fontFamilyLabel => 'Família de fontes';

  @override
  String get btnImportCustomFont =>
      'IMPORTAR FONTE PERSONALIZADA (.ttf / .otf)';

  @override
  String get fontWeightLabel => 'Espessura da fonte';

  @override
  String get textCaseLabel => 'Maiúsculas e minúsculas';

  @override
  String get fontSizeLabel => 'Tamanho da fonte';

  @override
  String get letterSpacingLabel => 'Espaçamento entre letras';

  @override
  String get lineHeightLabel => 'Altura da linha';

  @override
  String get onboardingAppTagline =>
      'Editor de legendas com IA local 100% offline';

  @override
  String get configLabelWhisperCli => 'Whisper CLI';

  @override
  String get configValueDemoMode => 'Modo de demonstração (Simulado)';

  @override
  String get configLabelFfmpegCli => 'FFmpeg CLI';

  @override
  String get configValueSystemPathDefault => 'Padrão do PATH do sistema';

  @override
  String get configLabelAssetsLocation => 'Local dos recursos';

  @override
  String get filePickerAssetsDialogTitle =>
      'Selecionar pasta de recursos do CapStudio';

  @override
  String errorSelectFolderFailed(String error) {
    return 'Falha ao selecionar pasta: $error';
  }

  @override
  String errorResetFailed(String error) {
    return 'Falha ao redefinir: $error';
  }

  @override
  String errorVerificationFailed(String error) {
    return 'Falha na verificação: $error';
  }

  @override
  String errorAssetsFolderStillMissing(String path) {
    return 'Pasta de recursos ainda não encontrada em: $path';
  }

  @override
  String get dbRecoveredTitle => 'Banco de dados recuperado automaticamente';

  @override
  String dbRecoveredBody(String backupPath) {
    return 'Foi detectada uma incompatibilidade de esquema ou corrupção no banco de dados. O banco de dados foi redefinido e seus dados anteriores foram copiados para:\n\n$backupPath';
  }

  @override
  String errorDemoLoadFailed(String error) {
    return 'Falha ao carregar o vídeo de demonstração: $error';
  }

  @override
  String importProgressPercent(int percent) {
    return '$percent% concluído';
  }

  @override
  String get errorInvalidDropFileFormat =>
      'Formato de arquivo inválido. Solte um arquivo de vídeo.';

  @override
  String get findTextLabel => 'Localizar texto';

  @override
  String get replaceWithLabel => 'Substituir por';

  @override
  String findReplaceSuccessCount(int count) {
    return '$count ocorrências substituídas!';
  }

  @override
  String get btnReplaceAll => 'SUBSTITUIR TUDO';

  @override
  String errorVideoFileNotFound(String path) {
    return 'Arquivo de vídeo não encontrado:\n$path\nPor favor, vincule novamente o arquivo de vídeo.';
  }

  @override
  String get errorTranscriptionFailed =>
      'Falha na transcrição. Tente novamente.';

  @override
  String transcriptionActiveModel(String quality, String model) {
    return 'Ativo: $quality ($model)';
  }

  @override
  String get badgeRecommended => 'REC';

  @override
  String get languageLabel => 'Idioma';

  @override
  String warningEnglishOnlyModel(String model, String language) {
    return 'Aviso: O modelo selecionado ($model) é apenas em inglês. Transcrever em \"$language\" falhará ou gerará legendas em inglês. Selecione um modelo multilíngue (ex.: Tiny ou Base).';
  }

  @override
  String get tipAutoDetectMixedLanguage =>
      'Dica: A detecção automática não é recomendada para idiomas mistos (como Hinglish). Selecionar explicitamente o idioma falado (ex.: português ou inglês) fornecerá legendas muito mais precisas.';

  @override
  String get detectedHardwareLabel => 'Hardware do sistema detectado:';

  @override
  String hardwareRamSize(String ramGB) {
    return 'Tamanho da memória RAM: $ramGB GB';
  }

  @override
  String hardwareCpuCores(int cores) {
    return 'Núcleos lógicos da CPU: $cores';
  }

  @override
  String hardwareGpuDevice(String gpu) {
    return 'Dispositivo GPU: $gpu';
  }

  @override
  String get hardwareDetecting => 'Detectando estatísticas de hardware...';

  @override
  String get btnStartReTranscribe => 'INICIAR RETRANSCRIÇÃO';

  @override
  String get btnImportSrtVtt => 'IMPORTAR ARQUIVO SRT/VTT';

  @override
  String importedSubtitleWords(int count) {
    return '$count palavras importadas do arquivo de legenda.';
  }

  @override
  String get errorImportSubtitleFailed =>
      'Falha ao importar o arquivo de legendas. Verifique o formato do arquivo.';

  @override
  String get noProjectLoaded => 'Nenhum projeto carregado';

  @override
  String get badge916Vertical => '9:16 VERTICAL';

  @override
  String get badge169Landscape => '16:9 HORIZONTAL';

  @override
  String get reframeTargetCanvas =>
      'Tela de destino: 1080 × 1920 (TikTok, YouTube Shorts, Instagram Reels)';

  @override
  String get reframeModeLabel => 'Modo de reenquadramento:';

  @override
  String get reframeModeBlurPillarbox => 'Pillarbox com desfoque (Recomendado)';

  @override
  String get reframeModeBlurPillarboxDesc =>
      'Redimensiona e desfoca o vídeo no fundo para preencher 9:16, mantendo o vídeo centralizado nítido.';

  @override
  String get reframeModeCenterCrop => 'Corte inteligente centralizado';

  @override
  String get reframeModeCenterCropDesc =>
      'Preenche toda a tela 9:16 cortando as bordas esquerda e direita.';

  @override
  String get reframeModeSplitScreen => 'Tela dividida / Camada dupla';

  @override
  String get reframeModeSplitScreenDesc =>
      'Empilha duas janelas de vídeo verticalmente (ideal para reações e diálogos de podcast).';

  @override
  String get btnResetTo169 => 'ATUALMENTE 9:16 (REDEFINIR PARA 16:9)';

  @override
  String get btnSetCanvas916 => 'DEFINIR TELA DO PROJETO EM 9:16';

  @override
  String get silenceRemovalDesc =>
      'Corta automaticamente pausas vazias e intervalos de respiração para maximizar a retenção do vídeo.';

  @override
  String get silenceAggressivenessLabel => 'Agressividade do corte:';

  @override
  String silenceNoiseGateLabel(int db) {
    return 'Gate de ruído para silêncio: $db dB';
  }

  @override
  String silenceMinPauseLabel(String duration) {
    return 'Pausa mínima: ${duration}s';
  }

  @override
  String get btnScanning => 'ESCANEANDO...';

  @override
  String silenceNoneFound(String duration) {
    return 'Nenhum intervalo de silêncio encontrado com mais de ${duration}s.';
  }

  @override
  String silenceFoundCount(int count, String totalSecs) {
    return '$count silêncios encontrados (${totalSecs}s de ar morto economizados)!';
  }

  @override
  String errorScanningAudio(String error) {
    return 'Erro ao escanear o áudio: $error';
  }

  @override
  String jumpCutsApplied(int count) {
    return '$count jump-cuts aplicados à linha do tempo do projeto!';
  }

  @override
  String get viralHooksDesc =>
      'Analisa palavras da transcrição em busca de mais de 80 ganchos virais, ritmo (120–170 PPM), perguntas, densidade de energia e limites de clipes.';

  @override
  String get btnAnalyzingTranscript => 'ANALISANDO TRANSCRIÇÃO...';

  @override
  String get selectAllLabel => 'Selecionar tudo';

  @override
  String selectedCountOf(int selected, int total) {
    return '$selected de $total selecionados';
  }

  @override
  String get btnSelectClipsToBatchExport =>
      'SELECIONAR CLIPES PARA EXPORTAR EM LOTE';

  @override
  String btnBatchExportCount(int count) {
    return 'EXPORTAR $count CLIPE(S) EM LOTE';
  }

  @override
  String get viralNoClipsDetected =>
      'Nenhum clipe viral de alta pontuação detectado nesta faixa de duração do vídeo.';

  @override
  String get badgeCleanCut => 'CORTE LIMPO';

  @override
  String get badgeFirst5s => 'PRIMEIROS 5s';

  @override
  String get btnPreview => 'Pré-visualizar';

  @override
  String get btnTrim => 'Cortar';

  @override
  String get tooltipForkAs916 => 'Bifurcar como novo projeto de Short 9:16';

  @override
  String wpmLabelOk(int wpm) {
    return '$wpm PPM ✓';
  }

  @override
  String wpmLabelFast(int wpm) {
    return '$wpm PPM RÁPIDO';
  }

  @override
  String wpmLabelSlow(int wpm) {
    return '$wpm PPM LENTO';
  }

  @override
  String hookScoreLabel(int score) {
    return 'Gancho $score/40';
  }

  @override
  String energyScoreLabel(int score) {
    return 'Energia $score/20';
  }

  @override
  String get filePickerClipsFolderTitle =>
      'Escolha a pasta para salvar os clipes';

  @override
  String get errorChooseOutputFolderFirst =>
      'Por favor, escolha uma pasta de saída primeiro.';

  @override
  String batchExportSheetTitle(int count) {
    return 'EXPORTAR $count CLIPE(S) EM LOTE';
  }

  @override
  String get tapToChooseOutputFolder => 'Toque para escolher a pasta de saída…';

  @override
  String get burnCaptionsOnClipsLabel =>
      'Incorporar legendas dinâmicas nos clipes';

  @override
  String get burnCaptionsOnClipsDesc =>
      'Grava legendas animadas estilizadas sincronizadas com o áudio do clipe';

  @override
  String exportCancelledProgress(int done, int total) {
    return 'Exportação cancelada. $done/$total concluídos.';
  }

  @override
  String exportProgressSummary(int done, int total, int failed) {
    return '$done/$total exportados · $failed com falha';
  }

  @override
  String get btnExporting => 'EXPORTANDO…';

  @override
  String get btnExportComplete => 'EXPORTAÇÃO CONCLUÍDA ✓';

  @override
  String get btnStartExport => 'INICIAR EXPORTAÇÃO';

  @override
  String exportClipSavedAt(String path) {
    return '✓ Salvo: $path';
  }

  @override
  String projectTrimmedToClip(int rank, String start, String end) {
    return 'Projeto cortado para o clipe viral #$rank ($start - $end)!';
  }

  @override
  String shortProjectCreated(String name) {
    return 'Short 9:16 criado: \"$name\"';
  }

  @override
  String get btnOpen => 'ABRIR';

  @override
  String errorCreateShortProjectFailed(String error) {
    return 'Falha ao criar projeto de short: $error';
  }

  @override
  String get autoDetect => 'Detecção automática';

  @override
  String presetSaved(String name) {
    return 'Predefinição de estilo \"$name\" salva com sucesso!';
  }

  @override
  String get presetDeleted => 'Predefinição excluída com sucesso.';

  @override
  String get presetExported =>
      'Predefinições de estilo exportadas com sucesso!';

  @override
  String errorPresetExportFailed(String error) {
    return 'Falha ao exportar predefinições: $error';
  }

  @override
  String get presetImported =>
      'Predefinições de estilo importadas com sucesso!';

  @override
  String errorPresetImportFailed(String error) {
    return 'Falha ao importar predefinições: $error';
  }

  @override
  String get selectFontFileDialogTitle =>
      'Selecionar arquivo de fonte TTF ou OTF';

  @override
  String get fontWeightThin => 'Fino';

  @override
  String get fontWeightExtraLight => 'Extraleve';

  @override
  String get fontWeightLight => 'Leve';

  @override
  String get fontWeightNormal => 'Normal';

  @override
  String get fontWeightMedium => 'Médio';

  @override
  String get fontWeightSemiBold => 'Seminegrito';

  @override
  String get fontWeightBold => 'Negrito';

  @override
  String get fontWeightExtraBold => 'Extranegrito';

  @override
  String get fontWeightBlack => 'Preto';

  @override
  String get fontCaseNormal => 'Normal';

  @override
  String get fontCaseUppercase => 'MAIÚSCULAS';

  @override
  String get fontCaseCapitalize => 'Iniciais maiúsculas';

  @override
  String get strokeStyleThickOutline => 'Contorno espesso';

  @override
  String get strokeStyleNoneFlat => 'Nenhum (Plano)';

  @override
  String get shadowStyleSoft => 'Sombra suave';

  @override
  String get shadowStyleNone => 'Nenhuma';

  @override
  String get animStyleActivePop => 'Pop ativo';

  @override
  String get animStyleActiveBounce => 'Pulo com salto ativo';

  @override
  String get animStyleKineticTilt => 'Inclinação cinética';

  @override
  String get animStyleGlowPulse => 'Pulso de brilho ativo';

  @override
  String get animStyleWordReveal => 'Aparecimento gradual de palavras';

  @override
  String get animStyleNoneStatic => 'Nenhum (Estático)';

  @override
  String fontImportedSuccess(String name) {
    return 'Fonte personalizada \"$name\" importada e aplicada com sucesso!';
  }

  @override
  String get errorFontImportFailed =>
      'Falha ao carregar o arquivo de fonte. Dados inválidos.';

  @override
  String get invalidTimingError =>
      'Tempos de início/fim inválidos. O início deve ser >= 0, e o fim deve ser >= início e <= à duração do vídeo.';

  @override
  String get projectSavedSuccess => 'Projeto salvo com sucesso.';

  @override
  String wordDeletedSuccess(String text) {
    return 'Palavra excluída: \"$text\"';
  }

  @override
  String get splitClip => 'Dividir clipe';

  @override
  String get removeClip => 'Remover clipe';

  @override
  String get resetToOriginal => 'Redefinir para o original';

  @override
  String splitTimelineAt(String time) {
    return 'Linha do tempo dividida em ${time}s.';
  }

  @override
  String get splitTimelineError =>
      'O indicador de reprodução deve estar dentro da região ativa para dividir.';

  @override
  String get exclusionToggled =>
      'Exclusão do segmento sob o indicador de reprodução alternada.';

  @override
  String get splitsReset =>
      'Todas as divisões e exclusões da linha do tempo foram redefinidas.';

  @override
  String get shareVideo => 'Compartilhar vídeo';

  @override
  String get openOutputFolder => 'Abrir pasta de saída';

  @override
  String get errorLogCopied =>
      'Log de erros copiado para a área de transferência.';

  @override
  String get diagnosticsExported =>
      'Relatório de diagnóstico filtrado aberto na folha de compartilhamento.';

  @override
  String errorDiagnosticsFailed(String error) {
    return 'Falha ao exportar relatório de diagnóstico: $error';
  }

  @override
  String logLineCopied(String message) {
    return 'Linha do log copiada para a área de transferência: \"$message\"';
  }

  @override
  String commandCopied(String command) {
    return 'Copiado: \"$command\"';
  }

  @override
  String get settingsRestored => 'Configurações restauradas para os padrões.';

  @override
  String get gpuEncoderNoneCpu => 'Nenhum (CPU)';

  @override
  String get gpuEncoderNvidia => 'NVIDIA NVENC';

  @override
  String get gpuEncoderAmd => 'AMD AMF';

  @override
  String get gpuEncoderIntel => 'Intel QSV';

  @override
  String get gpuEncoderApple => 'Apple VideoToolbox';

  @override
  String get btnDownloadVcRedist => 'BAIXAR VC++ REDISTRIBUTABLE';

  @override
  String errorDownloadToolFailed(String error) {
    return 'Falha ao baixar ferramenta: $error';
  }

  @override
  String get errorFolderNotAccessible =>
      'A pasta selecionada não existe ou não está acessível.';

  @override
  String modelDeleted(String name) {
    return 'Modelo excluído: $name';
  }

  @override
  String errorModelDeleteFailed(String error) {
    return 'Falha ao excluir modelo: $error';
  }

  @override
  String errorModelDownloadFailed(String name, String error) {
    return 'Falha ao baixar o modelo $name: $error';
  }

  @override
  String errorOpenFolderFailed(String path) {
    return 'Não foi possível abrir a pasta automaticamente. Caminho: $path';
  }

  @override
  String errorDownloadPackFailed(String error) {
    return 'Falha ao baixar pacote: $error';
  }

  @override
  String errorPackDownloadNamedFailed(String name, String error) {
    return 'Falha ao baixar pacote $name: $error';
  }

  @override
  String get stickersIndexRefreshed =>
      'Índice de figurinhas personalizadas atualizado com sucesso!';

  @override
  String errorChangeAssetFolderFailed(String error) {
    return 'Falha ao alterar a pasta de recursos: $error';
  }

  @override
  String errorSetAssetFolderFailed(String error) {
    return 'Falha ao definir a pasta de recursos: $error';
  }

  @override
  String get warningNoAvx =>
      'Falta de suporte a AVX detectada! Baixando whisper-cli compatível (sem AVX)...';

  @override
  String get errorAutoDetectWhisper =>
      'Não foi possível detectar o whisper-cli automaticamente. Navegue manualmente.';

  @override
  String get errorAutoDetectFfmpeg =>
      'Não foi possível detectar o ffmpeg automaticamente. Navegue manualmente.';

  @override
  String errorToolDownloadFailed(String error) {
    return 'Falha ao baixar ferramenta: $error';
  }

  @override
  String get returnToDashboard => 'Voltar ao painel';

  @override
  String errorImportVideoFailed(String error) {
    return 'Falha na importação: $error';
  }

  @override
  String get videoRelinkedSuccess => 'Vídeo revinculado com sucesso!';

  @override
  String get errorRelinkVideoFailed => 'Falha ao revincular vídeo.';

  @override
  String get retranscriptionSuccess => 'Retranscrição concluída com sucesso!';

  @override
  String get retranscriptionFailed => 'Falha na retranscrição.';
}
