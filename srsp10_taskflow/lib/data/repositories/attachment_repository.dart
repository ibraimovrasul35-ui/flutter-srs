import 'package:drift/drift.dart';

import '../../core/app_exception.dart';
import '../database/app_database.dart';
import 'repository_utils.dart';

class AttachmentRepository {
  AttachmentRepository(this._db);

  final AppDatabase _db;

  Stream<List<Attachment>> watchAttachments(int taskId) =>
      (_db.select(_db.attachments)
            ..where((a) => a.taskId.equals(taskId))
            ..orderBy([(a) => OrderingTerm.desc(a.addedAt)]))
          .watch();

  /// В базе хранится только путь к файлу, сам файл остаётся на устройстве.
  Future<int> addAttachment({
    required int taskId,
    required String fileName,
    required String filePath,
  }) async {
    final name = requireText(fileName, 'Имя файла', max: 255);
    final path = requireText(filePath, 'Путь к файлу', max: 1024);
    final task = await (_db.select(
      _db.tasks,
    )..where((t) => t.id.equals(taskId))).getSingleOrNull();
    if (task == null || task.deletedAt != null) {
      throw const AppException('Задача не найдена');
    }
    return _db
        .into(_db.attachments)
        .insert(
          AttachmentsCompanion.insert(
            taskId: taskId,
            fileName: name,
            filePath: path,
            addedAt: DateTime.now(),
          ),
        );
  }

  Future<void> deleteAttachment(int id) =>
      (_db.delete(_db.attachments)..where((a) => a.id.equals(id))).go();
}
