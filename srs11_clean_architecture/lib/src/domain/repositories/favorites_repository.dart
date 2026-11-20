import 'package:fpdart/fpdart.dart';

import '../entities/post.dart';
import '../failures/failures.dart';

/// Избранные посты, сохранённые на устройстве (новая функция СРС 11).
abstract interface class FavoritesRepository {
  /// Избранное, новые сверху.
  Future<Either<Failure, List<Post>>> getFavorites();

  /// Добавляет пост в избранное или убирает его оттуда.
  /// Возвращает обновлённый список.
  Future<Either<Failure, List<Post>>> toggleFavorite(Post post);
}
