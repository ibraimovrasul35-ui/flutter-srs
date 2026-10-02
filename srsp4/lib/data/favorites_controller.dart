import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'demo_products.dart';
import 'product.dart';

/// Список избранного (id товаров). Сохраняется между запусками.
class FavoritesController extends ValueNotifier<Set<String>> {
  FavoritesController(this._prefs)
    : super((_prefs.getStringList(_key) ?? const <String>[]).toSet());

  static const _key = 'favorite_ids';
  final SharedPreferences _prefs;

  bool isFavorite(Product product) => value.contains(product.id);

  List<Product> get products =>
      demoProducts.where((p) => value.contains(p.id)).toList();

  int get totalPrice => products.fold(0, (sum, p) => sum + p.price);

  /// Возвращает true, если товар добавлен, и false, если удалён.
  bool toggle(Product product) {
    final ids = Set<String>.of(value);
    final added = ids.add(product.id);
    if (!added) ids.remove(product.id);
    _save(ids);
    return added;
  }

  void clear() => _save(<String>{});

  void _save(Set<String> ids) {
    value = ids;
    _prefs.setStringList(_key, ids.toList());
  }
}
