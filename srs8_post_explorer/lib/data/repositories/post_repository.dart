import 'package:dio/dio.dart';

import '../../core/error/app_exception.dart';
import '../local/post_cache.dart';
import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';
import '../remote/post_api.dart';

/// Единственная точка доступа к данным для UI.
/// Объединяет сервер (Retrofit) и локальный кэш, а все ошибки
/// превращает в [AppException]. UI не знает о Dio.
class PostRepository {
  final PostApi _api;
  final PostCache _cache;

  PostRepository({required this._api, required this._cache});

  static const pageSize = 10;

  // ---------- Список постов ----------

  /// Сохранённые посты для фильтра (null — кэша ещё нет).
  Cached<List<Post>>? getCachedPosts({int? userId}) =>
      _cache.readPosts(userId);

  /// Загружает страницу с сервера и обновляет кэш.
  /// Страница 1 перезаписывает кэш, следующие дописываются к нему.
  Future<List<Post>> fetchPosts({
    required int page,
    int limit = pageSize,
    int? userId,
    CancelToken? cancelToken,
  }) async {
    final posts = await _guard(() => userId == null
        ? _api.getPosts(page, limit, cancelToken: cancelToken)
        : _api.getPostsByUser(userId,
            page: page, limit: limit, cancelToken: cancelToken));

    if (page == 1) {
      await _cache.savePosts(userId, posts);
    } else {
      final old = _cache.readPosts(userId)?.data ?? const <Post>[];
      final ids = old.map((p) => p.id).toSet();
      await _cache.savePosts(
          userId, [...old, ...posts.where((p) => !ids.contains(p.id))]);
    }
    return posts;
  }

  // ---------- Детали ----------

  Cached<Post>? getCachedPost(int id) => _cache.readPost(id);

  Cached<List<Comment>>? getCachedComments(int postId) =>
      _cache.readComments(postId);

  Future<Post> fetchPost(int id) async {
    final post = await _guard(() => _api.getPost(id));
    await _cache.savePost(post);
    return post;
  }

  Future<List<Comment>> fetchComments(int postId) async {
    final comments = await _guard(() => _api.getComments(postId));
    await _cache.saveComments(postId, comments);
    return comments;
  }

  // ---------- Авторы ----------

  Cached<List<User>>? getCachedUsers() => _cache.readUsers();

  Future<List<User>> fetchUsers() async {
    final users = await _guard(() => _api.getUsers());
    await _cache.saveUsers(users);
    return users;
  }

  Future<User> fetchUser(int id) => _guard(() => _api.getUser(id));

  // ---------- Создание поста ----------

  /// Отправляет POST. Возвращает объект, который вернул сервер
  /// (JSONPlaceholder всегда отдаёт id = 101 и ничего не сохраняет).
  Future<Post> createPost({
    required String title,
    required String body,
    required int userId,
  }) {
    return _guard(() => _api.createPost(
        CreatePostRequest(title: title, body: body, userId: userId)));
  }

  /// Сохраняет созданный пост локально с пометкой «создан локально».
  /// Чтобы id не пересекались (сервер всегда даёт 101), локальным
  /// постам выдаётся отрицательный id.
  Future<Post> saveLocalPost(Post serverPost) async {
    final local = serverPost.copyWith(
      id: -DateTime.now().millisecondsSinceEpoch,
      isLocal: true,
    );
    await _cache.saveLocalPosts([local, ..._cache.readLocalPosts()]);
    return local;
  }

  List<Post> getLocalPosts() => _cache.readLocalPosts();

  // ---------- Общая обработка ошибок ----------

  Future<T> _guard<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e, st) {
      throw ErrorMapper.map(e, st);
    }
  }
}
