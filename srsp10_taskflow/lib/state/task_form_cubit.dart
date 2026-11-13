import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/database/app_database.dart';
import '../data/repositories/project_repository.dart';
import '../data/repositories/task_repository.dart';
import '../models/enums.dart';
import '../models/views.dart';
import 'load_state.dart';

class TaskFormState extends Equatable {
  const TaskFormState({
    this.projects = const [],
    this.members = const [],
    this.projectId,
    this.saving = false,
  });

  final List<Project> projects;

  /// Участники выбранного проекта — только они могут быть исполнителями.
  final List<MemberView> members;
  final int? projectId;
  final bool saving;

  TaskFormState copyWith({
    List<Project>? projects,
    List<MemberView>? members,
    int? projectId,
    bool? saving,
  }) => TaskFormState(
    projects: projects ?? this.projects,
    members: members ?? this.members,
    projectId: projectId ?? this.projectId,
    saving: saving ?? this.saving,
  );

  @override
  List<Object?> get props => [projects, members, projectId, saving];
}

/// Форма создания и редактирования задачи.
class TaskFormCubit extends Cubit<TaskFormState> {
  TaskFormCubit(this._tasks, this._projects, {int? projectId})
    : super(TaskFormState(projectId: projectId)) {
    _load();
  }

  final TaskRepository _tasks;
  final ProjectRepository _projects;

  Future<void> _load() async {
    final projects = await _projects.getProjects();
    if (isClosed) return;
    emit(state.copyWith(projects: projects));
    if (state.projectId != null) await selectProject(state.projectId!);
  }

  Future<void> selectProject(int projectId) async {
    final members = await _projects.getMembers(projectId);
    if (isClosed) return;
    emit(
      TaskFormState(
        projects: state.projects,
        members: members,
        projectId: projectId,
      ),
    );
  }

  Future<String?> create({
    required String title,
    required String description,
    int? assigneeId,
    required TaskPriority priority,
    DateTime? deadline,
    required int actorId,
  }) => _saving(
    () => _tasks.createTask(
      projectId: state.projectId,
      title: title,
      description: description,
      assigneeId: assigneeId,
      priority: priority,
      deadline: deadline,
      actorId: actorId,
    ),
  );

  Future<String?> update(
    int taskId, {
    required String title,
    required String description,
    required TaskPriority priority,
    DateTime? deadline,
  }) => _saving(
    () => _tasks.updateTask(
      taskId,
      title: title,
      description: description,
      priority: priority,
      deadline: deadline,
    ),
  );

  Future<String?> _saving(Future<void> Function() action) async {
    emit(state.copyWith(saving: true));
    final error = await runAction(action);
    if (!isClosed) emit(state.copyWith(saving: false));
    return error;
  }
}
