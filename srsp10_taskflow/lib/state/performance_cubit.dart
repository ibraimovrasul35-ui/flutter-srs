import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/performance_repository.dart';
import '../models/benchmark_result.dart';
import 'load_state.dart';

class PerformanceState extends Equatable {
  const PerformanceState({
    this.busy = false,
    this.seeded = false,
    this.status,
    this.results = const [],
  });

  final bool busy;
  final bool seeded;
  final String? status;
  final List<BenchmarkResult> results;

  @override
  List<Object?> get props => [busy, seeded, status, results];
}

class PerformanceCubit extends Cubit<PerformanceState> {
  PerformanceCubit(this._repository) : super(const PerformanceState()) {
    _repository.isSeeded().then((seeded) {
      if (!isClosed) emit(PerformanceState(seeded: seeded));
    });
  }

  final PerformanceRepository _repository;

  Future<String?> seed() => _run('Создаю 1 000 пользователей, 100 проектов и '
      '10 000 задач…', () async {
    final watch = Stopwatch()..start();
    await _repository.seedLargeDataset();
    emit(
      PerformanceState(
        seeded: true,
        status: 'Данные созданы за ${watch.elapsed.inMilliseconds} мс',
      ),
    );
  });

  Future<String?> compare() => _run('Сравниваю запросы…', () async {
    final results = await _repository.compareIndexes();
    emit(
      PerformanceState(
        seeded: state.seeded,
        status: 'Каждый запрос выполнен 30 раз, показано среднее время',
        results: results,
      ),
    );
  });

  Future<String?> clear() => _run('Удаляю нагрузочные данные…', () async {
    await _repository.clearLargeDataset();
    emit(const PerformanceState(status: 'Нагрузочные данные удалены'));
  });

  Future<String?> _run(String status, Future<void> Function() action) async {
    emit(
      PerformanceState(
        busy: true,
        seeded: state.seeded,
        status: status,
        results: state.results,
      ),
    );
    final error = await runAction(action);
    if (error != null && !isClosed) {
      emit(
        PerformanceState(
          seeded: state.seeded,
          status: error,
          results: state.results,
        ),
      );
    }
    return error;
  }
}
