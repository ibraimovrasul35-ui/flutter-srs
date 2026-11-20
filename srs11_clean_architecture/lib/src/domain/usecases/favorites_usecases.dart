import 'package:fpdart/fpdart.dart';

import '../entities/post.dart';
import '../failures/failures.dart';
import '../repositories/favorites_repository.dart';
import 'usecase.dart';

/// Список избранного из локального хранилища.
class GetFavoritesUseCase implements UseCase<List<Post>, NoParams> {
  final FavoritesRepository _repository;

  const GetFavoritesUseCase(this._repository);

  @override
  Future<Either<Failure, List<Post>>> call([NoParams _ = const NoParams()]) =>
      _repository.getFavorites();
}

/// Добавить в избранное / убрать из избранного.
class ToggleFavoriteUseCase implements UseCase<List<Post>, Post> {
  final FavoritesRepository _repository;

  const ToggleFavoriteUseCase(this._repository);

  @override
  Future<Either<Failure, List<Post>>> call(Post post) =>
      _repository.toggleFavorite(post);
}
