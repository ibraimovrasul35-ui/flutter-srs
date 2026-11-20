import 'package:equatable/equatable.dart';

/// Параметры локального поиска и сортировки загруженных постов.
class PostFilter extends Equatable {
  final String query;
  final int? userId;
  final bool ascending;

  const PostFilter({this.query = '', this.userId, this.ascending = true});

  bool get isSearching => query.trim().isNotEmpty;

  bool get isActive => userId != null || isSearching || !ascending;

  /// [userId] передаётся функцией, чтобы можно было явно задать null
  /// («все авторы»).
  PostFilter copyWith({
    String? query,
    int? Function()? userId,
    bool? ascending,
  }) {
    return PostFilter(
      query: query ?? this.query,
      userId: userId == null ? this.userId : userId(),
      ascending: ascending ?? this.ascending,
    );
  }

  @override
  List<Object?> get props => [query, userId, ascending];
}
