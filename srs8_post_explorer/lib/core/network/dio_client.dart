import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_interceptor.dart';

/// Единый HTTP-клиент приложения. Экземпляр Dio создаётся один раз
/// и переиспользуется всеми запросами.
class DioClient {
  DioClient._();

  static const baseUrl = 'https://jsonplaceholder.typicode.com';
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 15);

  static Dio? _instance;

  static Dio get instance => _instance ??= create();

  /// Отдельная фабрика нужна тестам: они подменяют адаптер на mock.
  static Dio create({
    String baseUrl = DioClient.baseUrl,
    bool enableLogging = kDebugMode,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: connectTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(ApiInterceptor());
    if (enableLogging) {
      dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: false,
          responseBody: false,
          error: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
      );
    }
    return dio;
  }
}
