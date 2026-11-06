import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/cart.dart';
import 'cart_screen.dart';

/// Главный экран: каталог товаров и кнопка перехода в корзину.
class HomeScreen extends StatelessWidget {
  final Cart cart;

  const HomeScreen({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Мини-магазин'),
            actions: [
              IconButton(
                key: const Key('openCart'),
                tooltip: 'Корзина',
                icon: Badge(
                  isLabelVisible: cart.itemCount > 0,
                  label: Text('${cart.itemCount}'),
                  child: const Icon(Icons.shopping_cart),
                ),
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => CartScreen(cart: cart)),
                ),
              ),
            ],
          ),
          body: ListView(
            children: [
              for (final product in catalog)
                ListTile(
                  leading: Text(product.emoji,
                      style: const TextStyle(fontSize: 28)),
                  title: Text(product.name),
                  subtitle: Text('${product.price.toStringAsFixed(0)} ₸'),
                  trailing: ElevatedButton(
                    key: Key('add_${product.id}'),
                    onPressed: () => cart.add(product),
                    child: const Text('В корзину'),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Товаров в корзине: ${cart.itemCount}',
                key: const Key('cartCounter'),
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
