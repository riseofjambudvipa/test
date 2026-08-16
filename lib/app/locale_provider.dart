import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/settings/settings_service.dart';

class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier() : super(_getLocaleFromSettings());

  static Locale? _getLocaleFromSettings() {
    final stored = SettingsService.instance.uiLanguage;
    if (stored == 'system') return null;
    return Locale(stored);
  }

  void setLocale(String langCode) {
    if (langCode == 'system') {
      state = null;
      SettingsService.instance.setUiLanguage('system');
    } else {
      state = Locale(langCode);
      SettingsService.instance.setUiLanguage(langCode);
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier();
});
