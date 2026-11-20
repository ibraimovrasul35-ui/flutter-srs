import '../../../constants/storage_keys.dart';
import '../../../models/favorite_model.dart';
import 'json_storage.dart';

/// Избранное в SharedPreferences (новая функция СРС 11).
abstract interface class FavoritesLocalDataSource {
  List<FavoriteModel> readFavorites();

  Future<void> saveFavorites(List<FavoriteModel> favorites);
}

class FavoritesLocalDataSourceImpl implements FavoritesLocalDataSource {
  final JsonStorage _storage;

  const FavoritesLocalDataSourceImpl(this._storage);

  @override
  List<FavoriteModel> readFavorites() =>
      _storage.readList(StorageKeys.favorites, FavoriteModel.fromJson)?.data ??
      const [];

  @override
  Future<void> saveFavorites(List<FavoriteModel> favorites) =>
      _storage.writeList(
          StorageKeys.favorites, favorites.map((f) => f.toJson()).toList());
}
