import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Параметры фильтрации, поиска и сортировки списка задач.
class TaskFilter extends Equatable {
  const TaskFilter({
    this.projectId,
    this.assigneeId,
    this.status,
    this.priority,
    this.query = '',
    this.sort = TaskSort.createdDesc,
    this.deletedOnly = false,
  });

  final int? projectId;
  final int? assigneeId;
  final TaskStatus? status;
  final TaskPriority? priority;

  /// Поиск по названию и описанию.
  final String query;
  final TaskSort sort;

  /// true — корзина (только удалённые задачи), false — обычные списки.
  final bool deletedOnly;

  TaskFilter copyWith({
    int? Function()? assigneeId,
    TaskStatus? Function()? status,
    TaskPriority? Function()? priority,
    String? query,
    TaskSort? sort,
  }) {
    return TaskFilter(
      projectId: projectId,
      assigneeId: assigneeId != null ? assigneeId() : this.assigneeId,
      status: status != null ? status() : this.status,
      priority: priority != null ? priority() : this.priority,
      query: query ?? this.query,
      sort: sort ?? this.sort,
      deletedOnly: deletedOnly,
    );
  }

  @override
  List<Object?> get props => [
    projectId,
    assigneeId,
    status,
    priority,
    query,
    sort,
    deletedOnly,
  ];
}
