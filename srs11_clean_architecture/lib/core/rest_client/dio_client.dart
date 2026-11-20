import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../constants/api_constants.dart';
import 'api_interceptor.dart';

/// Фабрика единого HTTP-клиента. Экземпляр создаётся один раз в DI
/// (`core/di/injection.dart`), а тесты подменяют адаптер на mock.
class DioClient {
  const DioClient._();

  static Dio create({
    String baseUrl = ApiConstants.baseUrl,
    bool enableLogging = kDebugMode,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.connectTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(ApiInterceptor());
    if (enableLogging) {
      dio.interceptors.add(
        LogInterceptor(
          requestHeader: false,
          responseBody: false,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }
    return dio;
  }
}
