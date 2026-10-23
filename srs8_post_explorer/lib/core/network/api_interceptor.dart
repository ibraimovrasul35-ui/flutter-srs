import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../error/app_exception.dart';

/// Собственный interceptor:
/// * добавляет технические заголовки к каждому запросу;
/// * централизованно превращает ошибки Dio в [AppException]
///   (кладёт её в `DioException.error`), подробности пишет в лог.
class ApiInterceptor extends Interceptor {
  static const appName = 'PostExplorer';
  static const appVersion = '1.0.0';

  int _counter = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _counter++;
    options.headers.addAll({
      'Accept': 'application/json',
      'X-App-Name': appName,
      'X-App-Version': appVersion,
      'X-Request-Id': '${DateTime.now().millisecondsSinceEpoch}-$_counter',
    });
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final appException = ErrorMapper.fromDio(err);
    if (appException.type != AppErrorType.cancelled) {
      developer.log(
        '${err.requestOptions.method} ${err.requestOptions.uri} -> '
        '${err.response?.statusCode ?? err.type.name}',
        name: 'PostExplorer.http',
        error: err.message,
      );
    }
    handler.next(err.copyWith(error: appException));
  }
}
