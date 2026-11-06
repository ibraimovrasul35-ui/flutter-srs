import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shop_app/main.dart';
import 'package:shop_app/services/cart.dart';

void main() {
  group('Shop Widget Tests', () {
    late Cart cart;

    setUp(() => cart = Cart());

    // Запускает приложение в тестовой среде.
    Future<void> openApp(WidgetTester tester) async {
      await tester.pumpWidget(ShopApp(cart: cart));
    }

    testWidgets('Главный экран: заголовок, товары и кнопки', (tester) async {
      await openApp(tester);

      // Заголовок
      expect(find.text('Мини-магазин'), findsOneWidget);
      // Основные элементы: товары каталога
      expect(find.text('Яблоки'), findsOneWidget);
      expect(find.text('Хлеб'), findsOneWidget);
      // Кнопки: 4 «В корзину» + кнопка корзины
      expect(find.widgetWithText(ElevatedButton, 'В корзину'),
          findsNWidgets(4));
      expect(find.byKey(const Key('openCart')), findsOneWidget);
      // Начальное состояние счётчика
      expect(find.text('Товаров в корзине: 0'), findsOneWidget);
    });

    testWidgets('Нажатие «В корзину» меняет счётчик', (tester) async {
      await openApp(tester);

      await tester.tap(find.byKey(const Key('add_p1')));
      await tester.pump();
      expect(find.text('Товаров в корзине: 1'), findsOneWidget);

      await tester.tap(find.byKey(const Key('add_p2')));
      await tester.tap(find.byKey(const Key('add_p2')));
      await tester.pump();
      expect(find.text('Товаров в корзине: 3'), findsOneWidget);
      // Бейдж на иконке корзины тоже обновился
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('Переход на экран корзины и итоговая сумма', (tester) async {
      await openApp(tester);

      await tester.tap(find.byKey(const Key('add_p1'))); // 450
      await tester.tap(find.byKey(const Key('add_p2'))); // 120
      await tester.pump();

      // Переход между экранами
      await tester.tap(find.byKey(const Key('openCart')));
      await tester.pumpAndSettle();

      expect(find.text('Корзина'), findsOneWidget);
      expect(find.text('Итого: 570 ₸'), findsOneWidget);

      // Уменьшение количества хлеба -> сумма пересчитывается
      await tester.tap(find.byKey(const Key('decrease_p2')));
      await tester.pump();
      expect(find.text('Итого: 450 ₸'), findsOneWidget);
    });

    testWidgets('Промокод: верный и неверный ввод', (tester) async {
      await openApp(tester);
      await tester.tap(find.byKey(const Key('add_p4'))); // 1500
      await tester.tap(find.byKey(const Key('openCart')));
      await tester.pumpAndSettle();

      // Неверный промокод
      await tester.enterText(find.byKey(const Key('promoField')), 'ABC');
      await tester.tap(find.byKey(const Key('applyPromo')));
      await tester.pump();
      expect(find.text('Неверный промокод'), findsOneWidget);
      expect(find.text('Итого: 1500 ₸'), findsOneWidget);

      // Верный промокод
      await tester.enterText(find.byKey(const Key('promoField')), 'SALE20');
      await tester.tap(find.byKey(const Key('applyPromo')));
      await tester.pump();
      expect(find.text('Промокод применён'), findsOneWidget);
      expect(find.text('Итого: 1200 ₸'), findsOneWidget);
    });

    testWidgets('Пустая корзина показывает сообщение', (tester) async {
      await openApp(tester);
      await tester.tap(find.byKey(const Key('openCart')));
      await tester.pumpAndSettle();
      expect(find.text('Корзина пуста'), findsOneWidget);
    });
  });
}
