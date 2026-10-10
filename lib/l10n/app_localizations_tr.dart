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

  @override
  String get exportBurnIn => 'ALTYAZI GÖMMELİ VİDEO DIŞA AKTARIMI';

  @override
  String get exportTimecodeFormats => 'ZAMAN KODLU ALTYAZI FORMATLARI';

  @override
  String get exportWebEnabled =>
      'İstemci tarafı video dışa aktarımı etkindir. İşleme tarayıcınızda yerel olarak çalışır.';

  @override
  String get exportWebCaptionOnly =>
      'Web dışa aktarımı şu anda yalnızca altyazıları içerir — emojiler ve ses efektleri henüz videoya gömülmez. Tam sonuç için masaüstü veya mobil uygulamadan dışa aktarın.';

  @override
  String get exportOutputName => 'Çıktı Videosu Adı';

  @override
  String get exportMode => 'Dışa Aktarma Modu';

  @override
  String get exportModeFast => 'Hızlı (Yerel FFmpeg)';

  @override
  String get exportModeFastUnsupported =>
      'Hızlı (Yerel FFmpeg) ⚠️ Desteklenmiyor';

  @override
  String get exportModeSlow => 'Yavaş (1:1 Önizleme İşleme)';

  @override
  String get exportTargetFps => 'Hedef FPS';

  @override
  String get exportFps24 => '24 FPS (Film)';

  @override
  String get exportFps25 => '25 FPS (PAL)';

  @override
  String get exportFps30 => '30 FPS (Standart)';

  @override
  String get exportFps50 => '50 FPS';

  @override
  String get exportFps60 => '60 FPS (Akıcı)';

  @override
  String get exportFastUnsupported =>
      'Hızlı Mod bu cihazda desteklenmiyor çünkü sistem FFmpeg sürümünde altyazı işleme filtreleri (libass) bulunmuyor. Bunun yerine Yavaş Mod kullanılacak.';

  @override
  String get exportSlowInfo =>
      'Her kareyi önizlemede göründüğü gibi yakalar. Bu, piksel piksel mükemmel altyazılar sağlar ancak işlemeyi yavaşlatır.';

  @override
  String get exportDestDirectory => 'HEDEF KLASÖR';

  @override
  String get exportDestBrowser => 'Tarayıcı İndirme Konumu';

  @override
  String get exportDestAndroid =>
      'İndirilenler klasörü (/storage/emulated/0/Download)';

  @override
  String get exportDestIos =>
      'Uygulama Belgeleri (dışa aktarma sonrası paylaşım sayfası)';

  @override
  String get exportChooseFolder => 'Çıktı Klasörünü Seç';

  @override
  String get exportStartMp4 => 'MP4 DIŞA AKTARIMINI BAŞLAT';

  @override
  String get exportSrtTitle => 'SubRip Altyazıları (.srt)';

  @override
  String get exportSrtDesc =>
      'Zaman kodlu evrensel standart. YouTube, VLC ve Premiere Pro ile uyumludur.';

  @override
  String get exportVttTitle => 'WebVTT Altyazıları (.vtt)';

  @override
  String get exportVttDesc =>
      'HTML5 oynatıcılarda ve çevrimiçi akışta yaygın olarak kullanılan web odaklı altyazı formatı.';

  @override
  String get exportAssTitle => 'Advanced SubStation Alpha (.ass)';

  @override
  String get exportAssDesc =>
      'Yazı tipi boyutlarını, stilleri, kenar boşluklarını ve satır içi vurguları içeren profesyonel format.';

  @override
  String get exportTxtTitle => 'Düz Metin Transkripti (.txt)';

  @override
  String get exportTxtDesc =>
      'Zaman damgası önek işaretleriyle satır satır transkript.';

  @override
  String exportSuccess(String type) {
    return '$type başarıyla dışa aktarıldı!';
  }

  @override
  String get exportNoLocation =>
      'Kayıt konumu seçilmedi. Lütfen bir dosya yolu belirleyin.';

  @override
  String get exportNoLocationCancelled =>
      'Kayıt konumu seçilmedi. Dışa aktarma iptal edildi.';

  @override
  String exportFailed(String error) {
    return 'Dışa aktarılamadı: $error';
  }

  @override
  String get exportCopySrtTooltip => 'SRT\'yi panoya kopyala';

  @override
  String get exportCopiedSrt => 'SRT panoya kopyalandı!';

  @override
  String exportCopyFailedSrt(String error) {
    return 'SRT kopyalanamadı: $error';
  }

  @override
  String exportSubtitlesDialogTitle(String type) {
    return '$type Altyazılarını Dışa Aktar';
  }

  @override
  String get exportVideoDialogTitle => 'Video MP4 Dışa Aktar';

  @override
  String get ffmpegRequiredTitle => 'FFmpeg Gerekli';

  @override
  String get ffmpegRequiredBody =>
      'Altyazıları bir video dosyasına gömmek için yerel bir FFmpeg kurulumu gerekir.\n\nLütfen Ayarlar\'da FFmpeg yolunu yapılandırın.';

  @override
  String get okLabel => 'TAMAM';

  @override
  String get exportWebTitle => 'Video Dışa Aktarılıyor (İstemci Tarafı)';

  @override
  String exportWebSuccess(String fileName) {
    return 'Video $fileName olarak başarıyla dışa aktarıldı!';
  }

  @override
  String exportWebFailed(String error) {
    return 'İşleme başarısız oldu: $error';
  }

  @override
  String get viralShortsTitle => 'VİRAL SHORTS STÜDYOSU';

  @override
  String get viralShortsSubtitle =>
      '9:16 Dikey Yeniden Çerçeveleme, Sessizlik Atlama Kesmeleri ve Yapay Zeka Kanca Dedektörü';

  @override
  String get viralReframeTitle => '1. DİKEY 9:16 ÇERÇEVELEME';

  @override
  String get viralSilenceTitle => '2. SESSİZLİK KALDIRMA (ATLAMA KESMELERİ)';

  @override
  String get viralHooksTitle => '3. YAPAY ZEKA VİRAL KANCA DEDEKTÖRÜ';

  @override
  String get btnFindViralMoments => 'VİRAL ANLARI BUL';

  @override
  String get btnScanSilences => 'SESSİZLİKLERİ TARA';

  @override
  String get btnApplyJumpCuts => 'ATLAMA KESMELERİNİ UYGULA';

  @override
  String get editorTabShorts => 'Shorts';

  @override
  String get editorTabClips => 'Klipler';

  @override
  String get captionList => 'ALTYAZI LİSTESİ';

  @override
  String get uncertainLabel => 'Belirsiz (<%40)';

  @override
  String get mediumConfidenceLabel => 'Orta (%40-60)';

  @override
  String get jumpToUncertain => 'Sonraki belirsiz kelimeye atla';

  @override
  String get noUncertainWords => 'Belirsiz kelime bulunamadı.';

  @override
  String get findAndReplace => 'Bul ve Değiştir';

  @override
  String get addWordTitle => 'Kelime Ekle';

  @override
  String get editWordTitle => 'Kelimeyi Düzenle';

  @override
  String get wordTextLabel => 'Kelime Metni';

  @override
  String get startTimeLabel => 'Başlangıç Zamanı (sn)';

  @override
  String get endTimeLabel => 'Bitiş Zamanı (sn)';

  @override
  String get splitChunk => 'Parçayı Böl';

  @override
  String get insertLineAfter => 'Sonrasına Satır Ekle';

  @override
  String get duplicateLine => 'Satırı Çoğalt';

  @override
  String get deleteLine => 'Satırı Sil';

  @override
  String get chooseSfxTitle => 'Ses Efekti Seç';

  @override
  String get searchSfxPlaceholder => 'Ses efekti ara...';

  @override
  String get noSfxFound => 'Ses efekti bulunamadı';

  @override
  String get emojiSearch => 'Emoji Arama';

  @override
  String get noEmojisFound => 'Emoji bulunamadı.';

  @override
  String get mySavedPresets => 'KAYITLI HAZIR AYARLARIM';

  @override
  String get btnImport => 'İÇE AKTAR';

  @override
  String get btnExportCaps => 'DIŞA AKTAR';

  @override
  String get btnSaveCurrent => 'MEVCUDU KAYDET';

  @override
  String get resetToDefault => 'Varsayılana Sıfırla';

  @override
  String get resetConfirmBody =>
      'Tüm altyazı stilleri varsayılana sıfırlanacak. Bu işlem geri alınamaz.';

  @override
  String get btnReset => 'Sıfırla';

  @override
  String get wordHighlightBox => 'Kelime Vurgu Kutusu';

  @override
  String get wordHighlightBoxDesc =>
      'Konuşulan aktif kelimelerin arkasında renkli arka plan kutusu';

  @override
  String get maxWordsPerChunk => 'Altyazı Parçası Başına Maksimum Kelime';

  @override
  String get maxCharsPerLine => 'Altyazı Satırı Başına Maksimum Karakter';

  @override
  String get fontSettings => 'Yazı Tipi Ayarları';

  @override
  String get colorSettings => 'Renk Ayarları';

  @override
  String get borderSettings => 'Kenarlık ve Gölge Ayarları';

  @override
  String get speechToTextTitle => 'KONUŞMADAN METNE DÖNÜŞTÜRME';

  @override
  String get speechToTextDesc =>
      'Yerel Konuşmadan Metne dönüştürmeyi yeniden çalıştırın. Manuel düzenlemeler veya zamanlama değişiklikleri silinecektir.';

  @override
  String get useLocalAi => 'Yerel Yapay Zeka Transkripsiyonunu Kullan';

  @override
  String get runOnDeviceDesc =>
      'Konuşmayı metne dönüştürmeyi doğrudan bu cihazda çalıştırın';

  @override
  String get offlineDemoModeActive =>
      'Çevrimdışı Demo modu etkin. Web sürümünde yerel Whisper AI transkripsiyonu desteklenmez.';

  @override
  String get demoModeNote =>
      'Demo modu son derece gerçekçi transkripsiyon belirteçleri oluşturur. Kurulum yapmadan stilleri, şablonları ve zaman çizelgesi işlemlerini test etmek için idealdir.';

  @override
  String get transcriptionQuality => 'Transkripsiyon Kalitesi';

  @override
  String get advancedSettings => 'Gelişmiş Ayarlar';

  @override
  String get cpuThreadsLabel => 'CPU İş Parçacıkları';

  @override
  String get vadSensitivity => 'VAD Hassasiyeti';

  @override
  String get translateToEnglish => 'Altyazıları İngilizceye çevir';

  @override
  String get startTranscriptionBtn => 'TRANSKRİPSİYONU BAŞLAT';

  @override
  String get hardwareLocked => 'Donanım Kilitli';

  @override
  String get btnDownload => 'İndir';

  @override
  String get welcomeTitle => 'CapStudio\'ya Hoş Geldiniz';

  @override
  String get welcomeSubtitle =>
      'Yüksek hassasiyetli altyazılar ve viral shorts videoları, %100 çevrimdışı.';

  @override
  String get setupAssetDirTitle => 'Varlık Dizinini Seçin';

  @override
  String get setupAssetDirDesc =>
      'Modelleri, yazı tiplerini ve emoji paketlerini saklamak için bir dizin seçin.';

  @override
  String get downloadPacksTitle => 'İçerik Paketlerini İndirin (İsteğe Bağlı)';

  @override
  String get downloadPacksDesc =>
      'Video projeleriniz için isteğe bağlı yazı tipleri ve ses efektleri.';

  @override
  String get setupCompleteTitle => 'Kurulum Tamamlandı';

  @override
  String get setupCompleteDesc =>
      'Göz alıcı altyazılı videolar oluşturmaya hazırsınız.';

  @override
  String get btnGetStarted => 'Başlayın';

  @override
  String get btnNext => 'İLERİ';

  @override
  String get btnSkip => 'ATLA';

  @override
  String get onboardingFeaturePrivacy => '%100 Gizlilik';

  @override
  String get onboardingFeaturePrivacyDesc =>
      'Dosyalarınız asla cihazınızdan çıkmaz. Tüm yapay zeka modelleri yerel olarak çalışır.';

  @override
  String get onboardingFeatureGpu => 'GPU Hızlandırmalı Oynatma';

  @override
  String get onboardingFeatureGpuDesc =>
      'Donanım kod çözme ile yüksek performanslı video düzenleme.';

  @override
  String get onboardingFeatureAssets => 'Çevrimdışı Yardımcı Varlıklar';

  @override
  String get onboardingFeatureAssetsDesc =>
      'Zengin emoji paketlerini bir kez indirin ve tamamen çevrimdışı kullanın.';

  @override
  String get onboardingReadyTitle => 'Başlamaya Hazırsınız!';

  @override
  String get onboardingConfigDetails => 'Yapılandırma Ayrıntıları:';

  @override
  String get btnLaunchCapStudio => 'CapStudio\'yu Başlat';

  @override
  String get assetVerificationFailed =>
      'Varlık doğrulaması başarısız oldu. Lütfen varlıkların düzgün indirildiğinden emin olun.';

  @override
  String get assetsFolderNotFound => 'Varlık Klasörü Bulunamadı';

  @override
  String get assetsFolderNotFoundDesc =>
      'CapStudio yapılandırılan konumda varlık klasörünü bulamadı. Klasör harici bir sürücüdeyse lütfen sürücüyü bağlayın.';

  @override
  String get expectedPathLabel => 'BEKLENEN YOL:';

  @override
  String get browseNewLocation => 'Yeni Konuma Göz At';

  @override
  String get resetToDefaultPath => 'Varsayılan Yola Sıfırla';

  @override
  String get retryVerification => 'Doğrulamayı Yeniden Dene';

  @override
  String get storagePathFolder => 'Depolama Yolu Klasörü';

  @override
  String get tipWindowsDrive =>
      'İpucu: C: sürücüsü küçükse daha fazla alan için D: veya E: sürücüsünde bir yol seçin.';

  @override
  String get tipGeneralDrive =>
      'İpucu: Kök biriminiz doluysa harici bir sürücü yolu seçebilirsiniz.';

  @override
  String get confirmLocation => 'Konumu Onayla';

  @override
  String get requiredBadge => 'GEREKLİ';

  @override
  String get emojiPacksHeader => 'EMOJİ PAKETLERİ';

  @override
  String get fontPacksHeader => 'YAZI TİPİ PAKETLERİ';

  @override
  String get connectCliTitle => 'Yerel CLI Araçlarını Bağlayın';

  @override
  String get connectCliDesc =>
      'CapStudio\'nun yerel olarak transkripsiyon yapması ve videoları dışa aktarması için whisper.cpp ve FFmpeg ikili dosyalarına ihtiyacı vardır.';

  @override
  String get skipSetup => 'Kurulumu şimdilik atla';

  @override
  String get btnValidate => 'Doğrula';

  @override
  String get autoDetectAndValidate => 'Otomatik Algıla ve Doğrula';

  @override
  String get whisperCliPathLabel => 'Whisper CLI Yürütülebilir Dosya Yolu';

  @override
  String get ffmpegCliPathLabel => 'FFmpeg CLI Yürütülebilir Dosya Yolu';

  @override
  String get newProject => 'Yeni Proje';

  @override
  String get searchProjects => 'Projeleri ara...';

  @override
  String get filterAll => 'Tümü';

  @override
  String get sortByRecent => 'En Son';

  @override
  String get sortByDuration => 'Süreye Göre';

  @override
  String get noMatchingProjects => 'Aramanızla eşleşen proje bulunamadı';

  @override
  String get btnEdit => 'DÜZENLE';

  @override
  String get btnDuplicate => 'ÇOĞALT';

  @override
  String get tooltipEdit => 'Düzenle';

  @override
  String get tooltipRename => 'Yeniden Adlandır';

  @override
  String get tooltipDuplicate => 'Çoğalt';

  @override
  String get tooltipDelete => 'Sil';

  @override
  String get tooltipTheme => 'Tema';

  @override
  String get tooltipSettings => 'Ayarlar';

  @override
  String get selectDemoFormat => 'DEMO FORMATINI SEÇİN';

  @override
  String get selectDemoDesc =>
      'CapStudio\'nun yüksek kaliteli altyazı motorunu, canlı kelime animasyonlarını ve ses dalga formlarını anında önizlemek için bir düzen seçin.';

  @override
  String get landscapeDemo => 'Yatay Demo';

  @override
  String get landscapeDemoDesc =>
      'YouTube, masaüstü ve sunumlar için idealdir.';

  @override
  String get portraitDemo => 'Dikey Demo';

  @override
  String get portraitDemoDesc =>
      'TikTok, Shorts, Reels ve mobil için idealdir.';

  @override
  String get format16x9 => '16:9 Formatı';

  @override
  String get format9x16 => '9:16 Formatı';

  @override
  String get dropVideoHere => 'VİDEOYU BURAYA BIRAKIN';

  @override
  String get dropVideoSupported => 'MP4, MOV, AVI vb. destekler.';

  @override
  String get statusLocalOffline => 'YEREL ÇEVRİMDİŞI';

  @override
  String get speechModelTitle => 'Konuşma Tanıma Modeli';

  @override
  String get hardwareUpgradesTitle => 'Donanım Performansı Yükseltmeleri';

  @override
  String get showAdvancedPaths => 'GELİŞMİŞ YOL YAPILANDIRMASINI GÖSTER';

  @override
  String get hideAdvancedPaths => 'GELİŞMİŞ YOL YAPILANDIRMASINI GİZLE';

  @override
  String get autoDownload => 'OTOMATİK İNDİR';

  @override
  String get gpuAcceleratedTranscription =>
      'GPU Hızlandırmalı Transkripsiyon (CUDA)';

  @override
  String get gpuRequiresNvidia => 'CUDA uyumlu bir NVIDIA GPU gerektirir';

  @override
  String get gpuExportEncoder => 'GPU Dışa Aktarma Kodlayıcısı';

  @override
  String get gpuExportEncoderDesc =>
      'MP4 video dışa aktarımı için donanım hızlandırma';

  @override
  String get defaultLanguage => 'Varsayılan Dil';

  @override
  String get vadTitle => 'Ses Aktivitesi Algılama (VAD)';

  @override
  String get vadDesc => 'İşleme sırasında sessiz bölümleri atlar';

  @override
  String get vadThreshold => 'VAD Eşiği';

  @override
  String get autoSaveTitle => 'Otomatik Kaydetme';

  @override
  String get autoSaveDesc =>
      'Proje düzenlemelerini her 3 saniyede bir otomatik olarak veritabanına kaydeder';

  @override
  String get defaultOutputsTitle => 'Varsayılan Çıktılar';

  @override
  String get defaultExportFolder => 'Varsayılan Dışa Aktarma Klasörü';

  @override
  String get alwaysAskExportPath => 'Her Zaman Dışa Aktarma Yolunu Sor';

  @override
  String get alwaysAskExportPathDesc =>
      'Her dışa aktarmada çıktı yolu sorar (Masaüstü)';

  @override
  String get performanceTitle => 'Performans';

  @override
  String get exportCpuThreads => 'Dışa Aktarma CPU İş Parçacıkları';

  @override
  String get exportCpuThreadsDesc =>
      'İşleme için kullanılacak işlemci iş parçacıkları (cihaza göre güvenle otomatik ayarlanır)';

  @override
  String get aboutAppSubtitle =>
      '%100 Çevrimdışı, Gizlilik Odaklı Yapay Zeka Altyazı Stüdyosu';

  @override
  String get openSourceLicenses => 'Açık Kaynak Lisansları';

  @override
  String get openSourceComplianceDesc =>
      'CapStudio birçok açık kaynaklı kütüphaneden yararlanır. Yasal mağaza uyumluluğu için tüm Dart paketlerinin, bağımlılıkların ve lisans metinlerinin tam kaydı aşağıda derlenmiştir.';

  @override
  String get visitWebsite => 'Web Sitesini Ziyaret Et';

  @override
  String get btnContinue => 'Devam Et';

  @override
  String get btnBack => 'Geri';

  @override
  String get editTiming => 'Zamanlamayı Düzenle';

  @override
  String get wordSettingsTitle => 'Kelime Ayarları';

  @override
  String get emojiSettingsTitle => 'EMOJİ AYARLARI';

  @override
  String get changeEmojiTooltip => 'Emojiyi Değiştir';

  @override
  String get searchEmojisHint => 'Emoji Ara...';

  @override
  String emojiPosX(String offset) {
    return 'Emoji Konumu (X Kayması: ${offset}px)';
  }

  @override
  String emojiPosY(String offset) {
    return 'Emoji Konumu (Y Kayması: ${offset}px)';
  }

  @override
  String emojiScale(String scale) {
    return 'Emoji Ölçeği (${scale}x)';
  }

  @override
  String emojiAnimSpeed(String speed) {
    return 'Animasyon Hızı (${speed}x)';
  }

  @override
  String get emojiStylePack => 'Emoji Stili / Paketi';

  @override
  String get selectStylePackTooltip => 'Stil Paketini Seçin';

  @override
  String get selectEmojiTitle => 'EMOJİ SEÇİN';

  @override
  String get stylePackLabel => 'STİL PAKETİ';

  @override
  String get searchHint => 'Ara...';

  @override
  String get btnCreateProject => 'PROJE OLUŞTUR';

  @override
  String get btnChooseFile => 'DOSYA SEÇ';

  @override
  String get selectSubtitleFile => 'Altyazı Dosyasını Seçin';

  @override
  String get selectTranscriptionQuality => 'TRANSKRİPSİYON KALİTESİNİ SEÇİN';

  @override
  String get translateToEnglishDesc =>
      'Yabancı konuşmayı doğrudan İngilizce altyazılara dönüştürün';

  @override
  String get hardwareSettings => 'DONANIM VE PERFORMANS AYARLARI';

  @override
  String get styleTemplatesHeader => 'STİL ŞABLONLARI';

  @override
  String get resetToDefaultStyle => 'Varsayılan stile sıfırla';

  @override
  String get resetStylingTitle => 'Stil Sıfırlansın mı?';

  @override
  String get resetStylingDesc =>
      'Tüm altyazı stilleri varsayılana sıfırlanacak. Bu işlem geri alınamaz.';

  @override
  String get sizeAndPosition => 'BOYUT VE KONUM';

  @override
  String get verticalYPos => 'Dikey Y Konumu (%)';

  @override
  String get fontConfigHeader => 'YAZI TİPİ YAPILANDIRMASI';

  @override
  String get fontFamilyLabel => 'Yazı Tipi Ailesi';

  @override
  String get btnImportCustomFont => 'ÖZEL YAZI TİPİ İÇE AKTAR (.ttf / .otf)';

  @override
  String get fontWeightLabel => 'Yazı Tipi Kalınlığı';

  @override
  String get textCaseLabel => 'Büyük/Küçük Harf';

  @override
  String get fontSizeLabel => 'Yazı Tipi Boyutu';

  @override
  String get letterSpacingLabel => 'Harf Aralığı';

  @override
  String get lineHeightLabel => 'Satır Yüksekliği';

  @override
  String get onboardingAppTagline =>
      '%100 Çevrimdışı Yerel Yapay Zeka Altyazı Düzenleyicisi';

  @override
  String get configLabelWhisperCli => 'Whisper CLI';

  @override
  String get configValueDemoMode => 'Demo Modu (Örnek)';

  @override
  String get configLabelFfmpegCli => 'FFmpeg CLI';

  @override
  String get configValueSystemPathDefault => 'Sistem PATH varsayılanı';

  @override
  String get configLabelAssetsLocation => 'Varlık Konumu';

  @override
  String get filePickerAssetsDialogTitle => 'CapStudio Varlık Klasörünü Seçin';

  @override
  String errorSelectFolderFailed(String error) {
    return 'Klasör seçilemedi: $error';
  }

  @override
  String errorResetFailed(String error) {
    return 'Sıfırlanamadı: $error';
  }

  @override
  String errorVerificationFailed(String error) {
    return 'Doğrulama başarısız oldu: $error';
  }

  @override
  String errorAssetsFolderStillMissing(String path) {
    return 'Varlık klasörü belirtilen yolda hala bulunamadı: $path';
  }

  @override
  String get dbRecoveredTitle => 'Veritabanı Otomatik Olarak Kurtarıldı';

  @override
  String dbRecoveredBody(String backupPath) {
    return 'Veritabanı şema uyuşmazlığı veya bozulması tespit edildi. Veritabanı sıfırlandı ve önceki verileriniz şuraya yedeklendi:\n\n$backupPath';
  }

  @override
  String errorDemoLoadFailed(String error) {
    return 'Demo video yüklenemedi: $error';
  }

  @override
  String importProgressPercent(int percent) {
    return '%$percent Tamamlandı';
  }

  @override
  String get errorInvalidDropFileFormat =>
      'Geçersiz dosya biçimi. Lütfen bir video dosyası sürükleyin.';

  @override
  String get findTextLabel => 'Metni bul';

  @override
  String get replaceWithLabel => 'Bununla değiştir';

  @override
  String findReplaceSuccessCount(int count) {
    return '$count eşleşme değiştirildi!';
  }

  @override
  String get btnReplaceAll => 'TÜMÜNÜ DEĞİŞTİR';

  @override
  String errorVideoFileNotFound(String path) {
    return 'Video dosyası bulunamadı:\n$path\nLütfen video dosyasını yeniden bağlayın.';
  }

  @override
  String get errorTranscriptionFailed =>
      'Transkripsiyon başarısız oldu. Lütfen tekrar deneyin.';

  @override
  String transcriptionActiveModel(String quality, String model) {
    return 'Aktif: $quality ($model)';
  }

  @override
  String get badgeRecommended => 'ÖNERİLEN';

  @override
  String get languageLabel => 'Dil';

  @override
  String warningEnglishOnlyModel(String model, String language) {
    return 'Uyarı: Seçilen model ($model) yalnızca İngilizceyi destekler. \"$language\" dilinde transkripsiyon başarısız olur veya İngilizce altyazılar üretir. Lütfen çok dilli bir model seçin (örn. Tiny veya Base).';
  }

  @override
  String get tipAutoDetectMixedLanguage =>
      'İpucu: Karışık diller için otomatik algılama önerilmez. Konuştuğunuz dili doğrudan seçmek çok daha doğru altyazılar sağlar.';

  @override
  String get detectedHardwareLabel => 'Algılanan Sistem Donanımı:';

  @override
  String hardwareRamSize(String ramGB) {
    return 'RAM Boyutu: $ramGB GB';
  }

  @override
  String hardwareCpuCores(int cores) {
    return 'CPU Mantıksal Çekirdekleri: $cores';
  }

  @override
  String hardwareGpuDevice(String gpu) {
    return 'GPU Cihazı: $gpu';
  }

  @override
  String get hardwareDetecting => 'Donanım özellikleri algılanıyor...';

  @override
  String get btnStartReTranscribe => 'YENİDEN TRANSKRİPSİYONU BAŞLAT';

  @override
  String get btnImportSrtVtt => 'SRT/VTT DOSYASI İÇE AKTAR';

  @override
  String importedSubtitleWords(int count) {
    return 'Altyazı dosyasından $count kelime içe aktarıldı.';
  }

  @override
  String get errorImportSubtitleFailed =>
      'Altyazı dosyası içe aktarılamadı. Lütfen dosya formatını kontrol edin.';

  @override
  String get noProjectLoaded => 'Yüklü proje yok';

  @override
  String get badge916Vertical => '9:16 DİKEY';

  @override
  String get badge169Landscape => '16:9 YATAY';

  @override
  String get reframeTargetCanvas =>
      'Hedef tuval: 1080 × 1920 (TikTok, YouTube Shorts, Instagram Reels)';

  @override
  String get reframeModeLabel => 'Yeniden Çerçeveleme Modu:';

  @override
  String get reframeModeBlurPillarbox => 'Bulanık Kenar - Pillarbox (Önerilen)';

  @override
  String get reframeModeBlurPillarboxDesc =>
      'Videoyu 9:16 boyutuna uyarlamak için arka planı bulanıklaştırıp büyütür, merkezdeki videoyu net tutar.';

  @override
  String get reframeModeCenterCrop => 'Akıllı Merkez Kırpma';

  @override
  String get reframeModeCenterCropDesc =>
      'Sol ve sağ kenarları kırparak tam 9:16 ekranı doldurur.';

  @override
  String get reframeModeSplitScreen => 'Bölünmüş Ekran / Çift Katman';

  @override
  String get reframeModeSplitScreenDesc =>
      'İki video penceresini dikey olarak üst üste yerleştirir (tepki ve podcast videoları için idealdir).';

  @override
  String get btnResetTo169 => 'ŞU AN 9:16 (16:9 OLARAK SIFIRLA)';

  @override
  String get btnSetCanvas916 => 'PROJE TUVALİNİ 9:16 YAP';

  @override
  String get silenceRemovalDesc =>
      'İzleyici tutma oranını artırmak için sessiz duraklamaları ve nefes boşluklarını otomatik olarak keser.';

  @override
  String get silenceAggressivenessLabel => 'Kesme Hassasiyeti:';

  @override
  String silenceNoiseGateLabel(int db) {
    return 'Sessizlik Gürültü Eşiği: $db dB';
  }

  @override
  String silenceMinPauseLabel(String duration) {
    return 'Min. Duraklama: $duration sn';
  }

  @override
  String get btnScanning => 'TARANIYOR...';

  @override
  String silenceNoneFound(String duration) {
    return '$duration saniyeyi aşan sessizlik boşluğu bulunamadı.';
  }

  @override
  String silenceFoundCount(int count, String totalSecs) {
    return '$count sessizlik bulundu ($totalSecs sn ölü zaman kesildi)!';
  }

  @override
  String errorScanningAudio(String error) {
    return 'Ses taranırken hata oluştu: $error';
  }

  @override
  String jumpCutsApplied(int count) {
    return 'Proje zaman çizelgesine $count atlama kesmesi uygulandı!';
  }

  @override
  String get viralHooksDesc =>
      'Transkripsiyon kelimelerini 80\'den fazla viral kanca, konuşma hızı (120–170 K/DK), sorular, enerji yoğunluğu ve klip sınırları için tarar.';

  @override
  String get btnAnalyzingTranscript => 'TRANSKRİPT ANALİZ EDİLİYOR...';

  @override
  String get selectAllLabel => 'Tümünü Seç';

  @override
  String selectedCountOf(int selected, int total) {
    return '$selected / $total seçildi';
  }

  @override
  String get btnSelectClipsToBatchExport =>
      'TOPLU DIŞA AKTARILACAK KLİPLERİ SEÇİN';

  @override
  String btnBatchExportCount(int count) {
    return '$count KLİBİ TOPLU DIŞA AKTAR';
  }

  @override
  String get viralNoClipsDetected =>
      'Bu video süresi aralığında yüksek puanlı viral klip tespit edilmedi.';

  @override
  String get badgeCleanCut => 'TEMİZ KESİM';

  @override
  String get badgeFirst5s => 'İLK 5 SN';

  @override
  String get btnPreview => 'Önizleme';

  @override
  String get btnTrim => 'Kırp';

  @override
  String get tooltipForkAs916 => 'Yeni 9:16 Shorts Projesi Olarak Kopyala';

  @override
  String wpmLabelOk(int wpm) {
    return '$wpm K/DK ✓';
  }

  @override
  String wpmLabelFast(int wpm) {
    return '$wpm K/DK HIZLI';
  }

  @override
  String wpmLabelSlow(int wpm) {
    return '$wpm K/DK YAVAŞ';
  }

  @override
  String hookScoreLabel(int score) {
    return 'Kanca $score/40';
  }

  @override
  String energyScoreLabel(int score) {
    return 'Enerji $score/20';
  }

  @override
  String get filePickerClipsFolderTitle =>
      'Kliplerin kaydedileceği klasörü seçin';

  @override
  String get errorChooseOutputFolderFirst =>
      'Lütfen önce bir çıktı klasörü seçin.';

  @override
  String batchExportSheetTitle(int count) {
    return '$count KLİBİ TOPLU DIŞA AKTAR';
  }

  @override
  String get tapToChooseOutputFolder => 'Çıktı klasörünü seçmek için dokunun…';

  @override
  String get burnCaptionsOnClipsLabel => 'Kliplere Dinamik Altyazıları Göm';

  @override
  String get burnCaptionsOnClipsDesc =>
      'Klip sesiyle senkronize edilmiş stilli animasyonlu altyazıları videoya gömer';

  @override
  String exportCancelledProgress(int done, int total) {
    return 'Dışa aktarma iptal edildi. $done/$total tamamlandı.';
  }

  @override
  String exportProgressSummary(int done, int total, int failed) {
    return '$done/$total dışa aktarıldı · $failed başarısız';
  }

  @override
  String get btnExporting => 'DIŞA AKTARILIYOR…';

  @override
  String get btnExportComplete => 'DIŞA AKTARMA TAMAMLANDI ✓';

  @override
  String get btnStartExport => 'DIŞA AKTARMAYI BAŞLAT';

  @override
  String exportClipSavedAt(String path) {
    return '✓ Kaydedildi: $path';
  }

  @override
  String projectTrimmedToClip(int rank, String start, String end) {
    return 'Proje viral klip #$rank ($start - $end) boyutuna kırpıldı!';
  }

  @override
  String shortProjectCreated(String name) {
    return '9:16 Short Projesi Oluşturuldu: \"$name\"';
  }

  @override
  String get btnOpen => 'AÇ';

  @override
  String errorCreateShortProjectFailed(String error) {
    return 'Shorts projesi oluşturulamadı: $error';
  }

  @override
  String get autoDetect => 'Otomatik Algıla';

  @override
  String presetSaved(String name) {
    return '\"$name\" stil hazır ayarı başarıyla kaydedildi!';
  }

  @override
  String get presetDeleted => 'Hazır ayar başarıyla silindi.';

  @override
  String get presetExported => 'Stil hazır ayarları başarıyla dışa aktarıldı!';

  @override
  String errorPresetExportFailed(String error) {
    return 'Hazır ayarlar dışa aktarılamadı: $error';
  }

  @override
  String get presetImported => 'Stil hazır ayarları başarıyla içe aktarıldı!';

  @override
  String errorPresetImportFailed(String error) {
    return 'Hazır ayarlar içe aktarılamadı: $error';
  }

  @override
  String get selectFontFileDialogTitle =>
      'TTF veya OTF Yazı Tipi Dosyası Seçin';

  @override
  String get fontWeightThin => 'İnce';

  @override
  String get fontWeightExtraLight => 'Ekstra İnce';

  @override
  String get fontWeightLight => 'Açık';

  @override
  String get fontWeightNormal => 'Normal';

  @override
  String get fontWeightMedium => 'Orta';

  @override
  String get fontWeightSemiBold => 'Yarı Kalın';

  @override
  String get fontWeightBold => 'Kalın';

  @override
  String get fontWeightExtraBold => 'Ekstra Kalın';

  @override
  String get fontWeightBlack => 'En Kalın';

  @override
  String get fontCaseNormal => 'Normal';

  @override
  String get fontCaseUppercase => 'BÜYÜK HARF';

  @override
  String get fontCaseCapitalize => 'Baş Harfleri Büyüt';

  @override
  String get strokeStyleThickOutline => 'Kalın Kenarlık';

  @override
  String get strokeStyleNoneFlat => 'Yok (Düz)';

  @override
  String get shadowStyleSoft => 'Yumuşak Gölge';

  @override
  String get shadowStyleNone => 'Yok';

  @override
  String get animStyleActivePop => 'Aktif Vurgu (Pop)';

  @override
  String get animStyleActiveBounce => 'Aktif Zıplama';

  @override
  String get animStyleKineticTilt => 'Kinetik Yaylı Eğim';

  @override
  String get animStyleGlowPulse => 'Parlayan Aktif Nabız';

  @override
  String get animStyleWordReveal => 'Kademeli Kelime Açılışı';

  @override
  String get animStyleNoneStatic => 'Yok (Sabit)';

  @override
  String fontImportedSuccess(String name) {
    return 'Özel yazı tipi başarıyla içe aktarıldı ve uygulandı: \"$name\"';
  }

  @override
  String get errorFontImportFailed =>
      'Yazı tipi dosyası yüklenemedi. Geçersiz veri.';

  @override
  String get invalidTimingError =>
      'Geçersiz başlangıç/bitiş zamanları. Başlangıç >= 0 ve bitiş >= başlangıç ve <= video süresi olmalıdır.';

  @override
  String get projectSavedSuccess => 'Proje başarıyla kaydedildi.';

  @override
  String wordDeletedSuccess(String text) {
    return 'Kelime silindi: \"$text\"';
  }

  @override
  String get splitClip => 'Klibi böl';

  @override
  String get removeClip => 'Klibi kaldır';

  @override
  String get resetToOriginal => 'Orijinale sıfırla';

  @override
  String splitTimelineAt(String time) {
    return 'Zaman çizelgesi $time. saniyede bölündü.';
  }

  @override
  String get splitTimelineError =>
      'Bölmek için oynatma çizgisi etkin bölgenin içinde olmalıdır.';

  @override
  String get exclusionToggled =>
      'Oynatma çizgisinin altındaki bölüm hariç tutma durumu değiştirildi.';

  @override
  String get splitsReset =>
      'Tüm zaman çizelgesi bölmeleri ve hariç tutmaları sıfırlandı.';

  @override
  String get shareVideo => 'Videoyu Paylaş';

  @override
  String get openOutputFolder => 'Çıktı klasörünü aç';

  @override
  String get errorLogCopied => 'Hata günlüğü panoya kopyalandı.';

  @override
  String get diagnosticsExported =>
      'Filtrelenmiş tanılama raporu paylaşım sayfasında açıldı.';

  @override
  String errorDiagnosticsFailed(String error) {
    return 'Tanılama raporu dışa aktarılamadı: $error';
  }

  @override
  String logLineCopied(String message) {
    return 'Günlük satırı panoya kopyalandı: \"$message\"';
  }

  @override
  String commandCopied(String command) {
    return 'Kopyalandı: \"$command\"';
  }

  @override
  String get settingsRestored => 'Ayarlar varsayılanlara sıfırlandı.';

  @override
  String get gpuEncoderNoneCpu => 'Yok (CPU)';

  @override
  String get gpuEncoderNvidia => 'NVIDIA NVENC';

  @override
  String get gpuEncoderAmd => 'AMD AMF';

  @override
  String get gpuEncoderIntel => 'Intel QSV';

  @override
  String get gpuEncoderApple => 'Apple VideoToolbox';

  @override
  String get btnDownloadVcRedist => 'VC++ REDISTRIBUTABLE İNDİR';

  @override
  String errorDownloadToolFailed(String error) {
    return 'Araç indirilemedi: $error';
  }

  @override
  String get errorFolderNotAccessible =>
      'Seçilen klasör mevcut değil veya erişilemiyor.';

  @override
  String modelDeleted(String name) {
    return 'Model silindi: $name';
  }

  @override
  String errorModelDeleteFailed(String error) {
    return 'Model silinemedi: $error';
  }

  @override
  String errorModelDownloadFailed(String name, String error) {
    return '$name modeli indirilemedi: $error';
  }

  @override
  String errorOpenFolderFailed(String path) {
    return 'Klasör otomatik olarak açılamadı. Yol: $path';
  }

  @override
  String errorDownloadPackFailed(String error) {
    return 'Paket indirilemedi: $error';
  }

  @override
  String errorPackDownloadNamedFailed(String name, String error) {
    return '$name paketi indirilemedi: $error';
  }

  @override
  String get stickersIndexRefreshed =>
      'Özel çıkartmalar dizini başarıyla yenilendi!';

  @override
  String errorChangeAssetFolderFailed(String error) {
    return 'Varlık klasörü değiştirilemedi: $error';
  }

  @override
  String errorSetAssetFolderFailed(String error) {
    return 'Varlık klasörü ayarlanamadı: $error';
  }

  @override
  String get warningNoAvx =>
      'AVX desteği bulunamadı! Uyumlu whisper-cli (AVX\'siz) indiriliyor...';

  @override
  String get errorAutoDetectWhisper =>
      'whisper-cli otomatik olarak algılanamadı. Lütfen manuel olarak seçin.';

  @override
  String get errorAutoDetectFfmpeg =>
      'ffmpeg otomatik olarak algılanamadı. Lütfen manuel olarak seçin.';

  @override
  String errorToolDownloadFailed(String error) {
    return 'Araç indirilemedi: $error';
  }

  @override
  String get returnToDashboard => 'Panele Geri Dön';

  @override
  String errorImportVideoFailed(String error) {
    return 'İçe aktarma başarısız oldu: $error';
  }

  @override
  String get videoRelinkedSuccess => 'Video başarıyla yeniden bağlandı!';

  @override
  String get errorRelinkVideoFailed => 'Video yeniden bağlanamadı.';

  @override
  String get retranscriptionSuccess => 'Yeniden transkripsiyon başarılı!';

  @override
  String get retranscriptionFailed => 'Yeniden transkripsiyon başarısız oldu.';
}
