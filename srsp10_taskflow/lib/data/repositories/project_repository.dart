import 'package:drift/drift.dart';

import '../../core/app_exception.dart';
import '../../models/enums.dart';
import '../../models/views.dart';
import '../database/app_database.dart';
import 'repository_utils.dart';

class ProjectRepository {
  ProjectRepository(this._db);

  final AppDatabase _db;

  /// Проекты с количеством задач, обновляется при изменении projects и tasks.
  Stream<List<ProjectSummary>> watchProjects() {
    return _db
        .customSelect(
          'SELECT p.*, COUNT(t.id) AS total, '
          "COALESCE(SUM(t.status = 'done'), 0) AS done, "
          "COALESCE(SUM(t.status = 'cancelled'), 0) AS cancelled "
          'FROM projects p '
          'LEFT JOIN tasks t ON t.project_id = p.id AND t.deleted_at IS NULL '
          'GROUP BY p.id ORDER BY p.created_at DESC, p.id DESC',
          readsFrom: {_db.projects, _db.tasks},
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => ProjectSummary(
                  project: _db.projects.map(row.data),
                  totalTasks: row.read<int>('total'),
                  doneTasks: row.read<int>('done'),
                  cancelledTasks: row.read<int>('cancelled'),
                ),
              )
              .toList(),
        );
  }

  Future<List<Project>> getProjects() => (_db.select(
    _db.projects,
  )..orderBy([(p) => OrderingTerm(expression: p.name)])).get();

  Stream<Project?> watchProject(int id) => (_db.select(
    _db.projects,
  )..where((p) => p.id.equals(id))).watchSingleOrNull();

  Future<Project?> getProject(int id) => (_db.select(
    _db.projects,
  )..where((p) => p.id.equals(id))).getSingleOrNull();

  /// Создаёт проект. Создатель сразу добавляется в него с ролью Owner.
  Future<int> createProject({
    required String name,
    String description = '',
    ProjectStatus status = ProjectStatus.active,
    DateTime? endDate,
    int? ownerId,
  }) async {
    final cleanName = requireText(name, 'Название', max: 120);
    final now = DateTime.now();
    _validateEndDate(endDate, now);
    return _db.transaction(() async {
      final id = await _db
          .into(_db.projects)
          .insert(
            ProjectsCompanion.insert(
              name: cleanName,
              description: Value(description.trim()),
              status: Value(status),
              endDate: Value(endDate),
              createdAt: Value(now),
            ),
          );
      if (ownerId != null) {
        await addMember(id, ownerId, MemberRole.owner);
      }
      return id;
    });
  }

  Future<void> updateProject(
    int id, {
    required String name,
    required String description,
    required ProjectStatus status,
    DateTime? endDate,
  }) async {
    final cleanName = requireText(name, 'Название', max: 120);
    final project = await _requireProject(id);
    _validateEndDate(endDate, project.createdAt);
    await (_db.update(_db.projects)..where((p) => p.id.equals(id))).write(
      ProjectsCompanion(
        name: Value(cleanName),
        description: Value(description.trim()),
        status: Value(status),
        endDate: Value(endDate),
      ),
    );
  }

  /// Удаление проекта каскадно удаляет участников, задачи и всё, что к ним
  /// относится (комментарии, вложения, историю).
  Future<void> deleteProject(int id) =>
      (_db.delete(_db.projects)..where((p) => p.id.equals(id))).go();

  Stream<List<MemberView>> watchMembers(int projectId) =>
      _membersQuery(projectId).watch().map(_mapMembers);

  Future<List<MemberView>> getMembers(int projectId) =>
      _membersQuery(projectId).get().then(_mapMembers);

  Future<bool> isMember(int projectId, int userId) async {
    final row =
        await (_db.select(_db.projectMembers)..where(
              (m) => m.projectId.equals(projectId) & m.userId.equals(userId),
            ))
            .getSingleOrNull();
    return row != null;
  }

  Future<void> addMember(int projectId, int userId, MemberRole role) async {
    await _requireProject(projectId);
    final user = await (_db.select(
      _db.users,
    )..where((u) => u.id.equals(userId))).getSingleOrNull();
    if (user == null) throw const AppException('Пользователь не найден');
    if (await isMember(projectId, userId)) {
      throw AppException('${user.name} уже участвует в этом проекте');
    }
    await guardUnique(
      () => _db
          .into(_db.projectMembers)
          .insert(
            ProjectMembersCompanion.insert(
              projectId: projectId,
              userId: userId,
              role: role,
            ),
          ),
      '${user.name} уже участвует в этом проекте',
    );
  }

  Future<void> changeRole(int projectId, int userId, MemberRole role) =>
      (_db.update(_db.projectMembers)..where(
            (m) => m.projectId.equals(projectId) & m.userId.equals(userId),
          ))
          .write(ProjectMembersCompanion(role: Value(role)));

  /// Удаляет участника. Нельзя, пока на нём есть незавершённые задачи проекта.
  Future<void> removeMember(int projectId, int userId) {
    return _db.transaction(() async {
      final t = _db.tasks;
      final count = t.id.count();
      final open =
          await (_db.selectOnly(t)
                ..addColumns([count])
                ..where(
                  t.projectId.equals(projectId) &
                      t.assigneeId.equals(userId) &
                      t.deletedAt.isNull() &
                      t.status.isInValues(TaskStatus.openStatuses),
                ))
              .map((row) => row.read(count)!)
              .getSingle();
      if (open > 0) {
        throw AppException(
          'Сначала переназначьте незавершённые задачи участника ($open)',
        );
      }
      await (_db.delete(_db.projectMembers)..where(
            (m) => m.projectId.equals(projectId) & m.userId.equals(userId),
          ))
          .go();
    });
  }

  JoinedSelectStatement<HasResultSet, dynamic> _membersQuery(int projectId) {
    return _db.select(_db.projectMembers).join([
        innerJoin(_db.users, _db.users.id.equalsExp(_db.projectMembers.userId)),
      ])
      ..where(_db.projectMembers.projectId.equals(projectId))
      ..orderBy([OrderingTerm(expression: _db.users.name)]);
  }

  /// Owner, затем Admin, затем Member; внутри роли — по имени.
  List<MemberView> _mapMembers(List<TypedResult> rows) =>
      rows
          .map(
            (row) => MemberView(
              user: row.readTable(_db.users),
              role: row.readTable(_db.projectMembers).role,
            ),
          )
          .toList()
        ..sort((a, b) {
          final byRole = a.role.index.compareTo(b.role.index);
          return byRole != 0 ? byRole : a.user.name.compareTo(b.user.name);
        });

  Future<Project> _requireProject(int id) async {
    final project = await getProject(id);
    if (project == null) throw const AppException('Проект не найден');
    return project;
  }

  void _validateEndDate(DateTime? endDate, DateTime createdAt) {
    if (endDate != null &&
        endDate.isBefore(
          DateTime(createdAt.year, createdAt.month, createdAt.day),
        )) {
      throw const AppException(
        'Дата завершения не может быть раньше даты создания',
      );
    }
  }
}
