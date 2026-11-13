import 'dart:math';

import 'package:drift/drift.dart';

import '../../core/app_exception.dart';
import '../../models/benchmark_result.dart';
import '../../models/enums.dart';
import '../database/app_database.dart';

/// Нагрузочные данные и сравнение скорости запросов с индексами и без них.
class PerformanceRepository {
  PerformanceRepository(this._db);

  final AppDatabase _db;

  static const _seedEmailDomain = '@load.taskflow.test';
  static const _seedProjectPrefix = 'Нагрузочный проект';

  Future<bool> isSeeded() async {
    final row =
        await (_db.select(_db.users)
              ..where((u) => u.email.like('%$_seedEmailDomain'))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// Создаёт 1 000 пользователей, 100 проектов (по 10 участников)
  /// и 10 000 задач одной транзакцией через batch-вставку.
  Future<void> seedLargeDataset({
    int users = 1000,
    int projects = 100,
    int tasks = 10000,
    int membersPerProject = 10,
  }) async {
    if (await isSeeded()) {
      throw const AppException('Нагрузочные данные уже созданы');
    }
    final random = Random(42);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    await _db.transaction(() async {
      await _db.batch((b) {
        b.insertAll(_db.users, [
          for (var i = 1; i <= users; i++)
            UsersCompanion.insert(
              name: 'Пользователь $i',
              email: 'user$i$_seedEmailDomain',
              registeredAt: Value(now.subtract(Duration(days: i % 365))),
            ),
        ]);
        b.insertAll(_db.projects, [
          for (var i = 1; i <= projects; i++)
            ProjectsCompanion.insert(
              name: '$_seedProjectPrefix $i',
              description: Value(
                'Сгенерирован для проверки производительности',
              ),
              createdAt: Value(now.subtract(Duration(days: 200 - i))),
              status: Value(ProjectStatus.values[i % 3]),
            ),
        ]);
      });

      final userIds =
          await (_db.selectOnly(_db.users)
                ..addColumns([_db.users.id])
                ..where(_db.users.email.like('%$_seedEmailDomain'))
                ..orderBy([OrderingTerm.asc(_db.users.id)]))
              .map((r) => r.read(_db.users.id)!)
              .get();
      final projectIds =
          await (_db.selectOnly(_db.projects)
                ..addColumns([_db.projects.id])
                ..where(_db.projects.name.like('$_seedProjectPrefix %'))
                ..orderBy([OrderingTerm.asc(_db.projects.id)]))
              .map((r) => r.read(_db.projects.id)!)
              .get();

      // Участники проекта p — пользователи p*10 .. p*10+9 (по кругу).
      List<int> membersOf(int p) => [
        for (var k = 0; k < membersPerProject; k++)
          userIds[(p * membersPerProject + k) % userIds.length],
      ];

      await _db.batch((b) {
        for (var p = 0; p < projectIds.length; p++) {
          final members = membersOf(p);
          b.insertAll(_db.projectMembers, [
            for (var k = 0; k < members.length; k++)
              ProjectMembersCompanion.insert(
                projectId: projectIds[p],
                userId: members[k],
                role: k == 0
                    ? MemberRole.owner
                    : (k < 3 ? MemberRole.admin : MemberRole.member),
              ),
          ]);
        }

        final perProject = tasks ~/ projectIds.length;
        b.insertAll(_db.tasks, [
          for (var p = 0; p < projectIds.length; p++)
            for (var j = 0; j < perProject; j++)
              _seedTask(
                index: p * perProject + j,
                projectId: projectIds[p],
                assigneeId: membersOf(p)[j % membersPerProject],
                // Дедлайны разнесены так, чтобы у одного исполнителя на одну
                // дату было не больше двух задач.
                deadline: today.add(Duration(days: (j % 60) - 10)),
                createdAt: now.subtract(
                  Duration(minutes: random.nextInt(500000)),
                ),
              ),
        ]);
      });

      await _db.customStatement(
        'INSERT INTO task_history '
        '(task_id, kind, new_status, changed_at, undone) '
        "SELECT t.id, 'created', 'todo', t.created_at, 0 FROM tasks t "
        'JOIN projects p ON p.id = t.project_id '
        "WHERE p.name LIKE '$_seedProjectPrefix %'",
      );
    });
  }

  TasksCompanion _seedTask({
    required int index,
    required int projectId,
    required int assigneeId,
    required DateTime deadline,
    required DateTime createdAt,
  }) {
    const words = [
      'Дизайн',
      'Тестирование',
      'Отчёт',
      'Интеграция',
      'Рефакторинг',
      'Документация',
      'Аналитика',
      'Релиз',
    ];
    return TasksCompanion.insert(
      title: '${words[index % words.length]} #$index',
      description: Value('Нагрузочная задача $index для проекта $projectId'),
      projectId: projectId,
      assigneeId: Value(assigneeId),
      priority: Value(TaskPriority.values[index % 4]),
      status: Value(TaskStatus.values[(index ~/ 4) % 4]),
      deadline: Value(deadline),
      createdAt: createdAt,
      updatedAt: createdAt,
    );
  }

  /// Удаляет нагрузочные данные (задачи и участники удаляются каскадно).
  Future<void> clearLargeDataset() async {
    await _db.transaction(() async {
      await (_db.delete(
        _db.projects,
      )..where((p) => p.name.like('$_seedProjectPrefix %'))).go();
      await (_db.delete(
        _db.users,
      )..where((u) => u.email.like('%$_seedEmailDomain'))).go();
    });
  }

  /// Выполняет набор запросов с индексами, затем удаляет индексы tasks,
  /// повторяет замер и восстанавливает индексы.
  Future<List<BenchmarkResult>> compareIndexes({int runs = 30}) async {
    final queries = await _benchmarkQueries();
    final withIndex = await _measure(queries, runs);

    final indexes = _db.taskIndexes;
    final withoutIndex = <String, double>{};
    try {
      for (final index in indexes) {
        await _db.customStatement('DROP INDEX IF EXISTS ${index.entityName}');
      }
      await _db.customStatement('ANALYZE');
      withoutIndex.addAll(await _measure(queries, runs));
    } finally {
      await _db.recreateIndexes(indexes);
      await _db.customStatement('ANALYZE');
    }

    return [
      for (final name in queries.keys)
        BenchmarkResult(
          query: name,
          withIndexMs: withIndex[name]!,
          withoutIndexMs: withoutIndex[name]!,
        ),
    ];
  }

  Future<Map<String, Future<void> Function(int run)>>
  _benchmarkQueries() async {
    final userIds =
        await (_db.selectOnly(_db.users)
              ..addColumns([_db.users.id])
              ..limit(500))
            .map((r) => r.read(_db.users.id)!)
            .get();
    final projectIds =
        await (_db.selectOnly(_db.projects)
              ..addColumns([_db.projects.id])
              ..limit(200))
            .map((r) => r.read(_db.projects.id)!)
            .get();
    if (userIds.isEmpty || projectIds.isEmpty) {
      throw const AppException('Сначала создайте нагрузочные данные');
    }
    final now = DateTime.now();

    Future<void> run(String sql, List<Variable> vars) =>
        _db.customSelect(sql, variables: vars).get();

    return {
      'Задачи исполнителя, сортировка по дедлайну': (i) => run(
        'SELECT * FROM tasks WHERE assignee_id = ? AND deleted_at IS NULL '
        'ORDER BY deadline LIMIT 30',
        [Variable.withInt(userIds[i % userIds.length])],
      ),
      'Задачи проекта с фильтром по статусу': (i) => run(
        "SELECT * FROM tasks WHERE project_id = ? AND status = 'todo' "
        'AND deleted_at IS NULL',
        [Variable.withInt(projectIds[i % projectIds.length])],
      ),
      'Фильтр по приоритету (страница)': (i) => run(
        'SELECT * FROM tasks WHERE priority = ? AND deleted_at IS NULL '
        'ORDER BY created_at DESC LIMIT 30 OFFSET ?',
        [
          Variable.withString(TaskPriority.values[i % 4].name),
          Variable.withInt((i % 10) * 30),
        ],
      ),
      'Просроченные задачи (COUNT)': (_) => run(
        "SELECT COUNT(*) FROM tasks WHERE status IN ('todo', 'inProgress') "
        'AND deadline < ? AND deleted_at IS NULL',
        [Variable.withDateTime(now)],
      ),
      'Лимит 3 задачи на дедлайн (COUNT)': (i) => run(
        'SELECT COUNT(*) FROM tasks WHERE assignee_id = ? '
        "AND status IN ('todo', 'inProgress') AND deadline >= ? AND deadline < ?",
        [
          Variable.withInt(userIds[i % userIds.length]),
          Variable.withDateTime(now),
          Variable.withDateTime(now.add(const Duration(days: 1))),
        ],
      ),
    };
  }

  Future<Map<String, double>> _measure(
    Map<String, Future<void> Function(int run)> queries,
    int runs,
  ) async {
    final result = <String, double>{};
    for (final entry in queries.entries) {
      await entry.value(0); // прогрев
      final watch = Stopwatch()..start();
      for (var i = 0; i < runs; i++) {
        await entry.value(i);
      }
      watch.stop();
      result[entry.key] = watch.elapsedMicroseconds / runs / 1000;
    }
    return result;
  }
}
