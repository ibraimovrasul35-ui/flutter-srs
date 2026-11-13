import 'package:drift/drift.dart';

import '../../core/app_exception.dart';
import '../../core/formatters.dart';
import '../../models/enums.dart';
import '../../models/task_filter.dart';
import '../../models/views.dart';
import '../database/app_database.dart';
import 'repository_utils.dart';

class TaskRepository {
  TaskRepository(this._db);

  final AppDatabase _db;

  /// Сколько незавершённых задач с одним дедлайном может быть у исполнителя.
  static const maxOpenTasksPerDeadline = 3;

  $TasksTable get _tasks => _db.tasks;
  late final $UsersTable _assignee = _db.alias(_db.users, 'assignee');

  // ---------------------------------------------------------------- чтение

  /// Страница задач по фильтру. Поток обновляется сам при изменении таблиц.
  Stream<List<TaskView>> watchTasks(
    TaskFilter filter, {
    int limit = 30,
    int offset = 0,
  }) => _listQuery(filter, limit, offset).watch().map(_mapTasks);

  Future<List<TaskView>> getTasks(
    TaskFilter filter, {
    int limit = 30,
    int offset = 0,
  }) => _listQuery(filter, limit, offset).get().then(_mapTasks);

  /// Общее количество задач по фильтру (для пагинации).
  Stream<int> watchCount(TaskFilter filter) =>
      _countQuery(filter).watchSingle();

  Future<int> countTasks(TaskFilter filter) => _countQuery(filter).getSingle();

