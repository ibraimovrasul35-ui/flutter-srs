import 'dart:convert';
import 'dart:developer' as developer;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/comment.dart';
import '../models/post.dart';
import '../models/user.dart';

/// Данные из кэша вместе со временем сохранения.
class Cached<T> {
  final T data;
  final DateTime savedAt;

  const Cached(this.data, this.savedAt);
}

/// Простой локальный кэш на SharedPreferences.
/// Данные хранятся как JSON-строка: {"savedAt": "...", "data": [...]}.
class PostCache {
  final SharedPreferences _prefs;

  PostCache(this._prefs);

  static const _prefix = 'cache_v1_';
  static const _localPostsKey = '${_prefix}local_posts';
  static const _usersKey = '${_prefix}users';

  static String postsKey(int? userId) =>
      userId == null ? '${_prefix}posts_all' : '${_prefix}posts_user_$userId';
  static String postKey(int id) => '${_prefix}post_$id';
  static String commentsKey(int postId) => '${_prefix}comments_$postId';

  // ---------- Посты списка ----------

  Cached<List<Post>>? readPosts(int? userId) =>
      _readList(postsKey(userId), Post.fromJson);

  Future<void> savePosts(int? userId, List<Post> posts) =>
      _writeList(postsKey(userId), posts.map((p) => p.toJson()).toList());

  // ---------- Детали поста ----------

  Cached<Post>? readPost(int id) {
    final cached = _readList(postKey(id), Post.fromJson);
    if (cached == null || cached.data.isEmpty) return null;
    return Cached(cached.data.first, cached.savedAt);
  }

  Future<void> savePost(Post post) => _writeList(postKey(post.id), [post.toJson()]);

  Cached<List<Comment>>? readComments(int postId) =>
      _readList(commentsKey(postId), Comment.fromJson);

  Future<void> saveComments(int postId, List<Comment> comments) => _writeList(
      commentsKey(postId), comments.map((c) => c.toJson()).toList());

  // ---------- Авторы ----------

  Cached<List<User>>? readUsers() => _readList(_usersKey, User.fromJson);

  Future<void> saveUsers(List<User> users) =>
      _writeList(_usersKey, users.map((u) => u.toJson()).toList());

  // ---------- Посты, созданные локально ----------

  List<Post> readLocalPosts() {
    final cached = _readList(_localPostsKey, Post.fromJson);
    return cached?.data.map((p) => p.copyWith(isLocal: true)).toList() ?? [];
  }

  Future<void> saveLocalPosts(List<Post> posts) =>
      _writeList(_localPostsKey, posts.map((p) => p.toJson()).toList());

  // ---------- Общие методы ----------

  Cached<List<T>>? _readList<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final list = (decoded['data'] as List)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
      return Cached(list, DateTime.parse(decoded['savedAt'] as String));
    } catch (e) {
      // Повреждённый кэш не должен ронять приложение — просто игнорируем.
      developer.log('Broken cache for $key: $e', name: 'PostExplorer.cache');
      return null;
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> data) {
    return _prefs.setString(
      key,
      jsonEncode({'savedAt': DateTime.now().toIso8601String(), 'data': data}),
    );
  }
}
