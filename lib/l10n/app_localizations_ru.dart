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

  @override
  String get exportBurnIn => 'ЭКСПОРТ ВИДЕО СО ВСТРОЕННЫМИ СУБТИТРАМИ';

  @override
  String get exportTimecodeFormats => 'ФОРМАТЫ СУБТИТРОВ С ВРЕМЕННЫМИ КОДАМИ';

  @override
  String get exportWebEnabled =>
      'Экспорт видео на стороне клиента включен. Рендеринг выполняется локально в вашем браузере.';

  @override
  String get exportWebCaptionOnly =>
      'Веб-экспорт сейчас включает только субтитры — эмодзи и звуковые эффекты пока не встраиваются в видео. Экспортируйте из настольного или мобильного приложения для полного результата.';

  @override
  String get exportOutputName => 'Имя выходного видео';

  @override
  String get exportMode => 'Режим экспорта';

  @override
  String get exportModeFast => 'Быстрый (встроенный FFmpeg)';

  @override
  String get exportModeFastUnsupported =>
      'Быстрый (встроенный FFmpeg) ⚠️ Не поддерживается';

  @override
  String get exportModeSlow => 'Медленный (рендер 1:1 как в предпросмотре)';

  @override
  String get exportTargetFps => 'Целевой FPS';

  @override
  String get exportFps24 => '24 FPS (кино)';

  @override
  String get exportFps25 => '25 FPS (PAL)';

  @override
  String get exportFps30 => '30 FPS (стандарт)';

  @override
  String get exportFps50 => '50 FPS';

  @override
  String get exportFps60 => '60 FPS (плавно)';

  @override
  String get exportFastUnsupported =>
      'Быстрый режим не поддерживается на этом устройстве, так как в системной сборке FFmpeg отсутствуют фильтры рендеринга субтитров (libass). Вместо него будет использован медленный режим.';

  @override
  String get exportSlowInfo =>
      'Захватывает каждый кадр точно так, как он показан в предпросмотре. Это гарантирует попиксельно точные субтитры, но рендеринг выполняется медленнее.';

  @override
  String get exportDestDirectory => 'ЦЕЛЕВАЯ ПАПКА';

  @override
  String get exportDestBrowser => 'Место загрузки в браузере';

  @override
  String get exportDestAndroid =>
      'Папка «Загрузки» (/storage/emulated/0/Download)';

  @override
  String get exportDestIos =>
      'Документы приложения (лист общего доступа после экспорта)';

  @override
  String get exportChooseFolder => 'Выбрать папку для вывода';

  @override
  String get exportStartMp4 => 'НАЧАТЬ ЭКСПОРТ MP4';

  @override
  String get exportSrtTitle => 'Субтитры SubRip (.srt)';

  @override
  String get exportSrtDesc =>
      'Универсальный стандарт с временными кодами. Совместим с YouTube, VLC и Premiere Pro.';

  @override
  String get exportVttTitle => 'Субтитры WebVTT (.vtt)';

  @override
  String get exportVttDesc =>
      'Веб-оптимизированный формат субтитров, широко используемый в HTML5-плеерах и онлайн-стриминге.';

  @override
  String get exportAssTitle => 'Advanced SubStation Alpha (.ass)';

  @override
  String get exportAssDesc =>
      'Профессиональный формат, поддерживающий размеры шрифтов, стили, поля и встроенные выделения.';

  @override
  String get exportTxtTitle => 'Текстовая расшифровка (.txt)';

  @override
  String get exportTxtDesc =>
      'Построчная расшифровка с префиксами временных меток.';

  @override
  String exportSuccess(String type) {
    return 'Экспорт $type выполнен успешно!';
  }

  @override
  String get exportNoLocation =>
      'Место сохранения не выбрано. Пожалуйста, укажите путь к файлу.';

  @override
  String get exportNoLocationCancelled =>
      'Место сохранения не выбрано. Экспорт отменен.';

  @override
  String exportFailed(String error) {
    return 'Не удалось выполнить экспорт: $error';
  }

  @override
  String get exportCopySrtTooltip => 'Скопировать SRT в буфер обмена';

  @override
  String get exportCopiedSrt => 'SRT скопирован в буфер обмена!';

  @override
  String exportCopyFailedSrt(String error) {
    return 'Не удалось скопировать SRT: $error';
  }

  @override
  String exportSubtitlesDialogTitle(String type) {
    return 'Экспорт субтитров $type';
  }

  @override
  String get exportVideoDialogTitle => 'Экспорт видео в MP4';

  @override
  String get ffmpegRequiredTitle => 'Требуется FFmpeg';

  @override
  String get ffmpegRequiredBody =>
      'Для встраивания субтитров в видеофайл требуется локальная установка FFmpeg.\n\nУкажите путь к FFmpeg в настройках.';

  @override
  String get okLabel => 'OK';

  @override
  String get exportWebTitle => 'Экспорт видео (на стороне клиента)';

  @override
  String exportWebSuccess(String fileName) {
    return 'Видео успешно экспортировано как $fileName!';
  }

  @override
  String exportWebFailed(String error) {
    return 'Ошибка рендеринга: $error';
  }

  @override
  String get viralShortsTitle => 'СТУДИЯ ВИРУСНЫХ SHORTS';

  @override
  String get viralShortsSubtitle =>
      'Вертикальный рефрейм 9:16, джамп-каты тишины и ИИ-детектор хуков';

  @override
  String get viralReframeTitle => '1. ВЕРТИКАЛЬНЫЙ РЕФРЕЙМ 9:16';

  @override
  String get viralSilenceTitle => '2. УДАЛЕНИЕ ТИШИНЫ (ДЖАМП-КАТЫ)';

  @override
  String get viralHooksTitle => '3. ИИ-ДЕТЕКТОР ВИРУСНЫХ ХУКОВ';

  @override
  String get btnFindViralMoments => 'НАЙТИ ВИРУСНЫЕ МОМЕНТЫ';

  @override
  String get btnScanSilences => 'СКАНИРОВАТЬ ТИШИНУ';

  @override
  String get btnApplyJumpCuts => 'ПРИМЕНИТЬ ДЖАМП-КАТЫ';

  @override
  String get editorTabShorts => 'Shorts';

  @override
  String get editorTabClips => 'Клипы';

  @override
  String get captionList => 'СПИСОК СУБТИТРОВ';

  @override
  String get uncertainLabel => 'Неуверенно (<40%)';

  @override
  String get mediumConfidenceLabel => 'Средняя точность (40-60%)';

  @override
  String get jumpToUncertain => 'Перейти к следующему неуверенному слову';

  @override
  String get noUncertainWords => 'Неуверенных слов не найдено.';

  @override
  String get findAndReplace => 'Найти и заменить';

  @override
  String get addWordTitle => 'Добавить слово';

  @override
  String get editWordTitle => 'Редактировать слово';

  @override
  String get wordTextLabel => 'Текст слова';

  @override
  String get startTimeLabel => 'Время начала (с)';

  @override
  String get endTimeLabel => 'Время окончания (с)';

  @override
  String get splitChunk => 'Разделить фрагмент';

  @override
  String get insertLineAfter => 'Вставить строку после';

  @override
  String get duplicateLine => 'Дублировать строку';

  @override
  String get deleteLine => 'Удалить строку';

  @override
  String get chooseSfxTitle => 'Выбрать звуковой эффект';

  @override
  String get searchSfxPlaceholder => 'Поиск звуковых эффектов...';

  @override
  String get noSfxFound => 'Звуковые эффекты не найдены';

  @override
  String get emojiSearch => 'Поиск эмодзи';

  @override
  String get noEmojisFound => 'Эмодзи не найдены.';

  @override
  String get mySavedPresets => 'МОИ СОХРАНЕННЫЕ ПРЕСЕТЫ';

  @override
  String get btnImport => 'ИМПОРТ';

  @override
  String get btnExportCaps => 'ЭКСПОРТ';

  @override
  String get btnSaveCurrent => 'СОХРАНИТЬ ТЕКУЩИЙ';

  @override
  String get resetToDefault => 'Сбросить по умолчанию';

  @override
  String get resetConfirmBody =>
      'Все стили субтитров будут сброшены к значениям по умолчанию. Это действие нельзя отменить.';

  @override
  String get btnReset => 'Сбросить';

  @override
  String get wordHighlightBox => 'Плашка подсветки слова';

  @override
  String get wordHighlightBoxDesc =>
      'Цветная плашка под текущим произносимым словом';

  @override
  String get maxWordsPerChunk => 'Макс. слов во фрагменте субтитров';

  @override
  String get maxCharsPerLine => 'Макс. символов в строке субтитров';

  @override
  String get fontSettings => 'Параметры шрифта';

  @override
  String get colorSettings => 'Настройки цвета';

  @override
  String get borderSettings => 'Параметры обводки и тени';

  @override
  String get speechToTextTitle => 'РАСПОЗНАВАНИЕ РЕЧИ В ТЕКСТ';

  @override
  String get speechToTextDesc =>
      'Повторно запустить локальное распознавание речи. Все ручные правки и тайминги будут заменены.';

  @override
  String get useLocalAi => 'Использовать локальный ИИ для распознавания';

  @override
  String get runOnDeviceDesc =>
      'Запуск распознавания речи прямо на этом устройстве';

  @override
  String get offlineDemoModeActive =>
      'Активен демо-режим офлайн. Локальное распознавание Whisper AI не поддерживается в веб-версии.';

  @override
  String get demoModeNote =>
      'Демо-режим мгновенно создает реалистичный транскрипт. Идеально для тестирования стилей, шаблонов и работы с таймлайном без предварительной настройки.';

  @override
  String get transcriptionQuality => 'Качество распознавания';

  @override
  String get advancedSettings => 'Дополнительные настройки';

  @override
  String get cpuThreadsLabel => 'Потоки процессора';

  @override
  String get vadSensitivity => 'Чувствительность VAD';

  @override
  String get translateToEnglish => 'Переводить субтитры на английский';

  @override
  String get startTranscriptionBtn => 'НАЧАТЬ РАСПОЗНАВАНИЕ';

  @override
  String get hardwareLocked => 'Ограничено оборудованием';

  @override
  String get btnDownload => 'Скачать';

  @override
  String get welcomeTitle => 'Добро пожаловать в CapStudio';

  @override
  String get welcomeSubtitle =>
      'Высокоточные субтитры и вирусные Shorts, 100% офлайн.';

  @override
  String get setupAssetDirTitle => 'Выберите папку для ресурсов';

  @override
  String get setupAssetDirDesc =>
      'Выберите каталог для хранения моделей, шрифтов и пакетов эмодзи.';

  @override
  String get downloadPacksTitle => 'Загрузить пакеты контента (необязательно)';

  @override
  String get downloadPacksDesc =>
      'Дополнительные шрифты и звуковые эффекты для ваших видеопроектов.';

  @override
  String get setupCompleteTitle => 'Настройка завершена';

  @override
  String get setupCompleteDesc =>
      'Все готово для создания великолепных видео с субтитрами.';

  @override
  String get btnGetStarted => 'Начать работу';

  @override
  String get btnNext => 'ДАЛЕЕ';

  @override
  String get btnSkip => 'ПРОПУСТИТЬ';

  @override
  String get onboardingFeaturePrivacy => '100% конфиденциальность';

  @override
  String get onboardingFeaturePrivacyDesc =>
      'Файлы никогда не покидают ваше устройство. Все модели ИИ работают локально.';

  @override
  String get onboardingFeatureGpu => 'Воспроизведение с ускорением GPU';

  @override
  String get onboardingFeatureGpuDesc =>
      'Высокая производительность монтажа с аппаратным декодированием.';

  @override
  String get onboardingFeatureAssets => 'Локальные автономные ресурсы';

  @override
  String get onboardingFeatureAssetsDesc =>
      'Скачайте наборы эмодзи один раз и используйте их полностью без интернета.';

  @override
  String get onboardingReadyTitle => 'Все готово к работе!';

  @override
  String get onboardingConfigDetails => 'Сведения о конфигурации:';

  @override
  String get btnLaunchCapStudio => 'Запустить CapStudio';

  @override
  String get assetVerificationFailed =>
      'Проверка ресурсов не удалась. Убедитесь, что ресурсы скачаны корректно.';

  @override
  String get assetsFolderNotFound => 'Папка ресурсов не найдена';

  @override
  String get assetsFolderNotFoundDesc =>
      'CapStudio не удалось найти папку ресурсов по указанному пути. Если она находится на внешнем диске, подключите его.';

  @override
  String get expectedPathLabel => 'ОЖИДАЕМЫЙ ПУТЬ:';

  @override
  String get browseNewLocation => 'Указать новое расположение';

  @override
  String get resetToDefaultPath => 'Сбросить на путь по умолчанию';

  @override
  String get retryVerification => 'Повторить проверку';

  @override
  String get storagePathFolder => 'Папка хранилища';

  @override
  String get tipWindowsDrive =>
      'Совет: если диск C: заполнен, выберите путь на диске D: или E:, где больше свободного места.';

  @override
  String get tipGeneralDrive =>
      'Совет: можно выбрать внешний накопитель, если основной диск заполнен.';

  @override
  String get confirmLocation => 'Подтвердить расположение';

  @override
  String get requiredBadge => 'ОБЯЗАТЕЛЬНО';

  @override
  String get emojiPacksHeader => 'ПАКЕТЫ ЭМОДЗИ';

  @override
  String get fontPacksHeader => 'ПАКЕТЫ ШРИФТОВ';

  @override
  String get connectCliTitle => 'Подключение локальных утилит CLI';

  @override
  String get connectCliDesc =>
      'CapStudio требуются исполняемые файлы whisper.cpp и FFmpeg для локального распознавания и экспорта видео.';

  @override
  String get skipSetup => 'Пропустить настройку';

  @override
  String get btnValidate => 'Проверить';

  @override
  String get autoDetectAndValidate => 'Автоопределение и проверка';

  @override
  String get whisperCliPathLabel => 'Путь к исполняемому файлу Whisper CLI';

  @override
  String get ffmpegCliPathLabel => 'Путь к исполняемому файлу FFmpeg CLI';

  @override
  String get newProject => 'Новый проект';

  @override
  String get searchProjects => 'Поиск проектов...';

  @override
  String get filterAll => 'Все';

  @override
  String get sortByRecent => 'Сначала новые';

  @override
  String get sortByDuration => 'По длительности';

  @override
  String get noMatchingProjects => 'Нет проектов, соответствующих поиску';

  @override
  String get btnEdit => 'ИЗМЕНИТЬ';

  @override
  String get btnDuplicate => 'ДУБЛИРОВАТЬ';

  @override
  String get tooltipEdit => 'Редактировать';

  @override
  String get tooltipRename => 'Переименовать';

  @override
  String get tooltipDuplicate => 'Дублировать';

  @override
  String get tooltipDelete => 'Удалить';

  @override
  String get tooltipTheme => 'Тема';

  @override
  String get tooltipSettings => 'Настройки';

  @override
  String get selectDemoFormat => 'ВЫБЕРИТЕ ФОРМАТ ДЕМО';

  @override
  String get selectDemoDesc =>
      'Выберите формат разметки, чтобы оценить движок субтитров высокой четкости CapStudio, пословную анимацию и звуковую волну.';

  @override
  String get landscapeDemo => 'Горизонтальное демо';

  @override
  String get landscapeDemoDesc =>
      'Идеально для YouTube, компьютеров и презентаций.';

  @override
  String get portraitDemo => 'Вертикальное демо';

  @override
  String get portraitDemoDesc =>
      'Идеально для TikTok, Shorts, Reels и мобильных устройств.';

  @override
  String get format16x9 => 'Формат 16:9';

  @override
  String get format9x16 => 'Формат 9:16';

  @override
  String get dropVideoHere => 'ПЕРЕТАЩИТЕ ВИДЕО СЮДА';

  @override
  String get dropVideoSupported => 'Поддерживаются MP4, MOV, AVI и др.';

  @override
  String get statusLocalOffline => 'ЛОКАЛЬНО ОФЛАЙН';

  @override
  String get speechModelTitle => 'Модель распознавания речи';

  @override
  String get hardwareUpgradesTitle => 'Аппаратное ускорение производительности';

  @override
  String get showAdvancedPaths => 'ПОКАЗАТЬ ДОПОЛНИТЕЛЬНЫЕ ПУТИ';

  @override
  String get hideAdvancedPaths => 'СКРЫТЬ ДОПОЛНИТЕЛЬНЫЕ ПУТИ';

  @override
  String get autoDownload => 'АВТОЗАГРУЗКА';

  @override
  String get gpuAcceleratedTranscription =>
      'Распознавание с ускорением GPU (CUDA)';

  @override
  String get gpuRequiresNvidia =>
      'Требуется видеокарта NVIDIA с поддержкой CUDA';

  @override
  String get gpuExportEncoder => 'Аппаратный энкодер экспорта GPU';

  @override
  String get gpuExportEncoderDesc =>
      'Аппаратное ускорение для экспорта видео MP4';

  @override
  String get defaultLanguage => 'Язык по умолчанию';

  @override
  String get vadTitle => 'Детектор активности голоса (VAD)';

  @override
  String get vadDesc => 'Пропускает участки тишины при обработке';

  @override
  String get vadThreshold => 'Порог срабатывания VAD';

  @override
  String get autoSaveTitle => 'Автосохранение';

  @override
  String get autoSaveDesc =>
      'Автоматически сохранять изменения проекта в базу данных каждые 3 секунды';

  @override
  String get defaultOutputsTitle => 'Параметры вывода по умолчанию';

  @override
  String get defaultExportFolder => 'Папка экспорта по умолчанию';

  @override
  String get alwaysAskExportPath => 'Всегда запрашивать путь экспорта';

  @override
  String get alwaysAskExportPathDesc =>
      'Запрашивать папку сохранения при каждом экспорте (ПК)';

  @override
  String get performanceTitle => 'Производительность';

  @override
  String get exportCpuThreads => 'Потоки CPU для экспорта';

  @override
  String get exportCpuThreadsDesc =>
      'Количество потоков процессора для рендеринга (автоматически подбирается под устройство)';

  @override
  String get aboutAppSubtitle =>
      '100% офлайн, конфиденциальная студия создания субтитров на базе ИИ';

  @override
  String get openSourceLicenses => 'Лицензии открытого ПО';

  @override
  String get openSourceComplianceDesc =>
      'CapStudio использует множество библиотек с открытым исходным кодом. Полный реестр всех пакетов Dart, транзитивных зависимостей и тексты лицензий приведены ниже в соответствии с требованиями магазинов приложений.';

  @override
  String get visitWebsite => 'Посетить веб-сайт';

  @override
  String get btnContinue => 'Продолжить';

  @override
  String get btnBack => 'Назад';

  @override
  String get editTiming => 'Изменить тайминг';

  @override
  String get wordSettingsTitle => 'Настройки слова';

  @override
  String get emojiSettingsTitle => 'НАСТРОЙКИ ЭМОДЗИ';

  @override
  String get changeEmojiTooltip => 'Сменить эмодзи';

  @override
  String get searchEmojisHint => 'Поиск эмодзи...';

  @override
  String emojiPosX(String offset) {
    return 'Позиция эмодзи (смещение по X: ${offset}px)';
  }

  @override
  String emojiPosY(String offset) {
    return 'Позиция эмодзи (смещение по Y: ${offset}px)';
  }

  @override
  String emojiScale(String scale) {
    return 'Масштаб эмодзи (${scale}x)';
  }

  @override
  String emojiAnimSpeed(String speed) {
    return 'Скорость анимации (${speed}x)';
  }

  @override
  String get emojiStylePack => 'Стиль / Пакет эмодзи';

  @override
  String get selectStylePackTooltip => 'Выбрать пакет стилей';

  @override
  String get selectEmojiTitle => 'ВЫБЕРИТЕ ЭМОДЗИ';

  @override
  String get stylePackLabel => 'ПАКЕТ СТИЛЕЙ';

  @override
  String get searchHint => 'Поиск...';

  @override
  String get btnCreateProject => 'СОЗДАТЬ ПРОЕКТ';

  @override
  String get btnChooseFile => 'ВЫБРАТЬ ФАЙЛ';

  @override
  String get selectSubtitleFile => 'Выберите файл субтитров';

  @override
  String get selectTranscriptionQuality => 'ВЫБЕРИТЕ КАЧЕСТВО РАСПОЗНАВАНИЯ';

  @override
  String get translateToEnglishDesc =>
      'Переводить иностранную речь напрямую в английские субтитры';

  @override
  String get hardwareSettings => 'НАСТРОЙКИ ОБОРУДОВАНИЯ И ПРОИЗВОДИТЕЛЬНОСТИ';

  @override
  String get styleTemplatesHeader => 'ШАБЛОНЫ СТИЛЕЙ';

  @override
  String get resetToDefaultStyle => 'Сбросить к стилю по умолчанию';

  @override
  String get resetStylingTitle => 'Сбросить оформление?';

  @override
  String get resetStylingDesc =>
      'Все стили субтитров будут сброшены к значениям по умолчанию. Это действие нельзя отменить.';

  @override
  String get sizeAndPosition => 'РАЗМЕР И ПОЛОЖЕНИЕ';

  @override
  String get verticalYPos => 'Положение по вертикали Y (%)';

  @override
  String get fontConfigHeader => 'НАСТРОЙКА ШРИФТА';

  @override
  String get fontFamilyLabel => 'Семейство шрифтов';

  @override
  String get btnImportCustomFont => 'ИМПОРТ СВОЕГО ШРИФТА (.ttf / .otf)';

  @override
  String get fontWeightLabel => 'Насыщенность шрифта';

  @override
  String get textCaseLabel => 'Регистр текста';

  @override
  String get fontSizeLabel => 'Размер шрифта';

  @override
  String get letterSpacingLabel => 'Межбуквенный интервал';

  @override
  String get lineHeightLabel => 'Высота строки';

  @override
  String get onboardingAppTagline =>
      'Полностью автономный локальный редактор субтитров на базе ИИ';

  @override
  String get configLabelWhisperCli => 'Whisper CLI';

  @override
  String get configValueDemoMode => 'Демо-режим (эмуляция)';

  @override
  String get configLabelFfmpegCli => 'FFmpeg CLI';

  @override
  String get configValueSystemPathDefault => 'По умолчанию из системного PATH';

  @override
  String get configLabelAssetsLocation => 'Расположение ресурсов';

  @override
  String get filePickerAssetsDialogTitle => 'Выберите папку ресурсов CapStudio';

  @override
  String errorSelectFolderFailed(String error) {
    return 'Не удалось выбрать папку: $error';
  }

  @override
  String errorResetFailed(String error) {
    return 'Не удалось сбросить: $error';
  }

  @override
  String errorVerificationFailed(String error) {
    return 'Проверка не удалась: $error';
  }

  @override
  String errorAssetsFolderStillMissing(String path) {
    return 'Папка ресурсов по-прежнему не найдена по пути: $path';
  }

  @override
  String get dbRecoveredTitle => 'База данных успешно восстановлена';

  @override
  String dbRecoveredBody(String backupPath) {
    return 'Обнаружено несоответствие схемы или повреждение базы данных. База данных была сброшена, а резервная копия сохранена в:\n\n$backupPath';
  }

  @override
  String errorDemoLoadFailed(String error) {
    return 'Не удалось загрузить демо-видео: $error';
  }

  @override
  String importProgressPercent(int percent) {
    return 'Выполнено $percent%';
  }

  @override
  String get errorInvalidDropFileFormat =>
      'Неверный формат файла. Перетащите видеофайл.';

  @override
  String get findTextLabel => 'Найти текст';

  @override
  String get replaceWithLabel => 'Заменить на';

  @override
  String findReplaceSuccessCount(int count) {
    return 'Заменено вхождений: $count!';
  }

  @override
  String get btnReplaceAll => 'ЗАМЕНИТЬ ВСЕ';

  @override
  String errorVideoFileNotFound(String path) {
    return 'Видеофайл не найден:\n$path\nПожалуйста, укажите путь к файлу заново.';
  }

  @override
  String get errorTranscriptionFailed =>
      'Распознавание не удалось. Пожалуйста, попробуйте снова.';

  @override
  String transcriptionActiveModel(String quality, String model) {
    return 'Активно: $quality ($model)';
  }

  @override
  String get badgeRecommended => 'РЕК';

  @override
  String get languageLabel => 'Язык';

  @override
  String warningEnglishOnlyModel(String model, String language) {
    return 'Внимание: выбранная модель ($model) поддерживает только английский язык. Распознавание на языке \"$language\" завершится ошибкой или создаст английские субтитры. Пожалуйста, выберите многоязычную модель (например, Tiny или Base).';
  }

  @override
  String get tipAutoDetectMixedLanguage =>
      'Совет: автоопределение не рекомендуется для смешанных языков. Явный выбор языка речи обеспечит гораздо более точные субтитры.';

  @override
  String get detectedHardwareLabel => 'Обнаруженное оборудование системы:';

  @override
  String hardwareRamSize(String ramGB) {
    return 'Объем ОЗУ: $ramGB ГБ';
  }

  @override
  String hardwareCpuCores(int cores) {
    return 'Логические ядра CPU: $cores';
  }

  @override
  String hardwareGpuDevice(String gpu) {
    return 'Видеокарта (GPU): $gpu';
  }

  @override
  String get hardwareDetecting => 'Определение характеристик оборудования...';

  @override
  String get btnStartReTranscribe => 'НАЧАТЬ ПОВТОРНОЕ РАСПОЗНАВАНИЕ';

  @override
  String get btnImportSrtVtt => 'ИМПОРТ ФАЙЛА SRT/VTT';

  @override
  String importedSubtitleWords(int count) {
    return 'Импортировано слов из файла субтитров: $count.';
  }

  @override
  String get errorImportSubtitleFailed =>
      'Не удалось импортировать файл субтитров. Проверьте формат файла.';

  @override
  String get noProjectLoaded => 'Проект не загружен';

  @override
  String get badge916Vertical => '9:16 ВЕРТИКАЛЬНЫЙ';

  @override
  String get badge169Landscape => '16:9 ГОРИЗОНТАЛЬНЫЙ';

  @override
  String get reframeTargetCanvas =>
      'Целевой холст: 1080 × 1920 (TikTok, YouTube Shorts, Instagram Reels)';

  @override
  String get reframeModeLabel => 'Режим кадрирования:';

  @override
  String get reframeModeBlurPillarbox =>
      'Размытые полосы по бокам (рекомендуется)';

  @override
  String get reframeModeBlurPillarboxDesc =>
      'Масштабирует и размывает фон для заполнения 9:16, сохраняя четкость видео в центре.';

  @override
  String get reframeModeCenterCrop => 'Умная обрезка по центру';

  @override
  String get reframeModeCenterCropDesc =>
      'Заполняет весь экран 9:16, обрезая видео по краям слева и справа.';

  @override
  String get reframeModeSplitScreen => 'Разделенный экран / Два слоя';

  @override
  String get reframeModeSplitScreenDesc =>
      'Размещает два видеоокна друг над другом (идеально для реакций и подкастов).';

  @override
  String get btnResetTo169 => 'СЕЙЧАС 9:16 (СБРОСИТЬ НА 16:9)';

  @override
  String get btnSetCanvas916 => 'УСТАНОВИТЬ ХОЛСТ ПРОЕКТА 9:16';

  @override
  String get silenceRemovalDesc =>
      'Автоматически вырезает паузы и вздохи для максимального удержания зрителей.';

  @override
  String get silenceAggressivenessLabel => 'Агрессивность вырезки:';

  @override
  String silenceNoiseGateLabel(int db) {
    return 'Шумовой порог тишины: $db дБ';
  }

  @override
  String silenceMinPauseLabel(String duration) {
    return 'Мин. пауза: $duration с';
  }

  @override
  String get btnScanning => 'СКАНИРОВАНИЕ...';

  @override
  String silenceNoneFound(String duration) {
    return 'Не найдено пауз длиннее $duration с.';
  }

  @override
  String silenceFoundCount(int count, String totalSecs) {
    return 'Найдено пауз: $count (вырезано $totalSecs с тишины)!';
  }

  @override
  String errorScanningAudio(String error) {
    return 'Ошибка сканирования аудио: $error';
  }

  @override
  String jumpCutsApplied(int count) {
    return 'На таймлайн проекта добавлено $count склеек (джамп-катов)!';
  }

  @override
  String get viralHooksDesc =>
      'Сканирует слова расшифровки на 80+ вирусных хуков, темп речи (120–170 сл/мин), вопросы, уровень энергии и границы клипов.';

  @override
  String get btnAnalyzingTranscript => 'АНАЛИЗ ТРАНСКРИПЦИИ...';

  @override
  String get selectAllLabel => 'Выбрать все';

  @override
  String selectedCountOf(int selected, int total) {
    return 'Выбрано: $selected из $total';
  }

  @override
  String get btnSelectClipsToBatchExport =>
      'ВЫБЕРИТЕ КЛИПЫ ДЛЯ ПАКЕТНОГО ЭКСПОРТА';

  @override
  String btnBatchExportCount(int count) {
    return 'ПАКЕТНЫЙ ЭКСПОРТ $count КЛИПОВ';
  }

  @override
  String get viralNoClipsDetected =>
      'В этом диапазоне длительности видео не найдено вирусных клипов с высоким рейтингом.';

  @override
  String get badgeCleanCut => 'ЧИСТАЯ СКЛЕЙКА';

  @override
  String get badgeFirst5s => 'ПЕРВЫЕ 5 С';

  @override
  String get btnPreview => 'Предпросмотр';

  @override
  String get btnTrim => 'Обрезать';

  @override
  String get tooltipForkAs916 => 'Создать отдельный проект Shorts 9:16';

  @override
  String wpmLabelOk(int wpm) {
    return '$wpm сл/мин ✓';
  }

  @override
  String wpmLabelFast(int wpm) {
    return '$wpm сл/мин БЫСТРО';
  }

  @override
  String wpmLabelSlow(int wpm) {
    return '$wpm сл/мин МЕДЛЕННО';
  }

  @override
  String hookScoreLabel(int score) {
    return 'Хук $score/40';
  }

  @override
  String energyScoreLabel(int score) {
    return 'Энергия $score/20';
  }

  @override
  String get filePickerClipsFolderTitle =>
      'Выберите папку для сохранения клипов';

  @override
  String get errorChooseOutputFolderFirst =>
      'Сначала выберите папку для сохранения.';

  @override
  String batchExportSheetTitle(int count) {
    return 'ПАКЕТНЫЙ ЭКСПОРТ $count КЛИПОВ';
  }

  @override
  String get tapToChooseOutputFolder => 'Нажмите, чтобы выбрать папку...';

  @override
  String get burnCaptionsOnClipsLabel =>
      'Вшивать динамические субтитры в клипы';

  @override
  String get burnCaptionsOnClipsDesc =>
      'Вшивает анимированные стилизованные субтитры синхронно со звуком клипа';

  @override
  String exportCancelledProgress(int done, int total) {
    return 'Экспорт отменен. Выполнено: $done/$total.';
  }

  @override
  String exportProgressSummary(int done, int total, int failed) {
    return 'Экспортировано: $done/$total · Ошибок: $failed';
  }

  @override
  String get btnExporting => 'ЭКСПОРТ…';

  @override
  String get btnExportComplete => 'ЭКСПОРТ ЗАВЕРШЕН ✓';

  @override
  String get btnStartExport => 'НАЧАТЬ ЭКСПОРТ';

  @override
  String exportClipSavedAt(String path) {
    return '✓ Сохранено: $path';
  }

  @override
  String projectTrimmedToClip(int rank, String start, String end) {
    return 'Проект обрезан по вирусному клипу №$rank ($start - $end)!';
  }

  @override
  String shortProjectCreated(String name) {
    return 'Создан проект Shorts 9:16: \"$name\"';
  }

  @override
  String get btnOpen => 'ОТКРЫТЬ';

  @override
  String errorCreateShortProjectFailed(String error) {
    return 'Не удалось создать проект Shorts: $error';
  }

  @override
  String get autoDetect => 'Автоопределение';

  @override
  String presetSaved(String name) {
    return 'Стилевой пресет \"$name\" успешно сохранен!';
  }

  @override
  String get presetDeleted => 'Пресет успешно удален.';

  @override
  String get presetExported => 'Стилевые пресеты успешно экспортированы!';

  @override
  String errorPresetExportFailed(String error) {
    return 'Не удалось экспортировать пресеты: $error';
  }

  @override
  String get presetImported => 'Стилевые пресеты успешно импортированы!';

  @override
  String errorPresetImportFailed(String error) {
    return 'Не удалось импортировать пресеты: $error';
  }

  @override
  String get selectFontFileDialogTitle => 'Выберите файл шрифта TTF или OTF';

  @override
  String get fontWeightThin => 'Тонкий';

  @override
  String get fontWeightExtraLight => 'Сверхсветлый';

  @override
  String get fontWeightLight => 'Светлый';

  @override
  String get fontWeightNormal => 'Обычный';

  @override
  String get fontWeightMedium => 'Средний';

  @override
  String get fontWeightSemiBold => 'Полужирный';

  @override
  String get fontWeightBold => 'Жирный';

  @override
  String get fontWeightExtraBold => 'Сверхжирный';

  @override
  String get fontWeightBlack => 'Черный';

  @override
  String get fontCaseNormal => 'Обычный';

  @override
  String get fontCaseUppercase => 'ПРОПИСНЫЕ';

  @override
  String get fontCaseCapitalize => 'С Заглавной Буквы';

  @override
  String get strokeStyleThickOutline => 'Толстая обводка';

  @override
  String get strokeStyleNoneFlat => 'Без обводки (плоский)';

  @override
  String get shadowStyleSoft => 'Мягкая тень';

  @override
  String get shadowStyleNone => 'Без тени';

  @override
  String get animStyleActivePop => 'Всплывание текущего слова';

  @override
  String get animStyleActiveBounce => 'Отскок активного слова';

  @override
  String get animStyleKineticTilt => 'Кинетический наклон';

  @override
  String get animStyleGlowPulse => 'Пульсирующее свечение';

  @override
  String get animStyleWordReveal => 'Пошаговое появление слов';

  @override
  String get animStyleNoneStatic => 'Без анимации (статичный)';

  @override
  String fontImportedSuccess(String name) {
    return 'Пользовательский шрифт успешно импортирован и применен: \"$name\"';
  }

  @override
  String get errorFontImportFailed =>
      'Не удалось загрузить файл шрифта. Недопустимые данные.';

  @override
  String get invalidTimingError =>
      'Недопустимые тайминги начала/окончания. Начало должно быть >= 0, а окончание >= началу и <= длительности видео.';

  @override
  String get projectSavedSuccess => 'Проект успешно сохранен.';

  @override
  String wordDeletedSuccess(String text) {
    return 'Слово удалено: \"$text\"';
  }

  @override
  String get splitClip => 'Разделить клип';

  @override
  String get removeClip => 'Удалить клип';

  @override
  String get resetToOriginal => 'Вернуть к оригиналу';

  @override
  String splitTimelineAt(String time) {
    return 'Таймлайн разделен на $time с.';
  }

  @override
  String get splitTimelineError =>
      'Курсор воспроизведения должен находиться внутри активной области для разделения.';

  @override
  String get exclusionToggled =>
      'Переключено исключение сегмента под курсором воспроизведения.';

  @override
  String get splitsReset =>
      'Сброшены все разделения и исключения на таймлайне.';

  @override
  String get shareVideo => 'Поделиться видео';

  @override
  String get openOutputFolder => 'Открыть папку с результатом';

  @override
  String get errorLogCopied => 'Журнал ошибок скопирован в буфер обмена.';

  @override
  String get diagnosticsExported =>
      'Отфильтрованный отчет диагностики открыт в меню «Поделиться».';

  @override
  String errorDiagnosticsFailed(String error) {
    return 'Не удалось экспортировать отчет диагностики: $error';
  }

  @override
  String logLineCopied(String message) {
    return 'Строка журнала скопирована в буфер обмена: \"$message\"';
  }

  @override
  String commandCopied(String command) {
    return 'Скопировано: \"$command\"';
  }

  @override
  String get settingsRestored => 'Настройки сброшены до значений по умолчанию.';

  @override
  String get gpuEncoderNoneCpu => 'Нет (CPU)';

  @override
  String get gpuEncoderNvidia => 'NVIDIA NVENC';

  @override
  String get gpuEncoderAmd => 'AMD AMF';

  @override
  String get gpuEncoderIntel => 'Intel QSV';

  @override
  String get gpuEncoderApple => 'Apple VideoToolbox';

  @override
  String get btnDownloadVcRedist => 'СКАЧАТЬ VC++ REDISTRIBUTABLE';

  @override
  String errorDownloadToolFailed(String error) {
    return 'Не удалось скачать утилиту: $error';
  }

  @override
  String get errorFolderNotAccessible =>
      'Выбранная папка не существует или недоступна.';

  @override
  String modelDeleted(String name) {
    return 'Модель удалена: $name';
  }

  @override
  String errorModelDeleteFailed(String error) {
    return 'Не удалось удалить модель: $error';
  }

  @override
  String errorModelDownloadFailed(String name, String error) {
    return 'Не удалось скачать модель $name: $error';
  }

  @override
  String errorOpenFolderFailed(String path) {
    return 'Не удалось открыть папку автоматически. Путь: $path';
  }

  @override
  String errorDownloadPackFailed(String error) {
    return 'Не удалось скачать пакет: $error';
  }

  @override
  String errorPackDownloadNamedFailed(String name, String error) {
    return 'Не удалось скачать пакет $name: $error';
  }

  @override
  String get stickersIndexRefreshed =>
      'Индекс пользовательских стикеров успешно обновлен!';

  @override
  String errorChangeAssetFolderFailed(String error) {
    return 'Не удалось изменить папку ресурсов: $error';
  }

  @override
  String errorSetAssetFolderFailed(String error) {
    return 'Не удалось задать папку ресурсов: $error';
  }

  @override
  String get warningNoAvx =>
      'Обнаружено отсутствие поддержки AVX! Загрузка совместимого whisper-cli (без AVX)...';

  @override
  String get errorAutoDetectWhisper =>
      'Не удалось автоматически найти whisper-cli. Укажите путь вручную.';

  @override
  String get errorAutoDetectFfmpeg =>
      'Не удалось автоматически найти ffmpeg. Укажите путь вручную.';

  @override
  String errorToolDownloadFailed(String error) {
    return 'Не удалось скачать инструмент: $error';
  }

  @override
  String get returnToDashboard => 'Вернуться на панель управления';

  @override
  String errorImportVideoFailed(String error) {
    return 'Ошибка импорта: $error';
  }

  @override
  String get videoRelinkedSuccess => 'Видео успешно перепривязано!';

  @override
  String get errorRelinkVideoFailed => 'Не удалось перепривязать видео.';

  @override
  String get retranscriptionSuccess =>
      'Повторное распознавание успешно завершено!';

  @override
  String get retranscriptionFailed =>
      'Не удалось выполнить повторное распознавание.';
}
