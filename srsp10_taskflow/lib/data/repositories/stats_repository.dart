import 'package:drift/drift.dart';

import '../../models/dashboard_stats.dart';
import '../../models/enums.dart';
import '../database/app_database.dart';

/// Статистика для Dashboard. Все числа считает SQLite (COUNT/SUM/GROUP BY).
class StatsRepository {
  StatsRepository(this._db);

  final AppDatabase _db;

  /// Пересчитывает статистику при любом изменении задач, проектов или людей.
  Stream<DashboardStats> watchStats() async* {
    yield await getStats();
    final updates = _db.tableUpdates(
      TableUpdateQuery.onAllTables([_db.tasks, _db.projects, _db.users]),
    );
    await for (final _ in updates) {
      yield await getStats();
    }
  }

  Future<DashboardStats> getStats() async {
    final totals = await _db
        .customSelect(
          'SELECT '
          '(SELECT COUNT(*) FROM projects) AS projects, '
          'COUNT(*) AS total, '
          "COALESCE(SUM(status = 'done'), 0) AS done, "
          "COALESCE(SUM(status IN ('todo', 'inProgress')), 0) AS open, "
          "COALESCE(SUM(status IN ('todo', 'inProgress') "
          'AND deadline IS NOT NULL AND deadline < ?), 0) AS overdue '
          'FROM tasks WHERE deleted_at IS NULL',
          variables: [Variable.withDateTime(DateTime.now())],
          readsFrom: {_db.tasks, _db.projects},
        )
        .getSingle();

    final priorityRows = await _db
        .customSelect(
          'SELECT priority, COUNT(*) AS c FROM tasks '
          'WHERE deleted_at IS NULL GROUP BY priority',
          readsFrom: {_db.tasks},
        )
        .get();
    final byPriority = {for (final p in TaskPriority.values) p: 0};
    for (final row in priorityRows) {
      byPriority[TaskPriority.values.byName(row.read<String>('priority'))] = row
          .read<int>('c');
    }

    final assigneeRows = await _db
        .customSelect(
          'SELECT u.name AS name, COUNT(t.id) AS c FROM tasks t '
          'JOIN users u ON u.id = t.assignee_id '
          'WHERE t.deleted_at IS NULL '
          'GROUP BY u.id ORDER BY c DESC, u.name LIMIT 50',
          readsFrom: {_db.tasks, _db.users},
        )
        .get();

    final projectRows = await _db
        .customSelect(
          'SELECT p.name AS name, COUNT(t.id) AS total, '
          "COALESCE(SUM(t.status = 'done'), 0) AS done, "
          "COALESCE(SUM(t.status = 'cancelled'), 0) AS cancelled "
          'FROM projects p '
          'LEFT JOIN tasks t ON t.project_id = p.id AND t.deleted_at IS NULL '
          'GROUP BY p.id ORDER BY p.name LIMIT 100',
          readsFrom: {_db.tasks, _db.projects},
        )
        .get();

    return DashboardStats(
      projects: totals.read<int>('projects'),
      totalTasks: totals.read<int>('total'),
      doneTasks: totals.read<int>('done'),
      openTasks: totals.read<int>('open'),
      overdueTasks: totals.read<int>('overdue'),
      byPriority: byPriority,
      byAssignee: [
        for (final row in assigneeRows)
          AssigneeLoad(row.read<String>('name'), row.read<int>('c')),
      ],
      projectProgress: [for (final row in projectRows) _progress(row)],
    );
  }

  ProjectProgress _progress(QueryRow row) {
    final total = row.read<int>('total');
    final done = row.read<int>('done');
    final relevant = total - row.read<int>('cancelled');
    return ProjectProgress(
      name: row.read<String>('name'),
      total: total,
      done: done,
      percent: relevant == 0 ? 0 : done * 100 / relevant,
    );
  }
}
