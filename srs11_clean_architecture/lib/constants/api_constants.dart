/// Настройки REST API в одном месте.
class ApiConstants {
  const ApiConstants._();

  static const baseUrl = 'https://jsonplaceholder.typicode.com';
  static const connectTimeout = Duration(seconds: 10);
  static const receiveTimeout = Duration(seconds: 15);

  /// Размер страницы при пагинации списка постов.
  static const pageSize = 10;

  static const appName = 'PostExplorer';
  static const appVersion = '2.0.0';
}
