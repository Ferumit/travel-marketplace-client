import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing the application's language (Locale).
class LocaleService extends ChangeNotifier {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  static const _keyLocale = 'app_locale';

  // Default to Russian
  Locale _locale = const Locale('ru');
  Locale get locale => _locale;

  /// Supported locales
  static const supportedLocales = [
    Locale('ru'),
    Locale('en'),
    Locale('kk'),
  ];

  /// Loads the saved locale. Call in main().
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLocale = prefs.getString(_keyLocale);

    if (savedLocale != null) {
      _locale = Locale(savedLocale);
    }
    notifyListeners();
  }

  /// Sets a new locale and saves it.
  Future<void> setLocale(Locale newLocale) async {
    if (_locale == newLocale) return;

    if (!supportedLocales.contains(newLocale)) return;

    _locale = newLocale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLocale, newLocale.languageCode);
  }
}