  Stream<TaskView?> watchTask(int id) {
    final query = _joined()..where(_tasks.id.equals(id));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : _mapTask(row),
    );
  }

  Future<Task?> getTask(int id) =>
      (_db.select(_tasks)..where((t) => t.id.equals(id))).getSingleOrNull();

  Stream<List<HistoryView>> watchHistory(int taskId) {
    final h = _db.taskHistory;
    final query =
        _db.select(h).join([
            leftOuterJoin(_db.users, _db.users.id.equalsExp(h.changedBy)),
          ])
          ..where(h.taskId.equals(taskId))
          ..orderBy([OrderingTerm.desc(h.changedAt), OrderingTerm.desc(h.id)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => HistoryView(
              entry: row.readTable(h),
              user: row.readTableOrNull(_db.users),
            ),
          )
          .toList(),
    );
  }

  Future<List<HistoryEntry>> getHistory(int taskId) =>
      (_db.select(_db.taskHistory)
            ..where((h) => h.taskId.equals(taskId))
            ..orderBy([(h) => OrderingTerm(expression: h.id)]))
          .get();

  // -------------------------------------------------------------- изменение

  /// Создаёт задачу и первую запись истории в одной транзакции.
  /// Если запись истории не сохранится, задача тоже не сохранится.
  Future<int> createTask({
    required int? projectId,
    required String title,
    String description = '',
    int? assigneeId,
    TaskPriority priority = TaskPriority.medium,
    DateTime? deadline,
    required int actorId,
  }) async {
    if (projectId == null) {
      throw const AppException('Задачу нельзя создать без проекта');
    }
    final cleanTitle = requireText(title, 'Название');
    _validateDeadline(deadline);

    return _db.transaction(() async {
      await _requireProject(projectId);
      if (assigneeId != null) {
        await _requireMember(projectId, assigneeId);
        await _checkAssigneeLimit(assigneeId, deadline);
      }
      final now = DateTime.now();
      final id = await _db
          .into(_tasks)
          .insert(
            TasksCompanion.insert(
              title: cleanTitle,
              description: Value(description.trim()),
              projectId: projectId,
              assigneeId: Value(assigneeId),
              priority: Value(priority),
              deadline: Value(deadline),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _writeHistory(
        taskId: id,
        kind: HistoryKind.created,
        newStatus: TaskStatus.todo,
        actorId: actorId,
        at: now,
      );
      return id;
    });
  }

  /// Редактирует название, описание, приоритет и дедлайн.
  Future<void> updateTask(
    int id, {
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? deadline,
  }) async {
    final cleanTitle = requireText(title, 'Название');
    await _db.transaction(() async {
      final task = await _requireActiveTask(id);
      if (deadline != task.deadline) {
        _validateDeadline(deadline);
        if (task.assigneeId != null && task.status.isOpen) {
          await _checkAssigneeLimit(
            task.assigneeId!,
            deadline,
            exceptTaskId: id,
          );
        }
      }
      await (_db.update(_tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          title: Value(cleanTitle),
          description: Value(description.trim()),
          priority: Value(priority),
          deadline: Value(deadline),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<void> changePriority(int id, TaskPriority priority) async {
    await _requireActiveTask(id);
    await (_db.update(_tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        priority: Value(priority),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Меняет статус и автоматически пишет запись в историю (атомарно).
  Future<void> changeStatus(int id, TaskStatus status, {required int actorId}) {
    return _db.transaction(() async {
      final task = await _requireActiveTask(id);
      if (task.status == status) return;
      final now = DateTime.now();
      await _setStatus(id, status, now);
      await _writeHistory(
        taskId: id,
        kind: HistoryKind.status,
        oldStatus: task.status,
        newStatus: status,
        actorId: actorId,
        at: now,
      );
    });
  }

  /// Отменяет последнее (ещё не отменённое) изменение статуса.
  /// Возвращает статус, который был восстановлен.
  Future<TaskStatus> undoLastStatusChange(int id, {required int actorId}) {
    return _db.transaction(() async {
      final task = await _requireActiveTask(id);
      final last =
          await (_db.select(_db.taskHistory)
                ..where(
                  (h) =>
                      h.taskId.equals(id) &
                      h.kind.equalsValue(HistoryKind.status) &
                      h.undone.equals(false),
                )
                ..orderBy([
                  (h) => OrderingTerm.desc(h.changedAt),
                  (h) => OrderingTerm.desc(h.id),
                ])
                ..limit(1))
              .getSingleOrNull();
      if (last == null || last.oldStatus == null) {
        throw const AppException('Нет изменений статуса для отмены');
      }
      final restored = last.oldStatus!;
      final now = DateTime.now();
      await _setStatus(id, restored, now);
      await (_db.update(_db.taskHistory)..where((h) => h.id.equals(last.id)))
          .write(const TaskHistoryCompanion(undone: Value(true)));
      await _writeHistory(
        taskId: id,
        kind: HistoryKind.undo,
        oldStatus: task.status,
        newStatus: restored,
        actorId: actorId,
        at: now,
      );
      return restored;
    });
  }

  /// Переназначение: проверка участия в проекте, смена исполнителя и запись
  /// в историю выполняются атомарно в одной транзакции.
  Future<void> reassign(int id, int? assigneeId, {required int actorId}) {
    return _db.transaction(() async {
      final task = await _requireActiveTask(id);
      if (task.assigneeId == assigneeId) return;
      if (assigneeId != null) {
        await _requireMember(task.projectId, assigneeId);
        if (task.status.isOpen) {
          await _checkAssigneeLimit(
            assigneeId,
            task.deadline,
            exceptTaskId: id,
          );
        }
      }
      final now = DateTime.now();
      await (_db.update(_tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(assigneeId: Value(assigneeId), updatedAt: Value(now)),
      );
      final from = await _userName(task.assigneeId);
      final to = await _userName(assigneeId);
      await _writeHistory(
        taskId: id,
        kind: HistoryKind.assignee,
        details: '$from → $to',
        actorId: actorId,
        at: now,
      );
    });
  }

  /// Soft Delete: задача переносится в корзину.
  Future<void> moveToTrash(int id) async {
    await _requireActiveTask(id);
    final now = DateTime.now();
    await (_db.update(_tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(deletedAt: Value(now), updatedAt: Value(now)),
    );
  }

  Future<void> restore(int id) async {
    final task = await getTask(id);
    if (task == null || task.deletedAt == null) {
      throw const AppException('Задачи нет в корзине');
    }
    await (_db.update(_tasks)..where((t) => t.id.equals(id))).write(
      TasksCompanion(
        deletedAt: const Value(null),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// Полное удаление (только из корзины). Комментарии, вложения и история
  /// удаляются каскадно.
  Future<void> deletePermanently(int id) async {
    final task = await getTask(id);
    if (task == null) return;
    if (task.deletedAt == null) {
      throw const AppException('Сначала переместите задачу в корзину');
    }
    await (_db.delete(_tasks)..where((t) => t.id.equals(id))).go();
  }

  Future<int> emptyTrash() =>
      (_db.delete(_tasks)..where((t) => t.deletedAt.isNotNull())).go();

  // ---------------------------------------------------------------- помощь

  JoinedSelectStatement<HasResultSet, dynamic> _joined() {
    return _db.select(_tasks).join([
      innerJoin(_db.projects, _db.projects.id.equalsExp(_tasks.projectId)),
      leftOuterJoin(_assignee, _assignee.id.equalsExp(_tasks.assigneeId)),
    ]);
  }

  JoinedSelectStatement<HasResultSet, dynamic> _listQuery(
    TaskFilter filter,
    int limit,
    int offset,
  ) {
    final t = _tasks;
    return _joined()
      ..where(_where(filter))
      ..orderBy(switch (filter.sort) {
        TaskSort.createdDesc => [
          OrderingTerm.desc(t.createdAt),
          OrderingTerm.desc(t.id),
        ],
        TaskSort.createdAsc => [
          OrderingTerm.asc(t.createdAt),
          OrderingTerm.asc(t.id),
        ],
        TaskSort.deadlineAsc => [
          OrderingTerm(expression: t.deadline, nulls: NullsOrder.last),
          OrderingTerm.asc(t.id),
        ],
      })
      ..limit(limit, offset: offset);
  }

  Selectable<int> _countQuery(TaskFilter filter) {
    final count = _tasks.id.count();
    return (_db.selectOnly(_tasks)
          ..addColumns([count])
          ..where(_where(filter)))
        .map((row) => row.read(count)!);
  }

  Expression<bool> _where(TaskFilter f) {
    final t = _tasks;
    final conditions = <Expression<bool>>[
      f.deletedOnly ? t.deletedAt.isNotNull() : t.deletedAt.isNull(),
      if (f.projectId != null) t.projectId.equals(f.projectId!),
      if (f.assigneeId != null) t.assigneeId.equals(f.assigneeId!),
      if (f.status != null) t.status.equalsValue(f.status),
      if (f.priority != null) t.priority.equalsValue(f.priority),
    ];
    final query = f.query.trim();
    if (query.isNotEmpty) {
      // LIKE в SQLite не различает регистр только для латиницы,
      // поэтому для кириллицы ищем несколько вариантов написания.
      conditions.add(
        _caseVariants(query)
            .map((v) => t.title.like('%$v%') | t.description.like('%$v%'))
            .reduce((a, b) => a | b),
      );
    }
    return conditions.reduce((a, b) => a & b);
  }

  static Set<String> _caseVariants(String query) {
    final lower = query.toLowerCase();
    return {
      query,
      lower,
      query.toUpperCase(),
      lower[0].toUpperCase() + lower.substring(1),
    };
  }

  List<TaskView> _mapTasks(List<TypedResult> rows) =>
      rows.map(_mapTask).toList();

  TaskView _mapTask(TypedResult row) => TaskView(
    task: row.readTable(_tasks),
    projectName: row.readTable(_db.projects).name,
    assignee: row.readTableOrNull(_assignee),
  );

  Future<void> _setStatus(int id, TaskStatus status, DateTime at) =>
      (_db.update(_tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(status: Value(status), updatedAt: Value(at)),
      );

  Future<void> _writeHistory({
    required int taskId,
    required HistoryKind kind,
    TaskStatus? oldStatus,
    TaskStatus? newStatus,
    String? details,
    required int actorId,
    required DateTime at,
  }) {
    return _db
        .into(_db.taskHistory)
        .insert(
          TaskHistoryCompanion.insert(
            taskId: taskId,
            kind: kind,
            oldStatus: Value(oldStatus),
            newStatus: Value(newStatus),
            details: Value(details),
            changedBy: Value(actorId),
            changedAt: at,
          ),
        );
  }

  Future<void> _requireProject(int projectId) async {
    final project = await (_db.select(
      _db.projects,
    )..where((p) => p.id.equals(projectId))).getSingleOrNull();
    if (project == null) throw const AppException('Проект не найден');
  }

  Future<Task> _requireActiveTask(int id) async {
    final task = await getTask(id);
    if (task == null || task.deletedAt != null) {
      throw const AppException('Задача не найдена');
    }
    return task;
  }

  Future<void> _requireMember(int projectId, int userId) async {
    final member =
        await (_db.select(_db.projectMembers)..where(
              (m) => m.projectId.equals(projectId) & m.userId.equals(userId),
            ))
            .getSingleOrNull();
    if (member == null) {
      throw const AppException(
        'Исполнителем может быть только участник проекта',
      );
    }
  }

  /// Не больше трёх незавершённых задач у исполнителя на один дедлайн.
  /// Проверка выполняется запросом к базе.
  Future<void> _checkAssigneeLimit(
    int userId,
    DateTime? deadline, {
    int? exceptTaskId,
  }) async {
    if (deadline == null) return;
    final t = _tasks;
    final day = startOfDay(deadline);
    final count = t.id.count();
    final query = _db.selectOnly(t)
      ..addColumns([count])
      ..where(
        t.assigneeId.equals(userId) &
            t.deletedAt.isNull() &
            t.status.isInValues(TaskStatus.openStatuses) &
            t.deadline.isBiggerOrEqualValue(day) &
            t.deadline.isSmallerThanValue(day.add(const Duration(days: 1))),
      );
    if (exceptTaskId != null) query.where(t.id.equals(exceptTaskId).not());
    final open = await query.map((row) => row.read(count)!).getSingle();
    if (open >= maxOpenTasksPerDeadline) {
      throw AppException(
        'У исполнителя уже $open незавершённые задачи '
        'с дедлайном ${formatDate(day)}',
      );
    }
  }

  void _validateDeadline(DateTime? deadline) {
    if (deadline != null && deadline.isBefore(startOfDay(DateTime.now()))) {
      throw const AppException('Дедлайн не может быть в прошлом');
    }
  }

  Future<String> _userName(int? id) async {
    if (id == null) return 'не назначен';
    final user = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(id))).getSingleOrNull();
    return user?.name ?? 'удалён';
  }
}
