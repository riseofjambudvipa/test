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
}
