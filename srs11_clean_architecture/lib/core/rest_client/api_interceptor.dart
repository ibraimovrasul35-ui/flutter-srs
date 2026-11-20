import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../constants/api_constants.dart';

/// Добавляет технические заголовки к каждому запросу и пишет ошибки в лог.
/// Ошибки в исключения приложения превращает Data Layer
/// (`src/data/exceptions/exception_mapper.dart`).
class ApiInterceptor extends Interceptor {
  int _counter = 0;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _counter++;
    options.headers.addAll({
      'Accept': 'application/json',
      'X-App-Name': ApiConstants.appName,
      'X-App-Version': ApiConstants.appVersion,
      'X-Request-Id': '${DateTime.now().millisecondsSinceEpoch}-$_counter',
    });
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    developer.log(
      '${err.requestOptions.method} ${err.requestOptions.uri} -> '
      '${err.response?.statusCode ?? err.type.name}',
      name: 'PostExplorer.http',
      error: err.message,
    );
    handler.next(err);
  }
}
