import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

import 'exceptions.dart';

/// Превращает любую ошибку запроса (Dio, разбор JSON и т. д.)
/// в исключение из иерархии [AppException].
class ExceptionMapper {
  const ExceptionMapper._();

  static AppException map(Object error) {
    return switch (error) {
      AppException e => e,
      DioException e => fromDio(e),
      CheckedFromJsonException e => ParsingException(e.toString()),
      MissingRequiredKeysException e => ParsingException(e.toString()),
      FormatException e => ParsingException(e.toString()),
      TypeError e => ParsingException(e.toString()),
      _ => UnknownException(error.toString()),
    };
  }

  static AppException fromDio(DioException e) {
    final inner = e.error;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return RequestTimeoutException(e.message);
      case DioExceptionType.connectionError:
        return NetworkException(e.message);
      case DioExceptionType.badResponse:
        return fromStatus(
            e.response?.statusCode ?? 0, e.response?.data?.toString());
      case DioExceptionType.transformTimeout:
      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
        return UnknownException('${e.type.name}: ${e.message}');
      case DioExceptionType.unknown:
        // Без dart:io (чтобы работало и в web): SocketException узнаём по имени.
        final text = '${inner?.runtimeType} $inner';
        if (text.contains('SocketException') ||
            text.contains('HandshakeException') ||
            text.contains('XMLHttpRequest')) {
          return NetworkException(text);
        }
        if (inner != null && inner is! DioException) return map(inner);
        return UnknownException(text);
    }
  }

  static HttpStatusException fromStatus(int code, [String? details]) {
    if (code == 401) return UnauthorizedException(details);
    if (code == 400 || code == 422) return BadRequestException(code, details);
    if (code >= 500) return ServerException(code, details);
    return UnexpectedStatusException(code, details);
  }
}
