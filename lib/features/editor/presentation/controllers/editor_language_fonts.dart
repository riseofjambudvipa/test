part of 'editor_controller.dart';

/// Maps Whisper-detected language codes to the correct font family.
/// Covers ALL 99+ Whisper-supported languages across 25+ scripts.
/// Latin/Cyrillic/Greek languages use the default template font (Montserrat).
String suggestFontForLanguage(String whisperLang) {
  final lang = whisperLang.trim().toLowerCase();
  if (lang.startsWith('zh-tw') || lang.startsWith('zh-hk') || lang.startsWith('zh-hant')) {
    return 'Noto Sans TC';
  }
  if (lang.startsWith('zh') || lang.startsWith('yue')) {
    return 'Noto Sans SC';
  }
  if (lang.startsWith('ja')) {
    return 'Noto Sans JP';
  }
  if (lang.startsWith('ko')) {
    return 'Noto Sans KR';
  }

  final primary = lang.split('-').first;
  return switch (primary) {
    // Devanagari script
    'hi' || 'mr' || 'ne' || 'sa'       => 'Noto Sans Devanagari',
    // Arabic script
    'ar' || 'fa' || 'ps'               => 'Noto Sans Arabic',
    // Urdu (Nastaliq style)
    'ur'                                => 'Noto Nastaliq Urdu',
    // Thai
    'th'                                => 'Noto Sans Thai',
    // Hebrew / Yiddish
    'he' || 'yi'                        => 'Noto Sans Hebrew',
    // Tamil
    'ta'                                => 'Noto Sans Tamil',
    // Telugu
    'te'                                => 'Noto Sans Telugu',
    // Bengali
    'bn'                                => 'Noto Sans Bengali',
    // Gujarati
    'gu'                                => 'Noto Sans Gujarati',
    // Kannada
    'kn'                                => 'Noto Sans Kannada',
    // Malayalam
    'ml'                                => 'Noto Sans Malayalam',
    // Gurmukhi (Punjabi)
    'pa'                                => 'Noto Sans Gurmukhi',
    // Odia
    'or'                                => 'Noto Sans Oriya',
    // Sinhala
    'si'                                => 'Noto Sans Sinhala',
    // Myanmar (Burmese)
    'my'                                => 'Noto Sans Myanmar',
    // Khmer (Cambodian)
    'km'                                => 'Noto Sans Khmer',
    // Lao
    'lo'                                => 'Noto Sans Lao',
    // Georgian
    'ka'                                => 'Noto Sans Georgian',
    // Armenian
    'hy'                                => 'Noto Sans Armenian',
    // Ethiopic (Amharic)
    'am'                                => 'Noto Sans Ethiopic',
    _                                   => 'Montserrat',
  };
}

/// Returns true if the language needs a CJK downloadable font pack.
bool isCjkLanguage(String whisperLang) {
  final lang = whisperLang.trim().toLowerCase();
  final primary = lang.split('-').first;
  return ['zh', 'yue', 'ja', 'ko'].contains(primary);
}
