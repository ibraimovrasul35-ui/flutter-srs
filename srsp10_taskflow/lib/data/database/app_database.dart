import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../models/enums.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Users,
    Projects,
    ProjectMembers,
    Tasks,
    Comments,
    Attachments,
    TaskHistory,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// База приложения в файле taskflow.sqlite на устройстве.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'taskflow'));

  /// v1 — первая версия: в таблице tasks не было поля priority.
  /// v2 — добавлено поле priority, у старых задач оно равно medium.
  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(tasks, tasks.priority);
        await customStatement(
          "UPDATE tasks SET priority = 'medium' "
          "WHERE priority IS NULL OR priority = ''",
        );
        await m.createIndex(idxTasksPriority);
      }
    },
    beforeOpen: (details) async {
      // В SQLite внешние ключи по умолчанию выключены.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Индексы таблицы tasks (используются при сравнении скорости запросов).
  List<Index> get taskIndexes => allSchemaEntities
      .whereType<Index>()
      .where((i) => i.entityName.startsWith('idx_tasks_'))
      .toList();

  /// Создаёт заново индексы, удалённые для замера скорости.
  Future<void> recreateIndexes(List<Index> indexes) async {
    final migrator = createMigrator();
    for (final index in indexes) {
      await migrator.createIndex(index);
    }
  }
}
