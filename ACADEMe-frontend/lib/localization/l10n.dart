import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  late final Map<String, String> _localizedStrings;
  static Map<String, String>? _fallbackStrings; // Store English translations for fallback

  AppLocalizations(this.locale);

  /// Load the localization files
  static Future<AppLocalizations> load(Locale locale) async {
    final jsonString = await rootBundle.loadString('assets/l10n/${locale.languageCode}.json');
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

    final appLocalizations = AppLocalizations(locale);
    appLocalizations._localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));

    // Load fallback English translations once
    if (_fallbackStrings == null) {
      final fallbackJson = await rootBundle.loadString('assets/l10n/en.json');
      final fallbackJsonMap = json.decode(fallbackJson) as Map<String, dynamic>;
      _fallbackStrings = fallbackJsonMap.map((key, value) => MapEntry(key, value.toString()));
    }

    return appLocalizations;
  }

  /// Delegate to load the localizations
  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// Translate a key, with fallback to English if missing
  String translate(String key) {
    return _localizedStrings[key] ?? _fallbackStrings?[key] ?? key;
  }

  /// Get the localizations instance from the context
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return L10n.supportedLocales.any((l) => l.languageCode == locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}

class L10n {
  static const supportedLocales = [
    Locale('en', ''),
    Locale('hi', ''),
    Locale('es', ''),
    Locale('fr', ''),
    Locale('zh', ''),
    Locale('de', ''),
  ];

  /// Get the supported locale, defaulting to English if not found
  static Locale getSupportedLocale(Locale? locale) {
    return supportedLocales.firstWhere(
          (l) => l.languageCode == locale?.languageCode,
      orElse: () => const Locale('en'),
    );
  }

  /// Get the language name for UI display
  static String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return "English";
      case 'hi':
        return "हिन्दी (Hindi)";
      case 'es':
        return "Español (Spanish)";
      case 'fr':
        return "Français (French)";
      case 'zh':
        return "中文 (Chinese)";
      case 'de':
        return "Deutsch (German)";
      default:
        return "English";
    }
  }

  /// Retrieve translated text from the localization instance
  static String getTranslatedText(BuildContext context, String key) {
    return AppLocalizations.of(context)?.translate(key) ?? key;
  }
}
