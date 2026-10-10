// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'CapStudio';

  @override
  String get dashboardTitle => 'मेरे प्रोजेक्ट';

  @override
  String get dashboardSubtitle => 'ऑफलाइन एआई कैप्शन और सबटाइटल्स स्टूडियो';

  @override
  String get importVideo => 'वीडियो आयात करें';

  @override
  String get dragDropText => 'अपनी वीडियो फ़ाइल को यहाँ खींचें और छोड़ें';

  @override
  String get clickBrowse => 'या स्थानीय फ़ाइलें खोजने के लिए क्लिक करें';

  @override
  String get demoMode => 'डेमो मोड';

  @override
  String get demoModeDesc =>
      'स्टाइलिंग और संपादक सुविधाओं को आज़माने के लिए एक डेमो प्रोजेक्ट लोड करें।';

  @override
  String get warningAssets => 'एसेट फ़ोल्डर रिकवरी आवश्यक';

  @override
  String get warningAssetsDesc =>
      'ऐप सपोर्ट फ़ोल्डर में बंडल एसेट्स नहीं मिले। रीस्टोर करने या एसेट डायरेक्टरी बदलने के लिए यहाँ डबल-क्लिक करें।';

  @override
  String get deleteProjectTitle => 'प्रोजेक्ट हटाएं';

  @override
  String deleteProjectConfirm(String projectName) {
    return 'क्या आप निश्चित रूप से \"$projectName\" को स्थायी रूप से हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।';
  }

  @override
  String get renameProjectTitle => 'प्रोजेक्ट का नाम बदलें';

  @override
  String get projectNameLabel => 'प्रोजेक्ट का नाम';

  @override
  String get btnCancel => 'रद्द करें';

  @override
  String get btnDelete => 'हटाएं';

  @override
  String get btnRename => 'नाम बदलें';

  @override
  String get btnSave => 'सहेजें';

  @override
  String get btnConfirm => 'पुष्टि करें';

  @override
  String get btnExport => 'निर्यात करें';

  @override
  String get btnUndo => 'पूर्ववत करें';

  @override
  String get btnRedo => 'पुनः करें';

  @override
  String get statusDraft => 'ड्राफ्ट';

  @override
  String get statusCompleted => 'पूरा हुआ';

  @override
  String get createdLabel => 'बनाया गया:';

  @override
  String get durationLabel => 'अवधि:';

  @override
  String get statusLabel => 'स्थिति:';

  @override
  String get settingsTitle => 'सेटिंग्स';

  @override
  String get settingsGeneral => 'सामान्य सेटिंग्स';

  @override
  String get settingsTheme => 'ऐप थीम';

  @override
  String get themeSystem => 'सिस्टम डिफ़ॉल्ट';

  @override
  String get themeLight => 'लाइट मोड';

  @override
  String get themeDark => 'डार्क मोड';

  @override
  String get settingsLanguage => 'ऐप की भाषा';

  @override
  String get settingsTranscription => 'ट्रांसक्रिप्शन सेटिंग्स';

  @override
  String get settingsWhisperModel => 'व्हिस्पर मॉडल';

  @override
  String get settingsWhisperModelDesc =>
      'ट्रांसक्रिप्शन के लिए एक मॉडल चुनें। छोटा तेज़ है; बड़ा अधिक सटीक है।';

  @override
  String get settingsTranscribeLang => 'ट्रांसक्रिप्शन भाषा';

  @override
  String get settingsAutoDetect => 'भाषा का स्वतः पता लगाएं';

  @override
  String get settingsGPU => 'GPU त्वरण (CUDA)';

  @override
  String get settingsVAD => 'VAD थ्रेशोल्ड (वॉयस एक्टिविटी)';

  @override
  String get settingsExport => 'निर्यात सेटिंग्स';

  @override
  String get settingsExportDest => 'डिफ़ॉल्ट निर्यात निर्देशिका';

  @override
  String get settingsBrowse => 'ब्राउज़ करें';

  @override
  String get settingsEmojiPacks => 'इमोजी और स्टाइल पैक';

  @override
  String get settingsEmojiPacksDesc =>
      'इमोजी रेंडरिंग स्टाइल और सक्रिय सबटाइटल्स एसेट्स कस्टमाइज़ करें।';

  @override
  String get settingsEmojiSearchLang => 'इमोजी खोज भाषा';

  @override
  String get settingsBtnManagePacks => 'इमोजी पैक प्रबंधित करें';

  @override
  String get systemTitle => 'सिस्टम जानकारी';

  @override
  String get systemVersion => 'संस्करण';

  @override
  String get systemReset => 'डिफ़ॉल्ट रीसेट करें';

  @override
  String get editorTabCaptions => 'कैप्शन';

  @override
  String get editorTabStyles => 'स्टाइल्स';

  @override
  String get editorTabTrim => 'ट्रिम';

  @override
  String get editorTabAudio => 'ऑडियो';

  @override
  String get editorTabTranscription => 'ट्रांसक्रिप्शन';

  @override
  String get editorTabShortcuts => 'शॉर्टकट';

  @override
  String get editorTabDebug => 'डीबग';

  @override
  String get editorHeaderBack => 'पीछे';

  @override
  String get editorKeyboardShortcuts => 'कीबोर्ड शॉर्टकट';

  @override
  String get dialogAnalyzing => 'वीडियो का विश्लेषण किया जा रहा है...';

  @override
  String get dialogTranscribing => 'ऑडियो ट्रांसक्राइब किया जा रहा है...';

  @override
  String get dialogExtracting => 'ऑडियो निकाला जा रहा है...';

  @override
  String get dialogWait => 'इसमें कुछ समय लग सकता है। कृपया प्रतीक्षा करें।';

  @override
  String get dialogError => 'त्रुटि';

  @override
  String get dialogImportFailed => 'वीडियो आयात करने में विफल।';

  @override
  String get noProjects => 'अभी तक कोई प्रोजेक्ट नहीं बनाया गया है';

  @override
  String get aboutApp => 'कैपस्टूडियो के बारे में';

  @override
  String get aboutAppDesc =>
      'कैपस्टूडियो, क्रेडिट और ओपन-सोर्स लाइसेंस के बारे में बताएं।';

  @override
  String get aboutAppThanks =>
      'उन ओपन-सोर्स प्रोजेक्ट्स को विशेष धन्यवाद जो कैपस्टूडियो को संभव बनाते हैं:';

  @override
  String get btnViewAllLicenses => 'सभी पैकेज लाइसेंस देखें';

  @override
  String get exportBurnIn => 'वीडियो में टेक्स्ट जलाकर (बर्न-इन) निर्यात';

  @override
  String get exportTimecodeFormats => 'टाइमकोड सबटाइटल फ़ॉर्मेट';

  @override
  String get exportWebEnabled =>
      'क्लाइंट-साइड वीडियो निर्यात सक्षम है। रेंडरिंग आपके ब्राउज़र में स्थानीय रूप से चलती है।';

  @override
  String get exportWebCaptionOnly =>
      'वेब निर्यात में फ़िलहाल केवल सबटाइटल शामिल हैं — इमोजी और ध्वनि प्रभाव अभी वीडियो में नहीं जलाए गए हैं। पूरा परिणाम पाने के लिए डेस्कटॉप या मोबाइल ऐप से निर्यात करें।';

  @override
  String get exportOutputName => 'आउटपुट वीडियो का नाम';

  @override
  String get exportMode => 'निर्यात मोड';

  @override
  String get exportModeFast => 'तेज़ (नेटिव FFmpeg)';

  @override
  String get exportModeFastUnsupported => 'तेज़ (नेटिव FFmpeg) ⚠️ समर्थित नहीं';

  @override
  String get exportModeSlow => 'धीमा (1:1 प्रीव्यू रेंडर)';

  @override
  String get exportTargetFps => 'लक्ष्य FPS';

  @override
  String get exportFps24 => '24 FPS (फ़िल्म)';

  @override
  String get exportFps25 => '25 FPS (PAL)';

  @override
  String get exportFps30 => '30 FPS (मानक)';

  @override
  String get exportFps50 => '50 FPS';

  @override
  String get exportFps60 => '60 FPS (स्मूद)';

  @override
  String get exportFastUnsupported =>
      'इस डिवाइस पर फ़ास्ट मोड समर्थित नहीं है क्योंकि सिस्टम FFmpeg बिल्ड में सबटाइटल रेंडरिंग फ़िल्टर (libass) नहीं है। इसके बजाय स्लो मोड का उपयोग किया जाएगा।';

  @override
  String get exportSlowInfo =>
      'प्रत्येक फ्रेम को बिल्कुल वैसे ही कैप्चर करता है जैसे प्रीव्यू में दिखता है। यह पिक्सेल-परफेक्ट सबटाइटल सुनिश्चित करता है, लेकिन रेंडरिंग धीमी होती है।';

  @override
  String get exportDestDirectory => 'गंतव्य निर्देशिका';

  @override
  String get exportDestBrowser => 'ब्राउज़र डाउनलोड स्थान';

  @override
  String get exportDestAndroid =>
      'डाउनलोड फ़ोल्डर (/storage/emulated/0/Download)';

  @override
  String get exportDestIos => 'ऐप दस्तावेज़ (निर्यात के बाद शेयर शीट)';

  @override
  String get exportChooseFolder => 'आउटपुट फ़ोल्डर चुनें';

  @override
  String get exportStartMp4 => 'MP4 निर्यात शुरू करें';

  @override
  String get exportSrtTitle => 'SubRip सबटाइटल (.srt)';

  @override
  String get exportSrtDesc =>
      'टाइमकोड वाला सार्वभौमिक मानक। YouTube, VLC और Premiere Pro के साथ संगत।';

  @override
  String get exportVttTitle => 'WebVTT सबटाइटल (.vtt)';

  @override
  String get exportVttDesc =>
      'वेब-अनुकूलित सबटाइटल फ़ॉर्मेट, जो HTML5 प्लेयर और ऑनलाइन स्ट्रीमिंग में व्यापक रूप से उपयोग होता है।';

  @override
  String get exportAssTitle => 'Advanced SubStation Alpha (.ass)';

  @override
  String get exportAssDesc =>
      'पेशेवर फ़ॉर्मेट जिसमें फ़ॉन्ट आकार, शैलियाँ, मार्जिन और इनलाइन हाइलाइट शामिल होते हैं।';

  @override
  String get exportTxtTitle => 'सादा टेक्स्ट ट्रांसक्रिप्ट (.txt)';

  @override
  String get exportTxtDesc =>
      'टाइमस्टैम्प उपसर्ग चिह्नों के साथ पंक्ति-दर-पंक्ति ट्रांसक्रिप्ट।';

  @override
  String exportSuccess(String type) {
    return '$type सफलतापूर्वक निर्यात हो गया!';
  }

  @override
  String get exportNoLocation =>
      'कोई सेव स्थान चयनित नहीं है। कृपया फ़ाइल पथ चुनें।';

  @override
  String get exportNoLocationCancelled =>
      'कोई सेव स्थान चयनित नहीं है। निर्यात रद्द कर दिया गया।';

  @override
  String exportFailed(String error) {
    return 'निर्यात विफल: $error';
  }

  @override
  String get exportCopySrtTooltip => 'SRT को क्लिपबोर्ड पर कॉपी करें';

  @override
  String get exportCopiedSrt => 'SRT क्लिपबोर्ड पर कॉपी हो गया!';

  @override
  String exportCopyFailedSrt(String error) {
    return 'SRT कॉपी करने में विफल: $error';
  }

  @override
  String exportSubtitlesDialogTitle(String type) {
    return '$type सबटाइटल निर्यात करें';
  }

  @override
  String get exportVideoDialogTitle => 'वीडियो MP4 निर्यात करें';

  @override
  String get ffmpegRequiredTitle => 'FFmpeg आवश्यक है';

  @override
  String get ffmpegRequiredBody =>
      'वीडियो फ़ाइल में सबटाइटल जलाने के लिए FFmpeg की स्थानीय स्थापना आवश्यक है।\n\nकृपया सेटिंग्स में FFmpeg पथ कॉन्फ़िगर करें।';

  @override
  String get okLabel => 'ठीक है';

  @override
  String get exportWebTitle => 'वीडियो निर्यात हो रहा है (क्लाइंट-साइड)';

  @override
  String exportWebSuccess(String fileName) {
    return 'वीडियो $fileName के रूप में सफलतापूर्वक निर्यात हो गया!';
  }

  @override
  String exportWebFailed(String error) {
    return 'रेंडरिंग विफल: $error';
  }

  @override
  String get viralShortsTitle => 'वायरल शॉर्ट्स स्टूडियो';

  @override
  String get viralShortsSubtitle =>
      '9:16 वर्टिकल रीफ्रेम, साइलेंस जंप-कट्स और एआई हुक डिटेक्टर';

  @override
  String get viralReframeTitle => '1. वर्टिकल 9:16 रीफ्रेम';

  @override
  String get viralSilenceTitle => '2. साइलेंस हटाना (जंप-कट्स)';

  @override
  String get viralHooksTitle => '3. एआई वायरल हुक डिटेक्टर';

  @override
  String get btnFindViralMoments => 'वायरल मोमेंट्स खोजें';

  @override
  String get btnScanSilences => 'साइलेंस स्कैन करें';

  @override
  String get btnApplyJumpCuts => 'जंप-कट्स लागू करें';

  @override
  String get editorTabShorts => 'शॉर्ट्स';

  @override
  String get editorTabClips => 'क्लिप्स';

  @override
  String get captionList => 'कैप्शन सूची';

  @override
  String get uncertainLabel => 'अनिश्चित (<40%)';

  @override
  String get mediumConfidenceLabel => 'मध्यम (40-60%)';

  @override
  String get jumpToUncertain => 'अगले अनिश्चित शब्द पर जाएं';

  @override
  String get noUncertainWords => 'कोई अनिश्चित शब्द नहीं मिला।';

  @override
  String get findAndReplace => 'खोजें और बदलें';

  @override
  String get addWordTitle => 'शब्द जोड़ें';

  @override
  String get editWordTitle => 'शब्द संपादित करें';

  @override
  String get wordTextLabel => 'शब्द का पाठ';

  @override
  String get startTimeLabel => 'प्रारंभ समय (सेकंड)';

  @override
  String get endTimeLabel => 'समाप्ति समय (सेकंड)';

  @override
  String get splitChunk => 'भाग विभाजित करें';

  @override
  String get insertLineAfter => 'बाद में पंक्ति जोड़ें';

  @override
  String get duplicateLine => 'पंक्ति की प्रतिलिपि बनाएँ';

  @override
  String get deleteLine => 'पंक्ति हटाएं';

  @override
  String get chooseSfxTitle => 'ध्वनि प्रभाव चुनें';

  @override
  String get searchSfxPlaceholder => 'ध्वनि प्रभाव खोजें...';

  @override
  String get noSfxFound => 'कोई ध्वनि प्रभाव नहीं मिला';

  @override
  String get emojiSearch => 'इमोजी खोजें';

  @override
  String get noEmojisFound => 'कोई इमोजी नहीं मिला।';

  @override
  String get mySavedPresets => 'मेरे सहेजे गए प्रीसेट्स';

  @override
  String get btnImport => 'आयात करें';

  @override
  String get btnExportCaps => 'निर्यात करें';

  @override
  String get btnSaveCurrent => 'वर्तमान सहेजें';

  @override
  String get resetToDefault => 'डिफ़ॉल्ट पर रीसेट करें';

  @override
  String get resetConfirmBody =>
      'यह सभी कैप्शन शैलियों को डिफ़ॉल्ट पर रीसेट कर देगा। इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get btnReset => 'रीसेट करें';

  @override
  String get wordHighlightBox => 'शब्द हाइलाइट बॉक्स';

  @override
  String get wordHighlightBoxDesc =>
      'सक्रिय बोले जाने वाले शब्दों के पीछे रंगीन पिल पृष्ठभूमि';

  @override
  String get maxWordsPerChunk => 'प्रति सबटाइटल चंक अधिकतम शब्द';

  @override
  String get maxCharsPerLine => 'प्रति सबटाइटल पंक्ति अधिकतम वर्ण';

  @override
  String get fontSettings => 'फ़ॉन्ट सेटिंग्स';

  @override
  String get colorSettings => 'रंग सेटिंग्स';

  @override
  String get borderSettings => 'बॉर्डर और शैडो सेटिंग्स';

  @override
  String get speechToTextTitle => 'स्पीच-टू-टेक्स्ट ट्रांसक्रिप्शन';

  @override
  String get speechToTextDesc =>
      'स्थानीय स्पीच-टू-टेक्स्ट ट्रांसक्रिप्शन पुनः चलाएं। कोई भी मैन्युअल संपादन या टाइमिंग ऑफसेट बदल दिए जाएंगे।';

  @override
  String get useLocalAi => 'स्थानीय AI ट्रांसक्रिप्शन का उपयोग करें';

  @override
  String get runOnDeviceDesc => 'सीधे इस डिवाइस पर स्पीच-टू-टेक्स्ट चलाएं';

  @override
  String get offlineDemoModeActive =>
      'ऑफलाइन डेमो मोड सक्रिय है। वेब पर स्थानीय Whisper AI ट्रांसक्रिप्शन समर्थित नहीं है।';

  @override
  String get demoModeNote =>
      'डेमो मोड तुरंत अत्यधिक यथार्थवादी ट्रांसक्रिप्ट टोकन उत्पन्न करता है। बिना सेटअप के शैलियों, टेम्पलेट्स और टाइमलाइन संचालन का परीक्षण करने के लिए उपयुक्त।';

  @override
  String get transcriptionQuality => 'ट्रांसक्रिप्शन गुणवत्ता';

  @override
  String get advancedSettings => 'उन्नत सेटिंग्स';

  @override
  String get cpuThreadsLabel => 'CPU थ्रेड्स';

  @override
  String get vadSensitivity => 'VAD संवेदनशीलता';

  @override
  String get translateToEnglish => 'कैप्शन का अंग्रेजी में अनुवाद करें';

  @override
  String get startTranscriptionBtn => 'ट्रांसक्रिप्शन शुरू करें';

  @override
  String get hardwareLocked => 'हार्डवेयर लॉक है';

  @override
  String get btnDownload => 'डाउनलोड करें';

  @override
  String get welcomeTitle => 'CapStudio में आपका स्वागत है';

  @override
  String get welcomeSubtitle =>
      'उच्च सटीकता वाले कैप्शन और वायरल शॉर्ट्स, 100% ऑफ़लाइन।';

  @override
  String get setupAssetDirTitle => 'एसेट निर्देशिका चुनें';

  @override
  String get setupAssetDirDesc =>
      'मॉडल, फ़ॉन्ट और इमोजी पैक संग्रहीत करने के लिए एक निर्देशिका चुनें।';

  @override
  String get downloadPacksTitle => 'सामग्री पैक डाउनलोड करें (वैकल्पिक)';

  @override
  String get downloadPacksDesc =>
      'आपके वीडियो प्रोजेक्ट्स के लिए वैकल्पिक फ़ॉन्ट और ध्वनि प्रभाव।';

  @override
  String get setupCompleteTitle => 'सेटअप पूरा हुआ';

  @override
  String get setupCompleteDesc =>
      'अब आप शानदार कैप्शन वाले वीडियो बनाने के लिए तैयार हैं।';

  @override
  String get btnGetStarted => 'शुरू करें';

  @override
  String get btnNext => 'आगे बढ़ें';

  @override
  String get btnSkip => 'छोड़ें';

  @override
  String get onboardingFeaturePrivacy => '100% गोपनीयता';

  @override
  String get onboardingFeaturePrivacyDesc =>
      'आपकी फ़ाइलें कभी भी आपके डिवाइस से बाहर नहीं जातीं। सभी AI मॉडल स्थानीय रूप से चलते हैं।';

  @override
  String get onboardingFeatureGpu => 'GPU त्वरित प्लेबैक';

  @override
  String get onboardingFeatureGpuDesc =>
      'हार्डवेयर डिकोडिंग का उपयोग करके उच्च प्रदर्शन वाला वीडियो संपादन।';

  @override
  String get onboardingFeatureAssets => 'ऑफ़लाइन साइडकार एसेट्स';

  @override
  String get onboardingFeatureAssetsDesc =>
      'समृद्ध इमोजी पैक एक बार डाउनलोड करें और पूरी तरह से ऑफ़लाइन चलाएं।';

  @override
  String get onboardingReadyTitle => 'आप शुरुआत के लिए तैयार हैं!';

  @override
  String get onboardingConfigDetails => 'कॉन्फ़िगरेशन विवरण:';

  @override
  String get btnLaunchCapStudio => 'CapStudio लॉन्च करें';

  @override
  String get assetVerificationFailed =>
      'एसेट सत्यापन विफल रहा। कृपया सुनिश्चित करें कि एसेट्स ठीक से डाउनलोड हो गए हैं।';

  @override
  String get assetsFolderNotFound => 'एसेट फ़ोल्डर नहीं मिला';

  @override
  String get assetsFolderNotFoundDesc =>
      'CapStudio कॉन्फ़िगर किए गए स्थान पर एसेट फ़ोल्डर खोजने में असमर्थ रहा। यदि फ़ोल्डर किसी बाहरी ड्राइव पर है, तो कृपया उसे कनेक्ट करें।';

  @override
  String get expectedPathLabel => 'अपेक्षित पथ:';

  @override
  String get browseNewLocation => 'नया स्थान ब्राउज़ करें';

  @override
  String get resetToDefaultPath => 'डिफ़ॉल्ट पथ पर रीसेट करें';

  @override
  String get retryVerification => 'सत्यापन पुनः प्रयास करें';

  @override
  String get storagePathFolder => 'स्टोरेज पथ फ़ोल्डर';

  @override
  String get tipWindowsDrive =>
      'सुझाव: यदि C: ड्राइव छोटी है, तो अधिक स्थान के लिए D: या E: पर पथ चुनें।';

  @override
  String get tipGeneralDrive =>
      'सुझाव: यदि आपका रूट वॉल्यूम भर गया है तो आप बाहरी ड्राइव पथ चुन सकते हैं।';

  @override
  String get confirmLocation => 'स्थान की पुष्टि करें';

  @override
  String get requiredBadge => 'आवश्यक';

  @override
  String get emojiPacksHeader => 'इमोजी पैक';

  @override
  String get fontPacksHeader => 'फ़ॉन्ट पैक';

  @override
  String get connectCliTitle => 'स्थानीय CLI टूल्स कनेक्ट करें';

  @override
  String get connectCliDesc =>
      'CapStudio को स्थानीय रूप से ट्रांसक्रिप्शन करने और वीडियो निर्यात करने के लिए whisper.cpp और FFmpeg बाइनरी की आवश्यकता होती है।';

  @override
  String get skipSetup => 'अभी के लिए सेटअप छोड़ें';

  @override
  String get btnValidate => 'सत्यापित करें';

  @override
  String get autoDetectAndValidate => 'स्वतः पता लगाएं और सत्यापित करें';

  @override
  String get whisperCliPathLabel => 'Whisper CLI निष्पादन योग्य पथ';

  @override
  String get ffmpegCliPathLabel => 'FFmpeg CLI निष्पादन योग्य पथ';

  @override
  String get newProject => 'नया प्रोजेक्ट';

  @override
  String get searchProjects => 'प्रोजेक्ट्स खोजें...';

  @override
  String get filterAll => 'सभी';

  @override
  String get sortByRecent => 'सबसे हाल का';

  @override
  String get sortByDuration => 'अवधि';

  @override
  String get noMatchingProjects =>
      'आपकी खोज से मेल खाने वाला कोई प्रोजेक्ट नहीं है';

  @override
  String get btnEdit => 'संपादित करें';

  @override
  String get btnDuplicate => 'प्रतिलिपि बनाएँ';

  @override
  String get tooltipEdit => 'संपादित करें';

  @override
  String get tooltipRename => 'नाम बदलें';

  @override
  String get tooltipDuplicate => 'प्रतिलिपि बनाएँ';

  @override
  String get tooltipDelete => 'हटाएं';

  @override
  String get tooltipTheme => 'थीम';

  @override
  String get tooltipSettings => 'सेटिंग्स';

  @override
  String get selectDemoFormat => 'डेमो फ़ॉर्मेट चुनें';

  @override
  String get selectDemoDesc =>
      'CapStudio के उच्च-सटीक कैप्शन इंजन, लाइव शब्द-स्तरीय एनिमेशन और ऑडियो वेवफॉर्म का तुरंत पूर्वावलोकन करने के लिए एक लेआउट प्रारूप चुनें।';

  @override
  String get landscapeDemo => 'लैंडस्केप डेमो';

  @override
  String get landscapeDemoDesc =>
      'YouTube, डेस्कटॉप और प्रस्तुतियों के लिए बिल्कुल सही।';

  @override
  String get portraitDemo => 'पोर्ट्रेट डेमो';

  @override
  String get portraitDemoDesc =>
      'TikTok, Shorts, Reels और मोबाइल के लिए आदर्श।';

  @override
  String get format16x9 => '16:9 फ़ॉर्मेट';

  @override
  String get format9x16 => '9:16 फ़ॉर्मेट';

  @override
  String get dropVideoHere => 'वीडियो यहाँ छोड़ें';

  @override
  String get dropVideoSupported => 'MP4, MOV, AVI आदि का समर्थन करता है';

  @override
  String get statusLocalOffline => 'स्थानीय ऑफ़लाइन';

  @override
  String get speechModelTitle => 'वाक् पहचान मॉडल';

  @override
  String get hardwareUpgradesTitle => 'हार्डवेयर प्रदर्शन अपग्रेड';

  @override
  String get showAdvancedPaths => 'उन्नत पथ कॉन्फ़िगरेशन दिखाएं';

  @override
  String get hideAdvancedPaths => 'उन्नत पथ कॉन्फ़िगरेशन छुपाएं';

  @override
  String get autoDownload => 'स्वतः डाउनलोड';

  @override
  String get gpuAcceleratedTranscription => 'GPU त्वरित ट्रांसक्रिप्शन (CUDA)';

  @override
  String get gpuRequiresNvidia => 'CUDA संगतता वाले NVIDIA GPU की आवश्यकता है';

  @override
  String get gpuExportEncoder => 'GPU निर्यात एनकोडर';

  @override
  String get gpuExportEncoderDesc =>
      'MP4 वीडियो निर्यात के लिए हार्डवेयर त्वरण';

  @override
  String get defaultLanguage => 'डिफ़ॉल्ट भाषा';

  @override
  String get vadTitle => 'वॉयस एक्टिविटी डिटेक्शन (VAD)';

  @override
  String get vadDesc => 'प्रसंस्करण के दौरान शांत भागों को छोड़ देता है';

  @override
  String get vadThreshold => 'VAD थ्रेशोल्ड';

  @override
  String get autoSaveTitle => 'स्वचालित ऑटो-सेव';

  @override
  String get autoSaveDesc =>
      'हर 3 सेकंड में प्रोजेक्ट संपादनों को डेटाबेस में स्वचालित रूप से सहेजें';

  @override
  String get defaultOutputsTitle => 'डिफ़ॉल्ट आउटपुट';

  @override
  String get defaultExportFolder => 'डिफ़ॉल्ट निर्यात फ़ोल्डर';

  @override
  String get alwaysAskExportPath => 'हमेशा निर्यात पथ पूछें';

  @override
  String get alwaysAskExportPathDesc =>
      'प्रत्येक निर्यात पर आउटपुट पथ के लिए संकेत दें (डेस्कटॉप)';

  @override
  String get performanceTitle => 'प्रदर्शन';

  @override
  String get exportCpuThreads => 'निर्यात CPU थ्रेड्स';

  @override
  String get exportCpuThreadsDesc =>
      'रेंडरिंग के लिए उपयोग किए जाने वाले प्रोसेसर थ्रेड्स (डिवाइस के अनुसार सुरक्षित रूप से स्वतः स्केल होते हैं)';

  @override
  String get aboutAppSubtitle =>
      '100% ऑफ़लाइन, गोपनीयता-प्रथम AI कैप्शनिंग और सबटाइटल स्टूडियो';

  @override
  String get openSourceLicenses => 'ओपन सोर्स लाइसेंस';

  @override
  String get openSourceComplianceDesc =>
      'CapStudio कई अन्य ओपन-सोर्स लाइब्रेरी पर निर्भर करता है। कानूनी स्टोर अनुपालन के लिए सभी Dart पैकेज, निर्भरताओं और पूर्ण लाइसेंस ग्रंथों की एक पूरी सूची नीचे संकलित है।';

  @override
  String get visitWebsite => 'वेबसाइट पर जाएं';

  @override
  String get btnContinue => 'जारी रखें';

  @override
  String get btnBack => 'वापस';

  @override
  String get editTiming => 'समय संपादित करें';

  @override
  String get wordSettingsTitle => 'शब्द सेटिंग्स';

  @override
  String get emojiSettingsTitle => 'इमोजी सेटिंग्स';

  @override
  String get changeEmojiTooltip => 'इमोजी बदलें';

  @override
  String get searchEmojisHint => 'इमोजी खोजें...';

  @override
  String emojiPosX(String offset) {
    return 'इमोजी स्थिति (X ऑफसेट: ${offset}px)';
  }

  @override
  String emojiPosY(String offset) {
    return 'इमोजी स्थिति (Y ऑफसेट: ${offset}px)';
  }

  @override
  String emojiScale(String scale) {
    return 'इमोजी स्केल (${scale}x)';
  }

  @override
  String emojiAnimSpeed(String speed) {
    return 'एनीमेशन गति (${speed}x)';
  }

  @override
  String get emojiStylePack => 'इमोजी स्टाइल / पैक';

  @override
  String get selectStylePackTooltip => 'स्टाइल पैक चुनें';

  @override
  String get selectEmojiTitle => 'इमोजी चुनें';

  @override
  String get stylePackLabel => 'स्टाइल पैक';

  @override
  String get searchHint => 'खोजें...';

  @override
  String get btnCreateProject => 'प्रोजेक्ट बनाएं';

  @override
  String get btnChooseFile => 'फ़ाइल चुनें';

  @override
  String get selectSubtitleFile => 'सबटाइटल फ़ाइल चुनें';

  @override
  String get selectTranscriptionQuality => 'ट्रांसक्रिप्शन गुणवत्ता चुनें';

  @override
  String get translateToEnglishDesc =>
      'विदेशी भाषण को सीधे अंग्रेजी सबटाइटल में बदलें';

  @override
  String get hardwareSettings => 'हार्डवेयर और प्रदर्शन सेटिंग्स';

  @override
  String get styleTemplatesHeader => 'स्टाइल टेम्पलेट्स';

  @override
  String get resetToDefaultStyle => 'डिफ़ॉल्ट स्टाइल पर रीसेट करें';

  @override
  String get resetStylingTitle => 'स्टाइलिंग रीसेट करें?';

  @override
  String get resetStylingDesc =>
      'यह सभी कैप्शन शैलियों को डिफ़ॉल्ट पर रीसेट कर देगा। इसे पूर्ववत नहीं किया जा सकता।';

  @override
  String get sizeAndPosition => 'आकार और स्थिति';

  @override
  String get verticalYPos => 'लंबवत Y स्थिति (%)';

  @override
  String get fontConfigHeader => 'फ़ॉन्ट कॉन्फ़िगरेशन';

  @override
  String get fontFamilyLabel => 'फ़ॉन्ट फ़ैमिली';

  @override
  String get btnImportCustomFont => 'कस्टम फ़ॉन्ट आयात करें (.ttf / .otf)';

  @override
  String get fontWeightLabel => 'फ़ॉन्ट वेट';

  @override
  String get textCaseLabel => 'टेक्स्ट केस';

  @override
  String get fontSizeLabel => 'फ़ॉन्ट आकार';

  @override
  String get letterSpacingLabel => 'अक्षरों के बीच का स्थान';

  @override
  String get lineHeightLabel => 'पंक्ति की ऊंचाई';

  @override
  String get onboardingAppTagline => '100% ऑफ़लाइन स्थानीय AI कैप्शन संपादक';

  @override
  String get configLabelWhisperCli => 'Whisper CLI';

  @override
  String get configValueDemoMode => 'डेमो मोड (मॉक)';

  @override
  String get configLabelFfmpegCli => 'FFmpeg CLI';

  @override
  String get configValueSystemPathDefault => 'सिस्टम PATH डिफ़ॉल्ट';

  @override
  String get configLabelAssetsLocation => 'एसेट का स्थान';

  @override
  String get filePickerAssetsDialogTitle => 'CapStudio एसेट फ़ोल्डर चुनें';

  @override
  String errorSelectFolderFailed(String error) {
    return 'फ़ोल्डर चुनने में विफल: $error';
  }

  @override
  String errorResetFailed(String error) {
    return 'रीसेट करने में विफल: $error';
  }

  @override
  String errorVerificationFailed(String error) {
    return 'सत्यापन विफल रहा: $error';
  }

  @override
  String errorAssetsFolderStillMissing(String path) {
    return 'एसेट फ़ोल्डर अभी भी यहाँ नहीं मिला: $path';
  }

  @override
  String get dbRecoveredTitle =>
      'डेटाबेस स्वचालित रूप से पुनर्प्राप्त किया गया';

  @override
  String dbRecoveredBody(String backupPath) {
    return 'डेटाबेस स्कीमा बेमेल या डेटा करप्शन का पता चला था। डेटाबेस को रीसेट कर दिया गया था, और आपके पिछले डेटा का बैकअप यहाँ लिया गया था:\n\n$backupPath';
  }

  @override
  String errorDemoLoadFailed(String error) {
    return 'डेमो वीडियो लोड करने में विफल: $error';
  }

  @override
  String importProgressPercent(int percent) {
    return '$percent% पूरा हुआ';
  }

  @override
  String get errorInvalidDropFileFormat =>
      'अमान्य फ़ाइल प्रारूप। कृपया एक वीडियो फ़ाइल छोड़ें।';

  @override
  String get findTextLabel => 'टेक्स्ट खोजें';

  @override
  String get replaceWithLabel => 'इससे बदलें';

  @override
  String findReplaceSuccessCount(int count) {
    return '$count बार बदला गया!';
  }

  @override
  String get btnReplaceAll => 'सभी बदलें';

  @override
  String errorVideoFileNotFound(String path) {
    return 'वीडियो फ़ाइल नहीं मिली:\n$path\nकृपया वीडियो फ़ाइल को फिर से लिंक करें।';
  }

  @override
  String get errorTranscriptionFailed =>
      'ट्रांसक्रिप्शन विफल रहा। कृपया पुन: प्रयास करें।';

  @override
  String transcriptionActiveModel(String quality, String model) {
    return 'सक्रिय: $quality ($model)';
  }

  @override
  String get badgeRecommended => 'सुझाया गया';

  @override
  String get languageLabel => 'भाषा';

  @override
  String warningEnglishOnlyModel(String model, String language) {
    return 'चेतावनी: चयनित मॉडल ($model) केवल अंग्रेज़ी समर्थित है। \"$language\" में ट्रांसक्राइब करना विफल हो जाएगा या अंग्रेज़ी कैप्शन उत्पन्न करेगा। कृपया एक बहुभाषी मॉडल चुनें (जैसे Tiny या Base)।';
  }

  @override
  String get tipAutoDetectMixedLanguage =>
      'सुझाव: मिश्रित भाषाओं (जैसे हिंग्लिश) के लिए ऑटो-डिटेक्ट की अनुशंसा नहीं की जाती है। अपनी बोली जाने वाली भाषा (जैसे हिंदी या अंग्रेजी) को स्पष्ट रूप से चुनने से अधिक सटीक कैप्शन मिलेंगे।';

  @override
  String get detectedHardwareLabel => 'पहचाना गया सिस्टम हार्डवेयर:';

  @override
  String hardwareRamSize(String ramGB) {
    return 'RAM का आकार: $ramGB GB';
  }

  @override
  String hardwareCpuCores(int cores) {
    return 'CPU लॉजिकल कोर: $cores';
  }

  @override
  String hardwareGpuDevice(String gpu) {
    return 'GPU डिवाइस: $gpu';
  }

  @override
  String get hardwareDetecting => 'हार्डवेयर स्थिति का पता लगाया जा रहा है...';

  @override
  String get btnStartReTranscribe => 'पुनः ट्रांसक्रिप्शन शुरू करें';

  @override
  String get btnImportSrtVtt => 'SRT/VTT फ़ाइल आयात करें';

  @override
  String importedSubtitleWords(int count) {
    return 'सबटाइटल फ़ाइल से $count शब्द आयात किए गए।';
  }

  @override
  String get errorImportSubtitleFailed =>
      'सबटाइटल फ़ाइल आयात करने में विफल। कृपया फ़ाइल फ़ॉर्मेट की जाँच करें।';

  @override
  String get noProjectLoaded => 'कोई प्रोजेक्ट लोड नहीं हुआ';

  @override
  String get badge916Vertical => '9:16 वर्टिकल';

  @override
  String get badge169Landscape => '16:9 लैंडस्केप';

  @override
  String get reframeTargetCanvas =>
      'लक्ष्य कैनवास: 1080 × 1920 (TikTok, YouTube Shorts, Instagram Reels)';

  @override
  String get reframeModeLabel => 'रीफ्रेम मोड:';

  @override
  String get reframeModeBlurPillarbox => 'ब्लर पिलरबॉक्स (सुझाया गया)';

  @override
  String get reframeModeBlurPillarboxDesc =>
      '9:16 स्क्रीन भरने के लिए पृष्ठभूमि में वीडियो को स्केल और ब्लर करता है, जबकि केंद्र का वीडियो स्पष्ट रहता है।';

  @override
  String get reframeModeCenterCrop => 'सेंटर स्मार्ट क्रॉप';

  @override
  String get reframeModeCenterCropDesc =>
      'बाएं और दाएं किनारों को क्रॉप करके पूरी 9:16 स्क्रीन भरता है।';

  @override
  String get reframeModeSplitScreen => 'स्प्लिट स्क्रीन / डुअल लेयर';

  @override
  String get reframeModeSplitScreenDesc =>
      'दो वीडियो विंडो को लंबवत रूप से रखता है (प्रतिक्रियाओं और पॉडकास्ट बातचीत के लिए आदर्श)।';

  @override
  String get btnResetTo169 => 'वर्तमान में 9:16 (16:9 पर रीसेट करें)';

  @override
  String get btnSetCanvas916 => 'प्रोजेक्ट कैनवास को 9:16 पर सेट करें';

  @override
  String get silenceRemovalDesc =>
      'वीडियो प्रतिधारण को अधिकतम करने के लिए स्वचालित रूप से शांत अंतराल और सांस लेने के ठहराव को काटता है।';

  @override
  String get silenceAggressivenessLabel => 'कट आक्रामकता:';

  @override
  String silenceNoiseGateLabel(int db) {
    return 'साइलेंस नॉइज़ गेट: $db dB';
  }

  @override
  String silenceMinPauseLabel(String duration) {
    return 'न्यूनतम ठहराव: ${duration}s';
  }

  @override
  String get btnScanning => 'स्कैनिंग जारी है...';

  @override
  String silenceNoneFound(String duration) {
    return '${duration}s से अधिक का कोई साइलेंस अंतराल नहीं मिला।';
  }

  @override
  String silenceFoundCount(int count, String totalSecs) {
    return '$count साइलेंस मिले (${totalSecs}s का खाली समय बचाया गया)!';
  }

  @override
  String errorScanningAudio(String error) {
    return 'ऑडियो स्कैन करने में त्रुटि: $error';
  }

  @override
  String jumpCutsApplied(int count) {
    return 'प्रोजेक्ट टाइमलाइन पर $count जंप-कट लागू किए गए!';
  }

  @override
  String get viralHooksDesc =>
      '80+ वायरल हुक, गति (120–170 WPM), प्रश्न, ऊर्जा घनत्व और क्लिप सीमाओं के लिए ट्रांसक्रिप्शन शब्दों को स्कैन करता है।';

  @override
  String get btnAnalyzingTranscript =>
      'ट्रांसक्रिप्ट का विश्लेषण किया जा रहा है...';

  @override
  String get selectAllLabel => 'सभी चुनें';

  @override
  String selectedCountOf(int selected, int total) {
    return '$total में से $selected चयनित';
  }

  @override
  String get btnSelectClipsToBatchExport => 'बैच निर्यात के लिए क्लिप चुनें';

  @override
  String btnBatchExportCount(int count) {
    return '$count क्लिप का बैच निर्यात करें';
  }

  @override
  String get viralNoClipsDetected =>
      'इस वीडियो अवधि सीमा में कोई उच्च स्कोरिंग वायरल क्लिप नहीं मिली।';

  @override
  String get badgeCleanCut => 'क्लीन कट';

  @override
  String get badgeFirst5s => 'पहले 5 सेकंड';

  @override
  String get btnPreview => 'पूर्वावलोकन';

  @override
  String get btnTrim => 'ट्रिम करें';

  @override
  String get tooltipForkAs916 =>
      'नए 9:16 शॉर्ट प्रोजेक्ट के रूप में विभाजित करें';

  @override
  String wpmLabelOk(int wpm) {
    return '$wpm WPM ✓';
  }

  @override
  String wpmLabelFast(int wpm) {
    return '$wpm WPM तेज़';
  }

  @override
  String wpmLabelSlow(int wpm) {
    return '$wpm WPM धीमा';
  }

  @override
  String hookScoreLabel(int score) {
    return 'हुक $score/40';
  }

  @override
  String energyScoreLabel(int score) {
    return 'ऊर्जा $score/20';
  }

  @override
  String get filePickerClipsFolderTitle =>
      'क्लिप्स सहेजने के लिए फ़ोल्डर चुनें';

  @override
  String get errorChooseOutputFolderFirst =>
      'कृपया पहले एक आउटपुट फ़ोल्डर चुनें।';

  @override
  String batchExportSheetTitle(int count) {
    return '$count क्लिप का बैच निर्यात करें';
  }

  @override
  String get tapToChooseOutputFolder => 'आउटपुट फ़ोल्डर चुनने के लिए टैप करें…';

  @override
  String get burnCaptionsOnClipsLabel => 'क्लिप पर गतिशील कैप्शन बर्न करें';

  @override
  String get burnCaptionsOnClipsDesc =>
      'क्लिप ऑडियो के साथ सिंक किए गए स्टाइल वाले एनिमेटेड सबटाइटल बर्न करता है';

  @override
  String exportCancelledProgress(int done, int total) {
    return 'निर्यात रद्द कर दिया गया। $done/$total पूर्ण।';
  }

  @override
  String exportProgressSummary(int done, int total, int failed) {
    return '$done/$total निर्यात किए गए · $failed विफल';
  }

  @override
  String get btnExporting => 'निर्यात हो रहा है…';

  @override
  String get btnExportComplete => 'निर्यात पूरा हुआ ✓';

  @override
  String get btnStartExport => 'निर्यात शुरू करें';

  @override
  String exportClipSavedAt(String path) {
    return '✓ सहेजा गया: $path';
  }

  @override
  String projectTrimmedToClip(int rank, String start, String end) {
    return 'प्रोजेक्ट को वायरल क्लिप #$rank ($start - $end) पर ट्रिम किया गया!';
  }

  @override
  String shortProjectCreated(String name) {
    return '9:16 शॉर्ट बनाया गया: \"$name\"';
  }

  @override
  String get btnOpen => 'खोलें';

  @override
  String errorCreateShortProjectFailed(String error) {
    return 'शॉर्ट प्रोजेक्ट बनाने में विफल: $error';
  }

  @override
  String get autoDetect => 'स्वतः पता लगाएं';

  @override
  String presetSaved(String name) {
    return 'स्टाइल प्रीसेट \"$name\" सफलतापूर्वक सहेजा गया!';
  }

  @override
  String get presetDeleted => 'प्रीसेट सफलतापूर्वक हटा दिया गया।';

  @override
  String get presetExported => 'स्टाइल प्रीसेट्स सफलतापूर्वक निर्यात किए गए!';

  @override
  String errorPresetExportFailed(String error) {
    return 'प्रीसेट्स निर्यात करने में विफल: $error';
  }

  @override
  String get presetImported => 'स्टाइल प्रीसेट्स सफलतापूर्वक आयात किए गए!';

  @override
  String errorPresetImportFailed(String error) {
    return 'प्रीसेट्स आयात करने में विफल: $error';
  }

  @override
  String get selectFontFileDialogTitle => 'TTF या OTF फ़ॉन्ट फ़ाइल चुनें';

  @override
  String get fontWeightThin => 'पतला (Thin)';

  @override
  String get fontWeightExtraLight => 'अतिरिक्त हल्का (Extra Light)';

  @override
  String get fontWeightLight => 'हल्का (Light)';

  @override
  String get fontWeightNormal => 'सामान्य (Normal)';

  @override
  String get fontWeightMedium => 'मध्यम (Medium)';

  @override
  String get fontWeightSemiBold => 'सेमी बोल्ड (Semi Bold)';

  @override
  String get fontWeightBold => 'बोल्ड (Bold)';

  @override
  String get fontWeightExtraBold => 'एक्स्ट्रा बोल्ड (Extra Bold)';

  @override
  String get fontWeightBlack => 'ब्लैक (Black)';

  @override
  String get fontCaseNormal => 'सामान्य';

  @override
  String get fontCaseUppercase => 'अपरकेस (UPPERCASE)';

  @override
  String get fontCaseCapitalize => 'कैपिटलाइज़ (Capitalize)';

  @override
  String get strokeStyleThickOutline => 'मोटी रूपरेखा (Thick Outline)';

  @override
  String get strokeStyleNoneFlat => 'कोई नहीं (सपाट/Flat)';

  @override
  String get shadowStyleSoft => 'हल्की छाया (Soft Shadow)';

  @override
  String get shadowStyleNone => 'कोई नहीं';

  @override
  String get animStyleActivePop => 'एक्टिव पॉप (Active Pop)';

  @override
  String get animStyleActiveBounce => 'एक्टिव बाउंस जंप (Active Bounce)';

  @override
  String get animStyleKineticTilt => 'काइनेटिक बाउंसी टिल्ट';

  @override
  String get animStyleGlowPulse => 'ग्लोइंग एक्टिव पल्स';

  @override
  String get animStyleWordReveal => 'वर्ड रिवील स्टैगर';

  @override
  String get animStyleNoneStatic => 'कोई नहीं (स्थिर)';

  @override
  String fontImportedSuccess(String name) {
    return 'कस्टम फ़ॉन्ट सफलतापूर्वक आयात और लागू किया गया: \"$name\"';
  }

  @override
  String get errorFontImportFailed =>
      'फ़ॉन्ट फ़ाइल लोड करने में विफल। अमान्य डेटा।';

  @override
  String get invalidTimingError =>
      'अमान्य प्रारंभ/समाप्ति समय। प्रारंभ >= 0 होना चाहिए, और समाप्ति >= प्रारंभ और <= वीडियो अवधि होनी चाहिए।';

  @override
  String get projectSavedSuccess => 'प्रोजेक्ट सफलतापूर्वक सहेजा गया।';

  @override
  String wordDeletedSuccess(String text) {
    return 'शब्द हटाया गया: \"$text\"';
  }

  @override
  String get splitClip => 'क्लिप विभाजित करें';

  @override
  String get removeClip => 'क्लिप हटाएं';

  @override
  String get resetToOriginal => 'मूल स्थिति में रीसेट करें';

  @override
  String splitTimelineAt(String time) {
    return '${time}s पर टाइमलाइन विभाजित करें।';
  }

  @override
  String get splitTimelineError =>
      'विभाजित करने के लिए प्लेहेड सक्रिय क्षेत्र के अंदर होना चाहिए।';

  @override
  String get exclusionToggled => 'प्लेहेड के तहत खंड बहिष्करण टॉगल किया गया।';

  @override
  String get splitsReset => 'सभी टाइमलाइन विभाजन और बहिष्करण रीसेट करें।';

  @override
  String get shareVideo => 'वीडियो साझा करें';

  @override
  String get openOutputFolder => 'आउटपुट फ़ोल्डर खोलें';

  @override
  String get errorLogCopied => 'त्रुटि लॉग क्लिपबोर्ड पर कॉपी हो गया।';

  @override
  String get diagnosticsExported =>
      'फ़िल्टर की गई नैदानिक रिपोर्ट शेयर शीट में खोली गई।';

  @override
  String errorDiagnosticsFailed(String error) {
    return 'नैदानिक रिपोर्ट निर्यात करने में विफल: $error';
  }

  @override
  String logLineCopied(String message) {
    return 'लॉग पंक्ति क्लिपबोर्ड पर कॉपी की गई: \"$message\"';
  }

  @override
  String commandCopied(String command) {
    return 'कॉपी किया गया: \"$command\"';
  }

  @override
  String get settingsRestored => 'सेटिंग्स डिफ़ॉल्ट पर पुनर्स्थापित की गईं।';

  @override
  String get gpuEncoderNoneCpu => 'कोई नहीं (CPU)';

  @override
  String get gpuEncoderNvidia => 'NVIDIA NVENC';

  @override
  String get gpuEncoderAmd => 'AMD AMF';

  @override
  String get gpuEncoderIntel => 'Intel QSV';

  @override
  String get gpuEncoderApple => 'Apple VideoToolbox';

  @override
  String get btnDownloadVcRedist => 'VC++ REDISTRIBUTABLE डाउनलोड करें';

  @override
  String errorDownloadToolFailed(String error) {
    return 'टूल डाउनलोड करने में विफल: $error';
  }

  @override
  String get errorFolderNotAccessible =>
      'चयनित फ़ोल्डर मौजूद नहीं है या सुलभ नहीं है।';

  @override
  String modelDeleted(String name) {
    return 'मॉडल हटाया गया: $name';
  }

  @override
  String errorModelDeleteFailed(String error) {
    return 'मॉडल हटाने में विफल: $error';
  }

  @override
  String errorModelDownloadFailed(String name, String error) {
    return 'मॉडल $name डाउनलोड करने में विफल: $error';
  }

  @override
  String errorOpenFolderFailed(String path) {
    return 'फ़ोल्डर स्वचालित रूप से नहीं खोला जा सका। पथ: $path';
  }

  @override
  String errorDownloadPackFailed(String error) {
    return 'पैक डाउनलोड करने में विफल: $error';
  }

  @override
  String errorPackDownloadNamedFailed(String name, String error) {
    return 'पैक $name डाउनलोड करने में विफल: $error';
  }

  @override
  String get stickersIndexRefreshed =>
      'कस्टम स्टिकर इंडेक्स सफलतापूर्वक रीफ़्रेश किया गया!';

  @override
  String errorChangeAssetFolderFailed(String error) {
    return 'एसेट फ़ोल्डर बदलने में विफल: $error';
  }

  @override
  String errorSetAssetFolderFailed(String error) {
    return 'एसेट फ़ोल्डर सेट करने में विफल: $error';
  }

  @override
  String get warningNoAvx =>
      'AVX समर्थन का अभाव पाया गया! संगत whisper-cli (बिना-AVX) डाउनलोड हो रहा है...';

  @override
  String get errorAutoDetectWhisper =>
      'whisper-cli का स्वतः पता नहीं लगाया जा सका। कृपया मैन्युअल रूप से ब्राउज़ करें।';

  @override
  String get errorAutoDetectFfmpeg =>
      'ffmpeg का स्वतः पता नहीं लगाया जा सका। कृपया मैन्युअल रूप से ब्राउज़ करें।';

  @override
  String errorToolDownloadFailed(String error) {
    return 'टूल डाउनलोड करने में विफल: $error';
  }

  @override
  String get returnToDashboard => 'डैशबोर्ड पर लौटें';

  @override
  String errorImportVideoFailed(String error) {
    return 'आयात विफल रहा: $error';
  }

  @override
  String get videoRelinkedSuccess => 'वीडियो सफलतापूर्वक पुनः लिंक किया गया!';

  @override
  String get errorRelinkVideoFailed => 'वीडियो को पुनः लिंक करने में विफल।';

  @override
  String get retranscriptionSuccess => 'पुनः ट्रांसक्रिप्शन सफल रहा!';

  @override
  String get retranscriptionFailed => 'पुनः ट्रांसक्रिप्शन विफल रहा।';
}
