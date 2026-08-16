// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appName => 'CapStudio';

  @override
  String get dashboardTitle => 'Projelerim';

  @override
  String get dashboardSubtitle =>
      'Çevrimdışı Yapay Zeka Altyazı ve Transkripsiyon Stüdyosu';

  @override
  String get importVideo => 'Videoyu İçe Aktar';

  @override
  String get dragDropText => 'Video dosyanızı buraya sürükleyip bırakın';

  @override
  String get clickBrowse => 'veya yerel dosyalara göz atmak için tıklayın';

  @override
  String get demoMode => 'DEMO MODU';

  @override
  String get demoModeDesc =>
      'Stil ve editör özelliklerini denemek için örnek bir proje yükleyin.';

  @override
  String get warningAssets => 'Varlık Klasörünün Kurtarılması Gerekiyor';

  @override
  String get warningAssetsDesc =>
      'Uygulama destek klasöründe yerleşik varlıklar bulunamadı. Kurtarmak veya varlık dizinini değiştirmek için buraya çift tıklayın.';

  @override
  String get deleteProjectTitle => 'Projeyi Sil';

  @override
  String deleteProjectConfirm(String projectName) {
    return '\"$projectName\" projesini kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.';
  }

  @override
  String get renameProjectTitle => 'Projeyi Yeniden Adlandır';

  @override
  String get projectNameLabel => 'Proje Adı';

  @override
  String get btnCancel => 'İPTAL';

  @override
  String get btnDelete => 'SİL';

  @override
  String get btnRename => 'YENİDEN ADLANDIR';

  @override
  String get btnSave => 'KAYDET';

  @override
  String get btnConfirm => 'ONAYLA';

  @override
  String get btnExport => 'DIŞA AKTAR';

  @override
  String get btnUndo => 'Geri Al';

  @override
  String get btnRedo => 'Yinele';

  @override
  String get statusDraft => 'Taslak';

  @override
  String get statusCompleted => 'Tamamlandı';

  @override
  String get createdLabel => 'Oluşturulma Tarihi:';

  @override
  String get durationLabel => 'Süre:';

  @override
  String get statusLabel => 'Durum:';

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String get settingsGeneral => 'Genel Ayarlar';

  @override
  String get settingsTheme => 'Uygulama Teması';

  @override
  String get themeSystem => 'Sistem Varsayılanı';

  @override
  String get themeLight => 'Açık Tema';

  @override
  String get themeDark => 'Koyu Tema';

  @override
  String get settingsLanguage => 'Arayüz Dili';

  @override
  String get settingsTranscription => 'Transkripsiyon Ayarları';

  @override
  String get settingsWhisperModel => 'Whisper Modeli';

  @override
  String get settingsWhisperModelDesc =>
      'Transkripsiyon için bir model seçin. Daha küçük olanlar daha hızlı, daha büyük olanlar daha doğrudur.';

  @override
  String get settingsTranscribeLang => 'Transkripsiyon Dili';

  @override
  String get settingsAutoDetect => 'Dili Otomatik Algıla';

  @override
  String get settingsGPU => 'GPU Donanım Hızlandırma (CUDA)';

  @override
  String get settingsVAD => 'VAD Ses Algılama Eşiği';

  @override
  String get settingsExport => 'Dışa Aktarma Ayarları';

  @override
  String get settingsExportDest => 'Varsayılan Dışa Aktarma Dizini';

  @override
  String get settingsBrowse => 'Gözat';

  @override
  String get settingsEmojiPacks => 'Emoji ve Stil Paketleri';

  @override
  String get settingsEmojiPacksDesc =>
      'Emoji oluşturma stillerini ve aktif altyazı varlıklarını özelleştirin.';

  @override
  String get settingsEmojiSearchLang => 'Emoji Arama Dili';

  @override
  String get settingsBtnManagePacks => 'EMOJİ PAKETLERİNİ YÖNET';

  @override
  String get systemTitle => 'Sistem Bilgisi';

  @override
  String get systemVersion => 'Sürüm';

  @override
  String get systemReset => 'Varsayılanları Sıfırla';

  @override
  String get editorTabCaptions => 'Altyazılar';

  @override
  String get editorTabStyles => 'Stiller';

  @override
  String get editorTabTrim => 'Kırp';

  @override
  String get editorTabAudio => 'Ses';

  @override
  String get editorTabTranscription => 'Transkripsiyon';

  @override
  String get editorTabShortcuts => 'Kısayollar';

  @override
  String get editorTabDebug => 'Hata Ayıklama';

  @override
  String get editorHeaderBack => 'Geri';

  @override
  String get editorKeyboardShortcuts => 'Klavye Kısayolları';

  @override
  String get dialogAnalyzing => 'Video analiz ediliyor...';

  @override
  String get dialogTranscribing => 'Ses transkribe ediliyor...';

  @override
  String get dialogExtracting => 'Ses ayrıştırılıyor...';

  @override
  String get dialogWait => 'Bu işlem biraz zaman alabilir. Lütfen bekleyin.';

  @override
  String get dialogError => 'Hata';

  @override
  String get dialogImportFailed => 'Video içe aktarılamadı.';

  @override
  String get noProjects => 'Henüz proje oluşturulmadı';

  @override
  String get aboutApp => 'CapStudio Hakkında';

  @override
  String get aboutAppDesc =>
      'CapStudio, krediler ve açık kaynaklı lisanslar hakkında bilgi verir.';

  @override
  String get aboutAppThanks =>
      'CapStudio\'yu mümkün kılan açık kaynaklı projelere özel teşekkürler:';

  @override
  String get btnViewAllLicenses => 'TÜM PAKET LİSANSLARINI GÖR';
}
