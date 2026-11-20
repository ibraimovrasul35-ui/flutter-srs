import 'dart:developer' as developer;

import 'package:fpdart/fpdart.dart';

import '../../domain/failures/failures.dart';
import '../exceptions/exception_mapper.dart';
import '../exceptions/exceptions.dart';

/// Исключение Data Layer → Failure для Domain/UI.
///
/// | Ситуация            | Failure              |
/// |---------------------|----------------------|
/// | нет интернета       | NetworkFailure       |
/// | таймаут             | NetworkFailure       |
/// | 5xx                 | ServerFailure        |
/// | 401                 | UnauthorizedFailure  |
/// | 400 / 422           | ValidationFailure    |
/// | всё остальное       | UnknownFailure       |
extension AppExceptionToFailure on AppException {
  Failure toFailure() => switch (this) {
        NetworkException() => const NetworkFailure(),
        RequestTimeoutException() => const NetworkFailure.timeout(),
        ServerException() => const ServerFailure(),
        UnauthorizedException() => const UnauthorizedFailure(),
        BadRequestException() => const ValidationFailure(),
        ParsingException() => const UnknownFailure(
            'Сервер вернул данные в неожиданном формате. Попробуйте позже'),
        CacheException() =>
          const UnknownFailure('Не удалось сохранить данные на устройстве'),
        UnexpectedStatusException(statusCode: 404) =>
          const UnknownFailure('Данные не найдены'),
        UnexpectedStatusException() => const UnknownFailure(),
        UnknownException() => const UnknownFailure(),
      };
}

/// Общая обёртка для методов репозитория: выполняет [action] и
/// возвращает Right(результат) или Left(Failure). Подробности ошибки
/// уходят в лог, наружу — только понятный Failure.
Future<Either<Failure, T>> guard<T>(Future<T> Function() action) async {
  try {
    return Right(await action());
  } catch (error, stackTrace) {
    final exception = ExceptionMapper.map(error);
    developer.log(
      exception.toString(),
      name: 'PostExplorer.error',
      error: error,
      stackTrace: stackTrace,
    );
    return Left(exception.toFailure());
  }
}
