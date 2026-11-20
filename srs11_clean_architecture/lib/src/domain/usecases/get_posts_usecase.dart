import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../entities/post.dart';
import '../failures/failures.dart';
import '../repositories/post_repository.dart';
import 'usecase.dart';

class GetPostsParams extends Equatable {
  final int page;
  final int limit;
  final int? userId;

  const GetPostsParams({required this.page, required this.limit, this.userId});

  @override
  List<Object?> get props => [page, limit, userId];
}

/// Загружает страницу постов (все или конкретного автора).
class GetPostsUseCase implements UseCase<List<Post>, GetPostsParams> {
  final PostRepository _repository;

  const GetPostsUseCase(this._repository);

  @override
  Future<Either<Failure, List<Post>>> call(GetPostsParams params) {
    if (params.page < 1) {
      return Future.value(
          const Left(ValidationFailure('Номер страницы должен быть ≥ 1')));
    }
    return _repository.getPosts(
      page: params.page,
      limit: params.limit,
      userId: params.userId,
    );
  }
}
