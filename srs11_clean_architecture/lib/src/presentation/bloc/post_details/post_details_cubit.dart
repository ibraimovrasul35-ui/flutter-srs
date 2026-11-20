import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/author.dart';
import '../../../domain/entities/comment.dart';
import '../../../domain/entities/post.dart';
import '../../../domain/failures/failures.dart';
import '../../../domain/usecases/get_author_usecase.dart';
import '../../../domain/usecases/get_cached_post_details_usecase.dart';
import '../../../domain/usecases/get_post_details_usecase.dart';

part 'post_details_state.dart';

class PostDetailsCubit extends Cubit<PostDetailsState> {
  final GetPostDetailsUseCase _getDetails;
  final GetCachedPostDetailsUseCase _getCachedDetails;
  final GetAuthorUseCase _getAuthor;

  /// [post] — пост из списка: заголовок и текст видны сразу,
  /// пока догружаются актуальные данные и комментарии.
  PostDetailsCubit({
    required Post post,
    required this._getDetails,
    required this._getCachedDetails,
    required this._getAuthor,
  }) : super(PostDetailsState(post: post));

  bool _inFlight = false;

  Future<void> load() async {
    if (_inFlight) return; // повторный pull-to-refresh во время загрузки
    _inFlight = true;
    try {
      await _load();
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _load() async {
    final post = state.post;
    if (state.author == null) unawaited(_loadAuthor(post.userId));

    // Локальный пост на сервере не существует — запрашивать нечего.
    if (post.isLocal) {
      emit(state.copyWith(status: DetailsStatus.success));
      return;
    }

    if (state.status == DetailsStatus.loading) {
      final cached = (await _getCachedDetails(post.id)).toNullable();
      if (isClosed) return;
      if (cached != null) {
        emit(state.copyWith(
          status: DetailsStatus.success,
          post: cached.data.post,
          comments: cached.data.comments,
          isFromCache: true,
        ));
      }
    } else if (state.status == DetailsStatus.failure) {
      emit(state.copyWith(status: DetailsStatus.loading, failure: null));
    }

    final result = await _getDetails(post.id);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        // Если что-то уже показано (кэш), не прячем это за ошибкой.
        status: state.status == DetailsStatus.success
            ? DetailsStatus.success
            : DetailsStatus.failure,
        isFromCache: state.status == DetailsStatus.success,
        failure: failure,
      )),
      (details) => emit(state.copyWith(
        status: DetailsStatus.success,
        post: details.post,
        comments: details.comments,
        isFromCache: false,
        failure: null,
      )),
    );
  }

  Future<void> _loadAuthor(int userId) async {
    final result = await _getAuthor(userId);
    if (isClosed) return;
    // Автор — дополнительная информация, без него экран работает.
    result.fold((_) {}, (author) => emit(state.copyWith(author: author)));
  }
}
