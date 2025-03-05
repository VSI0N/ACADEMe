import 'package:flutter/material.dart';
import 'package:ACADEMe/localization/l10n.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('en'); // Default language is English

  Locale get locale => _locale;

  LanguageProvider() {
    _initializeLocale();
  }

  Future<void> _initializeLocale() async {
    await _loadSavedLocale();
    notifyListeners(); // Ensure UI updates after loading saved language
  }

  void setLocale(Locale newLocale) async {
    if (!L10n.supportedLocales.any((locale) => locale.languageCode == newLocale.languageCode)) {
      return; // Ensure valid locale
    }

    _locale = newLocale;
    notifyListeners();
    await _saveLocale(newLocale);
  }

  Future<void> _saveLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', locale.languageCode);
  }

  Future<void> _loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('language_code');

    if (languageCode != null &&
        L10n.supportedLocales.any((locale) => locale.languageCode == languageCode)) {
      _locale = Locale(languageCode);
    } else {
      _locale = const Locale('en'); // Fallback to English if not supported
    }
  }
}
