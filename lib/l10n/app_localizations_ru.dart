// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appName => 'CapStudio';

  @override
  String get dashboardTitle => 'Мои проекты';

  @override
  String get dashboardSubtitle => 'Автономная AI студия для создания субтитров';

  @override
  String get importVideo => 'Импортировать видео';

  @override
  String get dragDropText => 'Перетащите файл видео сюда';

  @override
  String get clickBrowse => 'или нажмите для выбора на компьютере';

  @override
  String get demoMode => 'ДЕМО-РЕЖИМ';

  @override
  String get demoModeDesc =>
      'Загрузите демонстрационный проект для тестирования стилей и функций редактора.';

  @override
  String get warningAssets => 'Требуется восстановление папки ресурсов';

  @override
  String get warningAssetsDesc =>
      'Встроенные ресурсы не найдены в папке поддержки приложения. Дважды щелкните здесь для восстановления или изменения каталога ресурсов.';

  @override
  String get deleteProjectTitle => 'Удалить проект';

  @override
  String deleteProjectConfirm(String projectName) {
    return 'Вы уверены, что хотите навсегда удалить проект \"$projectName\"? Это действие нельзя отменить.';
  }

  @override
  String get renameProjectTitle => 'Переименовать проект';

  @override
  String get projectNameLabel => 'Имя проекта';

  @override
  String get btnCancel => 'ОТМЕНА';

  @override
  String get btnDelete => 'УДАЛИТЬ';

  @override
  String get btnRename => 'ПЕРЕИМЕНОВАТЬ';

  @override
  String get btnSave => 'СОХРАНИТЬ';

  @override
  String get btnConfirm => 'ПОДТВЕРДИТЬ';

  @override
  String get btnExport => 'ЭКСПОРТ';

  @override
  String get btnUndo => 'Отменить';

  @override
  String get btnRedo => 'Повторить';

  @override
  String get statusDraft => 'Черновик';

  @override
  String get statusCompleted => 'Завершен';

  @override
  String get createdLabel => 'Создан:';

  @override
  String get durationLabel => 'Длительность:';

  @override
  String get statusLabel => 'Статус:';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsGeneral => 'Общие настройки';

  @override
  String get settingsTheme => 'Тема приложения';

  @override
  String get themeSystem => 'Системная тема';

  @override
  String get themeLight => 'Светлая тема';

  @override
  String get themeDark => 'Темная тема';

  @override
  String get settingsLanguage => 'Язык интерфейса';

  @override
  String get settingsTranscription => 'Настройки распознавания текста';

  @override
  String get settingsWhisperModel => 'Модель Whisper';

  @override
  String get settingsWhisperModelDesc =>
      'Выберите модель для распознавания текста. Меньшие модели работают быстрее, большие — точнее.';

  @override
  String get settingsTranscribeLang => 'Язык распознавания';

  @override
  String get settingsAutoDetect => 'Автоопределение языка';

  @override
  String get settingsGPU => 'Аппаратное ускорение GPU (CUDA)';

  @override
  String get settingsVAD => 'Порог VAD (активность голоса)';

  @override
  String get settingsExport => 'Настройки экспорта';

  @override
  String get settingsExportDest => 'Папка экспорта по умолчанию';

  @override
  String get settingsBrowse => 'Обзор';

  @override
  String get settingsEmojiPacks => 'Пакеты эмодзи и стилей';

  @override
  String get settingsEmojiPacksDesc =>
      'Настройте стили отображения эмодзи и активные файлы субтитров.';

  @override
  String get settingsEmojiSearchLang => 'Язык поиска эмодзи';

  @override
  String get settingsBtnManagePacks => 'УПРАВЛЕНИЕ ПАКЕТАМИ ЭМОДЗИ';

  @override
  String get systemTitle => 'Информация о системе';

  @override
  String get systemVersion => 'Версия';

  @override
  String get systemReset => 'Сбросить настройки';

  @override
  String get editorTabCaptions => 'Субтитры';

  @override
  String get editorTabStyles => 'Стили';

  @override
  String get editorTabTrim => 'Обрезка';

  @override
  String get editorTabAudio => 'Звук';

  @override
  String get editorTabTranscription => 'Транскрипция';

  @override
  String get editorTabShortcuts => 'Горячие клавиши';

  @override
  String get editorTabDebug => 'Отладка';

  @override
  String get editorHeaderBack => 'Назад';

  @override
  String get editorKeyboardShortcuts => 'Горячие клавиши клавиатуры';

  @override
  String get dialogAnalyzing => 'Анализ видео...';

  @override
  String get dialogTranscribing => 'Распознавание речи...';

  @override
  String get dialogExtracting => 'Извлечение аудио...';

  @override
  String get dialogWait =>
      'Это может занять некоторое время. Пожалуйста, подождите.';

  @override
  String get dialogError => 'Ошибка';

  @override
  String get dialogImportFailed => 'Не удалось импортировать видео.';

  @override
  String get noProjects => 'Проекты еще не созданы';

  @override
  String get aboutApp => 'О CapStudio';

  @override
  String get aboutAppDesc =>
      'Описание CapStudio, благодарности и лицензии с открытым исходным кодом.';

  @override
  String get aboutAppThanks =>
      'Особая благодарность проектам с открытым исходным кодом, благодаря которым создана программа CapStudio:';

  @override
  String get btnViewAllLicenses => 'ПОСМОТРЕТЬ ВСЕ ЛИЦЕНЗИИ ПАКЕТОВ';
}
