import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/post.dart';
import '../../../domain/failures/failures.dart';
import '../../../domain/usecases/favorites_usecases.dart';

part 'favorites_state.dart';

/// Избранное (новая функция СРС 11). Один экземпляр на всё приложение:
/// звёздочки в списке, на экране деталей и на экране «Избранное»
/// показывают одно и то же состояние.
class FavoritesCubit extends Cubit<FavoritesState> {
  final GetFavoritesUseCase _getFavorites;
  final ToggleFavoriteUseCase _toggleFavorite;

  FavoritesCubit({
    required this._getFavorites,
    required this._toggleFavorite,
  }) : super(const FavoritesState());

  /// id постов, которые сейчас сохраняются: двойное нажатие
  /// не запустит вторую запись.
  final _pending = <int>{};

  Future<void> load() async {
    emit(state.copyWith(status: FavoritesStatus.loading));
    final result = await _getFavorites();
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
          status: FavoritesStatus.failure, failure: failure)),
      (favorites) => emit(state.copyWith(
        status:
            favorites.isEmpty ? FavoritesStatus.empty : FavoritesStatus.success,
        favorites: favorites,
      )),
    );
  }

  /// Возвращает Failure, если сохранить не удалось (экран покажет SnackBar).
  Future<Failure?> toggle(Post post) async {
    if (!_pending.add(post.id)) return null;
    try {
      final result = await _toggleFavorite(post);
      if (isClosed) return null;
      final Failure? failure = result.fold((failure) => failure, (favorites) {
        emit(state.copyWith(
          status: favorites.isEmpty
              ? FavoritesStatus.empty
              : FavoritesStatus.success,
          favorites: favorites,
        ));
        return null;
      });
      return failure;
    } finally {
      _pending.remove(post.id);
    }
  }
}
