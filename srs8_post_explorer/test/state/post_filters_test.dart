import 'package:flutter_test/flutter_test.dart';
import 'package:srs8_post_explorer/data/models/post.dart';
import 'package:srs8_post_explorer/presentation/state/post_filters.dart';

void main() {
  const posts = [
    Post(id: 3, userId: 1, title: 'Flutter и Dio', body: 'a'),
    Post(id: 1, userId: 2, title: 'Retrofit в Dart', body: 'b'),
    Post(id: 2, userId: 1, title: 'Кэширование данных', body: 'c'),
  ];

  // Тест 5
  group('Фильтрация постов', () {
    test('по автору', () {
      final result = applyPostFilters(posts, userId: 1);
      expect(result.map((p) => p.id), [2, 3]);
    });

    test('по заголовку без учёта регистра', () {
      final result = applyPostFilters(posts, query: 'DART');
      expect(result.map((p) => p.id), [1]);
    });

    test('по автору и заголовку вместе', () {
      expect(applyPostFilters(posts, userId: 2, query: 'flutter'), isEmpty);
    });

    test('сортировка по ID в обе стороны', () {
      expect(applyPostFilters(posts).map((p) => p.id), [1, 2, 3]);
      expect(applyPostFilters(posts, ascending: false).map((p) => p.id),
          [3, 2, 1]);
    });
  });
}
