import 'package:drift/drift.dart';

import '../../core/app_exception.dart';
import '../../models/views.dart';
import '../database/app_database.dart';
import 'repository_utils.dart';

class CommentRepository {
  CommentRepository(this._db);

  final AppDatabase _db;

  Stream<List<CommentView>> watchComments(int taskId) {
    final c = _db.comments;
    final query =
        _db.select(c).join([
            innerJoin(_db.users, _db.users.id.equalsExp(c.authorId)),
          ])
          ..where(c.taskId.equals(taskId))
          ..orderBy([OrderingTerm.asc(c.createdAt), OrderingTerm.asc(c.id)]);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => CommentView(
              comment: row.readTable(c),
              author: row.readTable(_db.users),
            ),
          )
          .toList(),
    );
  }

  /// Добавляет комментарий. К несуществующей или удалённой задаче нельзя.
  Future<int> addComment({
    required int taskId,
    required int authorId,
    required String text,
  }) async {
    final body = requireText(text, 'Комментарий', max: 2000);
    final task = await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(taskId))).getSingleOrNull();
    if (task == null || task.deletedAt != null) {
      throw const AppException('Нельзя комментировать несуществующую задачу');
    }
    return _db
        .into(_db.comments)
        .insert(
          CommentsCompanion.insert(
            taskId: taskId,
            authorId: authorId,
            body: body,
            createdAt: DateTime.now(),
          ),
        );
  }

  /// Удалить комментарий может только его автор.
  Future<void> deleteComment(int commentId, {required int userId}) async {
    final comment = await (_db.select(
      _db.comments,
    )..where((c) => c.id.equals(commentId))).getSingleOrNull();
    if (comment == null) return;
    if (comment.authorId != userId) {
      throw const AppException('Удалить комментарий может только его автор');
    }
    await (_db.delete(_db.comments)..where((c) => c.id.equals(commentId))).go();
  }
}
