part of 'posts_cubit.dart';

/// Состояние первичной загрузки списка.
enum ListStatus { initial, loading, success, failure }

const _unset = Object();

/// Разные операции имеют свои флаги: первичная загрузка ([status]),
/// подгрузка страницы ([isLoadingMore] / [loadMoreError]) и
/// ручное обновление ([isRefreshing]) — они не мешают друг другу.
final class PostsState extends Equatable {
  final ListStatus status;
  final List<Post> posts; // посты с сервера (или из кэша) для текущего фильтра
  final List<Post> localPosts; // созданные через форму, только на устройстве
  final List<User> users;

  // Фильтры
  final int? selectedUserId;
  final String query;
  final bool sortAscending;

  // Пагинация
  final int page; // последняя загруженная страница
  final bool hasMore;
  final bool isLoadingMore;
  final String? loadMoreError;

  // Кэш и ошибки
  final bool isFromCache;
  final DateTime? cachedAt;
  final bool isRefreshing;
  final String? errorMessage;

  const PostsState({
    this.status = ListStatus.initial,
    this.posts = const [],
    this.localPosts = const [],
    this.users = const [],
    this.selectedUserId,
    this.query = '',
    this.sortAscending = true,
    this.page = 0,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.loadMoreError,
    this.isFromCache = false,
    this.cachedAt,
    this.isRefreshing = false,
    this.errorMessage,
  });

  /// Что показывать в списке: локальные посты сверху, затем серверные.
  List<Post> get visibleLocalPosts => applyPostFilters(localPosts,
      query: query, userId: selectedUserId, ascending: sortAscending);

  List<Post> get visiblePosts => applyPostFilters(posts,
      query: query, userId: selectedUserId, ascending: sortAscending);

  bool get isSearching => query.trim().isNotEmpty;

  bool get hasActiveFilters =>
      selectedUserId != null || isSearching || !sortAscending;

  bool get isEmpty =>
      status == ListStatus.success &&
      visiblePosts.isEmpty &&
      visibleLocalPosts.isEmpty;

  String authorName(int userId) {
    for (final u in users) {
      if (u.id == userId) return u.name;
    }
    return 'Пользователь $userId';
  }

  PostsState copyWith({
    ListStatus? status,
    List<Post>? posts,
    List<Post>? localPosts,
    List<User>? users,
    Object? selectedUserId = _unset,
    String? query,
    bool? sortAscending,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    Object? loadMoreError = _unset,
    bool? isFromCache,
    Object? cachedAt = _unset,
    bool? isRefreshing,
    Object? errorMessage = _unset,
  }) {
    return PostsState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      localPosts: localPosts ?? this.localPosts,
      users: users ?? this.users,
      selectedUserId: identical(selectedUserId, _unset)
          ? this.selectedUserId
          : selectedUserId as int?,
      query: query ?? this.query,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreError: identical(loadMoreError, _unset)
          ? this.loadMoreError
          : loadMoreError as String?,
      isFromCache: isFromCache ?? this.isFromCache,
      cachedAt:
          identical(cachedAt, _unset) ? this.cachedAt : cachedAt as DateTime?,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: identical(errorMessage, _unset)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        posts,
        localPosts,
        users,
        selectedUserId,
        query,
        sortAscending,
        page,
        hasMore,
        isLoadingMore,
        loadMoreError,
        isFromCache,
        cachedAt,
        isRefreshing,
        errorMessage,
      ];
}
