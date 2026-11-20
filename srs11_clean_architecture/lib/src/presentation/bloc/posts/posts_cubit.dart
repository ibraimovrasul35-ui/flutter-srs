import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../constants/api_constants.dart';
import '../../../domain/entities/author.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/entities/post_filter.dart';
import '../../../domain/failures/failures.dart';
import '../../../domain/usecases/filter_posts_usecase.dart';
import '../../../domain/usecases/get_authors_usecase.dart';
import '../../../domain/usecases/get_cached_posts_usecase.dart';
import '../../../domain/usecases/get_posts_usecase.dart';
import '../../../domain/usecases/local_posts_usecases.dart';

part 'posts_state.dart';

/// Список постов. Знает только о UseCase: ни Dio, ни репозиториев здесь нет.
class PostsCubit extends Cubit<PostsState> {
  final GetPostsUseCase _getPosts;
  final GetCachedPostsUseCase _getCachedPosts;
  final GetAuthorsUseCase _getAuthors;
  final GetLocalPostsUseCase _getLocalPosts;
  final SaveLocalPostUseCase _saveLocalPost;
  final FilterPostsUseCase _filterPosts;

  PostsCubit({
    required this._getPosts,
    required this._getCachedPosts,
    required this._getAuthors,
    required this._getLocalPosts,
    required this._saveLocalPost,
    required this._filterPosts,
  }) : super(const PostsState());

  static const pageSize = ApiConstants.pageSize;

  /// «Поколение» запросов. При смене автора оно растёт, и ответы старых
  /// запросов игнорируются, поэтому результаты разных фильтров не смешиваются.
  int _generation = 0;
  bool _firstPageInFlight = false;

  /// Пересчитывает видимые списки при каждом изменении данных или фильтра.
  void _update(PostsState next) {
    if (isClosed) return;
    emit(next.copyWith(
      visiblePosts: _filterPosts(next.posts, next.filter),
      visibleLocalPosts: _filterPosts(next.localPosts, next.filter),
    ));
  }

  Future<void> init() async {
    if (state.status != ListStatus.initial) return; // уже запускали
    final local = await _getLocalPosts();
    local.fold((_) {}, (posts) => _update(state.copyWith(localPosts: posts)));
    unawaited(_loadAuthors());
    await loadFirstPage();
  }

  Future<void> _loadAuthors() async {
    final result = await _getAuthors();
    // Без списка авторов приложение работает: будет «Пользователь N».
    result.fold((_) {}, (authors) => _update(state.copyWith(authors: authors)));
  }

  /// Первая страница: сначала кэш (если есть), затем свежие данные.
  Future<void> loadFirstPage({bool refresh = false}) async {
    final generation = ++_generation;
    final userId = state.filter.userId;
    _firstPageInFlight = true;

    try {
      if (refresh) {
        _update(state.copyWith(isRefreshing: true, loadMoreFailure: null));
      } else {
        final cached = (await _getCachedPosts(userId)).toNullable();
        if (generation != _generation) return;
        if (cached != null && cached.data.isNotEmpty) {
          _update(state.copyWith(
            status: ListStatus.success,
            posts: cached.data,
            page: (cached.data.length / pageSize).ceil(),
            hasMore: true,
            isFromCache: true,
            cachedAt: cached.savedAt,
            failure: null,
            loadMoreFailure: null,
          ));
        } else {
          _update(state.copyWith(
            status: ListStatus.loading,
            posts: const [],
            page: 0,
            hasMore: true,
            isFromCache: false,
            cachedAt: null,
            failure: null,
            loadMoreFailure: null,
          ));
        }
      }

      final result = await _getPosts(
          GetPostsParams(page: 1, limit: pageSize, userId: userId));
      if (generation != _generation || isClosed) return;

      result.fold(
        (failure) {
          if (state.posts.isNotEmpty) {
            // Последний успешный результат не удаляем — показываем его как кэш.
            _update(state.copyWith(
              status: ListStatus.success,
              isFromCache: true,
              isRefreshing: false,
              failure: failure,
            ));
          } else {
            _update(state.copyWith(
              status: state.localPosts.isEmpty
                  ? ListStatus.failure
                  : ListStatus.success,
              isRefreshing: false,
              failure: failure,
            ));
          }
        },
        (posts) => _update(state.copyWith(
          status: posts.isEmpty && state.localPosts.isEmpty
              ? ListStatus.empty
              : ListStatus.success,
          posts: posts,
          page: 1,
          hasMore: posts.length >= pageSize,
          isFromCache: false,
          cachedAt: null,
          isRefreshing: false,
          failure: null,
          loadMoreFailure: null,
        )),
      );
    } finally {
      if (generation == _generation) _firstPageInFlight = false;
    }
  }

  /// Следующая страница при прокрутке. Пока страница грузится, повторные
  /// вызовы игнорируются: одна и та же страница не запрашивается дважды.
  Future<void> loadNextPage() async {
    if (state.status != ListStatus.success ||
        !state.hasMore ||
        state.isLoadingMore ||
        _firstPageInFlight) {
      return;
    }
    final generation = _generation;
    final nextPage = state.page + 1;
    _update(state.copyWith(isLoadingMore: true, loadMoreFailure: null));

    final result = await _getPosts(GetPostsParams(
        page: nextPage, limit: pageSize, userId: state.filter.userId));
    if (generation != _generation || isClosed) return;

    result.fold(
      (failure) => _update(
          state.copyWith(isLoadingMore: false, loadMoreFailure: failure)),
      (newPosts) {
        final ids = state.posts.map((p) => p.id).toSet();
        _update(state.copyWith(
          posts: [
            ...state.posts,
            ...newPosts.where((p) => !ids.contains(p.id)),
          ],
          page: nextPage,
          hasMore: newPosts.length >= pageSize,
          isLoadingMore: false,
        ));
      },
    );
  }

  /// Pull-to-refresh. Если обновление уже идёт, второй запрос не нужен.
  Future<void> refresh() async {
    if (state.isRefreshing) return;
    await loadFirstPage(refresh: state.status == ListStatus.success);
  }

  // ---------- Фильтры ----------

  /// null — все посты, иначе посты выбранного автора (запрос к серверу).
  Future<void> selectAuthor(int? userId) async {
    if (userId == state.filter.userId) return;
    _update(state.copyWith(
      filter: state.filter.copyWith(userId: () => userId),
      posts: const [],
      page: 0,
      hasMore: true,
      isLoadingMore: false,
      loadMoreFailure: null,
    ));
    await loadFirstPage();
  }

  /// Поиск идёт по уже загруженным постам, без запросов к серверу.
  void search(String query) {
    if (query == state.filter.query) return;
    _update(state.copyWith(filter: state.filter.copyWith(query: query)));
  }

  void toggleSort() => _update(state.copyWith(
      filter: state.filter.copyWith(ascending: !state.filter.ascending)));

  Future<void> resetFilters() async {
    final authorChanged = state.filter.userId != null;
    _update(state.copyWith(
        filter: state.filter.copyWith(query: '', ascending: true)));
    if (authorChanged) await selectAuthor(null);
  }

  // ---------- Локальные посты ----------

  /// Возвращает Failure, если пост не удалось сохранить.
  Future<Failure?> addCreatedPost(Post serverPost) async {
    final result = await _saveLocalPost(serverPost);
    return result.fold((failure) => failure, (local) {
      _update(state.copyWith(
        localPosts: [local, ...state.localPosts],
        status: state.status == ListStatus.empty ||
                state.status == ListStatus.failure
            ? ListStatus.success
            : state.status,
      ));
      return null;
    });
  }
}
