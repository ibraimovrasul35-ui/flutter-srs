import 'package:fpdart/fpdart.dart';

import '../entities/cached.dart';
import '../entities/post_details.dart';
import '../failures/failures.dart';
import '../repositories/post_repository.dart';
import 'usecase.dart';

/// Сохранённые детали поста (null — кэша нет).
class GetCachedPostDetailsUseCase
    implements UseCase<Cached<PostDetails>?, int> {
  final PostRepository _repository;

  const GetCachedPostDetailsUseCase(this._repository);

  @override
  Future<Either<Failure, Cached<PostDetails>?>> call(int postId) =>
      _repository.getCachedPostDetails(postId);
}
