import 'package:flutter/material.dart';

/// Модель товара. Название хранится как ключ локализации.
class Product {
  const Product({
    required this.id,
    required this.nameKey,
    required this.price,
    required this.imageUrl,
    required this.icon,
  });

  final String id;
  final String nameKey;
  final int price;
  final String imageUrl;

  /// Иконка-заглушка, пока картинка грузится или если нет интернета.
  final IconData icon;
}
