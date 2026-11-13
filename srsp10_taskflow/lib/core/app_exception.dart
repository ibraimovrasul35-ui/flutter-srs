/// Ошибка бизнес-логики или проверки данных, текст показывается пользователю.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
