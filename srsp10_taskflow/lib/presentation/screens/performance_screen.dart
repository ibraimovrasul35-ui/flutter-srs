import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/performance_repository.dart';
import '../../models/benchmark_result.dart';
import '../../state/performance_cubit.dart';
import '../widgets/common.dart';

/// Нагрузочные данные и сравнение скорости запросов с индексами и без.
class PerformanceScreen extends StatelessWidget {
  const PerformanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          PerformanceCubit(context.read<PerformanceRepository>()),
      child: Scaffold(
        appBar: AppBar(title: const Text('Производительность')),
        body: BlocBuilder<PerformanceCubit, PerformanceState>(
          builder: (context, state) {
            final cubit = context.read<PerformanceCubit>();
            Future<void> run(Future<String?> Function() action) async {
              final error = await action();
              if (context.mounted) showResult(context, error);
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Генерация 1 000 пользователей, 100 проектов и 10 000 задач. '
                  'Затем одни и те же запросы выполняются с индексами и после '
                  'их временного удаления (DROP INDEX), чтобы увидеть разницу.',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      icon: const Icon(Icons.dataset),
                      label: const Text('Создать данные'),
                      onPressed: state.busy || state.seeded
                          ? null
                          : () => run(cubit.seed),
                    ),
                    FilledButton.tonalIcon(
                      icon: const Icon(Icons.speed),
                      label: const Text('Сравнить запросы'),
                      onPressed: state.busy || !state.seeded
                          ? null
                          : () => run(cubit.compare),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Удалить данные'),
                      onPressed: state.busy || !state.seeded
                          ? null
                          : () => run(cubit.clear),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.busy) const LinearProgressIndicator(),
                if (state.status != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(state.status!),
                  ),
                if (state.results.isNotEmpty) _ResultsTable(state.results),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResultsTable extends StatelessWidget {
  const _ResultsTable(this.results);

  final List<BenchmarkResult> results;

  String _ms(double v) => v.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          columns: const [
            DataColumn(label: Text('Запрос')),
            DataColumn(label: Text('С индексом, мс'), numeric: true),
            DataColumn(label: Text('Без индекса, мс'), numeric: true),
            DataColumn(label: Text('Ускорение'), numeric: true),
          ],
          rows: [
            for (final r in results)
              DataRow(
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 180),
                      child: Text(r.query),
                    ),
                  ),
                  DataCell(Text(_ms(r.withIndexMs))),
                  DataCell(Text(_ms(r.withoutIndexMs))),
                  DataCell(
                    Text(
                      '×${r.speedup.toStringAsFixed(1)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: r.speedup >= 1 ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
