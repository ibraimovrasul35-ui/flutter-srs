import 'package:intl/intl.dart';

final _date = DateFormat('dd.MM.yyyy');
final _dateTime = DateFormat('dd.MM.yyyy HH:mm');

String formatDate(DateTime? value) => value == null ? '—' : _date.format(value);

String formatDateTime(DateTime value) => _dateTime.format(value);

/// Начало дня (00:00) для сравнения дат без учёта времени.
DateTime startOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day);
