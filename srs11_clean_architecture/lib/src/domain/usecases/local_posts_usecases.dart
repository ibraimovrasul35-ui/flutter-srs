import 'package:fpdart/fpdart.dart';

import '../entities/post.dart';
import '../failures/failures.dart';
import '../repositories/post_repository.dart';
import 'usecase.dart';

/// Посты, созданные на этом устройстве.
class GetLocalPostsUseCase implements UseCase<List<Post>, NoParams> {
  final PostRepository _repository;

  const GetLocalPostsUseCase(this._repository);

  @override
  Future<Either<Failure, List<Post>>> call([NoParams _ = const NoParams()]) =>
      _repository.getLocalPosts();
}

/// Сохраняет ответ сервера на POST как локальный пост.
class SaveLocalPostUseCase implements UseCase<Post, Post> {
  final PostRepository _repository;

  const SaveLocalPostUseCase(this._repository);

  @override
  Future<Either<Failure, Post>> call(Post serverPost) =>
      _repository.saveLocalPost(serverPost);
}
