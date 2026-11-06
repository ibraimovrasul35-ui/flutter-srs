/// Товар в каталоге магазина.
class Product {
  final String id;
  final String name;
  final double price;
  final String emoji;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.emoji,
  });
}

/// Каталог товаров, который показывается на главном экране.
const List<Product> catalog = [
  Product(id: 'p1', name: 'Яблоки', price: 450, emoji: '🍎'),
  Product(id: 'p2', name: 'Хлеб', price: 120, emoji: '🍞'),
  Product(id: 'p3', name: 'Молоко', price: 380, emoji: '🥛'),
  Product(id: 'p4', name: 'Сыр', price: 1500, emoji: '🧀'),
];
