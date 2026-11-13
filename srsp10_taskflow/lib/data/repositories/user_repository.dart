import 'package:drift/drift.dart';

import '../../core/app_exception.dart';
import '../../models/enums.dart';
import '../database/app_database.dart';
import 'repository_utils.dart';

class UserRepository {
  UserRepository(this._db);

  final AppDatabase _db;

  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  Stream<List<User>> watchUsers() => _usersQuery().watch();

  Future<List<User>> getUsers() => _usersQuery().get();

  Stream<User?> watchUser(int id) => (_db.select(
    _db.users,
  )..where((u) => u.id.equals(id))).watchSingleOrNull();

  Future<User?> getUser(int id) =>
      (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingleOrNull();

  Future<int> createUser({
    required String name,
    required String email,
    DateTime? registeredAt,
  }) async {
    final cleanName = requireText(name, 'Имя', max: 100);
    final cleanEmail = _validateEmail(email);
    await _ensureEmailFree(cleanEmail);
    return guardUnique(
      () => _db
          .into(_db.users)
          .insert(
            UsersCompanion.insert(
              name: cleanName,
              email: cleanEmail,
              registeredAt: Value(registeredAt ?? DateTime.now()),
            ),
          ),
      'Пользователь с email $cleanEmail уже существует',
    );
  }

  Future<void> updateUser(
    int id, {
    required String name,
    required String email,
  }) async {
    final cleanName = requireText(name, 'Имя', max: 100);
    final cleanEmail = _validateEmail(email);
    await _ensureEmailFree(cleanEmail, exceptUserId: id);
    await guardUnique(
      () => (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
        UsersCompanion(name: Value(cleanName), email: Value(cleanEmail)),
      ),
      'Пользователь с email $cleanEmail уже существует',
    );
  }

  /// Удаляет пользователя. Запрещено, если за ним есть незавершённые задачи.
  /// Завершённые задачи остаются без исполнителя (ON DELETE SET NULL),
  /// участие в проектах и комментарии удаляются каскадно.
  Future<void> deleteUser(int id) {
    return _db.transaction(() async {
      final open = await openTasksCount(id);
      if (open > 0) {
        throw AppException(
          'Нельзя удалить пользователя: за ним закреплено '
          'незавершённых задач — $open',
        );
      }
      await (_db.delete(_db.users)..where((u) => u.id.equals(id))).go();
    });
  }

  Future<int> openTasksCount(int userId) {
    final t = _db.tasks;
    final count = t.id.count();
    final query = _db.selectOnly(t)
      ..addColumns([count])
      ..where(
        t.assigneeId.equals(userId) &
            t.deletedAt.isNull() &
            t.status.isInValues(TaskStatus.openStatuses),
      );
    return query.map((row) => row.read(count)!).getSingle();
  }

  SimpleSelectStatement<$UsersTable, User> _usersQuery() =>
      _db.select(_db.users)..orderBy([(u) => OrderingTerm(expression: u.name)]);

  String _validateEmail(String email) {
    final value = email.trim().toLowerCase();
    if (!_emailPattern.hasMatch(value)) {
      throw const AppException('Некорректный email');
    }
    return value;
  }

  Future<void> _ensureEmailFree(String email, {int? exceptUserId}) async {
    final query = _db.select(_db.users)..where((u) => u.email.equals(email));
    if (exceptUserId != null) {
      query.where((u) => u.id.equals(exceptUserId).not());
    }
    if (await query.getSingleOrNull() != null) {
      throw AppException('Пользователь с email $email уже существует');
    }
  }
}
