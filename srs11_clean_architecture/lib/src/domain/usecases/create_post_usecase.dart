import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/post.dart';
import '../failures/failures.dart';
import '../repositories/post_repository.dart';
import '../validators/post_validator.dart';
import 'usecase.dart';

class CreatePostParams extends Equatable {
  final String title;
  final String body;
  final int? userId;

  const CreatePostParams({
    required this.title,
    required this.body,
    required this.userId,
  });

  @override
  List<Object?> get props => [title, body, userId];
}

/// Проверяет данные и отправляет POST /posts.
/// Если данные неверны, запрос не отправляется, а возвращается
/// ValidationFailure с понятным текстом.
class CreatePostUseCase implements UseCase<Post, CreatePostParams> {
  final PostRepository _repository;

  const CreatePostUseCase(this._repository);

  @override
  Future<Either<Failure, Post>> call(CreatePostParams params) async {
    final error = PostValidator.title(params.title) ??
        PostValidator.body(params.body) ??
        PostValidator.author(params.userId);
    if (error != null) return Left(ValidationFailure(error));

    return _repository.createPost(
      title: params.title.trim(),
      body: params.body.trim(),
      userId: params.userId!,
    );
  }
}
