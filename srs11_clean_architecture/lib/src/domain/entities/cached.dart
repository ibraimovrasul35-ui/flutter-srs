import 'package:equatable/equatable.dart';

/// Данные из локального кэша и время, когда они были сохранены.
/// Нужны, чтобы сразу показать прошлый результат (offline),
/// пока с сервера грузятся свежие данные.
class Cached<T> extends Equatable {
  final T data;
  final DateTime savedAt;

  const Cached(this.data, this.savedAt);

  @override
  List<Object?> get props => [data, savedAt];
}
