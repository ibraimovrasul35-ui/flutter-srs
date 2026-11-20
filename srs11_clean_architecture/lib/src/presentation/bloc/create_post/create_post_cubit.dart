import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/author.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/failures/failures.dart';
import '../../../domain/usecases/create_post_usecase.dart';
import '../../../domain/usecases/get_authors_usecase.dart';

part 'create_post_state.dart';

class CreatePostCubit extends Cubit<CreatePostState> {
  final GetAuthorsUseCase _getAuthors;
  final CreatePostUseCase _createPost;

  CreatePostCubit({
    required this._getAuthors,
    required this._createPost,
  }) : super(const CreatePostState());

  /// Авторы уже загружены списком постов, поэтому обычно запроса
  /// к серверу здесь нет — AuthorRepository отдаёт их из памяти.
  Future<void> loadAuthors() async {
    emit(state.copyWith(authorsStatus: AuthorsStatus.loading));
    final result = await _getAuthors();
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
          authorsStatus: AuthorsStatus.failure, authorsFailure: failure)),
      (authors) => emit(state.copyWith(
        authorsStatus:
            authors.isEmpty ? AuthorsStatus.empty : AuthorsStatus.success,
        authors: authors,
      )),
    );
  }

  Future<void> submit({
    required String title,
    required String body,
    required int? userId,
  }) async {
    if (state.isSubmitting) return; // защита от повторного нажатия
    emit(state.copyWith(submitStatus: SubmitStatus.submitting));
    final result = await _createPost(
        CreatePostParams(title: title, body: body, userId: userId));
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
          submitStatus: SubmitStatus.failure, submitFailure: failure)),
      (post) => emit(state.copyWith(
          submitStatus: SubmitStatus.success, createdPost: post)),
    );
  }
}
