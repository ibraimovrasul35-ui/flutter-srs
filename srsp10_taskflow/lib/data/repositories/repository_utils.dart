import '../../core/app_exception.dart';

/// Выполняет запись и переводит нарушение UNIQUE в понятную ошибку.
/// Нужна на случай, если проверка «до сохранения» не успела поймать дубликат.
Future<T> guardUnique<T>(Future<T> Function() action, String message) async {
  try {
    return await action();
  } catch (e) {
    if (e.toString().contains('UNIQUE constraint failed')) {
      throw AppException(message);
    }
    rethrow;
  }
}

String requireText(String value, String field, {int max = 200}) {
  final text = value.trim();
  if (text.isEmpty) throw AppException('Поле «$field» не может быть пустым');
  if (text.length > max) {
    throw AppException('Поле «$field» длиннее $max символов');
  }
  return text;
}
