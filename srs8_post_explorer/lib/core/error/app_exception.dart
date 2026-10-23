import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

enum AppErrorType {
  noConnection,
  timeout,
  client, // HTTP 4xx
  server, // HTTP 5xx
  parsing, // некорректный JSON / нет обязательного поля
  cancelled, // запрос отменён (например, сменился фильтр)
  unknown,
}

/// Единая ошибка приложения. UI показывает [message],
/// технические подробности ([details]) пишутся только в лог.
class AppException implements Exception {
  final AppErrorType type;
  final int? statusCode;
  final String? details;

  const AppException(this.type, {this.statusCode, this.details});

  String get message {
    switch (type) {
      case AppErrorType.noConnection:
        return 'Нет подключения к интернету';
      case AppErrorType.timeout:
        return 'Сервер слишком долго не отвечает. Попробуйте ещё раз';
      case AppErrorType.client:
        if (statusCode == 404) return 'Данные не найдены (404)';
        return 'Некорректный запрос (ошибка $statusCode)';
      case AppErrorType.server:
        return 'Ошибка на сервере ($statusCode). Попробуйте позже';
      case AppErrorType.parsing:
        return 'Сервер вернул данные в неожиданном формате';
      case AppErrorType.cancelled:
        return 'Запрос отменён';
      case AppErrorType.unknown:
        return 'Что-то пошло не так. Попробуйте ещё раз';
    }
  }

  @override
  String toString() =>
      'AppException($type, status: $statusCode, details: $details)';
}

/// Централизованное преобразование любых ошибок в [AppException].
class ErrorMapper {
  const ErrorMapper._();

  static AppException map(Object error, [StackTrace? stackTrace]) {
    final AppException result = switch (error) {
      AppException e => e,
      DioException e => fromDio(e),
      CheckedFromJsonException e =>
        AppException(AppErrorType.parsing, details: e.toString()),
      MissingRequiredKeysException e =>
        AppException(AppErrorType.parsing, details: e.toString()),
      FormatException e =>
        AppException(AppErrorType.parsing, details: e.toString()),
      TypeError e => AppException(AppErrorType.parsing, details: e.toString()),
      _ => AppException(AppErrorType.unknown, details: error.toString()),
    };
    if (result.type != AppErrorType.cancelled) {
      developer.log(
        result.toString(),
        name: 'PostExplorer.error',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return result;
  }

  static AppException fromDio(DioException e) {
    // Interceptor уже мог положить готовую ошибку в e.error.
    final inner = e.error;
    if (inner is AppException) return inner;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return AppException(AppErrorType.timeout, details: e.message);
      case DioExceptionType.connectionError:
        return AppException(AppErrorType.noConnection, details: e.message);
      case DioExceptionType.cancel:
        return const AppException(AppErrorType.cancelled);
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode ?? 0;
        if (code >= 500) {
          return AppException(AppErrorType.server,
              statusCode: code, details: e.response?.data?.toString());
        }
        return AppException(AppErrorType.client,
            statusCode: code, details: e.response?.data?.toString());
      case DioExceptionType.badCertificate:
        return AppException(AppErrorType.unknown, details: e.message);
      case DioExceptionType.unknown:
        // Без dart:io (чтобы работало и в web): SocketException узнаём по имени.
        final text = '${inner?.runtimeType} $inner';
        if (text.contains('SocketException') ||
            text.contains('HandshakeException') ||
            text.contains('XMLHttpRequest')) {
          return AppException(AppErrorType.noConnection, details: text);
        }
        if (inner is FormatException) {
          return AppException(AppErrorType.parsing, details: text);
        }
        return AppException(AppErrorType.unknown, details: text);
    }
  }
}
