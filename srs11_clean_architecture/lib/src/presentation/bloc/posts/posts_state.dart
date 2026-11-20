part of 'posts_cubit.dart';

/// Состояние первичной загрузки списка: Loading / Success / Empty / Error.
enum ListStatus { initial, loading, success, empty, failure }

const _unset = Object();

/// У разных операций свои флаги: первичная загрузка ([status]),
/// подгрузка страницы ([isLoadingMore] / [loadMoreFailure]) и
/// ручное обновление ([isRefreshing]). Они не мешают друг другу.
final class PostsState extends Equatable {
  final ListStatus status;
  final List<Post> posts; // с сервера (или из кэша) для текущего автора
  final List<Post> localPosts; // созданные через форму, только на устройстве
  final List<Author> authors;
  final PostFilter filter;

  /// Посты после поиска и сортировки (их считает FilterPostsUseCase).
  final List<Post> visiblePosts;
  final List<Post> visibleLocalPosts;

  // Пагинация
  final int page; // последняя загруженная страница
  final bool hasMore;
  final bool isLoadingMore;
  final Failure? loadMoreFailure;

  // Кэш и ошибки
  final bool isFromCache;
  final DateTime? cachedAt;
  final bool isRefreshing;
  final Failure? failure;

  const PostsState({
    this.status = ListStatus.initial,
    this.posts = const [],
    this.localPosts = const [],
    this.authors = const [],
    this.filter = const PostFilter(),
    this.visiblePosts = const [],
    this.visibleLocalPosts = const [],
    this.page = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.loadMoreFailure,
    this.isFromCache = false,
    this.cachedAt,
    this.isRefreshing = false,
    this.failure,
  });

  /// Данные есть, но поиск/фильтр ничего не нашёл.
  bool get nothingFound =>
      status == ListStatus.success &&
      visiblePosts.isEmpty &&
      visibleLocalPosts.isEmpty;

  String authorName(int userId) {
    for (final a in authors) {
      if (a.id == userId) return a.name;
    }
    return 'Пользователь $userId';
  }

  PostsState copyWith({
    ListStatus? status,
    List<Post>? posts,
    List<Post>? localPosts,
    List<Author>? authors,
    PostFilter? filter,
    List<Post>? visiblePosts,
    List<Post>? visibleLocalPosts,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Object? loadMoreFailure = _unset,
    bool? isFromCache,
    Object? cachedAt = _unset,
    bool? isRefreshing,
    Object? failure = _unset,
  }) {
    return PostsState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      localPosts: localPosts ?? this.localPosts,
      authors: authors ?? this.authors,
      filter: filter ?? this.filter,
      visiblePosts: visiblePosts ?? this.visiblePosts,
      visibleLocalPosts: visibleLocalPosts ?? this.visibleLocalPosts,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailure: identical(loadMoreFailure, _unset)
          ? this.loadMoreFailure
          : loadMoreFailure as Failure?,
      isFromCache: isFromCache ?? this.isFromCache,
      cachedAt:
          identical(cachedAt, _unset) ? this.cachedAt : cachedAt as DateTime?,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      failure: identical(failure, _unset) ? this.failure : failure as Failure?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        posts,
        localPosts,
        authors,
        filter,
        visiblePosts,
        visibleLocalPosts,
        page,
        hasMore,
        isLoadingMore,
        loadMoreFailure,
        isFromCache,
        cachedAt,
        isRefreshing,
        failure,
      ];
}
