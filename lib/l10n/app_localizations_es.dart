// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'CapStudio';

  @override
  String get dashboardTitle => 'Mis Proyectos';

  @override
  String get dashboardSubtitle =>
      'Estudio de subtítulos y subtítulos de IA sin conexión';

  @override
  String get importVideo => 'Importar Video';

  @override
  String get dragDropText => 'Arrastra y suelta tu archivo de video aquí';

  @override
  String get clickBrowse => 'o haz clic para explorar archivos locales';

  @override
  String get demoMode => 'MODO DEMO';

  @override
  String get demoModeDesc =>
      'Carga un proyecto de demostración para probar los estilos y las funciones del editor.';

  @override
  String get warningAssets => 'Se requiere recuperar la carpeta de activos';

  @override
  String get warningAssetsDesc =>
      'No se encontraron los activos integrados en la carpeta de soporte de la aplicación. Haz doble clic aquí para restaurar o cambiar el directorio de activos.';

  @override
  String get deleteProjectTitle => 'Eliminar Proyecto';

  @override
  String deleteProjectConfirm(String projectName) {
    return '¿Estás seguro de que deseas eliminar permanentemente \"$projectName\"? Esta acción no se puede deshacer.';
  }

  @override
  String get renameProjectTitle => 'Renombrar Proyecto';

  @override
  String get projectNameLabel => 'Nombre del Proyecto';

  @override
  String get btnCancel => 'CANCELAR';

  @override
  String get btnDelete => 'ELIMINAR';

  @override
  String get btnRename => 'RENOMBRAR';

  @override
  String get btnSave => 'GUARDAR';

  @override
  String get btnConfirm => 'CONFIRMAR';

  @override
  String get btnExport => 'EXPORTAR';

  @override
  String get btnUndo => 'Deshacer';

  @override
  String get btnRedo => 'Rehacer';

  @override
  String get statusDraft => 'Borrador';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get createdLabel => 'Creado:';

  @override
  String get durationLabel => 'Duración:';

  @override
  String get statusLabel => 'Estado:';

  @override
  String get settingsTitle => 'Configuración';

  @override
  String get settingsGeneral => 'Configuración General';

  @override
  String get settingsTheme => 'Tema de la aplicación';

  @override
  String get themeSystem => 'Predeterminado del Sistema';

  @override
  String get themeLight => 'Modo Claro';

  @override
  String get themeDark => 'Modo Oscuro';

  @override
  String get settingsLanguage => 'Idioma de la interfaz';

  @override
  String get settingsTranscription => 'Configuración de Transcripción';

  @override
  String get settingsWhisperModel => 'Modelo de Whisper';

  @override
  String get settingsWhisperModelDesc =>
      'Selecciona un modelo para la transcripción. Más pequeño es más rápido; más grande es más preciso.';

  @override
  String get settingsTranscribeLang => 'Idioma de Transcripción';

  @override
  String get settingsAutoDetect => 'Detectar idioma automáticamente';

  @override
  String get settingsGPU => 'Aceleración por GPU (CUDA)';

  @override
  String get settingsVAD => 'Umbral de VAD (Actividad de voz)';

  @override
  String get settingsExport => 'Configuración de Exportación';

  @override
  String get settingsExportDest => 'Directorio de exportación predeterminado';

  @override
  String get settingsBrowse => 'Buscar';

  @override
  String get settingsEmojiPacks => 'Paquetes de Emojis y Estilos';

  @override
  String get settingsEmojiPacksDesc =>
      'Personaliza los estilos de renderizado de emojis y los activos de subtítulos activos.';

  @override
  String get settingsEmojiSearchLang => 'Idioma de búsqueda de emojis';

  @override
  String get settingsBtnManagePacks => 'GESTIONAR PAQUETES DE EMOJIS';

  @override
  String get systemTitle => 'Información del Sistema';

  @override
  String get systemVersion => 'Versión';

  @override
  String get systemReset => 'Restablecer Valores Predeterminados';

  @override
  String get editorTabCaptions => 'Subtítulos';

  @override
  String get editorTabStyles => 'Estilos';

  @override
  String get editorTabTrim => 'Recortar';

  @override
  String get editorTabAudio => 'Audio';

  @override
  String get editorTabTranscription => 'Transcripción';

  @override
  String get editorTabShortcuts => 'Atajos';

  @override
  String get editorTabDebug => 'Depurar';

  @override
  String get editorHeaderBack => 'Volver';

  @override
  String get editorKeyboardShortcuts => 'Atajos de Teclado';

  @override
  String get dialogAnalyzing => 'Analizando video...';

  @override
  String get dialogTranscribing => 'Transcribiendo audio...';

  @override
  String get dialogExtracting => 'Extrayendo audio...';

  @override
  String get dialogWait => 'Esto puede tardar un momento. Por favor espera.';

  @override
  String get dialogError => 'Error';

  @override
  String get dialogImportFailed => 'Error al importar el video.';

  @override
  String get noProjects => 'No hay proyectos creados';

  @override
  String get aboutApp => 'Acerca de CapStudio';

  @override
  String get aboutAppDesc =>
      'Detalles sobre CapStudio, créditos y licencias de código abierto.';

  @override
  String get aboutAppThanks =>
      'Agradecimiento especial a los proyectos de código aberto que hacen posible CapStudio:';

  @override
  String get btnViewAllLicenses => 'VER LICENCIAS DE TODOS LOS PAQUETES';

  @override
  String get exportBurnIn => 'EXPORTACIÓN DE VIDEO CON TEXTO INCORPORADO';

  @override
  String get exportTimecodeFormats =>
      'FORMATOS DE SUBTÍTULOS CON CÓDIGO DE TIEMPO';

  @override
  String get exportWebEnabled =>
      'La exportación de video del lado del cliente está habilitada. El renderizado se ejecuta localmente en su navegador.';

  @override
  String get exportWebCaptionOnly =>
      'La exportación web actualmente incluye solo subtítulos: los emojis y los efectos de sonido aún no se incorporan al video. Exporte desde la aplicación de escritorio o móvil para obtener el resultado completo.';

  @override
  String get exportOutputName => 'Nombre del video de salida';

  @override
  String get exportMode => 'Modo de exportación';

  @override
  String get exportModeFast => 'Rápido (FFmpeg nativo)';

  @override
  String get exportModeFastUnsupported =>
      'Rápido (FFmpeg nativo) ⚠️ No compatible';

  @override
  String get exportModeSlow => 'Lento (Renderizado 1:1 de vista previa)';

  @override
  String get exportTargetFps => 'FPS objetivo';

  @override
  String get exportFps24 => '24 FPS (Cine)';

  @override
  String get exportFps25 => '25 FPS (PAL)';

  @override
  String get exportFps30 => '30 FPS (Estándar)';

  @override
  String get exportFps50 => '50 FPS';

  @override
  String get exportFps60 => '60 FPS (Fluido)';

  @override
  String get exportFastUnsupported =>
      'El modo rápido no es compatible con este dispositivo porque la compilación del sistema de FFmpeg carece de filtros de renderizado de subtítulos (libass). Se usará el modo lento.';

  @override
  String get exportSlowInfo =>
      'Captura cada fotograma exactamente como se muestra en la vista previa. Esto garantiza subtítulos perfectos píxel a píxel, pero el renderizado es más lento.';

  @override
  String get exportDestDirectory => 'DIRECTORIO DE DESTINO';

  @override
  String get exportDestBrowser => 'Ubicación de descarga del navegador';

  @override
  String get exportDestAndroid =>
      'Carpeta de descargas (/storage/emulated/0/Download)';

  @override
  String get exportDestIos =>
      'Documentos de la aplicación (hoja para compartir tras la exportación)';

  @override
  String get exportChooseFolder => 'Elegir carpeta de salida';

  @override
  String get exportStartMp4 => 'INICIAR EXPORTACIÓN MP4';

  @override
  String get exportSrtTitle => 'Subtítulos SubRip (.srt)';

  @override
  String get exportSrtDesc =>
      'Estándar universal con código de tiempo. Compatible con YouTube, VLC y Premiere Pro.';

  @override
  String get exportVttTitle => 'Subtítulos WebVTT (.vtt)';

  @override
  String get exportVttDesc =>
      'Formato de subtítulos optimizado para web, muy usado en reproductores HTML5 y transmisión en línea.';

  @override
  String get exportAssTitle => 'Advanced SubStation Alpha (.ass)';

  @override
  String get exportAssDesc =>
      'Formato profesional que incorpora tamaños de fuente, estilos, márgenes y resaltados en línea.';

  @override
  String get exportTxtTitle => 'Transcripción de texto plano (.txt)';

  @override
  String get exportTxtDesc =>
      'Transcripción línea por línea con marcadores de prefijo de marca de tiempo.';

  @override
  String exportSuccess(String type) {
    return '¡$type exportado correctamente!';
  }

  @override
  String get exportNoLocation =>
      'No se seleccionó una ubicación de guardado. Elija una ruta de archivo.';

  @override
  String get exportNoLocationCancelled =>
      'No se seleccionó una ubicación de guardado. Exportación cancelada.';

  @override
  String exportFailed(String error) {
    return 'No se pudo exportar: $error';
  }

  @override
  String get exportCopySrtTooltip => 'Copiar SRT al portapapeles';

  @override
  String get exportCopiedSrt => '¡SRT copiado al portapapeles!';

  @override
  String exportCopyFailedSrt(String error) {
    return 'No se pudo copiar el SRT: $error';
  }

  @override
  String exportSubtitlesDialogTitle(String type) {
    return 'Exportar subtítulos $type';
  }

  @override
  String get exportVideoDialogTitle => 'Exportar video MP4';

  @override
  String get ffmpegRequiredTitle => 'Se requiere FFmpeg';

  @override
  String get ffmpegRequiredBody =>
      'Se requiere una instalación local de FFmpeg para incorporar subtítulos en un archivo de video.\n\nConfigure la ruta de FFmpeg en Ajustes.';

  @override
  String get okLabel => 'ACEPTAR';

  @override
  String get exportWebTitle => 'Exportando video (del lado del cliente)';

  @override
  String exportWebSuccess(String fileName) {
    return '¡Video exportado correctamente como $fileName!';
  }

  @override
  String exportWebFailed(String error) {
    return 'Error de renderizado: $error';
  }

  @override
  String get viralShortsTitle => 'ESTUDIO DE SHORTS VIRALES';

  @override
  String get viralShortsSubtitle =>
      'Reencuadre vertical 9:16, cortes de salto en silencios y detector de ganchos con IA';

  @override
  String get viralReframeTitle => '1. REENCUADRE VERTICAL 9:16';

  @override
  String get viralSilenceTitle => '2. ELIMINACIÓN DE SILENCIOS (JUMP-CUTS)';

  @override
  String get viralHooksTitle => '3. DETECTOR DE GANCHOS VIRALES CON IA';

  @override
  String get btnFindViralMoments => 'BUSCAR MOMENTOS VIRALES';

  @override
  String get btnScanSilences => 'BUSCAR SILENCIOS';

  @override
  String get btnApplyJumpCuts => 'APLICAR JUMP-CUTS';

  @override
  String get editorTabShorts => 'Shorts';

  @override
  String get editorTabClips => 'Clips';

  @override
  String get captionList => 'LISTA DE SUBTÍTULOS';

  @override
  String get uncertainLabel => 'Incierto (<40%)';

  @override
  String get mediumConfidenceLabel => 'Medio (40-60%)';

  @override
  String get jumpToUncertain => 'Saltar a la siguiente palabra incierta';

  @override
  String get noUncertainWords => 'No se encontraron palabras inciertas.';

  @override
  String get findAndReplace => 'Buscar y reemplazar';

  @override
  String get addWordTitle => 'Agregar palabra';

  @override
  String get editWordTitle => 'Editar palabra';

  @override
  String get wordTextLabel => 'Texto de la palabra';

  @override
  String get startTimeLabel => 'Tiempo inicial (s)';

  @override
  String get endTimeLabel => 'Tiempo final (s)';

  @override
  String get splitChunk => 'Dividir fragmento';

  @override
  String get insertLineAfter => 'Insertar línea después';

  @override
  String get duplicateLine => 'Duplicar línea';

  @override
  String get deleteLine => 'Eliminar línea';

  @override
  String get chooseSfxTitle => 'Elegir efecto de sonido';

  @override
  String get searchSfxPlaceholder => 'Buscar SFX...';

  @override
  String get noSfxFound => 'No se encontraron efectos de sonido';

  @override
  String get emojiSearch => 'Búsqueda de emojis';

  @override
  String get noEmojisFound => 'No se encontraron emojis.';

  @override
  String get mySavedPresets => 'MIS AJUSTES PREESTABLECIDOS';

  @override
  String get btnImport => 'IMPORTAR';

  @override
  String get btnExportCaps => 'EXPORTAR';

  @override
  String get btnSaveCurrent => 'GUARDAR ACTUAL';

  @override
  String get resetToDefault => 'Restablecer a valores predeterminados';

  @override
  String get resetConfirmBody =>
      'Esto restablecerá todos los estilos de subtítulos a los valores predeterminados. No se puede deshacer.';

  @override
  String get btnReset => 'Restablecer';

  @override
  String get wordHighlightBox => 'Caja de resaltado de palabra';

  @override
  String get wordHighlightBoxDesc =>
      'Fondo de píldora coloreada detrás de las palabras habladas activas';

  @override
  String get maxWordsPerChunk =>
      'Máximo de palabras por fragmento de subtítulo';

  @override
  String get maxCharsPerLine => 'Máximo de caracteres por línea de subtítulo';

  @override
  String get fontSettings => 'Configuración de fuente';

  @override
  String get colorSettings => 'Configuración de color';

  @override
  String get borderSettings => 'Configuración de borde y sombra';

  @override
  String get speechToTextTitle => 'TRANSCRIPCIÓN DE VOZ A TEXTO';

  @override
  String get speechToTextDesc =>
      'Vuelve a ejecutar la transcripción local de voz a texto. Se reemplazarán todas las ediciones manuales o desfases de tiempo.';

  @override
  String get useLocalAi => 'Usar transcripción con IA local';

  @override
  String get runOnDeviceDesc =>
      'Ejecutar voz a texto directamente en este dispositivo';

  @override
  String get offlineDemoModeActive =>
      'El modo de demostración sin conexión está activo. La transcripción local de Whisper AI no es compatible en la web.';

  @override
  String get demoModeNote =>
      'El modo de demostración genera instantáneamente tokens de transcripción altamente realistas. Perfecto para probar estilos, plantillas y operaciones de la línea de tiempo sin configuración previa.';

  @override
  String get transcriptionQuality => 'Calidad de transcripción';

  @override
  String get advancedSettings => 'Configuración avanzada';

  @override
  String get cpuThreadsLabel => 'Hilos de CPU';

  @override
  String get vadSensitivity => 'Sensibilidad de VAD';

  @override
  String get translateToEnglish => 'Traducir subtítulos al inglés';

  @override
  String get startTranscriptionBtn => 'INICIAR TRANSCRIPCIÓN';

  @override
  String get hardwareLocked => 'Bloqueado por hardware';

  @override
  String get btnDownload => 'Descargar';

  @override
  String get welcomeTitle => 'Bienvenido a CapStudio';

  @override
  String get welcomeSubtitle =>
      'Subtítulos de alta precisión y shorts virales, 100% sin conexión.';

  @override
  String get setupAssetDirTitle => 'Elegir directorio de activos';

  @override
  String get setupAssetDirDesc =>
      'Selecciona un directorio para almacenar modelos, fuentes y paquetes de emojis.';

  @override
  String get downloadPacksTitle => 'Descargar paquetes de contenido (Opcional)';

  @override
  String get downloadPacksDesc =>
      'Fuentes y efectos de sonido opcionales para tus proyectos de video.';

  @override
  String get setupCompleteTitle => 'Configuración completada';

  @override
  String get setupCompleteDesc =>
      'Ya estás listo para crear increíbles videos con subtítulos.';

  @override
  String get btnGetStarted => 'Comenzar';

  @override
  String get btnNext => 'SIGUIENTE';

  @override
  String get btnSkip => 'OMITIR';

  @override
  String get onboardingFeaturePrivacy => '100% de Privacidad';

  @override
  String get onboardingFeaturePrivacyDesc =>
      'Tus archivos nunca salen de tu dispositivo. Todos los modelos de IA se ejecutan localmente.';

  @override
  String get onboardingFeatureGpu => 'Reproducción acelerada por GPU';

  @override
  String get onboardingFeatureGpuDesc =>
      'Edición de video de alto rendimiento mediante decodificación por hardware.';

  @override
  String get onboardingFeatureAssets => 'Activos sidecar sin conexión';

  @override
  String get onboardingFeatureAssetsDesc =>
      'Descarga paquetes completos de emojis una sola vez y ejecútalos totalmente sin conexión.';

  @override
  String get onboardingReadyTitle => '¡Todo listo para empezar!';

  @override
  String get onboardingConfigDetails => 'Detalles de configuración:';

  @override
  String get btnLaunchCapStudio => 'Iniciar CapStudio';

  @override
  String get assetVerificationFailed =>
      'Error en la verificación de activos. Asegúrate de que los activos se hayan descargado correctamente.';

  @override
  String get assetsFolderNotFound => 'Carpeta de activos no encontrada';

  @override
  String get assetsFolderNotFoundDesc =>
      'CapStudio no pudo encontrar la carpeta de activos en la ubicación configurada. Si la carpeta está en una unidad externa, conéctala.';

  @override
  String get expectedPathLabel => 'RUTA ESPERADA:';

  @override
  String get browseNewLocation => 'Explorar nueva ubicación';

  @override
  String get resetToDefaultPath => 'Restablecer a la ruta predeterminada';

  @override
  String get retryVerification => 'Reintentar verificación';

  @override
  String get storagePathFolder => 'Carpeta de ruta de almacenamiento';

  @override
  String get tipWindowsDrive =>
      'Consejo: Si la unidad C: tiene poco espacio, elige una ruta en D: o E: para más capacidad.';

  @override
  String get tipGeneralDrive =>
      'Consejo: Puedes seleccionar una ruta en una unidad externa si tu volumen raíz está lleno.';

  @override
  String get confirmLocation => 'Confirmar ubicación';

  @override
  String get requiredBadge => 'REQUERIDO';

  @override
  String get emojiPacksHeader => 'PAQUETES DE EMOJIS';

  @override
  String get fontPacksHeader => 'PAQUETES DE FUENTES';

  @override
  String get connectCliTitle => 'Conectar herramientas CLI locales';

  @override
  String get connectCliDesc =>
      'CapStudio necesita los binarios de whisper.cpp y FFmpeg para realizar transcripciones y exportar videos localmente.';

  @override
  String get skipSetup => 'Omitir configuración por ahora';

  @override
  String get btnValidate => 'Validar';

  @override
  String get autoDetectAndValidate => 'Autodetectar y validar';

  @override
  String get whisperCliPathLabel => 'Ruta del ejecutable de Whisper CLI';

  @override
  String get ffmpegCliPathLabel => 'Ruta del ejecutable de FFmpeg CLI';

  @override
  String get newProject => 'Nuevo proyecto';

  @override
  String get searchProjects => 'Buscar proyectos...';

  @override
  String get filterAll => 'Todos';

  @override
  String get sortByRecent => 'Más recientes';

  @override
  String get sortByDuration => 'Duración';

  @override
  String get noMatchingProjects => 'Ningún proyecto coincide con tu búsqueda';

  @override
  String get btnEdit => 'EDITAR';

  @override
  String get btnDuplicate => 'DUPLICAR';

  @override
  String get tooltipEdit => 'Editar';

  @override
  String get tooltipRename => 'Renombrar';

  @override
  String get tooltipDuplicate => 'Duplicar';

  @override
  String get tooltipDelete => 'Eliminar';

  @override
  String get tooltipTheme => 'Tema';

  @override
  String get tooltipSettings => 'Configuración';

  @override
  String get selectDemoFormat => 'SELECCIONAR FORMATO DE DEMO';

  @override
  String get selectDemoDesc =>
      'Selecciona un formato de diseño para previsualizar al instante el motor de subtítulos de alta fidelidad, animaciones palabra por palabra en vivo y formas de onda de audio de CapStudio.';

  @override
  String get landscapeDemo => 'Demo horizontal';

  @override
  String get landscapeDemoDesc =>
      'Perfecto para YouTube, escritorio y presentaciones.';

  @override
  String get portraitDemo => 'Demo vertical';

  @override
  String get portraitDemoDesc =>
      'Ideal para TikTok, Shorts, Reels y dispositivos móviles.';

  @override
  String get format16x9 => 'Formato 16:9';

  @override
  String get format9x16 => 'Formato 9:16';

  @override
  String get dropVideoHere => 'ARRASTRA EL VIDEO AQUÍ';

  @override
  String get dropVideoSupported => 'Compatible con MP4, MOV, AVI, etc.';

  @override
  String get statusLocalOffline => 'LOCAL SIN CONEXIÓN';

  @override
  String get speechModelTitle => 'Modelo de reconocimiento de voz';

  @override
  String get hardwareUpgradesTitle => 'Mejoras de rendimiento de hardware';

  @override
  String get showAdvancedPaths => 'MOSTRAR CONFIGURACIÓN AVANZADA DE RUTAS';

  @override
  String get hideAdvancedPaths => 'OCULTAR CONFIGURACIÓN AVANZADA DE RUTAS';

  @override
  String get autoDownload => 'DESCARGA AUTOMÁTICA';

  @override
  String get gpuAcceleratedTranscription =>
      'Transcripción acelerada por GPU (CUDA)';

  @override
  String get gpuRequiresNvidia => 'Requiere GPU NVIDIA compatible con CUDA';

  @override
  String get gpuExportEncoder => 'Codificador de exportación por GPU';

  @override
  String get gpuExportEncoderDesc =>
      'Aceleración por hardware para exportación de video MP4';

  @override
  String get defaultLanguage => 'Idioma predeterminado';

  @override
  String get vadTitle => 'Detección de actividad de voz (VAD)';

  @override
  String get vadDesc => 'Omite regiones de silencio durante el procesamiento';

  @override
  String get vadThreshold => 'Umbral de VAD';

  @override
  String get autoSaveTitle => 'Guardado automático';

  @override
  String get autoSaveDesc =>
      'Guarda automáticamente las ediciones del proyecto en la base de datos cada 3 segundos';

  @override
  String get defaultOutputsTitle => 'Salidas predeterminadas';

  @override
  String get defaultExportFolder => 'Carpeta de exportación predeterminada';

  @override
  String get alwaysAskExportPath => 'Preguntar siempre la ruta de exportación';

  @override
  String get alwaysAskExportPathDesc =>
      'Solicita la ruta de salida en cada exportación (Escritorio)';

  @override
  String get performanceTitle => 'Rendimiento';

  @override
  String get exportCpuThreads => 'Hilos de CPU para exportación';

  @override
  String get exportCpuThreadsDesc =>
      'Hilos del procesador a utilizar para el renderizado (Se ajusta automáticamente de forma segura por dispositivo)';

  @override
  String get aboutAppSubtitle =>
      'Estudio de subtítulos y closed captions con IA, 100% sin conexión y con privacidad garantizada';

  @override
  String get openSourceLicenses => 'Licencias de código abierto';

  @override
  String get openSourceComplianceDesc =>
      'CapStudio se basa en muchas otras bibliotecas de código abierto. A continuación se compila un registro completo de todos los paquetes de Dart, dependencias transitivas y textos de licencia completos para el cumplimiento legal en tiendas.';

  @override
  String get visitWebsite => 'Visitar sitio web';

  @override
  String get btnContinue => 'Continuar';

  @override
  String get btnBack => 'Atrás';

  @override
  String get editTiming => 'Editar sincronización';

  @override
  String get wordSettingsTitle => 'Configuración de palabras';

  @override
  String get emojiSettingsTitle => 'CONFIGURACIÓN DE EMOJIS';

  @override
  String get changeEmojiTooltip => 'Cambiar emoji';

  @override
  String get searchEmojisHint => 'Buscar emojis...';

  @override
  String emojiPosX(String offset) {
    return 'Posición del emoji (Desfase X: ${offset}px)';
  }

  @override
  String emojiPosY(String offset) {
    return 'Posición del emoji (Desfase Y: ${offset}px)';
  }

  @override
  String emojiScale(String scale) {
    return 'Escala del emoji (${scale}x)';
  }

  @override
  String emojiAnimSpeed(String speed) {
    return 'Velocidad de animación (${speed}x)';
  }

  @override
  String get emojiStylePack => 'Estilo / Paquete de emojis';

  @override
  String get selectStylePackTooltip => 'Seleccionar paquete de estilos';

  @override
  String get selectEmojiTitle => 'SELECCIONAR EMOJI';

  @override
  String get stylePackLabel => 'PAQUETE DE ESTILOS';

  @override
  String get searchHint => 'Buscar...';

  @override
  String get btnCreateProject => 'CREAR PROYECTO';

  @override
  String get btnChooseFile => 'ELEGIR ARCHIVO';

  @override
  String get selectSubtitleFile => 'Seleccionar archivo de subtítulos';

  @override
  String get selectTranscriptionQuality =>
      'SELECCIONAR CALIDAD DE TRANSCRIPCIÓN';

  @override
  String get translateToEnglishDesc =>
      'Convierte voz en otros idiomas directamente en subtítulos en inglés';

  @override
  String get hardwareSettings => 'CONFIGURACIÓN DE HARDWARE Y RENDIMIENTO';

  @override
  String get styleTemplatesHeader => 'PLANTILLAS DE ESTILO';

  @override
  String get resetToDefaultStyle => 'Restablecer al estilo predeterminado';

  @override
  String get resetStylingTitle => '¿Restablecer estilo?';

  @override
  String get resetStylingDesc =>
      'Esto restablecerá todos los estilos de subtítulos a los valores predeterminados. No se puede deshacer.';

  @override
  String get sizeAndPosition => 'TAMAÑO Y POSICIÓN';

  @override
  String get verticalYPos => 'Posición vertical Y (%)';

  @override
  String get fontConfigHeader => 'CONFIGURACIÓN DE FUENTE';

  @override
  String get fontFamilyLabel => 'Familia de fuente';

  @override
  String get btnImportCustomFont =>
      'IMPORTAR FUENTE PERSONALIZADA (.ttf / .otf)';

  @override
  String get fontWeightLabel => 'Grosor de fuente';

  @override
  String get textCaseLabel => 'Mayúsculas y minúsculas';

  @override
  String get fontSizeLabel => 'Tamaño de fuente';

  @override
  String get letterSpacingLabel => 'Espaciado entre letras';

  @override
  String get lineHeightLabel => 'Altura de línea';

  @override
  String get onboardingAppTagline =>
      'Editor de subtítulos con IA local 100% sin conexión';

  @override
  String get configLabelWhisperCli => 'Whisper CLI';

  @override
  String get configValueDemoMode => 'Modo demo (Simulado)';

  @override
  String get configLabelFfmpegCli => 'FFmpeg CLI';

  @override
  String get configValueSystemPathDefault =>
      'Predeterminado del PATH del sistema';

  @override
  String get configLabelAssetsLocation => 'Ubicación de activos';

  @override
  String get filePickerAssetsDialogTitle =>
      'Seleccionar carpeta de activos de CapStudio';

  @override
  String errorSelectFolderFailed(String error) {
    return 'Error al seleccionar la carpeta: $error';
  }

  @override
  String errorResetFailed(String error) {
    return 'Error al restablecer: $error';
  }

  @override
  String errorVerificationFailed(String error) {
    return 'Falló la verificación: $error';
  }

  @override
  String errorAssetsFolderStillMissing(String path) {
    return 'Aún no se encuentra la carpeta de activos en: $path';
  }

  @override
  String get dbRecoveredTitle => 'Base de datos recuperada automáticamente';

  @override
  String dbRecoveredBody(String backupPath) {
    return 'Se detectó una discrepancia de esquema o corrupción en la base de datos. La base de datos se restableció y sus datos anteriores se respaldaron en:\n\n$backupPath';
  }

  @override
  String errorDemoLoadFailed(String error) {
    return 'Error al cargar el video de demostración: $error';
  }

  @override
  String importProgressPercent(int percent) {
    return '$percent% completado';
  }

  @override
  String get errorInvalidDropFileFormat =>
      'Formato de archivo no válido. Por favor, arrastra un archivo de video.';

  @override
  String get findTextLabel => 'Buscar texto';

  @override
  String get replaceWithLabel => 'Reemplazar con';

  @override
  String findReplaceSuccessCount(int count) {
    return '¡Se reemplazaron $count apariciones!';
  }

  @override
  String get btnReplaceAll => 'REEMPLAZAR TODO';

  @override
  String errorVideoFileNotFound(String path) {
    return 'Archivo de video no encontrado:\n$path\nPor favor, vuelve a vincular el archivo de video.';
  }

  @override
  String get errorTranscriptionFailed =>
      'Falló la transcripción. Inténtalo de nuevo.';

  @override
  String transcriptionActiveModel(String quality, String model) {
    return 'Activo: $quality ($model)';
  }

  @override
  String get badgeRecommended => 'REC';

  @override
  String get languageLabel => 'Idioma';

  @override
  String warningEnglishOnlyModel(String model, String language) {
    return 'Advertencia: El modelo seleccionado ($model) solo admite inglés. Transcribir en \"$language\" fallará o generará subtítulos en inglés. Selecciona un modelo multilingüe (ej. Tiny o Base).';
  }

  @override
  String get tipAutoDetectMixedLanguage =>
      'Consejo: No se recomienda la autodetección para idiomas mixtos (como Hinglish). Seleccionar explícitamente el idioma hablado (ej. español o inglés) proporcionará subtítulos mucho más precisos.';

  @override
  String get detectedHardwareLabel => 'Hardware del sistema detectado:';

  @override
  String hardwareRamSize(String ramGB) {
    return 'Tamaño de RAM: $ramGB GB';
  }

  @override
  String hardwareCpuCores(int cores) {
    return 'Núcleos lógicos de CPU: $cores';
  }

  @override
  String hardwareGpuDevice(String gpu) {
    return 'Dispositivo GPU: $gpu';
  }

  @override
  String get hardwareDetecting => 'Detectando estadísticas de hardware...';

  @override
  String get btnStartReTranscribe => 'INICIAR RETRANSCRIPCIÓN';

  @override
  String get btnImportSrtVtt => 'IMPORTAR ARCHIVO SRT/VTT';

  @override
  String importedSubtitleWords(int count) {
    return 'Se importaron $count palabras del archivo de subtítulos.';
  }

  @override
  String get errorImportSubtitleFailed =>
      'Error al importar el archivo de subtítulos. Verifica el formato del archivo.';

  @override
  String get noProjectLoaded => 'Ningún proyecto cargado';

  @override
  String get badge916Vertical => '9:16 VERTICAL';

  @override
  String get badge169Landscape => '16:9 HORIZONTAL';

  @override
  String get reframeTargetCanvas =>
      'Lienzo de destino: 1080 × 1920 (TikTok, YouTube Shorts, Instagram Reels)';

  @override
  String get reframeModeLabel => 'Modo de reencuadre:';

  @override
  String get reframeModeBlurPillarbox =>
      'Pillarbox con desenfoque (Recomendado)';

  @override
  String get reframeModeBlurPillarboxDesc =>
      'Escala y desenfoca el video de fondo para llenar 9:16, manteniendo nítido el video centrado.';

  @override
  String get reframeModeCenterCrop => 'Recorte inteligente centrado';

  @override
  String get reframeModeCenterCropDesc =>
      'Llena toda la pantalla 9:16 recortando los bordes izquierdo y derecho.';

  @override
  String get reframeModeSplitScreen => 'Pantalla dividida / Capa doble';

  @override
  String get reframeModeSplitScreenDesc =>
      'Apila dos ventanas de video verticalmente (ideal para reacciones y diálogos de podcast).';

  @override
  String get btnResetTo169 => 'ACTUALMENTE 9:16 (RESTABLECER A 16:9)';

  @override
  String get btnSetCanvas916 => 'ESTABLECER LIENZO DEL PROYECTO EN 9:16';

  @override
  String get silenceRemovalDesc =>
      'Corta automáticamente pausas muertas y espacios de respiración para maximizar la retención del video.';

  @override
  String get silenceAggressivenessLabel => 'Agresividad del corte:';

  @override
  String silenceNoiseGateLabel(int db) {
    return 'Puerta de ruido para silencio: $db dB';
  }

  @override
  String silenceMinPauseLabel(String duration) {
    return 'Pausa mínima: ${duration}s';
  }

  @override
  String get btnScanning => 'ESCANEANDO...';

  @override
  String silenceNoneFound(String duration) {
    return 'No se encontraron silencios que superen los ${duration}s.';
  }

  @override
  String silenceFoundCount(int count, String totalSecs) {
    return '¡Se encontraron $count silencios (${totalSecs}s de tiempo muerto ahorrados)!';
  }

  @override
  String errorScanningAudio(String error) {
    return 'Error al escanear el audio: $error';
  }

  @override
  String jumpCutsApplied(int count) {
    return '¡Se aplicaron $count jump-cuts a la línea de tiempo del proyecto!';
  }

  @override
  String get viralHooksDesc =>
      'Escanea las palabras de transcripción en busca de más de 80 ganchos virales, ritmo (120–170 PPM), preguntas, densidad de energía y límites de clips.';

  @override
  String get btnAnalyzingTranscript => 'ANALIZANDO TRANSCRIPCIÓN...';

  @override
  String get selectAllLabel => 'Seleccionar todo';

  @override
  String selectedCountOf(int selected, int total) {
    return '$selected de $total seleccionados';
  }

  @override
  String get btnSelectClipsToBatchExport =>
      'SELECCIONAR CLIPS PARA EXPORTAR EN LOTE';

  @override
  String btnBatchExportCount(int count) {
    return 'EXPORTAR $count CLIP(S) EN LOTE';
  }

  @override
  String get viralNoClipsDetected =>
      'No se detectaron clips virales con alta puntuación en este rango de duración del video.';

  @override
  String get badgeCleanCut => 'CORTE LIMPIO';

  @override
  String get badgeFirst5s => 'PRIMEROS 5s';

  @override
  String get btnPreview => 'Vista previa';

  @override
  String get btnTrim => 'Recortar';

  @override
  String get tooltipForkAs916 => 'Bifurcar como nuevo proyecto Short 9:16';

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
    return 'Energía $score/20';
  }

  @override
  String get filePickerClipsFolderTitle => 'Elegir carpeta para guardar clips';

  @override
  String get errorChooseOutputFolderFirst =>
      'Por favor, elige primero una carpeta de salida.';

  @override
  String batchExportSheetTitle(int count) {
    return 'EXPORTAR $count CLIP(S) EN LOTE';
  }

  @override
  String get tapToChooseOutputFolder =>
      'Toca para elegir la carpeta de salida…';

  @override
  String get burnCaptionsOnClipsLabel =>
      'Incrustar subtítulos dinámicos en los clips';

  @override
  String get burnCaptionsOnClipsDesc =>
      'Incrusta subtítulos animados con estilo sincronizados con el audio del clip';

  @override
  String exportCancelledProgress(int done, int total) {
    return 'Exportación cancelada. $done/$total completados.';
  }

  @override
  String exportProgressSummary(int done, int total, int failed) {
    return '$done/$total exportados · $failed fallidos';
  }

  @override
  String get btnExporting => 'EXPORTANDO…';

  @override
  String get btnExportComplete => 'EXPORTACIÓN COMPLETADA ✓';

  @override
  String get btnStartExport => 'INICIAR EXPORTACIÓN';

  @override
  String exportClipSavedAt(String path) {
    return '✓ Guardado: $path';
  }

  @override
  String projectTrimmedToClip(int rank, String start, String end) {
    return '¡Proyecto recortado al clip viral #$rank ($start - $end)!';
  }

  @override
  String shortProjectCreated(String name) {
    return 'Short 9:16 creado: \"$name\"';
  }

  @override
  String get btnOpen => 'ABRIR';

  @override
  String errorCreateShortProjectFailed(String error) {
    return 'Error al crear el proyecto de short: $error';
  }

  @override
  String get autoDetect => 'Detección automática';

  @override
  String presetSaved(String name) {
    return '¡Ajuste preestablecido de estilo \"$name\" guardado correctamente!';
  }

  @override
  String get presetDeleted => 'Ajuste preestablecido eliminado correctamente.';

  @override
  String get presetExported =>
      '¡Ajustes preestablecidos de estilo exportados correctamente!';

  @override
  String errorPresetExportFailed(String error) {
    return 'Error al exportar ajustes preestablecidos: $error';
  }

  @override
  String get presetImported =>
      '¡Ajustes preestablecidos de estilo importados correctamente!';

  @override
  String errorPresetImportFailed(String error) {
    return 'Error al importar ajustes preestablecidos: $error';
  }

  @override
  String get selectFontFileDialogTitle =>
      'Seleccionar archivo de fuente TTF u OTF';

  @override
  String get fontWeightThin => 'Fino';

  @override
  String get fontWeightExtraLight => 'Extra fino';

  @override
  String get fontWeightLight => 'Ligero';

  @override
  String get fontWeightNormal => 'Normal';

  @override
  String get fontWeightMedium => 'Medio';

  @override
  String get fontWeightSemiBold => 'Seminegrita';

  @override
  String get fontWeightBold => 'Negrita';

  @override
  String get fontWeightExtraBold => 'Extranegrita';

  @override
  String get fontWeightBlack => 'Negro';

  @override
  String get fontCaseNormal => 'Normal';

  @override
  String get fontCaseUppercase => 'MAYÚSCULAS';

  @override
  String get fontCaseCapitalize => 'Tipo título';

  @override
  String get strokeStyleThickOutline => 'Contorno grueso';

  @override
  String get strokeStyleNoneFlat => 'Ninguno (Plano)';

  @override
  String get shadowStyleSoft => 'Sombra suave';

  @override
  String get shadowStyleNone => 'Ninguna';

  @override
  String get animStyleActivePop => 'Pop activo';

  @override
  String get animStyleActiveBounce => 'Rebote activo';

  @override
  String get animStyleKineticTilt => 'Inclinación cinética';

  @override
  String get animStyleGlowPulse => 'Pulso brillante activo';

  @override
  String get animStyleWordReveal => 'Aparición escalonada de palabras';

  @override
  String get animStyleNoneStatic => 'Ninguno (Estático)';

  @override
  String fontImportedSuccess(String name) {
    return '¡Fuente personalizada \"$name\" importada y aplicada con éxito!';
  }

  @override
  String get errorFontImportFailed =>
      'Error al cargar el archivo de fuente. Datos no válidos.';

  @override
  String get invalidTimingError =>
      'Tiempos de inicio/fin no válidos. El inicio debe ser >= 0, y el fin debe ser >= inicio y <= a la duración del video.';

  @override
  String get projectSavedSuccess => 'Proyecto guardado correctamente.';

  @override
  String wordDeletedSuccess(String text) {
    return 'Palabra eliminada: \"$text\"';
  }

  @override
  String get splitClip => 'Dividir clip';

  @override
  String get removeClip => 'Eliminar clip';

  @override
  String get resetToOriginal => 'Restablecer al original';

  @override
  String splitTimelineAt(String time) {
    return 'Línea de tiempo dividida en ${time}s.';
  }

  @override
  String get splitTimelineError =>
      'El cabezal de reproducción debe estar dentro de la región activa para dividir.';

  @override
  String get exclusionToggled =>
      'Se alternó la exclusión del segmento bajo el cabezal de reproducción.';

  @override
  String get splitsReset =>
      'Se restablecieron todas las divisiones y exclusiones de la línea de tiempo.';

  @override
  String get shareVideo => 'Compartir video';

  @override
  String get openOutputFolder => 'Abrir carpeta de salida';

  @override
  String get errorLogCopied => 'Registro de errores copiado al portapapeles.';

  @override
  String get diagnosticsExported =>
      'Informe de diagnóstico filtrado abierto en la hoja para compartir.';

  @override
  String errorDiagnosticsFailed(String error) {
    return 'Error al exportar el informe de diagnóstico: $error';
  }

  @override
  String logLineCopied(String message) {
    return 'Línea de registro copiada al portapapeles: \"$message\"';
  }

  @override
  String commandCopied(String command) {
    return 'Copiado: \"$command\"';
  }

  @override
  String get settingsRestored =>
      'Configuración restablecida a los valores predeterminados.';

  @override
  String get gpuEncoderNoneCpu => 'Ninguno (CPU)';

  @override
  String get gpuEncoderNvidia => 'NVIDIA NVENC';

  @override
  String get gpuEncoderAmd => 'AMD AMF';

  @override
  String get gpuEncoderIntel => 'Intel QSV';

  @override
  String get gpuEncoderApple => 'Apple VideoToolbox';

  @override
  String get btnDownloadVcRedist => 'DESCARGAR VC++ REDISTRIBUTABLE';

  @override
  String errorDownloadToolFailed(String error) {
    return 'Error al descargar la herramienta: $error';
  }

  @override
  String get errorFolderNotAccessible =>
      'La carpeta seleccionada no existe o no es accesible.';

  @override
  String modelDeleted(String name) {
    return 'Modelo eliminado: $name';
  }

  @override
  String errorModelDeleteFailed(String error) {
    return 'Error al eliminar el modelo: $error';
  }

  @override
  String errorModelDownloadFailed(String name, String error) {
    return 'Error al descargar el modelo $name: $error';
  }

  @override
  String errorOpenFolderFailed(String path) {
    return 'No se pudo abrir la carpeta automáticamente. Ruta: $path';
  }

  @override
  String errorDownloadPackFailed(String error) {
    return 'Error al descargar el paquete: $error';
  }

  @override
  String errorPackDownloadNamedFailed(String name, String error) {
    return 'Error al descargar el paquete $name: $error';
  }

  @override
  String get stickersIndexRefreshed =>
      '¡Índice de stickers personalizados actualizado correctamente!';

  @override
  String errorChangeAssetFolderFailed(String error) {
    return 'Error al cambiar la carpeta de activos: $error';
  }

  @override
  String errorSetAssetFolderFailed(String error) {
    return 'Error al establecer la carpeta de activos: $error';
  }

  @override
  String get warningNoAvx =>
      '¡Se detectó falta de compatibilidad con AVX! Descargando whisper-cli compatible (sin AVX)...';

  @override
  String get errorAutoDetectWhisper =>
      'No se pudo autodetectar whisper-cli. Por favor, explora manualmente.';

  @override
  String get errorAutoDetectFfmpeg =>
      'No se pudo autodetectar ffmpeg. Por favor, explora manualmente.';

  @override
  String errorToolDownloadFailed(String error) {
    return 'Error al descargar la herramienta: $error';
  }

  @override
  String get returnToDashboard => 'Volver al panel principal';

  @override
  String errorImportVideoFailed(String error) {
    return 'Error en la importación: $error';
  }

  @override
  String get videoRelinkedSuccess => '¡Video revinculado correctamente!';

  @override
  String get errorRelinkVideoFailed => 'Error al revincular el video.';

  @override
  String get retranscriptionSuccess => '¡Retranscripción exitosa!';

  @override
  String get retranscriptionFailed => 'Falló la retranscripción.';
}
