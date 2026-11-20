import 'package:fpdart/fpdart.dart';

import '../entities/cached.dart';
import '../entities/post.dart';
import '../entities/post_details.dart';
import '../failures/failures.dart';

/// Контракт работы с постами. Реализация — `PostRepositoryImpl`
/// в Data Layer; Domain и Presentation знают только этот интерфейс.
abstract interface class PostRepository {
  /// Страница постов с сервера (и обновление кэша).
  /// [userId] == null — все посты, иначе посты автора.
  Future<Either<Failure, List<Post>>> getPosts({
    required int page,
    required int limit,
    int? userId,
  });

  /// Сохранённый список для фильтра или null, если кэша ещё нет.
  Future<Either<Failure, Cached<List<Post>>?>> getCachedPosts({int? userId});

  /// Пост и его комментарии с сервера (и обновление кэша).
  Future<Either<Failure, PostDetails>> getPostDetails(int postId);

  Future<Either<Failure, Cached<PostDetails>?>> getCachedPostDetails(
      int postId);

  /// POST /posts. Возвращает пост, который вернул сервер.
  Future<Either<Failure, Post>> createPost({
    required String title,
    required String body,
    required int userId,
  });

  /// Сохраняет созданный пост на устройстве с пометкой «создан локально».
  Future<Either<Failure, Post>> saveLocalPost(Post serverPost);

  Future<Either<Failure, List<Post>>> getLocalPosts();
}
