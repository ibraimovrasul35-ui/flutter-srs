import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/repositories/task_repository.dart';
import '../models/enums.dart';
import '../models/task_filter.dart';
import '../models/views.dart';
import 'load_state.dart';

class TaskListState extends Equatable {
  const TaskListState({
    required this.filter,
    this.tasks = const [],
    this.total = 0,
    this.limit = pageSize,
    this.loading = true,
  });

  /// Размер страницы при пагинации.
  static const pageSize = 30;

  final TaskFilter filter;
  final List<TaskView> tasks;
  final int total;
  final int limit;
  final bool loading;

  bool get hasMore => tasks.length < total;

  TaskListState copyWith({
    List<TaskView>? tasks,
    int? total,
    int? limit,
    bool? loading,
  }) => TaskListState(
    filter: filter,
    tasks: tasks ?? this.tasks,
    total: total ?? this.total,
    limit: limit ?? this.limit,
    loading: loading ?? this.loading,
  );

  @override
  List<Object?> get props => [filter, tasks, total, limit, loading];
}

/// Список задач: фильтры, поиск, сортировка и постраничная подгрузка.
class TaskListCubit extends Cubit<TaskListState> {
  TaskListCubit(this._repository, TaskFilter filter)
    : super(TaskListState(filter: filter)) {
    _subscribe();
  }

  final TaskRepository _repository;
  StreamSubscription<List<TaskView>>? _tasksSub;
  StreamSubscription<int>? _countSub;
  Timer? _debounce;

  void setStatus(TaskStatus? status) =>
      _applyFilter(state.filter.copyWith(status: () => status));

  void setPriority(TaskPriority? priority) =>
      _applyFilter(state.filter.copyWith(priority: () => priority));

  void setAssignee(int? assigneeId) =>
      _applyFilter(state.filter.copyWith(assigneeId: () => assigneeId));

  void setSort(TaskSort sort) =>
      _applyFilter(state.filter.copyWith(sort: sort));

  void search(String query) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _applyFilter(state.filter.copyWith(query: query)),
    );
  }

  /// Следующая страница: увеличиваем лимит запроса на pageSize.
  void loadMore() {
    if (state.loading || !state.hasMore) return;
    emit(
      state.copyWith(
        limit: state.limit + TaskListState.pageSize,
        loading: true,
      ),
    );
    _subscribe();
  }

  Future<String?> restore(int taskId) =>
      runAction(() => _repository.restore(taskId));

  Future<String?> deletePermanently(int taskId) =>
      runAction(() => _repository.deletePermanently(taskId));

  Future<String?> emptyTrash() => runAction(_repository.emptyTrash);

  void _applyFilter(TaskFilter filter) {
    if (filter == state.filter) return;
    emit(TaskListState(filter: filter, tasks: state.tasks, total: state.total));
    _subscribe();
  }

  void _subscribe() {
    _tasksSub?.cancel();
    _countSub?.cancel();
    final filter = state.filter;
    _tasksSub = _repository.watchTasks(filter, limit: state.limit).listen((
      tasks,
    ) {
      if (!isClosed && filter == state.filter) {
        emit(state.copyWith(tasks: tasks, loading: false));
      }
    });
    _countSub = _repository.watchCount(filter).listen((total) {
      if (!isClosed && filter == state.filter) {
        emit(state.copyWith(total: total));
      }
    });
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await _tasksSub?.cancel();
    await _countSub?.cancel();
    return super.close();
  }
}
