import '../data/database/app_database.dart';
import '../data/repositories/project_repository.dart';
import '../data/repositories/stats_repository.dart';
import '../data/repositories/user_repository.dart';
import '../models/dashboard_stats.dart';
import '../models/enums.dart';
import '../models/views.dart';
import 'load_state.dart';

class UsersCubit extends WatchCubit<List<User>> {
  UsersCubit(this._repository) : super(_repository.watchUsers());

  final UserRepository _repository;

  Future<String?> create(String name, String email) =>
      runAction(() => _repository.createUser(name: name, email: email));

  Future<String?> update(int id, String name, String email) =>
      runAction(() => _repository.updateUser(id, name: name, email: email));

  Future<String?> delete(int id) => runAction(() => _repository.deleteUser(id));
}

class ProjectsCubit extends WatchCubit<List<ProjectSummary>> {
  ProjectsCubit(this._repository) : super(_repository.watchProjects());

  final ProjectRepository _repository;

  Future<String?> create({
    required String name,
    required String description,
    required ProjectStatus status,
    DateTime? endDate,
    int? ownerId,
  }) => runAction(
    () => _repository.createProject(
      name: name,
      description: description,
      status: status,
      endDate: endDate,
      ownerId: ownerId,
    ),
  );

  Future<String?> update(
    int id, {
    required String name,
    required String description,
    required ProjectStatus status,
    DateTime? endDate,
  }) => runAction(
    () => _repository.updateProject(
      id,
      name: name,
      description: description,
      status: status,
      endDate: endDate,
    ),
  );

  Future<String?> delete(int id) =>
      runAction(() => _repository.deleteProject(id));
}

class DashboardCubit extends WatchCubit<DashboardStats> {
  DashboardCubit(StatsRepository repository) : super(repository.watchStats());
}
