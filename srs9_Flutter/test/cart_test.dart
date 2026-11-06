import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/models/product.dart';
import 'package:shop_app/services/cart.dart';

void main() {
  const apple = Product(id: 'a', name: 'Яблоки', price: 450, emoji: '🍎');
  const bread = Product(id: 'b', name: 'Хлеб', price: 120, emoji: '🍞');

  group('Cart Unit Tests', () {
    late Cart cart;

    // Перед каждым тестом создаём новую пустую корзину.
    setUp(() => cart = Cart());

    test('Новая корзина пустая', () {
      expect(cart.isEmpty, isTrue);
      expect(cart.itemCount, 0);
      expect(cart.total, 0);
    });

    test('Добавление товара увеличивает количество', () {
      cart.add(apple);
      cart.add(apple, quantity: 2);
      expect(cart.quantityOf(apple), 3);
      expect(cart.itemCount, 3);
    });

    test('Подсчёт общей стоимости', () {
      cart.add(apple, quantity: 2); // 2 * 450 = 900
      cart.add(bread); //             1 * 120 = 120
      expect(cart.subtotal, 1020);
      expect(cart.total, 1020);
    });

    test('Уменьшение количества и удаление товара', () {
      cart.add(apple, quantity: 2);
      cart.add(bread);

      cart.decrease(apple);
      expect(cart.quantityOf(apple), 1);

      cart.decrease(apple); // при нуле товар убирается
      expect(cart.items.containsKey(apple), isFalse);

      cart.remove(bread);
      expect(cart.isEmpty, isTrue);
    });

    test('Верный промокод даёт скидку 10%', () {
      cart.add(apple, quantity: 2); // 900
      final ok = cart.applyPromo(' sale10 '); // регистр и пробелы не важны
      expect(ok, isTrue);
      expect(cart.total, closeTo(810, 0.001));
    });

    // ---- Некорректные входные данные (доп. задание) ----

    test('Неверный промокод не меняет сумму', () {
      cart.add(bread);
      expect(cart.applyPromo('FREE100'), isFalse);
      expect(cart.discount, 0);
      expect(cart.total, 120);
    });

    test('Нулевое или отрицательное количество вызывает ошибку', () {
      expect(() => cart.add(apple, quantity: 0), throwsArgumentError);
      expect(() => cart.add(apple, quantity: -3), throwsArgumentError);
      expect(cart.isEmpty, isTrue);
    });

    test('Уменьшение отсутствующего товара ничего не ломает', () {
      cart.decrease(apple);
      expect(cart.isEmpty, isTrue);
    });

    test('Очистка корзины сбрасывает товары и скидку', () {
      cart.add(apple);
      cart.applyPromo('SALE20');
      cart.clear();
      expect(cart.isEmpty, isTrue);
      expect(cart.discount, 0);
    });
  });
}
