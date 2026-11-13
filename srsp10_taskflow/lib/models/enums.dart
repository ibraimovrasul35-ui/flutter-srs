/// Статус проекта.
enum ProjectStatus {
  active('Активный'),
  completed('Завершённый'),
  archived('Архивный');

  const ProjectStatus(this.label);
  final String label;
}

/// Роль участника проекта.
enum MemberRole {
  owner('Owner'),
  admin('Admin'),
  member('Member');

  const MemberRole(this.label);
  final String label;
}

/// Статус задачи.
enum TaskStatus {
  todo('Ожидает'),
  inProgress('В работе'),
  done('Завершена'),
  cancelled('Отменена');

  const TaskStatus(this.label);
  final String label;

  /// Незавершённая задача: ещё ожидает выполнения или выполняется.
  bool get isOpen => this == todo || this == inProgress;

  static const openStatuses = [todo, inProgress];
}

/// Приоритет задачи.
enum TaskPriority {
  low('Низкий'),
  medium('Средний'),
  high('Высокий'),
  critical('Критический');

  const TaskPriority(this.label);
  final String label;
}

/// Тип записи в истории изменений задачи.
enum HistoryKind {
  created('Создана'),
  status('Смена статуса'),
  assignee('Смена исполнителя'),
  undo('Отмена изменения');

  const HistoryKind(this.label);
  final String label;
}

/// Сортировка списка задач.
enum TaskSort {
  createdDesc('Сначала новые'),
  createdAsc('Сначала старые'),
  deadlineAsc('По дедлайну');

  const TaskSort(this.label);
  final String label;
}
