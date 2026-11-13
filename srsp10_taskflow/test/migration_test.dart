import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srsp10_taskflow/data/database/app_database.dart';
import 'package:srsp10_taskflow/models/enums.dart';

/// Проверка миграции на тестовой базе-файле.
///
/// 1. Создаём базу и превращаем её в схему версии 1: в tasks нет priority.
/// 2. Кладём туда задачи «старой» версии.
/// 3. Открываем базу текущей версией приложения — Drift запускает миграцию.
void main() {
  late Directory dir;
  late File file;

  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    dir = Directory.systemTemp.createTempSync('taskflow_migration');
    file = File('${dir.path}/taskflow.sqlite');
  });

  tearDown(() => dir.deleteSync(recursive: true));

  Future<List<String>> taskColumns(AppDatabase db) async =>
      (await db.customSelect('PRAGMA table_info(tasks)').get())
          .map((r) => r.read<String>('name'))
          .toList();

  test('v1 → v2: добавляет priority = medium без потери данных', () async {
    // --- база версии 1
    final v1 = AppDatabase(NativeDatabase(file));
    await v1.customStatement(
      "INSERT INTO users (name, email, registered_at) VALUES ('Расул', 'r@test.kz', 0)",
    );
    await v1.customStatement(
      "INSERT INTO projects (name, description, created_at, status) "
      "VALUES ('Старый проект', '', 0, 'active')",
    );
    await v1.customStatement('DROP INDEX idx_tasks_priority');
    await v1.customStatement('ALTER TABLE tasks DROP COLUMN priority');
    for (final title in ['Первая', 'Вторая', 'Третья']) {
      await v1.customStatement(
        'INSERT INTO tasks (title, description, project_id, assignee_id, '
        "status, created_at, updated_at) VALUES ('$title', '', 1, 1, 'todo', 0, 0)",
      );
    }
    await v1.customStatement('PRAGMA user_version = 1');
    expect(await taskColumns(v1), isNot(contains('priority')));
    await v1.close();

    // --- открываем текущей версией: выполняется миграция
    final v2 = AppDatabase(NativeDatabase(file));
    expect(await taskColumns(v2), contains('priority'));

    final tasks = await v2.select(v2.tasks).get();
    expect(tasks.map((t) => t.title), ['Первая', 'Вторая', 'Третья']);
    expect(tasks.every((t) => t.priority == TaskPriority.medium), isTrue);
    expect(tasks.every((t) => t.assigneeId == 1), isTrue);

    final version = await v2.customSelect('PRAGMA user_version').getSingle();
    expect(version.read<int>('user_version'), 2);

    // Итоговая схема совпадает со схемой, которую создаёт новая установка.
    await v2.validateDatabaseSchema();
    await v2.close();
  });
}
