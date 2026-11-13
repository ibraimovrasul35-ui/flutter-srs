import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/database/app_database.dart';
import '../data/repositories/attachment_repository.dart';
import '../data/repositories/comment_repository.dart';
import '../data/repositories/project_repository.dart';
import '../data/repositories/task_repository.dart';
import '../models/enums.dart';
import '../models/views.dart';
import 'load_state.dart';

class TaskDetailsState extends Equatable {
  const TaskDetailsState({
    this.task,
    this.history = const [],
    this.comments = const [],
    this.attachments = const [],
    this.members = const [],
    this.loaded = false,
  });

  final TaskView? task;
  final List<HistoryView> history;
  final List<CommentView> comments;
  final List<Attachment> attachments;

  /// Участники проекта — кандидаты в исполнители.
  final List<MemberView> members;
  final bool loaded;

  /// Есть ли изменение статуса, которое можно отменить.
  bool get canUndo =>
      history.any((h) => h.entry.kind == HistoryKind.status && !h.entry.undone);

  TaskDetailsState copyWith({
    TaskView? Function()? task,
    List<HistoryView>? history,
    List<CommentView>? comments,
    List<Attachment>? attachments,
    List<MemberView>? members,
  }) => TaskDetailsState(
    task: task != null ? task() : this.task,
    history: history ?? this.history,
    comments: comments ?? this.comments,
    attachments: attachments ?? this.attachments,
    members: members ?? this.members,
    loaded: true,
  );

  @override
  List<Object?> get props => [
    task,
    history,
    comments,
    attachments,
    members,
    loaded,
  ];
}

class TaskDetailsCubit extends Cubit<TaskDetailsState> {
  TaskDetailsCubit({
    required this.taskId,
    required this._tasks,
    required this._comments,
    required this._attachments,
    required this._projects,
  }) : super(const TaskDetailsState()) {
    _subscriptions = [
      _tasks.watchTask(taskId).listen(_onTask),
      _tasks
          .watchHistory(taskId)
          .listen((h) => emit(state.copyWith(history: h))),
      _comments
          .watchComments(taskId)
          .listen((c) => emit(state.copyWith(comments: c))),
      _attachments
          .watchAttachments(taskId)
          .listen((a) => emit(state.copyWith(attachments: a))),
    ];
  }

  final int taskId;
  final TaskRepository _tasks;
  final CommentRepository _comments;
  final AttachmentRepository _attachments;
  final ProjectRepository _projects;
  late final List<StreamSubscription<Object?>> _subscriptions;
  StreamSubscription<List<MemberView>>? _membersSub;

  void _onTask(TaskView? task) {
    final projectChanged =
        task != null && task.task.projectId != state.task?.task.projectId;
    emit(state.copyWith(task: () => task));
    if (projectChanged) {
      _membersSub?.cancel();
      _membersSub = _projects
          .watchMembers(task.task.projectId)
          .listen((m) => emit(state.copyWith(members: m)));
    }
  }

  Future<String?> changeStatus(TaskStatus status, int actorId) =>
      runAction(() => _tasks.changeStatus(taskId, status, actorId: actorId));

  Future<String?> undo(int actorId) =>
      runAction(() => _tasks.undoLastStatusChange(taskId, actorId: actorId));

  Future<String?> changePriority(TaskPriority priority) =>
      runAction(() => _tasks.changePriority(taskId, priority));

  Future<String?> reassign(int? userId, int actorId) =>
      runAction(() => _tasks.reassign(taskId, userId, actorId: actorId));

  Future<String?> moveToTrash() => runAction(() => _tasks.moveToTrash(taskId));

  Future<String?> restore() => runAction(() => _tasks.restore(taskId));

  Future<String?> addComment(String text, int authorId) => runAction(
    () => _comments.addComment(taskId: taskId, authorId: authorId, text: text),
  );

  Future<String?> deleteComment(int commentId, int userId) =>
      runAction(() => _comments.deleteComment(commentId, userId: userId));

  Future<String?> addAttachment(String fileName, String filePath) => runAction(
    () => _attachments.addAttachment(
      taskId: taskId,
      fileName: fileName,
      filePath: filePath,
    ),
  );

  Future<String?> deleteAttachment(int id) =>
      runAction(() => _attachments.deleteAttachment(id));

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    await _membersSub?.cancel();
    return super.close();
  }
}
