import 'dart:developer' as developer;

import 'package:fpdart/fpdart.dart';

import '../../../models/comment_model.dart';
import '../../../models/post_model.dart';
import '../../domain/entities/cached.dart';
import '../../domain/entities/post.dart';
import '../../domain/entities/post_details.dart';
import '../../domain/failures/failures.dart';
import '../../domain/repositories/post_repository.dart';
import '../datasources/post_local_data_source.dart';
import '../datasources/post_remote_data_source.dart';
import '../mapper/failure_mapper.dart';
import '../mapper/post_mapper.dart';

/// Объединяет сервер и локальный кэш. Наружу отдаёт только сущности
/// и `Either<Failure, T>`: исключения и DTO остаются внутри Data Layer.
class PostRepositoryImpl implements PostRepository {
  final PostRemoteDataSource _remote;
  final PostLocalDataSource _local;

  const PostRepositoryImpl({
    required this._remote,
    required this._local,
  });

  @override
  Future<Either<Failure, List<Post>>> getPosts({
    required int page,
    required int limit,
    int? userId,
  }) {
    return guard(() async {
      final models =
          await _remote.getPosts(page: page, limit: limit, userId: userId);
      await _updateListCache(userId, page, models);
      return models.map((m) => m.toEntity()).toList();
    });
  }

  /// Страница 1 перезаписывает кэш, следующие дописываются без дубликатов.
  Future<void> _updateListCache(
      int? userId, int page, List<PostModel> models) {
    if (page == 1) return _saveQuietly(() => _local.savePosts(userId, models));
    final old = _local.readPosts(userId)?.data ?? const <PostModel>[];
    final ids = old.map((p) => p.id).toSet();
    return _saveQuietly(() => _local.savePosts(
        userId, [...old, ...models.where((p) => !ids.contains(p.id))]));
  }

  @override
  Future<Either<Failure, Cached<List<Post>>?>> getCachedPosts({int? userId}) {
    return guard(() async {
      final cached = _local.readPosts(userId);
      if (cached == null) return null;
      return Cached(
        cached.data.map((m) => m.toEntity()).toList(),
        cached.savedAt,
      );
    });
  }

  @override
  Future<Either<Failure, PostDetails>> getPostDetails(int postId) {
    return guard(() async {
      // Оба запроса идут параллельно. Future.wait сообщает первую ошибку
      // и не оставляет вторую необработанной.
      final results = await Future.wait<Object>([
        _remote.getPost(postId),
        _remote.getComments(postId),
      ]);
      final post = results[0] as PostModel;
      final comments = results[1] as List<CommentModel>;
      await _saveQuietly(() async {
        await _local.savePost(post);
        await _local.saveComments(postId, comments);
      });
      return PostDetails(
        post: post.toEntity(),
        comments: comments.map((c) => c.toEntity()).toList(),
      );
    });
  }

  @override
  Future<Either<Failure, Cached<PostDetails>?>> getCachedPostDetails(
      int postId) {
    return guard(() async {
      final post = _local.readPost(postId);
      final comments = _local.readComments(postId);
      if (post == null || comments == null) return null;
      return Cached(
        PostDetails(
          post: post.data.toEntity(),
          comments: comments.data.map((c) => c.toEntity()).toList(),
        ),
        comments.savedAt,
      );
    });
  }

  @override
  Future<Either<Failure, Post>> createPost({
    required String title,
    required String body,
    required int userId,
  }) {
    return guard(() async {
      final model = await _remote.createPost(
          CreatePostRequestModel(title: title, body: body, userId: userId));
      return model.toEntity();
    });
  }

  /// JSONPlaceholder всегда выдаёт новому посту id = 101 и ничего не
  /// сохраняет. Чтобы id не пересекались, локальный пост получает
  /// отрицательный id.
  @override
  Future<Either<Failure, Post>> saveLocalPost(Post serverPost) {
    return guard(() async {
      final local = serverPost.copyWith(
        id: -DateTime.now().millisecondsSinceEpoch,
        isLocal: true,
      );
      await _local.saveLocalPosts([local.toModel(), ..._local.readLocalPosts()]);
      return local;
    });
  }

  @override
  Future<Either<Failure, List<Post>>> getLocalPosts() {
    return guard(() async => _local
        .readLocalPosts()
        .map((m) => m.toEntity(isLocal: true))
        .toList());
  }

  /// Ошибка записи кэша не должна ломать успешный ответ сервера.
  Future<void> _saveQuietly(Future<void> Function() save) async {
    try {
      await save();
    } catch (e) {
      developer.log('Cache write failed: $e', name: 'PostExplorer.cache');
    }
  }
}
