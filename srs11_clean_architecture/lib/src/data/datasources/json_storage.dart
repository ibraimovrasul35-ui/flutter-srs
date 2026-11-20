import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/cached.dart';
import '../exceptions/exceptions.dart';

/// Хранение списков моделей в SharedPreferences в виде JSON-строки
/// `{"savedAt": "...", "data": [...]}`. Общая часть всех Local DataSource.
class JsonStorage {
  final SharedPreferences _prefs;

  const JsonStorage(this._prefs);

  /// null — по ключу ничего нет. Повреждённая запись тоже даёт null:
  /// битый кэш не должен ронять приложение.
  Cached<List<T>>? readList<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = (decoded['data'] as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
      return Cached(list, DateTime.parse(decoded['savedAt'] as String));
    } catch (e) {
      developer.log('Broken cache for $key: $e', name: 'PostExplorer.cache');
      return null;
    }
  }

  /// Бросает [CacheException], если запись не удалась.
  Future<void> writeList(String key, List<Map<String, dynamic>> data) async {
    try {
      final ok = await _prefs.setString(
        key,
        jsonEncode(
            {'savedAt': DateTime.now().toIso8601String(), 'data': data}),
      );
      if (!ok) throw CacheException('setString($key) вернул false');
    } on CacheException {
      rethrow;
    } catch (e) {
      throw CacheException('$key: $e');
    }
  }
}
