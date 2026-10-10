// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'كاب ستوديو';

  @override
  String get dashboardTitle => 'مشاريعي';

  @override
  String get dashboardSubtitle =>
      'استوديو توليد الترجمة والتعليقات الصوتية الذكي دون اتصال بالإنترنت';

  @override
  String get importVideo => 'استيراد فيديو';

  @override
  String get dragDropText => 'اسحب وأسقط ملف الفيديو الخاص بك هنا';

  @override
  String get clickBrowse => 'أو انقر لتصفح الملفات المحلية';

  @override
  String get demoMode => 'الوضع التجريبي';

  @override
  String get demoModeDesc =>
      'قم بتحميل مشروع تجريبي لتجربة أنماط الخطوط وميزات المحرر.';

  @override
  String get warningAssets => 'مطلوب استرداد مجلد الأصول';

  @override
  String get warningAssetsDesc =>
      'لم يتم العثور على الأصول المدمجة في مجلد دعم التطبيق. انقر نقرًا مزدوجًا هنا لاستعادتها أو لتغيير دليل الأصول.';

  @override
  String get deleteProjectTitle => 'حذف المشروع';

  @override
  String deleteProjectConfirm(String projectName) {
    return 'هل أنت متأكد أنك تريد حذف المشروع \"$projectName\" نهائيًا؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get renameProjectTitle => 'إعادة تسمية المشروع';

  @override
  String get projectNameLabel => 'اسم المشروع';

  @override
  String get btnCancel => 'إلغاء';

  @override
  String get btnDelete => 'حذف';

  @override
  String get btnRename => 'إعادة تسمية';

  @override
  String get btnSave => 'حفظ';

  @override
  String get btnConfirm => 'تأكيد';

  @override
  String get btnExport => 'تصدير';

  @override
  String get btnUndo => 'تراجع';

  @override
  String get btnRedo => 'إعادة';

  @override
  String get statusDraft => 'مسودة';

  @override
  String get statusCompleted => 'مكتمل';

  @override
  String get createdLabel => 'تم إنشاؤه:';

  @override
  String get durationLabel => 'المدة:';

  @override
  String get statusLabel => 'الحالة:';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsGeneral => 'الإعدادات العامة';

  @override
  String get settingsTheme => 'سمة التطبيق';

  @override
  String get themeSystem => 'افتراضي النظام';

  @override
  String get themeLight => 'الوضع المضيء';

  @override
  String get themeDark => 'الوضع المظلم';

  @override
  String get settingsLanguage => 'لغة الواجهة';

  @override
  String get settingsTranscription => 'إعدادات نسخ النصوص والتعرف على الصوت';

  @override
  String get settingsWhisperModel => 'نموذج Whisper';

  @override
  String get settingsWhisperModelDesc =>
      'اختر نموذجًا لنسخ النص. النماذج الأصغر أسرع؛ الأكبر أكثر دقة.';

  @override
  String get settingsTranscribeLang => 'لغة نسخ النص';

  @override
  String get settingsAutoDetect => 'الكشف التلقائي عن اللغة';

  @override
  String get settingsGPU => 'تسريع البطاقة الرسومية (CUDA)';

  @override
  String get settingsVAD => 'عتبة VAD (نشاط الصوت)';

  @override
  String get settingsExport => 'إعدادات التصدير';

  @override
  String get settingsExportDest => 'دليل التصدير الافتراضي';

  @override
  String get settingsBrowse => 'تصفح';

  @override
  String get settingsEmojiPacks => 'حزم الرموز التعبيرية والأنماط';

  @override
  String get settingsEmojiPacksDesc =>
      'تخصيص أنماط رندر الرموز التعبيرية وأصول الترجمة النشطة.';

  @override
  String get settingsEmojiSearchLang => 'لغة البحث عن الرموز التعبيرية';

  @override
  String get settingsBtnManagePacks => 'إدارة حزم الرموز التعبيرية';

  @override
  String get systemTitle => 'معلومات النظام';

  @override
  String get systemVersion => 'الإصدار';

  @override
  String get systemReset => 'إعادة تعيين الافتراضيات';

  @override
  String get editorTabCaptions => 'الترجمات';

  @override
  String get editorTabStyles => 'الأنماط';

  @override
  String get editorTabTrim => 'القص';

  @override
  String get editorTabAudio => 'الصوت';

  @override
  String get editorTabTranscription => 'نسخ الصوت';

  @override
  String get editorTabShortcuts => 'الاختصارات';

  @override
  String get editorTabDebug => 'التصحيح';

  @override
  String get editorHeaderBack => 'رجوع';

  @override
  String get editorKeyboardShortcuts => 'اختصارات لوحة المفاتيح';

  @override
  String get dialogAnalyzing => 'جاري تحليل الفيديو...';

  @override
  String get dialogTranscribing => 'جاري نسخ الصوت...';

  @override
  String get dialogExtracting => 'جاري استخراج الصوت...';

  @override
  String get dialogWait => 'قد يستغرق هذا بعض الوقت. يرجى الانتظار.';

  @override
  String get dialogError => 'خطأ';

  @override
  String get dialogImportFailed => 'فشل استيراد الفيديو.';

  @override
  String get noProjects => 'لم يتم إنشاء أي مشاريع بعد';

  @override
  String get aboutApp => 'حول CapStudio';

  @override
  String get aboutAppDesc =>
      'معلومات عن CapStudio، الاعتمادات، وتراخيص المصدر المفتوح.';

  @override
  String get aboutAppThanks =>
      'شكر خاص لمشاريع المصدر المفتوح التي تجعل CapStudio ممكناً:';

  @override
  String get btnViewAllLicenses => 'عرض جميع تراخيص الحزم';

  @override
  String get exportBurnIn => 'تصدير الفيديو مع حرق الترجمة';

  @override
  String get exportTimecodeFormats => 'تنسيقات الترجمة ذات الأكواد الزمنية';

  @override
  String get exportWebEnabled =>
      'تصدير الفيديو من جهة العميل مفعّل. تتم المعالجة محليًا في متصفحك.';

  @override
  String get exportWebCaptionOnly =>
      'يتضمن تصدير الويب حاليًا الترجمة فقط — لم يتم حرق الرموز التعبيرية والمؤثرات الصوتية في الفيديو بعد. صدّر من تطبيق سطح المكتب أو الجوال للحصول على النتيجة الكاملة.';

  @override
  String get exportOutputName => 'اسم فيديو الإخراج';

  @override
  String get exportMode => 'وضع التصدير';

  @override
  String get exportModeFast => 'سريع (FFmpeg مدمج)';

  @override
  String get exportModeFastUnsupported => 'سريع (FFmpeg مدمج) ⚠️ غير مدعوم';

  @override
  String get exportModeSlow => 'بطيء (معالجة المعاينة 1:1)';

  @override
  String get exportTargetFps => 'معدل الإطارات المستهدف';

  @override
  String get exportFps24 => '24 إطارًا/ث (سينما)';

  @override
  String get exportFps25 => '25 إطارًا/ث (PAL)';

  @override
  String get exportFps30 => '30 إطارًا/ث (قياسي)';

  @override
  String get exportFps50 => '50 إطارًا/ث';

  @override
  String get exportFps60 => '60 إطارًا/ث (سلس)';

  @override
  String get exportFastUnsupported =>
      'الوضع السريع غير مدعوم على هذا الجهاز لأن إصدار FFmpeg النظامي يفتقر إلى مرشحات عرض الترجمة (libass). سيتم استخدام الوضع البطيء بدلاً منه.';

  @override
  String get exportSlowInfo =>
      'يلتقط كل إطار تمامًا كما يظهر في المعاينة. وهذا يضمن ترجمة دقيقة بكسلًا بكسل، لكن المعالجة تكون أبطأ.';

  @override
  String get exportDestDirectory => 'مجلد الوجهة';

  @override
  String get exportDestBrowser => 'موقع تنزيل المتصفح';

  @override
  String get exportDestAndroid =>
      'مجلد التنزيلات (/storage/emulated/0/Download)';

  @override
  String get exportDestIos => 'مستندات التطبيق (ورقة المشاركة بعد التصدير)';

  @override
  String get exportChooseFolder => 'اختر مجلد الإخراج';

  @override
  String get exportStartMp4 => 'بدء تصدير MP4';

  @override
  String get exportSrtTitle => 'ترجمة SubRip (.srt)';

  @override
  String get exportSrtDesc =>
      'معيار عالمي بأكواد زمنية. متوافق مع YouTube وVLC وPremiere Pro.';

  @override
  String get exportVttTitle => 'ترجمة WebVTT (.vtt)';

  @override
  String get exportVttDesc =>
      'تنسيق ترجمة محسّن للويب، يُستخدم على نطاق واسع في مشغلات HTML5 والبث عبر الإنترنت.';

  @override
  String get exportAssTitle => 'Advanced SubStation Alpha (.ass)';

  @override
  String get exportAssDesc =>
      'تنسيق احترافي يدعم أحجام الخطوط والأنماط والهوامش والتمييز المضمن.';

  @override
  String get exportTxtTitle => 'نسخة نصية (.txt)';

  @override
  String get exportTxtDesc => 'نسخة سطرًا بسطر مع بادئات الطوابع الزمنية.';

  @override
  String exportSuccess(String type) {
    return 'تم تصدير $type بنجاح!';
  }

  @override
  String get exportNoLocation =>
      'لم يتم تحديد موقع للحفظ. يرجى اختيار مسار ملف.';

  @override
  String get exportNoLocationCancelled =>
      'لم يتم تحديد موقع للحفظ. تم إلغاء التصدير.';

  @override
  String exportFailed(String error) {
    return 'فشل التصدير: $error';
  }

  @override
  String get exportCopySrtTooltip => 'نسخ SRT إلى الحافظة';

  @override
  String get exportCopiedSrt => 'تم نسخ SRT إلى الحافظة!';

  @override
  String exportCopyFailedSrt(String error) {
    return 'فشل نسخ SRT: $error';
  }

  @override
  String exportSubtitlesDialogTitle(String type) {
    return 'تصدير ترجمة $type';
  }

  @override
  String get exportVideoDialogTitle => 'تصدير فيديو MP4';

  @override
  String get ffmpegRequiredTitle => 'FFmpeg مطلوب';

  @override
  String get ffmpegRequiredBody =>
      'يلزم تثبيت محلي لـ FFmpeg لحرق الترجمة داخل ملف الفيديو.\n\nيرجى ضبط مسار FFmpeg في الإعدادات.';

  @override
  String get okLabel => 'موافق';

  @override
  String get exportWebTitle => 'جارٍ تصدير الفيديو (من جهة العميل)';

  @override
  String exportWebSuccess(String fileName) {
    return 'تم تصدير الفيديو بنجاح باسم $fileName!';
  }

  @override
  String exportWebFailed(String error) {
    return 'فشلت المعالجة: $error';
  }

  @override
  String get viralShortsTitle => 'استوديو المقاطع القصيرة الفيروسية';

  @override
  String get viralShortsSubtitle =>
      'إعادة تأطير عمودي 9:16، قص الصمت واكتشاف الخطافات بالذكاء الاصطناعي';

  @override
  String get viralReframeTitle => '1. إعادة تأطير عمودية 9:16';

  @override
  String get viralSilenceTitle => '2. إزالة فترات الصمت (قفزات المونتاج)';

  @override
  String get viralHooksTitle => '3. كاشف الخطافات الفيروسية بالذكاء الاصطناعي';

  @override
  String get btnFindViralMoments => 'البحث عن اللحظات الفيروسية';

  @override
  String get btnScanSilences => 'فحص فترات الصمت';

  @override
  String get btnApplyJumpCuts => 'تطبيق قفزات المونتاج';

  @override
  String get editorTabShorts => 'شورتس';

  @override
  String get editorTabClips => 'مقاطع';

  @override
  String get captionList => 'قائمة الترجمة';

  @override
  String get uncertainLabel => 'غير مؤكد (<40%)';

  @override
  String get mediumConfidenceLabel => 'متوسط (40-60%)';

  @override
  String get jumpToUncertain => 'الانتقال إلى الكلمة غير المؤكدة التالية';

  @override
  String get noUncertainWords => 'لم يتم العثور على كلمات غير مؤكدة.';

  @override
  String get findAndReplace => 'بحث واستبدال';

  @override
  String get addWordTitle => 'إضافة كلمة';

  @override
  String get editWordTitle => 'تعديل الكلمة';

  @override
  String get wordTextLabel => 'نص الكلمة';

  @override
  String get startTimeLabel => 'وقت البدء (ث)';

  @override
  String get endTimeLabel => 'وقت الانتهاء (ث)';

  @override
  String get splitChunk => 'تقسيم المقطع';

  @override
  String get insertLineAfter => 'إدراج سطر بعد';

  @override
  String get duplicateLine => 'تكرار السطر';

  @override
  String get deleteLine => 'حذف السطر';

  @override
  String get chooseSfxTitle => 'اختر مؤثرًا صوتيًا';

  @override
  String get searchSfxPlaceholder => 'البحث عن المؤثرات الصوتية...';

  @override
  String get noSfxFound => 'لم يتم العثور على مؤثرات صوتية';

  @override
  String get emojiSearch => 'البحث عن الرموز التعبيرية';

  @override
  String get noEmojisFound => 'لم يتم العثور على رموز تعبيرية.';

  @override
  String get mySavedPresets => 'إعداداتي المسبقة المحفوظة';

  @override
  String get btnImport => 'استيراد';

  @override
  String get btnExportCaps => 'تصدير';

  @override
  String get btnSaveCurrent => 'حفظ الحالي';

  @override
  String get resetToDefault => 'إعادة التعيين إلى الافتراضي';

  @override
  String get resetConfirmBody =>
      'سيؤدي هذا إلى إعادة تعيين جميع أنماط الترجمة إلى الوضع الافتراضي. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get btnReset => 'إعادة تعيين';

  @override
  String get wordHighlightBox => 'مربع تمييز الكلمة';

  @override
  String get wordHighlightBoxDesc =>
      'خلفية كبسولة ملونة خلف الكلمات المنطوقة النشطة';

  @override
  String get maxWordsPerChunk => 'الحد الأقصى للكلمات لكل مقطع ترجمة';

  @override
  String get maxCharsPerLine => 'الحد الأقصى للأحرف لكل سطر ترجمة';

  @override
  String get fontSettings => 'إعدادات الخط';

  @override
  String get colorSettings => 'إعدادات الألوان';

  @override
  String get borderSettings => 'إعدادات الحدود والظل';

  @override
  String get speechToTextTitle => 'تحويل الكلام إلى نص';

  @override
  String get speechToTextDesc =>
      'إعادة تشغيل تحويل الكلام إلى نص محليًا. سيتم استبدال أي تعديلات يدوية أو إزاحات زمنية.';

  @override
  String get useLocalAi => 'استخدام النسخ الصوتي بالذكاء الاصطناعي محليًا';

  @override
  String get runOnDeviceDesc =>
      'تشغيل تحويل الكلام إلى نص مباشرة على هذا الجهاز';

  @override
  String get offlineDemoModeActive =>
      'الوضع التجريبي غير المتصل بالإنترنت نشط. تحويل الصوت Whisper AI محليًا غير مدعوم على الويب.';

  @override
  String get demoModeNote =>
      'يولد الوضع التجريبي على الفور رموز نصوص واقعية للغاية. مثالي لاختبار الأنماط والقوالب وعمليات المخطط الزمني دون إعداد مسبق.';

  @override
  String get transcriptionQuality => 'جودة نسخ النص';

  @override
  String get advancedSettings => 'إعدادات متقدمة';

  @override
  String get cpuThreadsLabel => 'خيوط المعالج (CPU)';

  @override
  String get vadSensitivity => 'حساسية كشف نشاط الصوت (VAD)';

  @override
  String get translateToEnglish => 'ترجمة النصوص إلى الإنجليزية';

  @override
  String get startTranscriptionBtn => 'بدء نسخ النص';

  @override
  String get hardwareLocked => 'العتاد مقفل';

  @override
  String get btnDownload => 'تنزيل';

  @override
  String get welcomeTitle => 'مرحبًا بك في كاب ستوديو';

  @override
  String get welcomeSubtitle =>
      'ترجمات عالية الدقة ومقاطع قصيرة فيروسية، 100% دون اتصال بالإنترنت.';

  @override
  String get setupAssetDirTitle => 'اختر دليل الأصول';

  @override
  String get setupAssetDirDesc =>
      'حدد مجلدًا لتخزين النماذج والخطوط وحزم الرموز التعبيرية.';

  @override
  String get downloadPacksTitle => 'تنزيل حزم المحتوى (اختياري)';

  @override
  String get downloadPacksDesc =>
      'خطوط ومؤثرات صوتية اختيارية لمشاريع الفيديو الخاصة بك.';

  @override
  String get setupCompleteTitle => 'اكتمل الإعداد';

  @override
  String get setupCompleteDesc =>
      'أنت جاهز لإنشاء مقاطع فيديو مذهلة مع الترجمات.';

  @override
  String get btnGetStarted => 'ابدأ الآن';

  @override
  String get btnNext => 'التالي';

  @override
  String get btnSkip => 'تخطي';

  @override
  String get onboardingFeaturePrivacy => 'خصوصية 100%';

  @override
  String get onboardingFeaturePrivacyDesc =>
      'ملفاتك لا تغادر جهازك أبدًا. تعمل جميع نماذج الذكاء الاصطناعي محليًا.';

  @override
  String get onboardingFeatureGpu =>
      'تشغيل مسرّع بواسطة وحدة معالجة الرسوميات (GPU)';

  @override
  String get onboardingFeatureGpuDesc =>
      'تحرير فيديو عالي الأداء باستخدام فك تشفير العتاد.';

  @override
  String get onboardingFeatureAssets => 'أصول جانبية دون اتصال بالإنترنت';

  @override
  String get onboardingFeatureAssetsDesc =>
      'قم بتنزيل حزم الرموز التعبيرية الغنية مرة واحدة واعمل بالكامل دون اتصال بالإنترنت.';

  @override
  String get onboardingReadyTitle => 'أنت جاهز للانطلاق!';

  @override
  String get onboardingConfigDetails => 'تفاصيل التكوين:';

  @override
  String get btnLaunchCapStudio => 'تشغيل كاب ستوديو';

  @override
  String get assetVerificationFailed =>
      'فشل التحقق من الأصول. يرجى التأكد من تنزيل الأصول بشكل صحيح.';

  @override
  String get assetsFolderNotFound => 'لم يتم العثور على مجلد الأصول';

  @override
  String get assetsFolderNotFoundDesc =>
      'تعذر على كاب ستوديو تحديد موقع مجلد الأصول في المسار الذي تم تكوينه. إذا كان المجلد على محرك أقراص خارجي، يرجى توصيله.';

  @override
  String get expectedPathLabel => 'المسار المتوقع:';

  @override
  String get browseNewLocation => 'تصفح موقع جديد';

  @override
  String get resetToDefaultPath => 'إعادة التعيين إلى المسار الافتراضي';

  @override
  String get retryVerification => 'إعادة محاولة التحقق';

  @override
  String get storagePathFolder => 'مجلد مسار التخزين';

  @override
  String get tipWindowsDrive =>
      'تلميح: إذا كانت مساحة القرص C: صغيرة، اختر مسارًا على D: أو E: لتوفير مساحة إضافية.';

  @override
  String get tipGeneralDrive =>
      'تلميح: يمكنك تحديد مسار محرك أقراص خارجي إذا كانت وحدة التخزين الرئيسية ممتلئة.';

  @override
  String get confirmLocation => 'تأكيد الموقع';

  @override
  String get requiredBadge => 'مطلوب';

  @override
  String get emojiPacksHeader => 'حزم الرموز التعبيرية';

  @override
  String get fontPacksHeader => 'حزم الخطوط';

  @override
  String get connectCliTitle => 'ربط أدوات سطر الأوامر المحلية (CLI)';

  @override
  String get connectCliDesc =>
      'يحتاج كاب ستوديو إلى ملفات whisper.cpp و FFmpeg الثنائية لإجراء النسخ الصوتي وتصدير مقاطع الفيديو محليًا.';

  @override
  String get skipSetup => 'تخطي الإعداد الآن';

  @override
  String get btnValidate => 'التحقق';

  @override
  String get autoDetectAndValidate => 'الكشف التلقائي والتحقق';

  @override
  String get whisperCliPathLabel => 'مسار ملف Whisper CLI التنفيذي';

  @override
  String get ffmpegCliPathLabel => 'مسار ملف FFmpeg CLI التنفيذي';

  @override
  String get newProject => 'مشروع جديد';

  @override
  String get searchProjects => 'البحث في المشاريع...';

  @override
  String get filterAll => 'الكل';

  @override
  String get sortByRecent => 'الأحدث';

  @override
  String get sortByDuration => 'المدة';

  @override
  String get noMatchingProjects => 'لا توجد مشاريع تطابق بحثك';

  @override
  String get btnEdit => 'تعديل';

  @override
  String get btnDuplicate => 'تكرار';

  @override
  String get tooltipEdit => 'تعديل';

  @override
  String get tooltipRename => 'إعادة تسمية';

  @override
  String get tooltipDuplicate => 'تكرار';

  @override
  String get tooltipDelete => 'حذف';

  @override
  String get tooltipTheme => 'السمة';

  @override
  String get tooltipSettings => 'الإعدادات';

  @override
  String get selectDemoFormat => 'اختر تنسيق العرض التجريبي';

  @override
  String get selectDemoDesc =>
      'حدد تنسيق تخطيط لمعاينة محرك ترجمة كاب ستوديو عالي الدقة، وحركات مستوى الكلمات الحية، والموجات الصوتية على الفور.';

  @override
  String get landscapeDemo => 'عرض تجريبي أفقي';

  @override
  String get landscapeDemoDesc =>
      'مثالي لـ YouTube وأجهزة الكمبيوتر والعروض التقديمية.';

  @override
  String get portraitDemo => 'عرض تجريبي طولي';

  @override
  String get portraitDemoDesc =>
      'مثالي لـ TikTok و Shorts و Reels والهواتف المحمولة.';

  @override
  String get format16x9 => 'تنسيق 16:9';

  @override
  String get format9x16 => 'تنسيق 9:16';

  @override
  String get dropVideoHere => 'أفلت الفيديو هنا';

  @override
  String get dropVideoSupported => 'يدعم MP4 و MOV و AVI وغيرها';

  @override
  String get statusLocalOffline => 'محلي دون اتصال';

  @override
  String get speechModelTitle => 'نموذج التعرف على الصوت';

  @override
  String get hardwareUpgradesTitle => 'ترقيات أداء العتاد';

  @override
  String get showAdvancedPaths => 'إظهار تكوين المسار المتقدم';

  @override
  String get hideAdvancedPaths => 'إخفاء تكوين المسار المتقدم';

  @override
  String get autoDownload => 'تنزيل تلقائي';

  @override
  String get gpuAcceleratedTranscription =>
      'نسخ مسرّع ببطاقة الرسوميات GPU (CUDA)';

  @override
  String get gpuRequiresNvidia => 'يتطلب بطاقة رسوميات NVIDIA تدعم CUDA';

  @override
  String get gpuExportEncoder => 'مشفر التصدير عبر بطاقة الرسوميات (GPU)';

  @override
  String get gpuExportEncoderDesc => 'تسريع عتادي لتصدير فيديو MP4';

  @override
  String get defaultLanguage => 'اللغة الافتراضية';

  @override
  String get vadTitle => 'كشف نشاط الصوت (VAD)';

  @override
  String get vadDesc => 'يتخطى المناطق الصامتة أثناء المعالجة';

  @override
  String get vadThreshold => 'عتبة VAD';

  @override
  String get autoSaveTitle => 'الحفظ التلقائي';

  @override
  String get autoSaveDesc =>
      'حفظ تعديلات المشروع تلقائيًا في قاعدة البيانات كل 3 ثوانٍ';

  @override
  String get defaultOutputsTitle => 'المخرجات الافتراضية';

  @override
  String get defaultExportFolder => 'مجلد التصدير الافتراضي';

  @override
  String get alwaysAskExportPath => 'السؤال دائمًا عن مسار التصدير';

  @override
  String get alwaysAskExportPathDesc =>
      'يطلب مسار الإخراج عند كل عملية تصدير (سطح المكتب)';

  @override
  String get performanceTitle => 'الأداء';

  @override
  String get exportCpuThreads => 'خيوط المعالج للتصدير';

  @override
  String get exportCpuThreadsDesc =>
      'خيوط المعالج المستخدمة للرندر (تتدرج تلقائيًا بأمان حسب الجهاز)';

  @override
  String get aboutAppSubtitle =>
      'استوديو ترجمة وتسميات توضيحية بالذكاء الاصطناعي 100% دون اتصال بالإنترنت وموجّه للخصوصية أولاً';

  @override
  String get openSourceLicenses => 'تراخيص المصدر المفتوح';

  @override
  String get openSourceComplianceDesc =>
      'يعتمد كاب ستوديو على العديد من مكتبات المصدر المفتوح الأخرى. تم تجميع سجل كامل لجميع حزم Dart والتبعيات غير المباشرة ونصوص التراخيص الكاملة أدناه للامتثال القانوني للمتجر.';

  @override
  String get visitWebsite => 'زيارة الموقع الإلكتروني';

  @override
  String get btnContinue => 'متابعة';

  @override
  String get btnBack => 'رجوع';

  @override
  String get editTiming => 'تعديل التوقيت';

  @override
  String get wordSettingsTitle => 'إعدادات الكلمة';

  @override
  String get emojiSettingsTitle => 'إعدادات الرموز التعبيرية';

  @override
  String get changeEmojiTooltip => 'تغيير الرمز التعبيري';

  @override
  String get searchEmojisHint => 'البحث عن الرموز التعبيرية...';

  @override
  String emojiPosX(String offset) {
    return 'موضع الرمز التعبيري (إزاحة X: $offset بكسل)';
  }

  @override
  String emojiPosY(String offset) {
    return 'موضع الرمز التعبيري (إزاحة Y: $offset بكسل)';
  }

  @override
  String emojiScale(String scale) {
    return 'حجم الرمز التعبيري (${scale}x)';
  }

  @override
  String emojiAnimSpeed(String speed) {
    return 'سرعة الحركة (${speed}x)';
  }

  @override
  String get emojiStylePack => 'نمط / حزمة الرموز التعبيرية';

  @override
  String get selectStylePackTooltip => 'اختر حزمة النمط';

  @override
  String get selectEmojiTitle => 'اختر رمزًا تعبيريًا';

  @override
  String get stylePackLabel => 'حزمة النمط';

  @override
  String get searchHint => 'بحث...';

  @override
  String get btnCreateProject => 'إنشاء مشروع';

  @override
  String get btnChooseFile => 'اختيار ملف';

  @override
  String get selectSubtitleFile => 'حدد ملف الترجمة';

  @override
  String get selectTranscriptionQuality => 'حدد جودة نسخ النص';

  @override
  String get translateToEnglishDesc =>
      'تحويل الكلام باللغات الأجنبية مباشرة إلى ترجمة بالإنجليزية';

  @override
  String get hardwareSettings => 'إعدادات العتاد والأداء';

  @override
  String get styleTemplatesHeader => 'قوالب الأنماط';

  @override
  String get resetToDefaultStyle => 'إعادة التعيين إلى النمط الافتراضي';

  @override
  String get resetStylingTitle => 'إعادة تعيين الأنماط؟';

  @override
  String get resetStylingDesc =>
      'سيؤدي هذا إلى إعادة تعيين جميع أنماط الترجمة إلى الوضع الافتراضي. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get sizeAndPosition => 'الحجم والموضع';

  @override
  String get verticalYPos => 'الموضع الرأسي Y (%)';

  @override
  String get fontConfigHeader => 'تكوين الخط';

  @override
  String get fontFamilyLabel => 'عائلة الخط';

  @override
  String get btnImportCustomFont => 'استيراد خط مخصص (.ttf / .otf)';

  @override
  String get fontWeightLabel => 'وزن الخط';

  @override
  String get textCaseLabel => 'حالة الأحرف';

  @override
  String get fontSizeLabel => 'حجم الخط';

  @override
  String get letterSpacingLabel => 'تباعد الأحرف';

  @override
  String get lineHeightLabel => 'ارتفاع السطر';

  @override
  String get onboardingAppTagline =>
      'محرر ترجمة بالذكاء الاصطناعي محلي 100% دون اتصال بالإنترنت';

  @override
  String get configLabelWhisperCli => 'Whisper CLI';

  @override
  String get configValueDemoMode => 'الوضع التجريبي (محاكاة)';

  @override
  String get configLabelFfmpegCli => 'FFmpeg CLI';

  @override
  String get configValueSystemPathDefault => 'المسار الافتراضي للنظام (PATH)';

  @override
  String get configLabelAssetsLocation => 'موقع الأصول';

  @override
  String get filePickerAssetsDialogTitle => 'حدد مجلد أصول كاب ستوديو';

  @override
  String errorSelectFolderFailed(String error) {
    return 'فشل تحديد المجلد: $error';
  }

  @override
  String errorResetFailed(String error) {
    return 'فشلت إعادة التعيين: $error';
  }

  @override
  String errorVerificationFailed(String error) {
    return 'فشل التحقق: $error';
  }

  @override
  String errorAssetsFolderStillMissing(String path) {
    return 'لا يزال مجلد الأصول غير موجود في: $path';
  }

  @override
  String get dbRecoveredTitle => 'تم استرداد قاعدة البيانات تلقائيًا';

  @override
  String dbRecoveredBody(String backupPath) {
    return 'تم اكتشاف عدم تطابق في بنية قاعدة البيانات أو تلفها. تمت إعادة تعيين قاعدة البيانات، ونُسخت بياناتك السابقة احتياطيًا إلى:\n\n$backupPath';
  }

  @override
  String errorDemoLoadFailed(String error) {
    return 'فشل تحميل الفيديو التجريبي: $error';
  }

  @override
  String importProgressPercent(int percent) {
    return 'اكتمل $percent%';
  }

  @override
  String get errorInvalidDropFileFormat =>
      'تنسيق ملف غير صالح. يرجى إفلات ملف فيديو.';

  @override
  String get findTextLabel => 'البحث عن نص';

  @override
  String get replaceWithLabel => 'استبدال بـ';

  @override
  String findReplaceSuccessCount(int count) {
    return 'تم استبدال $count تكرارًا!';
  }

  @override
  String get btnReplaceAll => 'استبدال الكل';

  @override
  String errorVideoFileNotFound(String path) {
    return 'لم يتم العثور على ملف الفيديو:\n$path\nيرجى إعادة ربط ملف الفيديو.';
  }

  @override
  String get errorTranscriptionFailed =>
      'فشل نسخ النص. يرجى المحاولة مرة أخرى.';

  @override
  String transcriptionActiveModel(String quality, String model) {
    return 'نشط: $quality ($model)';
  }

  @override
  String get badgeRecommended => 'موصى به';

  @override
  String get languageLabel => 'اللغة';

  @override
  String warningEnglishOnlyModel(String model, String language) {
    return 'تحذير: النموذج المحدد ($model) يدعم الإنجليزية فقط. سيؤدي النسخ باللغة \"$language\" إلى الفشل أو إنشاء ترجمات باللغة الإنجليزية. يرجى تحديد نموذج متعدد اللغات (مثل Tiny أو Base).';
  }

  @override
  String get tipAutoDetectMixedLanguage =>
      'تلميح: لا يُنصح بالكشف التلقائي للغات المختلطة (مثل الهينجليش). سيوفر التحديد الصريح للغتك المنطوقة (مثل الهندية أو الإنجليزية) ترجمات أكثر دقة بكثير.';

  @override
  String get detectedHardwareLabel => 'عتاد النظام المكتشف:';

  @override
  String hardwareRamSize(String ramGB) {
    return 'حجم ذاكرة الرام: $ramGB جيجابايت';
  }

  @override
  String hardwareCpuCores(int cores) {
    return 'أنوية المعالج المنطقية: $cores';
  }

  @override
  String hardwareGpuDevice(String gpu) {
    return 'جهاز وحدة معالجة الرسوميات (GPU): $gpu';
  }

  @override
  String get hardwareDetecting => 'جارٍ فحص إحصائيات العتاد...';

  @override
  String get btnStartReTranscribe => 'بدء إعادة نسخ النص';

  @override
  String get btnImportSrtVtt => 'استيراد ملف SRT/VTT';

  @override
  String importedSubtitleWords(int count) {
    return 'تم استيراد $count كلمة من ملف الترجمة.';
  }

  @override
  String get errorImportSubtitleFailed =>
      'فشل استيراد ملف الترجمة. يرجى التحقق من تنسيق الملف.';

  @override
  String get noProjectLoaded => 'لم يتم تحميل أي مشروع';

  @override
  String get badge916Vertical => 'عمودي 9:16';

  @override
  String get badge169Landscape => 'أفقي 16:9';

  @override
  String get reframeTargetCanvas =>
      'لوحة العمل المستهدفة: 1080 × 1920 (TikTok و YouTube Shorts و Instagram Reels)';

  @override
  String get reframeModeLabel => 'وضع إعادة التأطير:';

  @override
  String get reframeModeBlurPillarbox => 'أعمدة جانبية ضبابية (موصى به)';

  @override
  String get reframeModeBlurPillarboxDesc =>
      'يوسع الفيديو ويجعله ضبابيًا في الخلفية لملء 9:16، مع الحفاظ على وضوح الفيديو المركزي.';

  @override
  String get reframeModeCenterCrop => 'قص ذكي من المنتصف';

  @override
  String get reframeModeCenterCropDesc =>
      'يملأ شاشة 9:16 بالكامل عن طريق قص الحواف اليسرى واليمنى.';

  @override
  String get reframeModeSplitScreen => 'شاشة مقسمة / طبقة مزدوجة';

  @override
  String get reframeModeSplitScreenDesc =>
      'يرتب نافذتي فيديو عموديًا (مثالي لردود الفعل وحوارات البودكاست).';

  @override
  String get btnResetTo169 => 'حاليًا 9:16 (إعادة التعيين إلى 16:9)';

  @override
  String get btnSetCanvas916 => 'ضبط لوحة عمل المشروع على 9:16';

  @override
  String get silenceRemovalDesc =>
      'يقطع تلقائيًا فترات التوقف الميتة وفجوات التنفس لزيادة تفاعل واحتفاظ المشاهدين بالفيديو.';

  @override
  String get silenceAggressivenessLabel => 'شدة القص:';

  @override
  String silenceNoiseGateLabel(int db) {
    return 'بوابة كتم الضوضاء الصامتة: $db ديسيبل';
  }

  @override
  String silenceMinPauseLabel(String duration) {
    return 'أدنى توقف: $duration ث';
  }

  @override
  String get btnScanning => 'جارٍ الفحص...';

  @override
  String silenceNoneFound(String duration) {
    return 'لم يتم العثور على فجوات صمت تتجاوز $duration ثانية.';
  }

  @override
  String silenceFoundCount(int count, String totalSecs) {
    return 'تم العثور على $count فترة صمت (تم توفير $totalSecs ثانية من الوقت الميت)!';
  }

  @override
  String errorScanningAudio(String error) {
    return 'خطأ أثناء فحص الصوت: $error';
  }

  @override
  String jumpCutsApplied(int count) {
    return 'تم تطبيق $count قفزة مونتاج على المخطط الزمني للمشروع!';
  }

  @override
  String get viralHooksDesc =>
      'يفحص كلمات النص المنسوخ لأكثر من 80 خطافًا فيروسيًا، والسرعة (120–170 ك/د)، والأسئلة، وكثافة الطاقة، وحدود المقاطع.';

  @override
  String get btnAnalyzingTranscript => 'جارٍ تحليل النص...';

  @override
  String get selectAllLabel => 'تحديد الكل';

  @override
  String selectedCountOf(int selected, int total) {
    return 'تم تحديد $selected من أصل $total';
  }

  @override
  String get btnSelectClipsToBatchExport => 'حدد المقاطع للتصدير المجمع';

  @override
  String btnBatchExportCount(int count) {
    return 'تصدير مجمع لـ $count مقطع';
  }

  @override
  String get viralNoClipsDetected =>
      'لم يتم اكتشاف مقاطع فيروسية عالية التقييم في نطاق مدة هذا الفيديو.';

  @override
  String get badgeCleanCut => 'قص نظيف';

  @override
  String get badgeFirst5s => 'أول 5 ثوانٍ';

  @override
  String get btnPreview => 'معاينة';

  @override
  String get btnTrim => 'قص';

  @override
  String get tooltipForkAs916 => 'تفريغ كمشروع قصير جديد 9:16';

  @override
  String wpmLabelOk(int wpm) {
    return '$wpm ك/د ✓';
  }

  @override
  String wpmLabelFast(int wpm) {
    return '$wpm ك/د سريع';
  }

  @override
  String wpmLabelSlow(int wpm) {
    return '$wpm ك/د بطيء';
  }

  @override
  String hookScoreLabel(int score) {
    return 'الخطاف $score/40';
  }

  @override
  String energyScoreLabel(int score) {
    return 'الطاقة $score/20';
  }

  @override
  String get filePickerClipsFolderTitle => 'اختر مجلدًا لحفظ المقاطع';

  @override
  String get errorChooseOutputFolderFirst => 'يرجى اختيار مجلد الإخراج أولاً.';

  @override
  String batchExportSheetTitle(int count) {
    return 'تصدير مجمع لـ $count مقطع';
  }

  @override
  String get tapToChooseOutputFolder => 'انقر لاختيار مجلد الإخراج…';

  @override
  String get burnCaptionsOnClipsLabel => 'حرق ترجمات حركية على المقاطع';

  @override
  String get burnCaptionsOnClipsDesc =>
      'حرق ترجمات متحركة منسقة ومتزامنة مع صوت المقطع';

  @override
  String exportCancelledProgress(int done, int total) {
    return 'تم إلغاء التصدير. اكتمل $done/$total.';
  }

  @override
  String exportProgressSummary(int done, int total, int failed) {
    return 'تم تصدير $done/$total · فشل $failed';
  }

  @override
  String get btnExporting => 'جارٍ التصدير…';

  @override
  String get btnExportComplete => 'اكتمل التصدير ✓';

  @override
  String get btnStartExport => 'بدء التصدير';

  @override
  String exportClipSavedAt(String path) {
    return '✓ تم الحفظ: $path';
  }

  @override
  String projectTrimmedToClip(int rank, String start, String end) {
    return 'تم قص المشروع إلى المقطع الفيروسي #$rank ($start - $end)!';
  }

  @override
  String shortProjectCreated(String name) {
    return 'تم إنشاء شورت 9:16: \"$name\"';
  }

  @override
  String get btnOpen => 'فتح';

  @override
  String errorCreateShortProjectFailed(String error) {
    return 'فشل إنشاء مشروع الشورت: $error';
  }

  @override
  String get autoDetect => 'كشف تلقائي';

  @override
  String presetSaved(String name) {
    return 'تم حفظ النمط المسبق \"$name\" بنجاح!';
  }

  @override
  String get presetDeleted => 'تم حذف الإعداد المسبق بنجاح.';

  @override
  String get presetExported => 'تم تصدير الإعدادات المسبقة للأنماط بنجاح!';

  @override
  String errorPresetExportFailed(String error) {
    return 'فشل تصدير الإعدادات المسبقة: $error';
  }

  @override
  String get presetImported => 'تم استيراد الإعدادات المسبقة للأنماط بنجاح!';

  @override
  String errorPresetImportFailed(String error) {
    return 'فشل استيراد الإعدادات المسبقة: $error';
  }

  @override
  String get selectFontFileDialogTitle => 'حدد ملف خط TTF أو OTF';

  @override
  String get fontWeightThin => 'رفيع';

  @override
  String get fontWeightExtraLight => 'رفيع للغاية';

  @override
  String get fontWeightLight => 'خفيف';

  @override
  String get fontWeightNormal => 'عادي';

  @override
  String get fontWeightMedium => 'متوسط';

  @override
  String get fontWeightSemiBold => 'شبه عريض';

  @override
  String get fontWeightBold => 'عريض';

  @override
  String get fontWeightExtraBold => 'عريض للغاية';

  @override
  String get fontWeightBlack => 'داكن (Black)';

  @override
  String get fontCaseNormal => 'عادي';

  @override
  String get fontCaseUppercase => 'أحرف كبيرة';

  @override
  String get fontCaseCapitalize => 'بداية أحرف كبيرة';

  @override
  String get strokeStyleThickOutline => 'إطار سميك';

  @override
  String get strokeStyleNoneFlat => 'بدون (مسطح)';

  @override
  String get shadowStyleSoft => 'ظل خفيف';

  @override
  String get shadowStyleNone => 'بدون';

  @override
  String get animStyleActivePop => 'بروز نشط (Active Pop)';

  @override
  String get animStyleActiveBounce => 'قفزة ارتدادية نشطة';

  @override
  String get animStyleKineticTilt => 'إمالة حركية ارتدادية';

  @override
  String get animStyleGlowPulse => 'نبض توهج نشط';

  @override
  String get animStyleWordReveal => 'كشف متتابع للكلمات';

  @override
  String get animStyleNoneStatic => 'بدون (ثابت)';

  @override
  String fontImportedSuccess(String name) {
    return 'تم استيراد الخط المخصص وتطبيقه بنجاح: \"$name\"';
  }

  @override
  String get errorFontImportFailed => 'فشل تحميل ملف الخط. بيانات غير صالحة.';

  @override
  String get invalidTimingError =>
      'توقيت البدء/الانتهاء غير صالح. يجب أن يكون البدء >= 0، ويجب أن يكون الانتهاء >= البدء و <= مدة الفيديو.';

  @override
  String get projectSavedSuccess => 'تم حفظ المشروع بنجاح.';

  @override
  String wordDeletedSuccess(String text) {
    return 'تم حذف الكلمة: \"$text\"';
  }

  @override
  String get splitClip => 'تقسيم المقطع';

  @override
  String get removeClip => 'إزالة المقطع';

  @override
  String get resetToOriginal => 'إعادة التعيين إلى الأصل';

  @override
  String splitTimelineAt(String time) {
    return 'تقسيم المخطط الزمني عند $time ث.';
  }

  @override
  String get splitTimelineError =>
      'يجب أن يكون مؤشر التشغيل داخل المنطقة النشطة للتقسيم.';

  @override
  String get exclusionToggled => 'تم تبديل استبعاد المقطع تحت مؤشر التشغيل.';

  @override
  String get splitsReset =>
      'إعادة تعيين جميع تقسيمات واستبعادات المخطط الزمني.';

  @override
  String get shareVideo => 'مشاركة الفيديو';

  @override
  String get openOutputFolder => 'فتح مجلد المخرجات';

  @override
  String get errorLogCopied => 'تم نسخ سجل الأخطاء إلى الحافظة.';

  @override
  String get diagnosticsExported =>
      'تم فتح تقرير التشخيص المصفى في ورقة المشاركة.';

  @override
  String errorDiagnosticsFailed(String error) {
    return 'فشل تصدير تقرير التشخيص: $error';
  }

  @override
  String logLineCopied(String message) {
    return 'تم نسخ سطر السجل إلى الحافظة: \"$message\"';
  }

  @override
  String commandCopied(String command) {
    return 'تم النسخ: \"$command\"';
  }

  @override
  String get settingsRestored => 'تمت استعادة الإعدادات الافتراضية.';

  @override
  String get gpuEncoderNoneCpu => 'بدون (المعالج CPU)';

  @override
  String get gpuEncoderNvidia => 'NVIDIA NVENC';

  @override
  String get gpuEncoderAmd => 'AMD AMF';

  @override
  String get gpuEncoderIntel => 'Intel QSV';

  @override
  String get gpuEncoderApple => 'Apple VideoToolbox';

  @override
  String get btnDownloadVcRedist => 'تنزيل حزمة VC++ REDISTRIBUTABLE';

  @override
  String errorDownloadToolFailed(String error) {
    return 'فشل تنزيل الأداة: $error';
  }

  @override
  String get errorFolderNotAccessible =>
      'المجلد المحدد غير موجود أو لا يمكن الوصول إليه.';

  @override
  String modelDeleted(String name) {
    return 'تم حذف النموذج: $name';
  }

  @override
  String errorModelDeleteFailed(String error) {
    return 'فشل حذف النموذج: $error';
  }

  @override
  String errorModelDownloadFailed(String name, String error) {
    return 'فشل تنزيل النموذج $name: $error';
  }

  @override
  String errorOpenFolderFailed(String path) {
    return 'تعذر فتح المجلد تلقائيًا. المسار: $path';
  }

  @override
  String errorDownloadPackFailed(String error) {
    return 'فشل تنزيل الحزمة: $error';
  }

  @override
  String errorPackDownloadNamedFailed(String name, String error) {
    return 'فشل تنزيل الحزمة $name: $error';
  }

  @override
  String get stickersIndexRefreshed => 'تم تحديث فهرس الملصقات المخصصة بنجاح!';

  @override
  String errorChangeAssetFolderFailed(String error) {
    return 'فشل تغيير مجلد الأصول: $error';
  }

  @override
  String errorSetAssetFolderFailed(String error) {
    return 'فشل تعيين مجلد الأصول: $error';
  }

  @override
  String get warningNoAvx =>
      'تم اكتشاف عدم وجود دعم AVX! جارٍ تنزيل إصدار whisper-cli المتوافق (بدون AVX)...';

  @override
  String get errorAutoDetectWhisper =>
      'تعذر الكشف التلقائي عن whisper-cli. يرجى التصفح يدويًا.';

  @override
  String get errorAutoDetectFfmpeg =>
      'تعذر الكشف التلقائي عن ffmpeg. يرجى التصفح يدويًا.';

  @override
  String errorToolDownloadFailed(String error) {
    return 'فشل تنزيل الأداة: $error';
  }

  @override
  String get returnToDashboard => 'العودة إلى لوحة التحكم';

  @override
  String errorImportVideoFailed(String error) {
    return 'فشل الاستيراد: $error';
  }

  @override
  String get videoRelinkedSuccess => 'تمت إعادة ربط الفيديو بنجاح!';

  @override
  String get errorRelinkVideoFailed => 'فشلت إعادة ربط الفيديو.';

  @override
  String get retranscriptionSuccess => 'نجحت إعادة نسخ النص!';

  @override
  String get retranscriptionFailed => 'فشلت إعادة نسخ النص.';
}
