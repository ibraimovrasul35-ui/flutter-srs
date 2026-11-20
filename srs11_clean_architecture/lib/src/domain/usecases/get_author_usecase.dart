import 'package:fpdart/fpdart.dart';

import '../entities/author.dart';
import '../failures/failures.dart';
import '../repositories/author_repository.dart';
import 'usecase.dart';

class GetAuthorUseCase implements UseCase<Author, int> {
  final AuthorRepository _repository;

  const GetAuthorUseCase(this._repository);

  @override
  Future<Either<Failure, Author>> call(int authorId) =>
      _repository.getAuthor(authorId);
}
