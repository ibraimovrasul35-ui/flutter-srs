/// Исключения Data Layer. Их бросают DataSource; репозиторий ловит их
/// и превращает в Failure (`mapper/failure_mapper.dart`), поэтому до UI
/// они не доходят.
///
/// [details] — технические подробности только для лога.
sealed class AppException implements Exception {
  final String? details;

  const AppException([this.details]);

  @override
  String toString() => '$runtimeType(${details ?? ''})';
}

/// Нет соединения с сервером (нет интернета, DNS, SSL-рукопожатие).
final class NetworkException extends AppException {
  const NetworkException([super.details]);
}

/// Сервер не ответил за отведённое время.
final class RequestTimeoutException extends AppException {
  const RequestTimeoutException([super.details]);
}

/// Ответ с HTTP-кодом ошибки.
sealed class HttpStatusException extends AppException {
  final int statusCode;

  const HttpStatusException(this.statusCode, [super.details]);

  @override
  String toString() => '$runtimeType($statusCode, ${details ?? ''})';
}

/// HTTP 5xx.
final class ServerException extends HttpStatusException {
  const ServerException(super.statusCode, [super.details]);
}

/// HTTP 401.
final class UnauthorizedException extends HttpStatusException {
  const UnauthorizedException([String? details]) : super(401, details);
}

/// HTTP 400 (и 422): сервер не принял данные запроса.
final class BadRequestException extends HttpStatusException {
  const BadRequestException(super.statusCode, [super.details]);
}

/// Остальные коды (403, 404, 409 …).
final class UnexpectedStatusException extends HttpStatusException {
  const UnexpectedStatusException(super.statusCode, [super.details]);
}

/// Сервер вернул JSON не того формата.
final class ParsingException extends AppException {
  const ParsingException([super.details]);
}

/// Не удалось записать или прочитать локальное хранилище.
final class CacheException extends AppException {
  const CacheException([super.details]);
}

/// Любая другая ошибка.
final class UnknownException extends AppException {
  const UnknownException([super.details]);
}
