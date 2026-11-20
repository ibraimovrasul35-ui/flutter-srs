import 'package:fpdart/fpdart.dart';

import '../entities/author.dart';
import '../failures/failures.dart';

abstract interface class AuthorRepository {
  /// Список авторов. Загружается с сервера один раз за запуск;
  /// без интернета отдаётся сохранённая копия.
  Future<Either<Failure, List<Author>>> getAuthors();

  /// Автор по id. Если список авторов уже загружен, запроса не будет.
  Future<Either<Failure, Author>> getAuthor(int id);
}
