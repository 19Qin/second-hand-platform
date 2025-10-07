import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageManager {
  static const String _languageKey = 'selected_language';
  static const String _localeKey = 'selected_locale';
  
  static final LanguageManager _instance = LanguageManager._internal();
  factory LanguageManager() => _instance;
  LanguageManager._internal();

  SharedPreferences? _prefs;
  Locale _currentLocale = const Locale('en', 'US');

  Locale get currentLocale => _currentLocale;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final languageCode = _prefs?.getString(_languageKey) ?? 'en';
    final countryCode = _prefs?.getString(_localeKey) ?? 'US';
    _currentLocale = Locale(languageCode, countryCode);
  }

  Future<void> setLanguage(Locale locale) async {
    await init();
    _currentLocale = locale;
    await _prefs?.setString(_languageKey, locale.languageCode);
    await _prefs?.setString(_localeKey, locale.countryCode ?? '');
  }

  Future<Locale> getSavedLanguage() async {
    await init();
    return _currentLocale;
  }

  String getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文';
      default:
        return 'English';
    }
  }

  List<Locale> get supportedLocales => [
    const Locale('en', 'US'),
    const Locale('zh', 'CN'),
  ];
}

