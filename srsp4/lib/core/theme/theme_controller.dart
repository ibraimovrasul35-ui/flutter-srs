import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Хранит выбранную тему и сохраняет её в SharedPreferences,
/// чтобы она восстанавливалась после перезапуска приложения.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController(this._prefs)
    : super((_prefs.getBool(_key) ?? false) ? ThemeMode.dark : ThemeMode.light);

  static const _key = 'is_dark_theme';
  final SharedPreferences _prefs;

  bool get isDark => value == ThemeMode.dark;

  Future<void> setDark(bool isDark) async {
    value = isDark ? ThemeMode.dark : ThemeMode.light;
    await _prefs.setBool(_key, isDark);
  }
}
