import 'package:flutter_test/flutter_test.dart';
import 'package:srsp10_taskflow/data/repositories/performance_repository.dart';
import 'package:srsp10_taskflow/models/task_filter.dart';

import 'helpers.dart';

void main() {
  late TestEnv env;

  setUp(() => env = TestEnv());
  tearDown(() => env.dispose());

  test('нагрузочные данные 1000 / 100 / 10 000 и сравнение индексов', () async {
    final perf = PerformanceRepository(env.db);
    await perf.seedLargeDataset();

    expect((await env.users.getUsers()).length, 1000);
    expect((await env.projects.getProjects()).length, 100);
    expect(await env.tasks.countTasks(const TaskFilter()), 10000);

    // Пагинация на большой выборке.
    final page = await env.tasks.getTasks(
      const TaskFilter(query: 'Дизайн'),
      limit: 30,
      offset: 30,
    );
    expect(page, hasLength(30));

    final results = await perf.compareIndexes(runs: 5);
    expect(results, hasLength(5));
    expect(
      results.every((r) => r.withIndexMs > 0 && r.withoutIndexMs > 0),
      isTrue,
    );

    // После замера индексы восстановлены.
    final indexes = await env.db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name LIKE 'idx_tasks_%'",
        )
        .get();
    expect(indexes, hasLength(env.db.taskIndexes.length));

    // ignore: avoid_print
    for (final r in results) {
      // ignore: avoid_print
      print(
        '${r.query}: ${r.withIndexMs.toStringAsFixed(2)} мс с индексом, '
        '${r.withoutIndexMs.toStringAsFixed(2)} мс без индекса '
        '(×${r.speedup.toStringAsFixed(1)})',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
