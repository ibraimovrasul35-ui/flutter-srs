import 'package:fpdart/fpdart.dart';

import '../entities/cached.dart';
import '../entities/post.dart';
import '../failures/failures.dart';
import '../repositories/post_repository.dart';
import 'usecase.dart';

/// Сохранённые посты для фильтра автора (null — все посты).
/// Результат null означает, что кэша нет.
class GetCachedPostsUseCase implements UseCase<Cached<List<Post>>?, int?> {
  final PostRepository _repository;

  const GetCachedPostsUseCase(this._repository);

  @override
  Future<Either<Failure, Cached<List<Post>>?>> call(int? userId) =>
      _repository.getCachedPosts(userId: userId);
}
