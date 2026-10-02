import 'package:flutter/material.dart';

import 'product.dart';

/// Демонстрационные данные вместо базы данных.
const demoProducts = <Product>[
  Product(
    id: 'headphones',
    nameKey: 'product_headphones',
    price: 24990,
    imageUrl: 'https://picsum.photos/id/1/400/400',
    icon: Icons.headphones,
  ),
  Product(
    id: 'watch',
    nameKey: 'product_watch',
    price: 39990,
    imageUrl: 'https://picsum.photos/id/175/400/400',
    icon: Icons.watch,
  ),
  Product(
    id: 'laptop',
    nameKey: 'product_laptop',
    price: 349990,
    imageUrl: 'https://picsum.photos/id/0/400/400',
    icon: Icons.laptop_mac,
  ),
  Product(
    id: 'camera',
    nameKey: 'product_camera',
    price: 189990,
    imageUrl: 'https://picsum.photos/id/250/400/400',
    icon: Icons.photo_camera,
  ),
  Product(
    id: 'speaker',
    nameKey: 'product_speaker',
    price: 19990,
    imageUrl: 'https://picsum.photos/id/96/400/400',
    icon: Icons.speaker,
  ),
  Product(
    id: 'phone',
    nameKey: 'product_phone',
    price: 279990,
    imageUrl: 'https://picsum.photos/id/160/400/400',
    icon: Icons.smartphone,
  ),
];
