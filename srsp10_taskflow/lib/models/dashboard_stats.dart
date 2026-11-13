import 'package:equatable/equatable.dart';

import 'enums.dart';

class AssigneeLoad extends Equatable {
  const AssigneeLoad(this.name, this.count);

  final String name;
  final int count;

  @override
  List<Object?> get props => [name, count];
}

class ProjectProgress extends Equatable {
  const ProjectProgress({
    required this.name,
    required this.total,
    required this.done,
    required this.percent,
  });

  final String name;
  final int total;
  final int done;

  /// Процент выполнения 0..100.
  final double percent;

  @override
  List<Object?> get props => [name, total, done, percent];
}

/// Данные экрана статистики. Всё считается SQL-запросами к SQLite.
class DashboardStats extends Equatable {
  const DashboardStats({
    required this.projects,
    required this.totalTasks,
    required this.doneTasks,
    required this.openTasks,
    required this.overdueTasks,
    required this.byPriority,
    required this.byAssignee,
    required this.projectProgress,
  });

  final int projects;
  final int totalTasks;
  final int doneTasks;

  /// Незавершённые: todo + inProgress.
  final int openTasks;
  final int overdueTasks;
  final Map<TaskPriority, int> byPriority;
  final List<AssigneeLoad> byAssignee;
  final List<ProjectProgress> projectProgress;

  @override
  List<Object?> get props => [
    projects,
    totalTasks,
    doneTasks,
    openTasks,
    overdueTasks,
    byPriority,
    byAssignee,
    projectProgress,
  ];
}
