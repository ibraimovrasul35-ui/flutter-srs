part of 'favorites_cubit.dart';

enum FavoritesStatus { loading, success, empty, failure }

final class FavoritesState extends Equatable {
  final FavoritesStatus status;
  final List<Post> favorites;
  final Failure? failure;

  const FavoritesState({
    this.status = FavoritesStatus.loading,
    this.favorites = const [],
    this.failure,
  });

  bool isFavorite(int postId) => favorites.any((p) => p.id == postId);

  FavoritesState copyWith({
    FavoritesStatus? status,
    List<Post>? favorites,
    Failure? failure,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      favorites: favorites ?? this.favorites,
      failure: status == FavoritesStatus.failure ? failure : null,
    );
  }

  @override
  List<Object?> get props => [status, favorites, failure];
}
