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
}
