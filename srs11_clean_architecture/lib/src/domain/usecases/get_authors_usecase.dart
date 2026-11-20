import 'package:fpdart/fpdart.dart';

import '../entities/author.dart';
import '../failures/failures.dart';
import '../repositories/author_repository.dart';
import 'usecase.dart';

class GetAuthorsUseCase implements UseCase<List<Author>, NoParams> {
  final AuthorRepository _repository;

  const GetAuthorsUseCase(this._repository);

  @override
  Future<Either<Failure, List<Author>>> call([NoParams _ = const NoParams()]) =>
      _repository.getAuthors();
}
