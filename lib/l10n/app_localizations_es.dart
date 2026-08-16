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
}
