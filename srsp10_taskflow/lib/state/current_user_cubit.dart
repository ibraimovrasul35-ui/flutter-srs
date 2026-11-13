import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/database/app_database.dart';
import '../data/repositories/user_repository.dart';

class CurrentUserState extends Equatable {
  const CurrentUserState({this.users = const [], this.user});

  final List<User> users;

  /// От чьего имени выполняются действия (история, комментарии).
  final User? user;

  @override
  List<Object?> get props => [users, user];
}

class CurrentUserCubit extends Cubit<CurrentUserState> {
  CurrentUserCubit(UserRepository repository)
    : super(const CurrentUserState()) {
    _subscription = repository.watchUsers().listen((users) {
      final selectedId = state.user?.id;
      final user =
          users.where((u) => u.id == selectedId).firstOrNull ??
          users.firstOrNull;
      emit(CurrentUserState(users: users, user: user));
    });
  }

  late final StreamSubscription<List<User>> _subscription;

  void select(User user) =>
      emit(CurrentUserState(users: state.users, user: user));

  @override
  Future<void> close() async {
    await _subscription.cancel();
    return super.close();
  }
}
