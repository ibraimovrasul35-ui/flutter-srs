import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../failures/failures.dart';

/// Базовый контракт сценария: один публичный метод `call`,
/// результат — либо Failure, либо данные.
abstract interface class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Для сценариев без параметров.
final class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => const [];
}
