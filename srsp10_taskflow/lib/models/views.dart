import 'package:equatable/equatable.dart';

import '../data/database/app_database.dart';
import 'enums.dart';

/// Задача вместе с названием проекта и исполнителем (результат JOIN).
class TaskView extends Equatable {
  const TaskView({
    required this.task,
    required this.projectName,
    this.assignee,
  });

  final Task task;
  final String projectName;
  final User? assignee;

  bool get isOverdue =>
      task.status.isOpen &&
      task.deadline != null &&
      task.deadline!.isBefore(DateTime.now());

  @override
  List<Object?> get props => [task, projectName, assignee];
}

/// Проект и прогресс по его задачам.
class ProjectSummary extends Equatable {
  const ProjectSummary({
    required this.project,
    required this.totalTasks,
    required this.doneTasks,
    required this.cancelledTasks,
  });

  final Project project;
  final int totalTasks;
  final int doneTasks;
  final int cancelledTasks;

  /// Процент выполнения: завершённые от всех, кроме отменённых.
  double get progress {
    final relevant = totalTasks - cancelledTasks;
    return relevant == 0 ? 0 : doneTasks / relevant;
  }

  @override
  List<Object?> get props => [project, totalTasks, doneTasks, cancelledTasks];
}

/// Участник проекта.
class MemberView extends Equatable {
  const MemberView({required this.user, required this.role});

  final User user;
  final MemberRole role;

  @override
  List<Object?> get props => [user, role];
}

/// Комментарий с автором.
class CommentView extends Equatable {
  const CommentView({required this.comment, required this.author});

  final Comment comment;
  final User author;

  @override
  List<Object?> get props => [comment, author];
}

/// Запись истории с пользователем, который выполнил изменение.
class HistoryView extends Equatable {
  const HistoryView({required this.entry, this.user});

  final HistoryEntry entry;
  final User? user;

  @override
  List<Object?> get props => [entry, user];
}
