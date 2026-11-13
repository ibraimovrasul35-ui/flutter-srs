import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../core/app_exception.dart';

/// Состояние загрузки данных из потока базы.
class LoadState<T> extends Equatable {
  const LoadState.loading() : data = null, error = null;
  const LoadState.data(T this.data) : error = null;
  const LoadState.error(String this.error) : data = null;

  final T? data;
  final String? error;

  bool get isLoading => data == null && error == null;

  @override
  List<Object?> get props => [data, error];
}

/// Выполняет действие и возвращает текст ошибки (null — успех).
Future<String?> runAction(Future<void> Function() action) async {
  try {
    await action();
    return null;
  } on AppException catch (e) {
    return e.message;
  } catch (e) {
    return 'Не удалось сохранить: $e';
  }
}

/// Cubit, который подписан на watch()-поток Drift: экран обновляется сам,
/// как только меняются данные в базе.
abstract class WatchCubit<T> extends Cubit<LoadState<T>> {
  WatchCubit(Stream<T> source) : super(LoadState<T>.loading()) {
    _subscription = source.listen(
      (data) => emit(LoadState.data(data)),
      onError: (Object e) => emit(LoadState.error(e.toString())),
    );
  }

  late final StreamSubscription<T> _subscription;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
