import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'services/cart.dart';

void main() {
  runApp(ShopApp(cart: Cart()));
}

class ShopApp extends StatelessWidget {
  final Cart cart;

  const ShopApp({super.key, required this.cart});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Мини-магазин',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
      ),
      home: HomeScreen(cart: cart),
    );
  }
}
