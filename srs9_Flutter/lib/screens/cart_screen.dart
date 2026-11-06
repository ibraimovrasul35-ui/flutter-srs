import 'package:flutter/material.dart';

import '../services/cart.dart';

/// Экран корзины: список товаров, промокод и итоговая сумма.
class CartScreen extends StatefulWidget {
  final Cart cart;

  const CartScreen({super.key, required this.cart});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _promoController = TextEditingController();
  String? _promoMessage;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  void _applyPromo() {
    final ok = widget.cart.applyPromo(_promoController.text);
    setState(() {
      _promoMessage = ok ? 'Промокод применён' : 'Неверный промокод';
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = widget.cart;
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Корзина')),
          body: cart.isEmpty
              ? const Center(child: Text('Корзина пуста'))
              : ListView(
                  children: [
                    for (final entry in cart.items.entries)
                      ListTile(
                        leading: Text(entry.key.emoji,
                            style: const TextStyle(fontSize: 28)),
                        title: Text(entry.key.name),
                        subtitle: Text('${entry.value} шт.'),
                        trailing: IconButton(
                          key: Key('decrease_${entry.key.id}'),
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => cart.decrease(entry.key),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              key: const Key('promoField'),
                              controller: _promoController,
                              decoration:
                                  const InputDecoration(labelText: 'Промокод'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            key: const Key('applyPromo'),
                            onPressed: _applyPromo,
                            child: const Text('Применить'),
                          ),
                        ],
                      ),
                    ),
                    if (_promoMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(_promoMessage!),
                      ),
                  ],
                ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Итого: ${cart.total.toStringAsFixed(0)} ₸',
                key: const Key('cartTotal'),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
