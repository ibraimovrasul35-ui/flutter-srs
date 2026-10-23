import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';
import 'post_filters.dart';

part 'posts_state.dart';

class PostsCubit extends Cubit<PostsState> {
  final PostRepository _repository;

  PostsCubit(this._repository) : super(const PostsState());

  /// Номер «поколения» запросов. При смене фильтра он увеличивается,
  /// и ответы старых запросов игнорируются — результаты не смешиваются.
  int _generation = 0;
  CancelToken? _cancelToken;
  bool _firstPageInFlight = false;

  Future<void> init() async {
    emit(state.copyWith(localPosts: _repository.getLocalPosts()));
    _loadUsers();
    await loadFirstPage();
  }

  Future<void> _loadUsers() async {
    final cached = _repository.getCachedUsers();
    if (cached != null && !isClosed) emit(state.copyWith(users: cached.data));
    try {
      final users = await _repository.fetchUsers();
      if (!isClosed) emit(state.copyWith(users: users));
    } on AppException {
      // Без списка авторов приложение работает: в фильтре будут «Пользователь N».
    }
  }

  /// Первая страница: сначала кэш (если есть), затем свежие данные с сервера.
  Future<void> loadFirstPage({bool refresh = false}) async {
    _cancelToken?.cancel('Новый запрос первой страницы');
    final token = _cancelToken = CancelToken();
    final generation = ++_generation;
    final userId = state.selectedUserId;
    _firstPageInFlight = true;

    if (refresh) {
      emit(state.copyWith(isRefreshing: true, loadMoreError: null));
    } else {
      final cached = _repository.getCachedPosts(userId: userId);
      if (cached != null) {
        emit(state.copyWith(
          status: ListStatus.success,
          posts: cached.data,
          page: (cached.data.length / PostRepository.pageSize).ceil(),
          hasMore: true,
          isFromCache: true,
          cachedAt: cached.savedAt,
          errorMessage: null,
          loadMoreError: null,
        ));
      } else {
        emit(state.copyWith(
          status: ListStatus.loading,
          posts: const [],
          page: 0,
          hasMore: true,
          isFromCache: false,
          cachedAt: null,
          errorMessage: null,
          loadMoreError: null,
        ));
      }
    }

    try {
      final posts = await _repository.fetchPosts(
          page: 1, userId: userId, cancelToken: token);
      if (generation != _generation || isClosed) return;
      emit(state.copyWith(
        status: ListStatus.success,
        posts: posts,
        page: 1,
        hasMore: posts.length >= PostRepository.pageSize,
        isFromCache: false,
        cachedAt: null,
        isRefreshing: false,
        errorMessage: null,
        loadMoreError: null,
      ));
    } on AppException catch (e) {
      if (generation != _generation || isClosed) return;
      if (e.type == AppErrorType.cancelled) return;
      if (state.posts.isNotEmpty) {
        // Последний успешный результат не удаляем — показываем его как кэш.
        emit(state.copyWith(
          status: ListStatus.success,
          isFromCache: true,
          isRefreshing: false,
          errorMessage: e.message,
        ));
      } else {
        emit(state.copyWith(
          status: ListStatus.failure,
          isRefreshing: false,
          errorMessage: e.message,
        ));
      }
    } finally {
      if (generation == _generation) _firstPageInFlight = false;
    }
  }

  /// Подгрузка следующей страницы при прокрутке.
  /// Защита от повторов: пока страница грузится, новые вызовы игнорируются.
  Future<void> loadNextPage() async {
    if (state.status != ListStatus.success ||
        !state.hasMore ||
        state.isLoadingMore ||
        _firstPageInFlight) {
      return;
    }
    final generation = _generation;
    final nextPage = state.page + 1;
    emit(state.copyWith(isLoadingMore: true, loadMoreError: null));

    try {
      final newPosts = await _repository.fetchPosts(
        page: nextPage,
        userId: state.selectedUserId,
        cancelToken: _cancelToken,
      );
      if (generation != _generation || isClosed) return;
      final ids = state.posts.map((p) => p.id).toSet();
      emit(state.copyWith(
        posts: [...state.posts, ...newPosts.where((p) => !ids.contains(p.id))],
        page: nextPage,
        hasMore: newPosts.length >= PostRepository.pageSize,
        isLoadingMore: false,
      ));
    } on AppException catch (e) {
      if (generation != _generation || isClosed) return;
      emit(state.copyWith(
        isLoadingMore: false,
        loadMoreError: e.type == AppErrorType.cancelled ? null : e.message,
      ));
    }
  }

  Future<void> refresh() => loadFirstPage(refresh: true);

  // ---------- Фильтры ----------

  /// null — все посты, иначе посты выбранного автора (запрос к серверу).
  Future<void> selectAuthor(int? userId) async {
    if (userId == state.selectedUserId) return;
    // Сброс страниц: старые результаты сразу убираются.
    emit(state.copyWith(
      selectedUserId: userId,
      posts: const [],
      page: 0,
      hasMore: true,
      isLoadingMore: false,
      loadMoreError: null,
    ));
    await loadFirstPage();
  }

  void search(String query) => emit(state.copyWith(query: query));

  void toggleSort() => emit(state.copyWith(sortAscending: !state.sortAscending));

  Future<void> resetFilters() async {
    final authorChanged = state.selectedUserId != null;
    emit(state.copyWith(query: '', sortAscending: true));
    if (authorChanged) await selectAuthor(null);
  }

  // ---------- Локальные посты ----------

  Future<void> addCreatedPost(Post serverPost) async {
    final local = await _repository.saveLocalPost(serverPost);
    if (!isClosed) emit(state.copyWith(localPosts: [local, ...state.localPosts]));
  }

  @override
  Future<void> close() {
    _cancelToken?.cancel('Экран закрыт');
    return super.close();
  }
}
