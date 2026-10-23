import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/error/app_exception.dart';
import '../../data/models/post.dart';
import '../../data/models/user.dart';
import '../../data/repositories/post_repository.dart';

enum UsersStatus { loading, success, failure }

enum SubmitStatus { idle, submitting, success, failure }

final class CreatePostState extends Equatable {
  final UsersStatus usersStatus;
  final List<User> users;
  final SubmitStatus submitStatus;
  final Post? createdPost; // объект, который вернул сервер
  final String? errorMessage;

  const CreatePostState({
    this.usersStatus = UsersStatus.loading,
    this.users = const [],
    this.submitStatus = SubmitStatus.idle,
    this.createdPost,
    this.errorMessage,
  });

  bool get isSubmitting => submitStatus == SubmitStatus.submitting;

  CreatePostState copyWith({
    UsersStatus? usersStatus,
    List<User>? users,
    SubmitStatus? submitStatus,
    Post? createdPost,
    String? errorMessage,
  }) {
    return CreatePostState(
      usersStatus: usersStatus ?? this.usersStatus,
      users: users ?? this.users,
      submitStatus: submitStatus ?? this.submitStatus,
      createdPost: createdPost ?? this.createdPost,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [usersStatus, users, submitStatus, createdPost, errorMessage];
}

class CreatePostCubit extends Cubit<CreatePostState> {
  final PostRepository _repository;

  CreatePostCubit(this._repository) : super(const CreatePostState());

  // ---------- Валидация (вызывается до отправки) ----------

  static String? validateTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите заголовок';
    if (v.length < 5) return 'Минимум 5 символов';
    if (v.length > 100) return 'Максимум 100 символов';
    return null;
  }

  static String? validateBody(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите текст поста';
    if (v.length < 10) return 'Минимум 10 символов';
    if (v.length > 1000) return 'Максимум 1000 символов';
    return null;
  }

  static String? validateUser(int? userId) =>
      userId == null ? 'Выберите автора' : null;

  // ---------- Авторы ----------

  Future<void> loadUsers() async {
    final cached = _repository.getCachedUsers();
    if (cached != null) {
      emit(state.copyWith(usersStatus: UsersStatus.success, users: cached.data));
    } else {
      emit(state.copyWith(usersStatus: UsersStatus.loading));
    }
    try {
      final users = await _repository.fetchUsers();
      if (!isClosed) {
        emit(state.copyWith(usersStatus: UsersStatus.success, users: users));
      }
    } on AppException catch (e) {
      if (isClosed || state.users.isNotEmpty) return;
      emit(state.copyWith(usersStatus: UsersStatus.failure, errorMessage: e.message));
    }
  }

  // ---------- Отправка ----------

  Future<void> submit({
    required String title,
    required String body,
    required int userId,
  }) async {
    if (state.isSubmitting) return; // защита от повторного нажатия
    emit(state.copyWith(submitStatus: SubmitStatus.submitting));
    try {
      final created = await _repository.createPost(
          title: title.trim(), body: body.trim(), userId: userId);
      if (!isClosed) {
        emit(state.copyWith(
            submitStatus: SubmitStatus.success, createdPost: created));
      }
    } on AppException catch (e) {
      if (!isClosed) {
        emit(state.copyWith(
            submitStatus: SubmitStatus.failure, errorMessage: e.message));
      }
    }
  }
}
