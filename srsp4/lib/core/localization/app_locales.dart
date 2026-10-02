import 'package:flutter/material.dart';

/// Настройки локализации для easy_localization.
class AppLocales {
  AppLocales._();

  static const path = 'assets/translations';

  static const ru = Locale('ru');
  static const en = Locale('en');
  static const kk = Locale('kk');

  static const supported = [ru, en, kk];
  static const fallback = ru;

  /// Название языка на самом этом языке — для переключателя.
  static String nameOf(Locale locale) {
    switch (locale.languageCode) {
      case 'ru':
        return 'Русский';
      case 'kk':
        return 'Қазақша';
      default:
        return 'English';
    }
  }
}
