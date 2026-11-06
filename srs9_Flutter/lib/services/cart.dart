import 'package:flutter/foundation.dart';

import '../models/product.dart';

/// Корзина покупок: хранит товары и их количество,
/// считает общую стоимость и применяет промокод.
class Cart extends ChangeNotifier {
  /// Промокоды и размер скидки (0.10 = 10%).
  static const Map<String, double> promoCodes = {
    'SALE10': 0.10,
    'SALE20': 0.20,
  };

  final Map<Product, int> _items = {};
  double _discount = 0;

  /// Товары в корзине и их количество (только для чтения).
  Map<Product, int> get items => Map.unmodifiable(_items);

  /// Общее количество единиц товара в корзине.
  int get itemCount => _items.values.fold(0, (sum, qty) => sum + qty);

  bool get isEmpty => _items.isEmpty;

  /// Текущая скидка (доля от 0 до 1).
  double get discount => _discount;

  /// Стоимость без скидки.
  double get subtotal => _items.entries
      .fold(0, (sum, e) => sum + e.key.price * e.value);

  /// Итоговая стоимость с учётом скидки.
  double get total => subtotal * (1 - _discount);

  /// Количество конкретного товара в корзине.
  int quantityOf(Product product) => _items[product] ?? 0;

  /// Добавляет товар. Количество должно быть больше нуля.
  void add(Product product, {int quantity = 1}) {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero');
    }
    _items[product] = quantityOf(product) + quantity;
    notifyListeners();
  }

  /// Уменьшает количество товара на 1, при нуле убирает его из корзины.
  void decrease(Product product) {
    final qty = quantityOf(product);
    if (qty == 0) return;
    if (qty == 1) {
      _items.remove(product);
    } else {
      _items[product] = qty - 1;
    }
    notifyListeners();
  }

  /// Полностью удаляет товар из корзины.
  void remove(Product product) {
    if (_items.remove(product) != null) notifyListeners();
  }

  /// Применяет промокод. Возвращает true, если код верный.
  bool applyPromo(String code) {
    final value = promoCodes[code.trim().toUpperCase()];
    if (value == null) return false;
    _discount = value;
    notifyListeners();
    return true;
  }

  /// Очищает корзину и сбрасывает скидку.
  void clear() {
    _items.clear();
    _discount = 0;
    notifyListeners();
  }
}
