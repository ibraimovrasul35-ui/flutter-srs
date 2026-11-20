import 'package:equatable/equatable.dart';

/// Ошибка, которую видит пользователь. Data Layer превращает в Failure
/// любое исключение (см. `src/data/mapper/failure_mapper.dart`).
///
/// [message] — готовый понятный текст. Технические подробности
/// (текст исключения, ответ сервера) сюда не попадают, они пишутся в лог.
sealed class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [runtimeType, message];
}

/// Нет интернета или сервер не ответил вовремя.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Нет подключения к интернету. '
      'Проверьте сеть и попробуйте ещё раз']);

  const NetworkFailure.timeout()
      : super('Сервер слишком долго не отвечает. Попробуйте ещё раз');
}

/// HTTP 5xx.
final class ServerFailure extends Failure {
  const ServerFailure(
      [super.message = 'На сервере произошла ошибка. Попробуйте позже']);
}

/// HTTP 401.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure(
      [super.message = 'Нужна авторизация: сессия истекла или нет доступа']);
}

/// HTTP 400 или данные не прошли проверку ещё до отправки.
final class ValidationFailure extends Failure {
  const ValidationFailure(
      [super.message = 'Проверьте введённые данные: сервер их не принял']);
}

/// Всё остальное: неожиданный ответ, ошибка хранилища, неизвестная ошибка.
final class UnknownFailure extends Failure {
  const UnknownFailure(
      [super.message = 'Что-то пошло не так. Попробуйте ещё раз']);
}
