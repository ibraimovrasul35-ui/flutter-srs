import 'package:fpdart/fpdart.dart';

import '../entities/post_details.dart';
import '../failures/failures.dart';
import '../repositories/post_repository.dart';
import 'usecase.dart';

/// Пост и комментарии к нему с сервера.
class GetPostDetailsUseCase implements UseCase<PostDetails, int> {
  final PostRepository _repository;

  const GetPostDetailsUseCase(this._repository);

  @override
  Future<Either<Failure, PostDetails>> call(int postId) =>
      _repository.getPostDetails(postId);
}
