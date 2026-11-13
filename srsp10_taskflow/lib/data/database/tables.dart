import 'package:drift/drift.dart';

import '../../models/enums.dart';

/// users — пользователи. Email уникален.
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get email => text().withLength(min: 3, max: 200).unique()();
  DateTimeColumn get registeredAt =>
      dateTime().withDefault(currentDateAndTime)();
}

/// projects — проекты.
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get description => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get status =>
      textEnum<ProjectStatus>().withDefault(const Constant('active'))();
}

/// project_members — участники проектов (связь Many-to-Many users <-> projects).
/// Составной первичный ключ не даёт добавить пользователя в проект дважды.
@TableIndex(name: 'idx_members_user', columns: {#userId})
class ProjectMembers extends Table {
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get userId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => textEnum<MemberRole>()();
  DateTimeColumn get joinedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {projectId, userId};
}

/// tasks — задачи (One-to-Many: проект -> задачи, пользователь -> задачи).
@TableIndex(name: 'idx_tasks_project', columns: {#projectId, #status})
@TableIndex(name: 'idx_tasks_assignee', columns: {#assigneeId, #deadline})
@TableIndex(name: 'idx_tasks_status', columns: {#status, #deadline})
@TableIndex(name: 'idx_tasks_priority', columns: {#priority, #createdAt})
@TableIndex(name: 'idx_tasks_deadline', columns: {#deadline})
@TableIndex(name: 'idx_tasks_created', columns: {#createdAt})
class Tasks extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().withDefault(const Constant(''))();
  IntColumn get projectId =>
      integer().references(Projects, #id, onDelete: KeyAction.cascade)();
  IntColumn get assigneeId => integer().nullable().references(
    Users,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Добавлено во 2-й версии схемы (см. миграцию в AppDatabase).
  TextColumn get priority =>
      textEnum<TaskPriority>().withDefault(const Constant('medium'))();
  TextColumn get status =>
      textEnum<TaskStatus>().withDefault(const Constant('todo'))();
  DateTimeColumn get deadline => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  /// Soft Delete: задача в корзине, если поле заполнено.
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

/// comments — комментарии к задачам.
@TableIndex(name: 'idx_comments_task', columns: {#taskId})
class Comments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  IntColumn get authorId =>
      integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text().withLength(min: 1, max: 2000)();
  DateTimeColumn get createdAt => dateTime()();
}

/// attachments — вложения. Хранится путь к файлу, а не его содержимое.
@TableIndex(name: 'idx_attachments_task', columns: {#taskId})
class Attachments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get fileName => text().withLength(min: 1, max: 255)();
  TextColumn get filePath => text().withLength(min: 1, max: 1024)();
  DateTimeColumn get addedAt => dateTime()();
}

/// task_history — история изменений задач.
@DataClassName('HistoryEntry')
@TableIndex(name: 'idx_history_task', columns: {#taskId, #changedAt})
class TaskHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get taskId =>
      integer().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get kind => textEnum<HistoryKind>()();
  TextColumn get oldStatus => textEnum<TaskStatus>().nullable()();
  TextColumn get newStatus => textEnum<TaskStatus>().nullable()();
  TextColumn get details => text().nullable()();
  IntColumn get changedBy => integer().nullable().references(
    Users,
    #id,
    onDelete: KeyAction.setNull,
  )();
  DateTimeColumn get changedAt => dateTime()();

  /// Изменение статуса отменено через Undo.
  BoolColumn get undone => boolean().withDefault(const Constant(false))();
}
