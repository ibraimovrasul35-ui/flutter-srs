import 'package:fpdart/fpdart.dart';

import '../../../models/favorite_model.dart';
import '../../domain/entities/post.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_local_data_source.dart';
import '../mapper/failure_mapper.dart';
import '../mapper/post_mapper.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  final FavoritesLocalDataSource _local;

  const FavoritesRepositoryImpl(this._local);

  @override
  Future<Either<Failure, List<Post>>> getFavorites() =>
      guard(() async => _toEntities(_local.readFavorites()));

  @override
  Future<Either<Failure, List<Post>>> toggleFavorite(Post post) {
    return guard(() async {
      final current = _local.readFavorites();
      final exists = current.any((f) => f.post.id == post.id);
      final updated = exists
          ? current.where((f) => f.post.id != post.id).toList()
          : [
              FavoriteModel(
                post: post.toModel(),
                isLocal: post.isLocal,
                addedAt: DateTime.now(),
              ),
              ...current,
            ];
      await _local.saveFavorites(updated);
      return _toEntities(updated);
    });
  }

  /// Новые сверху.
  static List<Post> _toEntities(List<FavoriteModel> models) {
    final sorted = [...models]..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return sorted.map((f) => f.toEntity()).toList();
  }
}
