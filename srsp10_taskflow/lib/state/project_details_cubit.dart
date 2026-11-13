import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/database/app_database.dart';
import '../data/repositories/project_repository.dart';
import '../models/enums.dart';
import '../models/views.dart';
import 'load_state.dart';

class ProjectDetailsState extends Equatable {
  const ProjectDetailsState({
    this.project,
    this.members = const [],
    this.loaded = false,
  });

  final Project? project;
  final List<MemberView> members;
  final bool loaded;

  ProjectDetailsState copyWith({
    Project? Function()? project,
    List<MemberView>? members,
  }) => ProjectDetailsState(
    project: project != null ? project() : this.project,
    members: members ?? this.members,
    loaded: true,
  );

  @override
  List<Object?> get props => [project, members, loaded];
}

class ProjectDetailsCubit extends Cubit<ProjectDetailsState> {
  ProjectDetailsCubit(this._repository, this.projectId)
    : super(const ProjectDetailsState()) {
    _subscriptions = [
      _repository
          .watchProject(projectId)
          .listen((p) => emit(state.copyWith(project: () => p))),
      _repository
          .watchMembers(projectId)
          .listen((m) => emit(state.copyWith(members: m))),
    ];
  }

  final ProjectRepository _repository;
  final int projectId;
  late final List<StreamSubscription<Object?>> _subscriptions;

  Future<String?> addMember(int userId, MemberRole role) =>
      runAction(() => _repository.addMember(projectId, userId, role));

  Future<String?> changeRole(int userId, MemberRole role) =>
      runAction(() => _repository.changeRole(projectId, userId, role));

  Future<String?> removeMember(int userId) =>
      runAction(() => _repository.removeMember(projectId, userId));

  @override
  Future<void> close() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    return super.close();
  }
}
