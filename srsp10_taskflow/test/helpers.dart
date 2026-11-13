import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:srsp10_taskflow/data/database/app_database.dart';
import 'package:srsp10_taskflow/data/repositories/attachment_repository.dart';
import 'package:srsp10_taskflow/data/repositories/comment_repository.dart';
import 'package:srsp10_taskflow/data/repositories/project_repository.dart';
import 'package:srsp10_taskflow/data/repositories/stats_repository.dart';
import 'package:srsp10_taskflow/data/repositories/task_repository.dart';
import 'package:srsp10_taskflow/data/repositories/user_repository.dart';
import 'package:srsp10_taskflow/models/enums.dart';

/// Тестовая база в памяти и все репозитории поверх неё.
class TestEnv {
  TestEnv() : db = AppDatabase(NativeDatabase.memory()) {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  }

  final AppDatabase db;
  late final users = UserRepository(db);
  late final projects = ProjectRepository(db);
  late final tasks = TaskRepository(db);
  late final comments = CommentRepository(db);
  late final attachments = AttachmentRepository(db);
  late final stats = StatsRepository(db);

  Future<void> dispose() => db.close();

  Future<int> user(String name) =>
      users.createUser(name: name, email: '${name.toLowerCase()}@test.kz');

  /// Проект, где [ownerId] — Owner, а [memberIds] — участники.
  Future<int> project(
    String name,
    int ownerId, [
    List<int> memberIds = const [],
  ]) async {
    final id = await projects.createProject(name: name, ownerId: ownerId);
    for (final m in memberIds) {
      await projects.addMember(id, m, MemberRole.member);
    }
    return id;
  }

  DateTime inDays(int days) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(Duration(days: days));
  }
}
